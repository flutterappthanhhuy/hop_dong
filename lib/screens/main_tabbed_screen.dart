import 'package:flutter/material.dart';
import 'home_exports_screen.dart';
import 'template_list_screen.dart';

class MainTabbedScreen extends StatefulWidget {
  const MainTabbedScreen({super.key});

  @override
  State<MainTabbedScreen> createState() => _MainTabbedScreenState();
}

class _MainTabbedScreenState extends State<MainTabbedScreen> {
  int _index = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  Future<void> _openRoute(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) setState(() {}); // refresh khi quay lại
  }

  PreferredSizeWidget _buildAppBar() {
    final title = (_index == 0) ? 'Hồ sơ đã xuất' : 'Mẫu & thư mục';

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      titleSpacing: 0,
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (_index == 0)
          SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: 'Tìm HĐ / KH / MST',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {}); // rebuild để update HomeExportsScreen
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}), // rebuild khi gõ
              ),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: 'Tiện ích',
          onSelected: (v) async {
            if (v == 'folders') await _openRoute('/folders');
            if (v == 'onboarding') await _openRoute('/onboarding');
            if (v == 'import') await _openRoute('/import_customers');
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'folders',
              child: ListTile(
                leading: Icon(Icons.folder_open_outlined),
                title: Text('Quản lý thư mục'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'onboarding',
              child: ListTile(
                leading: Icon(Icons.auto_fix_high_outlined),
                title: Text('Tạo template (Wizard)'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.upload_file_outlined),
                title: Text('Import customers (CSV)'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final pages = [
      KeepAliveWrapper(child: HomeExportsScreen(searchQuery: _searchCtrl.text)),
      const KeepAliveWrapper(child: TemplateListScreen()),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: IndexedStack(
        key: ValueKey(_index),
        index: _index,
        children: pages,
      ),
    );
  }

  NavigationBar _buildBottomNav() {
    final color = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      elevation: 3,
      surfaceTintColor: color.surface,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Đã xuất',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_open_outlined),
          selectedIcon: Icon(Icons.folder_open),
          label: 'Mẫu',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTemplatesTab = _index == 1;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: isTemplatesTab
            ? FloatingActionButton.extended(
          key: const ValueKey('fab-templates'),
          onPressed: () async {
            final ok = await Navigator.pushNamed(context, '/upload');
            if (ok == true && mounted) setState(() {});
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm mẫu'),
        )
            : const SizedBox.shrink(key: ValueKey('fab-empty')),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
