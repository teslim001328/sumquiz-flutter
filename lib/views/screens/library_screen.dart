import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/library_item.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../screens/summary_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/flashcards_screen.dart';
import '../widgets/upgrade_modal.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const UpgradeModal(),
    );
  }

  void _navigateToCreationScreen(int tabIndex, UserModel user) {
    if (!_firestoreService.canGenerate(_getToolType(tabIndex), user)) {
      _showUpgradeDialog();
      return;
    }

    switch (tabIndex) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SummaryScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardsScreen()));
        break;
    }
  }

  String _getToolType(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'summaries';
      case 1:
        return 'quizzes';
      case 2:
        return 'flashcards';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final userModel = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summaries'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Flashcards'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: Text(
                  'You are offline - displaying saved content.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLibraryList(user, 'summaries'),
                _buildLibraryList(user, 'quizzes'),
                _buildLibraryList(user, 'flashcards'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (userModel != null) {
            _navigateToCreationScreen(_tabController.index, userModel);
          }
        },
        label: const Text('Create New'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLibraryList(User? user, String type) {
    if (user == null) {
      return const Center(child: Text('Please log in to see your library.'));
    }

    return StreamBuilder<List<LibraryItem>>(
      stream: _getStreamForType(user.uid, type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  item.title,
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Created on ${DateFormat.yMMMd().format(item.createdAt.toDate())}',
                  style: GoogleFonts.openSans(),
                ),
                trailing: Text(
                  item.content,
                  style: GoogleFonts.openSans(color: Colors.grey[600]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<List<LibraryItem>> _getStreamForType(String userId, String type) {
    switch (type) {
      case 'summaries':
        return _firestoreService.streamSummaries(userId);
      case 'quizzes':
        return _firestoreService.streamQuizzes(userId);
      case 'flashcards':
        return _firestoreService.streamFlashcards(userId);
      default:
        return Stream.value([]);
    }
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No $type yet',
            style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new one to get started',
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
