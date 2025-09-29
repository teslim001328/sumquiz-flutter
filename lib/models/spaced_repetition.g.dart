import 'package:hive/hive.dart';
import 'spaced_repetition.dart';

class SpacedRepetitionItemAdapter extends TypeAdapter<SpacedRepetitionItem> {
  @override
  final int typeId = 6; // Make sure this ID is unique

  @override
  SpacedRepetitionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return SpacedRepetitionItem(
      id: fields[0] as String,
      flashcardId: fields[1] as String,
      userId: fields[2] as String,
      nextReviewDate: fields[3] as DateTime,
      interval: fields[4] as int,
      easeFactor: fields[5] as double,
      repetitionCount: fields[6] as int,
      lastReviewed: fields[7] as DateTime,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SpacedRepetitionItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.flashcardId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.nextReviewDate)
      ..writeByte(4)
      ..write(obj.interval)
      ..writeByte(5)
      ..write(obj.easeFactor)
      ..writeByte(6)
      ..write(obj.repetitionCount)
      ..writeByte(7)
      ..write(obj.lastReviewed)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }
}