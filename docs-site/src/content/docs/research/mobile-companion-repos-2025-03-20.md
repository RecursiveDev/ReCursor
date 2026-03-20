---
title: "Research Report: Mobile Companion Repositories for Coding Agents"
description: "Generated: 2025-03-20 | Researcher Agent"
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/research/mobile-companion-repos-2025-03-20.md"
sidebar:
  order: 70
---
> Generated: 2025-03-20 | Researcher Agent

## Executive Summary

This research identified 7 relevant repositories across four categories of mobile-companion-adjacent tooling for coding workflows: (1) **Remote IDE/Web-based** solutions, (2) **Native Mobile Terminals**, (3) **AI Coding Agent Platforms**, and (4) **Tunnel/Bridge Infrastructure**. The strongest architectural patterns for ReCursor emerge from **code-server** (browser-based VS Code bridge), **claude-code plugins/hooks** (event interception), **continue.dev** (React-based GUI), and **Blink/a-Shell** (iOS terminal patterns with sandboxed filesystem abstractions).

**Key insight:** No existing open-source project provides a direct "Claude Code remote via mobile" solution. All solutions require either: (a) exposing a local web IDE through a tunnel, (b) native SSH terminal apps with limitations, or (c) browser-based responsive UIs paired with remote servers.

## Repositories Analyzed

| Repo | Category | Stars* | Mobile Type | Relevance Score |
|------|----------|--------|-------------|-----------------|
| [code-server](https://github.com/coder/code-server) | Remote IDE | 69k+ | PWA/iPad via Safari | ⭐⭐⭐⭐⭐ |
| [continue.dev](https://github.com/continuedev/continue) | AI Agent IDE | 24k+ | React GUI (extensible) | ⭐⭐⭐⭐⭐ |
| [claude-code](https://github.com/anthropics/claude-code) | AI Agent CLI | N/A | Hooks/events only | ⭐⭐⭐⭐⭐ |
| [termux-app](https://github.com/termux/termux-app) | Native Terminal | 38k+ | Android native | ⭐⭐⭐ |
| [blink](https://github.com/blinksh/blink) | Native Terminal | 8k+ | iOS native (SSH/Mosh) | ⭐⭐⭐⭐ |
| [a-shell](https://github.com/holzschu/a-shell) | Native Terminal | 2k+ | iOS native (sandboxed) | ⭐⭐⭐ |
| [localtunnel](https://github.com/localtunnel/localtunnel) | Tunnel/Bridge | 19k+ | CLI tool | ⭐⭐⭐ |

*Approximate star counts are estimates based on GitHub popularity tiers.

---

## 1. Code-Server (coder/code-server)

**Repository:** https://github.com/coder/code-server  
**Architecture:** Node.js/TypeScript bridge exposing VS Code via HTTP/WebSocket

### What It Does
Runs VS Code on a remote server, accessible via browser. The architecture involves:
- **Node.js entry layer** (`src/node/entry.ts`) - CLI bootstrap
- **HTTP server** (`src/node/http.ts`) - Express-based with authentication
- **WebSocket routing** (`src/node/wsRouter.ts`, `vscodeSocket.ts`) - VS Code protocol bridge
- **Socket management** (`src/node/socket.ts`) - Unix socket or TCP for VS Code IPC

### Mobile-Specific Patterns

#### iPad/iOS Support (from `docs/ipad.md`, `docs/ios.md`)
1. **PWA Installation:** "Add to Home Screen" from Safari for fullscreen native-like experience
2. **Self-signed certificates:** Requires CA:true certificate with SAN matching hostname; must use domain name (not IP) for WebSocket support
3. **USB-C Network:** Raspberry Pi connected via USB-C provides power + direct network; enables offline local development
4. **Keyboard shortcuts:** Custom `keybindings.json` to override Safari defaults (e.g., `cmd+w` for close editor, not browser tab)
5. **Servediter app:** Third-party app for accessing code-server when certificates can't be installed

#### Key Technical Constraints Discovered
- Safari requires `basicConstraints=CA:true` in certificates
- WebSockets blocked without domain names (use `.local` mDNS)
- `ctrl+c` doesn't stop processes in browser terminal (upstream VS Code issue #114009)
- Trackpad scrolling broken on iPadOS < 14.5

### Relevance to ReCursor
**Very High.** Code-server demonstrates:
- How to bridge a local CLI tool (VS Code) to a mobile browser
- WebSocket protocol forwarding patterns
- PWA manifest configuration for mobile-native feel
- Certificate/tunnel considerations for local network access

**Architecture takeaway:** ReCursor could adopt the pattern of running a local Node bridge that exposes a Flutter app's expected protocol (WebSocket or HTTP) and forwards to Claude Code's agent.

---

## 2. Continue.dev (continuedev/continue)

**Repository:** https://github.com/continuedev/continue  
**Architecture:** Modular AI coding assistant with React GUI

### Structure
```
continue/
├── core/               # Core agent logic (TS)
├── gui/               # React-based UI (runs beside IDE)
├── extensions/        # IDE adapters (VS Code, IntelliJ, CLI)
├── binary/            # Packaged binary via esbuild + pkg
└── actions/           # CI/CD checks
```

### What It Does
Continue provides AI-assisted coding that integrates with multiple IDEs. The GUI is a **React application** designed to run alongside an IDE, communicating via a protocol layer.

### Mobile-Relevant Patterns

#### GUI Architecture (`gui/src/`)
- **Memory Router:** Uses `createMemoryRouter` from react-router for embedded usage
- **Parallel Listeners:** `ParallelListeners` component for event handling
- **VSC Theme Provider:** Inherits IDE theming for consistent appearance
- **TipTap Editor:** Rich text input with editor context

#### Core Binary (`binary/`)
- **esbuild bundling:** TypeScript → single JS file
- **pkg packaging:** Node.js app → native binary (cross-platform)
- **TCP/stdio communication:** Can communicate via stdin/stdout OR TCP (debugging mode)

```typescript
// From binary/README.md
debug workflow: set useTcp to true in CoreMessenger.kt, 
connect VS Code debugger to Core Binary
```

#### Plugin/Integration Pattern
- **Protocol abstraction:** `core/protocol/` defines message types
- **ContinueServer:** `core/continueServer/` - server-side component interface

### Relevance to ReCursor
**Very High.** Continue demonstrates:
- How to separate GUI from core logic for cross-platform deployment
- React GUI patterns that could be adapted to Flutter
- Protocol-based architecture for IDE-agnostic communication
- Binary packaging for distribution

**Architecture takeaway:** ReCursor's `packages/bridge` should follow the `core/` + `binary/` pattern—core TypeScript logic that can be bundled and invoked from Flutter via stdin/stdio or local TCP socket.

---

## 3. Claude Code Official (anthropics/claude-code)

**Repository:** https://github.com/anthropics/claude-code  
**Architecture:** Node.js CLI with plugin system

### Key Mobile-Adjacent Feature: Hooks
The `plugins/hookify/` directory provides the **official hook system** for intercepting Claude Code events:

#### Hook Types (from `hooks/hooks.json`)
```json
{
  "hooks": {
    "PreToolUse": [{"type": "command", "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse.py"}],
    "PostToolUse": [{"type": "command", "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/posttooluse.py"}],
    "Stop": [{"type": "command", "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/stop.py"}],
    "UserPromptSubmit": [{"type": "command", "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/userpromptsubmit.py"}]
  }
}
```

#### Hook Pattern Implementation
Hooks receive JSON via stdin and output JSON to stdout:

```python
# From pretooluse.py
def main():
    input_data = json.load(sys.stdin)
    tool_name = input_data.get('tool_name', '')
    # Determine event type from tool
    if tool_name == 'Bash':
        event = 'bash'
    elif tool_name in ['Edit', 'Write', 'MultiEdit']:
        event = 'file'
    # Evaluate rules and return result
    result = engine.evaluate_rules(rules, input_data)
    print(json.dumps(result), file=sys.stdout)
    sys.exit(0)  # Always exit 0 to not block
```

### Plugin Architecture (from `plugins/README.md`)
```
plugin-name/
├── .claude-plugin/plugin.json    # Metadata
├── commands/                      # Slash commands
├── agents/                        # Specialized agents
├── skills/                        # Agent Skills
├── hooks/                         # Event handlers
└── .mcp.json                      # MCP server config
```

### Relevance to ReCursor
**Critical.** This is the **official extension mechanism** for Claude Code.

**Architecture takeaways:**
1. ReCursor's bridge could be implemented as a Claude Code plugin with hooks
2. Hooks use stdio JSON protocol—directly compatible with WebSocket bridging
3. `${CLAUDE_PLUGIN_ROOT}` environment variable for portable paths
4. Plugin discovery via `.claude/` directory in project root

**Limitation:** No official mobile/WebSocket extension point—hooks are local subprocess calls only.

---

## 4. Termux App (termux/termux-app)

**Repository:** https://github.com/termux/termux-app  
**Architecture:** Android terminal emulator (Java/Kotlin + native)

### What It Does
Provides a Linux environment on Android without rooting. Key architectural components:

#### Architecture
- **Terminal emulation:** VT100-compatible terminal emulation in Java
- **Bootstrap packages:** Minimal Linux userspace (~180MB) downloaded on first run
- **Package management:** `pkg`/`apt` wrapper for Android-compatible packages
- **Plugin ecosystem:** Separate APKs sharing `sharedUserId`:
  - `termux-api` - Android API access from shell
  - `termux-boot` - Auto-start on boot
  - `termux-float` - Floating terminal window
  - `termux-widget` - Home screen shortcuts

#### Mobile Constraints Documented
From README: **Android 12+ kills phantom processes >32** causing `[Process completed (signal 9)]` errors. Requires disabling phantom process killing or using fewer background processes.

### Relevance to ReCursor
**Low.** Termux is a full Linux environment, not an AI coding agent companion.

**Potential insight:** The sharedUserId plugin pattern could inspire optional ReCursor bridge extensions.

---

## 5. Blink Shell (blinksh/blink)

**Repository:** https://github.com/blinksh/blink  
**Architecture:** iOS SSH/Mosh client (Objective-C/Swift + C)

### What It Does
"Professional, desktop-grade terminal for iOS" using Mosh for persistent connections.

#### Key Features
- **Mosh support:** UDP-based persistent connections (survives IP changes)
- **HTerm rendering:** Chromium's terminal renderer for speed
- **Key management:** SSH key generation and management in iOS Keychain
- **Bluetooth keyboard:** Full support for remapping (Caps→Esc, Caps→Ctrl)
- **Built-in commands:** Local file operations without SSH connection

#### iOS Sandbox Workarounds
From README—environment variable redirection for iOS sandbox:
```objc
// From MCPSession.m
setenv PATH = $PATH:~/Library/bin:~/Documents/bin
setenv PYTHONHOME = $HOME/Library/
setenv SSH_HOME = $HOME/Documents/
setenv CURL_HOME = $HOME/Documents/
```

**Build:** Precompiled frameworks available; build requires Xcode with specific developer IDs via `developer_setup.xcconfig`

### Relevance to ReCursor
**Medium-High.** Blink demonstrates:
- iOS terminal UI/UX patterns
- SSH key management in mobile secure enclave
- Local command execution (cd, ls, cat, grep, curl, scp, sftp)
- Mosh for connection persistence (relevant for flaky mobile networks)

**Architecture takeaway:** If ReCursor requires SSH fallback, Mosh protocol provides better mobile network resilience than SSH alone.

---

## 6. a-Shell (holzschu/a-shell)

**Repository:** https://github.com/holzschu/a-shell  
**Architecture:** iOS terminal with WebAssembly command support (Swift + C + WebAssembly)

### What It Does
"Unix-like terminal on iOS" with unique WebAssembly command support.

#### Key Features
- **ios_system:** Shared framework for command interpretation
- **Multiple windows:** iPadOS 13+ multi-window support
- **WebAssembly commands:** User-compiled WASM binaries as commands
  ```bash
  clang program.c  # produces webAssembly
  ./a.out          # executes via WASM runtime
  ```
- **Bookmark system:** `pickFolder` + `bookmark`/`jump` for accessing directories in other apps' sandboxes
- **Shortcuts integration:** "Execute Command", "Put File", "Get File" for Shortcuts app automation
- **Python/Lua/TeX:** Built-in interpreters

#### iOS Sandbox Pattern
Again shows the `$HOME` redirection pattern:
```bash
# Cannot write to ~, only ~/Documents/, ~/Library/, ~/tmp
# a-Shell redirects $HOME → ~/Documents
# Config files → ~/Library/
```

### Relevance to ReCursor
**Medium.** Shows:
- WebAssembly as a portable command distribution format
- iOS multi-window architecture
- Bookmark-based cross-app file access
- Shortcuts integration for automation

---

## 7. LocalTunnel (localtunnel/localtunnel)

**Repository:** https://github.com/localtunnel/localtunnel  
**Architecture:** Node.js-based secure tunnel to localhost

### What It Does
```bash
npx localtunnel --port 8000
# Provides public URL like https://abc123.loca.lt
```

Uses a client-server model:
- **Client:** Your local machine (Node.js CLI)
- **Server:** Public tunnel server (can be self-hosted)
- **Protocol:** WebSocket-based tunneling

### Relevance to ReCursor
**Medium.** If ReCursor needs remote access without VPN:
- Similar tunnel architecture could expose local bridge to mobile
- Security considerations: public URL = public access (needs auth layer)
- Alternative: [ngrok](https://ngrok.com), [cloudflared](https://github.com/cloudflare/cloudflared)

**Architecture takeaway:** A tunnel could be ReCursor's "quick start" option—user runs bridge locally, tunnel provides public endpoint, mobile app connects via that endpoint with token auth.

---

## Comparative Architecture Matrix

| Aspect | code-server | Continue | Claude Hooks | Termux | Blink | a-Shell | LocalTunnel |
|--------|-------------|----------|--------------|--------|-------|---------|-------------|
| **Bridge Protocol** | WebSocket to VS Code | stdio/TCP to core | stdio JSON | N/A (local) | SSH/Mosh | Local exec | WebSocket tunnel |
| **Mobile Client** | Browser PWA | React GUI (desktop) | N/A | Native Android | Native iOS | Native iOS | CLI only |
| **Pairing/Auth** | Password/cookie | N/A | Env var based | N/A | SSH keys | N/A | Public URL + token |
| **Offline Support** | Yes (local) | Yes (local) | Yes (local) | Yes | Yes (Mosh) | Yes | Requires server |
| **Sandbox Handling** | N/A | N/A | N/A | Bootstrap pkgs | $HOME redirect | Bookmarks | N/A |

---

## Relevant vs. Not Relevant Classification

### ✅ Highly Relevant (direct patterns)

| Project | Relevance |
|---------|-----------|
| **code-server** | PWA bridge pattern, certificate handling, iPad-specific UX |
| **continue.dev** | GUI/core separation, protocol design, binary packaging |
| **claude-code hooks** | Official event interception mechanism, JSON protocol |
| **Blink** | Mobile terminal UX, Mosh for resilience, key management |

### ⚠️ Adjacent (some patterns)

| Project | Relevance |
|---------|-----------|
| **a-Shell** | WASM commands, Shortcuts integration (if ReCursor adds Shortcuts) |
| **LocalTunnel** | Tunnel architecture (if offering remote-without-VPN quickstart) |

### ❌ Not Relevant

| Project | Why Not |
|---------|---------|
| **Termux** | Full Linux environment vs. focused agent companion; different problem space |

---

## Recommendations for ReCursor

Based on this research:

### 1. Bridge Protocol Design (from continue.dev + claude-code)
- Use **JSON-over-stdio** for local bridge ↔ Flutter communication (like Continue's binary)
- Add **WebSocket fallback** for remote scenarios (like code-server)
- Implement **hooks.json-compatible event interception** for one-way observation

### 2. Mobile UX Patterns (from code-server + Blink)
- Support **PWA installation** for quick access (add to home screen)
- Handle **certificate/hostname requirements** for WebSocket (Apple constraints)
- Consider **Mosh protocol** for connection resilience if implementing SSH fallback

### 3. Distribution (from continue.dev binary + code-server npm)
- Package bridge as **npm installable** (`npm install -g recursor-bridge`)
- Package as **single binary** via `pkg` for users without Node
- Auto-discovery via project `.recursor/config.json`

### 4. Security Model (from Blink + code-server)
- **Local-first:** Default to localhost WebSocket (no tunnel)
- **Optional tunnel:** localtunnel/ngrok with token-based auth
- **No persistent cloud:** Unlike code-server SaaS, ReCursor should avoid requiring hosted infrastructure

### 5. Claude Integration (from claude-code plugins)
- Implement as **official plugin** using hooks API for event observation
- Document that real-time control requires Agent SDK (parallel session), not hooks
- Clarify in docs: **cannot join existing Claude Code session** (hooks are one-way)

---

## Open Questions Identified

1. **No mobile-native AI agent companion exists:** All solutions are either browser-based or generic SSH terminals. This validates ReCursor's niche.

2. **Claude Code Remote Control:** Officially first-party only (claude.ai/code + apps). Third-party protocols not documented. ReCursor's approach must use hooks (observation) or Agent SDK (parallel control).

3. **Hook Event Completeness:** Claude Code hooks at `PreToolUse` may not capture all UI-relevant events. Need verification of hook coverage for diff, timeline, and approval patterns.

---

## Sources

| Source | Type | URL |
|--------|------|-----|
| code-server | GitHub | https://github.com/coder/code-server |
| continue | GitHub | https://github.com/continuedev/continue |
| claude-code | GitHub | https://github.com/anthropics/claude-code |
| termux-app | GitHub | https://github.com/termux/termux-app |
| blink | GitHub | https://github.com/blinksh/blink |
| a-shell | GitHub | https://github.com/holzschu/a-shell |
| localtunnel | GitHub | https://github.com/localtunnel/localtunnel |
| Claude Code Docs | Official | https://code.claude.com/docs/ |
| Agent SDK Docs | Official | https://docs.claude.com/en/api/agent-sdk/overview |

---

*End of Research Report*
