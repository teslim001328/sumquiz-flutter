import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'upgrade_screen.dart';

class Question {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  Question({required this.question, required this.options, required this.correctAnswerIndex});
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;

  Future<void> _generateQuiz() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available.')),
      );
      return;
    }

    if (!_firestore.canGenerate('quizzes', userModel)) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _questions = [];
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _score = 0;
    });

    try {
      final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
      final prompt =
          'Create a multiple choice quiz from the following text. Return a JSON list of objects, where each object has a "question", an "options" list, and a "correctAnswerIndex". Text: ${_textController.text}';
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        final jsonResponse = jsonDecode(response.text!);
        if (jsonResponse is List) {
          setState(() {
            _questions = jsonResponse
                .map((item) => Question(
                      question: item['question'],
                      options: List<String>.from(item['options']),
                      correctAnswerIndex: item['correctAnswerIndex'],
                    ))
                .toList();
          });
        }
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
        await _firestore.incrementUsage('quizzes', _auth.currentUser!.uid);
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text('You have reached your daily limit. Upgrade to Pro for unlimited quiz generation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (_questions.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and generate a quiz before saving.')),
      );
      return;
    }

    try {
      await _firestore.saveQuiz(
        _auth.currentUser!.uid,
        _titleController.text,
        _questions.map((q) => {
          'question': q.question,
          'options': q.options,
          'correctAnswerIndex': q.correctAnswerIndex,
        }).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: $e')),
      );
    }
  }

  void _handleAnswer(int selectedIndex) {
    setState(() {
      _selectedAnswerIndex = selectedIndex;
      if (selectedIndex == _questions[_currentQuestionIndex].correctAnswerIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _selectedAnswerIndex = null;
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
        } else {
          // End of the quiz
          _showResultDialog();
        }
      });
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Finished!'),
        content: Text('Your score: $_score / ${_questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _questions = [];
                _currentQuestionIndex = 0;
                _score = 0;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_questions.isEmpty)
              Column(
                children: [
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'Enter your text here',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () {
                          // TODO: Implement paste from clipboard
                        },
                      ),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title for your quiz',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generateQuiz,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Quiz'),
                  ),
                ],
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_questions.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(_questions[_currentQuestionIndex].question, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    ...List.generate(_questions[_currentQuestionIndex].options.length, (index) {
                      final isCorrect = index == _questions[_currentQuestionIndex].correctAnswerIndex;
                      final isSelected = index == _selectedAnswerIndex;

                      Color? tileColor;
                      if (isSelected) {
                        tileColor = isCorrect ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
                      } else if (_selectedAnswerIndex != null && isCorrect) {
                        tileColor = Colors.green.withOpacity(0.5);
                      }

                      return ListTile(
                        title: Text(_questions[_currentQuestionIndex].options[index]),
                        tileColor: tileColor,
                        onTap: _selectedAnswerIndex == null ? () => _handleAnswer(index) : null,
                      );
                    }),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _saveQuiz,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Quiz'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
