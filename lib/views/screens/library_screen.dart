import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isOfflineMode = false;
  bool _showSettings = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadOfflineModePreference();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() => _searchQuery = _searchController.text.toLowerCase());

  Future<void> _loadOfflineModePreference() async {
    final isOffline = await _localDb.isOfflineModeEnabled();
    if (mounted) setState(() => _isOfflineMode = isOffline);
  }

  Future<void> _setOfflineMode(bool isEnabled) async {
    await _localDb.setOfflineMode(isEnabled);
    setState(() => _isOfflineMode = isEnabled);
  }

  void _toggleSettings() => setState(() => _showSettings = !_showSettings);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _showSettings ? _buildSettingsContent() : _buildLibraryContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(_showSettings ? 'Settings' : 'Library', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(icon: Icon(_showSettings ? Icons.close : Icons.settings_outlined), onPressed: _toggleSettings),
      ],
    );
  }

  Widget _buildLibraryContent() {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const Center(child: Text('Please log in to see your library.', style: TextStyle(color: Colors.white)));
    }

    return Column(
      children: [
        _buildSearchAndTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCombinedList(user.uid),
              _buildLibraryList(user.uid, 'summaries'),
              _buildLibraryList(user.uid, 'quizzes'),
              _buildLibraryList(user.uid, 'flashcards'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchAndTabs() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Library...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
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
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
    );
  }

  Widget _buildCombinedList(String userId) {
    return StreamBuilder<Map<String, List<LibraryItem>>>(
      stream: _firestoreService.streamAllItems(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allItems = snapshot.data!.values.expand((list) => list).toList();
        allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return _buildContentList(allItems, userId, 'all');
      },
    );
  }

  Widget _buildLibraryList(String userId, String type) {
    return StreamBuilder<List<LibraryItem>>(
      stream: _getStreamForType(userId, type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContentList(snapshot.data ?? [], userId, type);
      },
    );
  }
  
  Widget _buildContentList(List<LibraryItem> items, String userId, String type) {
    final filteredItems = items.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return ListTile(
          title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(item.type.toString().split('.').last, style: TextStyle(color: Colors.grey[400])),
          trailing: IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () => _showItemMenu(userId, item)),
          onTap: () => _navigateToContent(userId, item),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://firebasestorage.googleapis.com/v0/b/genie-a0445.appspot.com/o/images%2Fempty_library.png?alt=media&token=eb3b6c7a-4c27-4048-812e-1e9a26c4f877', height: 200),
              const SizedBox(height: 32),
              Text('No ${type == 'all' ? 'items' : type} found', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'You haven\'t added any items to your library yet. Start exploring and save your favorite content.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => showModalBottomSheet(context: context, builder: (context) => const AddContentModal()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: const Text('Add Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Offline Mode', style: TextStyle(color: Colors.white)),
            value: _isOfflineMode,
            onChanged: _setOfflineMode,
            secondary: const Icon(Icons.signal_cellular_off, color: Colors.white),
          ),
          const Divider(color: Colors.grey),
          const Text('My Content', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildContentCategory(user.uid, 'Summaries', Icons.description, 'summaries'),
          _buildContentCategory(user.uid, 'Quizzes', Icons.quiz, 'quizzes'),
          _buildContentCategory(user.uid, 'Flashcards', Icons.style, 'flashcards'),
        ],
      ),
    );
  }
  
  Widget _buildContentCategory(String userId, String title, IconData icon, String type) {
    return StreamBuilder<List<LibraryItem>>(
      stream: _getStreamForType(userId, type),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle: Text('$count items', style: TextStyle(color: Colors.grey[400])),
        );
      },
    );
  }

  Stream<List<LibraryItem>> _getStreamForType(String userId, String type) {
    return _firestoreService.streamItems(userId, type);
  }

  void _showItemMenu(String userId, LibraryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.edit, color: Colors.white), title: const Text('Edit', style: TextStyle(color: Colors.white)), onTap: () => { Navigator.pop(context), _editContent(userId, item) }),
          ListTile(leading: const Icon(Icons.delete, color: Colors.white), title: const Text('Delete', style: TextStyle(color: Colors.white)), onTap: () => { Navigator.pop(context), _deleteContent(userId, item) }),
        ],
      ),
    );
  }

  Future<void> _navigateToContent(String userId, LibraryItem item) async {
    final content = await _firestoreService.getSpecificItem(userId, item);
    if (content != null && mounted) {
      Widget screen;
      if (content is Summary) {
        screen = SummaryScreen(summary: content);
      } else if (content is Quiz) {
        screen = QuizScreen(quiz: content);
      } else if (content is FlashcardSet) {
        screen = FlashcardsScreen(flashcardSet: content);
      } else {
        return;
      }
      
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    }
  }

  Future<void> _editContent(String userId, LibraryItem item) async {
    final content = await _firestoreService.getSpecificItem(userId, item);
    if (content != null && mounted) {
      EditableContent editableContent;
      if (content is Summary) {
        editableContent = EditableContent.fromSummary(content.id, content.content, content.timestamp);
      } else if (content is Quiz) {
        editableContent = EditableContent.fromQuiz(content.id, content.title, content.questions, content.timestamp);
      } else if (content is FlashcardSet) {
        editableContent = EditableContent.fromFlashcardSet(content.id, content.title, content.flashcards, content.timestamp);
      } else {
        return;
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) => EditContentScreen(content: editableContent)));
    }
  }

  Future<void> _deleteContent(String userId, LibraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await _firestoreService.deleteItem(userId, item);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content deleted')));
      }
    }
  }
}
