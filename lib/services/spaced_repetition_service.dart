import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spaced_repetition.dart';
import '../models/flashcard_model.dart';
import 'local_database_service.dart';

class SpacedRepetitionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  static final SpacedRepetitionService _instance = SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  /// Initialize a new spaced repetition item for a flashcard
  Future<SpacedRepetitionItem> initializeSpacedRepetition(
    String flashcardId,
    String userId,
  ) async {
    final now = DateTime.now();
    final item = SpacedRepetitionItem(
      id: 'sr_$flashcardId',
      flashcardId: flashcardId,
      userId: userId,
      nextReviewDate: now, // Available for review immediately
      interval: 1, // 1 day
      easeFactor: 2.5, // Default ease factor
      repetitionCount: 0, // Never reviewed
      lastReviewed: now,
      createdAt: now,
      updatedAt: now,
    );

    // Save to local database
    await _localDb.saveSpacedRepetitionItem(item);
    
    return item;
  }

  /// Get flashcards that are due for review
  Future<List<Flashcard>> getDueFlashcards(String userId) async {
    final now = DateTime.now();
    final dueItems = await _localDb.getDueSpacedRepetitionItems(userId, now);
    
    final flashcards = <Flashcard>[];
    for (final item in dueItems) {
      try {
        final flashcardDoc = await _db
            .collection('users')
            .doc(userId)
            .collection('flashcard_sets')
            .doc(item.flashcardId)
            .get();
        
        if (flashcardDoc.exists) {
          final flashcardSet = FlashcardSet.fromFirestore(flashcardDoc);
          // Find the specific flashcard in the set
          final flashcard = flashcardSet.flashcards.firstWhere(
            (fc) => fc.id == item.flashcardId,
            orElse: () => flashcardSet.flashcards.first,
          );
          flashcards.add(flashcard);
        }
      } catch (e) {
        print('Error fetching flashcard: $e');
      }
    }
    
    return flashcards;
  }

  /// Process a review response using the SM-2 algorithm
  Future<void> processReview(
    String flashcardId,
    String userId,
    int quality, // 0-5 rating (0 = complete blackout, 5 = perfect response)
  ) async {
    // Get the current spaced repetition item
    SpacedRepetitionItem? item = 
        await _localDb.getSpacedRepetitionItem('sr_$flashcardId');
    
    if (item == null) {
      // Initialize if not exists
      item = await initializeSpacedRepetition(flashcardId, userId);
    }

    final now = DateTime.now();
    
    // Calculate new values based on SM-2 algorithm
    int newInterval;
    double newEaseFactor = item.easeFactor;
    int newRepetitionCount = item.repetitionCount;

    if (quality >= 3) {
      // Correct response
      if (item.repetitionCount == 0) {
        newInterval = 1; // 1 day
      } else if (item.repetitionCount == 1) {
        newInterval = 6; // 6 days
      } else {
        newInterval = (item.interval * item.easeFactor).round();
      }
      
      newRepetitionCount = item.repetitionCount + 1;
      
      // Adjust ease factor
      newEaseFactor = item.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    } else {
      // Incorrect response
      newRepetitionCount = 0;
      newInterval = 1; // Reset to 1 day
      
      // Decrease ease factor
      newEaseFactor = item.easeFactor - 0.2;
    }

    // Ensure ease factor doesn't go below 1.3
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    // Calculate next review date
    final nextReviewDate = now.add(Duration(days: newInterval));

    // Update the item
    final updatedItem = SpacedRepetitionItem(
      id: item.id,
      flashcardId: item.flashcardId,
      userId: item.userId,
      nextReviewDate: nextReviewDate,
      interval: newInterval,
      easeFactor: newEaseFactor,
      repetitionCount: newRepetitionCount,
      lastReviewed: now,
      createdAt: item.createdAt,
      updatedAt: now,
    );

    // Save updated item
    await _localDb.saveSpacedRepetitionItem(updatedItem);
  }

  /// Get statistics for spaced repetition
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final now = DateTime.now();
    final allItems = await _localDb.getAllSpacedRepetitionItems(userId);
    final dueItems = await _localDb.getDueSpacedRepetitionItems(userId, now);
    
    return {
      'totalCards': allItems.length,
      'dueCards': dueItems.length,
      'reviewedToday': allItems.where((item) => 
        item.lastReviewed.day == now.day && 
        item.lastReviewed.month == now.month && 
        item.lastReviewed.year == now.year
      ).length,
    };
  }
}