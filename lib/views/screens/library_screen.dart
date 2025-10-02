import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/library_item.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/local_database_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/word_export_service.dart';
import '../../services/sharing_service.dart';
import '../screens/summary_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/flashcards_screen.dart';
import '../widgets/upgrade_modal.dart';
import '../../models/editable_content.dart';
import '../../models/summary_model.dart';
import '../../models/quiz_model.dart';
import '../../models/flashcard_model.dart';
import '../screens/edit_content_screen.dart';
import '../../models/folder.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  bool _isOffline = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<LibraryItem> _allItems = [];
  List<LibraryItem> _filteredItems = [];
  List<Folder> _folders = [];
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
    
    // Load folders
    _loadFolders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadFolders() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      try {
        final folders = await _localDb.getAllFolders(user.uid);
        setState(() {
          _folders = folders;
        });
      } catch (e) {
        print('Error loading folders: $e');
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const UpgradeModal(),
    );
  }

  Future<void> _navigateToCreationScreen(int tabIndex, UserModel user) async {
    final canGenerate = await _firestoreService.canGenerate(user.uid, _getToolType(tabIndex));
    if (!mounted) return;
    if (!canGenerate) {
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

  Future<void> _createFolder() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    final folderNameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: folderNameController,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(folderNameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final folder = Folder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result,
          userId: user.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _localDb.saveFolder(folder);
        await _loadFolders();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating folder: $e')),
        );
      }
    }
  }

  Future<void> _renameFolder(Folder folder) async {
    final folderNameController = TextEditingController(text: folder.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: folderNameController,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(folderNameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _localDb.updateFolder(folder.id, result);
        await _loadFolders();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder renamed successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming folder: $e')),
        );
      }
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete the folder "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _localDb.deleteFolder(folder.id);
        await _loadFolders();
        
        // If this was the selected folder, clear the selection
        if (_selectedFolderId == folder.id) {
          setState(() {
            _selectedFolderId = null;
          });
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting folder: $e')),
        );
      }
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'create_folder') {
                _createFolder();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'create_folder',
                child: Text('Create Folder'),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildFoldersDrawer(),
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search library...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          // Folder selector
          if (_folders.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFolderId == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFolderId = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._folders.map((folder) => ChoiceChip(
                        label: Text(folder.name),
                        selected: _selectedFolderId == folder.id,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFolderId = selected ? folder.id : null;
                          });
                        },
                      )),
                ],
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

  Widget _buildFoldersDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Text(
              'Folders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('All Content'),
                  selected: _selectedFolderId == null,
                  onTap: () {
                    setState(() {
                      _selectedFolderId = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(),
                ..._folders.map((folder) => ListTile(
                      title: Text(folder.name),
                      selected: _selectedFolderId == folder.id,
                      onTap: () {
                        setState(() {
                          _selectedFolderId = folder.id;
                        });
                        Navigator.of(context).pop();
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (String result) {
                          if (result == 'rename') {
                            _renameFolder(folder);
                          } else if (result == 'delete') {
                            _deleteFolder(folder);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('Create New Folder'),
            onTap: () {
              Navigator.of(context).pop();
              _createFolder();
            },
          ),
        ],
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

        _allItems = snapshot.data ?? [];
        _filteredItems = _allItems.where((item) {
          // Apply search filter
          final matchesSearch = item.title.toLowerCase().contains(_searchQuery);
          
          // Apply folder filter if a folder is selected
          if (_selectedFolderId != null) {
            // In a real implementation, we would check if the item is in the selected folder
            // For now, we'll just return true to show all items
            return matchesSearch;
          }
          
          return matchesSearch;
        }).toList();

        if (_filteredItems.isEmpty) {
          return _buildEmptyState(_searchQuery.isEmpty ? type : 'search results');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _filteredItems.length,
          itemBuilder: (context, index) {
            final item = _filteredItems[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  item.title,
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Created on ${DateFormat.yMMMd().format(item.timestamp.toDate())}',
                  style: GoogleFonts.openSans(),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String result) {
                    if (result == 'edit') {
                      _editContent(user.uid, item, type);
                    } else if (result == 'delete') {
                      _deleteContent(user.uid, item, type);
                    } else if (result == 'assign_folder') {
                      _assignToFolder(item, type);
                    } else if (result == 'export_pdf') {
                      _exportToPdf(user.uid, item, type);
                    } else if (result == 'export_word') {
                      _exportToWord(user.uid, item, type);
                    } else if (result == 'share') {
                      _shareContent(user.uid, item, type);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'assign_folder',
                      child: Text('Assign to Folder'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'export_pdf',
                      child: Text('Export as PDF'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export_word',
                      child: Text('Export as Word'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Share'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignToFolder(LibraryItem item, String type) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null || _folders.isEmpty) return;

    final selectedFolderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _folders
                .map((folder) => ListTile(
                      title: Text(folder.name),
                      onTap: () => Navigator.of(context).pop(folder.id),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedFolderId != null) {
      try {
        // Save the relationship to the local database
        final contentType = type == 'summaries' 
            ? 'summary' 
            : type == 'quizzes' 
                ? 'quiz' 
                : 'flashcard';
                
        await _localDb.assignContentToFolder(
          item.id, 
          selectedFolderId, 
          contentType, 
          user.uid
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content assigned to folder!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning to folder: $e')),
        );
      }
    }
  }

  Future<void> _editContent(String userId, LibraryItem item, String type) async {
    // Fetch the full content based on type
    EditableContent? editableContent;
    
    switch (type) {
      case 'summaries':
        // Fetch the summary content
        final summaryDoc = await _firestoreService.db
            .collection('users')
            .doc(userId)
            .collection('summaries')
            .doc(item.id)
            .get();
        if (summaryDoc.exists) {
          final summary = Summary.fromFirestore(summaryDoc);
          editableContent = EditableContent.fromSummary(
            summary.id,
            summary.content,
            summary.timestamp,
          );
        }
        break;
      case 'quizzes':
        // Fetch the quiz content
        final quizDoc = await _firestoreService.db
            .collection('users')
            .doc(userId)
            .collection('quizzes')
            .doc(item.id)
            .get();
        if (quizDoc.exists) {
          final quiz = Quiz.fromFirestore(quizDoc);
          editableContent = EditableContent.fromQuiz(
            quiz.id,
            quiz.title,
            quiz.questions,
            quiz.timestamp,
          );
        }
        break;
      case 'flashcards':
        // Fetch the flashcard content
        final flashcardDoc = await _firestoreService.db
            .collection('users')
            .doc(userId)
            .collection('flashcard_sets')
            .doc(item.id)
            .get();
        if (flashcardDoc.exists) {
          final flashcardSet = FlashcardSet.fromFirestore(flashcardDoc);
          editableContent = EditableContent.fromFlashcardSet(
            flashcardSet.id,
            flashcardSet.title,
            flashcardSet.flashcards,
            flashcardSet.timestamp,
          );
        }
        break;
    }

    if (editableContent != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditContentScreen(content: editableContent!),
        ),
      );

      // If content was saved, refresh the list
      if (result == true) {
        setState(() {});
      }
    }
  }

  Future<void> _deleteContent(String userId, LibraryItem item, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        switch (type) {
          case 'summaries':
            await _firestoreService.db
                .collection('users')
                .doc(userId)
                .collection('summaries')
                .doc(item.id)
                .delete();
            break;
          case 'quizzes':
            await _firestoreService.db
                .collection('users')
                .doc(userId)
                .collection('quizzes')
                .doc(item.id)
                .delete();
            break;
          case 'flashcards':
            await _firestoreService.db
                .collection('users')
                .doc(userId)
                .collection('flashcard_sets')
                .doc(item.id)
                .delete();
            break;
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content deleted successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting content: $e')),
        );
      }
    }
  }

  Future<void> _exportToPdf(String userId, LibraryItem item, String type) async {
    try {
      String filePath = '';
      
      switch (type) {
        case 'summaries':
          final summaryDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('summaries')
              .doc(item.id)
              .get();
          if (summaryDoc.exists) {
            final summary = Summary.fromFirestore(summaryDoc);
            filePath = await PdfExportService().exportSummary(summary);
          }
          break;
        case 'quizzes':
          final quizDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('quizzes')
              .doc(item.id)
              .get();
          if (quizDoc.exists) {
            final quiz = Quiz.fromFirestore(quizDoc);
            filePath = await PdfExportService().exportQuiz(quiz);
          }
          break;
        case 'flashcards':
          final flashcardDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('flashcard_sets')
              .doc(item.id)
              .get();
          if (flashcardDoc.exists) {
            final flashcardSet = FlashcardSet.fromFirestore(flashcardDoc);
            filePath = await PdfExportService().exportFlashcardSet(flashcardSet);
          }
          break;
      }

      if (filePath.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to PDF: $filePath')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to PDF: $e')),
      );
    }
  }

  Future<void> _exportToWord(String userId, LibraryItem item, String type) async {
    try {
      String filePath = '';
      
      switch (type) {
        case 'summaries':
          final summaryDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('summaries')
              .doc(item.id)
              .get();
          if (summaryDoc.exists) {
            final summary = Summary.fromFirestore(summaryDoc);
            filePath = await WordExportService().exportSummary(summary);
          }
          break;
        case 'quizzes':
          final quizDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('quizzes')
              .doc(item.id)
              .get();
          if (quizDoc.exists) {
            final quiz = Quiz.fromFirestore(quizDoc);
            filePath = await WordExportService().exportQuiz(quiz);
          }
          break;
        case 'flashcards':
          final flashcardDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('flashcard_sets')
              .doc(item.id)
              .get();
          if (flashcardDoc.exists) {
            final flashcardSet = FlashcardSet.fromFirestore(flashcardDoc);
            filePath = await WordExportService().exportFlashcardSet(flashcardSet);
          }
          break;
      }

      if (filePath.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to Word: $filePath')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to Word: $e')),
      );
    }
  }

  Future<void> _shareContent(String userId, LibraryItem item, String type) async {
    try {
      switch (type) {
        case 'summaries':
          final summaryDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('summaries')
              .doc(item.id)
              .get();
          if (summaryDoc.exists) {
            final summary = Summary.fromFirestore(summaryDoc);
            await SharingService().shareSummary(summary);
          }
          break;
        case 'quizzes':
          final quizDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('quizzes')
              .doc(item.id)
              .get();
          if (quizDoc.exists) {
            final quiz = Quiz.fromFirestore(quizDoc);
            await SharingService().shareQuiz(quiz);
          }
          break;
        case 'flashcards':
          final flashcardDoc = await _firestoreService.db
              .collection('users')
              .doc(userId)
              .collection('flashcard_sets')
              .doc(item.id)
              .get();
          if (flashcardDoc.exists) {
            final flashcardSet = FlashcardSet.fromFirestore(flashcardDoc);
            await SharingService().shareFlashcardSet(flashcardSet);
          }
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing content: $e')),
      );
    }
  }

  Stream<List<LibraryItem>> _getStreamForType(String userId, String type) {
    switch (type) {
      case 'summaries':
        return _firestoreService.streamSummaries(userId).map((summaries) => summaries
            .map((s) => LibraryItem(
                  id: s.id, 
                  title: s.content, 
                  type: LibraryItemType.summary, 
                  timestamp: s.timestamp,
                  // In a real implementation, we would fetch folder assignments
                ))
            .toList());
      case 'quizzes':
        return _firestoreService.streamQuizzes(userId).map((quizzes) => quizzes
            .map((q) => LibraryItem(
                  id: q.id, 
                  title: q.title, 
                  type: LibraryItemType.quiz, 
                  timestamp: q.timestamp,
                  // In a real implementation, we would fetch folder assignments
                ))
            .toList());
      case 'flashcards':
        return _firestoreService.streamFlashcardSets(userId).map((flashcards) => flashcards
            .map((f) => LibraryItem(
                  id: f.id, 
                  title: f.title, 
                  type: LibraryItemType.flashcards, 
                  timestamp: f.timestamp,
                  // In a real implementation, we would fetch folder assignments
                ))
            .toList());
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
            'No $type found',
            style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Create a new one to get started' 
                : 'Try a different search term',
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}