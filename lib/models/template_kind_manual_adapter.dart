import 'package:hive/hive.dart';
import 'template_file.dart'; // nơi khai báo enum TemplateKind

class TemplateKindManualAdapter extends TypeAdapter<TemplateKind> {
  @override
  final int typeId = 63; // KHÔNG ĐƯỢC ĐỔI

  @override
  TemplateKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return TemplateKind.docx;
      case 1: return TemplateKind.xlsx;
      default: return TemplateKind.docx;
    }
  }

  @override
  void write(BinaryWriter writer, TemplateKind obj) {
    switch (obj) {
      case TemplateKind.docx: writer.writeByte(0); break;
      case TemplateKind.xlsx: writer.writeByte(1); break;
    }
  }
}
