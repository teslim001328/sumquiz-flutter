import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../widgets/upgrade_modal.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_model.dart';
import '../../models/summary_model.dart';

class QuizScreen extends StatefulWidget {
  final Quiz? quiz;

  const QuizScreen({super.key, this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  final AIService _aiService = AIService();
  late SpacedRepetitionService _srsService;

  bool _isLoading = false;
  bool _isQuizFinished = false;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (widget.quiz != null) {
      setState(() {
        _questions = widget.quiz!.questions;
        _titleController.text = widget.quiz!.title;
      });
    }
  }

  Future<void> _initializeServices() async {
    final dbService = LocalDatabaseService();
    await dbService.init();
    _srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
  }

  Future<void> _generateQuiz() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in both the title and the text fields.')),
        );
        return;
    }
    
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available.')),
      );
      return;
    }

    final canGenerate = await _firestore.canGenerate(userModel.uid, 'quizzes');
    if (!canGenerate) {
      if (mounted) _showUpgradeDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _isQuizFinished = false;
      _questions = [];
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _score = 0;
    });

    try {
      final summary = Summary(
        id: '',
        userId: userModel.uid,
        content: _textController.text,
        timestamp: Timestamp.now(),
      );
      final quiz = await _aiService.generateQuizFromSummary(summary);
      await _firestore.incrementUsage(userModel.uid, 'quizzes');
      if (mounted) {
        setState(() {
          _questions = quiz.questions;
          // Title is already set from the controller
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUpgradeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const UpgradeModal(),
    );
  }

  Future<void> _saveQuiz() async {
    if (_questions.isEmpty || _titleController.text.isEmpty) return;

    try {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user == null) throw Exception("User not found");
      await _firestore.addQuiz(
        user.uid,
        Quiz(
          id: '',
          title: _titleController.text,
          questions: _questions,
          timestamp: Timestamp.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleNextQuestion() {
    if (_selectedAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an answer.')),
      );
      return;
    }
    
    final isCorrect = _questions[_currentQuestionIndex].options[_selectedAnswerIndex!] ==
        _questions[_currentQuestionIndex].correctAnswer;

    if (isCorrect) {
      _score++;
    }

    final questionId = _questions[_currentQuestionIndex].hashCode.toString();
    _srsService.updateReview(questionId, isCorrect);

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
      });
    } else {
      setState(() {
        _isQuizFinished = true;
      });
    }
  }

  void _retryQuiz() {
      setState(() {
          _isQuizFinished = false;
          _currentQuestionIndex = 0;
          _selectedAnswerIndex = null;
          _score = 0;
      });
  }

  void _resetToCreation() {
    setState(() {
      _questions = [];
      _isQuizFinished = false;
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _score = 0;
      _textController.clear();
      _titleController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildContent(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isQuizFinished) {
      return _buildResultScreen();
    } else if (_questions.isNotEmpty) {
      return _buildQuizInterface();
    } else {
      return _buildCreationForm();
    }
  }

  Widget _buildCreationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text('Create Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Quiz Title', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter quiz title',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Text', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter text to generate quiz',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _generateQuiz,
                child: const Text('Generate Quiz', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInterface() {
    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Column(
              children: [
                const Text('Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Question ${_currentQuestionIndex + 1}/${_questions.length}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _resetToCreation,
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1532012197267-da84d127e765?w=800'),
                    fit: BoxFit.cover,
                ),
            ),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.4)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                  ),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question.question, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Choose the best answer', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                return RadioListTile<int>(
                  title: Text(question.options[index], style: const TextStyle(color: Colors.white, fontSize: 16)),
                  value: index,
                  groupValue: _selectedAnswerIndex,
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswerIndex = value;
                    });
                  },
                  activeColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.trailing,
                  tileColor: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleNextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text('Quiz Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _resetToCreation,
              )
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_score/${_questions.length}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Your Score', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1516975080664-626423896246?w=400',
                          width: 100, height: 100, fit: BoxFit.cover,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saveQuiz,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Quiz', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _retryQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
