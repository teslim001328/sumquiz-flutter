import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' hide Summary;
import '../../models/flashcard_model.dart';
import '../../models/quiz_model.dart';
import '../../models/summary_model.dart';

class AIService {
  final GenerativeModel _model;

  AIService()
      : _model = FirebaseAI.googleAI()
            .generativeModel(model: 'gemini-1.5-flash');

  Future<List<Flashcard>> generateFlashcards(Summary summary) async {
    try {
      final prompt =
          'Generate a list of flashcards based on the following summary. '
          'Provide the output in JSON format with the following structure: '
          '[{"question": "...", "answer": "..."}, {"question": "...", "answer": "..."}]';

      final response = await _model.generateContent([
        Content.text(prompt),
        Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text != null) {
        String jsonString = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(jsonString);
        final flashcards = jsonResponse
            .map((json) => Flashcard.fromJson(json))
            .toList();
        return flashcards;
      } else {
        throw Exception('Failed to generate flashcards: No response from model.');
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    }
  }

  Future<Quiz> generateQuizFromSummary(Summary summary) async {
    try {
      final prompt =
          'Generate a 10-question multiple-choice quiz based on the following summary. '
          'Provide the output in JSON format with the following structure: '
          '{"title": "Quiz Title", "questions": [{"question": "...", "options": ["...", "...", "..."], "correctAnswer": "..."}]}';

      final response = await _model.generateContent([
        Content.text(prompt),
        Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text != null) {
        // The response text might be wrapped in ```json ... ```, so let's strip that.
        String jsonString = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final jsonResponse = jsonDecode(jsonString);
        final quiz = Quiz.fromJson(jsonResponse);
        return quiz;
      } else {
        throw Exception('Failed to generate quiz: No response from model.');
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      rethrow;
    }
  }

  Future<String> generateSummary(String text, {File? pdfFile}) async {
    // This is just a placeholder implementation.
    await Future.delayed(const Duration(seconds: 2));
    return "This is a generated summary of the provided text.";
  }

  Future<List<dynamic>> generateQuiz(String text) async {
    // This is just a placeholder implementation.
    await Future.delayed(const Duration(seconds: 2));
    return [
      {
        "question": "What is the capital of France?",
        "options": ["London", "Paris", "Berlin", "Madrid"],
        "correctAnswer": "Paris"
      },
      {
        "question": "What is the largest planet in our solar system?",
        "options": ["Mars", "Jupiter", "Earth", "Saturn"],
        "correctAnswer": "Jupiter"
      }
    ];
  }
}
