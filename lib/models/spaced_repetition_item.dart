import 'package:hive/hive.dart';

part 'spaced_repetition_item.g.dart';

@HiveType(typeId: 4)
class SpacedRepetitionItem extends HiveObject {
  @HiveField(0)
  late String contentId;

  @HiveField(1)
  late String contentType;

  @HiveField(2)
  late int repetitionCount;

  @HiveField(3)
  late DateTime lastReviewed;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;

  SpacedRepetitionItem({
    required this.contentId,
    required this.contentType,
    this.repetitionCount = 0,
    required this.lastReviewed,
    required this.createdAt,
    required this.updatedAt,
  });
}
