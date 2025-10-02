import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/quiz_question.dart';

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final Timestamp timestamp;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.timestamp,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: '', // Not available from the AI response
      title: json['title'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      timestamp: Timestamp.now(), // Set a default timestamp
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'timestamp': timestamp,
    };
  }
}
