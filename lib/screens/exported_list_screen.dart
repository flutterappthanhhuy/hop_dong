import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../models/exported_contract.dart';
import '../services/export_store.dart';
import '../services/folder_store.dart';
import '../models/template_folder.dart';

class ExportedListScreen extends StatefulWidget {
  const ExportedListScreen({super.key});

  @override
  State<ExportedListScreen> createState() => _ExportedListScreenState();
}

class _ExportedListScreenState extends State<ExportedListScreen> {
  final exportStore = ExportStore();
  final folderStore = FolderStore();

  String? filterFolderId; // null = tất cả
  List<TemplateFolder> folders = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await exportStore.init();
    await folderStore.init();
    setState(() {
      folders = folderStore.getAll();
    });
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo thư mục'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Tên thư mục')),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Huỷ')),
          FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Tạo')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await folderStore.create(ctrl.text.trim());
      setState(() { folders = folderStore.getAll(); });
    }
  }

  Future<void> _moveExport(ExportedContract e) async {
    bool selected = false;
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Thư mục gốc'),
              trailing: (e.folderId == null) ? const Icon(Icons.check) : null,
              onTap: () { selected = true; Navigator.pop(context, null); },
            ),
            for (final f in folders)
              ListTile(
                title: Text(f.name),
                trailing: (e.folderId == f.id) ? const Icon(Icons.check) : null,
                onTap: () { selected = true; Navigator.pop(context, f.id); },
              ),
          ],
        ),
      ),
    );
    if (!selected) return;
    await exportStore.moveToFolder(e.id, choice);
    if (mounted) setState(() {});
  }

  Future<void> _deleteExport(ExportedContract e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá hồ sơ đã xuất'),
        content: Text('Xoá "${e.name}" khỏi danh sách? (File gốc vẫn nằm ở: ${e.filePath})'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Huỷ')),
          FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) {
      await exportStore.remove(e.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = exportStore.getAll();
    final items = (filterFolderId == null)
        ? all
        : all.where((e) => e.folderId == filterFolderId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ đã xuất'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.folder_open),
            onSelected: (v) => setState(()=> filterFolderId = v),
            itemBuilder: (_) => [
              const PopupMenuItem<String?>(value: null, child: Text('Tất cả')),
              ...folders.map((f)=> PopupMenuItem<String?>(value: f.id, child: Text(f.name))),
            ],
          ),
          IconButton(onPressed: _createFolder, icon: const Icon(Icons.create_new_folder_outlined)),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Chưa có hợp đồng nào đã xuất'))
          : ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = items[i];
          final folderName = folders.firstWhere(
                (f) => f.id == e.folderId,
            orElse: () => TemplateFolder(id: '', name: '', createdAt: DateTime.now()),
          ).name;

          final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(e.createdAt);
          final exists = File(e.filePath).existsSync();

          return ListTile(
            leading: Icon(exists ? Icons.description_outlined : Icons.warning_amber_outlined),
            title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('$timeStr${folderName.isNotEmpty ? ' · $folderName' : ''}\n${e.filePath}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            isThreeLine: true,
            onTap: () async {
              if (!exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File không còn tồn tại: ${e.filePath}')),
                );
                return;
              }
              await OpenFilex.open(e.filePath);
            },
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'move') await _moveExport(e);
                if (v == 'delete') await _deleteExport(e);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'move', child: Text('Di chuyển vào thư mục')),
                PopupMenuItem(value: 'delete', child: Text('Xoá khỏi danh sách')),
              ],
            ),
          );
        },
      ),
    );
  }
}
