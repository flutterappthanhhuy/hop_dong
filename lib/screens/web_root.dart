import 'package:flutter/material.dart';
import 'template_list_screen.dart';
import 'home_exports_screen.dart';

class WebRoot extends StatefulWidget {
  const WebRoot({super.key});
  @override
  State<WebRoot> createState() => _WebRootState();
}

class _WebRootState extends State<WebRoot> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      TemplateListScreen(),  // Mẫu hợp đồng
      HomeExportsScreen(),   // Hồ sơ đã xuất
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: true,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.library_books),
                label: Text('Mẫu hợp đồng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.outbox_outlined),
                label: Text('Hồ sơ đã xuất'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}
