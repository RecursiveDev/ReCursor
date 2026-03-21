# ReCursor documentation

<section class="hero-section">
  <span class="recursor-kicker">Documentation</span>
  <h1 class="recursor-hero-title">Mobile companion for AI coding workflows</h1>
  <p class="recursor-hero-subtitle">
    ReCursor is a Flutter app with OpenCode-like UI for Claude Code and other AI assistants.
    Bridge-first, no-login—connects to your user-controlled desktop bridge via secure tunnel.
  </p>
  <div class="hero-note">
    **Source of truth:** The canonical documentation lives in `docs-site/src/content/docs/` in this repository.
  </div>
</section>

## Start here

- [Getting started](/getting-started/): Documentation entry points and publishing guidance.
- [Architecture](/architecture/): System overview, bridge protocol, data flow, and project structure.
- [Integrations](/integrations/): Supported Claude Code Hooks, Agent SDK, and OpenCode UI pattern references.
- [Operations](/operations/): Security, offline behavior, testing, notifications, and CI/CD guidance.
- [Reference](/reference/): Bridge HTTP API, error taxonomy, and cross-language type contracts.
- [Legal](/legal/): Privacy policy and terms of service drafts for future release readiness.

## AI-friendly artifacts

<LlmsLinks />

## Project constraints

- ReCursor is a **mobile-first companion UI** for AI coding workflows.
- The app follows a **bridge-first, no-login** model that connects to a user-controlled desktop bridge.
- **Claude Code Hooks** are documented as **one-way observation** only.
- **Claude Agent SDK** is documented as a **parallel, controllable** session model.
- Third-party mirroring of first-party Claude Code Remote Control sessions is treated as **unsupported** unless official documentation changes.
