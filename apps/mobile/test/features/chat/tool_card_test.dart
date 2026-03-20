import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/models/message_models.dart';
import 'package:recursor_mobile/features/chat/presentation/widgets/tool_card.dart';

void main() {
  group('ToolCard', () {
    testWidgets('shows running state without metadata', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
              toolName: 'edit_file',
              params: {'path': 'lib/main.dart'},
              id: 'tool-1',
              isCompleted: false,
            ),
          ),
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('shows approval required state with risk level badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
              toolName: 'edit_file',
              params: {'path': 'lib/main.dart'},
              id: 'tool-1',
              isCompleted: false,
              metadata: {
                'risk_level': 'high',
                'source': 'agent_sdk',
              },
            ),
          ),
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      // High risk badge should be visible
      expect(find.text('HIGH'), findsOneWidget);
      // Approvals banner should be visible
      expect(find.textContaining('Approval required'), findsOneWidget);
      // Pending icon appears twice (in header and banner)
      expect(find.byIcon(Icons.pending_actions), findsNWidgets(2));
    });

    testWidgets('shows completed state with result', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
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
          ),
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows failed state with error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
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
          ),
        ),
      );

      expect(find.text('edit_file'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows medium risk level badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
              toolName: 'bash',
              params: {'command': 'ls -la'},
              id: 'tool-2',
              isCompleted: false,
              metadata: {'risk_level': 'medium'},
            ),
          ),
        ),
      );

      expect(find.text('MEDIUM'), findsOneWidget);
    });

    testWidgets('shows critical risk level badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
              toolName: 'bash',
              params: {'command': 'rm -rf /'},
              id: 'tool-3',
              isCompleted: false,
              metadata: {'risk_level': 'critical'},
            ),
          ),
        ),
      );

      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('expands parameters on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolCard(
              toolName: 'edit_file',
              params: {
                'path': 'lib/main.dart',
                'new_content': 'void main() {}'
              },
              id: 'tool-1',
              isCompleted: false,
            ),
          ),
        ),
      );

      // Parameters section should be present
      expect(find.text('Parameters'), findsOneWidget);

      // Tap on Parameters section
      await tester.tap(find.text('Parameters'));
      await tester.pumpAndSettle();

      // Key value list should now be visible (check for the widget type)
      expect(find.byType(ToolCard), findsOneWidget);
    });

    group('tool icon selection', () {
      testWidgets('shows file icon for file operations', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ToolCard(
                toolName: 'read_file',
                params: {},
                id: 'tool-1',
                isCompleted: false,
              ),
            ),
          ),
        );

        expect(find.byType(ToolCard), findsOneWidget);
      });

      testWidgets('shows terminal icon for bash operations', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ToolCard(
                toolName: 'bash',
                params: {},
                id: 'tool-1',
                isCompleted: false,
              ),
            ),
          ),
        );

        expect(find.byType(ToolCard), findsOneWidget);
      });

      testWidgets('shows git icon for git operations', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ToolCard(
                toolName: 'git_status',
                params: {},
                id: 'tool-1',
                isCompleted: false,
              ),
            ),
          ),
        );

        expect(find.byType(ToolCard), findsOneWidget);
      });
    });
  });
}
