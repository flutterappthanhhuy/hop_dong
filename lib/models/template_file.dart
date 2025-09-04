import 'package:hive/hive.dart';
part 'template_file.g.dart';

@HiveType(typeId: 63)
enum TemplateKind {
  @HiveField(0) docx,
  @HiveField(1) xlsx,
}

@HiveType(typeId: 180)
class TemplateFile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  TemplateKind kind;

  @HiveField(3)
  String filePath; // path local tới file gốc mẫu

  @HiveField(4)
  List<String> fields; // với .docx: danh sách {{field}}

  @HiveField(5)
  Map<String, String>? xlsxMapping; // với .xlsx: field -> ô (A1)
  @HiveField(6) String? category; // NEW: phân loại
  @HiveField(7) DateTime? createdAt; // NEW
  @HiveField(8) DateTime? updatedAt; // NEW
// MỚI: pattern đặt tên file xuất, version, folder
  @HiveField(9)  String? fileNamePattern;   // vd: 'HD_{{so_hop_dong}}_{{dia_chi}}.docx'
  @HiveField(10) int version;               // tăng khi sửa fields/mapping/pattern
  @HiveField(11) String? templateFolderId;  // id folder chứa template



  TemplateFile({
    required this.id,
    required this.name,
    required this.kind,
    required this.filePath,
    this.fields = const [],
    this.xlsxMapping,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.fileNamePattern,
    this.version = 1,
    this.templateFolderId,
  });
}
