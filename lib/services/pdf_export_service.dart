import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

import '../models/local_summary.dart';
import '../models/local_quiz.dart';
import '../models/local_flashcard_set.dart';

class PdfExportService {
  Future<void> exportSummary(LocalSummary summary) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20);

    page.graphics.drawString(
      summary.id, // Using id as title
      titleFont,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    page.graphics.drawString(
      summary.content,
      font,
      bounds: Rect.fromLTWH(0, 60, page.getClientSize().width, page.getClientSize().height - 60),
    );

    final bytes = await document.save();
    document.dispose();

    await _saveAndLaunchFile(bytes, 'summary_${summary.id}.pdf');
  }

  Future<void> exportQuiz(LocalQuiz quiz) async {
    final PdfDocument document = PdfDocument();
    
    for (var i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      final PdfPage page = document.pages.add();

      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final questionFont = PdfStandardFont(PdfFontFamily.helvetica, 16);

      page.graphics.drawString(
        'Question ${i + 1}:', 
        questionFont,
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30)
      );
      page.graphics.drawString(
        question.question, 
        questionFont, 
        bounds: Rect.fromLTWH(0, 30, page.getClientSize().width, 60)
      );

      double y = 100;
      for (var j = 0; j < question.options.length; j++) {
        final option = question.options[j];
        final isCorrect = option == question.correctAnswer;
        final optionText = '${String.fromCharCode(65 + j)}. $option';
        
        final graphics = page.graphics;

        graphics.drawString(
          optionText, 
          font, 
          bounds: Rect.fromLTWH(20, y, page.getClientSize().width - 20, 20),
          brush: isCorrect ? PdfBrushes.green : PdfBrushes.black
        );
        y += 25;
      }
    }

    final bytes = await document.save();
    document.dispose();

    await _saveAndLaunchFile(bytes, 'quiz_${quiz.id}.pdf');
  }

  Future<void> exportFlashcardSet(LocalFlashcardSet flashcardSet) async {
    final PdfDocument document = PdfDocument();

    for (final flashcard in flashcardSet.flashcards) {
      final PdfPage page = document.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 14);
      final termFont = PdfStandardFont(PdfFontFamily.helvetica, 18);

      // Draw term
      page.graphics.drawString(
        'Term:', 
        termFont, 
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30)
      );
      page.graphics.drawString(
        flashcard.question, 
        termFont, 
        bounds: Rect.fromLTWH(0, 30, page.getClientSize().width, 100)
      );
      
      // Draw definition
      page.graphics.drawString(
        'Definition:', 
        font, 
        bounds: Rect.fromLTWH(0, 150, page.getClientSize().width, 30)
      );
      page.graphics.drawString(
        flashcard.answer, 
        font, 
        bounds: Rect.fromLTWH(0, 180, page.getClientSize().width, 200)
      );
    }

    final bytes = await document.save();
    document.dispose();

    await _saveAndLaunchFile(bytes, 'flashcards_${flashcardSet.id}.pdf');
  }

  Future<void> _saveAndLaunchFile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    // Note: Launching the file will require a platform-specific implementation
    // using a package like `open_file` or `url_launcher`.
  }
}
