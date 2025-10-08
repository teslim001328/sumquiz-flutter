import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/quiz_question.dart';
import 'package:uuid/uuid.dart';

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final Timestamp timestamp;

  Quiz({
    String? id,
    required this.title,
    required this.questions,
    Timestamp? timestamp,
  })  : id = id ?? Uuid().v4(),
        timestamp = timestamp ?? Timestamp.now();

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      title: map['title'] ?? '',
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'questions': questions.map((q) => q.toFirestore()).toList(),
      'timestamp': timestamp,
    };
  }
}
