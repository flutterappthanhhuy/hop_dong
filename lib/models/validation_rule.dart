// lib/models/validation_rule.dart
class ValidationRule {
  final bool required;
  final RegExp? pattern;      // ví dụ regex MST
  final int? minLen, maxLen;  // độ dài
  final String? label;        // nhãn hiển thị

  const ValidationRule({
    this.required = false,
    this.pattern,
    this.minLen,
    this.maxLen,
    this.label,
  });

  String? validate(String? value) {
    final v = (value ?? '').trim();
    if (required && v.isEmpty) return 'Bắt buộc nhập';
    if (minLen != null && v.length < minLen!) return 'Tối thiểu $minLen ký tự';
    if (maxLen != null && v.length > maxLen!) return 'Tối đa $maxLen ký tự';
    if (pattern != null && v.isNotEmpty && !pattern!.hasMatch(v)) return 'Định dạng không hợp lệ';
    return null;
  }
}

// Ví dụ quy tắc MST (10 hoặc 13 số, có thể thêm dấu “-”):
final mstRule = ValidationRule(
  required: true,
  pattern: RegExp(r'^\d{10}(\d{3})?$'), // 10 hoặc 13 số
  label: 'Mã số thuế',
);
