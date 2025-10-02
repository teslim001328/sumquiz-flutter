import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/editable_content.dart';
import '../../models/quiz_question.dart';
import '../../models/flashcard.dart';
import '../../services/firestore_service.dart';

class EditContentScreen extends StatefulWidget {
  final EditableContent content;

  const EditContentScreen({super.key, required this.content});

  @override
  EditContentScreenState createState() => EditContentScreenState();
}

class EditContentScreenState extends State<EditContentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<QuizQuestion> _questions;
  late List<Flashcard> _flashcards;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.content.title);
    
    if (widget.content.type == 'summary') {
      _contentController = TextEditingController(text: widget.content.content);
    } else {
      _contentController = TextEditingController();
    }
    
    _questions = widget.content.questions?.toList() ?? [];
    _flashcards = widget.content.flashcards?.toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    try {
      switch (widget.content.type) {
        case 'summary':
          await _firestoreService.updateSummary(
            user.uid,
            widget.content.id,
            _titleController.text,
            _contentController.text,
          );
          break;
        case 'quiz':
          await _firestoreService.updateQuiz(
            user.uid,
            widget.content.id,
            _titleController.text,
            _questions,
          );
          break;
        case 'flashcard':
          await _firestoreService.updateFlashcardSet(
            user.uid,
            widget.content.id,
            _titleController.text,
            _flashcards,
          );
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved successfully!')),
      );
      Navigator.pop(context, true); // Return true to indicate content was saved
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving content: $e')),
      );
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestion(
        question: '',
        options: List.generate(4, (index) => ''),
        correctAnswer: '',
      ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.content.type}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveContent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.content.type == 'summary')
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
              )
            else if (widget.content.type == 'quiz')
              _buildQuizEditor()
            else if (widget.content.type == 'flashcard')
              _buildFlashcardEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        for (int i = 0; i < _questions.length; i++)
          _buildQuestionEditor(i),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addQuestion,
          icon: const Icon(Icons.add),
          label: const Text('Add Question'),
        ),
      ],
    );
  }

  Widget _buildQuestionEditor(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Question'),
              controller: TextEditingController(text: _questions[index].question),
              onChanged: (value) {
                setState(() {
                  _questions[index] = QuizQuestion(
                    question: value,
                    options: _questions[index].options,
                    correctAnswer: _questions[index].correctAnswer,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
            for (int j = 0; j < _questions[index].options.length; j++)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  decoration: InputDecoration(labelText: 'Option ${j + 1}'),
                  controller: TextEditingController(text: _questions[index].options[j]),
                  onChanged: (value) {
                    final newOptions = List<String>.from(_questions[index].options);
                    newOptions[j] = value;
                    setState(() {
                      _questions[index] = QuizQuestion(
                        question: _questions[index].question,
                        options: newOptions,
                        correctAnswer: _questions[index].correctAnswer,
                      );
                    });
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Correct Answer'),
              controller: TextEditingController(text: _questions[index].correctAnswer),
              onChanged: (value) {
                setState(() {
                  _questions[index] = QuizQuestion(
                    question: _questions[index].question,
                    options: _questions[index].options,
                    correctAnswer: value,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeQuestion(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Flashcards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        for (int i = 0; i < _flashcards.length; i++)
          _buildSingleFlashcardEditor(i),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addFlashcard,
          icon: const Icon(Icons.add),
          label: const Text('Add Flashcard'),
        ),
      ],
    );
  }

  Widget _buildSingleFlashcardEditor(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Question'),
              controller: TextEditingController(text: _flashcards[index].question),
              onChanged: (value) {
                setState(() {
                  _flashcards[index] = Flashcard(
                    question: value,
                    answer: _flashcards[index].answer,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Answer'),
              controller: TextEditingController(text: _flashcards[index].answer),
              onChanged: (value) {
                setState(() {
                  _flashcards[index] = Flashcard(
                    question: _flashcards[index].question,
                    answer: value,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeFlashcard(index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
