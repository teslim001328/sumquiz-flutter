import 'package:hive/hive.dart';
import 'dart:math';
import '../models/spaced_repetition_item.dart';
import '../models/local_flashcard.dart';
import 'dart:developer' as developer;

class SpacedRepetitionService {
  final Box<SpacedRepetitionItem> _srsBox;

  SpacedRepetitionService(this._srsBox);

  Future<void> scheduleReview(String flashcardId) async {
    final now = DateTime.now();
    final newItem = SpacedRepetitionItem(
      contentId: flashcardId,
      contentType: 'flashcard',
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

      if (answeredCorrectly) {
        newRepetitionCount = item.repetitionCount + 1;
      } else {
        newRepetitionCount = 0; // Reset progress
      }

      final updatedItem = SpacedRepetitionItem(
        contentId: item.contentId,
        contentType: item.contentType,
        repetitionCount: newRepetitionCount,
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
}
