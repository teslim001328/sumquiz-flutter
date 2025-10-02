// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaced_repetition_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpacedRepetitionItemAdapter extends TypeAdapter<SpacedRepetitionItem> {
  @override
  final int typeId = 4;

  @override
  SpacedRepetitionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpacedRepetitionItem(
      contentId: fields[0] as String,
      contentType: fields[1] as String,
      repetitionCount: fields[2] as int,
      lastReviewed: fields[3] as DateTime,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SpacedRepetitionItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.contentId)
      ..writeByte(1)
      ..write(obj.contentType)
      ..writeByte(2)
      ..write(obj.repetitionCount)
      ..writeByte(3)
      ..write(obj.lastReviewed)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
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
