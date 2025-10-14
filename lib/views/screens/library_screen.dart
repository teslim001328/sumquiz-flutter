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
import '../screens/edit_content_screen.dart';
import 'summary_screen.dart';
import 'quiz_screen.dart';
import 'flashcards_screen.dart';
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

  Future<void> _setOfflineMode(bool isEnabled) async {
    await _localDb.setOfflineMode(isEnabled);
    setState(() => _isOfflineMode = isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: user == null ? _buildLoggedOutView() : _buildLibraryContent(user),
      floatingActionButton: user != null && !_isOfflineMode
          ? FloatingActionButton(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const AddContentModal(),
                  isScrollControlled: true),
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text('Library',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 24)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showSettingsDialog(),
        ),
      ],
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text('Please Log In',
                style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Log in to access your synchronized library across all your devices.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 16, color: Colors.grey[400], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text('Offline Mode',
                style: GoogleFonts.oswald(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'You are currently in offline mode. Only locally stored content is available. Turn off offline mode in settings to sync with the cloud.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 16, color: Colors.grey[400], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryContent(User user) {
    if (_isOfflineMode) {
      return _buildOfflineState();
    }
    return Column(
      children: [
        _buildSearchAndTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCombinedList(user.uid),
              _buildLibraryList(user.uid, 'summaries', _summariesStream),
              _buildLibraryList(user.uid, 'quizzes', _quizzesStream),
              _buildLibraryList(user.uid, 'flashcards', _flashcardsStream),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Library...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
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
          borderRadius: BorderRadius.circular(30), color: Colors.grey[800]),
      labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
      unselectedLabelColor: Colors.grey[400],
      labelColor: Colors.white,
      dividerColor: Colors.transparent,
    );
  }

  Widget _buildCombinedList(String userId) {
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
          return _buildNoContentState('all');
        }

        final allItems = snapshot.data!.values.expand((list) => list).toList();
        allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return _buildContentList(allItems, userId);
      },
    );
  }

  Widget _buildLibraryList(
      String userId, String type, Stream<List<LibraryItem>>? stream) {
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
          return _buildNoContentState(type);
        }

        final items = snapshot.data!;
        return _buildContentList(items, userId);
      },
    );
  }

  Widget _buildContentList(List<LibraryItem> items, String userId) {
    final filteredItems = items.where((item) {
      return item.title.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredItems.isEmpty) {
      if (items.isNotEmpty && _searchQuery.isNotEmpty) {
        return _buildNoSearchResultsState();
      }
      return _buildNoContentState(_tabController.index == 0
          ? 'all'
          : ['summaries', 'quizzes', 'flashcards'][_tabController.index - 1]);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildLibraryCard(item, userId);
      },
    );
  }

  Widget _buildLibraryCard(LibraryItem item, String userId) {
    return Card(
      color: Colors.grey[900],
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
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item.type.toString().split('.').last,
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () => _showItemMenu(userId, item)),
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

  Widget _buildNoContentState(String type) {
    final typeName = type == 'all' ? 'content' : type.replaceAll('s', '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text('No $typeName yet',
                style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Tap the ' +
                  ' button to create your first set of study materials!',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 16, color: Colors.grey[400], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text('No Results Found',
                style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Your search for "$_searchQuery" did not match any content. Try a different search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 16, color: Colors.grey[400], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              Text('Settings', style: GoogleFonts.oswald(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SwitchListTile(
                title: const Text('Offline Mode',
                    style: TextStyle(color: Colors.white)),
                value: _isOfflineMode,
                onChanged: (bool value) {
                  _setOfflineMode(value);
                  setState(() {});
                  Navigator.of(context).pop();
                },
                secondary: const Icon(Icons.signal_wifi_off_outlined,
                    color: Colors.white),
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:
                    const Text('Close', style: TextStyle(color: Colors.white)))
          ],
        );
      },
    );
  }

  void _showItemMenu(String userId, LibraryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.white),
            title: const Text('Edit', style: TextStyle(color: Colors.white)),
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
    final content = await _firestoreService.getSpecificItem(userId, item);
    if (content == null || !mounted) return;

    Widget screen;
    switch (item.type) {
      case LibraryItemType.summary:
        screen = SummaryScreen(summary: content as Summary);
        break;
      case LibraryItemType.quiz:
        screen = QuizScreen(quiz: content as Quiz);
        break;
      case LibraryItemType.flashcards:
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
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Deletion is disabled in offline mode.')));
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Content'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item deleted')));
      }
    }
  }
}
