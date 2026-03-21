# Research Report: Claude Code Plugin Installation and Verification

> Generated: 2026-03-20 | Researcher Agent

## Executive Summary

The ReCursor project's current approach for installing a Claude Code plugin is **missing critical required components** based on official documentation. The local plugin package (`packages/claude-plugin/`) lacks the mandatory `.claude-plugin/plugin.json` manifest file, and the `hooks.json` file is located at the wrong path (plugin root instead of `hooks/hooks.json`). The installation instructions also reference an incorrect directory path (`~/.claude-code/plugins/` instead of `~/.claude/plugins/` based on upstream examples).

## Source Validation

| Source | Tier | Date | Version/Relevance |
| ------ | ---- | ---- | ----------------- |
| `plugins/plugin-dev/skills/plugin-structure/SKILL.md` | 1 (Official) | Current | Plugin structure requirements |
| `plugins/plugin-dev/skills/plugin-structure/examples/minimal-plugin.md` | 1 (Official) | Current | Minimal plugin requirements |
| `plugins/plugin-dev/skills/plugin-structure/examples/standard-plugin.md` | 1 (Official) | Current | Standard plugin structure |
| `plugins/plugin-dev/skills/hook-development/SKILL.md` | 1 (Official) | Current | Hook configuration format |
| `plugins/hookify/hooks/hooks.json` | 1 (Official) | Current | Working hookify example |
| `CHANGELOG.md` | 1 (Official) | Current | Installation methods |
| `plugins/plugin-dev/skills/skill-development/SKILL.md` | 1 (Official) | Current | Local testing with `--plugin-dir` |
| `plugins/README.md` | 1 (Official) | Current | High-level plugin overview |
| `plugins/plugin-dev/skills/plugin-structure/references/manifest-reference.md` | 1 (Official) | Current | Manifest requirements |

## Key Findings

### 1. Plugin Directory Location (Official Sources)

**Evidence from upstream repository:**

From `C:/Repository/claude-code/plugins/plugin-dev/skills/command-development/examples/plugin-commands.md` (line 548):
```markdown
@/home/user/.claude/plugins/my-plugin/config.json
```

**Finding:** Plugins are cached/installed under `~/.claude/plugins/` (_without_ the `-code` suffix).

**ReCursor Issue:** The ReCursor installation instructions specify `~/.claude-code/plugins/` (with hyphen), which **does not match** the evidenced path pattern.

### 2. Required Plugin Structure (Critical Discovery)

Official Claude Code plugins **must** follow this structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # REQUIRED: Plugin manifest
├── commands/                 # Optional: Slash commands
├── agents/                   # Optional: Subagent definitions
├── skills/                   # Optional: Agent skills
├── hooks/
│   └── hooks.json           # Optional: Event handlers (MUST be in hooks/ subdir)
└── README.md
```

**Source:** `C:/Repository/claude-code/plugins/plugin-dev/skills/plugin-structure/examples/minimal-plugin.md` (lines 1-50)

**Critical finding from manifest-reference.md (line 9):**
> "The manifest MUST be in the `.claude-plugin/` directory at the plugin root. Claude Code will not recognize plugins without this file in the correct location."

### 3. The Missing Manifest Problem

**ReCursor's current structure:**
```
packages/claude-plugin/
├── hooks.json         # ❌ Wrong location (should be hooks/hooks.json)
└── README.md          # Installation docs
```

**Missing:** `.claude-plugin/plugin.json` (REQUIRED)

**The minimal required `plugin.json` (from official source):**
```json
{
  "name": "recursor-bridge"
}
```

**Note:** The `name` field must be unique across all installed plugins and use kebab-case (lowercase with hyphens).

### 4. Hooks Configuration Format

**ReCursor's current `hooks.json` is at the plugin root** - this is **wrong**.

**Correct location:** `hooks/hooks.json` (inside a `hooks/` subdirectory)

From `C:/Repository/claude-code/plugins/hookify/hooks/hooks.json`:
```json
{
  "description": "Hookify plugin - User-configurable hooks from .local.md files",
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

From `C:/Repository/claude-code/plugins/plugin-dev/skills/hook-development/SKILL.md`:
> "For plugin hooks in `hooks/hooks.json`, use wrapper format with `hooks` field containing the events"

### 5. Official Installation Mechanisms

**Method A: Marketplace Installation (Production)**
```bash
claude
/plugin install plugin-name@marketplace-name
```

**Method B: Local Development Testing (Development)**
```bash
cc --plugin-dir /path/to/plugin
```

**Source:** `C:/Repository/claude-code/plugins/plugin-dev/skills/skill-development/SKILL.md` (lines 284-288)

**Environment Variables for Plugin Cache:**
- `CLAUDE_CODE_PLUGIN_CACHE_DIR` - Override default plugin cache location
- `CLAUDE_CODE_PLUGIN_SEED_DIR` - For headless mode plugin installation

### 6. Official Verification Steps

**From troubleshooting documentation in `plugins/hookify/README.md`:**

1. **Check plugin is installed:**
   ```
   /plugin
   ```
   (Lists all installed plugins with scope-based grouping)

2. **For hook-specific plugins:**
   ```
   /hookify:list
   ```
   (Lists loaded hook rules - plugin-specific command)

3. **Verify hook triggers:**
   - Hooks should work immediately after plugin loads
   - No restart of Claude Code required for hooks
   - Check rule file exists in correct location

### 7. Hooks vs Plugins vs Skills Clarification

Based on official documentation:

| Term | What It Is | Configuration |
| ---- | ---------- | ------------- |
| **Plugin** | Container for commands, agents, skills, hooks | `.claude-plugin/plugin.json` + optional components |
| **Hooks** | Event-driven automation (PreToolUse, PostToolUse, etc.) | `hooks/hooks.json` in plugin OR direct in `.claude/settings.json` |
| **Skills** | Modular knowledge packages loaded by agents | `skills/skill-name/SKILL.md` |
| **Commands** | Slash commands (`/command-name`) | `commands/command-name.md` |

**Key distinction:** Hooks can exist as user settings (direct in `.claude/settings.json`) OR as plugin components. ReCursor is attempting to distribute hooks as a plugin component.

## Code Examples

### Correct Minimal Plugin Structure for ReCursor

```
recursor-bridge/
├── .claude-plugin/
│   └── plugin.json          # Required manifest
├── hooks/
│   └── hooks.json           # Hook configuration
└── README.md
```

### Required plugin.json

```json
{
  "name": "recursor-bridge",
  "version": "1.0.0",
  "description": "Forward Claude Code events to ReCursor bridge server"
}
```

### Correct hooks/hooks.json

```json
{
  "description": "ReCursor bridge integration - forward events to mobile app",
  "hooks": {
    "SessionStart": [...],
    "SessionEnd": [...],
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...],
    "UserPromptSubmit": [...],
    "Notification": [...],
    "SubagentStop": [...]
  }
}
```

## Verification Commands

### To Test Locally
```bash
# Navigate to ReCursor project
cd C:/Repository/ReCursor

# Test with --plugin-dir flag
claude --plugin-dir ./packages/claude-plugin
```

### To Verify Installation
```bash
# Inside Claude Code session
/plugin
# Should list "recursor-bridge" among installed plugins if properly structured
```

## Recommendations

1. **Create missing `.claude-plugin/plugin.json`** manifest file (CRITICAL)
2. **Move `hooks.json` to `hooks/hooks.json`** subdirectory (CRITICAL)
3. **Update installation docs** to reference correct path (`~/.claude/plugins/` not `~/.claude-code/plugins/`) (CORRECTION)
4. **Document verification steps**: After installation, run `/plugin` to verify (BEST PRACTICE)
5. **Consider**: If this is hooks-only functionality, distributing via user settings (`.claude/settings.json`) might be simpler than a full plugin (ALTERNATIVE)

## Open Questions (Undocumented Behavior)

| Question | Status | Evidence |
| -------- | ------ | -------- |
| Does copy-install (cp -r) to `~/.claude/plugins/` work without using `/plugin install`? | **Unofficial** | No docs found; `--plugin-dir` is the documented local dev method |
| Is `~/.claude-code/` a valid alternative directory? | **Unverified** | All evidence points to `~/.claude/` (no hyphen) |
| Can hooks.json work at plugin root without subdirectory? | **No** | Official examples always show `hooks/hooks.json` structure |

## References

1. **Claude Code Plugin Development Docs:** `C:/Repository/claude-code/plugins/plugin-dev/skills/plugin-structure/SKILL.md`
2. **Hook Development Docs:** `C:/Repository/claude-code/plugins/plugin-dev/skills/hook-development/SKILL.md`
3. **Minimal Plugin Example:** `C:/Repository/claude-code/plugins/plugin-dev/skills/plugin-structure/examples/minimal-plugin.md`
4. **Standard Plugin Example:** `C:/Repository/claude-code/plugins/plugin-dev/skills/plugin-structure/examples/standard-plugin.md`
5. **Hookify Plugin (Reference Implementation):** `C:/Repository/claude-code/plugins/hookify/`
6. **Official Documentation:** https://docs.claude.com/en/docs/claude-code/plugins (linked in multiple READMEs)
7. **Upstream Repository:** https://github.com/anthropics/claude-code

## Files Modified

None (research-only task)

---
*Generated by Researcher Agent | ReCursor Research Artifact*
