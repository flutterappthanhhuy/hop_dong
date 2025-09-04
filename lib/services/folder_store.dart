import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/template_folder.dart';

class FolderStore {
  static const boxName = 'template_folders';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(35)) Hive.registerAdapter(TemplateFolderAdapter());
    if (!Hive.isBoxOpen(boxName)) await Hive.openBox<TemplateFolder>(boxName);
  }

  Box<TemplateFolder> get _box => Hive.box<TemplateFolder>(boxName);

  List<TemplateFolder> getAll() => _box.values.toList();

  Future<TemplateFolder> create(String name) async {
    final f = TemplateFolder(id: const Uuid().v4(), name: name, createdAt: DateTime.now());
    await _box.put(f.id, f);
    return f;
  }

  Future<void> rename(String id, String name) async {
    final f = _box.get(id);
    if (f != null) { f.name = name; await f.save(); }
  }

  Future<void> remove(String id) async {
    final f = _box.get(id);
    if (f != null) { await f.delete(); }
  }
}
