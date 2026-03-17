<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="apps/mobile/assets/branding/ReCursor_Darklogo.png">
    <img src="apps/mobile/assets/branding/ReCursor_Lightlogo.png" alt="ReCursor Logo" width="140" height="140">
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
  <a href="docs/README.md">
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

This repository is **work in progress**.

- ✅ Repo structure + documentation are being established.
- ⏳ Flutter app and bridge server implementation are not yet shipped.

If you're new here, start with: **`docs/README.md`**.

---

## What is ReCursor?

**ReCursor** is a Flutter mobile app designed to provide an **OpenCode-like UI/UX on mobile** (tool cards, diffs, session timeline), while integrating with a developer's desktop/local environment.

### Core product intent

- **UI/UX parity goal:** ReCursor's mobile UI should *feel like OpenCode desktop*, adapted for touch and smaller screens.
- **Claude Code integration goal:** Observe and complement a user's Claude Code workflow from mobile.

### Important constraint (Claude Code)

Claude Code's **Remote Control** feature is **first-party** (designed for `claude.ai/code` and official Claude apps). ReCursor docs are written to avoid claiming access to any private/undocumented Remote Control protocol.

ReCursor's supported approach is:
- **Claude Code Hooks**: event observation (one-way)
- **Claude Agent SDK**: a **parallel, controllable** agent session that ReCursor can drive (approvals/tool execution live here)

---

## Repository layout (scaffold)

```text
C:/Repository/ReCursor/
├── apps/
│   └── mobile/              # Flutter app scaffold (no UI implementation yet)
├── packages/
│   └── bridge/              # Node/TypeScript bridge scaffold (no server logic yet)
├── docs/                    # Source-of-truth project documentation
├── .github/                 # CI/CD scaffolding
└── fastlane/                # Release automation scaffolding
```

---

## Documentation

- **Docs index:** `docs/README.md`
- **Architecture overview:** `docs/architecture/overview.md`
- **Data flow diagrams:** `docs/architecture/data-flow.md`
- **Integrations:**
  - OpenCode UI patterns: `docs/integration/opencode-ui-patterns.md`
  - Claude Code Hooks: `docs/integration/claude-code-hooks.md`
  - Agent SDK: `docs/integration/agent-sdk.md`

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
