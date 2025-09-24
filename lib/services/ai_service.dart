import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quiz_question.dart';
import '../models/flashcard.dart';

class AIService {
  GenerativeModel _getModel() {
    return FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-pro',
      safetySettings: [
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none, null),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none, null),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none, null),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none, null),
      ],
      generationConfig: GenerationConfig(
        maxOutputTokens: 2048,
        temperature: 0.7,
      ),
    );
  }

  bool _isAuthenticated() => FirebaseAuth.instance.currentUser != null;

  Future<String> generateSummary(String text, {File? pdfFile}) async {
    if (!_isAuthenticated()) {
      throw Exception('User must be signed in to use AI features');
    }

    String fullText = text;

    if (pdfFile != null) {
      try {
        final Uint8List pdfBytes = await pdfFile.readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        final String pdfText = PdfTextExtractor(document).extractText();
        document.dispose();
        fullText += "\n\n$pdfText";
      } catch (e) {
        developer.log("Error reading PDF: $e", name: 'AIService.generateSummary');
        return "Error: Could not process the PDF file.";
      }
    }

    if (fullText.trim().isEmpty) {
      return "Error: No content provided for summarization.";
    }

    try {
      final response = await _getModel().generateContent([Content.text('Summarize the following text:\n$fullText')]);
      return response.text?.trim() ?? "Error: Could not generate a summary.";
    } catch (e) {
      developer.log("Error generating summary: $e", name: 'AIService.generateSummary');
      return "Error: An unexpected error occurred while generating the summary.";
    }
  }

  Future<List<QuizQuestion>> generateQuiz(String text) async {
    if (!_isAuthenticated()) {
      throw Exception('User must be signed in to use AI features');
    }

    final prompt = '''
Create a multiple-choice quiz from the following text. The goal is to test understanding of the main concepts. 
Return ONLY a valid JSON array of questions, where each object has:
- "question": string
- "options": array of exactly 4 strings
- "correctAnswer": string (must be one of the provided options)

Do not include any markdown formatting, code blocks, or additional text.

Text: $text''';

    try {
      final response = await _getModel().generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '';
      
      // Clean any potential markdown formatting
      String cleanedJsonString = jsonString;
      if (jsonString.startsWith('```json')) {
        cleanedJsonString = jsonString.substring(7, jsonString.length - 3).trim();
      } else if (jsonString.startsWith('```')) {
        cleanedJsonString = jsonString.substring(3, jsonString.length - 3).trim();
      }

      final jsonResponse = json.decode(cleanedJsonString);

      if (jsonResponse is List) {
        return jsonResponse.map((data) => QuizQuestion.fromJson(data)).toList();
      } else {
        developer.log("Invalid JSON structure: expected List", name: 'AIService.generateQuiz');
        return [];
      }
    } catch (e, s) {
      developer.log("Error decoding quiz JSON: $e", stackTrace: s, name: 'AIService.generateQuiz');
      return [];
    }
  }

  Future<List<Flashcard>> generateFlashcards(String text) async {
    if (!_isAuthenticated()) {
      throw Exception('User must be signed in to use AI features');
    }

    final prompt = '''
Create a set of flashcards from the following text. Focus on key terms and definitions.
Return ONLY a valid JSON array of flashcards, where each object has:
- "question": string
- "answer": string

Do not include any markdown formatting, code blocks, or additional text.

Text: $text''';

    try {
      final response = await _getModel().generateContent([Content.text(prompt)]);
      final jsonString = response.text?.trim() ?? '';

      // Clean any potential markdown formatting
      String cleanedJsonString = jsonString;
      if (jsonString.startsWith('```json')) {
        cleanedJsonString = jsonString.substring(7, jsonString.length - 3).trim();
      } else if (jsonString.startsWith('```')) {
        cleanedJsonString = jsonString.substring(3, jsonString.length - 3).trim();
      }
          
      final jsonResponse = json.decode(cleanedJsonString);

      if (jsonResponse is List) {
        return jsonResponse.map((data) => Flashcard.fromJson(data)).toList();
      } else {
        developer.log("Invalid JSON structure: expected List", name: 'AIService.generateFlashcards');
        return [];
      }
    } catch (e, s) {
      developer.log("Error decoding flashcard JSON: $e", stackTrace: s, name: 'AIService.generateFlashcards');
      return [];
    }
  }
}