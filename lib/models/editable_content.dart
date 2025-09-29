import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_question.dart';
import 'flashcard.dart';

/// A model representing editable content that can be updated by the user
class EditableContent {
  final String id;
  final String type; // 'summary', 'quiz', or 'flashcard'
  final String title;
  final String? content; // For summaries
  final List<QuizQuestion>? questions; // For quizzes
  final List<Flashcard>? flashcards; // For flashcards
  final Timestamp timestamp;

  EditableContent({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.questions,
    this.flashcards,
    required this.timestamp,
  });

  /// Create an EditableContent instance from a summary
  factory EditableContent.fromSummary(String id, String content, Timestamp timestamp) {
    return EditableContent(
      id: id,
      type: 'summary',
      title: content.length > 50 ? '${content.substring(0, 50)}...' : content,
      content: content,
      timestamp: timestamp,
    );
  }

  /// Create an EditableContent instance from a quiz
  factory EditableContent.fromQuiz(String id, String title, List<QuizQuestion> questions, Timestamp timestamp) {
    return EditableContent(
      id: id,
      type: 'quiz',
      title: title,
      questions: questions,
      timestamp: timestamp,
    );
  }

  /// Create an EditableContent instance from a flashcard set
  factory EditableContent.fromFlashcardSet(String id, String title, List<Flashcard> flashcards, Timestamp timestamp) {
    return EditableContent(
      id: id,
      type: 'flashcard',
      title: title,
      flashcards: flashcards,
      timestamp: timestamp,
    );
  }
}