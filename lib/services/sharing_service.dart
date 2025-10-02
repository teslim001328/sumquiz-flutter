import 'package:share_plus/share_plus.dart';
import 'dart:developer' as developer;

import '../models/local_summary.dart';
import '../models/local_quiz.dart';
import '../models/local_flashcard_set.dart';
import 'pdf_export_service.dart';

class SharingService {
  final PdfExportService _pdfExportService = PdfExportService();

  Future<void> shareSummary(LocalSummary summary) async {
    try {
      final pdfPath = await _generatePdf(summary, _pdfExportService.exportSummary);
      await Share.shareXFiles([XFile(pdfPath)], text: 'Here is the summary you requested!');
    } catch (e, s) {
      developer.log(
        'Error sharing summary',
        name: 'SharingService',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> shareQuiz(LocalQuiz quiz) async {
    try {
      final pdfPath = await _generatePdf(quiz, _pdfExportService.exportQuiz);
      await Share.shareXFiles([XFile(pdfPath)], text: 'Here is the quiz you requested!');
    } catch (e, s) {
      developer.log(
        'Error sharing quiz',
        name: 'SharingService',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> shareFlashcardSet(LocalFlashcardSet flashcardSet) async {
    try {
      final pdfPath = await _generatePdf(flashcardSet, _pdfExportService.exportFlashcardSet);
      await Share.shareXFiles([XFile(pdfPath)], text: 'Here are the flashcards you requested!');
    } catch (e, s) {
      developer.log(
        'Error sharing flashcard set',
        name: 'SharingService',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e, s) {
      developer.log(
        'Error sharing text',
        name: 'SharingService',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<String> _generatePdf<T>(T data, Future<void> Function(T) exportFunction) async {
    // This is a simplified stand-in for the actual PDF generation logic
    // that would be handled by the PdfExportService.
    await exportFunction(data);
    // In a real implementation, this would return the path to the generated PDF.
    return 'path/to/your/pdf.pdf';
  }
}
