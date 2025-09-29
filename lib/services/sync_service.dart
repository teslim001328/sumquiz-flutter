import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database_service.dart';
import '../models/local_summary.dart';
import '../models/local_quiz.dart';
import '../models/local_flashcard_set.dart';
import '../models/summary_model.dart';
import '../models/quiz_model.dart';
import '../models/flashcard_model.dart';
import '../models/quiz_question.dart';
import '../models/flashcard.dart';

class SyncService {
  final LocalDatabaseService _localDb;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SyncService(this._localDb);

  Future<void> syncAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Sync summaries
      await _syncSummaries(user.uid);
      
      // Sync quizzes
      await _syncQuizzes(user.uid);
      
      // Sync flashcard sets
      await _syncFlashcardSets(user.uid);
    } catch (e) {
      // Handle sync error
      print('Error during sync: $e');
    }
  }

  Future<void> _syncSummaries(String userId) async {
    // Get all unsynced summaries
    final localSummaries = await _localDb.getAllSummaries(userId);
    final unsyncedSummaries = localSummaries.where((s) => !s.isSynced).toList();

    for (final localSummary in unsyncedSummaries) {
      try {
        final summary = Summary(
          id: localSummary.id,
          content: localSummary.content,
          timestamp: Timestamp.fromDate(localSummary.timestamp),
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('summaries')
            .doc(localSummary.id)
            .set(summary.toJson());

        // Mark as synced locally
        await _localDb.updateSummarySyncStatus(localSummary.id, true);
      } catch (e) {
        print('Error syncing summary ${localSummary.id}: $e');
      }
    }

    // Get summaries from Firestore that don't exist locally
    final firestoreSummaries = await _firestore
        .collection('users')
        .doc(userId)
        .collection('summaries')
        .get();

    for (final doc in firestoreSummaries.docs) {
      final localSummary = await _localDb.getSummary(doc.id);
      if (localSummary == null) {
        // Summary exists in Firestore but not locally, download it
        final summary = Summary.fromFirestore(doc);
        final localSummary = LocalSummary(
          id: summary.id,
          content: summary.content,
          timestamp: summary.timestamp.toDate(),
          isSynced: true,
          userId: userId,
        );
        await _localDb.saveSummary(localSummary);
      } else {
        // Check if Firestore version is newer
        final firestoreSummary = Summary.fromFirestore(doc);
        if (firestoreSummary.timestamp.toDate().isAfter(localSummary.timestamp)) {
          // Update local version
          localSummary.content = firestoreSummary.content;
          localSummary.timestamp = firestoreSummary.timestamp.toDate();
          localSummary.isSynced = true;
          await _localDb.saveSummary(localSummary);
        }
      }
    }
  }

  Future<void> _syncQuizzes(String userId) async {
    // Get all unsynced quizzes
    final localQuizzes = await _localDb.getAllQuizzes(userId);
    final unsyncedQuizzes = localQuizzes.where((q) => !q.isSynced).toList();

    for (final localQuiz in unsyncedQuizzes) {
      try {
        final quiz = Quiz(
          id: localQuiz.id,
          title: localQuiz.title,
          questions: localQuiz.questions
              .map((q) => QuizQuestion(
                    question: q.question,
                    options: q.options,
                    correctAnswer: q.correctAnswer,
                  ))
              .toList(),
          timestamp: Timestamp.fromDate(localQuiz.timestamp),
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('quizzes')
            .doc(localQuiz.id)
            .set(quiz.toJson());

        // Mark as synced locally
        await _localDb.updateQuizSyncStatus(localQuiz.id, true);
      } catch (e) {
        print('Error syncing quiz ${localQuiz.id}: $e');
      }
    }

    // Get quizzes from Firestore that don't exist locally
    final firestoreQuizzes = await _firestore
        .collection('users')
        .doc(userId)
        .collection('quizzes')
        .get();

    for (final doc in firestoreQuizzes.docs) {
      final localQuiz = await _localDb.getQuiz(doc.id);
      if (localQuiz == null) {
        // Quiz exists in Firestore but not locally, download it
        final quiz = Quiz.fromFirestore(doc);
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
          isSynced: true,
          userId: userId,
        );
        await _localDb.saveQuiz(localQuiz);
      } else {
        // Check if Firestore version is newer
        final firestoreQuiz = Quiz.fromFirestore(doc);
        if (firestoreQuiz.timestamp.toDate().isAfter(localQuiz.timestamp)) {
          // Update local version
          localQuiz.title = firestoreQuiz.title;
          localQuiz.questions = firestoreQuiz.questions
              .map((q) => LocalQuizQuestion(
                    question: q.question,
                    options: q.options,
                    correctAnswer: q.correctAnswer,
                  ))
              .toList();
          localQuiz.timestamp = firestoreQuiz.timestamp.toDate();
          localQuiz.isSynced = true;
          await _localDb.saveQuiz(localQuiz);
        }
      }
    }
  }

  Future<void> _syncFlashcardSets(String userId) async {
    // Get all unsynced flashcard sets
    final localFlashcardSets = await _localDb.getAllFlashcardSets(userId);
    final unsyncedFlashcardSets = localFlashcardSets.where((fs) => !fs.isSynced).toList();

    for (final localFlashcardSet in unsyncedFlashcardSets) {
      try {
        final flashcardSet = FlashcardSet(
          id: localFlashcardSet.id,
          title: localFlashcardSet.title,
          flashcards: localFlashcardSet.flashcards
              .map((f) => Flashcard(
                    question: f.question,
                    answer: f.answer,
                  ))
              .toList(),
          timestamp: Timestamp.fromDate(localFlashcardSet.timestamp),
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('flashcard_sets')
            .doc(localFlashcardSet.id)
            .set(flashcardSet.toJson());

        // Mark as synced locally
        await _localDb.updateFlashcardSetSyncStatus(localFlashcardSet.id, true);
      } catch (e) {
        print('Error syncing flashcard set ${localFlashcardSet.id}: $e');
      }
    }

    // Get flashcard sets from Firestore that don't exist locally
    final firestoreFlashcardSets = await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcard_sets')
        .get();

    for (final doc in firestoreFlashcardSets.docs) {
      final localFlashcardSet = await _localDb.getFlashcardSet(doc.id);
      if (localFlashcardSet == null) {
        // Flashcard set exists in Firestore but not locally, download it
        final flashcardSet = FlashcardSet.fromFirestore(doc);
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
          isSynced: true,
          userId: userId,
        );
        await _localDb.saveFlashcardSet(localFlashcardSet);
      } else {
        // Check if Firestore version is newer
        final firestoreFlashcardSet = FlashcardSet.fromFirestore(doc);
        if (firestoreFlashcardSet.timestamp.toDate().isAfter(localFlashcardSet.timestamp)) {
          // Update local version
          localFlashcardSet.title = firestoreFlashcardSet.title;
          localFlashcardSet.flashcards = firestoreFlashcardSet.flashcards
              .map((f) => LocalFlashcard(
                    question: f.question,
                    answer: f.answer,
                  ))
              .toList();
          localFlashcardSet.timestamp = firestoreFlashcardSet.timestamp.toDate();
          localFlashcardSet.isSynced = true;
          await _localDb.saveFlashcardSet(localFlashcardSet);
        }
      }
    }
  }

  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}