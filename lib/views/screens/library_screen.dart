import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/library_item.dart';
import '../../services/firestore_service.dart';
import '../../services/local_database_service.dart';
import '../../models/editable_content.dart';
import '../../models/summary_model.dart';
import '../../models/quiz_model.dart';
import '../../models/flashcard_set.dart';
import '../../models/local_quiz.dart';
import '../../models/local_quiz_question.dart';
import '../screens/edit_content_screen.dart';
import 'summary_screen.dart';
import 'quiz_screen.dart';
import 'flashcards_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_content_modal.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isOfflineMode = false;
  String _searchQuery = '';

  Stream<Map<String, List<LibraryItem>>>? _allItemsStream;
  Stream<List<LibraryItem>>? _summariesStream;
  Stream<List<LibraryItem>>? _quizzesStream;
  Stream<List<LibraryItem>>? _flashcardsStream;
  String? _userIdForStreams;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _localDb.init();
    _loadOfflineModePreference();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<User?>(context);
    if (user != null && user.uid != _userIdForStreams) {
      _userIdForStreams = user.uid;
      _initializeStreams(user.uid);
    }
  }

  void _initializeStreams(String userId) {
    setState(() {
      _allItemsStream =
          _firestoreService.streamAllItems(userId).asBroadcastStream();
      _summariesStream = _firestoreService
          .streamItems(userId, 'summaries')
          .asBroadcastStream();
      _quizzesStream =
          _firestoreService.streamItems(userId, 'quizzes').asBroadcastStream();
      _flashcardsStream = _firestoreService
          .streamItems(userId, 'flashcards')
          .asBroadcastStream();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() =>
      setState(() => _searchQuery = _searchController.text.toLowerCase());

  Future<void> _loadOfflineModePreference() async {
    final isOffline = await _localDb.isOfflineModeEnabled();
    if (mounted) setState(() => _isOfflineMode = isOffline);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: user == null ? _buildLoggedOutView(theme) : _buildLibraryContent(user, theme),
      floatingActionButton: user != null && !_isOfflineMode
          ? FloatingActionButton(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const AddContentModal(),
                  isScrollControlled: true),
              backgroundColor: theme.cardColor,
              foregroundColor: theme.iconTheme.color,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Text('Library',
          style: theme.textTheme.headlineMedium),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildLoggedOutView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 80, color: theme.iconTheme.color),
            const SizedBox(height: 24),
            Text('Please Log In',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Log in to access your synchronized library across all your devices.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off_outlined,
                size: 80, color: theme.iconTheme.color),
            const SizedBox(height: 24),
            Text('Offline Mode',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'You are currently in offline mode. Only locally stored content is available. Turn off offline mode in settings to sync with the cloud.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryContent(User user, ThemeData theme) {
    if (_isOfflineMode) {
      return _buildOfflineState(theme);
    }
    return Column(
      children: [
        _buildSearchAndTabs(theme),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCombinedList(user.uid, theme),
              _buildLibraryList(user.uid, 'summaries', _summariesStream, theme),
              _buildLibraryList(user.uid, 'quizzes', _quizzesStream, theme),
              _buildLibraryList(user.uid, 'flashcards', _flashcardsStream, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndTabs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search Library...',
              hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
              prefixIcon: Icon(Icons.search, color: theme.textTheme.bodySmall?.color),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          _buildTabBar(theme),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'Summaries'),
        Tab(text: 'Quizzes'),
        Tab(text: 'Flashcards'),
      ],
      indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30), color: theme.colorScheme.secondaryContainer),
      labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
      unselectedLabelColor: theme.textTheme.bodySmall?.color,
      labelColor: theme.colorScheme.onSecondaryContainer,
      dividerColor: Colors.transparent,
    );
  }

  Widget _buildCombinedList(String userId, ThemeData theme) {
    return StreamBuilder<Map<String, List<LibraryItem>>>(
      stream: _allItemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.values.every((list) => list.isEmpty)) {
          return _buildNoContentState('all', theme);
        }

        final allItems = snapshot.data!.values.expand((list) => list).toList();
        allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return _buildContentList(allItems, userId, theme);
      },
    );
  }

  Widget _buildLibraryList(
      String userId, String type, Stream<List<LibraryItem>>? stream, ThemeData theme) {
    return StreamBuilder<List<LibraryItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return _buildNoContentState(type, theme);
        }

        final items = snapshot.data!;
        return _buildContentList(items, userId, theme);
      },
    );
  }

  Widget _buildContentList(List<LibraryItem> items, String userId, ThemeData theme) {
    final filteredItems = items.where((item) {
      return item.title.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredItems.isEmpty) {
      if (items.isNotEmpty && _searchQuery.isNotEmpty) {
        return _buildNoSearchResultsState(theme);
      }
      return _buildNoContentState(_tabController.index == 0
          ? 'all'
          : ['summaries', 'quizzes', 'flashcards'][_tabController.index - 1], theme);
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return _buildLibraryCard(item, userId, theme);
          },
        );
      } else {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 80.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400.0, // Max width of each item
            childAspectRatio: 3.5, // Adjust aspect ratio to look good
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return _buildLibraryCard(item, userId, theme);
          },
        );
      }
    });
  }

  Widget _buildLibraryCard(LibraryItem item, String userId, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToContent(userId, item),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _getIconForType(item.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item.type.toString().split('.').last,
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                  icon: Icon(Icons.more_horiz, color: theme.iconTheme.color),
                  onPressed: () => _showItemMenu(userId, item, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Icon _getIconForType(LibraryItemType type) {
    switch (type) {
      case LibraryItemType.summary:
        return const Icon(Icons.article_outlined, color: Colors.blueAccent);
      case LibraryItemType.quiz:
        return const Icon(Icons.quiz_outlined, color: Colors.greenAccent);
      case LibraryItemType.flashcards:
        return const Icon(Icons.style_outlined, color: Colors.orangeAccent);
    }
  }

  Widget _buildNoContentState(String type, ThemeData theme) {
    final typeName = type == 'all' ? 'content' : type.replaceAll('s', '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 100, color: theme.iconTheme.color),
            const SizedBox(height: 24),
            Text('No $typeName yet',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Tap the ' '+' ' button to create your first set of study materials!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined,
                size: 100, color: theme.iconTheme.color),
            const SizedBox(height: 24),
            Text('No Results Found',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Your search for "$_searchQuery" did not match any content. Try a different search term.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showItemMenu(String userId, LibraryItem item, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: theme.iconTheme.color),
            title: Text('Edit', style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _editContent(userId, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _deleteContent(userId, item);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToContent(String userId, LibraryItem item) async {
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Navigation is disabled in offline mode.')));
      return;
    }
    
    Widget screen;
    switch (item.type) {
      case LibraryItemType.summary:
        final content = await _firestoreService.getSpecificItem(userId, item);
        if (content == null || !mounted) return;
        screen = SummaryScreen(summary: content as Summary);
        break;
      case LibraryItemType.quiz:
        LocalQuiz? localQuiz = await _localDb.getQuiz(item.id);
        if (localQuiz == null) {
            final firestoreQuiz = await _firestoreService.getSpecificItem(userId, item) as Quiz?;
            if (firestoreQuiz == null) return;
            localQuiz = LocalQuiz(
                id: firestoreQuiz.id,
                userId: firestoreQuiz.userId,
                title: firestoreQuiz.title,
                questions: firestoreQuiz.questions.map((q) => 
                    LocalQuizQuestion(
                        question: q.question, 
                        options: q.options, 
                        correctAnswer: q.correctAnswer
                    )).toList(), 
                timestamp: firestoreQuiz.timestamp.toDate(),
                scores: [],
            );
            await _localDb.saveQuiz(localQuiz);
        }
        screen = QuizScreen(quiz: localQuiz);
        break;
      case LibraryItemType.flashcards:
        final content = await _firestoreService.getSpecificItem(userId, item);
        if (content == null || !mounted) return;
        screen = FlashcardsScreen(flashcardSet: content as FlashcardSet);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _editContent(String userId, LibraryItem item) async {
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Editing is disabled in offline mode.')));
      return;
    }
    final content = await _firestoreService.getSpecificItem(userId, item);
    if (content == null || !mounted) return;

    EditableContent editableContent;
    switch (item.type) {
      case LibraryItemType.summary:
        final summary = content as Summary;
        editableContent = EditableContent.fromSummary(summary.id, summary.title,
            summary.content, summary.tags, summary.timestamp);
        break;
      case LibraryItemType.quiz:
        final quiz = content as Quiz;
        editableContent = EditableContent.fromQuiz(
            quiz.id, quiz.title, quiz.questions, quiz.timestamp);
        break;
      case LibraryItemType.flashcards:
        final flashcardSet = content as FlashcardSet;
        editableContent = EditableContent.fromFlashcardSet(
            flashcardSet.id,
            flashcardSet.title,
            flashcardSet.flashcards,
            flashcardSet.timestamp);
        break;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditContentScreen(content: editableContent)));
  }

  Future<void> _deleteContent(String userId, LibraryItem item) async {
    final theme = Theme.of(context);
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Deletion is disabled in offline mode.')));
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text('Delete Content', style: theme.textTheme.headlineSmall),
            content: Text('Are you sure you want to delete this item?', style: theme.textTheme.bodyMedium),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface))),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _firestoreService.deleteItem(userId, item);
      await _localDb.deleteQuiz(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item deleted')));
      }
    }
  }
}
