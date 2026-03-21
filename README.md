<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="apps/mobile/assets/branding/recursor_logo_dark.svg">
    <img src="apps/mobile/assets/branding/recursor_logo_light.svg" alt="ReCursor Logo" width="140" height="140">
  </picture>
</p>

<h1 align="center">ReCursor</h1>

<p align="center">
  <strong>Mobile-first companion UI for AI coding workflows</strong>
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  </a>
  <a href="https://nodejs.org/">
    <img src="https://img.shields.io/badge/Node.js-20%2B-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js">
  </a>
  <a href="https://www.typescriptlang.org/">
    <img src="https://img.shields.io/badge/TypeScript-5.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/RecursiveDev/ReCursor?style=for-the-badge" alt="License">
  </a>
</p>

<p align="center">
  <a href="#project-status">
    <img src="https://img.shields.io/badge/Status-WIP-orange?style=flat-square" alt="Status: WIP">
  </a>
  <a href="docs-site/src/content/docs/index.mdx">
    <img src="https://img.shields.io/badge/Docs-Start%20Here-blue?style=flat-square" alt="Docs">
  </a>
  <a href="https://github.com/RecursiveDev/ReCursor/issues">
    <img src="https://img.shields.io/github/issues/RecursiveDev/ReCursor?style=flat-square" alt="Issues">
  </a>
  <a href="https://github.com/RecursiveDev/ReCursor/pulls">
    <img src="https://img.shields.io/github/issues-pr/RecursiveDev/ReCursor?style=flat-square" alt="Pull Requests">
  </a>
  <a href="https://github.com/RecursiveDev/ReCursor/commits/main">
    <img src="https://img.shields.io/github/last-commit/RecursiveDev/ReCursor?style=flat-square" alt="Last Commit">
  </a>
</p>

<p align="center">
  UI parity with <a href="https://github.com/opencode-ai/opencode">OpenCode</a> • Observability via Claude Code Hooks • Control via Claude Agent SDK
</p>

---

## Project status

This repository is **work in progress**, but the current Claude-first MVP is no longer just scaffolding.

- ✅ Bridge-first pairing, health verification, and connection mode handling are implemented.
- ✅ Claude Hooks observation, Agent SDK session flows, streaming chat, tool cards, and timeline persistence are implemented.
- ✅ Git status, diff viewing, and repository browsing are implemented for the current mobile/bridge stack.
- ⏳ Remaining work is focused on polish: approval UX refinement, notification center UI, and future multi-agent expansion.

If you're new here, start with: **`docs-site/src/content/docs/`** (browse the docs-site content or run `npm run dev` in `docs-site/` to view locally).

---

## What is ReCursor?

**ReCursor** is a Flutter mobile app designed to provide an **OpenCode-like UI/UX on mobile** (tool cards, diffs, session timeline), while integrating with a developer's desktop/local environment.

> **Long-term vision:** ReCursor is **coding-agent agnostic** — designed to support multiple AI coding tools. **Claude Code is the first supported integration**, with future support planned for OpenCode, Gemini CLI, Codex CLI, GitHub CLI, and others.

### Core product intent

- **UI/UX parity goal:** ReCursor's mobile UI should *feel like OpenCode desktop*, adapted for touch and smaller screens.
- **Integration goal:** Observe and complement a user's AI coding workflow from mobile. Currently supports **Claude Code** with additional agents planned.

### Current Integration: Claude Code

ReCursor currently integrates with **Claude Code**, Anthropic's AI coding assistant. Future releases will add support for additional coding agents (OpenCode, Gemini CLI, Codex CLI, GitHub CLI, etc.).

#### Important constraint (Claude Code)

Claude Code's **Remote Control** feature is **first-party only** (designed for `claude.ai/code` and official Claude apps). There is no public API for third-party clients to join or mirror existing Claude Code sessions.

ReCursor's supported Claude Code integration paths (current implementation):
- **Claude Code Hooks**: HTTP-based event observation (one-way)
- **Claude Agent SDK**: **parallel, controllable** agent sessions that ReCursor can drive

### Bridge-first, no-login workflow

ReCursor uses a **bridge-first** connection model:
- The mobile app connects directly to a **user-controlled desktop bridge** (no hosted service, no user accounts)
- On startup, the app restores saved bridge pairings or guides through QR-code pairing
- Remote access is achieved via secure tunnels (Tailscale, WireGuard) to the user's own bridge — not through unsupported third-party Claude Remote Control access

---

## Repository layout

```text
C:/Repository/ReCursor/
├── apps/
│   └── mobile/              # Flutter mobile client (startup, chat, timeline, repos, git, diff)
├── packages/
│   └── bridge/              # Node/TypeScript desktop bridge (WebSocket, hooks, CLI, file/git services)
├── docs/                    # Source-of-truth project documentation
├── .github/                 # CI/CD scaffolding
└── fastlane/                # Release automation scaffolding
```

---

## Documentation

- **Published docs site:** `docs-site/` — run `npm install && npm run dev` to view locally
- **Docs landing page:** [docs-site/src/content/docs/index.mdx](docs-site/src/content/docs/index.mdx)
- **Architecture:**
  - System overview: [docs-site/src/content/docs/architecture/system-overview.md](docs-site/src/content/docs/architecture/system-overview.md)
  - Data flow: [docs-site/src/content/docs/architecture/data-flow.md](docs-site/src/content/docs/architecture/data-flow.md)
  - Bridge protocol: [docs-site/src/content/docs/architecture/bridge-protocol.md](docs-site/src/content/docs/architecture/bridge-protocol.md)
- **Integrations:**
  - OpenCode UI patterns: [docs-site/src/content/docs/integrations/opencode-ui-patterns.md](docs-site/src/content/docs/integrations/opencode-ui-patterns.md)
  - Claude Code Hooks: [docs-site/src/content/docs/integrations/claude-code-hooks.md](docs-site/src/content/docs/integrations/claude-code-hooks.md)
  - Agent SDK: [docs-site/src/content/docs/integrations/agent-sdk.md](docs-site/src/content/docs/integrations/agent-sdk.md)

---

## Contributing

See:
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`

If you're using agentic AI to contribute, read **`AGENTS.md`** first.

---

## License

MIT — see `LICENSE`.
