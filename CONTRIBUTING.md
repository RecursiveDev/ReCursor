# Contributing to ReCursor

Thanks for your interest in contributing to **ReCursor**.

This project is currently early-stage and documentation-led. Contributions that improve clarity, correctness, and scaffolding quality are especially valuable.

## Code of Conduct

By participating, you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Quick links

- Docs index (source of truth): `docs/README.md`
- Architecture overview: `docs/architecture/overview.md`
- Plan / roadmap: `docs/PLAN.md`
- Agentic AI guidance: `AGENTS.md`

## What you can contribute right now

Because implementation is not yet complete, these contribution types are most helpful:

- Documentation fixes and improvements (accuracy, diagrams, references)
- Repo scaffolding improvements (structure, templates, meta files)
- Developer experience improvements (scripts, CI scaffolding) **only when requested/approved**

## Repository layout

```text
C:/Repository/ReCursor/
├── apps/mobile/            # Flutter app scaffold
├── packages/bridge/        # Node/TypeScript bridge scaffold
└── docs/                   # Documentation (architecture + integration guides)
```

## Development prerequisites (for future work)

You do **not** need a runnable app to contribute docs.

When implementation begins, expected toolchain:
- Flutter + Dart (for `apps/mobile/`)
- Node.js + npm (for `packages/bridge/`)

## Branching & PRs

### Branch naming

Use a short prefix:
- `docs/...` for documentation changes
- `scaffold/...` for structure and meta files
- `feat/...` for implementation work (only when requested)

Examples:
- `docs/fix-hooks-config`
- `scaffold/add-ci-skeleton`

### Commit messages

Conventional Commits are recommended:
- `docs: clarify claude hooks setup`
- `chore: scaffold bridge package`

### Pull request checklist

- [ ] Scope is focused and matches the PR title
- [ ] Docs links are valid (no broken relative links)
- [ ] No unsupported claims were added (especially around Claude Code Remote Control)
- [ ] New files include clear purpose and are placed in the right folder

## Documentation standards

- Prefer precise language and explicit constraints.
- When making factual claims about OpenCode/Claude Code behavior, cite a source:
  - a repo file path (preferred) or
  - an official documentation URL.

## Reporting issues

If you find a problem:
- Open an issue: https://github.com/RecursiveDev/ReCursor/issues
- Include:
  - what you expected
  - what happened
  - steps to reproduce (if applicable)
  - environment details

## Security

Please read our [Security Policy](SECURITY.md). Do **not** report vulnerabilities via public issues.
