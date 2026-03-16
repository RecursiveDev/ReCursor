# Project Structure

> Flutter directory layout and module organization for RemoteCLI.

---

## Top-Level Layout

```
remotecli/
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
│       │   ├── git/               # Git operation handlers
│       │   ├── terminal/          # Terminal session manager
│       │   ├── auth/              # Token validation, rate limiting
│       │   └── notifications/     # Event queue + WebSocket dispatch
│       ├── package.json
│       └── tsconfig.json
│
├── docs/                          # Documentation (this folder)
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
├── auth/
│   ├── auth_provider.dart         # Riverpod auth state provider
│   ├── auth_repository.dart       # OAuth + PAT token management
│   ├── token_storage.dart         # flutter_secure_storage wrapper
│   └── github_oauth.dart          # OAuth2 flow handler
│
├── storage/
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
│           └── voice_input_sheet.dart
│
├── files/                         # File browsing (via bridge)
│   ├── data/
│   │   ├── models/
│   │   │   └── file_tree_node.dart
│   │   └── repositories/
│   │       └── file_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── file_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── file_tree_screen.dart
│       │   └── file_viewer_screen.dart
│       └── widgets/
│           ├── tree_node.dart
│           └── syntax_viewer.dart
│
├── git/                           # Git operations
│   ├── data/
│   │   ├── models/
│   │   │   ├── git_status.dart
│   │   │   ├── git_branch.dart
│   │   │   └── git_commit.dart
│   │   └── repositories/
│   │       └── git_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       ├── git_provider.dart
│   │       └── branch_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── git_overview_screen.dart
│       │   ├── branch_manager_screen.dart
│       │   └── commit_screen.dart
│       └── widgets/
│           ├── branch_card.dart
│           ├── commit_card.dart
│           └── push_pull_progress.dart
│
├── diff/                          # Code diff viewer
│   ├── data/
│   │   └── models/
│   │       ├── diff_file.dart
│   │       └── diff_hunk.dart
│   ├── domain/
│   │   └── providers/
│   │       └── diff_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── diff_overview_screen.dart
│       │   └── diff_detail_screen.dart
│       └── widgets/
│           ├── unified_diff_view.dart
│           ├── side_by_side_diff.dart
│           ├── diff_line.dart
│           └── line_comment_sheet.dart
│
├── approvals/                     # Tool call approval flow
│   ├── data/
│   │   ├── models/
│   │   │   └── tool_call.dart
│   │   └── repositories/
│   │       └── approval_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── approval_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── approval_detail_screen.dart
│       │   └── audit_log_screen.dart
│       └── widgets/
│           ├── approval_card.dart
│           └── modify_sheet.dart
│
├── terminal/                      # Terminal session
│   ├── data/
│   │   └── models/
│   │       └── terminal_session.dart
│   ├── domain/
│   │   └── providers/
│   │       └── terminal_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── terminal_screen.dart
│       │   └── terminal_picker_screen.dart
│       └── widgets/
│           ├── terminal_output.dart
│           └── terminal_input_bar.dart
│
├── agents/                        # Multi-agent management
│   ├── data/
│   │   ├── models/
│   │   │   └── agent_config.dart
│   │   └── repositories/
│   │       └── agent_repository.dart
│   ├── domain/
│   │   └── providers/
│   │       └── agent_provider.dart
│   └── presentation/
│       ├── screens/
│       │   ├── agent_registry_screen.dart
│       │   ├── agent_config_screen.dart
│       │   └── add_agent_screen.dart
│       └── widgets/
│           ├── agent_card.dart
│           └── agent_switcher_sheet.dart
│
├── settings/                      # App settings
│   └── presentation/
│       ├── screens/
│       │   ├── settings_screen.dart
│       │   ├── account_screen.dart
│       │   ├── notification_prefs_screen.dart
│       │   ├── bridge_settings_screen.dart
│       │   └── offline_storage_screen.dart
│       └── widgets/
│           └── settings_tile.dart
│
└── bridge/                        # Bridge pairing & connection
    ├── data/
    │   └── repositories/
    │       └── bridge_repository.dart
    └── presentation/
        ├── screens/
        │   └── qr_pairing_screen.dart
        └── widgets/
            └── connection_status_bar.dart
```

### `shared/` — Shared UI Components

```
shared/
├── widgets/
│   ├── adaptive_layout.dart       # Responsive phone/tablet wrapper
│   ├── loading_indicator.dart
│   ├── error_banner.dart
│   ├── offline_banner.dart
│   ├── empty_state.dart
│   └── confirm_dialog.dart
├── extensions/
│   ├── context_extensions.dart    # Theme, media query shortcuts
│   └── string_extensions.dart
└── constants/
    ├── app_sizes.dart             # Spacing, padding, breakpoints
    └── app_colors.dart            # Color tokens
```

---

## Test Structure

Mirrors the `lib/` structure:

```
test/
├── core/
│   ├── network/
│   │   └── websocket_service_test.dart
│   ├── auth/
│   │   └── auth_provider_test.dart
│   ├── storage/
│   │   └── database_test.dart
│   └── sync/
│       └── sync_service_test.dart
├── features/
│   ├── chat/
│   │   ├── data/chat_repository_test.dart
│   │   ├── domain/chat_provider_test.dart
│   │   └── presentation/chat_screen_test.dart
│   ├── files/
│   │   └── ...
│   ├── git/
│   │   └── ...
│   └── ...
├── shared/
│   └── widgets/
│       └── adaptive_layout_test.dart
├── goldens/                       # Golden test baselines
│   └── ...
└── helpers/
    ├── test_bridge_server.dart    # Local WS server for integration tests
    ├── mock_providers.dart        # Shared Riverpod overrides
    └── fixtures/                  # JSON fixtures for mock responses
        ├── session_ready.json
        ├── stream_chunk.json
        └── tool_call.json

integration_test/
├── auth_flow_test.dart
├── chat_flow_test.dart
├── git_operations_test.dart
└── approval_flow_test.dart
```

---

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Files | `snake_case.dart` | `chat_screen.dart` |
| Classes | `PascalCase` | `ChatScreen` |
| Providers | `camelCaseProvider` | `chatProvider` |
| Tests | `<file>_test.dart` | `chat_screen_test.dart` |
| Feature dirs | `snake_case` | `features/chat/` |
| Constants | `camelCase` | `defaultPadding` |
