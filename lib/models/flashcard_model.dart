import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/flashcard.dart';

class FlashcardSet {
  final String id;
  final String title;
  final List<Flashcard> flashcards;
  final Timestamp timestamp;

  FlashcardSet({
    required this.id,
    required this.title,
    required this.flashcards,
    required this.timestamp,
  });

  factory FlashcardSet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FlashcardSet(
      id: doc.id,
      title: data['title'] ?? '',
      flashcards: (data['flashcards'] as List<dynamic>? ?? [])
          .map((f) => Flashcard.fromJson(f as Map<String, dynamic>))
          .toList(),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'flashcards': flashcards.map((f) => f.toJson()).toList(),
      'timestamp': timestamp,
    };
  }
}
