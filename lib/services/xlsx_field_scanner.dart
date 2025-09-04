import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';

/// Quét placeholder {{field}} trong file .xlsx
class XlsxFieldScanner {
  static final _placeholder = RegExp(r'\{\{\s*([A-Za-z0-9_]+)\s*\}\}');

  /// Mobile/Desktop
  static Future<List<String>> scanFields(String xlsxPath) async {
    final bytes = await File(xlsxPath).readAsBytes();
    return scanFieldsFromBytes(bytes);
  }

  /// ✅ Web dùng bytes
  static Future<List<String>> scanFieldsFromBytes(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);

    final seen = <String>{};
    final result = <String>[];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      for (final row in sheet.rows) {
        for (final cell in row) {
          final val = cell?.value.toString() ?? '';
          for (final m in _placeholder.allMatches(val)) {
            final key = m.group(1)!;
            if (seen.add(key)) result.add(key);
          }
        }
      }
    }
    return result;
  }
}
