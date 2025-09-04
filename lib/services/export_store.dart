import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/exported_contract.dart';

class ExportStore {
  static const boxName = 'exported_contracts';
  final _uuid = const Uuid();

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<ExportedContract>(boxName);
    }
  }

  Box<ExportedContract> get _box => Hive.box<ExportedContract>(boxName);

  List<ExportedContract> getAll() =>
      _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> add(String name, String filePath, {String? folderId}) async {
    final id = _uuid.v4();
    final ec = ExportedContract(
      id: id,
      name: name,
      filePath: filePath,
      createdAt: DateTime.now(),
      folderId: folderId,
    );
    await _box.put(id, ec);
  }

  Future<void> moveToFolder(String id, String? folderId) async {
    final ec = _box.get(id);
    if (ec != null) {
      ec.folderId = folderId;
      await ec.save();
    }
  }

  Future<void> remove(String id) async => _box.delete(id);
}
