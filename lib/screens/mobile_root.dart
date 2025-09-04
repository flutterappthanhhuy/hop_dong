import 'package:flutter/material.dart';
import 'template_list_screen.dart';
import 'home_exports_screen.dart';

class MobileRoot extends StatefulWidget {
  const MobileRoot({super.key});
  @override
  State<MobileRoot> createState() => _MobileRootState();
}

class _MobileRootState extends State<MobileRoot> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      TemplateListScreen(),   // Mẫu hợp đồng
      HomeExportsScreen(),    // Hồ sơ đã xuất
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Mẫu',
          ),
          NavigationDestination(
            icon: Icon(Icons.outbox_outlined),
            label: 'Đã xuất',
          ),
        ],
      ),
    );
  }
}
