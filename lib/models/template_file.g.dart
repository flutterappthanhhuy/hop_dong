// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateFileAdapter extends TypeAdapter<TemplateFile> {
  @override
  final int typeId = 180;

  @override
  TemplateFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateFile(
      id: fields[0] as String,
      name: fields[1] as String,
      kind: fields[2] as TemplateKind,
      filePath: fields[3] as String,
      fields: (fields[4] as List).cast<String>(),
      xlsxMapping: (fields[5] as Map?)?.cast<String, String>(),
      category: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
      fileNamePattern: fields[9] as String?,
      version: fields[10] as int,
      templateFolderId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateFile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.fields)
      ..writeByte(5)
      ..write(obj.xlsxMapping)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.fileNamePattern)
      ..writeByte(10)
      ..write(obj.version)
      ..writeByte(11)
      ..write(obj.templateFolderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TemplateKindAdapter extends TypeAdapter<TemplateKind> {
  @override
  final int typeId = 63;

  @override
  TemplateKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TemplateKind.docx;
      case 1:
        return TemplateKind.xlsx;
      default:
        return TemplateKind.docx;
    }
  }

  @override
  void write(BinaryWriter writer, TemplateKind obj) {
    switch (obj) {
      case TemplateKind.docx:
        writer.writeByte(0);
        break;
      case TemplateKind.xlsx:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
