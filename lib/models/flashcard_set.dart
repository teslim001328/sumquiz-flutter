import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/flashcard.dart';

class FlashcardSet {
  final String id;
  final String title;
  final String summaryId;
  final List<Flashcard> flashcards;
  final Timestamp timestamp;

  FlashcardSet({
    required this.id,
    required this.title,
    required this.summaryId,
    required this.flashcards,
    required this.timestamp,
  });

  factory FlashcardSet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FlashcardSet(
      id: doc.id,
      title: data['title'],
      summaryId: data['summaryId'],
      flashcards: (data['flashcards'] as List)
          .map((f) => Flashcard.fromJson(f))
          .toList(),
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summaryId': summaryId,
      'flashcards': flashcards.map((f) => f.toJson()).toList(),
      'timestamp': timestamp,
    };
  }
}
