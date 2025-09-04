import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:hive/hive.dart';

import '../models/export_record.dart';
import '../services/export_history.dart';
import '../services/folder_store.dart';
import '../services/template_store.dart';
import '../models/template_folder.dart';
import '../models/template_file.dart';
import '../services/batch_renderer.dart';

class BatchFillScreen extends StatefulWidget {
  final String? preselectFolderId;
  const BatchFillScreen({super.key, this.preselectFolderId});

  @override
  State<BatchFillScreen> createState() => _BatchFillScreenState();
}

class _BatchFillScreenState extends State<BatchFillScreen> {
  final folderStore = FolderStore();
  final templateStore = TemplateStore();

  List<TemplateFolder> _folders = [];
  String? _folderId;
  List<TemplateFile> _templatesInFolder = [];
  final Map<String, bool> _selected = {}; // templateId -> chọn?

  // Field động gom từ các file
  List<String> _placeholders = [];
  final Map<String, TextEditingController> _dataCtrls = {};
  final Map<String, bool> _boolValues = {};

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    await folderStore.init();
    await templateStore.init();

    setState(() {
      _folders = folderStore.getAll();
      _folderId = widget.preselectFolderId;
    });

    await _reloadTemplates();
  }

  Future<void> _reloadTemplates() async {
    final all = templateStore.getAll();
    final list = (_folderId == null)
        ? all
        : all.where((t) => t.templateFolderId == _folderId).toList();

    list.sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0))
        .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0)));

    setState(() {
      _templatesInFolder = list;
      for (final t in _templatesInFolder) {
        _selected.putIfAbsent(t.id, () => true);
      }
    });

    // ✅ Gom field trùng nhau
    final Set<String> keys = {};
    for (final t in list) {
      if (_selected[t.id] == true) {
        keys.addAll(t.fields);
      }
    }

    setState(() {
      _placeholders = keys.toList();
      for (final k in _placeholders) {
        _dataCtrls.putIfAbsent(k, () => TextEditingController());
      }
    });
  }

  Future<void> _runBatch() async {
    if (_placeholders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy trường dữ liệu trong mẫu')),
      );
      return;
    }

    final chosen = _templatesInFolder.where((t) => _selected[t.id] == true).toList();
    if (chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 1 mẫu')),
      );
      return;
    }

    final data = <String, String>{};
    for (final k in _placeholders) {
      final kind = _kindOf(k);
      if (kind == _FieldKind.boolType) {
        data[k] = (_boolValues[k] ?? false).toString();
      } else {
        data[k] = _ensureCtrl(k).text.trim();
      }
    }

    setState(() => _busy = true);
    try {
      final tmp = await getTemporaryDirectory();
      final res = await BatchRenderer().renderMany(
        templates: chosen,
        data: data,
        tmpDir: tmp,
        makeZipIfMany: true,
      );

      final history = ExportHistoryService();
      await history.init();

      if (res.zipPath != null) {
        await OpenFilex.open(res.zipPath!);
        await Share.shareXFiles([XFile(res.zipPath!)], text: 'Bộ hồ sơ đã xuất');
        await history.addRecord(ExportRecord(
          createdAt: DateTime.now(),
          outputType: 'zip',
          outputPath: res.zipPath!,
          data: data,
          id: '',
          templateId: '',
          templateName: '',
        ));
      } else if (res.outputPaths.isNotEmpty) {
        final path = res.outputPaths.first;
        await OpenFilex.open(path);
        await Share.shareXFiles([XFile(path)], text: 'Tài liệu đã xuất');
        await history.addRecord(ExportRecord(
          createdAt: DateTime.now(),
          outputType: 'docx',
          outputPath: path,
          data: data,
          id: '',
          templateId: '',
          templateName: '',
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xuất xong')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in _dataCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ====== Helpers ======
  TextEditingController _ensureCtrl(String key) {
    return _dataCtrls.putIfAbsent(key, () => TextEditingController());
  }

  String _viLabelFor(String key) {
    final s = key.replaceAll('_', ' ');
    return s.isEmpty ? key : s[0].toUpperCase() + s.substring(1);
  }

  _FieldKind _kindOf(String key) {
    final k = key.toLowerCase();
    if (k.contains('ngay')) return _FieldKind.date;
    if (k.startsWith('is_') || k.startsWith('co_') || k.startsWith('bool_')) {
      return _FieldKind.boolType;
    }
    if (k.contains('so_tien') || k.contains('gia')) return _FieldKind.money;
    if (k.contains('so_') || k.contains('sl')) return _FieldKind.number;
    return _FieldKind.text;
  }

  Widget _buildSmartField(String key) {
    final kind = _kindOf(key);
    final label = _viLabelFor(key);

    switch (kind) {
      case _FieldKind.date:
        return TextField(
          controller: _ensureCtrl(key),
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.event),
            border: const OutlineInputBorder(),
          ),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 20),
              lastDate: DateTime(now.year + 20),
              initialDate: now,
            );
            if (picked != null) {
              _ensureCtrl(key).text = "${picked.day}/${picked.month}/${picked.year}";
              setState(() {});
            }
          },
        );

      case _FieldKind.money:
        return TextField(
          controller: _ensureCtrl(key),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );

      case _FieldKind.number:
        return TextField(
          controller: _ensureCtrl(key),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );

      case _FieldKind.boolType:
        final value = _boolValues[key] ?? false;
        return SwitchListTile(
          title: Text(label),
          value: value,
          onChanged: (v) => setState(() => _boolValues[key] = v),
        );

      case _FieldKind.text:
      default:
        return TextField(
          controller: _ensureCtrl(key),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderName = _folders.firstWhere(
          (f) => f.id == _folderId,
      orElse: () => TemplateFolder(id: '', name: 'Thư mục gốc', createdAt: DateTime.now()),
    ).name;

    final selectedCount = _selected.entries.where((e) => e.value == true).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Điền & xuất nhiều tài liệu')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text('Đã chọn: $selectedCount mẫu'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _runBatch,
                icon: _busy
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.playlist_add_check),
                label: Text(_busy ? 'Đang xuất...' : 'Xuất'),
              ),
            ],
          ),
        ),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Thư mục: $folderName"),
            const SizedBox(height: 12),
            if (_templatesInFolder.isNotEmpty) ...[
              const Text("Chọn mẫu:"),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        for (final t in _templatesInFolder) {
                          _selected[t.id] = true;
                        }
                      });
                      _reloadTemplates();
                    },
                    icon: const Icon(Icons.select_all),
                    label: const Text("Chọn tất cả"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        for (final t in _templatesInFolder) {
                          _selected[t.id] = false;
                        }
                      });
                      _reloadTemplates();
                    },
                    icon: const Icon(Icons.deselect),
                    label: const Text("Bỏ chọn tất cả"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._templatesInFolder.map((t) => CheckboxListTile(
                value: _selected[t.id] ?? false,
                onChanged: (v) {
                  setState(() => _selected[t.id] = v ?? false);
                  _reloadTemplates();
                },
                title: Text(t.name),
              )),
            ],
            const SizedBox(height: 12),
            const Text("Nhập dữ liệu (gom chung):"),
            ..._placeholders.map(
                  (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSmartField(f),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FieldKind { text, number, money, date, boolType }
