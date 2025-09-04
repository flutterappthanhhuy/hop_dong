import 'dart:io' show File; // vẫn giữ cho Mobile/Desktop
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import '../models/template_file.dart';
import 'docx_field_scanner.dart';
import 'xlsx_field_scanner.dart';

class TemplateStore {
  static const boxName = 'template_files';
  static const _metaVersionBox = 'template_meta';
  static const _metaFolderMapBox = 'template_folder_map';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<TemplateFile>(boxName);
    }
    if (!Hive.isBoxOpen(_metaVersionBox)) {
      await Hive.openBox(_metaVersionBox);
    }
    if (!Hive.isBoxOpen(_metaFolderMapBox)) {
      await Hive.openBox(_metaFolderMapBox);
    }
  }

  Box<TemplateFile> get _box => Hive.box<TemplateFile>(boxName);

  List<TemplateFile> getAll() => _box.values.toList();

  TemplateFile? getById(String id) => _box.get(id);

  Future<void> upsert(TemplateFile t) async => _box.put(t.id, t);

  Future<void> add(TemplateFile t) async => _box.put(t.id, t);

  Future<void> remove(String id) async {
    final t = _box.get(id);
    if (t != null) {
      try {
        final f = File(t.filePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      try {
        await t.delete();
      } catch (_) {
        await _box.delete(id);
      }
    }
    final meta = Hive.box(_metaVersionBox);
    final folders = Hive.box(_metaFolderMapBox);
    await meta.delete(id);
    await folders.delete(id);
  }

  Future<void> clear() async => _box.clear();

  // ======================= VERSION =======================
  Future<void> bumpVersion(String id) async {
    final meta = Hive.box(_metaVersionBox);
    final cur = (meta.get(id) as int?) ?? 0;
    await meta.put(id, cur + 1);
  }

  Future<int> getVersion(String id) async {
    final meta = Hive.box(_metaVersionBox);
    return (meta.get(id) as int?) ?? 0;
  }

  // ======================= FOLDER =======================
  Future<void> moveToFolder(String id, String? folderId) async {
    final t = _box.get(id);
    if (t != null) {
      t.templateFolderId = folderId;
      t.updatedAt = DateTime.now();
      await t.save();
    }
  }

  Future<String?> getFolderId(String templateId) async {
    final folders = Hive.box(_metaFolderMapBox);
    final v = folders.get(templateId);
    return (v is String) ? v : null;
  }

  Future<Map<String, String?>> getAllFolderMap() async {
    final m = <String, String?>{};
    for (final t in _box.values) {
      m[t.id] = t.templateFolderId;
    }
    return m;
  }

  // ======================= IMPORT (Desktop/Mobile) =======================
  Future<TemplateFile> importTemplate(String filePath, {String? folderId}) async {
    final ext = p.extension(filePath).toLowerCase();
    List<String> fields = [];
    TemplateKind kind;

    if (ext == '.docx') {
      fields = await DocxFieldScanner.scanFields(filePath);
      kind = TemplateKind.docx;
    } else if (ext == '.xlsx') {
      fields = await XlsxFieldScanner.scanFields(filePath);
      kind = TemplateKind.xlsx;
    } else {
      throw UnsupportedError('File không được hỗ trợ: $ext');
    }

    final t = TemplateFile(
      id: const Uuid().v4(),
      name: p.basename(filePath),
      kind: kind,
      filePath: filePath,
      fields: fields,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      templateFolderId: folderId,
    );

    await add(t);
    return t;
  }

  // ======================= IMPORT (Web dùng bytes) =======================
  Future<TemplateFile> importTemplateBytes(
      Uint8List bytes, {
        required String fileName,
        required String ext,
        required TemplateKind kind,
        String? folderId,
      }) async {
    final id = const Uuid().v4();
    final fakePath = 'web_$id$ext';

    List<String> fields = [];
    if (kind == TemplateKind.docx) {
      fields = await DocxFieldScanner.scanFieldsFromBytes(bytes);
    } else if (kind == TemplateKind.xlsx) {
      fields = await XlsxFieldScanner.scanFieldsFromBytes(bytes);
    }

    final t = TemplateFile(
      id: id,
      name: fileName,
      kind: kind,
      filePath: fakePath,
      fields: fields,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      templateFolderId: folderId,
    );

    await add(t);
    return t;
  }
}
