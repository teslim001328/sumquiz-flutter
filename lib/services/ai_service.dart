import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart' as vertex;
import 'package:flutter/foundation.dart' hide Summary;
import 'package:myapp/models/flashcard.dart';
import 'package:myapp/models/quiz_model.dart';
import 'package:myapp/models/summary_model.dart';

class AIService {
  final vertex.GenerativeModel _model;

  AIService()
      : _model = vertex.FirebaseVertexAI.instance
            .generativeModel(model: 'gemini-1.5-pro');

  Future<List<Flashcard>> generateFlashcards(Summary summary) async {
    try {
      final prompt =
          'Generate a list of flashcards based on the following summary. '
          'Provide the output in JSON format with the following structure: '
          '[{"question": "...", "answer": "..."}, {"question": "...", "answer": "..."}]';

      final response = await _model.generateContent([
        vertex.Content.text(prompt),
        vertex.Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text != null) {
        String jsonString = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(jsonString);
        final flashcards = jsonResponse
            .map((json) => Flashcard.fromMap(json))
            .toList();
        return flashcards;
      } else {
        throw Exception('Failed to generate flashcards: No response from model.');
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      return Future.error('Error generating flashcards: $e');
    }
  }

  Future<Quiz> generateQuizFromSummary(Summary summary) async {
    try {
      final prompt =
          'Generate a 10-question multiple-choice quiz based on the following summary. '
          'Provide the output in JSON format with the following structure: '
          '{"title": "Quiz Title", "questions": [{"question": "...", "options": ["...", "...", "..."], "correctAnswer": "..."}]}';

      final response = await _model.generateContent([
        vertex.Content.text(prompt),
        vertex.Content.text('Summary: ${summary.content}'),
      ]);

      if (response.text != null) {
        String jsonString = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final jsonResponse = jsonDecode(jsonString);
        final quiz = Quiz.fromMap(jsonResponse);
        return quiz;
      } else {
        throw Exception('Failed to generate quiz: No response from model.');
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      return Future.error('Error generating quiz: $e');
    }
  }

  Future<String> generateSummary(String text, {Uint8List? pdfBytes}) async {
    try {
      const prompt =
          'Provide a concise summary of the following content. Focus on the key points and main ideas.';

      final content = <vertex.Part>[vertex.TextPart(prompt)];

      if (pdfBytes != null) {
        content.add(vertex.DataPart('application/pdf', pdfBytes));
        if (text.isNotEmpty) {
          content.add(vertex.TextPart('Also consider the following text: $text'));
        }
      } else if (text.isNotEmpty) {
        content.add(vertex.TextPart(text));
      } else {
        return 'Error: No content provided for summary.';
      }

      final response = await _model.generateContent([vertex.Content.multi(content)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Error generating summary: The model returned an empty response.';
      }
    } catch (e) {
      final errorMessage = 'Error generating summary: $e';
      debugPrint(errorMessage);
      return errorMessage;
    }
  }

  Future<List<dynamic>> generateQuiz(String text) async {
    // This is a placeholder implementation.
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
