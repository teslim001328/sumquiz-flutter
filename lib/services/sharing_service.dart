import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/summary_model.dart';
import '../models/quiz_model.dart';
import '../models/flashcard_model.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();
  factory SharingService() => _instance;
  SharingService._internal();

  Future<void> shareSummary(Summary summary) async {
    try {
      // Create a temporary text file with the summary content
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/summary_${summary.id}.txt';
      final file = File(filePath);
      await file.writeAsString(summary.content);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Summary: ${summary.content.substring(0, summary.content.length > 50 ? 50 : summary.content.length)}...',
        text: 'Check out this summary I created with SumQuiz!',
      );
    } catch (e) {
      print('Error sharing summary: $e');
      rethrow;
    }
  }

  Future<void> shareQuiz(Quiz quiz) async {
    try {
      // Create a formatted text representation of the quiz
      final buffer = StringBuffer();
      buffer.writeln('Quiz: ${quiz.title}');
      buffer.writeln('=' * quiz.title.length);
      buffer.writeln();
      
      for (int i = 0; i < quiz.questions.length; i++) {
        final question = quiz.questions[i];
        buffer.writeln('${i + 1}. ${question.question}');
        for (int j = 0; j < question.options.length; j++) {
          buffer.writeln('   ${String.fromCharCode(65 + j)}. ${question.options[j]}');
        }
        buffer.writeln();
      }
      
      // Create a temporary text file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/quiz_${quiz.id}.txt';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Quiz: ${quiz.title}',
        text: 'Check out this quiz I created with SumQuiz!',
      );
    } catch (e) {
      print('Error sharing quiz: $e');
      rethrow;
    }
  }

  Future<void> shareFlashcardSet(FlashcardSet flashcardSet) async {
    try {
      // Create a formatted text representation of the flashcards
      final buffer = StringBuffer();
      buffer.writeln('Flashcard Set: ${flashcardSet.title}');
      buffer.writeln('=' * flashcardSet.title.length);
      buffer.writeln();
      
      for (int i = 0; i < flashcardSet.flashcards.length; i++) {
        final flashcard = flashcardSet.flashcards[i];
        buffer.writeln('Question ${i + 1}: ${flashcard.question}');
        buffer.writeln('Answer: ${flashcard.answer}');
        buffer.writeln('-' * 20);
        buffer.writeln();
      }
      
      // Create a temporary text file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/flashcards_${flashcardSet.id}.txt';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Flashcards: ${flashcardSet.title}',
        text: 'Check out these flashcards I created with SumQuiz!',
      );
    } catch (e) {
      print('Error sharing flashcards: $e');
      rethrow;
    }
  }

  Future<void> shareText(String text, String subject) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      print('Error sharing text: $e');
      rethrow;
    }
  }
}