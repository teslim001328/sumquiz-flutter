import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' hide Summary;
import 'dart:developer' as developer;

import '../models/summary_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question.dart';

class AIService {
  // Use the new FirebaseAI.googleAI() factory
  final GenerativeModel _model;

  // Initialize the model in the constructor with a specific model name
  AIService() : _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');

  /// Generates a summary from the given text and/or PDF document.
  Future<String> generateSummary(String text, {Uint8List? pdfBytes}) async {
    try {
      final List<Part> parts = [];

      if (pdfBytes != null) {
        parts.add(DataPart('application/pdf', pdfBytes));
      }
      if (text.isNotEmpty) {
        parts.add(TextPart(text));
      }

      if (parts.isEmpty) {
        return "Error: No content provided. Please enter text or upload a PDF.";
      }

      final response = await _model.generateContent([
        Content.multi(parts),
        Content.text(
            'Summarize the provided content. Extract the main title, a list of relevant tags, and the summary content. Return a JSON object with "title", "tags", and "content" keys. Do not include markdown formatting.'),
      ]);

      if (response.text == null) {
        return "Error: Could not generate a summary from the provided content. The model returned no response.";
      }

      developer.log('AI Summary Response: ${response.text}', name: 'my_app.ai_service');

      // The response should be a clean JSON string, ready for parsing.
      return response.text!;

    } catch (e, s) {
      developer.log('Error generating summary', name: 'my_app.ai_service', error: e, stackTrace: s);
      // Return a JSON-formatted error
      return jsonEncode({
        'error': 'An unexpected error occurred while generating the summary. Please check the logs.',
      });
    }
  }

  /// Generates a quiz from a given summary.
  Future<Quiz> generateQuizFromSummary(Summary summary) async {
    try {
      const promptText =
          'Based on the following summary, generate a 10-question multiple-choice quiz. '
          'For each question, provide 4 options and indicate the correct answer. '
          'Return the quiz as a single, clean JSON object with a "title" and a "questions" array. '
          'Each question object should have "question", "options", and "correctAnswer" keys. '
          'The options should be an array of strings. The correctAnswer should be one of those strings. '
          'Do not include any markdown formatting (like ```json) in your response. Just the raw JSON.';

      final response = await _model.generateContent([
        Content.text(promptText),
        Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text == null) {
        throw Exception('Failed to generate quiz: Model returned no response.');
      }

      developer.log('AI Quiz Response: ${response.text}', name: 'my_app.ai_service');

      final quizData = json.decode(response.text!) as Map<String, dynamic>;

      final questions = (quizData['questions'] as List<dynamic>).map((q) {
        final options = (q['options'] as List<dynamic>).cast<String>();
        final correctAnswer = q['correctAnswer'] as String;

        if (!options.contains(correctAnswer)) {
          options[0] = correctAnswer;
        }

        return QuizQuestion(
          question: q['question'] as String,
          options: options,
          correctAnswer: correctAnswer,
        );
      }).toList();

      return Quiz(
        id: '', // Firestore will generate this
        userId: summary.userId,
        title: quizData['title'] as String,
        questions: questions,
        timestamp: DateTime.now(),
      );
    } catch (e, s) {
      developer.log('Error generating quiz', name: 'my_app.ai_service', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Provides AI-powered suggestions for improving a piece of text.
  Future<String> getSuggestion(String text) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    if (text.isEmpty) {
      return 'Start writing to get suggestions!';
    }
    
    try {
      final response = await _model.generateContent([
        Content.text('Given the following text, provide a concise suggestion to improve it: "$text"'),
      ]);
      return response.text ?? 'No suggestion available.';
    } catch (e) {
      return 'Error getting suggestion: $e';
    }
  }
}
