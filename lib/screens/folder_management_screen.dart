import 'package:flutter/material.dart';
import '../services/folder_store.dart';
import '../services/template_store.dart';
import '../models/template_folder.dart';
import '../models/template_file.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});
  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  final folderStore = FolderStore();
  final templateStore = TemplateStore();
  List<TemplateFolder> _folders = [];
  List<TemplateFile> _templates = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await folderStore.init();
    await templateStore.init();
    setState(() {
      _folders = folderStore.getAll();
      _templates = templateStore.getAll();
    });
  }

  int _countTemplates(String? folderId) {
    return _templates.where((t) => t.templateFolderId == folderId).length;
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
      await _init();
    }
  }

  Future<void> _renameFolder(TemplateFolder f) async {
    final ctrl = TextEditingController(text: f.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi tên thư mục'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Tên mới')),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Huỷ')),
          FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await folderStore.rename(f.id, ctrl.text.trim());
      await _init();
    }
  }

  Future<void> _deleteFolder(TemplateFolder f) async {
    final count = _countTemplates(f.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá thư mục'),
        content: Text(count > 0
            ? 'Thư mục đang chứa $count mẫu. Xoá sẽ KHÔNG xoá mẫu, chỉ bỏ liên kết thư mục. Tiếp tục?'
            : 'Bạn chắc chắn xoá thư mục này?'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Huỷ')),
          FilledButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) {
      // Bỏ liên kết thư mục cho các template đang thuộc folder này
      for (final t in _templates.where((t)=> t.templateFolderId == f.id)) {
        await templateStore.moveToFolder(t.id, null);
      }
      await folderStore.remove(f.id);
      await _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thư mục'),
        actions: [IconButton(onPressed: _createFolder, icon: const Icon(Icons.create_new_folder_outlined))],
      ),
      body: ListView.separated(
        itemCount: _folders.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          if (i == 0) {
            // Hàng "Thư mục gốc" (null)
            final count = _countTemplates(null);
            return ListTile(
              title: const Text('Thư mục gốc'),
              subtitle: Text('$count mẫu'),
              leading: const Icon(Icons.folder_open),
            );
          }
          final f = _folders[i-1];
          final count = _countTemplates(f.id);
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(f.name),
            subtitle: Text('$count mẫu'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'rename') await _renameFolder(f);
                if (v == 'delete') await _deleteFolder(f);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                PopupMenuItem(value: 'delete', child: Text('Xoá')),
              ],
            ),
          );
        },
      ),
    );
  }
}
