import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../../services/spaced_repetition_service.dart';
import '../../models/local_flashcard.dart';
import '../../models/spaced_repetition.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  late SpacedRepetitionService _spacedRepetitionService;
  List<LocalFlashcard> _dueFlashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    final box = Hive.box<SpacedRepetitionItem>('spaced_repetition');
    _spacedRepetitionService = SpacedRepetitionService(box);
    _loadDueFlashcards();
  }

  Future<void> _loadDueFlashcards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user != null) {
        // In a real app, you would fetch all flashcards from the local DB
        // and pass them to getDueFlashcards.
        // For now, we'll pass an empty list for demonstration.
        final flashcards = await _spacedRepetitionService.getDueFlashcards([]);
        setState(() {
          _dueFlashcards = flashcards;
          _isLoading = false;
          
          if (flashcards.isEmpty) {
            _message = 'No flashcards are due for review right now. Great job!';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error loading flashcards: $e';
      });
    }
  }

  Future<void> _processReview(bool answeredCorrectly) async {
    if (_currentIndex < _dueFlashcards.length) {
      final flashcard = _dueFlashcards[_currentIndex];
      
      try {
        await _spacedRepetitionService.updateReview(
          flashcard.id,
          answeredCorrectly,
        );
        
        // Move to next card or finish
        if (_currentIndex < _dueFlashcards.length - 1) {
          setState(() {
            _currentIndex++;
            _showAnswer = false;
          });
        } else {
          // Finished all cards
          setState(() {
            _message = 'You\'ve completed all due flashcards for now!';
            _dueFlashcards.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing review: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _message.isNotEmpty
            ? _buildMessageView()
            : _buildFlashcardReview();
  }

  Widget _buildMessageView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _dueFlashcards.isEmpty ? Icons.check_circle : Icons.error,
              size: 64,
              color: _dueFlashcards.isEmpty ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _message,
              style: GoogleFonts.roboto(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDueFlashcards,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardReview() {
    if (_currentIndex >= _dueFlashcards.length) {
      return _buildMessageView();
    }

    final flashcard = _dueFlashcards[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Text(
            'Card ${_currentIndex + 1} of ${_dueFlashcards.length}',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _dueFlashcards.length,
          ),
          const SizedBox(height: 32),
          
          // Flashcard
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Question',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      flashcard.question,
                      style: GoogleFonts.roboto(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_showAnswer) ...[
                      Text(
                        'Answer',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        flashcard.answer,
                        style: GoogleFonts.roboto(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          if (!_showAnswer)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAnswer = true;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Show Answer'),
            )
          else
            Column(
              children: [
                Text(
                  'How well did you know this?',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _processReview(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Incorrect'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _processReview(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Correct'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
