import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';

import '../../models/editable_content.dart';
import '../../models/quiz_question.dart';
import '../../models/flashcard.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class EditContentScreen extends StatefulWidget {
  final EditableContent content;

  const EditContentScreen({super.key, required this.content});

  @override
  EditContentScreenState createState() => EditContentScreenState();
}

class EditContentScreenState extends State<EditContentScreen> {
  late TextEditingController _titleController;
  late List<QuizQuestion> _questions;
  late List<Flashcard> _flashcards;
  late List<String> _tags;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.content.title);
    _tags = List<String>.from(widget.content.tags ?? []);

    if (widget.content.type == 'summary') {
      _initializeQuillController();
    }

    _questions =
        widget.content.questions?.map((q) => QuizQuestion.from(q)).toList() ?? [];
    _flashcards =
        widget.content.flashcards?.map((f) => Flashcard.from(f)).toList() ?? [];
  }

  void _initializeQuillController() {
    final content = widget.content.content;
    try {
      final doc = (content != null && content.isNotEmpty)
          ? Document.fromJson(jsonDecode(content))
          : Document();
      _quillController =
          QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
    } catch (e) {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to save.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? summaryContent;
      if (widget.content.type == 'summary' && _quillController != null) {
        summaryContent =
            jsonEncode(_quillController!.document.toDelta().toJson());
      }

      switch (widget.content.type) {
        case 'summary':
          await _firestoreService.updateSummary(userModel.uid,
              widget.content.id, _titleController.text, summaryContent!, _tags);
          break;
        case 'quiz':
          await _firestoreService.updateQuiz(userModel.uid, widget.content.id,
              _titleController.text, _questions);
          break;
        case 'flashcard':
          await _firestoreService.updateFlashcardSet(userModel.uid,
              widget.content.id, _titleController.text, _flashcards);
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Content saved successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving content: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion(
          question: '',
          options: List.generate(4, (index) => ''),
          correctAnswer: ''));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addFlashcard() {
    setState(() {
      _flashcards.add(Flashcard(question: '', answer: ''));
    });
  }

  void _removeFlashcard(int index) {
    setState(() {
      _flashcards.removeAt(index);
    });
  }

  void _addTag() {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a Tag'),
        content: TextField(
            controller: tagController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter tag')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (tagController.text.isNotEmpty) {
                  setState(() => _tags.add(tagController.text));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add')),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    String typeName = widget.content.type.isNotEmpty
        ? widget.content.type[0].toUpperCase() +
            widget.content.type.substring(1)
        : 'Content';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: Text('Edit $typeName',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_alt_outlined, color: Colors.white),
              onPressed: _saveContent,
              tooltip: 'Save',
            ),
        ],
      ),
      body: IgnorePointer(
        ignoring: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.content.type != 'flashcard')
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  decoration:
                      _inputDecoration(label: 'Title', hint: 'Enter title'),
                ),
              const SizedBox(height: 24),
              if (widget.content.type == 'summary')
                _buildSummaryEditor()
              else if (widget.content.type == 'quiz')
                _buildQuizEditor()
              else if (widget.content.type == 'flashcard')
                _buildFlashcardEditor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryEditor() {
    if (_quillController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagEditor(),
        const SizedBox(height: 24),
        QuillSimpleToolbar(
          controller: _quillController!,
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: QuillEditor.basic(
            controller: _quillController!,
            focusNode: _focusNode,
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }

  Widget _buildTagEditor() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        ..._tags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[800],
              onDeleted: () => _removeTag(tag),
              deleteIconColor: Colors.white70,
            )),
        ActionChip(
          label: const Text('Add Tag'),
          onPressed: _addTag,
          backgroundColor: Colors.blue,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildQuizEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          itemBuilder: (context, index) => _buildQuestionEditor(index),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('Add New Question',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionEditor(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.grey[900],
            collapsedBackgroundColor: Colors.grey[900],
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            title: Text('Question ${index + 1}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
                _questions[index].question.isEmpty
                    ? 'New Question'
                    : _questions[index].question,
                style: TextStyle(color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _questions[index].question,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(label: 'Question'),
                      onChanged: (value) =>
                          setState(() => _questions[index].question = value),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (optionIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(
                          initialValue:
                              _questions[index].options.length > optionIndex
                                  ? _questions[index].options[optionIndex]
                                  : '',
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _inputDecoration(label: 'Option ${optionIndex + 1}'),
                          onChanged: (value) => setState(() =>
                              _questions[index].options[optionIndex] = value),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _questions[index].correctAnswer,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(label: 'Correct Answer'),
                      onChanged: (value) =>
                          setState(() => _questions[index].correctAnswer = value),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _removeQuestion(index),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          decoration:
              _inputDecoration(label: 'Set Title', hint: 'e.g., AI Basics'),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _flashcards.length,
          itemBuilder: (context, index) => _buildSingleFlashcardEditor(index),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _addFlashcard,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('Add Flashcard',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleFlashcardEditor(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlashcardSideEditor(index, isFront: true),
          const SizedBox(height: 16),
          _buildFlashcardSideEditor(index, isFront: false),
        ],
      ),
    );
  }

  Widget _buildFlashcardSideEditor(int index, {required bool isFront}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
              'https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Fflashcard_background_2.png?alt=media&token=38a1656f-44e2-4545-9774-5c9e99395254'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: TextFormField(
              initialValue: isFront
                  ? _flashcards[index].question
                  : _flashcards[index].answer,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration.collapsed(
                  hintText: '...',
                  hintStyle: TextStyle(color: Colors.white54)),
              onChanged: (value) {
                setState(() {
                  if (isFront) {
                    _flashcards[index].question = value;
                  } else {
                    _flashcards[index].answer = value;
                  }
                });
              },
            ),
          ),
          Positioned(
            top: 8,
            left: 16,
            child: Text(isFront ? 'Front' : 'Back',
                style: TextStyle(
                    color: Colors.grey[400], fontWeight: FontWeight.bold)),
          ),
          if (isFront)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _removeFlashcard(index),
                tooltip: 'Remove Flashcard',
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
    );
  }
}