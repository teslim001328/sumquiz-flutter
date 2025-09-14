import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryItem {
  final String id;
  final String title;
  final String content;
  final Timestamp createdAt;
  final String type;

  LibraryItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.type,
  });

  factory LibraryItem.fromFirestore(DocumentSnapshot doc, String type) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String content = '';

    switch (type) {
      case 'summary':
        content = data['summary'] ?? '';
        break;
      case 'quiz':
        int questionCount = (data['questions'] as List?)?.length ?? 0;
        content = '$questionCount Questions';
        break;
      case 'flashcards':
        int cardCount = (data['cards'] as List?)?.length ?? 0;
        content = '$cardCount Cards';
        break;
    }

    return LibraryItem(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      content: content,
      createdAt: data['created_at'] ?? Timestamp.now(),
      type: type,
    );
  }
}
