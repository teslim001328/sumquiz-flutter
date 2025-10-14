import 'package:hive/hive.dart';
import 'local_quiz_question.dart';

part 'local_quiz.g.dart';

@HiveType(typeId: 1)
class LocalQuiz extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late List<LocalQuizQuestion> questions;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late bool isSynced;

  @HiveField(5)
  late String userId;

  LocalQuiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.timestamp,
    this.isSynced = false,
    required this.userId,
  });

  LocalQuiz.empty() {
    id = '';
    title = '';
    questions = [];
    timestamp = DateTime.now();
    isSynced = false;
    userId = '';
  }
}
