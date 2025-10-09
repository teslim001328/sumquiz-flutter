import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' hide Summary;
import 'package:myapp/models/flashcard.dart';
import 'package:myapp/models/quiz_model.dart';
import 'package:myapp/models/summary_model.dart';

class AIService {
  final GenerativeModel _model;

  AIService()
      : _model = FirebaseAI.googleAI()
            .generativeModel(model: 'gemini-2.5-pro');

  Future<List<Flashcard>> generateFlashcards(Summary summary) async {
    try {
      const prompt =
          'Generate a list of flashcards based on the following summary. '
          'Provide the output in JSON format with the following structure: '
          '[{"question": "...", "answer": "..."}, {"question": "...", "answer": "..."}]';

      final response = await _model.generateContent([
        Content.text(prompt),
        Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text != null) {
        // Clean the response to remove markdown code fences
        String jsonString = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(jsonString);
        final flashcards =
            jsonResponse.map((json) => Flashcard.fromMap(json)).toList();
        return flashcards;
      } else {
        throw Exception('No response from model.');
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    }
  }

  Future<Quiz> generateQuizFromSummary(Summary summary) async {
    try {
      const prompt =
          'Generate a 10-question multiple-choice quiz based on the following summary. '
          'Provide the output in JSON format with the following structure: '
          '{"title": "Quiz Title", "questions": [{"question": "...", "options": ["...", "...", "..."], "correctAnswer": "..."}]}';

      final response = await _model.generateContent([
        Content.text(prompt),
        Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text != null) {
        // Clean the response to remove markdown code fences
        String jsonString = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final jsonResponse = jsonDecode(jsonString);
        final quiz = Quiz.fromMap(jsonResponse);
        return quiz;
      } else {
        throw Exception('No response from model.');
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      rethrow;
    }
  }

  Future<String> generateSummary(String text, {Uint8List? pdfBytes}) async {
    try {
      const prompt =
          'Provide a concise summary of the following content. Focus on the key points and main ideas.';

      final promptParts = <Part>[];
      promptParts.add(const TextPart(prompt));

      if (pdfBytes != null) {
        promptParts.add(InlineDataPart('application/pdf', pdfBytes));
        if (text.isNotEmpty) {
          promptParts.add(TextPart('The user also provided this text as context: $text'));
        }
      } else if (text.isNotEmpty) {
        promptParts.add(TextPart(text));
      } else {
        return 'Error: Provide text or a PDF to summarize.';
      }

      final response = await _model.generateContent([Content('user', promptParts)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Error: Model returned empty response.';
      }
    } catch (e) {
      debugPrint('Error generating summary: $e');
      return 'Error: Unexpected error occurred. See logs.';
    }
  }

  Future<List<dynamic>> generateQuiz(String text) async {
    // Placeholder
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