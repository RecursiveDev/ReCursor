# ReCursor documentation

<section class="hero-section">
  <div class="hero-note">
    **Source of truth:** The canonical documentation lives in `/docs` in this repository. This site is generated from that corpus and preserves the project constraint that Claude Code Remote Control is first-party only.
  </div>
</section>

## Start here

- [Getting started](/getting-started/): Project overview, product vision, and the current implementation plan.
- [Architecture](/architecture/): System overview, bridge protocol, data flow, and project structure.
- [Integrations](/integrations/): Supported Claude Code Hooks, Agent SDK, and OpenCode UI pattern references.
- [Operations](/operations/): Security, offline behavior, testing, notifications, and CI/CD guidance.
- [Reference](/reference/): Bridge HTTP API, error taxonomy, and cross-language type contracts.
- [Wireframes](/wireframes/): Screen-by-screen mobile UI wireframes covering the bridge-first workflow.
- [Research](/research/): Background research documents that informed the current architecture.
- [Legal](/legal/): Privacy policy and terms of service drafts for future release readiness.

## AI-friendly artifacts

<div class="site-link-list">

- [Compact AI index](/llms.txt)
- [Full concatenated AI context](/llms-full.txt)

</div>

## Project constraints

- ReCursor is a **mobile-first companion UI** for AI coding workflows.
- The app follows a **bridge-first, no-login** model that connects to a user-controlled desktop bridge.
- **Claude Code Hooks** are documented as **one-way observation** only.
- **Claude Agent SDK** is documented as a **parallel, controllable** session model.
- Third-party mirroring of first-party Claude Code Remote Control sessions is treated as **unsupported** unless official documentation changes.
