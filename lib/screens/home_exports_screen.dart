import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

import '../services/export_history.dart';
import '../models/export_record.dart';

class HomeExportsScreen extends StatefulWidget {
  final String searchQuery;
  const HomeExportsScreen({super.key, this.searchQuery = ''});

  @override
  State<HomeExportsScreen> createState() => _HomeExportsScreenState();
}

class _HomeExportsScreenState extends State<HomeExportsScreen> {
  final svc = ExportHistoryService();
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  String? _region;
  List<ExportRecord> _all = [];
  List<ExportRecord> _filtered = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant HomeExportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _applyFilter();
    }
  }

  Future<void> _init() async {
    await svc.init();
    _all = svc.listAll()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _applyFilter();
  }

  void _applyFilter() {
    final q = widget.searchQuery.trim().toLowerCase();
    final r = _region;

    _filtered = _all.where((e) {
      final name = (e.data['ten_khach_hang'] ?? '').toLowerCase();
      final mst = (e.data['mst'] ?? '').toLowerCase();
      final so = (e.data['so_hop_dong'] ?? '').toLowerCase();
      final addr = (e.data['dia_chi'] ?? '').toLowerCase();

      final hitQ = q.isEmpty ||
          name.contains(q) ||
          mst.contains(q) ||
          so.contains(q) ||
          addr.contains(q);

      final kv = _detectRegion(e.data);
      final hitR = (r == null) || (kv == r);

      return hitQ && hitR;
    }).toList();

    setState(() {});
  }

  String _detectRegion(Map<String, String> data) {
    final explicit = (data['khu_vuc'] ?? '').trim();
    if (explicit.isNotEmpty) return explicit;

    final addr = (data['dia_chi'] ?? '').toLowerCase();
    const bac = [
      'hà nội',
      'ha noi',
      'hải phòng',
      'quảng ninh',
      'bac ninh',
      'bắc giang',
      'thai nguyen'
    ];
    const trung = [
      'đà nẵng',
      'thừa thiên huế',
      'quảng nam',
      'quảng ngãi',
      'bình định',
      'phú yên',
      'khánh hòa',
      'gia lai',
      'kon tum',
      'đắk lắk',
      'đắk nông',
      'quảng trị',
      'quảng bình',
      'nghệ an',
      'hà tĩnh'
    ];
    const nam = [
      'hồ chí minh',
      'tphcm',
      'bình dương',
      'đồng nai',
      'vũng tàu',
      'long an',
      'tiền giang',
      'bến tre',
      'trà vinh',
      'vĩnh long',
      'đồng tháp',
      'an giang',
      'kiên giang',
      'hậu giang',
      'sóc trăng',
      'bạc liêu',
      'cà mau',
      'tây ninh',
      'bình phước'
    ];

    bool containsAny(String s, List<String> keys) =>
        keys.any((k) => s.contains(k));

    if (containsAny(addr, bac)) return 'Bắc';
    if (containsAny(addr, trung)) return 'Trung';
    if (containsAny(addr, nam)) return 'Nam';
    return 'Khác';
  }

  Future<void> _deleteRecord(ExportRecord record) async {
    await svc.delete(record);
    _all.remove(record);
    _applyFilter();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá hợp đồng')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Chưa có hợp đồng nào phù hợp'))
                : ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = _filtered[i];
                final name = r.data['ten_khach_hang'] ?? '(không có)';
                final mst = r.data['mst'] ?? '';
                final so = r.data['so_hop_dong'] ?? '';
                final addr = r.data['dia_chi'] ?? '';
                final kv = _detectRegion(r.data);

                return Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xoá hợp đồng'),
                        content: const Text(
                            'Bạn có chắc muốn xoá hợp đồng này?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Huỷ'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Xoá'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteRecord(r),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text([
                      if (so.isNotEmpty) 'Số HĐ: $so',
                      if (mst.isNotEmpty) 'MST: $mst',
                      if (addr.isNotEmpty) addr,
                      '${_dateFmt.format(r.createdAt)} · $kv',
                    ].join(' · ')),
                    trailing: Text(r.outputType.toUpperCase()),
                    onTap: () async {
                      await OpenFilex.open(r.outputPath);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_exports',
        onPressed: () async {
          // 👇 BatchFillScreen sẽ trả về ExportRecord
          final ExportRecord? newRec = await Navigator.pushNamed(
            context,
            '/batch',
          ) as ExportRecord?;

          if (newRec != null && mounted) {
            await svc.addWithMove(newRec); // di chuyển file + lưu record
            _init();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo hợp đồng'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
