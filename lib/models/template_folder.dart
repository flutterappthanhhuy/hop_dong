import 'package:hive/hive.dart';
part 'template_folder.g.dart';

@HiveType(typeId: 35)
class TemplateFolder extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) DateTime createdAt;

  TemplateFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
