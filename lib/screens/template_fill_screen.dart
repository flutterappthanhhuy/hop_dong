import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cross_file/cross_file.dart';

import '../services/export_store.dart';
import '../utils/filename_template.dart'; // đặt tên file theo pattern
import '../models/template_file.dart';
import '../models/validation_rule.dart';
import '../services/template_store.dart';
import '../services/docx_renderer.dart';
import '../services/xlsx_renderer.dart';

class TemplateFillScreen extends StatefulWidget {
  final String templateId;
  const TemplateFillScreen({super.key, required this.templateId});

  @override
  State<TemplateFillScreen> createState() => _TemplateFillScreenState();
}

class _TemplateFillScreenState extends State<TemplateFillScreen> {
  TemplateFile? _tpl;
  bool _loading = true;

  // danh sách field (giữ thứ tự và loại)
  final List<String> _fields = [];

  // controller cho TEXT/NUMBER/MONEY/DATE
  final Map<String, TextEditingController> _dataCtrls = {};

  // giá trị cho BOOL
  final Map<String, bool> _boolValues = {};

  // rules + error
  final Map<String, ValidationRule> _rules = {
    'ten_khach_hang': const ValidationRule(required: true, minLen: 3, label: 'Tên khách hàng'),
    'mst': ValidationRule(required: true, pattern: RegExp(r'^\d{10}(\d{3})?$'), label: 'Mã số thuế'),
    'dia_chi': const ValidationRule(required: true, minLen: 5, label: 'Địa chỉ'),
  };
  Map<String, String> _fieldErrors = {};
  String? _errorOf(String key) => _fieldErrors[key];

  // Mapping XLSX (nhập JSON)
  final _mappingCtrl = TextEditingController();

  // ===== Helpers =====
  String _viLabelFor(String key) {
    const dict = {
      'ten_khach_hang': 'Tên khách hàng',
      'mst': 'Mã số thuế',
      'dia_chi': 'Địa chỉ',
      'hang_muc': 'Hạng mục',
      'ngay_ky': 'Ngày ký',
      'so_tien': 'Số tiền',
      'don_gia': 'Đơn giá',
      'tong_tien': 'Tổng tiền',
      'dai_dien': 'Người đại diện',
      'so_hop_dong': 'Số hợp đồng',
    };
    if (dict.containsKey(key)) return dict[key]!;
    final spaced = key.replaceAll('_', ' ');
    return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
  }

  bool _validateAll() {
    final errors = <String, String>{};
    for (final k in _fields) {
      final kind = _kindOf(k);
      final val = (kind == FieldKind.boolType)
          ? ((_boolValues[k] ?? false) ? 'true' : '')
          : _dataCtrls[k]?.text;
      final rule = _rules[k];
      final msg = rule?.validate(val);
      if (msg != null) errors[k] = msg;
    }
    setState(() => _fieldErrors = errors);

    if (errors.isNotEmpty) {
      final firstKey = errors.keys.first;
      final label = _rules[firstKey]?.label ?? _viLabelFor(firstKey);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $label - ${errors[firstKey]}')));
      return false;
    }
    return true;
  }

  FieldKind _kindOf(String key) {
    final k = key.toLowerCase();
    if (k.contains('ngay')) return FieldKind.date;
    if (k.contains('so_tien') || k.contains('don_gia') || k.contains('tong_tien') || k.endsWith('_gia') || k.contains('gia_')) {
      return FieldKind.money;
    }
    if (k.startsWith('is_') || k.startsWith('co_') || k.startsWith('bool_')) return FieldKind.boolType;
    if (k.contains('so_luong') || k.contains('so_') || k.endsWith('_number') || k.endsWith('_count')) return FieldKind.number;
    return FieldKind.text;
  }

  final _thousandsFormatter = _ThousandsSeparatorFormatter();

  String _formatDate(DateTime dt) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  List<_CustomerLite> _mstSuggestions(String query) {
    try {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return const [];
      if (!Hive.isBoxOpen('customers')) return const [];
      final box = Hive.box('customers');
      final vals = box.values.toList();
      final out = <_CustomerLite>[];
      for (final v in vals) {
        String? tax, name, addr;
        if (v is Map) {
          tax = (v['taxCode'] ?? v['mst'] ?? '').toString();
          name = (v['name'] ?? v['ten'] ?? '').toString();
          addr = (v['address'] ?? v['dia_chi'] ?? '').toString();
        } else {
          try { tax = (v.taxCode ?? v.mst ?? '').toString(); } catch (_) {}
          try { name = (v.name ?? v.ten ?? '').toString(); } catch (_) {}
          try { addr = (v.address ?? v.diaChi ?? '').toString(); } catch (_) {}
        }
        if ((tax ?? '').toLowerCase().contains(q)) {
          out.add(_CustomerLite(taxCode: tax ?? '', name: name ?? '', address: addr ?? ''));
          if (out.length >= 5) break;
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final box = Hive.box<TemplateFile>(TemplateStore.boxName);
      final tpl = box.get(widget.templateId);

      if (tpl == null) {
        setState(() { _tpl = null; _loading = false; });
        return;
      }

      final defaultFields = ['ten_khach_hang', 'mst', 'dia_chi', 'hang_muc', 'ngay_ky'];
      final fields = (tpl.kind == TemplateKind.docx)
          ? (tpl.fields.isNotEmpty ? tpl.fields : defaultFields)
          : (tpl.xlsxMapping?.keys.toList() ?? defaultFields);

      _fields
        ..clear()
        ..addAll(fields);

      for (final f in _fields) {
        final kind = _kindOf(f);
        if (kind == FieldKind.boolType) {
          _boolValues[f] = false;
        } else {
          _dataCtrls[f] = TextEditingController();
        }
      }

      if (tpl.kind == TemplateKind.xlsx) {
        _mappingCtrl.text = tpl.xlsxMapping == null
            ? '{\n  "ten_khach_hang": "A5",\n  "mst": "C7",\n  "dia_chi": "A8",\n  "hang_muc": "B12",\n  "ngay_ky": "E20"\n}'
            : _prettyJson(tpl.xlsxMapping!);
      }

      if (!mounted) return;
      setState(() { _tpl = tpl; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _tpl = null; _loading = false; });
    }
  }

  String _prettyJson(Map<String, String> m) =>
      '{\n${m.entries.map((e) => '  "${e.key}": "${e.value}"').join(',\n')}\n}';

  Future<void> _addField() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm trường mới'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'vd: ten_du_an'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Thêm')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty && _tpl != null) {
      final key = nameCtrl.text.trim();

      setState(() {
        _fields.add(key);
        final kind = _kindOf(key);
        if (kind == FieldKind.boolType) {
          _boolValues[key] = false;
        } else {
          _dataCtrls[key] = TextEditingController();
        }
      });

      if (_tpl!.kind == TemplateKind.docx) {
        final box = Hive.box<TemplateFile>(TemplateStore.boxName);
        final cur = box.get(_tpl!.id);
        if (cur != null) {
          final newFields = {...cur.fields, key}.toList();
          cur.fields = newFields;
          cur.save();
        }
      }
    }
  }

  Future<void> _saveXlsxMapping() async {
    if (_tpl == null || _tpl!.kind != TemplateKind.xlsx) return;
    try {
      final raw = _mappingCtrl.text.trim();
      final decoded = jsonDecode(raw);
      final map = <String, String>{};
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((k, v) {
          if (k is String && v is String) map[k] = v;
        });
      }
      final box = Hive.box<TemplateFile>(TemplateStore.boxName);
      final cur = box.get(_tpl!.id);
      if (cur != null) {
        cur.xlsxMapping = map;
        await cur.save();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu mapping XLSX')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi mapping (cần JSON hợp lệ): $e')));
    }
  }

  Future<void> _pickDateFor(String key) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year + 15),
      initialDate: now,
    );
    if (picked != null) {
      _dataCtrls[key]?.text = _formatDate(picked);
      setState(() {});
    }
  }

  Future<void> _renderAndOpen() async {
    if (_tpl == null) return;

    // Validate trước khi xuất
    if (!_validateAll()) return;


    // Thu dữ liệu
    final data = <String, String>{};
    for (final k in _fields) {
      final kind = _kindOf(k);
      if (kind == FieldKind.boolType) {
        data[k] = (_boolValues[k] ?? false).toString();
      } else {
        data[k] = _dataCtrls[k]?.text ?? '';
      }
    }

    final tmpDir = await getTemporaryDirectory();

    // Đặt tên file theo pattern
    final pattern = (_tpl!.fileNamePattern == null || _tpl!.fileNamePattern!.trim().isEmpty)
        ? (_tpl!.kind == TemplateKind.docx
        ? 'HD_{{so_hop_dong}}_{{dia_chi}}.docx'
        : 'HD_{{so_hop_dong}}_{{dia_chi}}.xlsx')
        : _tpl!.fileNamePattern!;

    final fileName = renderFilenameTemplate(pattern, data, fallback: 'hop_dong');
    final outPath = '${tmpDir.path}/$fileName';

    try {
      String finalPath = outPath;
      if (_tpl!.kind == TemplateKind.docx) {
        finalPath = await DocxRenderer.render(
          srcDocxPath: _tpl!.filePath,
          data: data,
          outPath: outPath,
        );
      } else {
        final mapping = _tpl!.xlsxMapping ?? {};
        if (mapping.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Hãy cấu hình mapping XLSX trước.')));
          return;
        }
        finalPath = await XlsxRenderer.render(
          srcXlsxPath: _tpl!.filePath,
          data: data,
          mapping: mapping,
          outPath: outPath,
        );
      }

      final f = File(finalPath);
      if (!f.existsSync() || f.lengthSync() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File xuất ra rỗng hoặc không tồn tại')),
        );
        return;
      }
      final exportStore = ExportStore();
      await exportStore.init();
      await exportStore.add(
        _tpl!.name,
        finalPath,
        folderId: null, // hoặc cho phép chọn folder trước khi lưu
      );

      // Tăng version (lưu ở meta box)
      final ts = TemplateStore();
      await ts.bumpVersion(_tpl!.id);

      final res = await OpenFilex.open(finalPath);
      if (res.type != ResultType.done) {
        await Share.shareXFiles([XFile(finalPath)], text: 'Hợp đồng đã điền');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất/mở file: $e')));
    }
  }

  // ===== Field UI =====
  Widget _buildSmartField(String key) {
    final kind = _kindOf(key);
    final label = _viLabelFor(key);

    switch (kind) {
      case FieldKind.date:
        return TextField(
          controller: _dataCtrls[key],
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'dd/MM/yyyy',
            errorText: _errorOf(key),
            suffixIcon: const Icon(Icons.event),
          ),
          onTap: () => _pickDateFor(key),
        );

      case FieldKind.money:
        return TextField(
          controller: _dataCtrls[key],
          keyboardType: TextInputType.number,
          inputFormatters: [_thousandsFormatter],
          decoration: InputDecoration(
            labelText: label,
            hintText: 'ví dụ: 100.000.000',
            errorText: _errorOf(key),
          ),
        );

      case FieldKind.number:
        return TextField(
          controller: _dataCtrls[key],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Chỉ nhập số',
            errorText: _errorOf(key),
          ),
        );

      case FieldKind.boolType:
        final value = _boolValues[key] ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Switch(
              value: value,
              onChanged: (v) => setState(() => _boolValues[key] = v),
            ),
          ],
        );

      case FieldKind.text:
      default:
        if (key == 'mst') {
          final ctrl = _dataCtrls[key]!;
          final suggestions = _mstSuggestions(ctrl.text);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: _viLabelFor('mst'),
                  hintText: 'Nhập MST (ví dụ 0312345678)',
                  errorText: _errorOf(key),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: suggestions.map((c) => ListTile(
                      dense: true,
                      title: Text(c.taxCode),
                      subtitle: Text(c.name),
                      trailing: SizedBox(
                        width: 180,
                        child: Text(
                          c.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      onTap: () {
                        ctrl.text = c.taxCode;
                        _dataCtrls['ten_khach_hang']?.text = c.name;
                        _dataCtrls['dia_chi']?.text = c.address;
                        setState(() {});
                      },
                    )).toList(),
                  ),
                ),
              ],
            ],
          );
        }
        return TextField(
          controller: _dataCtrls[key],
          decoration: InputDecoration(
            labelText: label,
            errorText: _errorOf(key),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_tpl == null) return const Scaffold(body: Center(child: Text('Không tìm thấy mẫu')));

    return Scaffold(
      appBar: AppBar(
        title: Text('Điền mẫu: ${_tpl?.name ?? ''}'),
        actions: [
          if (_tpl?.kind == TemplateKind.xlsx)
            IconButton(
              tooltip: 'Lưu mapping XLSX',
              icon: const Icon(Icons.grid_on),
              onPressed: _saveXlsxMapping,
            ),
          IconButton(
            tooltip: 'Thêm trường',
            icon: const Icon(Icons.add),
            onPressed: _addField,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_tpl?.kind == TemplateKind.xlsx) ...[
            const Text('Mapping XLSX (field → ô, ví dụ A5, C7...)'),
            TextField(
              controller: _mappingCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '{\n  "ten_khach_hang": "A5",\n  "mst": "C7"\n}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Nhập dữ liệu'),
          const SizedBox(height: 8),
          if (_fields.isEmpty) const Text('Chưa có trường nào. Hãy bấm Thêm trường.'),
          for (final f in _fields) ...[
            _buildSmartField(f),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _renderAndOpen,
            icon: const Icon(Icons.save),
            label: const Text('Xuất file đã điền'),
          ),
        ],
      ),
    );
  }
}

// ====== Kiểu field ======
enum FieldKind { text, number, money, date, boolType }

// ====== Formatter tiền VN (dấu .) ======
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  String _format(String digits) {
    digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final sb = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      sb.write(digits[i]);
      count++;
      if (count == 3 && i != 0) {
        sb.write('.');
        count = 0;
      }
    }
    return sb.toString().split('').reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = _format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CustomerLite {
  final String taxCode;
  final String name;
  final String address;
  const _CustomerLite({required this.taxCode, required this.name, required this.address});
}
