// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_flashcard_set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalFlashcardSetAdapter extends TypeAdapter<LocalFlashcardSet> {
  @override
  final int typeId = 4;

  @override
  LocalFlashcardSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalFlashcardSet(
      id: fields[0] as String,
      title: fields[1] as String,
      flashcards: (fields[2] as List).cast<LocalFlashcard>(),
      timestamp: fields[3] as DateTime,
      isSynced: fields[4] as bool,
      userId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalFlashcardSet obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.flashcards)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFlashcardSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}