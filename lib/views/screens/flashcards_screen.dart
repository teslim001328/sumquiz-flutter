import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../widgets/upgrade_modal.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/summary_model.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  final AIService _aiService = AIService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<Flashcard> _flashcards = [];

  Future<void> _generateFlashcards() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available.')),
      );
      return;
    }

    final canGenerate = await _firestore.canGenerate(userModel.uid, 'flashcards');
    if (!canGenerate) {
      if (mounted) {
        _showUpgradeDialog();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _flashcards = [];
    });

    try {
      final summary = Summary(
        id: '', // Not needed for generation
        userId: _auth.currentUser!.uid,
        content: _textController.text,
        timestamp: Timestamp.now(),
      );
      final flashcards = await _aiService.generateFlashcards(summary);
      setState(() {
        _flashcards = flashcards;
      });
    } catch (e, s) {
      developer.log(
        'Error generating flashcards',
        name: 'my_app.flashcards',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating flashcards: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _firestore.incrementUsage(userModel.uid, 'flashcards');
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text('You have reached your daily limit. Upgrade to Pro for unlimited flashcard generation.'),
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

  Future<void> _saveFlashcards() async {
    if (_flashcards.isEmpty || _titleController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and generate flashcards before saving.')),
      );
      return;
    }

    try {
      await _firestore.addFlashcardSet(
        _auth.currentUser!.uid,
        FlashcardSet(
          id: '',
          title: _titleController.text,
          summaryId: '', // Not linked to a summary in this context
          flashcards: _flashcards,
          timestamp: Timestamp.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashcards saved successfully!')),
      );
    } catch (e, s) {
      developer.log(
        'Error saving flashcards',
        name: 'my_app.flashcards',
        error: e,
        stackTrace: s,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving flashcards: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Flashcards'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter your text here',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData != null) {
                      _textController.text = clipboardData.text!;
                    }
                  },
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            if (_flashcards.isNotEmpty)
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title for your flashcards',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_flashcards.isNotEmpty)
              Expanded(
                child: CardSwiper(
                  cardsCount: _flashcards.length,
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) => FlipCard(
                    front: Card(
                      child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_flashcards[index].question, textAlign: TextAlign.center))),
                    ),
                    back: Card(
                      child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_flashcards[index].answer, textAlign: TextAlign.center))),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _generateFlashcards,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate'),
                ),
                ElevatedButton.icon(
                  onPressed: _saveFlashcards,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
