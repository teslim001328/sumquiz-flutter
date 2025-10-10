import 'package:hive/hive.dart';
import 'dart:math';
import '../models/spaced_repetition.dart';
import '../models/local_flashcard.dart';
import 'dart:developer' as developer;

class SpacedRepetitionService {
  final Box<SpacedRepetitionItem> _srsBox;

  SpacedRepetitionService(this._srsBox);

  Future<void> scheduleReview(String flashcardId) async {
    final now = DateTime.now();
    final newItem = SpacedRepetitionItem(
      id: flashcardId, // id is required
      userId: '', // userId is required, you may need to pass this in
      contentId: flashcardId,
      contentType: 'flashcard',
      nextReviewDate: now, // nextReviewDate is required
      lastReviewed: now,
      createdAt: now,
      updatedAt: now,
    );
    await _srsBox.put(flashcardId, newItem);
  }

  Future<List<LocalFlashcard>> getDueFlashcards(List<LocalFlashcard> allFlashcards) async {
    final dueItems = _srsBox.values.where((item) {
      if (item.contentType != 'flashcard') return false;
      final interval = _getInterval(item.repetitionCount);
      final dueDate = item.lastReviewed.add(Duration(days: interval));
      return DateTime.now().isAfter(dueDate);
    }).toList();

    final dueFlashcards = <LocalFlashcard>[];
    for (final item in dueItems) {
      try {
        final flashcard = allFlashcards.firstWhere((fc) => fc.id == item.contentId);
        dueFlashcards.add(flashcard);
      } catch (e) {
        developer.log('Flashcard with id ${item.contentId} not found', name: 'SpacedRepetitionService');
      }
    }
    return dueFlashcards;
  }

  Future<void> updateReview(String flashcardId, bool answeredCorrectly) async {
    final item = _srsBox.get(flashcardId);
    if (item != null) {
      final now = DateTime.now();
      int newRepetitionCount;
      int newCorrectStreak;

      if (answeredCorrectly) {
        newRepetitionCount = item.repetitionCount + 1;
        newCorrectStreak = item.correctStreak + 1;
      } else {
        newRepetitionCount = 0; // Reset progress
        newCorrectStreak = 0;
      }

      final updatedItem = SpacedRepetitionItem(
        id: item.id,
        userId: item.userId,
        contentId: item.contentId,
        contentType: item.contentType,
        nextReviewDate: now.add(Duration(days: _getInterval(newRepetitionCount))),
        repetitionCount: newRepetitionCount,
        correctStreak: newCorrectStreak,
        lastReviewed: now,
        createdAt: item.createdAt,
        updatedAt: now,
      );

      await _srsBox.put(flashcardId, updatedItem);
    }
  }

  int _getInterval(int repetitionCount) {
    if (repetitionCount == 0) return 1;
    if (repetitionCount == 1) return 3;
    return (pow(2, repetitionCount) * 2).toInt();
  }

  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final allItems = _srsBox.values.where((item) => item.userId == userId).toList();

    if (allItems.isEmpty) {
      return {
        'totalReviews': 0,
        'averageCorrectness': 0.0,
        'masteryLevel': 0.0,
        'reviewsOverTime': [],
      };
    }

    final totalReviews = allItems.length;
    final correctReviews = allItems.where((item) => item.correctStreak > 0).length;
    final averageCorrectness = totalReviews > 0 ? correctReviews / totalReviews : 0.0;
    final totalCorrectStreaks = allItems.fold<int>(0, (prev, item) => prev + item.correctStreak);
    final masteryLevel = totalReviews > 0 ? totalCorrectStreaks / totalReviews : 0.0;

    // Group reviews by day
    final reviewsOverTime = <DateTime, int>{};
    for (final item in allItems) {
      final date = DateTime(item.lastReviewed.year, item.lastReviewed.month, item.lastReviewed.day);
      reviewsOverTime[date] = (reviewsOverTime[date] ?? 0) + 1;
    }

    final sortedReviews = reviewsOverTime.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return {
      'totalReviews': totalReviews,
      'averageCorrectness': averageCorrectness,
      'masteryLevel': masteryLevel,
      'reviewsOverTime': sortedReviews,
    };
  }
}
