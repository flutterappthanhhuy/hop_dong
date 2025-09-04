import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/template_store.dart';
import '../models/template_file.dart';
import '../services/folder_store.dart';
import '../models/template_folder.dart';
import 'template_fill_screen.dart';
import 'batch_fill_screen.dart'; // 👈 THÊM

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  final store = TemplateStore();
  final folderStore = FolderStore();

  String? filterFolderId; // null = Tất cả
  List<TemplateFolder> folders = [];
  Map<String, String?> folderMap = {}; // templateId -> folderId (tham chiếu nhanh)

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await store.init();
    await folderStore.init();
    final map = await store.getAllFolderMap();
    setState(() {
      folders = folderStore.getAll();
      folderMap = map;
    });
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo thư mục'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Tên thư mục'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tạo')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await folderStore.create(ctrl.text.trim());
      await _init(); // reload danh sách thư mục
    }
  }

  Future<void> _moveTemplate(TemplateFile t) async {
    bool selected = false;
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Thư mục gốc'),
              trailing: (t.templateFolderId == null) ? const Icon(Icons.check) : null,
              onTap: () {
                selected = true;
                Navigator.pop(context, null);
              },
            ),
            for (final f in folders)
              ListTile(
                title: Text(f.name),
                trailing: (t.templateFolderId == f.id) ? const Icon(Icons.check) : null,
                onTap: () {
                  selected = true;
                  Navigator.pop(context, f.id);
                },
              ),
          ],
        ),
      ),
    );

    // Vuốt đóng sheet → không làm gì
    if (!selected) return;

    await store.moveToFolder(t.id, choice);
    await _init(); // reload lại folders + folderMap + danh sách
    if (mounted) setState(() {});
  }

  Future<void> _deleteTemplate(TemplateFile t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá mẫu'),
        content: Text('Bạn chắc chắn muốn xoá "${t.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) {
      await store.remove(t.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _duplicate(TemplateFile t) async {
    final newId = const Uuid().v4();

    final srcFile = File(t.filePath);
    final dir = srcFile.parent.path;
    final ext = t.filePath.contains('.') ? t.filePath.split('.').last : (t.kind == TemplateKind.xlsx ? 'xlsx' : 'docx');
    final newPath = '$dir/tpl_$newId.$ext';

    try {
      await srcFile.copy(newPath);
    } catch (_) {}

    final cloned = TemplateFile(
      id: newId,
      name: '${t.name} (bản sao)',
      kind: t.kind,
      filePath: newPath,
      fields: [...t.fields],
      xlsxMapping: t.xlsxMapping == null ? null : Map<String, String>.from(t.xlsxMapping!),
      category: t.category,
      templateFolderId: t.templateFolderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Nếu model có version/pattern và muốn copy:
      // version: t.version,
      // fileNamePattern: t.fileNamePattern,
    );

    await store.add(cloned);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    // Tính danh sách items theo filterFolderId (null = tất cả)
    final all = store.getAll();
    final List<TemplateFile> items = (filterFolderId == null)
        ? all
        : all.where((t) => t.templateFolderId == filterFolderId).toList();

    items.sort((a, b) =>
        (b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mẫu hợp đồng'),
        actions: [
          // Lọc theo folder (fix kiểu nullable)
          PopupMenuButton<String?>(
            icon: const Icon(Icons.folder_open),
            onSelected: (String? v) {
              setState(() => filterFolderId = v); // v có thể là null = Tất cả
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('Tất cả'),
              ),
              ...folders.map(
                    (f) => PopupMenuItem<String?>(value: f.id, child: Text(f.name)),
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              await _createFolder();
              await _init();
            },
            icon: const Icon(Icons.create_new_folder_outlined),
          ),


          // 👇 THÊM MENU BATCH FILL
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'batch') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BatchFillScreen(preselectFolderId: filterFolderId),
                  ),
                );
                // nếu cần refresh sau khi batch: await _init();
              }
              // ... các mục khác nếu muốn mở rộng
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'batch', child: Text('Điền nhiều & xuất')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.pushNamed(context, '/upload');
          if (ok == true) await _init();
        },
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Không có mẫu nào'))
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final t = items[i];
          final folderName = folders
              .firstWhere(
                (f) => f.id == t.templateFolderId,
            orElse: () => TemplateFolder(
              id: '',
              name: '',
              createdAt: DateTime.now(),
            ),
          )
              .name;

          return ListTile(
            title: Text(t.name),
            subtitle: Text(
              '${t.kind.name.toUpperCase()}'
                  '${folderName.isNotEmpty ? ' · $folderName' : ''}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'move') await _moveTemplate(t);
                if (v == 'delete') await _deleteTemplate(t);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'move', child: Text('Di chuyển vào thư mục')),
                PopupMenuItem(value: 'delete', child: Text('Xoá')),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateFillScreen(templateId: t.id),
                ),
              );
            },
            onLongPress: () => _duplicate(t),
          );
        },
      ),
    );
  }
}
