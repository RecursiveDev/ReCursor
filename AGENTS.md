# AGENTS.md

Guidance for **agentic AI** (and humans using AI assistants) contributing to **ReCursor**.

> Scope note: This repository is currently in an early phase. Prefer **documentation-first** changes until the Flutter app and bridge server implementation are explicitly requested.

---

## 1) What this repo is

ReCursor is intended to become a **Flutter mobile companion UI** for AI coding workflows.

> **Product vision:** ReCursor is **coding-agent agnostic** — designed to support multiple AI coding tools. **Claude Code is the first supported integration**, with future support planned for OpenCode, Gemini CLI, Codex CLI, GitHub CLI, and others.

Primary goals:
- **Mobile UI/UX parity with OpenCode desktop** (tool cards, diffs, timeline patterns).
- Integrate with a developer's desktop/local environment.
- **Architecture:** Build an integration layer (not agent-specific coupling) to support future agent adapters.

### Current integration scope

ReCursor currently integrates with **Claude Code**. Future releases will expand to additional coding agents.

Key constraint (Claude Code):
- **Claude Code Remote Control is first‑party** (claude.ai/code + official apps). Do **not** claim we can join/mirror a user's Claude Code Remote Control session via a public protocol unless official docs explicitly provide it.

Supported Claude Code integration mechanisms documented in this repo:
- **Hooks** (Claude Code plugin hooks) for **one-way event observation**.
- **Claude Agent SDK** for a **parallel, controllable** session.

---

## 2) Source of truth (do not guess)

When updating docs or implementing features, verify claims using these sources.

- **ReCursor docs (the contract):**
  - `docs-site/src/content/docs/` (canonical documentation source)
  - `docs-site/src/content/docs/architecture/system-overview.md`
  - `docs-site/src/content/docs/integrations/`

- **OpenCode UI patterns (desktop parity reference):**
  - Upstream repo: https://github.com/opencode-ai/opencode
  - Key path: `packages/ui/src/components/`

- **Claude Code supported extension points:**
  - Upstream repo: https://github.com/anthropics/claude-code
  - Key paths:
    - `plugins/plugin-dev/skills/hook-development/SKILL.md`
    - `plugins/hookify/hooks/hooks.json`

- **Official docs:**
  - Claude Code docs: https://docs.anthropic.com/en/docs/claude-code
  - Agent SDK docs: https://docs.anthropic.com/en/api/agent-sdk

If something is not in the above sources, treat it as **unknown** and document it as an **open question**.

---

## 3) Repo layout (scaffold)

```text
ReCursor/
├── apps/mobile/              # Flutter app scaffold
├── packages/bridge/          # Node/TypeScript bridge scaffold
├── packages/claude-plugin/   # Claude Code plugin scaffold
├── docs-site/                # Astro Starlight documentation site
│   └── src/content/docs/     # Canonical documentation source
├── .github/                  # CI scaffolding
└── fastlane/                 # Release scaffolding
```

---

## 4) Contribution rules for AI agents

### 4.1 Do / Don't

**Do:**
- Read the relevant docs before making changes.
- Keep edits strictly within the requested scope.
- Prefer small, reviewable commits/changesets.
- When changing docs, keep them **internally consistent** (cross-links, terminology).
- When making factual claims about OpenCode/Claude Code behavior, include a citation (URL + short excerpt) in your PR description.

**Don't:**
- Do not introduce claims like "ReCursor mirrors Claude Code Remote Control sessions" unless official docs explicitly support third‑party clients.
- Do not invent hook config keys (e.g. `hooks.http.*`). Claude Code hooks are configured via `hooks.json` with `type: "command"` / `type: "prompt"` handlers.
- Do not implement new features/tests/linting configs unless asked.

### 4.2 Documentation integrity checks

Before marking docs work complete:
- Ensure internal links resolve.
- Search for outdated branding/terms that should not exist.
- For Claude Code hooks docs, ensure you are aligned with the upstream repo:
  - `plugins/plugin-dev/skills/hook-development/SKILL.md`
  - `plugins/hookify/hooks/hooks.json`

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

### 4.4 Architecture for multi-agent support

When implementing features, preserve an **integration-friendly architecture** that avoids hard-coding Claude-specific assumptions:

**Do:**
- Use abstract interfaces/types for agent adapters (e.g., `AgentAdapter`, `AgentSession`, `AgentEvent`)
- Keep agent-specific logic in dedicated modules (e.g., `integrations/claude/`, `integrations/opencode/`)
- Design message types that can map to multiple agent protocols
- Document which parts are Claude-specific vs. agent-agnostic

**Don't:**
- Hard-code Claude-specific event types or tool names in core UI components
- Assume all agents have the same capabilities as Claude Code
- Couple bridge protocol tightly to Claude Code hooks format
- Use Claude-specific terminology where generic terms would suffice (e.g., "agent" instead of "Claude", "tool call" instead of "tool_use")

Future agent integrations will follow the adapter pattern established by the Claude Code integration.

---

## 5) Preferred workflow for future implementation

When implementation is requested:

1. **Confirm scope**: which subproject(s) are being built (Flutter app, bridge, both).
2. **Follow docs**: treat `docs-site/src/content/docs/` as the contract; if docs are wrong, fix docs first.
3. **Work efficiently in parallel**:
   - Identify independent tasks that can be executed concurrently (file reads, searches, analysis)
   - Batch related operations to minimize context switches
   - Use parallel tool invocations where dependencies allow
   - Prefer complete, working solutions over piecemeal slices
4. **Verify** with build/lint/test commands appropriate to the stack.

---

## 6) Quick links for agents

- **Docs index:** `docs-site/src/content/docs/index.mdx`
- **Architecture:** `docs-site/src/content/docs/architecture/system-overview.md`
- **Integrations:** `docs-site/src/content/docs/integrations/`
- **OpenCode upstream:** https://github.com/opencode-ai/opencode
- **Claude Code upstream:** https://github.com/anthropics/claude-code