import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/library_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User methods
  Future<void> createUser(User user) async {
    return await _db.collection('users').doc(user.uid).set({
      'name': user.displayName ?? 'User',
      'email': user.email,
      'subscription_status': 'Free',
      'daily_usage': {
        'summaries': 0,
        'quizzes': 0,
        'flashcards': 0,
      },
      'last_reset': Timestamp.now(),
    });
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    return await _db.collection('users').doc(uid).update(data);
  }

  // Check if user can generate content
  bool canGenerate(String toolType, UserModel user) {
    if (user.subscriptionStatus == 'Pro') {
      return true;
    }

    final now = DateTime.now();
    final lastReset = user.lastReset.toDate();
    if (now.difference(lastReset).inDays >= 1) {
      // It's a new day, so reset the usage counters
      return true; // Allow generation and then reset
    }

    int currentUsage = user.dailyUsage[toolType] ?? 0;

    switch (toolType) {
      case 'summaries':
        return currentUsage < 5;
      case 'quizzes':
        return currentUsage < 3;
      case 'flashcards':
        return currentUsage < 3;
      default:
        return false;
    }
  }

  // Increment usage for a specific tool
  Future<void> incrementUsage(String toolType, String userId) async {
    final userRef = _db.collection('users').doc(userId);
    final userSnap = await userRef.get();
    final user = UserModel.fromFirestore(userSnap);

    if (user.subscriptionStatus == 'Pro') {
      return; // Pro users have unlimited usage
    }

    final now = DateTime.now();
    final lastReset = user.lastReset.toDate();
    if (now.difference(lastReset).inDays >= 1) {
      // If it's a new day, reset all usage counters and update last_reset
      await userRef.update({
        'daily_usage.summaries': 0,
        'daily_usage.quizzes': 0,
        'daily_usage.flashcards': 0,
        'last_reset': Timestamp.now(),
      });
    }

    await userRef.update({
      'daily_usage.$toolType': FieldValue.increment(1),
    });
  }

  // Library methods

  Future<DocumentReference> addSummary(String userId, Map<String, dynamic> data) {
    final summaryData = <String, dynamic>{};
    summaryData.addAll(data);
    return _db.collection('users').doc(userId).collection('summaries').add(summaryData);
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

  Future<void> saveQuiz(String userId, String title, List<Map<String, dynamic>> questions) async {
    await _db.collection('users').doc(userId).collection('quizzes').add({
      'title': title,
      'questions': questions,
      'created_at': Timestamp.now(),
    });
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

  Future<void> saveFlashcards(String userId, String title, List<Map<String, String>> flashcards) async {
    await _db.collection('users').doc(userId).collection('flashcards').add({
      'title': title,
      'cards': flashcards,
      'created_at': Timestamp.now(),
    });
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
}
