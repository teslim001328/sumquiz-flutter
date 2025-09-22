import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/quiz_question.dart';
import '../models/flashcard.dart';

class AIService {
  Future<String> generateSummary(String text, {File? pdfFile}) async {
    final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
    String fullText = text;

    if (pdfFile != null) {
      try {
        final Uint8List pdfBytes = await pdfFile.readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        final String pdfText = PdfTextExtractor(document).extractText();
        document.dispose();
        fullText += "\n\n$pdfText";
      } catch (e) {
        developer.log("Error reading PDF: $e");
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
      developer.log("Error generating summary: $e");
      return "Error: An unexpected error occurred while generating the summary.";
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String text) async {
    final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
    final prompt =
        'Create a multiple-choice quiz from the following text. Return a JSON array of questions, where each object has a "question" string, an "options" array of strings, and a "correctAnswer" string. Text: $text';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonResponse = json.decode(response.text ?? '');

      if (jsonResponse is List) {
        return jsonResponse.map((data) {
          return QuizQuestion.fromJson(data);
        }).toList();
      }
    } catch (e, s) {
      developer.log("Error generating quiz: $e", stackTrace: s);
    }

    return [];
  }

  Future<List<Flashcard>> generateFlashcards(String text) async {
    final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
    final prompt =
        'Create a set of flashcards from the following text. Return a JSON array of flashcards, where each object has a "question" string, and an "answer" string. Text: $text';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonResponse = json.decode(response.text ?? '');

      if (jsonResponse is List) {
        return jsonResponse.map((data) {
          return Flashcard.fromJson(data);
        }).toList();
      }
    } catch (e, s) {
      developer.log("Error generating flashcards: $e", stackTrace: s);
    }

    return [];
  }
}
