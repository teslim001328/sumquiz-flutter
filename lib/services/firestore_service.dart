import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/quiz_question.dart';
import '../models/flashcard_model.dart';
import '../models/library_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => UserModel.fromFirestore(snap));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).update(data);
  }

  Future<void> saveSummary(String userId, String summary, String title) {
    return _db.collection('users').doc(userId).collection('summaries').add({
      'title': title,
      'summary': summary,
      'created_at': Timestamp.now(),
    });
  }

  Future<void> saveQuiz(String userId, String title, List<QuizQuestion> questions) {
    return _db.collection('users').doc(userId).collection('quizzes').add({
      'title': title,
      'questions': questions.map((q) => {
        'question': q.question,
        'options': q.options,
        'correct_answer': q.correctAnswer,
      }).toList(),
      'created_at': Timestamp.now(),
    });
  }

  Future<void> saveFlashcards(String userId, String title, List<Flashcard> flashcards) {
    return _db.collection('users').doc(userId).collection('flashcards').add({
      'title': title,
      'cards': flashcards.map((f) => {
        'front': f.question,
        'back': f.answer,
      }).toList(),
      'created_at': Timestamp.now(),
    });
  }

  Stream<List<LibraryItem>> streamSummaries(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('summaries')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LibraryItem.fromFirestore(doc, 'summary'))
            .toList());
  }

  Stream<List<LibraryItem>> streamQuizzes(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LibraryItem.fromFirestore(doc, 'quiz'))
            .toList());
  }

  Stream<List<LibraryItem>> streamFlashcards(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LibraryItem.fromFirestore(doc, 'flashcards'))
            .toList());
  }

  bool canGenerate(String toolType, UserModel user) {
    if (user.subscriptionStatus == 'Pro') {
      return true;
    }

    final now = DateTime.now();
    final lastReset = user.lastReset.toDate();
    final difference = now.difference(lastReset);

    if (difference.inDays > 0) {
      _resetDailyUsage(user.uid);
      return true;
    }

    final usage = user.dailyUsage[toolType] ?? 0;
    final limit = _getLimitForTool(toolType);

    return usage < limit;
  }

  Future<void> incrementUsage(String toolType, String uid) {
    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(uid);
      final snap = await transaction.get(userRef);
      final user = UserModel.fromFirestore(snap);

      if (canGenerate(toolType, user)) {
        final currentUsage = user.dailyUsage[toolType] ?? 0;
        transaction.update(userRef, {
          'daily_usage.$toolType': currentUsage + 1,
        });
      }
    });
  }

  Future<void> _resetDailyUsage(String uid) {
    return _db.collection('users').doc(uid).update({
      'daily_usage': {'summaries': 0, 'quizzes': 0, 'flashcards': 0},
      'last_reset': Timestamp.now(),
    });
  }

  int _getLimitForTool(String toolType) {
    switch (toolType) {
      case 'summaries':
        return 3;
      case 'quizzes':
        return 2;
      case 'flashcards':
        return 2;
      default:
        return 0;
    }
  }
}
