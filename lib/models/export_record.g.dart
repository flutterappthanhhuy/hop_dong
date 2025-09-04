// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExportRecordAdapter extends TypeAdapter<ExportRecord> {
  @override
  final int typeId = 33;

  @override
  ExportRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportRecord(
      id: fields[0] as String,
      templateId: fields[1] as String,
      templateName: fields[2] as String,
      data: (fields[3] as Map).cast<String, String>(),
      outputPath: fields[4] as String,
      outputType: fields[5] as String,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExportRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.templateName)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.outputPath)
      ..writeByte(5)
      ..write(obj.outputType)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
