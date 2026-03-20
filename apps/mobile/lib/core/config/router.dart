import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agents/presentation/screens/agent_list_screen.dart';
import '../../features/approvals/presentation/screens/approval_detail_screen.dart';
import '../../features/approvals/presentation/screens/approvals_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/session_list_screen.dart';
import '../../features/diff/presentation/screens/diff_viewer_screen.dart';
import '../../features/git/presentation/screens/git_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/repos/presentation/screens/file_tree_screen.dart';
import '../../features/repos/presentation/screens/file_viewer_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/startup/presentation/screens/bridge_setup_screen.dart';
import '../../features/startup/presentation/screens/splash_screen.dart';
import '../../features/terminal/presentation/screens/terminal_screen.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/splash'),
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
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
                builder: (_, __) => const GitScreen(sessionId: ''),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/approvals',
                builder: (_, __) => const ApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/home/agents',
        builder: (_, __) => const AgentListScreen(),
      ),
      GoRoute(
        path: '/approval/:id',
        builder: (_, state) =>
            ApprovalDetailScreen(toolCallId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/terminal',
        builder: (_, __) =>
            const TerminalScreen(sessionId: 'default', workingDirectory: '~'),
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

final routerProvider = Provider<GoRouter>((ref) {
  return _buildRouter();
});

final appRouter = Provider<GoRouter>((ref) => ref.watch(routerProvider));
