import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../models/template_file.dart';
import 'docx_field_scanner.dart';

class TemplateImporter {
  static Future<TemplateFile> importFile({
    required File file,
    required String dstPath,
    String? folderId,
  }) async {
    final ext = p.extension(file.path).toLowerCase();
    final kind = (ext == '.docx') ? TemplateKind.docx : TemplateKind.xlsx;

    final dst = File(dstPath);
    await dst.writeAsBytes(await file.readAsBytes());

    List<String> fields = [];
    Map<String, String>? mapping;

    if (kind == TemplateKind.docx) {
      fields = await DocxFieldScanner.scanFields(dst.path);
    } else if (kind == TemplateKind.xlsx) {
      mapping = await _scanXlsxFields(dst.path);
      fields = mapping.keys.toList();
    }

    return TemplateFile(
      id: p.basenameWithoutExtension(dst.path),
      name: p.basename(file.path),
      kind: kind,
      filePath: dst.path,
      fields: fields,
      xlsxMapping: mapping,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      templateFolderId: folderId,
    );
  }

  static Future<Map<String, String>> _scanXlsxFields(String xlsxPath) async {
    final bytes = File(xlsxPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final Map<String, String> mapping = {};
    for (final f in archive.files) {
      if (f.name.startsWith('xl/worksheets/') && f.name.endsWith('.xml')) {
        final xml = String.fromCharCodes(f.content as List<int>);
        final reg = RegExp(r'\{\{(.*?)\}\}');
        for (final m in reg.allMatches(xml)) {
          final field = m.group(1)!.trim();
          mapping[field] = '';
        }
      }
    }
    return mapping;
  }
}
