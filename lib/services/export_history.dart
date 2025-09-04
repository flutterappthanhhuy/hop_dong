import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/export_record.dart';

class ExportHistoryService {
  static const boxName = 'export_records';
  late Box<ExportRecord> _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(33)) {
      Hive.registerAdapter(ExportRecordAdapter());
    }
    _box = await Hive.openBox<ExportRecord>(boxName);
  }

  /// 👉 Lấy toàn bộ record
  List<ExportRecord> listAll() {
    return _box.values.toList();
  }

  /// 👉 Thêm record mới
  Future<void> addRecord(ExportRecord record) async {
    await _box.put(record.id, record);
  }

  /// 👉 Xoá record + file
  Future<void> delete(ExportRecord record) async {
    await _box.delete(record.id);
    try {
      final file = File(record.outputPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 👉 Di chuyển file vào thư mục theo số hợp đồng
  Future<String> moveToContractFolder(String filePath, String soHopDong) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(appDir.path, 'exports', soHopDong));

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final file = File(filePath);
    final newPath = p.join(folder.path, p.basename(filePath));

    // nếu file cùng tên đã tồn tại → thêm timestamp
    var finalPath = newPath;
    if (await File(finalPath).exists()) {
      final name = p.basenameWithoutExtension(filePath);
      final ext = p.extension(filePath);
      finalPath =
          p.join(folder.path, '${name}_${DateTime.now().millisecondsSinceEpoch}$ext');
    }

    final newFile = await file.rename(finalPath);
    return newFile.path;
  }

  /// 👉 Thêm record và auto-move file
  Future<ExportRecord> addWithMove(ExportRecord record) async {
    final soHopDong = record.data['so_hop_dong'] ?? 'UNKNOWN';
    final newPath = await moveToContractFolder(record.outputPath, soHopDong);

    final updated = record.copyWith(outputPath: newPath);
    await addRecord(updated);
    return updated;
  }
}
