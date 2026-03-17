import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/connection_state.dart' as cs;
import '../../core/providers/websocket_provider.dart';
import '../approvals/domain/providers/approval_provider.dart';

/// Root shell widget that wraps the bottom-navigation branches.
///
/// Renders a [ConnectionStatusBar] overlaid at the top of the body, and a
/// [BottomNavigationBar] with badge support for pending approvals.
class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingApprovalsProvider).length;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          navigationShell,
          // Connection status overlay at top
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ConnectionStatusBar(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.difference_outlined),
            label: 'Diff',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Files',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.source_outlined),
            label: 'Git',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.checklist_outlined),
            ),
            label: 'Approvals',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection status bar
// ---------------------------------------------------------------------------

class _ConnectionStatusBar extends ConsumerWidget {
  const _ConnectionStatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider);
    return statusAsync.when(
      data: (status) => _bar(status),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _bar(cs.ConnectionStatus status) {
    if (status == cs.ConnectionStatus.connected) return const SizedBox.shrink();

    final isReconnecting = status == cs.ConnectionStatus.reconnecting;
    final color = isReconnecting
        ? const Color(0xFFFF9800)
        : const Color(0xFFF44747);
    final message = isReconnecting ? 'Reconnecting…' : 'Offline';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
