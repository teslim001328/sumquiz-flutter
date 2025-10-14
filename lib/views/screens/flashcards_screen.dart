import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/summary_model.dart';
import '../widgets/upgrade_modal.dart';

class FlashcardsScreen extends StatefulWidget {
  final FlashcardSet? flashcardSet;
  const FlashcardsScreen({super.key, this.flashcardSet});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final CardSwiperController _swiperController = CardSwiperController();
  final AIService _aiService = AIService();
  final FirestoreService _firestoreService = FirestoreService();
  late SpacedRepetitionService _srsService;

  bool _isLoading = false;
  bool _isReviewFinished = false;
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    if (widget.flashcardSet != null) {
      setState(() {
        _flashcards = widget.flashcardSet!.flashcards;
        _titleController.text = widget.flashcardSet!.title;
      });
    }
  }

  Future<void> _initializeServices() async {
    final dbService = LocalDatabaseService();
    await dbService.init();
    _srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
  }

  Future<void> _generateFlashcards() async {
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in both the title and content fields.')),
      );
      return;
    }

    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not found.')));
      return;
    }

    final canGenerate =
        await _firestoreService.canGenerate(userModel.uid, 'flashcards');
    if (!canGenerate) {
      if (mounted) _showUpgradeDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      developer.log('Generating flashcards for content...',
          name: 'flashcards.generation');
      final summary = Summary(
        id: '', // Temporary ID
        userId: userModel.uid,
        title: _titleController.text,
        content: _textController.text,
        timestamp: Timestamp.now(),
      );
      final cards = await _aiService.generateFlashcards(summary);

      if (cards.isNotEmpty) {
        await _firestoreService.incrementUsage(userModel.uid, 'flashcards');
        if (mounted) {
          setState(() {
            _flashcards = cards;
            _isLoading = false;
          });
          developer.log('${cards.length} flashcards generated successfully.',
              name: 'flashcards.generation');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not generate flashcards from the provided content. Please try again with different text.'),
              backgroundColor: Colors.orange,
            ),
          );
          developer.log('AI service returned an empty list of flashcards.',
              name: 'flashcards.generation');
        }
      }
    } catch (e, s) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('quota')) {
          _showUpgradeDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating flashcards: $e')));
        }
        developer.log('Error generating flashcards',
            name: 'flashcards.generation', error: e, stackTrace: s);
      }
    }
  }

  Future<void> _saveFlashcardSet() async {
    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save a set.')),
      );
      return;
    }

    if (_flashcards.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Cannot save an empty set or a set without a title.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final set = FlashcardSet(
        id: '', // Firestore will generate this
        title: _titleController.text,
        flashcards: _flashcards,
        timestamp: Timestamp.now(),
      );

      await _firestoreService.addFlashcardSet(userModel.uid, set);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard set saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      developer.log('Error saving flashcard set',
          name: 'flashcards.save', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving set: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUpgradeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const UpgradeModal(),
    );
  }

  void _handleFlashcardReview(int index, bool knewIt) {
    final flashcardId = _flashcards[index].hashCode.toString();
    _srsService.updateReview(flashcardId, knewIt);
    _swiperController.swipe(CardSwiperDirection.right);
  }

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (currentIndex == null) {
      setState(() => _isReviewFinished = true);
    } else {
      setState(() {
        _currentIndex = currentIndex;
      });
    }
    return true;
  }

  void _reviewAgain() {
    setState(() {
      _isReviewFinished = false;
      _currentIndex = 0;
      _swiperController.moveTo(0);
    });
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
        actions: [
          if (_flashcards.isNotEmpty && !_isReviewFinished)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveFlashcardSet,
              tooltip: 'Save Set',
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildContent(),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(179), // 0.7 opacity
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isReviewFinished) {
      return _buildCompletionScreen();
    } else if (_flashcards.isNotEmpty) {
      return _buildReviewInterface();
    } else {
      return _buildCreationForm();
    }
  }

  Widget _buildCreationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text('Create Flashcards',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set Title',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter set title',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Content',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter content',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateFlashcards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Generate Flashcards',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInterface() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(_titleController.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text('Question ${_currentIndex + 1}/${_flashcards.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
            Expanded(
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: _flashcards.length,
                onSwipe: _onSwipe,
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  final card = _flashcards[index];
                  return FlipCard(
                    front: _buildCardSide(card.question, isFront: true),
                    back: _buildCardSide(card.answer,
                        isFront: false, cardIndex: index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSide(String text, {required bool isFront, int? cardIndex}) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          Expanded(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.4))))),
          if (!isFront)
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeedbackButton("Didn't Know",
                        () => _handleFlashcardReview(cardIndex!, false), false),
                    _buildFeedbackButton("Knew It",
                        () => _handleFlashcardReview(cardIndex!, true), true),
                  ],
                ))
          else
            const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Tap to Flip",
                    style: TextStyle(
                        color: Colors.white70, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(
      String text, VoidCallback onPressed, bool knewIt) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: knewIt
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        foregroundColor: knewIt ? Colors.greenAccent : Colors.redAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: knewIt ? Colors.greenAccent : Colors.redAccent,
                width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text('Set Complete!',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.greenAccent, size: 100),
                const SizedBox(height: 24),
                const Text("You've completed the set!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveFlashcardSet,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Save Flashcards',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _reviewAgain,
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Review Again',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Finish',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
