import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
