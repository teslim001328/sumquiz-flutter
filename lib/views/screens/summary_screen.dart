import 'dart:io';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../models/summary_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/upgrade_modal.dart';

enum SummaryState { initial, loading, error, success }

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _pdfFileName;
  SummaryState _state = SummaryState.initial;
  String _summary = '';
  String _errorMessage = '';

  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final document = PdfDocument(inputBytes: file.readAsBytesSync());
        final text = PdfTextExtractor(document).extractText();
        document.dispose();

        setState(() {
          _pdfFileName = result.files.single.name;
          _textController.text = text;
        });
      }
    } catch (e, s) {
      developer.log(
        'Error picking or reading PDF',
        name: 'my_app.summary',
        error: e,
        stackTrace: s,
      );
      setState(() {
        _state = SummaryState.error;
        _errorMessage = "Error picking or reading PDF: $e";
      });
    }
  }

  void _generateSummary() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not available. Please log in again.')),
      );
      return;
    }

    final canGenerate = await _firestoreService.canGenerate(userModel.uid, 'summaries');
    if (!canGenerate) {
      if (mounted) _showUpgradeDialog();
      return;
    }

    setState(() {
      _state = SummaryState.loading;
    });

    try {
      final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
      final prompt =
          'Summarize the following text: ${_textController.text}';
      final response = await model.generateContent([Content.text(prompt)]);
      final summary = response.text ?? '';

      if (summary.isEmpty) {
        setState(() {
          _state = SummaryState.error;
          _errorMessage = 'Could not generate a summary. Please try again.';
        });
      } else {
        await _firestoreService.incrementUsage(userModel.uid, 'summaries');
        setState(() {
          _summary = summary;
          _state = SummaryState.success;
        });
      }
    } catch (e, s) {
      developer.log(
        'An unexpected error occurred during summary generation',
        name: 'my_app.summary',
        error: e,
        stackTrace: s,
      );
      setState(() {
        _state = SummaryState.error;
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text('You have reached your daily summary limit. Upgrade to Pro for unlimited summaries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const UpgradeModal(),
                );
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _state = SummaryState.initial;
      _summary = '';
      _errorMessage = '';
    });
  }

  void _copySummary() {
    Clipboard.setData(ClipboardData(text: _summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to clipboard!')),
    );
  }

  void _saveToLibrary() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      try {
        await _firestoreService.addSummary(
          user.uid,
          Summary(
            id: '', // Firestore will generate this
            content: _summary,
            timestamp: Timestamp.now(),
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary saved to library!')),
        );
      } catch (e, s) {
        developer.log(
          'Error saving summary',
          name: 'my_app.summary',
          error: e,
          stackTrace: s,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving summary.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Summary'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(),
          ),
          if (_state == SummaryState.loading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case SummaryState.error:
        return _buildErrorState();
      case SummaryState.success:
        return _buildSuccessState();
      default:
        return _buildInitialState();
    }
  }

  Widget _buildInitialState() {
    bool canGenerate = _textController.text.isNotEmpty || _pdfFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate Summary',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Paste text or upload a PDF to get started.',
          style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _textController,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Paste your text here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (text) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload PDF'),
            onPressed: _pickPdf,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
        if (_pdfFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: Chip(
                label: Text(_pdfFileName!),
                onDeleted: () {
                  setState(() {
                    _pdfFileName = null;
                    _textController.clear();
                  });
                },
              ),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: canGenerate ? _generateSummary : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
            child: const Text('Generate Summary'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong.',
            style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Summary',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _summary,
              style: GoogleFonts.openSans(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: _copySummary,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Save'),
              onPressed: _saveToLibrary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _retry,
            child: const Text('Generate Another Summary'),
          ),
        ),
      ],
    );
  }
}
