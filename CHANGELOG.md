# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-21

### Added

#### Monorepo Infrastructure
- Monorepo scaffolding with `apps/`, `packages/`, `docs/`, `.github/`, `fastlane/` structure
- Development helper scripts in `tool/` for bridge and mobile workflows
- Pre-commit hooks for format and check enforcement
- Repository governance documents: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`
- Agentic AI contributor guidance in `AGENTS.md`

#### Mobile App (`apps/mobile/`)
- Flutter mobile application with Riverpod state management
- Feature screens: agents, approvals, chat, diff, git, home, repos, session, settings, startup, terminal
- Core infrastructure: config, models, monitoring, network, notifications, providers, storage, sync
- Health verification screen with payload normalization and connection mode detection
- WebSocket service unified across feature providers
- JetBrains Mono custom font and SVG branding assets
- Flutter analyzer configuration with pre-build checks
- Unit and integration tests for core features

#### Bridge Server (`packages/bridge/`)
- TypeScript bridge server for mobile-agent communication
- WebSocket connection manager for real-time messaging
- HTTP API router with health check protocol
- Agent SDK integration with session management
- Agent runtime for parallel session control
- Notification tracking system
- CLI entry point (`src/cli.ts`, `src/cli/`)
- Configuration management (`config.ts`)
- Jest testing infrastructure with unit tests for hooks and websocket

#### Claude Code Plugin (`packages/claude-plugin/`)
- Claude Code plugin scaffold for event forwarding
- Hook configuration for integration with Claude Code CLI

#### Documentation Site (`docs-site/`)
- Astro Starlight documentation site with custom editorial design system
- Custom layout components: Footer, PageTitle, SiteTitle, ThemeSelect
- LLM-friendly outputs: `llms.txt`, `llms-full.txt`, page-markdown generation
- Base-path aware URLs for GitHub Pages deployment
- Serif typography (Crimson Pro) for headings, Inter for body/UI
- Warm off-white palette with refined ink tones and dark mode support

#### Documentation (`docs/`)
- Architecture: `overview.md`, `data-flow.md`
- Integration guides: `claude-code-hooks.md`, `agent-sdk.md`, `opencode-ui-patterns.md`
- Protocol specs: `bridge-protocol.md`, `bridge-http-api.md`, `error-handling.md`, `type-mapping.md`
- Security: `security-architecture.md`, `offline-architecture.md`, `push-notifications.md`
- Operations: `ci-cd.md`, `testing-strategy.md`
- Research: Claude Code integration feasibility, remote control analysis, documentation stacks, mobile companion repos, tunnel pairing patterns
- Wireframes: Screen flows for all feature modules

#### CI/CD (`.github/workflows/`)
- `test.yml`: Automated testing workflow
- `docs.yml`: Documentation site build and deployment
- `deploy.yml`: Deployment workflow

### Changed

- Replaced authentication flow with startup sequence in mobile app
- Simplified router and home shell after auth removal
- Replaced PNG logos with SVG branding assets
- Reorganized and rebranded documentation from RemoteCLI to ReCursor
- Applied Prettier formatting to bridge source files

### Fixed

- CI trailing slash for GitHub Pages routing (`DOCS_BASE`)
- CI workflow permissions for repository updates

[0.1.0]: https://github.com/RecursiveDev/ReCursor/releases/tag/v0.1.0