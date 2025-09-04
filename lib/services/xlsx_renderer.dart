import 'dart:io';
import 'package:excel/excel.dart';

class XlsxRenderer {
  static Future<String> render({
    required String srcXlsxPath,
    required Map<String, String> data,
    required Map<String, String> mapping, // field -> A1
    required String outPath,
  }) async {
    final bytes = File(srcXlsxPath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final firstSheet = excel.tables.keys.first;
    final sheet = excel.tables[firstSheet]!;

    CellValue toCellValue(String s) {
      // cố gắng parse kiểu số/bool; mặc định là text
      final i = int.tryParse(s);
      if (i != null) return IntCellValue(i);

      final d = double.tryParse(s);
      if (d != null) return DoubleCellValue(d);

      final lower = s.toLowerCase().trim();
      if (lower == 'true') return const BoolCellValue(true);
      if (lower == 'false') return const BoolCellValue(false);

      // nếu muốn parse ngày:
      // try {
      //   final dt = DateTime.parse(s);
      //   return DateCellValue(dt);
      // } catch (_) {}

      return TextCellValue(s);
    }

    mapping.forEach((field, cellRef) {
      final val = data[field];
      if (val == null) return;

      final match = RegExp(r'([A-Z]+)([0-9]+)')
          .firstMatch(cellRef.trim().toUpperCase());
      if (match == null) return;

      final colLetters = match.group(1)!;
      final row = int.parse(match.group(2)!);

      int colIndex = 0;
      for (int i = 0; i < colLetters.length; i++) {
        colIndex = colIndex * 26 + (colLetters.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
      }
      colIndex -= 1; // zero-based

      final idx = CellIndex.indexByColumnRow(
        columnIndex: colIndex,
        rowIndex: row - 1,
      );

      // Cách 1: dùng updateCell với CellValue
      sheet.updateCell(idx, toCellValue(val));

      // (hoặc) Cách 2:
      // final cell = sheet.cell(idx);
      // cell.value = toCellValue(val);
    });

    final outBytes = excel.encode()!;
    File(outPath).writeAsBytesSync(outBytes);
    return outPath;
  }
}
