# Architecture

The architecture section describes the bridge-first system design and the constraints that shape ReCursor's mobile experience.

<div class="hero-note" style="margin-top: 1.5rem; margin-bottom: 2rem;">
  **Bridge-first by design:** ReCursor intentionally avoids cloud services. All communication between the mobile app and your development environment flows through a local bridge server you control.
</div>

## Core concepts

- [System overview](/architecture/system-overview/): The core component model: mobile app, bridge server, and Claude Code integration points.
- [Data flow](/architecture/data-flow/): Message-level sequence diagrams showing how commands travel from mobile to desktop.
- [Bridge protocol](/architecture/bridge-protocol/): The HTTP/WebSocket protocol specification for bridge communication.
- [Data models](/architecture/data-models/): Core data structures: requests, responses, sessions, and repositories.
- [Project structure](/architecture/project-structure/): Repository organization: Flutter app, bridge server, and documentation.

## Design principles

| Principle | Implementation |
|-----------|---------------|
| **Local-first** | Bridge runs on localhost, no cloud services required |
| **Transparent** | All data stays in your network boundary |
| **Reversible** | No persistent state changes without explicit approval |
| **Observable** | Full logging and monitoring of all bridge traffic |

## Navigation guide

- Start with [System overview](./system-overview/) for the core component model
- Use [Data flow](./data-flow/) when you need message-level sequence details
- Read [Bridge protocol](./bridge-protocol/) and [Project structure](./project-structure/) for implementation-facing reference material
