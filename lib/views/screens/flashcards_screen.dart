import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:provider/provider.dart';

import '../../models/summary_model.dart';
import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
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
        const SnackBar(content: Text('Please fill in both the title and content fields.')),
      );
      return;
    }

    final userModel = Provider.of<UserModel?>(context, listen: false);
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found.')));
      return;
    }

    final canGenerate = await _firestoreService.canGenerate(userModel.uid, 'flashcards');
    if (!canGenerate) {
      if (mounted) _showUpgradeDialog();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final summary = Summary(
        id: '', // Not needed for generation
        userId: userModel.uid,
        content: _textController.text,
        timestamp: Timestamp.now(),
      );
      final cards = await _aiService.generateFlashcards(summary);
      await _firestoreService.incrementUsage(userModel.uid, 'flashcards');
      if (mounted) {
        setState(() {
          _flashcards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
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

  void _resetToCreation() {
    setState(() {
      _flashcards = [];
      _isReviewFinished = false;
      _currentIndex = 0;
      _textController.clear();
      _titleController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildContent(),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(179), // 0.7 opacity
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Set Title', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter set title',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Content', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              child: TextButton(
                onPressed: _generateFlashcards,
                child: const Text('Generate Flashcards', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInterface() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Column(
              children: [
                const Text('Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Question ${_currentIndex + 1}/${_flashcards.length}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: _resetToCreation),
          ),
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _flashcards.length,
              onSwipe: _onSwipe,
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                final card = _flashcards[index];
                return FlipCard(
                  front: _buildCardSide(card.question, isFront: true),
                  back: _buildCardSide(card.answer, isFront: false, cardIndex: index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSide(String text, {required bool isFront, int? cardIndex}) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1541829076-248995839PASTE_IMAGE_URL_HERE'),
              fit: BoxFit.cover),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 20, spreadRadius: 2)]),
      child: Column(
        children: [
          Expanded(
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4))))),
          if (!isFront)
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeedbackButton("Didn't Know", () => _handleFlashcardReview(cardIndex!, false), false),
                    _buildFeedbackButton("Knew It", () => _handleFlashcardReview(cardIndex!, true), true),
                  ],
                ))
          else
            const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Tap to Flip", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(String text, VoidCallback onPressed, bool knewIt) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: knewIt ? Colors.green.withAlpha(51) : Colors.red.withAlpha(51),
        foregroundColor: knewIt ? Colors.green[800] : Colors.red[800],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text('Flashcards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1516975080664-626423896246?w=800'),
                        fit: BoxFit.cover),
                  ),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                              colors: [Colors.black.withAlpha(204), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.center)),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(24.0),
                      child: const Text("You've completed the set!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 40),
                TextButton(onPressed: _reviewAgain, child: const Text('Review Again', style: TextStyle(color: Colors.white, fontSize: 16))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[850], padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Back to Library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
