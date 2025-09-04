import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

import '../models/template_file.dart';
import '../services/template_store.dart';
import '../services/folder_store.dart';
import '../services/docx_field_scanner.dart';

class TemplateOnboardingWizard extends StatefulWidget {
  const TemplateOnboardingWizard({super.key});
  @override
  State<TemplateOnboardingWizard> createState() => _TemplateOnboardingWizardState();
}

class _TemplateOnboardingWizardState extends State<TemplateOnboardingWizard> {
  final _pageCtrl = PageController();
  int _step = 0;

  // B1
  File? _pickedFile;
  String? _ext; // docx/xlsx
  TemplateKind? _kind;

  // B2
  final _nameCtrl = TextEditingController();
  final _patternCtrl = TextEditingController(text: 'HD_{{so_hop_dong}}_{{dia_chi}}.docx');
  final List<String> _categories = const ['Hợp đồng', 'Báo giá', 'Biên bản', 'Khác'];
  String? _category;
  List<String> _fields = [];
  final Map<String, bool> _fieldEnabled = {};

  // Bổ sung folder (tuỳ chọn)
  String? _folderId; // null = root
  List<DropdownMenuItem<String?>> _folderItems = [const DropdownMenuItem(value: null, child: Text('Thư mục gốc'))];

  final _store = TemplateStore();
  final _folderStore = FolderStore();

  @override
  void initState() {
    super.initState();
    _initStores();
  }

  Future<void> _initStores() async {
    await _store.init();
    await _folderStore.init();
    final folders = _folderStore.getAll();
    setState(() {
      _folderItems = [
        const DropdownMenuItem(value: null, child: Text('Thư mục gốc')),
        ...folders.map((f)=> DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
      ];
    });
  }

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['docx','xlsx']);
    if (res == null) return;
    final path = res.files.single.path!;
    final f = File(path);
    final ext = path.split('.').last.toLowerCase();
    setState(() {
      _pickedFile = f;
      _ext = ext;
      _kind = (ext == 'docx') ? TemplateKind.docx : TemplateKind.xlsx;
      if (_kind == TemplateKind.xlsx) {
        _patternCtrl.text = 'HD_{{so_hop_dong}}_{{dia_chi}}.xlsx';
      }
      _nameCtrl.text = res.files.single.name;
    });

    // Quét field nếu là DOCX
    if (_kind == TemplateKind.docx) {
      try {
        final fields = await DocxFieldScanner.scanFields(path);
        setState(() {
          _fields = fields;
          _fieldEnabled.clear();
          for (final f in fields) { _fieldEnabled[f] = true; }
        });
      } catch (_) {/* ignore */}
    } else {
      // XLSX: để người dùng thêm sau (mapping)
      setState(() {
        _fields = ['ten_khach_hang','mst','dia_chi','hang_muc','ngay_ky'];
        _fieldEnabled.clear();
        for (final f in _fields) { _fieldEnabled[f] = true; }
      });
    }
  }

  bool get _canNext {
    if (_step == 0) return _pickedFile != null;
    if (_step == 1) return _nameCtrl.text.trim().isNotEmpty;
    return true;
  }

  Future<void> _save() async {
    if (_pickedFile == null || _kind == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final id = const Uuid().v4();
    final dst = File('${appDir.path}/tpl_$id.${_ext!}');
    await dst.writeAsBytes(await _pickedFile!.readAsBytes());

    final selectedFields = _fields.where((f)=> _fieldEnabled[f] == true).toList();

    final t = TemplateFile(
      id: id,
      name: _nameCtrl.text.trim().isEmpty ? 'Mẫu chưa đặt tên' : _nameCtrl.text.trim(),
      kind: _kind!,
      filePath: dst.path,
      fields: _kind == TemplateKind.docx ? selectedFields : [],
      xlsxMapping: null,
      category: _category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fileNamePattern: _patternCtrl.text.trim().isEmpty ? null : _patternCtrl.text.trim(),
      version: 1,
      templateFolderId: _folderId,
    );

    await _store.add(t);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo template')));
    Navigator.pop(context, true);
  }

  void _next() { if (_canNext) { setState(()=> _step++); _pageCtrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut); } }
  void _back() { if (_step>0) { setState(()=> _step--); _pageCtrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut); } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo template mới'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> Navigator.pop(context)),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_step>0) OutlinedButton(onPressed: _back, child: const Text('Quay lại')),
            const Spacer(),
            if (_step<2) FilledButton(onPressed: _canNext ? _next : null, child: const Text('Tiếp tục')),
            if (_step==2) FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Lưu')),
          ],
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // B1: Chọn file
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bước 1: Chọn file .docx hoặc .xlsx', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Chọn file'),
                  ),
                  const SizedBox(height: 12),
                  if (_pickedFile != null) Text('Đã chọn: ${_pickedFile!.path.split('/').last}'),
                ],
              ),
            ),
          ),
          // B2: Quét & cấu hình
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Bước 2: Cấu hình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên template')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: ['Hợp đồng','Báo giá','Biên bản','Khác']
                      .map((c)=> DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v)=> setState(()=> _category = v),
                  decoration: const InputDecoration(labelText: 'Nhóm'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _folderId,
                  items: _folderItems,
                  onChanged: (v)=> setState(()=> _folderId = v),
                  decoration: const InputDecoration(labelText: 'Thư mục'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _patternCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mẫu tên file xuất',
                    hintText: 'VD: HD_{{so_hop_dong}}_{{dia_chi}}.docx',
                  ),
                ),
                const SizedBox(height: 16),
                if (_kind == TemplateKind.docx) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text('Field phát hiện', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  if (_fields.isEmpty) const Text('Không phát hiện placeholder {{field}} nào.'),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _fields.map((f) => FilterChip(
                      label: Text(f),
                      selected: _fieldEnabled[f] ?? true,
                      onSelected: (v)=> setState(()=> _fieldEnabled[f] = v),
                    )).toList(),
                  ),
                ] else
                  const Text('XLSX sẽ cấu hình mapping ở bước sử dụng.', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // B3: Review & Lưu
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Bước 3: Xem lại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _row('Tên', _nameCtrl.text),
                _row('Loại', _kind?.name.toUpperCase() ?? ''),
                _row('Nhóm', _category ?? '(không)'),
                _row('Thư mục', _folderItems.firstWhere((e)=> e.value == _folderId, orElse: ()=> _folderItems.first).child.toString()),
                _row('Pattern tên file', _patternCtrl.text),
                const SizedBox(height: 12),
                if (_kind == TemplateKind.docx)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fields sẽ lưu:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_fields.where((f)=> _fieldEnabled[f] == true).join(', ')),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Row(
    children: [
      SizedBox(width: 140, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(child: Text(v.isEmpty ? '(trống)' : v)),
    ],
  );
}
