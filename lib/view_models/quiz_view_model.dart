import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../../models/local_quiz.dart';
import '../../services/local_database_service.dart';
import '../../services/auth_service.dart';

class QuizViewModel with ChangeNotifier {
  final LocalDatabaseService _localDatabaseService;
  final AuthService _authService;

  List<LocalQuiz> _quizzes = [];

  QuizViewModel(this._localDatabaseService, this._authService) {
    _loadQuizzes();
  }

  List<LocalQuiz> get quizzes => _quizzes;

  int get quizzesTaken {
    // This will count the total number of attempts across all quizzes.
    if (_quizzes.isEmpty) return 0;
    return _quizzes.map((q) => q.scores.length).sum;
  }

  double get averageScore {
    if (_quizzes.isEmpty) return 0.0;
    
    final allScores = _quizzes.expand((q) => q.scores).toList();
    if (allScores.isEmpty) return 0.0;
    
    return allScores.average;
  }

  double get bestScore {
    if (_quizzes.isEmpty) return 0.0;

    final allScores = _quizzes.expand((q) => q.scores).toList();
    if (allScores.isEmpty) return 0.0;

    return allScores.reduce((max, score) => score > max ? score : max);
  }

  void _loadQuizzes() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _localDatabaseService.init(); // Ensure DB is initialized
      _quizzes = await _localDatabaseService.getAllQuizzes(user.uid);
      notifyListeners();
    }
  }

  // Call this method to refresh data from the database
  void refresh() {
    _loadQuizzes();
  }
}
