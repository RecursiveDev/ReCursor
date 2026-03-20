// Router integration smoke test — verifies key feature screen imports resolve.
// Run with: flutter test test/router_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/features/agents/presentation/screens/agent_list_screen.dart';
import 'package:recursor_mobile/features/approvals/presentation/screens/approval_detail_screen.dart';
import 'package:recursor_mobile/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:recursor_mobile/features/git/presentation/screens/git_screen.dart';
import 'package:recursor_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:recursor_mobile/features/startup/presentation/screens/bridge_setup_screen.dart';
import 'package:recursor_mobile/features/startup/presentation/screens/splash_screen.dart';
import 'package:recursor_mobile/features/terminal/presentation/screens/terminal_screen.dart';

void main() {
  group('Feature Screen Reachability', () {
    test('SplashScreen exists and instantiates', () {
      const screen = SplashScreen();
      expect(screen, isA<SplashScreen>());
    });

    test('BridgeSetupScreen exists and instantiates', () {
      const screen = BridgeSetupScreen();
      expect(screen, isA<BridgeSetupScreen>());
    });

    test('AgentListScreen exists and instantiates', () {
      const screen = AgentListScreen();
      expect(screen, isA<AgentListScreen>());
    });

    test('ApprovalDetailScreen exists and instantiates', () {
      const screen = ApprovalDetailScreen(toolCallId: 'test-id');
      expect(screen, isA<ApprovalDetailScreen>());
    });

    test('ApprovalsScreen exists and instantiates', () {
      const screen = ApprovalsScreen();
      expect(screen, isA<ApprovalsScreen>());
    });

    test('GitScreen exists and instantiates', () {
      const screen = GitScreen(sessionId: '');
      expect(screen, isA<GitScreen>());
    });

    test('SettingsScreen exists and instantiates', () {
      const screen = SettingsScreen();
      expect(screen, isA<SettingsScreen>());
    });

    test('TerminalScreen exists and instantiates', () {
      const screen = TerminalScreen(
        sessionId: 'test-session',
        workingDirectory: '~/test',
      );
      expect(screen, isA<TerminalScreen>());
    });
  });
}
