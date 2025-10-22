import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../models/local_quiz.dart';
import '../../models/local_quiz_question.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_database_service.dart';
import '../widgets/upgrade_modal.dart';
import '../../models/summary_model.dart' as model_summary;

class QuizScreen extends StatefulWidget {
  final LocalQuiz? quiz;

  const QuizScreen({super.key, this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final AIService _aiService = AIService();
  final LocalDatabaseService _localDbService = LocalDatabaseService();

  late List<LocalQuizQuestion> _questions;
  bool _isLoading = false;
  bool _isQuizFinished = false;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _answerWasSelected = false;
  int _score = 0;
  String? _newQuizId; // Used to hold the ID for a newly generated quiz

  @override
  void initState() {
    super.initState();
    _localDbService.init();
    if (widget.quiz != null) {
      _questions = widget.quiz!.questions;
      _titleController.text = widget.quiz!.title;
    } else {
      _questions = [];
    }
  }
  
  Color _getTileColor(int index, ThemeData theme) {
    if (!_answerWasSelected) {
      return theme.cardColor;
    }
    final question = _questions[_currentQuestionIndex];
    final bool isCorrect = question.options[index] == question.correctAnswer;
    if (isCorrect) {
      return Colors.green.shade100;
    }
    if (index == _selectedAnswerIndex && !isCorrect) {
      return Colors.red.shade100;
    }
    return theme.cardColor;
  }
  
  Icon _getTileIcon(int index, ThemeData theme) {
    if (!_answerWasSelected) {
      return Icon(Icons.radio_button_unchecked, color: theme.disabledColor);
    }
    final question = _questions[_currentQuestionIndex];
    final bool isCorrect = question.options[index] == question.correctAnswer;

    if (isCorrect) {
      return Icon(Icons.check_circle, color: Colors.green);
    }
    if (index == _selectedAnswerIndex && !isCorrect) {
      return Icon(Icons.cancel, color: Colors.red);
    }
    return Icon(Icons.radio_button_unchecked, color: theme.disabledColor);
  }


  Future<void> _generateQuiz() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and text.')),
      );
      return;
    }

    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available.')),
      );
      return;
    }

    final canGenerate = await FirestoreService().canGenerate(userModel.uid, 'quizzes');
    if (!canGenerate) {
      if (mounted) _showUpgradeDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _resetQuizState();
    });

    try {
      final summary = model_summary.Summary(
        id: '',
        userId: userModel.uid,
        title: _titleController.text,
        content: _textController.text,
        timestamp: Timestamp.now(),
      );
      final quiz = await _aiService.generateQuizFromSummary(summary);
      await FirestoreService().incrementUsage(userModel.uid, 'quizzes');
      
      setState(() {
        _questions = quiz.questions.map((q) => LocalQuizQuestion(
          question: q.question,
          options: q.options,
          correctAnswer: q.correctAnswer,
        )).toList();
        _newQuizId = const Uuid().v4(); // Generate ID for potential saving
      });
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

    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save quiz. User not logged in.')),
      );
      return;
    }

    // This handles saving a quiz that was just generated.
    // Existing quizzes are updated when they finish, not here.
    if (_newQuizId != null) {
      final percentageScore = (_score / _questions.length) * 100.0;
      final newQuiz = LocalQuiz(
        id: _newQuizId!,
        userId: user.uid,
        title: _titleController.text,
        questions: _questions,
        timestamp: DateTime.now(),
        scores: [percentageScore],
      );

      try {
        await _localDbService.saveQuiz(newQuiz);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quiz saved successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error saving quiz: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    } else if (widget.quiz != null) {
        // If we are on the result screen of an existing quiz, we just pop
        Navigator.of(context).pop();
    }
  }

  void _onAnswerSelected(int index) {
    if (_answerWasSelected) return; // Don't allow changing answer

    final question = _questions[_currentQuestionIndex];
    final isCorrect = question.options[index] == question.correctAnswer;

    setState(() {
      _selectedAnswerIndex = index;
      _answerWasSelected = true;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _handleNextQuestion() {
    if (!_answerWasSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer.')),
      );
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answerWasSelected = false;
      });
    } else {
      // Quiz is finished
      _onQuizFinished();
    }
  }

  Future<void> _onQuizFinished() async {
    // If this was an existing quiz, update its score list
    if (widget.quiz != null) {
      final percentageScore = (_score / _questions.length) * 100.0;
      final existingQuiz = await _localDbService.getQuiz(widget.quiz!.id);
      if (existingQuiz != null) {
        existingQuiz.scores.add(percentageScore);
        await _localDbService.saveQuiz(existingQuiz);
      }
    }
    setState(() {
      _isQuizFinished = true;
    });
  }

  void _resetQuizState() {
    _isQuizFinished = false;
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _answerWasSelected = false;
    _score = 0;
  }
  
  void _retryQuiz() {
    setState(() {
      _resetQuizState();
      // If it's a generated quiz, we keep the questions.
      // If it's an existing quiz, we also just reset the state.
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          _buildContent(theme),
          if (_isLoading)
            Container(
              color: theme.scaffoldBackgroundColor.withAlpha(178),
              child: Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.onSurface)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isQuizFinished) {
      return _buildResultScreen(theme);
    } else if (_questions.isNotEmpty) {
      return _buildQuizInterface(theme);
    } else {
      return _buildCreationForm(theme);
    }
  }

  Widget _buildCreationForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text('Create Quiz', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiz Title', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter quiz title',
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Text', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter text to generate quiz',
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
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
              child: ElevatedButton(
                onPressed: _generateQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Generate Quiz',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInterface(ThemeData theme) {
    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(_titleController.text, style: theme.textTheme.headlineMedium),
          Text('Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                return Card(
                  elevation: _answerWasSelected ? 4 : 2,
                  color: _getTileColor(index, theme),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedAnswerIndex == index 
                             ? theme.colorScheme.primary 
                             : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(option, style: theme.textTheme.bodyLarge),
                    leading: _getTileIcon(index, theme),
                    onTap: () => _onAnswerSelected(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _answerWasSelected ? _handleNextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: theme.disabledColor,
              ),
              child: Text(
                _currentQuestionIndex < _questions.length - 1 ? 'Next Question' : 'Finish Quiz',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultScreen(ThemeData theme) {
    final percentage = (_score / _questions.length) * 100;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Quiz Results', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Your Score: $_score out of ${_questions.length}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  // A new quiz can be saved. An existing one is already updated.
                  _newQuizId != null ? 'Save Quiz' : 'Done',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _retryQuiz,
                 style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.onSurface),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                child: Text(
                  'Retry Quiz',
                   style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
