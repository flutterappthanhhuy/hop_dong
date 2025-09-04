import 'package:intl/intl.dart';
import 'package:flutter/services.dart';


String viLabelFor(String key) {
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
// fallback: snake_case → Capitalize
  final spaced = key.replaceAll('_', ' ');
  return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
}


/// Heuristic xác định loại field để render widget phù hợp
enum FieldKind { text, number, money, date, boolType }


FieldKind kindOf(String key) {
  final k = key.toLowerCase();
  if (k.contains('ngay')) return FieldKind.date;
  if (k.contains('so_tien') || k.contains('don_gia') || k.contains('tong_tien') || k.contains('gia')) return FieldKind.money;
  if (k.startsWith('is_') || k.startsWith('co_')) return FieldKind.boolType;
  if (k.contains('so_') || k.contains('sl') || k.contains('so_luong')) return FieldKind.number;
  return FieldKind.text;
}


class ThousandsSeparatorFormatter extends TextInputFormatter {
  final NumberFormat nf = NumberFormat.decimalPattern();
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final str = nf.format(int.parse(digits));
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}