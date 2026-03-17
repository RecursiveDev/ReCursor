import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';
import '../network/connection_state.dart' as cs;
import '../providers/websocket_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/bridge_setup_screen.dart';
import '../../features/chat/presentation/screens/session_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/diff/presentation/screens/diff_viewer_screen.dart';
import '../../features/repos/presentation/screens/file_tree_screen.dart';
import '../../features/repos/presentation/screens/file_viewer_screen.dart';

// ---------------------------------------------------------------------------
// Placeholder screens
// ---------------------------------------------------------------------------

class _GitScreen extends StatelessWidget {
  const _GitScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Git')),
      body: const Center(child: Text('Git')),
    );
  }
}

class _ApprovalsScreen extends StatelessWidget {
  const _ApprovalsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: const Center(child: Text('Approvals')),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings')),
    );
  }
}

class _AgentListScreen extends StatelessWidget {
  const _AgentListScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agents')),
      body: const Center(child: Text('Agents')),
    );
  }
}

class _ApprovalDetailScreen extends StatelessWidget {
  final String id;
  const _ApprovalDetailScreen({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Detail')),
      body: Center(child: Text('Approval: $id')),
    );
  }
}

class _TerminalScreen extends StatelessWidget {
  const _TerminalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal')),
      body: const Center(child: Text('Terminal')),
    );
  }
}

// ---------------------------------------------------------------------------
// Home shell
// ---------------------------------------------------------------------------

class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.difference), label: 'Diff'),
    BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Files'),
    BottomNavigationBarItem(icon: Icon(Icons.source), label: 'Git'),
    BottomNavigationBarItem(icon: Icon(Icons.approval), label: 'Approvals'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        items: _items,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ConnectionStatusBar (inline — also exported from shared/widgets)
// ---------------------------------------------------------------------------

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

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
    final color = isReconnecting ? const Color(0xFFFF9800) : const Color(0xFFF44747);
    final message = isReconnecting ? 'Reconnecting...' : 'Offline';

    return Container(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

GoRouter _buildRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authState.status;
      final location = state.matchedLocation;

      if (status == AuthStatus.loading) return null;

      if (status == AuthStatus.unauthenticated) {
        if (location == '/login' || location == '/splash') return null;
        return '/login';
      }

      if (status == AuthStatus.authenticated) {
        if (location == '/login' || location == '/splash') {
          return '/home/chat';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/bridge-setup',
        builder: (_, __) => const BridgeSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/chat',
                builder: (_, __) => const SessionListScreen(),
                routes: [
                  GoRoute(
                    path: ':sessionId',
                    builder: (_, state) => ChatScreen(
                      sessionId: state.pathParameters['sessionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/diff',
                builder: (_, __) => const DiffViewerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/repos',
                builder: (_, state) {
                  final sessionId =
                      state.uri.queryParameters['sessionId'] ?? '';
                  return FileTreeScreen(sessionId: sessionId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/git',
                builder: (_, __) => const _GitScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/approvals',
                builder: (_, __) => const _ApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/settings',
                builder: (_, __) => const _SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/home/agents',
        builder: (_, __) => const _AgentListScreen(),
      ),
      GoRoute(
        path: '/approval/:id',
        builder: (_, state) =>
            _ApprovalDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/terminal',
        builder: (_, __) => const _TerminalScreen(),
      ),
      GoRoute(
        path: '/home/repos/view',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return FileViewerScreen(
            sessionId: extra['sessionId'] ?? '',
            path: extra['path'] ?? '',
          );
        },
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return _buildRouter(authState);
});

final appRouter = Provider<GoRouter>((ref) => ref.watch(routerProvider));
