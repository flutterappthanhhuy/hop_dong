import 'package:hive/hive.dart';

part 'exported_contract.g.dart';

@HiveType(typeId: 200) // nhớ set typeId không trùng
class ExportedContract extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String filePath;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String? folderId; // để phân loại thư mục (nếu có)

  ExportedContract({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    this.folderId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'createdAt': createdAt.toIso8601String(),
    'folderId': folderId,
  };

  factory ExportedContract.fromMap(Map<String, dynamic> m) => ExportedContract(
    id: m['id'],
    name: m['name'],
    filePath: m['filePath'],
    createdAt: DateTime.parse(m['createdAt']),
    folderId: m['folderId'],
  );
}
