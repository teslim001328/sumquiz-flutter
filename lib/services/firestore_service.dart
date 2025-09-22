import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/summary_model.dart';
import 'package:myapp/models/quiz_model.dart';
import 'package:myapp/models/flashcard_model.dart';
import 'package:myapp/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
  }

  Future<void> saveUserData(UserModel user) {
    return _db.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<bool> canGenerate(String uid, String feature) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      int dailyCount = doc.data()!['daily_usage'][feature] ?? 0;
      return dailyCount < 10;
    }
    return false;
  }

  Future<void> incrementUsage(String uid, String feature) {
    return _db.collection('users').doc(uid).update({
      'daily_usage.$feature': FieldValue.increment(1),
    });
  }

  Stream<List<Summary>> streamSummaries(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('summaries')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((list) => list.docs.map((doc) => Summary.fromFirestore(doc)).toList());
  }

    Future<void> addSummary(String userId, Summary summary) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('summaries')
        .add(summary.toJson());
  }

  Stream<List<Quiz>> streamQuizzes(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('quizzes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((list) => list.docs.map((doc) => Quiz.fromFirestore(doc)).toList());
  }

  Stream<List<FlashcardSet>> streamFlashcards(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('flashcards')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((list) =>
            list.docs.map((doc) => FlashcardSet.fromFirestore(doc)).toList());
  }

  Future<void> saveFlashcards(String uid, FlashcardSet flashcardSet) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('flashcards')
        .add(flashcardSet.toJson());
  }
}
