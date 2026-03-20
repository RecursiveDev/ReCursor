import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/connection_status_bar.dart';

/// Root shell widget that wraps the bottom-navigation branches.
///
/// This stays feature-owned while preserving the existing router behavior.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<BottomNavigationBarItem> _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.difference), label: 'Diff'),
    BottomNavigationBarItem(
      icon: Icon(Icons.folder_outlined),
      label: 'Files',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.source), label: 'Git'),
    BottomNavigationBarItem(
      icon: Icon(Icons.approval),
      label: 'Approvals',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: _items,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
