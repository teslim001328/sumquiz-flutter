import 'package:hive/hive.dart';

part 'local_flashcard.g.dart';

@HiveType(typeId: 3)
class LocalFlashcard extends HiveObject {
  @HiveField(0)
  late String question;

  @HiveField(1)
  late String answer;

  LocalFlashcard({
    required this.question,
    required this.answer,
  });

  LocalFlashcard.empty() {
    question = '';
    answer = '';
  }
}