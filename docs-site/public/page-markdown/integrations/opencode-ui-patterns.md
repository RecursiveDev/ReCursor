# OpenCode UI Patterns for ReCursor

> Mapping OpenCode's terminal-native UI components to Flutter mobile widgets.

---

## Overview

**OpenCode** ([opencode-ai/opencode](https://github.com/opencode-ai/opencode)) is a terminal-native AI coding agent with a sophisticated UI for displaying tool use, diffs, and session state. ReCursor adapts these patterns for mobile Flutter.

> **Source Reference**: `C:/Repository/opencode/packages/ui/src/components/`

---

## Component Mapping

### Tool Cards

OpenCode renders rich tool cards in the terminal. ReCursor adapts these as Flutter cards.

#### OpenCode Pattern

```typescript
// OpenCode: packages/ui/src/components/basic-tool.tsx
interface ToolCardProps {
  tool: string;
  params: Record<string, any>;
  result?: ToolResult;
  status: 'pending' | 'running' | 'completed' | 'error';
}

// Terminal output with ANSI colors and formatting
<ToolCard>
  <ToolHeader icon={getToolIcon(tool)} name={tool} />
  <ToolParams params={params} />
  <ToolResult result={result} />
</ToolCard>
```

#### ReCursor Flutter Implementation

```dart
// ReCursor: lib/features/chat/widgets/tool_card.dart
class ToolCard extends StatelessWidget {
  final ToolUse tool;
  final ToolResult? result;
  final ToolStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToolHeader(tool: tool, status: status),
          _ToolParams(params: tool.params),
          if (result != null) _ToolResult(result: result),
        ],
      ),
    );
  }
}
```

#### Tool Card States

| State | OpenCode | ReCursor |
|-------|----------|----------|
| Pending | Spinner + "Running..." | `CircularProgressIndicator` + pulse animation |
| Running | Live output stream | Streaming text with fade-in |
| Completed | Checkmark + result | `Icons.check_circle` + expandable result |
| Error | Red X + error details | `Icons.error` + error card |

---

### Diff Viewer

OpenCode shows syntax-highlighted diffs. ReCursor provides touch-friendly diff viewing.

#### OpenCode Pattern

```typescript
// OpenCode: packages/ui/src/components/diff-changes.tsx
interface DiffChangesProps {
  files: DiffFile[];
  viewMode: 'unified' | 'split';
}

// Terminal diff with ANSI colors
<DiffChanges>
  {files.map(file => (
    <DiffFile key={file.path}>
      <DiffHeader path={file.path} stats={file.stats} />
      <DiffHunks hunks={file.hunks} />
    </DiffFile>
  ))}
</DiffChanges>
```

#### ReCursor Flutter Implementation

```dart
// ReCursor: lib/features/diff/widgets/diff_viewer.dart
class DiffViewer extends StatelessWidget {
  final List<DiffFile> files;
  final DiffViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        return DiffFileCard(
          file: files[index],
          viewMode: viewMode,
        );
      },
    );
  }
}

class DiffFileCard extends StatelessWidget {
  final DiffFile file;
  
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: _FileStatusIcon(status: file.status),
      title: Text(file.path),
      subtitle: Text('+${file.additions} -${file.deletions}'),
      children: [
        DiffHunksView(hunks: file.hunks),
      ],
    );
  }
}
```

#### Diff Line Rendering

```dart
// Syntax-highlighted diff lines
class DiffLine extends StatelessWidget {
  final DiffLineType type; // added, removed, context
  final String content;
  final int? lineNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColorForType(type),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          if (lineNumber != null)
            Text('$lineNumber', style: TextStyle(color: Colors.grey)),
          SizedBox(width: 8),
          _DiffMarker(type: type),
          Expanded(
            child: SyntaxHighlightedText(
              code: content,
              language: file.extension,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Session Timeline

OpenCode shows a timeline of session events. ReCursor adapts this as a scrollable timeline.

#### OpenCode Pattern

```typescript
// OpenCode: packages/ui/src/components/session-turn.tsx
interface SessionTurnProps {
  turns: Turn[];
  currentTurn: number;
}

// Terminal timeline with turn markers
<SessionTurn>
  {turns.map((turn, index) => (
    <TurnMarker
      key={turn.id}
      index={index}
      active={index === currentTurn}
      type={turn.type}
    />
  ))}
</SessionTurn>
```

#### ReCursor Flutter Implementation

```dart
// ReCursor: lib/features/session/widgets/session_timeline.dart
class SessionTimeline extends StatelessWidget {
  final List<SessionEvent> events;
  final String? currentEventId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        return TimelineTile(
          event: events[index],
          isActive: events[index].id == currentEventId,
          isFirst: index == 0,
          isLast: index == events.length - 1,
        );
      },
    );
  }
}

class TimelineTile extends StatelessWidget {
  final SessionEvent event;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        Column(
          children: [
            _TimelineDot(
              type: event.type,
              isActive: isActive,
            ),
            if (!isLast) _TimelineConnector(),
          ],
        ),
        SizedBox(width: 12),
        // Event content
        Expanded(
          child: _EventCard(event: event),
        ),
      ],
    );
  }
}
```

---

### Message Parts

OpenCode renders message content as typed parts. ReCursor uses similar part-based rendering.

#### OpenCode Pattern

```typescript
// OpenCode: packages/ui/src/components/message-part.tsx
interface MessagePartProps {
  part: MessagePart;
}

type MessagePart =
  | { type: 'text'; content: string }
  | { type: 'tool_use'; tool: string; params: any }
  | { type: 'tool_result'; result: ToolResult }
  | { type: 'thinking'; content: string };

// Render based on part type
function MessagePart({ part }: MessagePartProps) {
  switch (part.type) {
    case 'text':
      return <MarkdownText content={part.content} />;
    case 'tool_use':
      return <ToolCard tool={part.tool} params={part.params} />;
    case 'tool_result':
      return <ToolResult result={part.result} />;
    case 'thinking':
      return <ThinkingBlock content={part.content} />;
  }
}
```

#### ReCursor Flutter Implementation

```dart
// ReCursor: lib/features/chat/widgets/message_part.dart
class MessagePart extends StatelessWidget {
  final MessagePartEntity part;

  @override
  Widget build(BuildContext context) {
    return part.map(
      text: (p) => MarkdownText(content: p.content),
      toolUse: (p) => ToolCard(
        tool: p.tool,
        params: p.params,
        status: ToolStatus.pending,
      ),
      toolResult: (p) => ToolResultCard(result: p.result),
      thinking: (p) => ThinkingBlock(content: p.content),
    );
  }
}

// Freezed union for type-safe message parts
@freezed
class MessagePartEntity with _$MessagePartEntity {
  const factory MessagePartEntity.text({
    required String content,
  }) = TextPart;
  
  const factory MessagePartEntity.toolUse({
    required String tool,
    required Map<String, dynamic> params,
  }) = ToolUsePart;
  
  const factory MessagePartEntity.toolResult({
    required ToolResult result,
  }) = ToolResultPart;
  
  const factory MessagePartEntity.thinking({
    required String content,
  }) = ThinkingPart;
}
```

---

## UI Component Library

### Core Components

| OpenCode Component | ReCursor Widget | File |
|-------------------|-----------------|------|
| `BasicTool` | `ToolCard` | `lib/features/chat/widgets/tool_card.dart` |
| `DiffChanges` | `DiffViewer` | `lib/features/diff/widgets/diff_viewer.dart` |
| `SessionTurn` | `SessionTimeline` | `lib/features/session/widgets/session_timeline.dart` |
| `MessagePart` | `MessagePart` | `lib/features/chat/widgets/message_part.dart` |
| `ChatMessage` | `MessageBubble` | `lib/features/chat/widgets/message_bubble.dart` |

### Supporting Widgets

```dart
// lib/shared/widgets/

// Tool icon based on tool name
class ToolIcon extends StatelessWidget {
  final String tool;
  
  IconData get icon {
    return switch (tool) {
      'edit_file' => Icons.edit,
      'read_file' => Icons.file_open,
      'run_command' => Icons.terminal,
      'glob' => Icons.folder,
      'grep' => Icons.search,
      _ => Icons.build,
    };
  }
}

// Status indicator for tool execution
class ToolStatusIndicator extends StatelessWidget {
  final ToolStatus status;
  
  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ToolStatus.pending => SpinKitPulse(color: Colors.blue),
      ToolStatus.running => SpinKitWave(color: Colors.orange),
      ToolStatus.completed => Icon(Icons.check_circle, color: Colors.green),
      ToolStatus.error => Icon(Icons.error, color: Colors.red),
    };
  }
}

// Expandable code block with syntax highlighting
class CodeBlock extends StatelessWidget {
  final String code;
  final String? language;
  
  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: Text(language ?? 'Code'),
      collapsed: _TruncatedCode(code: code),
      expanded: SyntaxHighlightedCode(
        code: code,
        language: language,
      ),
    );
  }
}
```

---

## Theming

### OpenCode Color Scheme

OpenCode uses a terminal-inspired color scheme:

| Element | OpenCode (Terminal) | ReCursor (Flutter) |
|---------|---------------------|-------------------|
| Background | `#1e1e1e` (dark) | `Color(0xFF1E1E1E)` |
| Text | `#d4d4d4` | `Color(0xFFD4D4D4)` |
| Added lines | `#4ec9b0` (green) | `Colors.green[400]` |
| Removed lines | `#f44747` (red) | `Colors.red[400]` |
| Tool header | `#569cd6` (blue) | `Colors.blue[400]` |
| Accent | `#ce9178` (orange) | `Colors.orange[300]` |

### Material You Adaptation

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF569CD6),
        secondary: Color(0xFF4EC9B0),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: Color(0xFFF44747),
      ),
      cardTheme: CardTheme(
        color: Color(0xFF252526),
        elevation: 2,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: Color(0xFFD4D4D4),
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }
}
```

---

## Responsive Considerations

### Mobile Adaptations

| OpenCode (Terminal) | ReCursor (Mobile) |
|---------------------|-------------------|
| Fixed-width font | Dynamic font sizing |
| Horizontal scrolling | Horizontal swipe gestures |
| Keyboard shortcuts | Touch gestures + FABs |
| Split panes | Tab navigation |
| Mouse hover | Long-press menus |

### Tablet Layouts

```dart
// lib/features/chat/screens/chat_screen.dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Tablet: Split view
          return Row(
            children: [
              Expanded(flex: 2, child: ChatPanel()),
              Expanded(flex: 3, child: DetailPanel()),
            ],
          );
        }
        // Phone: Single panel
        return ChatPanel();
      },
    );
  }
}
```

---

## Animation Patterns

### Tool Card Animations

```dart
// Smooth expansion when tool completes
class ToolCard extends StatefulWidget {
  @override
  _ToolCardState createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(ToolCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == ToolStatus.completed &&
        oldWidget.status != ToolStatus.completed) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Card(/* ... */),
    );
  }
}
```

---

## Related Documentation

- [Architecture Overview](../architecture/system-overview/) — System architecture
- [Data Flow](../architecture/data-flow/) — Message sequence diagrams
- [Claude Code Hooks Integration](./claude-code-hooks/) — Event source
- [Agent SDK Integration](./agent-sdk/) — Session control

---

*Last updated: 2026-03-17*
