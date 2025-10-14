import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:myapp/models/summary_model.dart' as model_summary;

import '../models/flashcard.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question.dart';
import 'dart:developer' as developer;

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);
  @override
  String toString() => message;
}

class AIConfig {
  static const String textModel = 'gemini-1.5-flash';
  static const String visionModel = 'gemini-1.5-flash';
  static const int maxRetries = 3;
  static const int requestTimeout = 30;
  static const int maxInputLength = 10000;
  static const int maxPdfSize = 10 * 1024 * 1024; // 10MB limit
}

class AIService {
  final FirebaseAI _firebaseAI;
  final ImagePicker _imagePicker;

  AIService({FirebaseAI? firebaseAI, ImagePicker? imagePicker})
      : _firebaseAI = firebaseAI ?? FirebaseAI.vertexAI(),
        _imagePicker = imagePicker ?? ImagePicker();

  GenerativeModel _createModel(String modelName) {
    return _firebaseAI.generativeModel(
      model: modelName,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium,
            HarmBlockMethod.severity),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium,
            HarmBlockMethod.severity),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium,
            HarmBlockMethod.severity),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium,
            HarmBlockMethod.severity),
      ],
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  Future<T> _retryWithBackoff<T>(Future<T> Function() operation,
      {int maxRetries = AIConfig.maxRetries}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } on TimeoutException {
        throw AIServiceException('Request timed out. Please try again.');
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        final delay = Duration(seconds: pow(2, attempt).toInt());
        developer.log('Retry attempt $attempt after $delay',
            name: 'my_app.ai_service');
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  String _cleanJsonResponse(String text) {
    text = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*$'), '');
    text = text.replaceAll('```', '').trim();
    try {
      json.decode(text);
      return text;
    } catch (e) {
      throw FormatException('Response is not valid JSON: $text');
    }
  }

  String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[\n\r]+'), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  Future<String> getSuggestion(String text) async {
    if (text.trim().isEmpty) {
      throw AIServiceException('Cannot provide suggestions for empty text.');
    }
    if (text.length > AIConfig.maxInputLength) {
      throw AIServiceException(
          'Text too long. Maximum length is ${AIConfig.maxInputLength} characters.');
    }

    final model = _createModel(AIConfig.textModel);
    final prompt =
        'Provide a suggestion to improve the following text: ${_sanitizeInput(text)}';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: AIConfig.requestTimeout)));
      if (response.text == null || response.text!.isEmpty) {
        throw AIServiceException('Model returned empty response.');
      }
      return response.text!;
    } on TimeoutException {
      throw AIServiceException('Request timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('quota')) {
        throw AIServiceException('API quota exceeded. Please try again later.');
      } else if (e.toString().contains('permission')) {
        throw AIServiceException(
            'Permission denied. Check Firebase configuration.');
      }
      developer.log('Error getting suggestion',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException('Failed to get suggestion: ${e.toString()}');
    }
  }

  Future<String> generateSummary(String text, {Uint8List? pdfBytes}) async {
    if (pdfBytes != null) {
      if (pdfBytes.length > AIConfig.maxPdfSize) {
        throw AIServiceException('PDF file too large. Maximum size is 10MB.');
      }
      try {
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        text = PdfTextExtractor(document).extractText();
        document.dispose();
      } catch (e) {
        throw AIServiceException(
            'Failed to extract text from PDF: ${e.toString()}');
      }
    }

    if (text.trim().isEmpty) {
      throw AIServiceException('No text provided for summary generation.');
    }
    if (text.length > AIConfig.maxInputLength) {
      throw AIServiceException(
          'Text too long. Maximum length is ${AIConfig.maxInputLength} characters.');
    }

    final model = _createModel(AIConfig.textModel);
    final prompt =
        'Summarize the following text, and provide a title and three relevant tags in JSON format: { "title": "...", "content": "...", "tags": ["...", "...", "..."] }. Text: ${_sanitizeInput(text)}';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: AIConfig.requestTimeout)));
      if (response.text == null || response.text!.isEmpty) {
        throw AIServiceException('Model returned empty response.');
      }
      final jsonString = _cleanJsonResponse(response.text!);
      return jsonString;
    } on FormatException catch (e) {
      developer.log('JSON parsing error in summary',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException(
          'Failed to parse summary data. Please try again.');
    } on TimeoutException {
      throw AIServiceException('Request timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('quota')) {
        throw AIServiceException('API quota exceeded. Please try again later.');
      } else if (e.toString().contains('permission')) {
        throw AIServiceException(
            'Permission denied. Check Firebase configuration.');
      }
      developer.log('Error generating summary',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException('Failed to generate summary: ${e.toString()}');
    }
  }

  Future<List<Flashcard>> generateFlashcards(
      model_summary.Summary summary) async {
    final model = _createModel(AIConfig.textModel);
    final prompt =
        'Based on the following summary, generate a list of flashcards in JSON format: { "flashcards": [{"question": "...", "answer": "..."}] }. Summary: ${_sanitizeInput(summary.content)}';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: AIConfig.requestTimeout)));
      if (response.text != null) {
        final jsonString = _cleanJsonResponse(response.text!);
        final decoded = json.decode(jsonString);
        final flashcardsData = decoded['flashcards'] as List;

        return flashcardsData.map((data) {
          return Flashcard(
            question: data['question'] as String,
            answer: data['answer'] as String,
          );
        }).toList();
      } else {
        return [];
      }
    } on FormatException catch (e) {
      developer.log('JSON parsing error in flashcards',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException(
          'Failed to parse flashcard data. Please try again.');
    } on TimeoutException {
      throw AIServiceException('Request timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('quota')) {
        throw AIServiceException('API quota exceeded. Please try again later.');
      } else if (e.toString().contains('permission')) {
        throw AIServiceException(
            'Permission denied. Check Firebase configuration.');
      }
      developer.log('Error generating flashcards',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException(
          'Failed to generate flashcards: ${e.toString()}');
    }
  }

  Future<Quiz> generateQuizFromSummary(model_summary.Summary summary) async {
    final model = _createModel(AIConfig.textModel);
    final prompt =
        'Create a multiple-choice quiz from this summary: ${_sanitizeInput(summary.content)}. Return in JSON format: { "title": "Quiz Title", "questions": [ { "question": "What is...?", "options": ["A", "B", "C", "D"], "correctAnswer": "A" } ] }';

    try {
      final response = await _retryWithBackoff(() => model
          .generateContent([Content.text(prompt)]).timeout(
              const Duration(seconds: AIConfig.requestTimeout)));

      if (response.text == null) {
        throw AIServiceException(
            'Failed to generate quiz: No response from model');
      }

      final jsonString = _cleanJsonResponse(response.text!);
      final decoded = json.decode(jsonString);
      final quizData = decoded as Map<String, dynamic>;
      final questionsData = quizData['questions'] as List;

      final questions = questionsData.map((data) {
        final questionText = data['question'] as String;
        final options = List<String>.from(data['options'] as List);
        final correctAnswer = data['correctAnswer'] as String;
        return QuizQuestion(
          question: questionText,
          options: options,
          correctAnswer: correctAnswer,
        );
      }).toList();

      return Quiz(
        id: '',
        userId: summary.userId,
        title: quizData['title'] as String,
        questions: questions,
        timestamp: Timestamp.now(),
      );
    } on FormatException catch (e) {
      developer.log('JSON parsing error in quiz',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException('Failed to parse quiz data. Please try again.');
    } on TimeoutException {
      throw AIServiceException('Request timed out. Please try again.');
    } catch (e, s) {
      if (e.toString().contains('quota')) {
        throw AIServiceException('API quota exceeded. Please try again later.');
      } else if (e.toString().contains('permission')) {
        throw AIServiceException(
            'Permission denied. Check Firebase configuration.');
      }
      developer.log('Error generating quiz',
          name: 'my_app.ai_service', error: e, stackTrace: s);
      throw AIServiceException('Failed to generate quiz: ${e.toString()}');
    }
  }

  Future<Uint8List?> pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return null;
  }

  Future<String> describeImage(Uint8List imageBytes) async {
    final model = _createModel(AIConfig.visionModel);
    final imagePart = InlineDataPart('image/jpeg', imageBytes);
    final prompt = 'Describe this image.';
    try {
      final response = await _retryWithBackoff(() => model.generateContent([
            Content('user', [TextPart(prompt), imagePart])
          ]).timeout(const Duration(seconds: AIConfig.requestTimeout)));
      return response.text ?? 'Could not describe image.';
    } on TimeoutException {
      throw AIServiceException('Request timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('quota')) {
        throw AIServiceException('API quota exceeded. Please try again later.');
      } else if (e.toString().contains('permission')) {
        throw AIServiceException(
            'Permission denied. Check Firebase configuration.');
      }
      developer.log('Error describing image',
          name: 'my_app.ai_service', error: e);
      throw AIServiceException('Failed to describe image: ${e.toString()}');
    }
  }
}
