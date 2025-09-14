import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../../models/user_model.dart';
import '../../models/quiz_question.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';

enum QuizState { initial, loading, error, success }

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedLibraryItem;
  QuizState _state = QuizState.initial;
  String _errorMessage = '';
  List<QuizQuestion> _questions = [];

  late final AIService _aiService;
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(FirebaseVertexAI.instance);
    _firestoreService = FirestoreService();
  }

  void _generateQuiz() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final userModel = await _firestoreService.streamUser(user!.uid).first;

    if (!_firestoreService.canGenerate('quizzes', userModel)) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _state = QuizState.loading;
    });

    try {
      String content = _textController.text;
      if (_selectedLibraryItem != null) {
        // TODO: Fetch content from library
      }

      List<QuizQuestion> questions = await _aiService.generateQuiz(content);

      if (questions.isEmpty) {
        setState(() {
          _state = QuizState.error;
          _errorMessage = 'Could not generate a quiz from the provided text.';
        });
      } else {
        await _firestoreService.incrementUsage('quizzes', user.uid);
        setState(() {
          _questions = questions;
          _state = QuizState.success;
        });
      }
    } catch (e) {
      setState(() {
        _state = QuizState.error;
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text('You have reached your daily quiz limit. Upgrade to Pro for unlimited quizzes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement navigation to upgrade screen
              Navigator.of(context).pop();
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _state = QuizState.initial;
      _errorMessage = '';
    });
  }

  void _selectFromLibrary() {
    // TODO: Implement library picker bottom sheet
    setState(() {
      _selectedLibraryItem = 'My Awesome Summary';
    });
  }

  void _saveToLibrary() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      try {
        await _firestoreService.saveQuiz(user.uid, _selectedLibraryItem ?? "Pasted Text Quiz", _questions);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz saved to library!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving quiz.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Quiz'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(),
          ),
          if (_state == QuizState.loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case QuizState.error:
        return _buildErrorState();
      case QuizState.success:
        return _buildSuccessState();
      default:
        return _buildInitialState();
    }
  }

  Widget _buildInitialState() {
    bool canGenerate = _textController.text.isNotEmpty || _selectedLibraryItem != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate Quiz',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Input text or select content from your Library',
          style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _textController,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Paste text here to generate quiz...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (text) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.library_books),
            label: const Text('Select from Library'),
            onPressed: _selectFromLibrary,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
        if (_selectedLibraryItem != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: Chip(
                label: Text(_selectedLibraryItem!),
                onDeleted: () {
                  setState(() {
                    _selectedLibraryItem = null;
                  });
                },
              ),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: canGenerate ? _generateQuiz : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
            child: const Text('Generate Quiz'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to generate quiz',
            style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Quiz',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            final question = _questions[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}: ${question.question}',
                      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ...List<Widget>.from(question.options.map<Widget>((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: question.selectedAnswer,
                        onChanged: (value) {
                          setState(() {
                            question.selectedAnswer = value;
                          });
                        },
                      );
                    })),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Save'),
              onPressed: _saveToLibrary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _retry,
            child: const Text('Generate Another Quiz'),
          ),
        ),
      ],
    );
  }
}
