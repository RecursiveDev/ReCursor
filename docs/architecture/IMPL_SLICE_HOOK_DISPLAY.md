# Implementation Slice: Hook Event Display

> **Status:** PROPOSED  
> **Date:** 2026-03-21  
> **Priority:** P0 (First testable user experience)

## Executive Summary

This implementation slice delivers **one complete end-to-end flow**: Claude Code session events flow from hooks to mobile app and render as OpenCode-style tool cards. This is the highest-value slice because:

1. **Primary integration path** - Hooks are the documented way to observe Claude Code sessions
2. **Minimal dependencies** - No Agent SDK API key required for observation mode
3. **Immediate verification** - User can see tool_use/tool_result events appear in real-time
4. **Architecture-preserving** - Agent-agnostic event types with Claude-specific adapters

---

## Scope Definition

### In Scope

| Component | Scope | Lines Changed (Est.) |
|-----------|-------|---------------------|
| **Mobile: Event State** | Riverpod providers for incoming `claude_event` messages | ~200 |
| **Mobile: Tool Card Widget** | OpenCode-style card for tool_use/tool_result | ~300 |
| **Mobile: Event Timeline** | Scrolling list of events with timestamps | ~150 |
| **Bridge: Protocol Verification** | End-to-end test for hook → websocket flow | ~100 |
| **Docs: Setup Guide** | How to configure Claude Code hooks for ReCursor | ~100 |

**Total estimated:** ~850 lines across 8-10 files

### Explicitly Deferred (Future Slices)

| Deferred Item | Rationale |
|---------------|-----------|
| Agent SDK chat interface | Requires API key, separate user flow |
| Approval workflow | Requires session state management |
| Git diff rendering | Depends on tool result parsing |
| Settings/configuration UI | Not needed for first flow |

---

## Architecture Context

```
┌─────────────────────────────────────────────────────────────────┐
│                        IMPLEMENTATION SLICE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Claude Code ──POST──► Bridge ──WebSocket──► Mobile ──Display   │
│       │                │                    │                   │
│   Hooks.json       /hooks/event         claude_event        ToolCard │
│                      │                    │                   │
│                 (Existing)          (New Provider)      (New Widget)│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**What already exists (preserve):**
- Bridge: `/hooks/event` endpoint (packages/bridge/src/hooks/receiver.ts)
- Bridge: EventQueue with broadcast (packages/bridge/src/hooks/event_queue.ts)
- Bridge: Protocol mapper for hook events to BridgeMessage (packages/bridge/src/hooks/protocol_mapper.ts)
- Mobile: WebSocket service receiving messages (apps/mobile/lib/core/network/websocket_service.dart)
- Mobile: BridgeMessage types including `claudeEvent` (apps/mobile/lib/core/network/websocket_messages.dart)

**What's missing:**
- Mobile: State management to transform incoming `claude_event` messages into UI-usable models
- Mobile: Tool card widget rendering (OpenCode-style)
- Mobile: Timeline/scrollable list to display events

---

## Implementation Plan

### Phase 1: Mobile Event State (Est. 200 lines, 2-3 files)

**Goal:** Transform incoming `claude_event` WebSocket messages into typed, observable state.

#### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `apps/mobile/lib/features/session/domain/models/event_models.dart` | CREATE | Dart models for HookEvent types |
| `apps/mobile/lib/features/session/domain/providers/event_provider.dart` | CREATE | Riverpod provider to collect events from WebSocket stream |
| `apps/mobile/lib/features/session/domain/providers/` | MODIFY | Wire event provider into WebSocket message listener |

#### Task Breakdown

```markdown
### Phase 1: Mobile Event State

- [ ] 1. Create `apps/mobile/lib/features/session/domain/models/event_models.dart` [S, Risk: L]
  - [ ] 1.1. Define `HookEvent` sealed class with event types [XS]
  - [ ] 1.2. Define `ToolUseEvent` subclass with tool, params, risk_level [XS]
  - [ ] 1.3. Define `ToolResultEvent` subclass with tool, result, duration [XS]
  - [ ] 1.4. Define `SessionStartEvent`, `SessionEndEvent`, `MessageEvent` subclasses [XS]
  - [ ] 1.5. Add `fromJson` factory for parsing BridgeMessage payloads [S]

- [ ] 2. Create `apps/mobile/lib/features/session/domain/providers/event_provider.dart` [S, Risk: L]
  - [ ] 2.1. Define `EventNotifier` extending `AsyncNotifier<List<HookEvent>>` [XS]
  - [ ] 2.2. Implement `addEvent(HookEvent event)` method [XS]
  - [ ] 2.3. Implement `getEventsForSession(String sessionId)` filter [XS]
  - [ ] 2.4. Expose `eventsProvider` for widget consumption [XS]

- [ ] 3. Wire event provider to WebSocket stream [XS, Risk: L]
  - [ ] 3.1. Locate WebSocket message listener in websocket_service.dart [XS]
  - [ ] 3.2. Add event provider reference injection [XS]
  - [ ] 3.3. Route `claude_event` messages to event provider [XS]
```

### Phase 2: Tool Card Widget (Est. 300 lines, 3-4 files)

**Goal:** Render tool_use and tool_result events as OpenCode-style cards.

#### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `apps/mobile/lib/features/session/presentation/widgets/tool_card.dart` | CREATE | StatefulWidget for tool_use/tool_result display |
| `apps/mobile/lib/features/session/presentation/widgets/tool_icon.dart` | CREATE | Icon mapping by tool type (Read, Edit, Bash, etc.) |
| `apps/mobile/lib/features/session/presentation/widgets/status_indicator.dart` | CREATE | Visual status (pending, running, completed, error) |

#### Task Breakdown

```markdown
### Phase 2: Tool Card Widget

- [ ] 4. Create `apps/mobile/lib/features/session/presentation/widgets/tool_icon.dart` [XS, Risk: L]
  - [ ] 4.1. Define `ToolIcon` widget with `toolName` parameter [XS]
  - [ ] 4.2. Map tool names to icons (Edit→edit, Read→description, Bash→terminal) [XS]
  - [ ] 4.3. Use Material icons with theme colors [XS]

- [ ] 5. Create `apps/mobile/lib/features/session/presentation/widgets/status_indicator.dart` [XS, Risk: L]
  - [ ] 5.1. Define `StatusIndicator` widget with `ToolStatus` enum [XS]
  - [ ] 5.2. Map statuses to colors (pending→grey, running→blue, completed→green, error→red) [XS]
  - [ ] 5.3. Add animated progress for 'running' status [XS]

- [ ] 6. Create `apps/mobile/lib/features/session/presentation/widgets/tool_card.dart` [M, Risk: L]
  - [ ] 6.1. Define `ToolCard` widget accepting `HookEvent` [XS]
  - [ ] 6.2. Add collapsible header with ToolIcon, tool name, status [S]
  - [ ] 6.3. Implement expandable body showing input params (truncated) [S]
  - [ ] 6.4. Add tool result section for tool_result events [S]
  - [ ] 6.5. Support dark/light theme via Theme.of(context) [XS]
  - [ ] 6.6. Add timestamp and duration display [XS]
```

### Phase 3: Event Timeline (Est. 150 lines, 2 files)

**Goal:** Display scrolling list of events from current session.

#### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `apps/mobile/lib/features/session/presentation/widgets/event_timeline.dart` | CREATE | ListView of ToolCards with auto-scroll |
| `apps/mobile/lib/features/session/presentation/screens/session_screen.dart` | CREATE | Main session view placeholder |

#### Task Breakdown

```markdown
### Phase 3: Event Timeline

- [ ] 7. Create `apps/mobile/lib/features/session/presentation/widgets/event_timeline.dart` [S, Risk: L]
  - [ ] 7.1. Define `EventTimeline` widget consuming `eventsProvider` [XS]
  - [ ] 7.2. Build ListView.builder with ToolCard items [XS]
  - [ ] 7.3. Implement auto-scroll to newest event with ScrollController [XS]
  - [ ] 7.4. Add empty state message for no events [XS]
  - [ ] 7.5. Use `ref.watch` to reactively update on new events [XS]

- [ ] 8. Create `apps/mobile/lib/features/session/presentation/screens/session_screen.dart` [S, Risk: L]
  - [ ] 8.1. Define `SessionScreen` with AppBar and EventTimeline body [XS]
  - [ ] 8.2. Add session ID display in AppBar title [XS]
  - [ ] 8.3. Wire to app navigation after health verification passes [S]
```

### Phase 4: End-to-End Verification (Est. 100 lines, 2-3 files)

**Goal:** Verify bridge correctly transforms and forwards hook events.

#### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `packages/bridge/tests/hooks/event_flow.test.ts` | CREATE | Integration test for hook → websocket |
| `apps/mobile/test/features/session/event_flow_test.dart` | CREATE | Widget test for event rendering |

#### Task Breakdown

```markdown
### Phase 4: End-to-End Verification

- [ ] 9. Create `packages/bridge/tests/hooks/event_flow.test.ts` [S, Risk: M]
  - [ ] 9.1. Mock WebSocket server ConnectionManager [S]
  - [ ] 9.2. POST sample hook event to `/hooks/event` [XS]
  - [ ] 9.3. Verify event queued in EventQueue [XS]
  - [ ] 9.4. Verify broadcast called with BridgeMessage [XS]

- [ ] 10. Create `apps/mobile/test/features/session/event_flow_test.dart` [S, Risk: M]
  - [ ] 10.1. Create mock WebSocket service injecting events [S]
  - [ ] 10.2. Render EventTimeline widget [XS]
  - [ ] 10.3. Inject sample claude_event message [XS]
  - [ ] 10.4. Verify ToolCard appears with correct data [S]

- [ ] 11. Run all tests and verify 100% pass [XS, Risk: L]
  - [ ] 11.1. Run `npm test` in packages/bridge [XS]
  - [ ] 11.2. Run `flutter test` in apps/mobile [XS]
  - [ ] 11.3. Fix any failing tests [Variable]
```

### Phase 5: Documentation (Est. 100 lines, 1 file)

**Goal:** Clear setup instructions for users to configure Claude Code hooks.

#### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `docs/setup/claude-code-hooks-setup.md` | CREATE | Step-by-step hook configuration guide |

#### Task Breakdown

```markdown
### Phase 5: Documentation

- [ ] 12. Create `docs/setup/claude-code-hooks-setup.md` [S, Risk: L]
  - [ ] 12.1. Document hooks.json location (~/.claude/hooks/hooks.json) [XS]
  - [ ] 12.2. Provide curl command template for bridge URL [XS]
  - [ ] 12.3. List supported event types and their payloads [S]
  - [ ] 12.4. Add troubleshooting section for common issues [S]
  - [ ] 12.5. Include example hooks.json for ReCursor [S]
```

---

## Existing Modifications to Preserve

The following files have uncommitted changes that **must not be modified** by this slice:

| File | Change Type | Description |
|------|-------------|-------------|
| `apps/mobile/lib/core/network/websocket_messages.dart` | Modified | Added `ConnectionPurpose` enum and purpose field - **DO NOT TOUCH** |
| `apps/mobile/lib/core/network/websocket_service.dart` | Modified | Added purpose parameter to connect() - **DO NOT TOUCH** |
| `packages/bridge/src/types.ts` | Modified | Added `ConnectionPurpose` type - **DO NOT TOUCH** |
| `packages/bridge/src/websocket/connection_manager.ts` | Modified | Added purpose tracking to MobileClient - **DO NOT TOUCH** |
| `packages/bridge/src/websocket/connection_mode.ts` | Modified | Connection mode detection logic - **DO NOT TOUCH** |
| `packages/bridge/src/websocket/message_handler.ts` | Modified | Purpose handling in auth - **DO NOT TOUCH** |

**Strategy:** All new code goes in `features/session/` directory, not in `core/network/`.

---

## Testing Strategy

### Unit Tests

- `event_models_test.dart` - JSON parsing for all event types
- `event_provider_test.dart` - State management logic
- `tool_card_test.dart` - Widget rendering with various statuses

### Integration Tests

- Bridge: POST hook event → WebSocket broadcast
- Mobile: WebSocket receive → State update → Widget render

### Manual Verification

1. Start bridge server: `npm run dev` in `packages/bridge`
2. Start mobile app: `flutter run` in `apps/mobile`
3. Connect mobile to bridge (use stored credentials or manual entry)
4. POST test hook event to `http://localhost:3000/hooks/event`
5. Verify tool card appears in mobile app within 2 seconds

---

## Success Criteria

| Criterion | Verification Method |
|-----------|---------------------|
| Events appear in mobile app | Screenshot of EventTimeline with tool cards |
| End-to-end test passes | `npm test` + `flutter test` output |
| No regressions in existing tests | All existing tests pass |
| Documentation complete | User can configure hooks without help |
| Architecture preserved | No modifications to websocket_messages.dart or websocket_service.dart |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing connection flow | Low | High | All new code in `features/session/`, not `core/network/` |
| Hook event format changes upstream | Low | Medium | Document Claude Code version tested against |
| Performance with many events | Low | Low | EventQueue already handles 1000 event limit |
| Mobile state race conditions | Medium | Medium | Use Riverpod's built-in async handling |

---

## Effort Estimate

| Phase | Effort | Risk | Dependencies |
|-------|--------|------|--------------|
| Phase 1: Event State | M (4h) | L | None |
| Phase 2: Tool Cards | M (6h) | L | Phase 1 |
| Phase 3: Timeline | S (2h) | L | Phase 2 |
| Phase 4: Verification | S (3h) | M | Phases 1-3 |
| Phase 5: Documentation | S (1h) | L | None |
| **Total** | **M (16h / ~2 days)** | **L** | - |

---

## Files Summary

**New files to create (10):**
```
apps/mobile/lib/features/session/
├── domain/
│   ├── models/
│   │   └── event_models.dart          # Phase 1
│   └── providers/
│       └── event_provider.dart        # Phase 1
└── presentation/
    ├── screens/
    │   └── session_screen.dart        # Phase 3
    └── widgets/
        ├── event_timeline.dart        # Phase 3
        ├── status_indicator.dart      # Phase 2
        ├── tool_card.dart             # Phase 2
        └── tool_icon.dart             # Phase 2

packages/bridge/tests/hooks/
└── event_flow.test.ts                 # Phase 4

apps/mobile/test/features/session/
└── event_flow_test.dart              # Phase 4

docs/setup/
└── claude-code-hooks-setup.md        # Phase 5
```

**Files to modify (1):**
```
apps/mobile/lib/features/startup/domain/bridge_startup_controller.dart
# Wire session screen after health verification (Phase 3)
```

**Existing modified files to preserve (not touch):**
- See "Existing Modifications to Preserve" section above

---

## Acceptance Checklist

Before marking complete:

- [ ] All new files compile without errors
- [ ] All unit tests pass (`flutter test`, `npm test`)
- [ ] Manual test: POST hook event appears in mobile within 2 seconds
- [ ] Documentation allows user to configure hooks independently
- [ ] No modifications to existing `websocket_service.dart` or `websocket_messages.dart`
- [ ] Architecture pattern matches `docs/architecture/overview.md` (agent-agnostic)

---

*Last updated: 2026-03-21*