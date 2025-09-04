String renderFilenameTemplate(
    String pattern,
    Map<String, String> data, {
      String fallback = 'file',
    }) {
  String out = pattern;

  // Thay {{key}} bằng giá trị (nếu thiếu -> rỗng)
  data.forEach((k, v) {
    final value = (v ?? '').trim();
    out = out.replaceAll('{{$k}}', value);
  });

  // Xoá placeholder còn sót
  out = out.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');

  // Làm sạch ký tự không hợp lệ cho tên file
  out = out.replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]+'), ' ').trim();
  if (out.isEmpty) out = fallback;

  // Tránh tên trống trước đuôi mở rộng
  // Nếu không có đuôi, giữ nguyên (pattern của bạn thường đã có .docx/.xlsx)
  return out;
}
