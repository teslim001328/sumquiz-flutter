import 'package:hive/hive.dart';
import 'local_flashcard.dart';

part 'local_flashcard_set.g.dart';

@HiveType(typeId: 4)
class LocalFlashcardSet extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late List<LocalFlashcard> flashcards;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late bool isSynced;

  @HiveField(5)
  late String userId;

  LocalFlashcardSet({
    required this.id,
    required this.title,
    required this.flashcards,
    required this.timestamp,
    this.isSynced = false,
    required this.userId,
  });

  LocalFlashcardSet.empty() {
    id = '';
    title = '';
    flashcards = [];
    timestamp = DateTime.now();
    isSynced = false;
    userId = '';
  }
}
