# AGENTS.md

Guidance for **agentic AI** (and humans using AI assistants) contributing to **ReCursor**.

> Scope note: This repository is currently in an early phase. Prefer **documentation-first** changes until the Flutter app and bridge server implementation are explicitly requested.

---

## 1) What this repo is

ReCursor is intended to become a **Flutter mobile companion UI** for AI coding workflows.

Primary goals:
- **Mobile UI/UX parity with OpenCode desktop** (tool cards, diffs, timeline patterns).
- Integrate with a developer's desktop/local environment.

Key constraint:
- **Claude Code Remote Control is first‑party** (claude.ai/code + official apps). Do **not** claim we can join/mirror a user's Claude Code Remote Control session via a public protocol unless official docs explicitly provide it.

Supported Claude Code integration mechanisms documented in this repo:
- **Hooks** (Claude Code plugin hooks) for **one-way event observation**.
- **Claude Agent SDK** for a **parallel, controllable** session.

---

## 2) Source of truth (do not guess)

When updating docs or implementing features, verify claims using these sources.

> Note: Some references below include example local paths from one development machine. If you do not have these repos checked out locally, use the upstream GitHub repositories and adjust paths accordingly.

- **ReCursor docs (the contract):**
  - `C:/Repository/ReCursor/docs/README.md`
  - `C:/Repository/ReCursor/docs/architecture/overview.md`
  - `C:/Repository/ReCursor/docs/integration/`

- **OpenCode UI patterns (desktop parity reference):**
  - Upstream repo: https://github.com/anomalyco/opencode
  - Local repo (optional): `C:/Repository/opencode/`
  - Especially: `C:/Repository/opencode/packages/ui/src/components/`

- **Claude Code supported extension points:**
  - Upstream repo: https://github.com/anthropics/claude-code
  - Local repo (optional): `C:/Repository/claude-code/`
  - Especially: `C:/Repository/claude-code/plugins/plugin-dev/skills/hook-development/`

- **Official docs:**
  - Claude Code docs: https://code.claude.com/docs/
  - Agent SDK docs: https://docs.claude.com/en/api/agent-sdk/overview

If something is not in the above sources, treat it as **unknown** and document it as an **open question**.

---

## 3) Repo layout (scaffold)

```text
C:/Repository/ReCursor/
├── apps/mobile/            # Flutter app scaffold (no implementation yet)
├── packages/bridge/        # Node/TypeScript bridge scaffold (no implementation yet)
├── docs/                   # Project documentation (source-of-truth)
├── .github/                # CI scaffolding
└── fastlane/               # Release scaffolding
```

---

## 4) Contribution rules for AI agents

### 4.1 Do / Don't

**Do:**
- Read the relevant docs before making changes.
- Keep edits strictly within the requested scope.
- Prefer small, reviewable commits/changesets.
- When changing docs, keep them **internally consistent** (cross-links, terminology).
- When making factual claims about OpenCode/Claude Code behavior, include a citation (path + short excerpt) in your PR description.

**Don't:**
- Do not introduce claims like "ReCursor mirrors Claude Code Remote Control sessions" unless official docs explicitly support third‑party clients.
- Do not invent hook config keys (e.g. `hooks.http.*`). Claude Code hooks are configured via `hooks.json` with `type: "command"` / `type: "prompt"` handlers.
- Do not implement new features/tests/linting configs unless asked.

### 4.2 Documentation integrity checks

Before marking docs work complete:
- Ensure internal links resolve.
- Search for outdated branding/terms that should not exist.
- For Claude Code hooks docs, ensure you are aligned with:
  - `C:/Repository/claude-code/plugins/plugin-dev/skills/hook-development/SKILL.md`
  - `C:/Repository/claude-code/plugins/hookify/hooks/hooks.json`

### 4.3 Commit message guidelines

**Do not mention agentic authors or subauthors in commit messages.**

- No references to "Claude Code", "Cursor", "Copilot", or other coding agents in commit messages.
- No co-authored-by lines referencing AI assistants.
- Commit messages should reflect the human author's intent and rationale.
- Examples of forbidden patterns:
  - `Co-authored-by: Claude <noreply@anthropic.com>`
  - `Generated with Claude Code`
  - `Written by Cursor AI`
- Focus on **what changed** and **why**, not **who/what wrote it**.

---

## 5) Preferred workflow for future implementation

When implementation is requested:
1. **Confirm scope**: which subproject(s) are being built (Flutter app, bridge, both).
2. **Follow docs**: treat `docs/` as the contract; if docs are wrong, fix docs first.
3. **Implement minimal vertical slices**: scaffold → connect → render a small set of UI components.
4. **Verify** with build/lint/test commands appropriate to the stack.

---

## 6) Quick links for agents

- Docs index: `C:/Repository/ReCursor/docs/README.md`
- Plan: `C:/Repository/ReCursor/docs/PLAN.md`
- OpenCode UI mapping: `C:/Repository/ReCursor/docs/integration/opencode-ui-patterns.md`
- Claude Code hooks: `C:/Repository/ReCursor/docs/integration/claude-code-hooks.md`
- Agent SDK: `C:/Repository/ReCursor/docs/integration/agent-sdk.md`
- OpenCode upstream: https://github.com/anomalyco/opencode
- Claude Code upstream: https://github.com/anthropics/claude-code
