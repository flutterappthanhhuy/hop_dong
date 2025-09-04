import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';

class HomeShell extends StatefulWidget {
  final Widget child; // màn nội dung của bạn (Scaffold hay body đều OK)
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppNavItem _selected = AppNavItem.library;

  void _handleSelect(AppNavItem it) {
    setState(() => _selected = it);
    switch (it) {
      case AppNavItem.newChat:    Navigator.pushReplacementNamed(context, '/chat');        break;
      case AppNavItem.search:     Navigator.pushReplacementNamed(context, '/search');      break;
      case AppNavItem.library:    Navigator.pushReplacementNamed(context, '/templates');   break;
      case AppNavItem.codex:      Navigator.pushReplacementNamed(context, '/codex');       break;
      case AppNavItem.sora:       Navigator.pushReplacementNamed(context, '/sora');        break;
      case AppNavItem.gpts:       Navigator.pushReplacementNamed(context, '/gpts');        break;
      case AppNavItem.newProject: Navigator.pushReplacementNamed(context, '/onboarding');  break;
      case AppNavItem.chamCong:   Navigator.pushReplacementNamed(context, '/attendance');  break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final showRail = w >= 900;
    final extended = w >= 1200;

    return Scaffold(
      // KHÔNG dùng AppBar ở shell để tránh double appbar
      drawer: showRail ? null : AppSidebar.buildDrawer(context: context, onSelect: _handleSelect),
      body: Row(
        children: [
          if (showRail)
            AppSidebar(selected: _selected, onSelect: _handleSelect, extended: extended),
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFF7FAF8),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: widget.child, // màn của bạn (có thể là Scaffold hiện tại)
                      ),
                    ),
                  ),
                ),
                // Nút mở Drawer trên màn hẹp
                if (!showRail)
                  SafeArea(
                    child: Builder(
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
