import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/models/message_models.dart';
import 'package:recursor_mobile/features/chat/presentation/widgets/tool_card.dart';

void main() {
  group('ToolCard', () {
    testWidgets('shows running state without metadata', (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {'path': 'lib/main.dart'},
          id: 'tool-1',
          isCompleted: false,
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('shows approval required state with risk level badge',
        (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {'path': 'lib/main.dart'},
          id: 'tool-1',
          isCompleted: false,
          metadata: {
            'risk_level': 'high',
            'source': 'agent_sdk',
          },
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.textContaining('Approval required'), findsOneWidget);
      expect(find.byIcon(Icons.pending_actions), findsNWidgets(2));
    });

    testWidgets('shows hook observation banner for hook sourced approvals',
        (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {'path': 'lib/main.dart'},
          id: 'tool-1',
          isCompleted: false,
          metadata: {
            'risk_level': 'high',
            'source': 'hooks',
          },
        ),
      );

      expect(find.textContaining('Observed via Claude hooks'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('shows completed state with result', (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {'path': 'lib/main.dart'},
          id: 'tool-1',
          isCompleted: true,
          result: ToolResult(
            success: true,
            content: 'File updated successfully',
            durationMs: 150,
          ),
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows diff handoff button when result contains a diff',
        (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {'path': 'lib/main.dart'},
          id: 'tool-1',
          isCompleted: true,
          result: ToolResult(
            success: true,
            content: 'Updated file',
            metadata: {
              'diff':
                  '--- a/lib/main.dart\n+++ b/lib/main.dart\n@@ -1 +1 @@\n-void oldMain() {}\n+void main() {}',
            },
          ),
        ),
      );

      expect(find.text('View Diff'), findsOneWidget);
    });

    testWidgets('shows failed state with error', (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {'path': 'lib/main.dart'},
          id: 'tool-1',
          isCompleted: true,
          result: ToolResult(
            success: false,
            content: '',
            error: 'Permission denied',
            durationMs: 50,
          ),
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows medium risk level badge', (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'bash',
          params: {'command': 'ls -la'},
          id: 'tool-2',
          isCompleted: false,
          metadata: {'risk_level': 'medium'},
        ),
      );

      expect(find.text('MEDIUM'), findsOneWidget);
    });

    testWidgets('shows critical risk level badge', (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'bash',
          params: {'command': 'rm -rf /'},
          id: 'tool-3',
          isCompleted: false,
          metadata: {'risk_level': 'critical'},
        ),
      );

      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('expands parameters on tap', (tester) async {
      await _pumpToolCard(
        tester,
        const ToolCard(
          toolName: 'edit_file',
          params: {
            'path': 'lib/main.dart',
            'new_content': 'void main() {}',
          },
          id: 'tool-1',
          isCompleted: false,
        ),
      );

      expect(find.text('Parameters'), findsOneWidget);

      await tester.tap(find.text('Parameters'));
      await tester.pumpAndSettle();

      expect(find.byType(ToolCard), findsOneWidget);
    });

    group('tool icon selection', () {
      testWidgets('shows file icon for file operations', (tester) async {
        await _pumpToolCard(
          tester,
          const ToolCard(
            toolName: 'read_file',
            params: {},
            id: 'tool-1',
            isCompleted: false,
          ),
        );

        expect(find.byType(ToolCard), findsOneWidget);
      });

      testWidgets('shows terminal icon for bash operations', (tester) async {
        await _pumpToolCard(
          tester,
          const ToolCard(
            toolName: 'bash',
            params: {},
            id: 'tool-1',
            isCompleted: false,
          ),
        );

        expect(find.byType(ToolCard), findsOneWidget);
      });

      testWidgets('shows git icon for git operations', (tester) async {
        await _pumpToolCard(
          tester,
          const ToolCard(
            toolName: 'git_status',
            params: {},
            id: 'tool-1',
            isCompleted: false,
          ),
        );

        expect(find.byType(ToolCard), findsOneWidget);
      });
    });
  });
}

Future<void> _pumpToolCard(WidgetTester tester, ToolCard toolCard) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: toolCard),
      ),
    ),
  );
}
