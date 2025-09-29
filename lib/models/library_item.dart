import 'package:cloud_firestore/cloud_firestore.dart';

enum LibraryItemType { summary, quiz, flashcards }

class LibraryItem {
  final String id;
  final String title;
  final LibraryItemType type;
  final Timestamp timestamp;
  final List<String> folderIds; // IDs of folders this item belongs to

  LibraryItem({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    this.folderIds = const [],
  });
}