import 'package:flutter/material.dart';

enum AppNavItem {
  newChat, search, library, codex, sora, gpts, newProject, chamCong
}

class AppSidebar extends StatelessWidget {
  final AppNavItem selected;
  final ValueChanged<AppNavItem> onSelect;
  final bool extended;
  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.extended = true,
  });

  static const _labels = {
    AppNavItem.newChat:   'New chat',
    AppNavItem.search:    'Search chats',
    AppNavItem.library:   'Library',
    AppNavItem.codex:     'Codex',
    AppNavItem.sora:      'Sora',
    AppNavItem.gpts:      'GPTs',
    AppNavItem.newProject:'New project',
    AppNavItem.chamCong:  'app chấm công',
  };

  static const _icons = {
    AppNavItem.newChat:   Icons.edit_note_outlined,
    AppNavItem.search:    Icons.search,
    AppNavItem.library:   Icons.folder_copy_outlined,
    AppNavItem.codex:     Icons.psychology_alt_outlined,
    AppNavItem.sora:      Icons.play_circle_outline,
    AppNavItem.gpts:      Icons.grid_view_outlined,
    AppNavItem.newProject:Icons.add_box_outlined,
    AppNavItem.chamCong:  Icons.badge_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final destinations = AppNavItem.values.map((it) {
      return NavigationRailDestination(
        icon: Icon(_icons[it]),
        selectedIcon: Icon(_icons[it], color: Theme.of(context).colorScheme.primary),
        label: Text(_labels[it]!),
      );
    }).toList();

    return NavigationRail(
      destinations: destinations,
      selectedIndex: AppNavItem.values.indexOf(selected),
      onDestinationSelected: (i) => onSelect(AppNavItem.values[i]),
      extended: extended,
      minExtendedWidth: 220,
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8),
        child: Row(children: [
          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
          if (extended) const SizedBox(width: 8),
          if (extended) const Text('Điền Hợp Đồng', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  static Widget buildDrawer({
    required BuildContext context,
    required ValueChanged<AppNavItem> onSelect,
  }) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: AppNavItem.values.map((it) => ListTile(
            leading: Icon(_icons[it]),
            title: Text(_labels[it]!),
            onTap: () { Navigator.pop(context); onSelect(it); },
          )).toList(),
        ),
      ),
    );
  }
}
