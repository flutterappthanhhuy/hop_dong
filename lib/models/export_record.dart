import 'package:hive/hive.dart';

part 'export_record.g.dart';

@HiveType(typeId: 33) // giữ nguyên typeId, tránh trùng với model khác
class ExportRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String templateId;

  @HiveField(2)
  String templateName;

  @HiveField(3)
  Map<String, String> data; // dữ liệu đã nhập

  @HiveField(4)
  String outputPath; // đường dẫn file xuất

  @HiveField(5)
  String outputType; // docx/xlsx/pdf

  @HiveField(6)
  DateTime createdAt;

  ExportRecord({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.data,
    required this.outputPath,
    required this.outputType,
    required this.createdAt,
  });

  /// 👉 thêm copyWith
  ExportRecord copyWith({
    String? id,
    String? templateId,
    String? templateName,
    Map<String, String>? data,
    String? outputPath,
    String? outputType,
    DateTime? createdAt,
  }) {
    return ExportRecord(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      data: data ?? this.data,
      outputPath: outputPath ?? this.outputPath,
      outputType: outputType ?? this.outputType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
