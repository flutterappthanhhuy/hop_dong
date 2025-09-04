// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exported_contract.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExportedContractAdapter extends TypeAdapter<ExportedContract> {
  @override
  final int typeId = 200;

  @override
  ExportedContract read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportedContract(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String,
      createdAt: fields[3] as DateTime,
      folderId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExportedContract obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.folderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportedContractAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
