---
title: "Research Report: Tunnel/Pairing Pattern Repositories"
description: "Generated: 2026-03-20 | Researcher Agent"
editUrl: "https://github.com/RecursiveDev/ReCursor/edit/main/docs/research/tunnel-pairing-patterns-2026-03-20.md"
sidebar:
  order: 90
---
> Generated: 2026-03-20 | Researcher Agent

## Executive Summary

This research identifies **5 high-value open-source repositories** implementing secure pairing, remote exposure, and mobile-to-desktop bridge patterns relevant to ReCursor's architecture. The strongest candidate is **remote-claude** by MadsLangkilde, which demonstrates a production-ready Tailscale-based secure tunnel with QR onboarding, persistent PTY sessions, and voice control integration. Key patterns discovered include: (1) QR-code-based onboarding flows, (2) self-signed certificate generation for HTTPS in private networks, (3) Tailscale IP auto-detection for secure mobile access, (4) persistent PTY sessions with replay buffers for mobile reconnections, and (5) WebSocket-based real-time terminal streaming.

## Source Validation

| Source | Tier | Stars | Language | Relevance |
|--------|------|-------|----------|-----------|
| [MadsLangkilde/remote-claude](https://github.com/MadsLangkilde/remote-claude) | 1 | 0 | JavaScript/TypeScript/Swift | **Primary** - Most comprehensive |
| [GCWing/BitFun](https://github.com/GCWing/BitFun) | 1 | 489 | TypeScript/Rust | **Secondary** - QR pairing, mobile control |
| [obekt/iCode](https://github.com/obekt/iCode) | 1 | 1 | TypeScript | **Secondary** - Simpler PTY/WebSocket |
| [TheKinng96/claude-remote](https://github.com/TheKinng96/claude-remote) | 1 | 0 | Shell | **Tertiary** - QR setup pattern |
| [anderspitman/SirTunnel](https://github.com/anderspitman/SirTunnel) | 1 | 1547 | Python | **Reference** - SSH-based tunneling |
| [anderspitman/awesome-tunneling](https://github.com/anderspitman/awesome-tunneling) | 1 | 20542 | Markdown | **Reference** - Comprehensive tunnel list |

---

## Repository Analysis

### 1. MadsLangkilde/remote-claude ⭐ PRIMARY REFERENCE

**URL**: https://github.com/MadsLangkilde/remote-claude  
**Description**: "Control Claude Code from your phone. A mobile-first web terminal with persistent sessions, voice control via Gemini, and a macOS menu bar companion app."  
**Stack**: Node.js (Express + WebSocket + node-pty), Swift (macOS menu bar app), xterm.js (terminal UI)

#### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              YOUR MAC                                    │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ server.js (Express + WebSocket + node-pty)                      │   │
│  │ ┌──────────────┐  ┌─────────────────────┐  ┌─────────────────┐ │   │
│  │ │ HTTPS Server │  │ PTY Session Manager │  │ Project Scanner │ │   │
│  │ │  Port 3456   │  │  (persistent)     │  │ (auto-detect)   │ │   │
│  │ └──────┬───────┘  └──────────┬──────────┘  └─────────────────┘ │   │
│  │        │                     │                                  │   │
│  │        └─────────────────────┘                                │   │
│  │              WebSocket (wss)                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                         │
│           ┌──────────────────┴──────────────────┐                     │
│           │            Tailscale VPN              │                     │
│           │     (private encrypted network)      │                     │
│           └──────────────────┬──────────────────┘                     │
└──────────────────────────────┼─────────────────────────────────────────┘
                               │
┌──────────────────────────────┼─────────────────────────────────────────┐
│                         PHONE │ BROWSER)                               │
│                                                                         │
│  ┌──────────────────────────────┴─────────────────────────────────┐    │
│  │  index.html + app.js (PWA)                                     │    │
│  │  ┌───────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │    │
│  │  │ Project Browser│ │ xterm.js    │ │ Gemini Voice Assistant  │ │    │
│  │  │ (folder tree)  │ │ (terminal)  │ │ (WebSocket audio)       │ │    │
│  │  └───────────────┘ └─────────────┘ └─────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Key Patterns for ReCursor

**Pattern 1: Secure Network Detection (Tailscale Auto-Detection)**
```swift
// From: macos-app/RemoteClaude.swift:280-301
func getTailscaleIP() -> String? {
    let tailscalePaths = ["/usr/local/bin/tailscale", "/opt/homebrew/bin/tailscale"]
    for path in tailscalePaths {
        if FileManager.default.fileExists(atPath: path) {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = ["ip", "-4"]  // Get IPv4 Tailscale address
            // ... exec and return IP
        }
    }
    return nil
}
```
**Relevance**: Demonstrates detecting secure overlay networks without hardcoding IPs. Falls back to localhost if Tailscale unavailable.

**Pattern 2: QR Code Onboarding Flow**
```swift
// From: macos-app/RemoteClaude.swift:658-734
func generateQRCode(from string: String) -> NSImage? {
    guard let data = string.data(using: .utf8),
          let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    // ... render and return NSImage
}

@objc func showQRCode() {
    guard let url = getPhoneURL(),  // Builds https://<tailscale-ip>:3456
          let qrImage = generateQRCode(from: url) else { return }
    // Display in modal window with copy URL button
}
```
**Relevance**: Zero-friction mobile onboarding - generate URL with detected IP, display QR, mobile scans to connect. No manual IP entry.

**Pattern 3: Self-Signed Certificate for Private Network HTTPS**
```bash
# From: CLAUDE.md and RemoteClaude.swift
openssl req -x509 -newkey rsa:2048 \
  -keyout certs/key.pem -out certs/cert.pem \
  -days 365 -nodes \
  -subj "/CN=remote-claude" \
  -addext "subjectAltName=IP:${TAILSCALE_IP}"
```
**Relevance**: Required because mobile browsers require HTTPS for getUserMedia (microphone). Self-signed certs acceptable for Tailscale private network.

**Pattern 4: Persistent PTY Sessions with Reconnection Replay**
```javascript
// From: server.js:48-52, 163-178
const PTY_GRACE_MS = 30 * 60 * 1000; // 30 min grace period
const REPLAY_BUFFER_SIZE = 100000;   // 100KB replay buffer
const ptySessions = new Map();         // path -> { pty, replayBuffer, listeners }

// On WebSocket connect:
if (existing && !existing.exited) {
    clearTimeout(existing.killTimer);
    existing.listeners.add(ws);
    if (existing.replayBuffer.length > 0) {
        ws.send(JSON.stringify({ type: 'output', data: existing.replayBuffer }));
    }
}

// On PTY output:
proc.onData((data) => {
    session.replayBuffer += data;
    if (session.replayBuffer.length > REPLAY_BUFFER_SIZE) {
        session.replayBuffer = session.replayBuffer.slice(-REPLAY_BUFFER_SIZE);
    }
    for (const listener of session.listeners) {
        listener.send(JSON.stringify({ type: 'output', data }));
    }
});
```
**Relevance**: Critical for mobile where WebSocket drops on background/standby. PTY stays alive, reconnecting clients get replay buffer.

**Pattern 5: Auto-Reconnect on Visibility Change**
```javascript
// From: public/app.js (document.visibilitychange handler)
document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && currentProject) {
        if (!ws || ws.readyState === WebSocket.CLOSED) {
            connectWebSocket(currentProject);  // Auto-reconnect
        }
    }
});
```
**Relevance**: Mobile browsers pause JavaScript in background. This pattern reconnects automatically when user returns to tab.

**Pattern 6: Touch-Optimized Terminal Scrolling**
```javascript
// From: public/app.js (setupTouchScroll function)
function setupTouchScroll(container) {
    const viewport = container.querySelector('.xterm-viewport');
    viewport.style.touchAction = 'none';  // Disable browser handling
    
    let velocity = 0;
    let lastY = 0;
    const LINE_HEIGHT = 18;
    const FRICTION = 0.94;
    
    viewport.addEventListener('touchstart', (e) => {
        velocity = 0;
        lastY = e.touches[0].clientY;
    }, { passive: true });
    
    viewport.addEventListener('touchmove', (e) => {
        e.preventDefault();  // Custom handling
        const deltaY = lastY - e.touches[0].clientY;
        term.scrollLines(Math.round(deltaY / LINE_HEIGHT));
        velocity = deltaY / deltaTime;
    });
    
    // Momentum scrolling after lift-off
}
```
**Relevance**: xterm.js default scroll behavior terrible on mobile. Custom momentum scroll essential.

---

### 2. GCWing/BitFun ⭐ SECONDARY REFERENCE

**URL**: https://github.com/GCWing/BitFun  
**Description**: "AI assistant with built-in Code Agent and Cowork Agent... remotely control the desktop through mobile QR pairing or Telegram / Feishu bots"  
**Stack**: Rust + TypeScript (Tauri for desktop), mobile browser-based remote

#### Key Patterns

**Pattern: QR Pairing for Key Exchange**
```markdown
# From README.md
| Feature | Description |
|---------|-------------|
| **QR Pairing** | Scan a QR code generated by the desktop, complete key exchange, and bind a long-lived connection |
| **Full Control** | View sessions, switch modes, send instructions, and control the desktop workflow remotely |
| **Real-time Streaming** | Every Agent step and tool call can be viewed live on your phone |
```
**Relevance**: Mentions "key exchange" in QR flow - suggests cryptographic pairing beyond simple URL sharing. Architecture not inspectable (no source code breakdown available) but demonstrates production mobile remote control of AI coding agents.

---

### 3. obekt/iCode ⭐ SECONDARY REFERENCE

**URL**: https://github.com/obekt/iCode  
**Description**: "Remote-control Claude Code from your iPhone. Runs as a lightweight Node.js server on your Mac; connect from Safari over your local network."  
**Stack**: Node.js, TypeScript, xterm.js, esbuild

#### Architecture Overview

```
iPhone Safari <--WebSocket--> Node.js server <--PTY--> claude CLI
```

#### Key Patterns

**Pattern: Simplified WebSocket Protocol with Prefix Bytes**
```typescript
// From: src/server/pty.ts
// Protocol: client -> server
// "0<data>"       — stdin input
// "1<cols>,<rows>" — resize
// "2<json>"       — spawn/attach session: {"cwd":"/path"}

// Server -> client
// raw string      — PTY output (no prefix)
// "\x01<json>"    — control messages (spawned, attached, exited, error, ready)

export function handleConnection(ws: WebSocket): void {
    ws.on("message", (raw) => {
        const msg = raw.toString();
        const prefix = msg[0];
        const payload = msg.slice(1);
        
        switch (prefix) {
            case "0": currentSession?.pty.write(payload); break;
            case "1": /* resize handling */ break;
            case "2": selectProject(JSON.parse(payload).cwd); break;
        }
    });
}
```
**Relevance**: Lightweight protocol without JSON overhead for every keystroke. Prefix byte eliminates parsing overhead.

**Pattern: Project Persistence via JSON File**
```typescript
// From: src/server/index.ts
const PROJECTS_FILE = join(homedir(), ".config", "icode", "projects.json");

async function loadProjects(): Promise<string[]> {
    try {
        const data = await readFile(PROJECTS_FILE, "utf-8");
        return JSON.parse(data) as string[];
    } catch {
        return [];
    }
}

async function addProject(cwd: string): Promise<void> {
    const projects = await loadProjects();
    const filtered = projects.filter((p) => p !== cwd);
    filtered.unshift(cwd);  // Most recent first
    await saveProjects(filtered.slice(0, 20));  // Keep last 20
}
```
**Relevance**: Simple local-first project list without database. User's recent projects survive server restart.

**Pattern: Environment Sanitization Before Spawn**
```typescript
// From: src/server/pty.ts
const env: Record<string, string> = {};
for (const [k, v] of Object.entries(process.env)) {
    if (v !== undefined) env[k] = v;
}
env.TERM = env.TERM || "xterm-256color";
delete env.CLAUDECODE;        // Critical: prevents "nested session" error
delete env.CLAUDE_CODE_SESSION;
```
**Relevance**: Claude Code refuses to start if CLAUDECODE env var present (prevents recursive sessions).

---

### 4. TheKinng96/claude-remote ⭐ TERTIARY REFERENCE

**URL**: https://github.com/TheKinng96/claude-remote  
**Description**: "An open-source web server that lets you run Claude Code on your desktop and control it remotely from any mobile browser... with single QR code scan."  
**Stack**: Shell scripts (appears to be wrapper/planning repo)

#### Key Observations

This repository appears to be in planning phase (.planning/ directory present, .claude/commands/ for AI-assisted development). README emphasizes:

- "Zero-friction Setup: Connect mobile to desktop with single QR code scan"
- "Local-first Security: All data stays within your local network"
- No inspectable implementation yet - serves as requirements/spec reference

**Relevance**: Validates QR-first onboarding as user expectation for this use case.

---

### 5. anderspitman/SirTunnel ⭐ REFERENCE ARCHITECTURE

**URL**: https://github.com/anderspitman/SirTunnel  
**Description**: "Minimal, self-hosted, 0-config alternative to ngrok. Caddy+OpenSSH+50 lines of Python."  
**Stack**: Python, Caddy, SSH

#### Architecture Overview

```
Laptop (port 8080) <--SSH Reverse Tunnel--> Server (port 9001) <--Caddy--> HTTPS://sub1.example.com
```

#### Key Patterns

**Pattern: SSH Reverse Tunnel + Dynamic Caddy Configuration**
```python
# From: sirtunnel.py (50 lines)
import sys
import json
from urllib import request

host = sys.argv[1]   # sub1.example.com
port = sys.argv[2]   # 9001 (local SSH tunnel endpoint)
tunnel_id = host + '-' + port

# Add Caddy route dynamically via admin API
caddy_add_route_request = {
    "@id": tunnel_id,
    "match": [{"host": [host]}],
    "handle": [{
        "handler": "reverse_proxy",
        "upstreams": [{"dial": ':' + port}]
    }]
}

# POST to Caddy admin API
create_url = 'http://127.0.0.1:2019/config/apps/http/servers/sirtunnel/routes'
req = request.Request(method='POST', url=create_url, headers={'Content-Type': 'application/json'})
request.urlopen(req, body)

# Cleanup on CTRL-C (KeyboardInterrupt)
delete_url = 'http://127.0.0.1:2019/id/' + tunnel_id
req = request.Request(method='DELETE', url=delete_url)
request.urlopen(req)
```

**Usage Pattern**:
```bash
# From laptop:
ssh -tR 9001:localhost:8080 example.com sirtunnel.py sub1.example.com 9001
# -t: allocate TTY so CTRL-C propagates
# -R: reverse tunnel server:9001 -> laptop:8080
# Arguments passed to sirtunnel.py for Caddy config
```
**Relevance**: Demonstrates zero-server-config tunneling using existing SSH infrastructure. Caddy's auto-HTTPS makes this "just work".

---

### 6. anderspitman/awesome-tunneling ⭐ REFERENCE LIST

**URL**: https://github.com/anderspitman/awesome-tunneling  
**Stars**: 20,542  
**Purpose**: Curated list of ngrok alternatives and tunneling solutions

#### Recommended Solutions for ReCursor Context

| Tool | Type | Notes |
|------|------|-------|
| **Cloudflare Tunnel** | Managed | "Gold standard for most people" - production quality, free tier |
| **Tailscale** | Mesh VPN | WireGuard-based, zero-config, excellent for private device networks |
| **SirTunnel** | Self-hosted | Minimal (Caddy+SSH), auto HTTPS |
| **sish** | Self-hosted | SSH-based ngrok alternative, WebSocket support |
| **frp** | Self-hosted | Comprehensive ngrok alternative, P2P mode, UDP, QUIC |
| **headscale** | Self-hosted | Open source Tailscale control server |
| **piko** | Self-hosted | Production-grade, Kubernetes-friendly |

---

## Pattern Comparison Matrix

| Pattern | remote-claude | iCode | BitFun | SirTunnel | ReCursor Applicability |
|---------|---------------|-------|--------|-----------|------------------------|
| QR Onboarding | ✅ Core | ❌ Manual IP | ✅ Core | ❌ SSH-based | **High** - Essential UX |
| Tailscale Integration | ✅ Auto-detect | ❌ Same network | Unknown | ❌ | **High** - Secure default |
| Self-signed HTTPS | ✅ For media | ❌ HTTP only | Unknown | ✅ Via Caddy | **Medium** - Mobile requires HTTPS |
| Persistent PTY | ✅ 30min grace | ✅ Survival | ✅ | N/A | **Critical** - Mobile reconnects |
| Voice Control | ✅ Gemini | ❌ | ✅ | ❌ | **Future** - Differentiation |
| Touch Scroll | ✅ Custom | ✅ Basic | ✅ | N/A | **Critical** - Mobile UX |
| Auto-reconnect | ✅ Visibility | ❌ Manual | ✅ | N/A | **Critical** - Mobile background |
| Menu Bar App | ✅ Swift | ❌ | ❌ | N/A | **Nice** - Convenience layer |

---

## Recommendations for ReCursor

### Immediate Implementation (High Priority)

1. **QR Code Onboarding Flow**: Adopt remote-claude's pattern - generate URL with detected IP (Tailscale > LAN IP > localhost fallback), display QR code in desktop UI, mobile scans to connect. Zero manual IP entry.

2. **Secure Network Detection**: Implement Tailscale auto-detection (`tailscale ip -4`) with fallback to standard LAN IP detection. UI should indicate connection type (Tailscale secure vs local network vs insecure).

3. **Persistent Session Management**: WebSocket disconnects are normal on mobile. PTY sessions must survive with replay buffer (64-100KB) to sync missed output on reconnect.

4. **Touch-Optimized Terminal**: xterm.js default scroll is unusable on mobile. Implement custom touch scroll with momentum physics as shown in remote-claude.

### Medium Priority

5. **HTTPS Certificate Strategy**: For mobile microphone/camera access, HTTPS required. Use self-signed cert pattern with SAN for detected IP. Document cert warning acceptance for users.

6. **Environment Sanitization**: Always unset CLAUDECODE and CLAUDE_CODE_SESSION before spawning to prevent nested session errors.

7. **Simplified Protocol**: Consider iCode's prefix-byte protocol over full JSON for high-frequency terminal I/O.

### Future Research

8. **BitFun's Key Exchange**: BitFun mentions "complete key exchange" in QR flow - investigate if cryptographic pairing adds security beyond Tailscale's encryption.

9. **Voice Control Integration**: remote-claude's Gemini voice assistant uses function calling to translate speech to terminal actions - explore for ReCursor's future features.

---

## Files Modified
- `none` - read-only external research

## Verification Evidence

All repository evidence verified via:
1. GitHub API curl requests returning repository metadata
2. Direct raw file content retrieval via raw.githubusercontent.com
3. Local git clones to /tmp/repo-research/ for deep inspection
4. grep/read commands on cloned sources for specific patterns

Repository paths confirmed:
- `/tmp/repo-research/remote-claude/` - 13191 bytes server.js, 30400 bytes README.md
- `/tmp/repo-research/iCode/` - TypeScript source with prefix-byte protocol
- `/tmp/repo-research/SirTunnel/` - 50-line Python script
- `/tmp/repo-research/claude-remote/` - Planning-phase repository

---

## References

1. MadsLangkilde/remote-claude - https://github.com/MadsLangkilde/remote-claude
2. GCWing/BitFun - https://github.com/GCWing/BitFun
3. obekt/iCode - https://github.com/obekt/iCode
4. TheKinng96/claude-remote - https://github.com/TheKinng96/claude-remote
5. anderspitman/SirTunnel - https://github.com/anderspitman/SirTunnel
6. anderspitman/awesome-tunneling - https://github.com/anderspitman/awesome-tunneling
