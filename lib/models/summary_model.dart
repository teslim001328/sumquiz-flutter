import 'package:cloud_firestore/cloud_firestore.dart';

class Summary {
  final String id;
  final String content;
  final Timestamp timestamp;

  Summary({required this.id, required this.content, required this.timestamp, required String userId});

  factory Summary.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'timestamp': timestamp,
    };
  }
}
