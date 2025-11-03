import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../services/local_database_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/firestore_service.dart';
import 'flashcards_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late SpacedRepetitionService _srsService;
  late FirestoreService _firestoreService;
  List<Flashcard> _dueFlashcards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAndLoadDueCards();
  }

  Future<void> _initializeAndLoadDueCards() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = "User not found. Please log in again.";
        });
        return;
      }

      final dbService = LocalDatabaseService();
      await dbService.init();
      _srsService = SpacedRepetitionService(dbService.getSpacedRepetitionBox());
      _firestoreService = FirestoreService();

      // 1. Get all flashcard sets from Firestore
      final flashcardSets = await _firestoreService.streamFlashcardSets(userId).first;

      // 2. Flatten into a single list of all flashcards
      final allFlashcards = flashcardSets.expand((set) => set.flashcards).toList();

      // 3. Get the IDs of due cards from the local spaced repetition service
      final dueFlashcardIds = await _srsService.getDueFlashcardIds(userId);

      // 4. Filter the main list to get the due Flashcard objects
      final dueFlashcards = allFlashcards.where((card) => dueFlashcardIds.contains(card.id)).toList();

      if (!mounted) return;

      setState(() {
        _dueFlashcards = dueFlashcards;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "An error occurred while loading your review cards. Please try again later. Error: $e";
      });
    }
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
      // Refresh the due cards list when returning from a review session
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _initializeAndLoadDueCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;

    if (_isLoading) {
      content = Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    } else if (_error != null) {
      content = _buildErrorView(theme);
    } else {
      content = _buildBody(theme);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Review', style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Constrain content width
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: content,
          ),
        ),
      ),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _initializeAndLoadDueCards();
            },
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  Widget _buildNoCardsDueView(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _buildCardsDueView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'You have',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          '${_dueFlashcards.length}',
          style: theme.textTheme.displayLarge?.copyWith(
            color: theme.colorScheme.primary,
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
             backgroundColor: theme.colorScheme.primary,
             foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Start Review', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
