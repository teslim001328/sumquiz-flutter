import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/local_flashcard_set.dart';
import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import 'flashcards_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late LocalDatabaseService _dbService;
  late SpacedRepetitionService _srsService;
  List<Flashcard> _dueFlashcards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer context-dependent initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadDueCards();
    });
  }

  Future<void> _initializeAndLoadDueCards() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = "User not found. Please log in again.";
      });
      return;
    }

    _dbService = LocalDatabaseService();
    await _dbService.init();
    _srsService = SpacedRepetitionService(_dbService.getSpacedRepetitionBox());

    final List<LocalFlashcardSet> allFlashcardSets = await _dbService.getAllFlashcardSets(userId);
    final allLocalFlashcards = allFlashcardSets.expand((set) => set.flashcards).toList();

    final dueLocalFlashcards = await _srsService.getDueFlashcards(allLocalFlashcards);

    if (!mounted) return;

    setState(() {
      _dueFlashcards = dueLocalFlashcards.map((localCard) => Flashcard(
        question: localCard.question,
        answer: localCard.answer,
      )).toList();
      _isLoading = false;
    });
  }

  void _startReviewSession() {
    if (_dueFlashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flashcards are due for review today!')),
      );
      return;
    }

    final reviewSet = FlashcardSet(
      id: 'review_session',
      title: 'Due for Review',
      flashcards: _dueFlashcards,
      timestamp: Timestamp.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardsScreen(flashcardSet: reviewSet),
      ),
    ).then((_) {
      _initializeAndLoadDueCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Review', style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _error != null ? _buildErrorView(theme) : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_dueFlashcards.isEmpty) {
      return _buildNoCardsDueView(theme);
    } else {
      return _buildCardsDueView(theme);
    }
  }

  Widget _buildErrorView(ThemeData theme) {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'An Error Occurred',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCardsDueView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You have no flashcards due for review right now. Great job!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsDueView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You have',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '${_dueFlashcards.length}',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _dueFlashcards.length == 1 ? 'flashcard due for review' : 'flashcards due for review',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startReviewSession,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Review', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
