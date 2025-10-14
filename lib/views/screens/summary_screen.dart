import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/summary_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import 'quiz_screen.dart';

enum SummaryState { initial, loading, error, success }

class SummaryScreen extends StatefulWidget {
  final Summary? summary;

  const SummaryScreen({super.key, this.summary});

  @override
  SummaryScreenState createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _pdfFileName;
  Uint8List? _pdfBytes;
  SummaryState _state = SummaryState.initial;
  String _summaryContent = '';
  String _summaryTitle = '';
  List<String> _summaryTags = [];
  String _errorMessage = '';
  bool _isGeneratingQuiz = false;

  late final FirestoreService _firestoreService;
  late final AIService _aiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _aiService = AIService();
    if (widget.summary != null) {
      _summaryContent = widget.summary!.content;
      _summaryTitle = widget.summary!.title;
      _summaryTags = widget.summary!.tags;
      _state = SummaryState.success;
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pdfBytes = result.files.single.bytes;
          _pdfFileName = result.files.single.name;
        });
      }
    } catch (e, s) {
      developer.log('Error picking or reading PDF', name: 'my_app.summary', error: e, stackTrace: s);
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

    setState(() => _state = SummaryState.loading);

    try {
      final summaryJsonString = await _aiService.generateSummary(_textController.text, pdfBytes: _pdfBytes);
      final summaryData = json.decode(summaryJsonString) as Map<String, dynamic>;

      if (summaryData.containsKey('error')) {
        setState(() {
          _state = SummaryState.error;
          _errorMessage = summaryData['error'];
        });
      } else {
        await _firestoreService.incrementUsage(userModel.uid, 'summaries');
        setState(() {
          _summaryTitle = summaryData['title'] ?? 'Summary';
          _summaryContent = summaryData['content'] ?? '';
          _summaryTags = List<String>.from(summaryData['tags'] ?? []);
          _state = SummaryState.success;
        });
      }
    } catch (e, s) {
      developer.log('An unexpected error occurred during summary generation', name: 'my_app.summary', error: e, stackTrace: s);
      setState(() {
        _state = SummaryState.error;
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _showUpgradeDialog() {
    // UI for upgrade dialog is preserved but styled for dark theme
  }

  void _retry() {
    setState(() {
      _state = SummaryState.initial;
      _summaryContent = '';
      _summaryTitle = '';
      _summaryTags = [];
      _errorMessage = '';
    });
  }

  void _copySummary() {
    Clipboard.setData(ClipboardData(text: _summaryContent));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary content copied to clipboard!'), backgroundColor: Colors.green),
    );
  }

  void _saveToLibrary() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final summaryToSave = Summary(
          id: '',
          userId: user.uid,
          title: _summaryTitle,
          content: _summaryContent,
          tags: _summaryTags,
          timestamp: Timestamp.now(),
        );
        await _firestoreService.addSummary(user.uid, summaryToSave);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary saved to library!'), backgroundColor: Colors.green),
        );
      } catch (e, s) {
        developer.log('Error saving summary', name: 'my_app.summary', error: e, stackTrace: s);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving summary.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateQuiz() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isGeneratingQuiz = true);

    try {
      final summary = Summary(id: '', userId: user.uid, title: _summaryTitle, content: _summaryContent, tags: _summaryTags, timestamp: Timestamp.now());
      final quiz = await _aiService.generateQuizFromSummary(summary);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(quiz: quiz)));
      }
    } catch (e, s) {
      developer.log('Error generating quiz', name: 'my_app.summary', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error generating quiz.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _buildBody(),
          ),
          if (_state == SummaryState.loading || _isGeneratingQuiz)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Paste text or upload a file to get started.', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 24),
        TextField(
          controller: _textController,
          maxLines: 12,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            hintText: 'Paste your text here...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (text) => setState(() {}),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file, color: Colors.white),
          label: Text(_pdfFileName ?? 'Upload PDF', style: const TextStyle(color: Colors.white)),
          onPressed: _pickPdf,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_pdfFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _pdfBytes = null;
                  _pdfFileName = null;
                }),
                child: const Text('Clear PDF', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: canGenerate ? _generateSummary : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Generate Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          const Text('Oops! Something went wrong.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final bool isViewingSaved = widget.summary != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFEADFCE), Color(0xFFD8C9B8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_summaryTitle, style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_summaryTags.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _summaryTags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(color: Colors.black)),
                        backgroundColor: Colors.white.withOpacity(0.5),
                      )).toList(),
                ),
              if (_summaryTags.isNotEmpty) const SizedBox(height: 16),
              Text(_summaryContent, style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (!isViewingSaved)
          Row(
            children: [
              Expanded(child: _buildActionButton('Copy', _copySummary)),
              const SizedBox(width: 16),
              Expanded(child: _buildActionButton('Save', _saveToLibrary)),
            ],
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _generateQuiz,
            child: const Text('Generate Quiz', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        if (!isViewingSaved)
            Center(
              child: TextButton(
                onPressed: _retry,
                child: const Text('Generate Another Summary', style: TextStyle(color: Colors.white70)),
              ),
            ),
      ],
    );
  }
  
  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
