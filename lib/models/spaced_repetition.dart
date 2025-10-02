import 'package:hive/hive.dart';

part 'spaced_repetition.g.dart';

@HiveType(typeId: 8)
class SpacedRepetitionItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String contentId;

  @HiveField(3)
  String contentType;

  @HiveField(4)
  DateTime nextReviewDate;

  @HiveField(5)
  int interval;

  @HiveField(6)
  double easeFactor;

  SpacedRepetitionItem({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.nextReviewDate,
    this.interval = 1,
    this.easeFactor = 2.5,
  });
}
