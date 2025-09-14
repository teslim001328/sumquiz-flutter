import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/quiz_question.dart';
import '../models/flashcard_model.dart';

class AIService {
  final FirebaseVertexAI _ai;

  AIService(this._ai);

  Future<String> generateSummary(String text, {File? pdfFile}) async {
    final model = _ai.generativeModel(model: 'gemini-1.5-flash');
    String fullText = text;

    if (pdfFile != null) {
      try {
        final Uint8List pdfBytes = await pdfFile.readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        final String pdfText = PdfTextExtractor(document).extractText();
        document.dispose();
        fullText += "\n\n$pdfText";
      } catch (e) {
        print("Error reading PDF: $e");
        return "Error: Could not process the PDF file.";
      }
    }

    if (fullText.trim().isEmpty) {
      return "Error: No content provided for summarization.";
    }

    try {
      final response = await model.generateContent([Content.text(fullText)]);
      return response.text ?? "Error: Could not generate a summary.";
    } catch (e) {
      print("Error generating summary: $e");
      return "Error: An unexpected error occurred while generating the summary.";
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String text) async {
    final model = _ai.generativeModel(model: 'gemini-1.5-flash');
    final prompt = 'Create a multiple-choice quiz from the following text. Return a JSON array of questions, where each object has a "question" string, an "options" array of strings, and a "correct_option" string. Text: $text';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonResponse = json.decode(response.text ?? '');

      if (jsonResponse is List) {
        return jsonResponse.map((data) {
          return QuizQuestion(
            question: data['question'],
            options: List<String>.from(data['options']),
            correctAnswer: data['correct_option'],
          );
        }).toList();
      }
    } catch (e) {
      print("Error generating quiz: $e");
    }

    return [];
  }

  Future<List<Flashcard>> generateFlashcards(String text) async {
    final model = _ai.generativeModel(model: 'gemini-1.5-flash');
    final prompt = 'Create a set of flashcards from the following text. Return a JSON array of flashcards, where each object has a "front" string and a "back" string. Text: $text';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonResponse = json.decode(response.text ?? '');

      if (jsonResponse is List) {
        return jsonResponse.map((data) {
          return Flashcard(
            question: data['front'],
            answer: data['back'],
          );
        }).toList();
      }
    } catch (e) {
      print("Error generating flashcards: $e");
    }

    return [];
  }
}
