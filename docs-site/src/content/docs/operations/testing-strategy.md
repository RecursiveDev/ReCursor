---
title: "Testing Strategy"
description: "Comprehensive testing approach for ReCursor, a Flutter app with WebSocket connections and Claude Code integrations."
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/testing-strategy.md"
sidebar:
  order: 50
  label: "Testing strategy"
---
> Comprehensive testing approach for ReCursor, a Flutter app with WebSocket connections and Claude Code integrations.

---

## Testing Pyramid

```
         /  E2E  \          patrol - full user journeys on real devices
        /----------\
       / Integration \      Local WS server + integration_test
      /----------------\
     /   Widget Tests    \  flutter_test widget tester + mock providers
    /----------------------\
   /      Unit Tests        \ flutter_test + mockito/mocktail
  /--------------------------\
```

---

## Unit Testing

**Tools:** `flutter_test`, `mockito` or `mocktail`

### WebSocket Mocking Pattern

```dart
// Create a StreamController to simulate server messages
final controller = StreamController<dynamic>();
final mockChannel = MockWebSocketChannel(controller.stream);

// Inject via Riverpod override
final container = ProviderContainer(overrides: [
  webSocketProvider.overrideWithValue(mockChannel),
]);

// Simulate server messages
controller.add('{"type": "response", "data": "Hello"}');

// Assert with stream matchers
expectLater(
  service.messages,
  emitsInOrder([isA<AgentResponse>()]),
);
```

### Key Rules

- Mock WebSocket with `StreamController<dynamic>`, not Mockito directly on streams.
- Use `thenAnswer` (not `thenReturn`) for anything returning a Future or Stream.
- Use `expectLater` with `emitsInOrder` / `emits` / `emitsDone` for async stream assertions.
- Call `expectLater` **before** the stream emits to avoid missing events.

### What to Unit Test

- WebSocket service (connect, disconnect, reconnect, message parsing)
- Bridge connection state transitions (disconnected -> connecting -> connected -> error)
- Git command serialization/deserialization
- Notification payload parsing
- Diff parsing logic
- Sync queue operations and conflict resolution
- Claude Code Hook event parsing

---

## Widget Testing

**Tools:** `flutter_test` widget tester

### Pattern

```dart
testWidgets('shows connected status', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionStateProvider.overrideWith((_) => ConnectionState.connected),
      ],
      child: const MaterialApp(home: ChatScreen()),
    ),
  );

  expect(find.text('Connected'), findsOneWidget);
});
```

### What to Widget Test

- Chat UI with mock message streams
- Bridge QR pairing screen
- OpenCode-style Tool Cards with sample data
- Diff viewer with sample diff data
- Approval UI approve/reject/modify interactions
- Connection state indicators (connected, disconnected, reconnecting)
- Repository list and file browser
- Session timeline rendering

### OpenCode UI Component Testing

```dart
testWidgets('renders tool card with correct status', (tester) async {
  final toolUse = ToolUse(
    tool: 'edit_file',
    params: {'file_path': 'test.dart'},
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ToolCard(
          tool: toolUse,
          status: ToolStatus.completed,
        ),
      ),
    ),
  );
  
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
  expect(find.text('edit_file'), findsOneWidget);
});
```

---

## Golden Tests (Visual Regression)

**Tool:** `alchemist`

- Capture baseline screenshots for key screens and states.
- Connection states: connected, disconnected, reconnecting.
- Chat: empty, loading, with messages, with streaming response.
- Diff viewer: added lines, removed lines, modified files.
- Tool cards: pending, running, completed, error states.
- Run on CI to catch unintended visual changes.

---

## Integration Testing

**Tools:** `integration_test` package + local Dart WebSocket server

### Pattern

```dart
setUpAll(() async {
  // Start a local WebSocket server that replays scripted messages
  testServer = await TestBridgeServer.start(port: 8765);
});

testWidgets('full chat flow', (tester) async {
  await tester.pumpWidget(const MyApp());

  // Connect to local bridge
  await tester.tap(find.byKey(Key('connect_button')));
  await tester.pumpAndSettle();

  // Send a message
  await tester.enterText(find.byType(TextField), 'Fix the bug');
  await tester.tap(find.byKey(Key('send_button')));

  // Wait for streamed response
  await tester.pumpAndSettle(Duration(seconds: 2));
  expect(find.textContaining('Fixed'), findsOneWidget);
});
```

### What to Integration Test

- Bridge connect -> validate pairing -> chat -> receive response
- Git operation flows (commit, push, pull)
- Approval flow (receive tool call -> approve -> agent continues)
- Offline -> reconnect -> sync
- Hook event flow (Claude Code -> Hooks -> Bridge -> Mobile)

### Test Bridge Server

```typescript
// Local TypeScript server for integration tests
import { WebSocketServer } from 'ws';

class TestBridgeServer {
  private wss: WebSocketServer;
  private scenarios: Map<string, WebSocketMessage[]>;

  start(port: number) {
    this.wss = new WebSocketServer({ port });
    
    this.wss.on('connection', (ws) => {
      ws.on('message', (data) => {
        const msg = JSON.parse(data.toString());
        
        // Replay scripted responses
        const responses = this.scenarios.get(msg.type) || [];
        for (const response of responses) {
          ws.send(JSON.stringify(response));
        }
      });
    });
  }
}
```

---

## E2E Testing

**Tool:** `patrol`

- Complete user journeys on real or emulated devices.
- Includes system-level interactions (notifications, deep links).
- Run on `main` branch merges (too slow for every PR).

### E2E Scenarios

- Full onboarding flow: install -> bridge pairing -> first message
- Background notification: receive approval request -> tap notification -> approve
- Multi-session: switch between agent sessions
- Offline workflow: actions while offline -> sync on reconnect

---

## CI Integration

| Trigger | Tests Run |
|---------|-----------|
| PR opened/updated | Unit + Widget + Golden + `flutter analyze` |
| Push to `main` | All above + Integration |
| Release tag | All above + E2E on physical devices |

---

## Testing Conventions

### Mock Data

```dart
class TestData {
  static ToolUse sampleToolUse = ToolUse(
    tool: 'edit_file',
    params: {
      'file_path': 'lib/main.dart',
      'old_string': 'void main() {',
      'new_string': 'void main() async {',
    },
  );
  
  static DiffFile sampleDiffFile = DiffFile(
    path: 'lib/main.dart',
    status: FileChangeStatus.modified,
    additions: 1,
    deletions: 1,
    hunks: [
      DiffHunk(
        header: '@@ -10,5 +10,5 @@',
        oldStart: 10,
        oldLines: 5,
        newStart: 10,
        newLines: 5,
        lines: [
          DiffLine(type: DiffLineType.context, content: ' class MyApp {'),
          DiffLine(type: DiffLineType.removed, content: '-  void main() {'),
          DiffLine(type: DiffLineType.added, content: '+  void main() async {'),
          DiffLine(type: DiffLineType.context, content: '     // ...'),
        ],
      ),
    ],
  );
}
```

### Async Test Helpers

```dart
// Helper to wait for Riverpod state changes
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);
  
  while (DateTime.now().isBefore(endTime)) {
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  
  throw TimeoutException('Finder not found within $timeout');
}
```

---

## Claude Code Integration Testing

### Hook Event Testing

```dart
test('parses PostToolUse hook event', () {
  final json = {
    'event_type': 'PostToolUse',
    'session_id': 'sess-abc',
    'timestamp': '2026-03-17T10:32:00Z',
    'payload': {
      'tool': 'edit_file',
      'result': {'success': true},
    },
  };
  
  final event = HookEvent.fromJson(json);
  expect(event.eventType, 'PostToolUse');
  expect(event.sessionId, 'sess-abc');
});
```

### Bridge Integration Testing

```dart
testWidgets('displays Claude Code event from bridge', (tester) async {
  final bridge = MockBridgeService();
  
  when(bridge.eventStream).thenAnswer((_) => Stream.fromIterable([
    HookEvent.postToolUse(
      tool: 'edit_file',
      result: ToolResult.success(),
    ),
  ]));
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bridgeProvider.overrideWithValue(bridge),
      ],
      child: const ChatScreen(),
    ),
  );
  
  await tester.pump();
  expect(find.byType(ToolCard), findsOneWidget);
});
```

---

## Related Documentation

- [CI/CD Pipeline](/operations/ci-cd/) — CI/CD configuration
- [Architecture Overview](/architecture/system-overview/) — System architecture
- [Bridge Protocol](/architecture/bridge-protocol/) — WebSocket message specification

---

*Last updated: 2026-03-17*
