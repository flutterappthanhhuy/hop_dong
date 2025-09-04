import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/template_file.dart';
import 'template_store.dart';
import 'export_history.dart';
import '../models/export_record.dart';
import '../utils/filename_template.dart';
import '../services/docx_renderer.dart';
import '../services/xlsx_renderer.dart';

class BatchRendererResult {
  final List<String> outputPaths; // đường dẫn từng file đã render
  final String? zipPath;          // nếu >1 file => đường dẫn ZIP
  BatchRendererResult({required this.outputPaths, this.zipPath});
}

class BatchRenderer {
  final _history = ExportHistoryService();
  final _store = TemplateStore();

  Future<BatchRendererResult> renderMany({
    required List<TemplateFile> templates,
    required Map<String, String> data,
    required Directory tmpDir,
    bool makeZipIfMany = true,
  }) async {
    await _history.init();
    await _store.init();

    final outputs = <String>[];

    for (final t in templates) {
      // đặt tên theo pattern (nếu có)
      final pattern = (t.fileNamePattern == null || t.fileNamePattern!.trim().isEmpty)
          ? (t.kind == TemplateKind.docx
          ? 'HD_{{so_hop_dong}}_{{dia_chi}}.docx'
          : 'HD_{{so_hop_dong}}_{{dia_chi}}.xlsx')
          : t.fileNamePattern!;
      final fileName = renderFilenameTemplate(pattern, data, fallback: 'file');
      final outPath = p.join(tmpDir.path, fileName);

      // render
      String realOut;
      if (t.kind == TemplateKind.docx) {
        realOut = await DocxRenderer.render(
          srcDocxPath: t.filePath,
          data: data,
          outPath: outPath,
        );
      } else {
        final mapping = t.xlsxMapping ?? {};
        realOut = await XlsxRenderer.render(
          srcXlsxPath: t.filePath,
          data: data,
          mapping: mapping,
          outPath: outPath,
        );
      }
      outputs.add(realOut);

      // lưu lịch sử
      await _history.addRecord(ExportRecord(
        id: const Uuid().v4(),
        templateId: t.id,
        templateName: t.name,
        data: Map<String, String>.from(data),
        outputPath: realOut,
        outputType: t.kind == TemplateKind.docx ? 'docx' : 'xlsx',
        createdAt: DateTime.now(),
      ));

    }

    // nếu nhiều file → đóng gói ZIP
    String? zipPath;
    if (makeZipIfMany && outputs.length > 1) {
      final zipName = 'batch_${const Uuid().v4().substring(0,8)}.zip';
      final zipFile = File(p.join(tmpDir.path, zipName));
      final encoder = ZipFileEncoder()..create(zipFile.path);
      for (final f in outputs) {
        encoder.addFile(File(f));
      }
      encoder.close();
      zipPath = zipFile.path;
    }

    return BatchRendererResult(outputPaths: outputs, zipPath: zipPath);
  }
}