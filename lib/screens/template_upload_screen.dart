import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/template_file.dart';
import '../services/template_store.dart';
import '../services/folder_store.dart';
import '../models/template_folder.dart';

class TemplateUploadScreen extends StatefulWidget {
  const TemplateUploadScreen({super.key});
  @override
  State<TemplateUploadScreen> createState() => _TemplateUploadScreenState();
}

class _TemplateUploadScreenState extends State<TemplateUploadScreen> {
  final store = TemplateStore();
  final folderStore = FolderStore();

  final nameCtrl = TextEditingController();
  bool _busy = false;

  String? _folderId;
  List<TemplateFolder> _folders = [];

  @override
  void initState() {
    super.initState();
    _initStores();
  }

  Future<void> _initStores() async {
    await store.init();
    await folderStore.init();
    setState(() {
      _folders = folderStore.getAll();
    });
  }

  Future<void> _pickAndSave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'xlsx'],
        withData: true, // ⚡ quan trọng cho Web
      );
      if (res == null) {
        setState(() => _busy = false);
        return;
      }

      final picked = res.files.single;
      final fileName = picked.name;
      final ext = '.${p.extension(fileName).replaceAll('.', '').toLowerCase()}';
      final kind = ext == '.docx' ? TemplateKind.docx : TemplateKind.xlsx;

      TemplateFile t;
      if (kIsWeb) {
        // ⚡ Web: dùng bytes
        final bytes = picked.bytes!;
        t = await store.importTemplateBytes(
          bytes,
          fileName: fileName,
          ext: ext,
          kind: kind,
          folderId: _folderId,
        );
      } else {
        // ⚡ Mobile/Desktop: dùng file path
        final path = picked.path!;
        t = await store.importTemplate(
          path,
          folderId: _folderId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã thêm mẫu: ${t.name}')));
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm mẫu')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên mẫu (tuỳ chọn)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _folderId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Thư mục gốc')),
                ..._folders.map((f) =>
                    DropdownMenuItem(value: f.id, child: Text(f.name)))
              ],
              onChanged: (v) => setState(() => _folderId = v),
              decoration: const InputDecoration(labelText: 'Chọn thư mục'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : _pickAndSave,
              icon: const Icon(Icons.upload_file),
              label: Text(_busy ? 'Đang xử lý...' : 'Chọn file .docx/.xlsx'),
            ),
          ],
        ),
      ),
    );
  }
}
