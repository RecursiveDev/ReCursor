---
title: "Project Structure"
description: "Flutter directory layout and module organization for ReCursor."
sidebar:
  order: 30
  label: "Project structure"
---
> Flutter directory layout and module organization for ReCursor.

---

## Top-Level Layout

```
recursor/
├── apps/
│   └── mobile/                    # Flutter mobile app (iOS + Android)
│       ├── android/
│       ├── ios/
│       ├── lib/
│       │   ├── main.dart          # App entry point
│       │   ├── app.dart           # MaterialApp, router, theme
│       │   ├── core/              # App-wide infrastructure
│       │   ├── features/          # Feature modules
│       │   └── shared/            # Shared UI components
│       ├── test/                  # Unit + widget tests
│       ├── integration_test/      # Integration tests
│       ├── assets/                # Fonts, images, certificates
│       ├── pubspec.yaml
│       └── analysis_options.yaml
│
├── packages/
│   └── bridge/                    # TypeScript WebSocket bridge server
│       ├── src/
│       │   ├── server.ts          # WebSocket server entry
│       │   ├── agents/            # Agent adapters (Claude Code, OpenCode, etc.)
│       │   ├── hooks/             # Claude Code Hooks receiver
│       │   ├── git/               # Git operation handlers
│       │   ├── terminal/          # Terminal session manager
│       │   ├── auth/              # Device token validation, rate limiting
│       │   └── notifications/     # Event queue + WebSocket dispatch
│       ├── package.json
│       └── tsconfig.json
│
├── docs-site/                     # Documentation (Astro Starlight site)
│   └── src/content/docs/          # Canonical documentation source
├── .github/
│   └── workflows/                 # CI/CD pipelines
│       ├── test.yml               # PR test pipeline
│       └── deploy.yml             # Build + deploy pipeline
├── fastlane/                      # Fastlane config (iOS + Android)
└── README.md
```

---

## Flutter App Structure (`apps/mobile/lib/`)

### `core/` — App-Wide Infrastructure

```
core/
├── config/
│   ├── app_config.dart            # Environment config (dev, staging, prod)
│   ├── router.dart                # GoRouter route definitions
│   └── theme.dart                 # Material theme, colors, typography
│
├── network/
│   ├── websocket_service.dart     # WebSocket client (connect, reconnect, heartbeat)
│   ├── websocket_messages.dart    # Message type definitions (from bridge-protocol.md)
│   └── connection_state.dart      # Connection state enum + notifier
│
├── providers/
│   ├── token_storage_provider.dart # Secure bridge token storage provider
│   └── websocket_provider.dart     # Shared WebSocket service providers
│
├── storage/
│   ├── secure_token_storage.dart   # flutter_secure_storage wrapper for bridge pairing
│   ├── database.dart              # Drift database definition
│   ├── tables/                    # Drift table definitions
│   │   ├── sessions.dart
│   │   ├── messages.dart
│   │   ├── agents.dart
│   │   ├── approvals.dart
│   │   └── sync_queue.dart
│   ├── daos/                      # Data access objects
│   │   ├── session_dao.dart
│   │   ├── message_dao.dart
│   │   └── sync_dao.dart
│   └── preferences.dart           # Hive key-value store wrapper
│
├── notifications/
│   ├── notification_service.dart  # Local notification setup (flutter_local_notifications)
│   ├── notification_handler.dart  # WebSocket event -> in-app banner / local notification routing
│   └── notification_center.dart   # In-app notification list, unread count, persistence
│
└── sync/
    ├── sync_service.dart          # Offline queue flush + pull logic
    ├── sync_queue.dart            # Queue operations (enqueue, dequeue, retry)
    └── conflict_resolver.dart     # Last-write-wins + user prompt
```

### `features/` — Feature Modules

Each feature follows a consistent internal structure:

```
features/<feature>/
├── data/
│   ├── models/                    # Data transfer objects, JSON serialization
│   └── repositories/              # Repository implementations
├── domain/
│   ├── entities/                  # Domain models (immutable, no JSON)
│   └── providers/                 # Riverpod providers (state + logic)
└── presentation/
    ├── screens/                   # Full-page widgets
    ├── widgets/                   # Feature-specific reusable widgets
    └── controllers/               # UI logic (if needed beyond providers)
```

Feature modules:

```
features/
├── chat/                          # Agent chat interface
│   ├── data/
│   │   ├── models/
│   │   │   ├── chat_message.dart
│   │   │   └── chat_session.dart
│   │   └── repositories/
│   │       └── chat_repository.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── message.dart
│   │   └── providers/
│   │       ├── chat_provider.dart
│   │       └── session_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── chat_screen.dart
│       │   └── session_list_screen.dart
│       └── widgets/
│           ├── message_bubble.dart
│           ├── streaming_text.dart
│           ├── chat_input_bar.dart
│           ├── tool_card.dart          # OpenCode-style tool card
│           ├── message_part.dart       # OpenCode-style message parts
│           └── voice_input_sheet.dart
│
├── diff/                          # Code diff viewer
│   ├── data/
│   │   └── repositories/
│   │       └── diff_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── diff_provider.dart
│   └── presentation/
│       ├── screens/
│       │   └── diff_viewer_screen.dart
│       └── widgets/
│           ├── diff_viewer.dart       # OpenCode-style diff viewer
│           ├── diff_file_card.dart
│           ├── diff_hunk_view.dart
│           └── syntax_highlighted_text.dart
│
├── session/                       # Session management
│   ├── data/
│   │   └── repositories/
│   │       └── session_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── session_provider.dart
│   └── presentation/
│       ├── screens/
│       │   └── session_detail_screen.dart
│       └── widgets/
│           ├── session_timeline.dart   # OpenCode-style timeline
│           ├── session_card.dart
│           └── event_badge.dart
│
├── git/                           # Git operations
│   ├── data/
│   │   └── repositories/
│   │       └── git_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── git_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── commit_screen.dart
│       │   └── branch_screen.dart
│       └── widgets/
│           ├── git_status_card.dart
│           └── file_change_tile.dart
│
├── approvals/                     # Tool call approvals
│   ├── data/
│   │   └── repositories/
│   │       └── approval_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── approval_provider.dart
│   └── presentation/
│       ├── screens/
│       │   └── approval_detail_screen.dart
│       └── widgets/
│           ├── approval_card.dart
│           ├── risk_indicator.dart
│           └── modification_editor.dart
│
├── terminal/                      # Terminal session
│   ├── data/
│   │   └── repositories/
│   │       └── terminal_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── terminal_provider.dart
│   └── presentation/
│       ├── screens/
│       │   └── terminal_screen.dart
│       └── widgets/
│           ├── terminal_output.dart
│           └── ansi_renderer.dart
│
├── agents/                        # Agent management
│   ├── data/
│   │   └── repositories/
│   │       └── agent_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── agent_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── agent_list_screen.dart
│       │   └── agent_config_screen.dart
│       └── widgets/
│           └── agent_card.dart
│
├── startup/                       # Bridge-first launch and pairing restore
│   ├── domain/
│   │   └── bridge_startup_controller.dart
│   └── presentation/
│       └── screens/
│           ├── splash_screen.dart
│           └── bridge_setup_screen.dart
│
└── settings/                      # App settings
    └── presentation/
        ├── screens/
        │   └── settings_screen.dart
        └── widgets/
            └── setting_tile.dart
```

### `shared/` — Shared UI Components

```
shared/
├── widgets/
│   ├── loading_indicator.dart     # Consistent loading states
│   ├── error_card.dart            # Error display
│   ├── empty_state.dart           # Empty list placeholder
│   ├── connection_status_bar.dart # Online/offline indicator
│   ├── code_block.dart            # Syntax-highlighted code
│   ├── expandable_card.dart       # Reusable expandable pattern
│   └── markdown_view.dart         # Markdown rendering
│
├── constants/
│   ├── colors.dart                # App color palette
│   ├── typography.dart            # Text styles
│   └── dimens.dart                # Spacing, sizing constants
│
└── utils/
    ├── date_formatter.dart        # Date/time formatting
    ├── diff_parser.dart           # Unified diff parsing
    └── ansi_parser.dart           # ANSI color code parsing
```

---

## Bridge Server Structure (`packages/bridge/src/`)

```
bridge/
├── server.ts                      # Express + WebSocket server entry
├── config.ts                      # Environment configuration
├── types.ts                       # TypeScript type definitions
│
├── websocket/
│   ├── server.ts                  # WebSocket server setup
│   ├── connection_manager.ts      # Client connection tracking
│   └── message_handler.ts         # Message routing
│
├── hooks/
│   ├── receiver.ts                # Claude Code Hooks HTTP endpoint
│   ├── validator.ts               # Event validation
│   └── event_queue.ts             # Event queuing for offline replay
│
├── agents/
│   ├── agent_sdk_adapter.ts       # Agent SDK integration
│   ├── session_manager.ts         # Session lifecycle management
│   └── tool_executor.ts           # Tool execution wrapper
│
├── git/
│   ├── git_service.ts             # Git operations
│   └── diff_parser.ts             # Diff generation
│
├── terminal/
│   ├── terminal_manager.ts        # Terminal session management
│   └── output_stream.ts           # Terminal output streaming
│
├── auth/
│   ├── token_validator.ts         # Device pairing token validation
│   └── rate_limiter.ts            # Rate limiting
│
└── notifications/
    ├── event_bus.ts               # Internal event bus
    └── dispatcher.ts              # WebSocket dispatch
```

---

## Key Principles

1. **Feature-Based Organization**: Each feature is self-contained with its own data, domain, and presentation layers.

2. **Clean Architecture**: Dependencies flow inward:
   - Presentation depends on Domain
   - Domain depends on Data
   - Data depends on Core

3. **Riverpod for State**: All state management uses Riverpod providers, defined in `domain/providers/`.

4. **Repository Pattern**: All data access goes through repositories, which abstract local (Drift/Hive) vs. remote (WebSocket) sources.

5. **OpenCode UI Patterns**: UI components follow OpenCode patterns (tool cards, diff viewer, session timeline).

---

## Related Documentation

- [Data Models](./data-models/) — Drift schemas and domain entities
- [Architecture Overview](./system-overview/) — System architecture
- [OpenCode UI Patterns](../integrations/opencode-ui-patterns/) — UI component mapping

---

*Last updated: 2026-03-17*
