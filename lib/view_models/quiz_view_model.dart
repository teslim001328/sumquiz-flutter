import 'package:flutter/material.dart';
import 'package:myapp/models/local_quiz.dart';
import 'package:myapp/services/local_database_service.dart';
import 'package:myapp/services/auth_service.dart';

class QuizViewModel with ChangeNotifier {
  final LocalDatabaseService _localDatabaseService;
  final AuthService _authService;

  List<LocalQuiz> _quizzes = [];

  QuizViewModel(this._localDatabaseService, this._authService) {
    _loadQuizzes();
  }

  List<LocalQuiz> get quizzes => _quizzes;

  double get averageScore {
    if (_quizzes.isEmpty) return 0.0;
    final scoredQuizzes = _quizzes.where((q) => q.questions.any((qq) => qq.selectedOptionIndex != -1));
    if (scoredQuizzes.isEmpty) return 0.0;
    final totalScore = scoredQuizzes.fold<double>(0, (sum, quiz) => sum + _calculateScore(quiz));
    return totalScore / scoredQuizzes.length;
  }

  double get bestScore {
    if (_quizzes.isEmpty) return 0.0;
    final scores = _quizzes.map((quiz) => _calculateScore(quiz));
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a > b ? a : b);
  }

  double _calculateScore(LocalQuiz quiz) {
    final correctAnswers = quiz.questions.where((q) => q.options[q.correctOptionIndex] == q.options[q.selectedOptionIndex]).length;
    return (correctAnswers / quiz.questions.length) * 100;
  }

  void _loadQuizzes() async {
    final user = _authService.currentUser;
    if (user != null) {
      _quizzes = await _localDatabaseService.getAllQuizzes(user.uid);
      notifyListeners();
    }
  }

  void refresh() {
    _loadQuizzes();
  }
}
