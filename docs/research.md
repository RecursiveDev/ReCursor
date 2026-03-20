# Building a mobile AI coding agent: the open-source landscape in 2026

**The ecosystem around Claude Code and similar AI coding agents has exploded**, with over 300K-star projects, dozens of CLI alternatives, and the first purpose-built Flutter mobile clients emerging in early 2026. For anyone building a mobile-first AI coding agent controller in Flutter, the key building blocks already exist: CC Pocket provides a working Flutter-to-Claude-Code bridge via WebSockets, GSYGithubAppFlutter offers a **15.4K-star** GitHub client reference, and Conduit demonstrates production-grade WebSocket streaming for AI chat. Below is a comprehensive catalog of the most relevant repositories across five categories.

---

## Claude Code wrappers and reimplementations are a massive ecosystem

The Claude Code open-source ecosystem has grown into one of the most active spaces on GitHub, anchored by two flagship projects and surrounded by dozens of specialized tools.

**OpenClaw** ([openclaw/openclaw](https://github.com/openclaw/openclaw)) is the headline project — a self-hosted autonomous AI agent platform that uses Claude Code under the hood. At roughly **315K stars**, it became the fastest-growing GitHub repo ever in early 2026. Created by Peter Steinberger, it connects to 10+ messaging platforms (WhatsApp, Telegram, Slack, Discord, Signal, iMessage) with persistent memory and scheduled jobs. The entire "claw" ecosystem includes Claw Hub (a skill directory with 5,700+ community-built skills), plus lightweight alternatives like **NanoClaw** (container-isolated, by Qwibit AI), **BabyClaw** (single-file agent controlled via Telegram), and **PocoClaw** (polished web UI variant with sandboxed runtime).

**OpenCode** ([opencode-ai/opencode](https://github.com/opencode-ai/opencode)) is the most direct open-source Claude Code alternative — a terminal-native AI coding agent written in Go with **~112–122K stars**. Built by the SST team, it supports 75+ LLM providers, includes LSP integration for type-aware code intelligence, and offers multi-session parallel agent execution. Anthropic briefly blocked OpenCode from Claude API access in early 2026, underscoring its competitive significance.

Other notable Claude Code clones and wrappers include:

- **OpenCoder** ([ducan-ne/opencoder](https://github.com/ducan-ne/opencoder)) — A drop-in Claude Code replacement built on the Vercel AI SDK with 60fps React-compiled TUI, supporting any LLM provider and MCP integration
- **learn-claude-code** ([shareAI-lab/learn-claude-code](https://github.com/shareAI-lab/learn-claude-code)) — **~27.8K stars**, a "nano Claude Code" educational reimplementation in Python across 12 progressive sessions covering the agent loop, tool use, subagents, and context compaction
- **everything-claude-code** ([affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)) — **~50–61K stars**, the dominant skills/plugins system for Claude Code featuring 9 agents, 11 skills, 11 commands, and the AgentShield security scanner (Anthropic hackathon winner)
- **claude-code-mcp** ([steipete/claude-code-mcp](https://github.com/steipete/claude-code-mcp)) — ~600–1.2K stars, an MCP server that wraps Claude Code in one-shot mode, enabling "agent-in-agent" patterns where Cursor or Windsurf delegates tasks to Claude Code
- **claude-wrapper** ([ChrisColeTech/claude-wrapper](https://github.com/ChrisColeTech/claude-wrapper)) — Transforms Claude Code CLI into an OpenAI-compatible HTTP API server with streaming
- **Claw** ([jamesrochabrun/Claw](https://github.com/jamesrochabrun/Claw)) — Native macOS wrapper around Claude Code SDK in Swift
- **klaus** ([giantswarm/klaus](https://github.com/giantswarm/klaus)) — Enterprise Go wrapper orchestrating Claude Code agents in Kubernetes via Helm/CRDs

A thriving proxy ecosystem also exists for running Claude Code's CLI with non-Anthropic models. Projects like **claude-code-proxy** ([1rgs/claude-code-proxy](https://github.com/1rgs/claude-code-proxy)) and **9router** ([decolua/9router](https://github.com/decolua/9router)) connect Claude Code to 40+ providers and 100+ models. The curated list **awesome-claude-code** ([hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)) at **~28.4K stars** is the definitive community index.

---

## The CLI coding agent landscape has consolidated around seven major tools

The agentic coding CLI space, once fragmented across dozens of projects, has consolidated by March 2026. Several early entrants (GPT-Engineer, Smol Developer, Plandex, Mentat) have either pivoted, wound down, or stagnated. The actively maintained leaders are:

| Tool | Stars | LLM Support | Key Differentiator |
|------|-------|------------|-------------------|
| **OpenCode** ([opencode-ai/opencode](https://github.com/opencode-ai/opencode)) | ~122K | 75+ providers | LSP integration, multi-session, privacy-first |
| **Gemini CLI** ([google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)) | ~98K | Gemini only | Free tier (1000 req/day), Google Search grounding |
| **OpenHands** ([All-Hands-AI/OpenHands](https://github.com/All-Hands-AI/OpenHands)) | ~69K | 100+ via LiteLLM | Docker sandbox, browser automation, full SDK |
| **Codex CLI** ([openai/codex](https://github.com/openai/codex)) | ~65K | OpenAI only | Rust rewrite, cloud sandboxed execution |
| **Cline** ([cline/cline](https://github.com/cline/cline)) | ~59K | All major | Human-in-the-loop approvals, 5M+ installs |
| **Aider** ([Aider-AI/aider](https://github.com/Aider-AI/aider)) | ~42K | 100+ models | Git-native (auto-commits), 4.1M installs |
| **Goose** ([block/goose](https://github.com/block/goose)) | ~33K | 25+ providers | MCP extensibility, CLI pass-through, Linux Foundation |

**Aider** remains the gold standard for terminal-first developers who want every AI edit as a git commit. **OpenHands** (formerly OpenDevin) is the most full-featured platform, offering CLI, web GUI, SDK, and cloud deployment with Docker sandboxing — backed by an $18.8M Series A. **Goose** from Block stands out for its unique provider pass-through system, letting users route through existing Claude Code, Codex, or Gemini CLI subscriptions.

The key architectural divide is **model flexibility versus lock-in**. OpenCode, Aider, and Goose support any LLM. Codex CLI is locked to OpenAI. Gemini CLI is locked to Google. Claude Code is locked to Anthropic. For a mobile controller app, targeting multi-model tools like OpenCode, Aider, or Goose maximizes the addressable user base.

Other noteworthy projects include **Continue** ([continuedev/continue](https://github.com/continuedev/continue), ~32K stars) for privacy-first CI-enforceable AI coding, **SWE-agent** ([princeton-nlp/SWE-agent](https://github.com/princeton-nlp/SWE-agent), ~15–18K stars) for research-grade autonomous issue resolution, and **Open Interpreter** (~63K stars) as a general-purpose terminal agent.

---

## The first Flutter mobile clients for AI coding agents have arrived

The mobile-first AI coding agent space is nascent but rapidly materializing, with **CC Pocket** as the clear standout.

**CC Pocket** ([K9i-0/ccpocket](https://github.com/K9i-0/ccpocket)) is the most mature Flutter mobile client purpose-built for controlling Claude Code and Codex from a phone. At ~149 stars and **updated as of March 16, 2026**, it uses a TypeScript WebSocket bridge server (`packages/bridge/`) paired with a Flutter mobile app (`apps/mobile/`). Key features include starting/resuming agent sessions, approving tool calls, reviewing diffs remotely, git worktree support for parallel sessions, and QR code pairing via Tailscale/SSH. **This is the single most relevant architectural reference** for building a mobile AI coding agent controller in Flutter.

Other mobile clients include **claude-code-app** ([9cat/claude-code-app](https://github.com/9cat/claude-code-app), ~42 stars) which connects Flutter to Claude Code containers via SSH with voice input and auto-commit, and **Happy/Happier** ([slopus/happy](https://github.com/slopus/happy)) which provides E2E encrypted multi-agent mobile control supporting Codex, Claude Code, OpenCode, and more with push notifications when agents need input.

For Flutter LLM chat clients more broadly, the leaders are **Maid** ([Mobile-Artificial-Intelligence/maid](https://github.com/Mobile-Artificial-Intelligence/maid), ~1K+ stars) for local llama.cpp inference plus remote providers, and **AIdea** ([mylxsw/aidea](https://github.com/mylxsw/aidea)) for a mature Flutter + Go backend supporting multiple LLMs and Stable Diffusion. The official **Flutter AI Toolkit** ([flutter/ai](https://github.com/flutter/ai)) provides canonical `LlmProvider` abstractions with `generateStream()` and `sendMessageStream()` returning Dart streams, while **LangChain.dart** ([davidmigloz/langchain_dart](https://github.com/davidmigloz/langchain_dart)) ports the full LangChain framework to Dart with support for OpenAI, Gemini, Anthropic, and Ollama.

The emerging architectural pattern across all mobile coding agent clients is a **WebSocket bridge**: the phone connects via WebSocket to a bridge server running alongside the coding agent on the development machine, with Tailscale or SSH tunneling for remote access.

---

## Flutter GitHub client apps provide battle-tested architectural patterns

> **Note:** This section documents GitHub OAuth patterns as prior research for mobile GitHub client architecture. ReCursor's current direction is **bridge-first with no user authentication** — repository operations are delegated to the agent running on the development machine. Git operations via bridge commands, not native mobile OAuth.

For GitHub OAuth, repository browsing, and git operations on mobile, three codebases stand out as architectural references.

**GSYGithubAppFlutter** ([CarGuo/gsy_github_app_flutter](https://github.com/CarGuo/gsy_github_app_flutter)) at **15.4K stars** is the definitive Flutter GitHub client. Updated through February 2026, it uniquely demonstrates Redux, Provider, Riverpod, and Signals state management in the same project. Its four-layer architecture (UI → State → Service → Data) with repository pattern, event bus, and SQL caching provides a complete blueprint. Features include full GitHub OAuth (using custom URL scheme `gsygithubapp://authed`), repo/issue/PR browsing, trending repos, search, markdown rendering, and i18n. **Apache 2.0 licensed** with 2.6K forks.

**FlutterHub** ([khoren93/FlutterHub](https://github.com/khoren93/FlutterHub)) is the best **clean architecture with BLoC** example for GitHub clients. It implements dependency injection via GetIt, REST v3 via Chopper, GraphQL v4 via graphql_flutter, and immutable models via Freezed. Supports Basic Auth, Personal Access Token, and OAuth2 authentication — making it ideal for understanding multiple auth strategies.

**git-touch** ([pd4d10/git-touch](https://github.com/pd4d10/git-touch), **~1.7K stars**) is the best reference for multi-platform Git hosting abstraction, supporting GitHub, GitLab, Bitbucket, Gitea, and Gitee. It uses both REST v3 and GraphQL v4 APIs. Published on App Store, Google Play, and F-Droid, though its last release was mid-2024.

For **native git operations on mobile**, two libraries are essential. **git2dart** ([SkinnyMind/libgit2dart](https://github.com/SkinnyMind/libgit2dart)) provides full libgit2 bindings for Dart with Android arm64 support — clone, commit, push, pull, merge, diff, and worktree operations. **git_on_dart** is a pure Dart alternative optimized for Flutter mobile with SSH support via dartssh2. For GitHub OAuth specifically, the **github_oauth** package on pub.dev offers a drop-in solution handling the entire OAuth2 flow with WebView integration.

---

## WebSocket streaming for AI chat in Flutter has production-ready examples

Most Flutter AI chat apps use HTTP streaming rather than WebSockets, because OpenAI-compatible APIs use SSE/chunked transfer encoding. However, several production-quality WebSocket implementations exist.

**Conduit** ([cogwheel0/conduit](https://github.com/cogwheel0/conduit)) at **~1.1K stars** is the strongest WebSocket-based Flutter AI chat app. It's a native mobile client for Open-WebUI that uses **Socket.IO WebSockets** on `/ws/socket.io` for real-time streaming. Built with **Riverpod** state management and a clean feature-based architecture (`lib/core/`, `lib/features/auth/`, `lib/features/chat/`), it supports model selection, conversation management, markdown rendering, and SSO/OAuth. Very actively maintained with **1,022 commits**.

**LLMChat** ([c0sogi/LLMChat](https://github.com/c0sogi/LLMChat), 288 stars) is the best full-stack WebSocket + LLM reference. Its FastAPI backend exposes WebSocket endpoints at `/ws/chat/{api_key}`, with a `ChatStreamManager` handling LLM-to-client streaming. Includes Redis vector store for RAG and auto-summarization.

**Kelivo** ([Chevey339/kelivo](https://github.com/Chevey339/kelivo), **~1.7K stars**) is the most polished overall Flutter LLM chat client, supporting OpenAI, Gemini, Anthropic, and many other providers. It uses HTTP streaming rather than WebSockets but features MCP support, web search integration, multimodal input (images, PDFs), voice/TTS, and Material You theming. Updated February 2026. **AGPL-3.0 licensed**.

For architecture patterns specifically, **ai_fireside_chat** ([DenisovAV/ai_fireside_chat](https://github.com/DenisovAV/ai_fireside_chat)) provides the cleanest multi-provider abstraction — an abstract `ChatService` with concrete implementations per provider, all returning Dart streams via `processMessageStream()`, using BLoC state management. The official **Flutter AI Toolkit** establishes the canonical `LlmProvider` interface pattern with `generateStream()` returning `Stream<String>`. The **flutter_gen_ai_chat_ui** package ([hooshyar/flutter_gen_ai_chat_ui](https://github.com/hooshyar/flutter_gen_ai_chat_ui)) deserves mention as a framework-agnostic UI component library with streaming text animations (word-by-word rendering like ChatGPT/Claude), markdown support, and an AI Actions System for tool use.

---

## Claude Code Integration Constraints

> **Important Finding**: Claude Code Remote Control is **first-party only**. There is no public API for third-party clients to join or mirror existing Claude Code sessions.

**Supported Integration Paths for ReCursor:**

| Integration | Status | Use Case |
|-------------|--------|----------|
| Claude Code Hooks | ✅ Supported | Event observation (one-way) |
| Agent SDK | ✅ Supported | Parallel agent sessions |
| MCP (Model Context Protocol) | ✅ Supported | Tool interoperability |
| Remote Control Protocol | ❌ Not Available | First-party only |

**ReCursor Architecture:**
- **Event Source**: Claude Code Hooks POST events to bridge
- **Session Control**: Agent SDK for parallel sessions
- **UI Pattern**: OpenCode-style tool cards, diff viewer, timeline

---

## Conclusion: a reference architecture emerges

The research reveals a clear reference architecture for a mobile-first AI coding agent controller built in Flutter. **CC Pocket's WebSocket bridge pattern** — a TypeScript server running alongside the coding agent, connected to a Flutter mobile client via WebSocket with Tailscale tunneling — is the proven approach. For GitHub integration, **GSYGithubAppFlutter's four-layer architecture** with the **github_oauth** package provides the OAuth and API blueprint. For AI chat streaming, **Conduit's Riverpod + Socket.IO implementation** offers the most production-ready WebSocket pattern, while the **Flutter AI Toolkit's `LlmProvider` interface** provides the canonical abstraction layer.

The most impactful architectural decision is which coding agents to target. **OpenCode** (75+ providers, 122K stars) and **Aider** (git-native, 42K stars) have the largest user bases among model-flexible tools, while Claude Code and Codex CLI dominate among vendor-locked options. Goose's CLI pass-through system — letting users route through any existing agent subscription — offers a compelling aggregation model. Building on the WebSocket bridge pattern with multi-agent support (as Happy/Happier attempts) would address the broadest market.

For ReCursor specifically, the architecture combines:
1. **OpenCode UI patterns** for the mobile interface
2. **Claude Code Hooks** for event observation
3. **Agent SDK** for parallel sessions
4. **CC Pocket's bridge pattern** for connectivity

---

*Last updated: 2026-03-17*
