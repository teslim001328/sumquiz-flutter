import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/summary_model.dart';
import '../models/quiz_model.dart';
import '../models/flashcard_model.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  Future<String> exportSummary(Summary summary) async {
    // Create a new PDF document
    final pdf = PdfDocument();
    
    // Add a page to the document
    final page = pdf.pages.add();
    
    // Get page graphics
    final graphics = page.graphics;
    
    // Set font
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    
    // Draw title
    graphics.drawString(
      'Summary',
      titleFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    
    // Draw content
    graphics.drawString(
      summary.content,
      font,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(20, 50, page.getClientSize().width - 40, page.getClientSize().height - 70),
    );
    
    // Save the document
    final List<int> bytes = await pdf.save();
    pdf.dispose();
    
    // Get directory for saving the file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/summary_${summary.id}.pdf';
    
    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    return filePath;
  }

  Future<String> exportQuiz(Quiz quiz) async {
    // Create a new PDF document
    final pdf = PdfDocument();
    
    // Add a page to the document
    final page = pdf.pages.add();
    
    // Get page graphics
    final graphics = page.graphics;
    
    // Set fonts
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final questionFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    
    // Draw title
    graphics.drawString(
      quiz.title,
      titleFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    
    // Draw questions
    double yPosition = 50;
    for (int i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      
      // Draw question
      graphics.drawString(
        '${i + 1}. ${question.question}',
        questionFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(20, yPosition, page.getClientSize().width - 40, 20),
      );
      
      yPosition += 30;
      
      // Draw options
      for (int j = 0; j < question.options.length; j++) {
        graphics.drawString(
          '${String.fromCharCode(65 + j)}. ${question.options[j]}',
          font,
          brush: PdfBrushes.black,
          bounds: Rect.fromLTWH(40, yPosition, page.getClientSize().width - 60, 20),
        );
        yPosition += 25;
      }
      
      yPosition += 10; // Space between questions
    }
    
    // Save the document
    final List<int> bytes = await pdf.save();
    pdf.dispose();
    
    // Get directory for saving the file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/quiz_${quiz.id}.pdf';
    
    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    return filePath;
  }

  Future<String> exportFlashcardSet(FlashcardSet flashcardSet) async {
    // Create a new PDF document
    final pdf = PdfDocument();
    
    // Add a page to the document
    final page = pdf.pages.add();
    
    // Get page graphics
    final graphics = page.graphics;
    
    // Set fonts
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final cardFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
    final boldCardFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    
    // Draw title
    graphics.drawString(
      flashcardSet.title,
      titleFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    
    // Draw flashcards
    double yPosition = 50;
    for (int i = 0; i < flashcardSet.flashcards.length; i++) {
      final flashcard = flashcardSet.flashcards[i];
      
      // Draw question
      graphics.drawString(
        'Question ${i + 1}:',
        boldCardFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(20, yPosition, page.getClientSize().width - 40, 20),
      );
      
      yPosition += 25;
      
      graphics.drawString(
        flashcard.question,
        cardFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(40, yPosition, page.getClientSize().width - 60, 20),
      );
      
      yPosition += 30;
      
      // Draw answer
      graphics.drawString(
        'Answer:',
        boldCardFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(20, yPosition, page.getClientSize().width - 40, 20),
      );
      
      yPosition += 25;
      
      graphics.drawString(
        flashcard.answer,
        cardFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(40, yPosition, page.getClientSize().width - 60, 20),
      );
      
      yPosition += 40; // Space between flashcards
      
      // Add page break if needed
      if (yPosition > page.getClientSize().height - 100 && i < flashcardSet.flashcards.length - 1) {
        page.graphics.drawString(
          'Continue on next page...',
          font,
          brush: PdfBrushes.gray,
          bounds: Rect.fromLTWH(0, yPosition, page.getClientSize().width, 20),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        
        // Add new page
        final newPage = pdf.pages.add();
        graphics = newPage.graphics;
        yPosition = 50;
      }
    }
    
    // Save the document
    final List<int> bytes = await pdf.save();
    pdf.dispose();
    
    // Get directory for saving the file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/flashcards_${flashcardSet.id}.pdf';
    
    // Write the file
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    return filePath;
  }
}