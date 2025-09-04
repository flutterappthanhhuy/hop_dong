import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

class CustomerImportScreen extends StatefulWidget {
  const CustomerImportScreen({super.key});
  @override
  State<CustomerImportScreen> createState() => _CustomerImportScreenState();
}

class _CustomerImportScreenState extends State<CustomerImportScreen> {
  bool _busy = false;
  int _imported = 0;
  final List<String> _logs = [];

  Future<void> _ensureBox() async {
    if (!Hive.isBoxOpen('customers')) {
      await Hive.openBox('customers'); // box store Map theo key taxCode
    }
  }

  List<String> _splitCsvLine(String line) {
    // Parser đơn giản: tách theo dấu phẩy, hỗ trợ quote "..."
    final out = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (int i=0;i<line.length;i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        out.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    out.add(sb.toString());
    return out.map((e)=> e.trim().replaceAll(RegExp('^\"|\"\$'), '')).toList();
  }

  Future<void> _importCsv() async {
    if (_busy) return;
    setState(() { _busy = true; _logs.clear(); _imported = 0; });

    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (res == null) { setState(()=> _busy = false); return; }

      final file = File(res.files.single.path!);
      final lines = await file.readAsLines();

      if (lines.isEmpty) {
        setState(() { _logs.add('CSV rỗng'); _busy = false; });
        return;
      }

      await _ensureBox();
      final box = Hive.box('customers');

      // Header
      final header = _splitCsvLine(lines.first).map((e)=> e.toLowerCase()).toList();
      final idxName = header.indexOf('name');
      final idxTax  = header.indexOf('taxcode');
      final idxAddr = header.indexOf('address');

      if (idxName < 0 || idxTax < 0 || idxAddr < 0) {
        setState(() {
          _logs.add('Thiếu cột header (cần: name, taxCode, address)');
          _busy = false;
        });
        return;
      }

      int ok = 0, skip = 0;
      for (int i=1; i<lines.length; i++) {
        final raw = lines[i].trim();
        if (raw.isEmpty) continue;
        final cols = _splitCsvLine(raw);
        String name = (idxName < cols.length) ? cols[idxName] : '';
        String tax  = (idxTax  < cols.length) ? cols[idxTax]  : '';
        String addr = (idxAddr < cols.length) ? cols[idxAddr] : '';

        if (tax.isEmpty) { skip++; continue; }

        await box.put(tax, {
          'name': name,
          'taxCode': tax,
          'address': addr,
        });
        ok++;
      }

      setState(() {
        _imported = ok;
        _logs.add('Nhập thành công: $ok dòng, bỏ qua: $skip dòng');
      });
    } catch (e) {
      setState(()=> _logs.add('Lỗi: $e'));
    } finally {
      setState(()=> _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Customers (CSV)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _busy ? null : _importCsv,
              icon: const Icon(Icons.file_upload),
              label: Text(_busy ? 'Đang import...' : 'Chọn CSV & Import'),
            ),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text('Đã import: $_imported')),
            const SizedBox(height: 6),
            const Align(alignment: Alignment.centerLeft, child: Text('Log:')),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Text('• ${_logs[i]}'),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Yêu cầu header CSV: name,taxCode,address', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
