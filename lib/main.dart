import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hop_dong/screens/exported_list_screen.dart';
import 'package:hop_dong/screens/main_tabbed_screen.dart';

// Screens của bạn
import 'screens/web_root.dart';
import 'screens/mobile_root.dart';
import 'screens/template_list_screen.dart';
import 'screens/template_upload_screen.dart';
import 'screens/folder_management_screen.dart';
import 'screens/customer_import_screen.dart';
import 'screens/home_exports_screen.dart';
import 'screens/batch_fill_screen.dart';
import 'screens/placeholder_page.dart';
import 'screens/template_onboarding_wizard.dart';

// Hive models/adapters
import 'models/template_file.dart';
import 'models/template_kind_manual_adapter.dart';
import 'services/template_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // typeId = 63 (enum)
  final kindAdapter = TemplateKindAdapter(); // hoặc TemplateKindManualAdapter()
  if (!Hive.isAdapterRegistered(kindAdapter.typeId)) {
    Hive.registerAdapter(kindAdapter);
  }
  // typeId = 180 (class)
  final fileAdapter = TemplateFileAdapter();
  if (!Hive.isAdapterRegistered(fileAdapter.typeId)) {
    Hive.registerAdapter(fileAdapter);
  }

  // Open box qua TemplateStore
  final store = TemplateStore();
  await store.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Điền Hợp Đồng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),

      // 👇 Web dùng layout có sidebar; App dùng layout mobile (2 tab)
      home: kIsWeb ? const WebRoot() : const MainTabbedScreen(),

      routes: {
        // Các route màn chính
        '/templates'    : (_) => const TemplateListScreen(),
        '/home_exports' : (_) => const HomeExportsScreen(),
        '/onboarding'   : (_) => const TemplateOnboardingWizard(),
        '/home_exports' : (_) => const ExportedListScreen(),

        // Tiện ích/Phụ trợ
        '/upload'           : (_) => const TemplateUploadScreen(),
        '/folders'          : (_) => const FolderManagementScreen(),
        '/import_customers' : (_) => const CustomerImportScreen(),
        '/batch'            : (_) => const BatchFillScreen(),

        // Placeholder (nếu đang dùng menu phụ)
        '/search'     : (_) => const PlaceholderPage('Search chats / Tìm kiếm'),
        '/chat'       : (_) => const PlaceholderPage('New chat / Tạo hợp đồng nhanh'),
        '/codex'      : (_) => const PlaceholderPage('Codex'),
        '/sora'       : (_) => const PlaceholderPage('Sora'),
        '/gpts'       : (_) => const PlaceholderPage('GPTs'),
      },
    );
  }
}
