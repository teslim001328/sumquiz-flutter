import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';

import '../../models/user_model.dart';
import '../../models/flashcard_model.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';

enum FlashcardState { initial, loading, error, success }

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedLibraryItem;
  FlashcardState _state = FlashcardState.initial;
  String _errorMessage = '';
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;

  late final AIService _aiService;
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(FirebaseVertexAI.instance);
    _firestoreService = FirestoreService();
  }

  void _generateFlashcards() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    final userModel = await _firestoreService.streamUser(user!.uid).first;

    if (!_firestoreService.canGenerate('flashcards', userModel)) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _state = FlashcardState.loading;
    });

    try {
      String content = _textController.text;
      if (_selectedLibraryItem != null) {
        // TODO: Fetch content from library
      }

      List<Flashcard> flashcards = await _aiService.generateFlashcards(content);

      if (flashcards.isEmpty) {
        setState(() {
          _state = FlashcardState.error;
          _errorMessage = 'Could not generate flashcards from the provided text.';
        });
      } else {
        await _firestoreService.incrementUsage('flashcards', user.uid);
        setState(() {
          _flashcards = flashcards;
          _state = FlashcardState.success;
        });
      }
    } catch (e) {
      setState(() {
        _state = FlashcardState.error;
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text('You have reached your daily flashcard limit. Upgrade to Pro for unlimited flashcards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement navigation to upgrade screen
              Navigator.of(context).pop();
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _state = FlashcardState.initial;
      _errorMessage = '';
    });
  }

  void _selectFromLibrary() {
    // TODO: Implement library picker bottom sheet
    setState(() {
      _selectedLibraryItem = 'My Awesome Summary';
    });
  }

  void _saveToLibrary() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      try {
        await _firestoreService.saveFlashcards(user.uid, _selectedLibraryItem ?? "Pasted Text Flashcards", _flashcards);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcards saved to library!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving flashcards.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Flashcards'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(),
          ),
          if (_state == FlashcardState.loading)
            Container(
              color: Colors.black.withOpacity(0.5),
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
      case FlashcardState.error:
        return _buildErrorState();
      case FlashcardState.success:
        return _buildSuccessState();
      default:
        return _buildInitialState();
    }
  }

  Widget _buildInitialState() {
    bool canGenerate = _textController.text.isNotEmpty || _selectedLibraryItem != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate Flashcards',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Input text or select content from your Library',
          style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _textController,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Paste text here to generate flashcards...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (text) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.library_books),
            label: const Text('Select from Library'),
            onPressed: _selectFromLibrary,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
        if (_selectedLibraryItem != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: Chip(
                label: Text(_selectedLibraryItem!),
                onDeleted: () {
                  setState(() {
                    _selectedLibraryItem = null;
                  });
                },
              ),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: canGenerate ? _generateFlashcards : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
            child: const Text('Generate Flashcards'),
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
            'Failed to generate flashcards',
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
          'Your Flashcards',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: CardSwiper(
            cardsCount: _flashcards.length,
            onSwipe: (prev, current, direction) {
              setState(() {
                _currentIndex = current ?? 0;
              });
              return true;
            },
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final card = _flashcards[index];
              return FlipCard(
                front: _buildFlashcardSide(card.question),
                back: _buildFlashcardSide(card.answer),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Card ${_currentIndex + 1} of ${_flashcards.length}',
            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
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
            child: const Text('Generate Another Set of Flashcards'),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardSide(String text) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            text,
            style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
