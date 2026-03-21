# Claude-First MVP Status and Remaining Scope

> **Status:** UPDATED
> **Date:** 2026-03-21
> **Parent:** `docs/architecture/overview.md`

---

## Current Implementation Snapshot

The current Claude-first MVP is now in a **coherent, test-backed state** across the mobile app and bridge.

### Implemented MVP slices ✅

| Slice | Status | Evidence |
|-------|--------|----------|
| Hook ingestion and bridge forwarding | Complete | `packages/bridge/src/hooks/receiver.ts`, `packages/bridge/src/hooks/protocol_mapper.ts` |
| Session lifecycle from hook + SDK events | Complete | `apps/mobile/lib/features/chat/domain/providers/session_provider.dart` |
| Streaming chat persistence | Complete | `apps/mobile/lib/features/chat/domain/providers/chat_provider.dart` |
| Tool cards and tool-result rendering | Complete | `apps/mobile/lib/features/chat/presentation/widgets/tool_card.dart` |
| Timeline with persisted hook events | Complete | `apps/mobile/lib/core/storage/daos/session_event_dao.dart`, `apps/mobile/lib/features/session/domain/providers/session_timeline_provider.dart` |
| Diff handoff and viewer | Complete | `apps/mobile/lib/features/diff/domain/providers/diff_provider.dart`, `apps/mobile/lib/features/diff/presentation/screens/diff_viewer_screen.dart` |
| Repository file tree + file viewer | Complete | `apps/mobile/lib/features/repos/presentation/screens/file_tree_screen.dart`, `apps/mobile/lib/features/repos/presentation/screens/file_viewer_screen.dart` |
| Git status screen with session context | Complete | `apps/mobile/lib/features/git/presentation/screens/git_screen.dart` |
| Bridge health verification and connection mode handling | Complete | `apps/mobile/lib/features/startup/`, `packages/bridge/src/websocket/message_handler.ts` |
| Notification routing and bridge replay acknowledgments | Complete | `apps/mobile/lib/core/notifications/notification_handler.dart`, `packages/bridge/src/hooks/event_queue.ts` |

---

## Reconciled status of previously listed phases

The earlier "remaining phases" list drifted behind the actual codebase. The current status is:

| Previous Phase | Previous Label | Actual Status | Notes |
|----------------|----------------|---------------|-------|
| Phase A: Hook Event Timeline Enrichment | Remaining | Complete | Hook events are persisted and merged into the timeline. |
| Phase B: Notification Handling | Remaining | Complete for MVP | Notification messages are routed in-app, surfaced locally, and acknowledged back to the bridge. |
| Phase C: Branch Information Population | Remaining | Complete for live session events | Session branch metadata is captured from `SessionStart` / `session_ready`. |
| Phase D: Approval Workflow UI | Remaining | Partial | Hook-sourced approvals are intentionally observational; Agent SDK approvals are actionable in state, but mobile UI polish remains limited. |
| Phase E: File Browser Implementation | Remaining | Complete | File tree and file viewer are implemented and wired to bridge file responses. |
| Phase F: Git Status & Diff Viewer Polish | Remaining | Complete for MVP | Git status and diff handoff are implemented. |

---

## What remains intentionally out of scope

These items are still valid follow-up work, but they are **not required to consider the current Claude-first MVP coherent**:

### 1. Approval interaction polish
- Richer approve / deny controls directly inside more chat surfaces
- Dedicated mobile-first approval queue UX improvements
- More detailed modification flows for Agent SDK approvals

### 2. Notification center UI
- Bell / inbox surface for browsing notification history
- Bulk read / archive flows
- Deep-link polish from notifications into chat, diff, or approvals

### 3. Broader multi-agent expansion
- Generalized adapter surfaces for additional agents
- OpenCode / Gemini CLI / Codex CLI integrations
- More agent-agnostic bridge capability negotiation

### 4. Additional production hardening
- Broader integration coverage beyond current widget / provider / bridge tests
- Release packaging and store-delivery polish
- Performance tuning for larger repositories and longer timelines

---

## Scope guardrails for future work

When continuing beyond this MVP state:

- Preserve the current constraint that **Claude Code Remote Control remains first-party only**.
- Keep Claude Hooks framed as **observation**, not third-party session mirroring.
- Keep Agent SDK sessions framed as **parallel, controllable sessions**, not mirrored Claude Code sessions.
- Continue preserving the agent-agnostic architecture in shared UI and bridge contracts.

---

## Recommended next work after this MVP

If another implementation pass is opened, prioritize in this order:

1. **Approval UI polish for Agent SDK flows**
2. **Notification center / inbox surface**
3. **Cross-agent adapter groundwork**
4. **Additional end-to-end integration tests**

---

*Last updated: 2026-03-21*
