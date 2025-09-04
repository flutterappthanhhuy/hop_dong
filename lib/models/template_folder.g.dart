// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateFolderAdapter extends TypeAdapter<TemplateFolder> {
  @override
  final int typeId = 35;

  @override
  TemplateFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateFolder obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
