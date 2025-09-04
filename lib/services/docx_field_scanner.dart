import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Quét placeholder {{field}} trong nhiều phần của .docx
class DocxFieldScanner {
  static final _placeholder = RegExp(r'\{\{\s*([A-Za-z0-9_]+)\s*\}\}');

  /// Quét từ file path (Mobile/Desktop)
  static Future<List<String>> scanFields(String docxPath) async {
    final bytes = await File(docxPath).readAsBytes();
    return scanFieldsFromBytes(bytes);
  }

  /// ✅ Quét từ bytes (Web dùng cái này)
  static Future<List<String>> scanFieldsFromBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    final targets = <String>{
      'word/document.xml',
      'word/footnotes.xml',
      'word/endnotes.xml',
      'word/comments.xml',
    };
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('word/')) {
        if (f.name.contains('/header') && f.name.endsWith('.xml')) {
          targets.add(f.name);
        }
        if (f.name.contains('/footer') && f.name.endsWith('.xml')) {
          targets.add(f.name);
        }
      }
    }

    final seen = <String>{};
    final result = <String>[];

    for (final path in targets) {
      final file = archive.files.firstWhere(
            (f) => f.isFile && f.name == path,
        orElse: () => ArchiveFile('', 0, const <int>[]),
      );
      if (file.name.isEmpty) continue;
      final xml = utf8.decode(file.content as List<int>);

      // loại bỏ tag XML → giữ text
      final textOnly = xml.replaceAll(RegExp(r'<[^>]+>'), '');
      for (final m in _placeholder.allMatches(textOnly)) {
        final key = m.group(1)!;
        if (seen.add(key)) result.add(key);
      }
    }
    return result;
  }
}
