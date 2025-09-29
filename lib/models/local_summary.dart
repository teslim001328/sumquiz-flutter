import 'package:hive/hive.dart';

part 'local_summary.g.dart';

@HiveType(typeId: 0)
class LocalSummary extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String content;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late bool isSynced;

  @HiveField(4)
  late String userId;

  LocalSummary({
    required this.id,
    required this.content,
    required this.timestamp,
    this.isSynced = false,
    required this.userId,
  });

  LocalSummary.empty() {
    id = '';
    content = '';
    timestamp = DateTime.now();
    isSynced = false;
    userId = '';
  }
}