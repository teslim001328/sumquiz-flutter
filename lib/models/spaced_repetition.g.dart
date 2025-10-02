// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaced_repetition.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpacedRepetitionItemAdapter extends TypeAdapter<SpacedRepetitionItem> {
  @override
  final int typeId = 8;

  @override
  SpacedRepetitionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpacedRepetitionItem(
      id: fields[0] as String,
      userId: fields[1] as String,
      contentId: fields[2] as String,
      contentType: fields[3] as String,
      nextReviewDate: fields[4] as DateTime,
      interval: fields[5] as int,
      easeFactor: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SpacedRepetitionItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.contentId)
      ..writeByte(3)
      ..write(obj.contentType)
      ..writeByte(4)
      ..write(obj.nextReviewDate)
      ..writeByte(5)
      ..write(obj.interval)
      ..writeByte(6)
      ..write(obj.easeFactor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpacedRepetitionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
