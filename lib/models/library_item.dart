import 'package:cloud_firestore/cloud_firestore.dart';

enum LibraryItemType { summary, quiz, flashcards }

class LibraryItem {
  final String id;
  final String title;
  final LibraryItemType type;
  final Timestamp timestamp;

  LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
  });
}
