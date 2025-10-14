import 'package:cloud_firestore/cloud_firestore.dart';

class Summary {
  final String id;
  final String userId;
  String title;
  String content;
  final Timestamp timestamp;
  List<String> tags;

  Summary({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.timestamp,
    this.tags = const [],
  });

  factory Summary.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'tags': tags,
    };
  }
}
