import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/local_summary.dart';
import '../models/local_quiz.dart';
import '../models/local_quiz_question.dart';
import '../models/local_flashcard.dart';
import '../models/local_flashcard_set.dart';
import '../models/folder.dart';
import '../models/content_folder.dart';
import '../models/spaced_repetition.dart';

class LocalDatabaseService {
  static const String _summariesBoxName = 'summaries';
  static const String _quizzesBoxName = 'quizzes';
  static const String _flashcardSetsBoxName = 'flashcardSets';
  static const String _foldersBoxName = 'folders';
  static const String _contentFoldersBoxName = 'contentFolders';
  static const String _spacedRepetitionBoxName = 'spaced_repetition';

  late Box<LocalSummary> _summariesBox;
  late Box<LocalQuiz> _quizzesBox;
  late Box<LocalFlashcardSet> _flashcardSetsBox;
  late Box<Folder> _foldersBox;
  late Box<ContentFolder> _contentFoldersBox;
  late Box<SpacedRepetitionItem> _spacedRepetitionBox;

  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(LocalSummaryAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LocalQuizAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LocalQuizQuestionAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(LocalFlashcardAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(LocalFlashcardSetAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(FolderAdapter());
      if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(ContentFolderAdapter());
      if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(SpacedRepetitionItemAdapter());
      
      _summariesBox = await Hive.openBox<LocalSummary>(_summariesBoxName);
      _quizzesBox = await Hive.openBox<LocalQuiz>(_quizzesBoxName);
      _flashcardSetsBox = await Hive.openBox<LocalFlashcardSet>(_flashcardSetsBoxName);
      _foldersBox = await Hive.openBox<Folder>(_foldersBoxName);
      _contentFoldersBox = await Hive.openBox<ContentFolder>(_contentFoldersBoxName);
      _spacedRepetitionBox = await Hive.openBox<SpacedRepetitionItem>(_spacedRepetitionBoxName);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local database: $e');
      rethrow;
    }
  }

  // Summary operations
  Future<void> saveSummary(LocalSummary summary) async {
    await _summariesBox.put(summary.id, summary);
  }

  Future<LocalSummary?> getSummary(String id) async {
    return _summariesBox.get(id);
  }

  Future<List<LocalSummary>> getAllSummaries(String userId) async {
    return _summariesBox.values
        .where((summary) => summary.userId == userId)
        .toList();
  }

  Future<void> deleteSummary(String id) async {
    await _summariesBox.delete(id);
  }

  Future<void> updateSummarySyncStatus(String id, bool isSynced) async {
    final summary = await getSummary(id);
    if (summary != null) {
      summary.isSynced = isSynced;
      await saveSummary(summary);
    }
  }

  // Quiz operations
  Future<void> saveQuiz(LocalQuiz quiz) async {
    await _quizzesBox.put(quiz.id, quiz);
  }

  Future<LocalQuiz?> getQuiz(String id) async {
    return _quizzesBox.get(id);
  }

  Future<List<LocalQuiz>> getAllQuizzes(String userId) async {
    return _quizzesBox.values
        .where((quiz) => quiz.userId == userId)
        .toList();
  }

  Future<void> deleteQuiz(String id) async {
    await _quizzesBox.delete(id);
  }

  Future<void> updateQuizSyncStatus(String id, bool isSynced) async {
    final quiz = await getQuiz(id);
    if (quiz != null) {
      quiz.isSynced = isSynced;
      await saveQuiz(quiz);
    }
  }

  // Flashcard set operations
  Future<void> saveFlashcardSet(LocalFlashcardSet flashcardSet) async {
    await _flashcardSetsBox.put(flashcardSet.id, flashcardSet);
  }

  Future<LocalFlashcardSet?> getFlashcardSet(String id) async {
    return _flashcardSetsBox.get(id);
  }

  Future<List<LocalFlashcardSet>> getAllFlashcardSets(String userId) async {
    return _flashcardSetsBox.values
        .where((set) => set.userId == userId)
        .toList();
  }

  Future<void> deleteFlashcardSet(String id) async {
    await _flashcardSetsBox.delete(id);
  }

  Future<void> updateFlashcardSetSyncStatus(String id, bool isSynced) async {
    final flashcardSet = await getFlashcardSet(id);
    if (flashcardSet != null) {
      flashcardSet.isSynced = isSynced;
      await saveFlashcardSet(flashcardSet);
    }
  }

  // Folder operations
  Future<void> saveFolder(Folder folder) async {
    await _foldersBox.put(folder.id, folder);
  }

  Future<Folder?> getFolder(String id) async {
    return _foldersBox.get(id);
  }

  Future<List<Folder>> getAllFolders(String userId) async {
    return _foldersBox.values
        .where((folder) => folder.userId == userId)
        .toList();
  }

  Future<void> deleteFolder(String id) async {
    await _foldersBox.delete(id);
  }

  Future<void> updateFolder(String id, String newName) async {
    final folder = await getFolder(id);
    if (folder != null) {
      folder.name = newName;
      folder.updatedAt = DateTime.now();
      await saveFolder(folder);
    }
  }

  // Content-Folder relationship operations
  Future<void> assignContentToFolder(String contentId, String folderId, String contentType, String userId) async {
    final contentFolder = ContentFolder(
      contentId: contentId,
      folderId: folderId,
      contentType: contentType,
      userId: userId,
      assignedAt: DateTime.now(),
    );
    await _contentFoldersBox.add(contentFolder);
  }

  Future<List<ContentFolder>> getContentFolders(String contentId) async {
    return _contentFoldersBox.values
        .where((cf) => cf.contentId == contentId)
        .toList();
  }

  Future<List<ContentFolder>> getFolderContents(String folderId) async {
    return _contentFoldersBox.values
        .where((cf) => cf.folderId == folderId)
        .toList();
  }

  Future<void> removeContentFromFolder(String contentId, String folderId) async {
    final contentFolders = _contentFoldersBox.values
        .where((cf) => cf.contentId == contentId && cf.folderId == folderId)
        .toList();
    
    for (final cf in contentFolders) {
      await _contentFoldersBox.delete(cf.key);
    }
  }

  Future<void> clearAllData() async {
    await _summariesBox.clear();
    await _quizzesBox.clear();
    await _flashcardSetsBox.clear();
    await _foldersBox.clear();
    await _contentFoldersBox.clear();
  }

  Future<int> getUnsyncedCount(String userId) async {
    final unsyncedSummaries = _summariesBox.values
        .where((s) => s.userId == userId && !s.isSynced)
        .length;
    
    final unsyncedQuizzes = _quizzesBox.values
        .where((q) => q.userId == userId && !q.isSynced)
        .length;
    
    final unsyncedFlashcardSets = _flashcardSetsBox.values
        .where((fs) => fs.userId == userId && !fs.isSynced)
        .length;
    
    return unsyncedSummaries + unsyncedQuizzes + unsyncedFlashcardSets;
  }

  // Spaced repetition operations
  Future<void> saveSpacedRepetitionItem(SpacedRepetitionItem item) async {
    await _spacedRepetitionBox.put(item.id, item);
  }

  Future<SpacedRepetitionItem?> getSpacedRepetitionItem(String id) async {
    return _spacedRepetitionBox.get(id);
  }

  Future<List<SpacedRepetitionItem>> getAllSpacedRepetitionItems(String userId) async {
    return _spacedRepetitionBox.values
        .where((item) => item.userId == userId)
        .toList();
  }

  Future<List<SpacedRepetitionItem>> getDueSpacedRepetitionItems(String userId, DateTime now) async {
    return _spacedRepetitionBox.values
        .where((item) => item.userId == userId && item.nextReviewDate.isBefore(now))
        .toList();
  }

  Future<void> deleteSpacedRepetitionItem(String id) async {
    await _spacedRepetitionBox.delete(id);
  }
}
