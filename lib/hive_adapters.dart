// lib/hive_adapters.dart
import 'package:hive/hive.dart';
import 'models/template_file.dart';

// gom hằng số typeId vào 1 chỗ
const kTypeIdTemplateFile = 180;

Future<void> registerHiveAdapters() async {
  if (!Hive.isAdapterRegistered(kTypeIdTemplateFile)) {
    Hive.registerAdapter(TemplateFileAdapter()); // typeId = 180
  }
}
