import 'package:cloud_firestore/cloud_firestore.dart';

class Summary {
  final String id;
  final String userId;
  final String content;
  final Timestamp timestamp;

  Summary({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
  });

  factory Summary.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
