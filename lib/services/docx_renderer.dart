// lib/services/docx_renderer.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';

class DocxRenderer {
  static Future<String> render({
    required String srcDocxPath,
    required Map<String, String> data,
    required String outPath,
  }) async {
    final bytes = File(srcDocxPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Tên các phần có thể chứa text hiển thị
    final targets = <String>[
      'word/document.xml',
      // header/footer nếu có
      // (docx có thể có nhiều header/footer: header1.xml, header2.xml...)
    ];

    // thêm tất cả header/footer hiện diện
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

    // Hàm escape
    String escapeXml(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    // Tạo archive mới, thay thế nội dung cho các file mục tiêu
    final outArchive = Archive();
    for (final f in archive.files) {
      if (!f.isFile) {
        outArchive.addFile(f);
        continue;
      }

      if (targets.contains(f.name)) {
        final original = f.content as List<int>;
        String xml = utf8.decode(original);

        data.forEach((k, v) {
          xml = xml.replaceAll('{{' + k + '}}', escapeXml(v));
        });

        final updatedBytes = utf8.encode(xml);
        outArchive.addFile(ArchiveFile(f.name, updatedBytes.length, updatedBytes));
      } else {
        outArchive.addFile(f);
      }
    }

    final outBytes = ZipEncoder().encode(outArchive)!;
    File(outPath).writeAsBytesSync(outBytes);
    return outPath;
  }
}
