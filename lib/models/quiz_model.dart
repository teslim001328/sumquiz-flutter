import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String title;
  final List<Map<String, dynamic>> questions;
  final Timestamp timestamp;

  Quiz({required this.id, required this.title, required this.questions, required this.timestamp});

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      questions: List<Map<String, dynamic>>.from(data['questions'] ?? []),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'questions': questions,
      'timestamp': timestamp,
    };
  }
}
