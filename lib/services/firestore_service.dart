import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/summary_model.dart';
import 'package:myapp/models/quiz_model.dart';
import 'package:myapp/models/flashcard_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/quiz_question.dart';
import 'package:myapp/models/flashcard.dart';
import 'package:myapp/models/local_summary.dart';
import 'package:myapp/models/local_quiz.dart';
import 'package:myapp/models/local_quiz_question.dart';
import 'package:myapp/models/local_flashcard.dart';
import 'package:myapp/models/local_flashcard_set.dart';
import 'package:myapp/services/local_database_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  // Make the database instance accessible for direct queries
  FirebaseFirestore get db => _db;

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
      // Implement logic based on subscription status
      return dailyCount < 10; // Placeholder for free tier
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

    Future<void> addSummary(String userId, Summary summary) async {
    // Save to local database first
    final localSummary = LocalSummary(
      id: summary.id,
      content: summary.content,
      timestamp: summary.timestamp.toDate(),
      userId: userId,
      isSynced: false,
    );
    await _localDb.saveSummary(localSummary);
    
    // Try to save to Firestore if online
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .doc(summary.id)
          .set(summary.toJson());
      
      // Mark as synced
      await _localDb.updateSummarySyncStatus(summary.id, true);
    } catch (e) {
      // If offline, it will be synced later
      print('Error saving summary to Firestore: $e');
    }
  }

  Future<void> updateSummary(String userId, String summaryId, String title, String content) async {
    final timestamp = Timestamp.now();
    // Update in local database first
    final localSummary = await _localDb.getSummary(summaryId);
    if (localSummary != null) {
      localSummary.content = content;
      localSummary.timestamp = timestamp.toDate();
      localSummary.isSynced = false;
      await _localDb.saveSummary(localSummary);
    }
    
    // Try to update in Firestore if online
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .doc(summaryId)
          .update({
            'content': content,
            'timestamp': timestamp,
          });
      
      // Mark as synced
      await _localDb.updateSummarySyncStatus(summaryId, true);
    } catch (e) {
      // If offline, it will be synced later
      print('Error updating summary in Firestore: $e');
    }
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

  Future<void> addQuiz(String userId, Quiz quiz) async {
    // Save to local database first
    final localQuiz = LocalQuiz(
      id: quiz.id,
      title: quiz.title,
      questions: quiz.questions
          .map((q) => LocalQuizQuestion(
                question: q.question,
                options: q.options,
                correctAnswer: q.correctAnswer,
              ))
          .toList(),
      timestamp: quiz.timestamp.toDate(),
      userId: userId,
      isSynced: false,
    );
    await _localDb.saveQuiz(localQuiz);
    
    // Try to save to Firestore if online
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('quizzes')
          .doc(quiz.id)
          .set(quiz.toJson());
      
      // Mark as synced
      await _localDb.updateQuizSyncStatus(quiz.id, true);
    } catch (e) {
      // If offline, it will be synced later
      print('Error saving quiz to Firestore: $e');
    }
  }

  Future<void> updateQuiz(String userId, String quizId, String title, List<QuizQuestion> questions) async {
    final timestamp = Timestamp.now();
    // Update in local database first
    final localQuiz = await _localDb.getQuiz(quizId);
    if (localQuiz != null) {
      localQuiz.title = title;
      localQuiz.questions = questions
          .map((q) => LocalQuizQuestion(
                question: q.question,
                options: q.options,
                correctAnswer: q.correctAnswer,
              ))
          .toList();
      localQuiz.timestamp = timestamp.toDate();
      localQuiz.isSynced = false;
      await _localDb.saveQuiz(localQuiz);
    }
    
    // Try to update in Firestore if online
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('quizzes')
          .doc(quizId)
          .update({
            'title': title,
            'questions': questions.map((q) => q.toJson()).toList(),
            'timestamp': timestamp,
          });
      
      // Mark as synced
      await _localDb.updateQuizSyncStatus(quizId, true);
    } catch (e) {
      // If offline, it will be synced later
      print('Error updating quiz in Firestore: $e');
    }
  }

  Stream<List<FlashcardSet>> streamFlashcardSets(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('flashcard_sets')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((list) =>
            list.docs.map((doc) => FlashcardSet.fromFirestore(doc)).toList());
  }

  Future<void> addFlashcardSet(String userId, FlashcardSet flashcardSet) async {
    // Save to local database first
    final localFlashcardSet = LocalFlashcardSet(
      id: flashcardSet.id,
      title: flashcardSet.title,
      flashcards: flashcardSet.flashcards
          .map((f) => LocalFlashcard(
                question: f.question,
                answer: f.answer,
              ))
          .toList(),
      timestamp: flashcardSet.timestamp.toDate(),
      userId: userId,
      isSynced: false,
    );
    await _localDb.saveFlashcardSet(localFlashcardSet);
    
    // Try to save to Firestore if online
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('flashcard_sets')
          .doc(flashcardSet.id)
          .set(flashcardSet.toJson());
      
      // Mark as synced
      await _localDb.updateFlashcardSetSyncStatus(flashcardSet.id, true);
    } catch (e) {
      // If offline, it will be synced later
      print('Error saving flashcard set to Firestore: $e');
    }
  }

  Future<void> updateFlashcardSet(String userId, String flashcardSetId, String title, List<Flashcard> flashcards) async {
    final timestamp = Timestamp.now();
    // Update in local database first
    final localFlashcardSet = await _localDb.getFlashcardSet(flashcardSetId);
    if (localFlashcardSet != null) {
      localFlashcardSet.title = title;
      localFlashcardSet.flashcards = flashcards
          .map((f) => LocalFlashcard(
                question: f.question,
                answer: f.answer,
              ))
          .toList();
      localFlashcardSet.timestamp = timestamp.toDate();
      localFlashcardSet.isSynced = false;
      await _localDb.saveFlashcardSet(localFlashcardSet);
    }
    
    // Try to update in Firestore if online
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('flashcard_sets')
          .doc(flashcardSetId)
          .update({
            'title': title,
            'flashcards': flashcards.map((f) => f.toJson()).toList(),
            'timestamp': timestamp,
          });
      
      // Mark as synced
      await _localDb.updateFlashcardSetSyncStatus(flashcardSetId, true);
    } catch (e) {
      // If offline, it will be synced later
      print('Error updating flashcard set in Firestore: $e');
    }
  }
}