import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' hide Summary;
import '../../models/quiz_model.dart';
import '../../models/summary_model.dart';

class AIService {
  final GenerativeModel _model;

  AIService() : _model = FirebaseAI.instance.googleAI().generativeModel(model: 'gemini-1.5-flash');

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
        final jsonResponse = jsonDecode(response.text!);
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
    // In a real application, you would use the AI service to generate a summary.
    await Future.delayed(const Duration(seconds: 2));
    return "This is a generated summary of the provided text.";
  }

  Future<List<dynamic>> generateQuiz(String text) async {
    // This is just a placeholder implementation.
    // In a real application, you would use the AI service to generate a quiz.
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
