import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../widgets/upgrade_modal.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_model.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _questions = widget.quiz!.questions;
      _titleController.text = widget.quiz!.title;
    }
  }

  Future<void> _generateQuiz() async {
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
      if (mounted) {
        _showUpgradeDialog();
      }
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
      final questions = await _aiService.generateQuiz(_textController.text);
      setState(() {
        _questions = questions;
      });
    } catch (e, s) {
      developer.log(
        'Error generating quiz',
        name: 'my_app.quiz',
        error: e,
        stackTrace: s,
      );
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
        await _firestore.incrementUsage(userModel.uid, 'quizzes');
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
              if (mounted) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const UpgradeModal(),
                );
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (_questions.isEmpty || _titleController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and generate a quiz before saving.')),
      );
      return;
    }

    try {
      await _firestore.addQuiz(
        _auth.currentUser!.uid,
        Quiz(
          id: '',
          title: _titleController.text,
          questions: _questions,
          timestamp: Timestamp.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved successfully!')),
      );
    } catch (e, s) {
      developer.log(
        'Error saving quiz',
        name: 'my_app.quiz',
        error: e,
        stackTrace: s,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: $e')),
      );
    }
  }

  void _handleAnswer(int selectedIndex) {
    setState(() {
      _selectedAnswerIndex = selectedIndex;
      if (_questions[_currentQuestionIndex].options[selectedIndex] ==
          _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _selectedAnswerIndex = null;
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            // End of the quiz
            _showResultDialog();
          }
        });
      }
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
              if (mounted) {
                setState(() {
                  _questions = [];
                  _currentQuestionIndex = 0;
                  _score = 0;
                });
              }
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
                        onPressed: () async {
                          final clipboardData =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (clipboardData != null) {
                            _textController.text = clipboardData.text!;
                          }
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
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(_questions[_currentQuestionIndex].question,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    ...List.generate(
                        _questions[_currentQuestionIndex].options.length,
                        (index) {
                      final isCorrect = _questions[_currentQuestionIndex]
                              .options[index] ==
                          _questions[_currentQuestionIndex].correctAnswer;
                      final isSelected = index == _selectedAnswerIndex;

                      Color? tileColor;
                      if (isSelected) {
                        tileColor = isCorrect
                            ? Colors.green.withAlpha(128)
                            : Colors.red.withAlpha(128);
                      } else if (_selectedAnswerIndex != null && isCorrect) {
                        tileColor = Colors.green.withAlpha(128);
                      }

                      return ListTile(
                        title: Text(
                            _questions[_currentQuestionIndex].options[index]),
                        tileColor: tileColor,
                        onTap: _selectedAnswerIndex == null
                            ? () => _handleAnswer(index)
                            : null,
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
