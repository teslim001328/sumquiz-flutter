// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalSummaryAdapter extends TypeAdapter<LocalSummary> {
  @override
  final int typeId = 0;

  @override
  LocalSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSummary(
      id: fields[0] as String,
      content: fields[1] as String,
      timestamp: fields[2] as DateTime,
      isSynced: fields[3] as bool,
      userId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSummary obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
