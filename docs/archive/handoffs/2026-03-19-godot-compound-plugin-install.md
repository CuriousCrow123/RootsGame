# Handoff: godot-compound Plugin Installation

**Date:** 2026-03-19
**Status:** Complete

## Goal

Install the `godot-compound` local plugin into Claude Code so that all `gc:*` commands, skills, and agents are persistently available in every session without passing CLI flags.

## Context

The plugin lives at `~/.claude/godot-compound/` and was authored as a Godot-focused fork of the compound-engineering plugin. It provides the Plan → Work → Review → Compound development loop adapted for Godot 4 + GDScript projects.

## Problems encountered and how they were solved

### 1. No `plugin add` command for local directories

The initial instruction was `claude /plugin add ~/.claude/godot-compound`, but this command doesn't exist. Claude Code's plugin CLI only supports:

- `claude plugin install <name>` — installs from a registered marketplace
- `claude --plugin-dir <path>` — loads a local plugin for one session only (not persistent)

**Solution:** Created a local marketplace wrapper that the plugin system can register and install from permanently.

### 2. plugin.json schema validation failure

`claude plugin validate` failed because the `author` field was a plain string:

```json
// Before (invalid)
"author": "Alan"

// After (valid)
"author": { "name": "Alan" }
```

**File changed:** `~/.claude/godot-compound/.claude-plugin/plugin.json`

### 3. marketplace.json schema discovery

There's no public documentation for the marketplace manifest schema. Figured it out by reverse-engineering the compound-engineering plugin's marketplace at `~/.claude/plugins/marketplaces/compound-engineering-plugin/.claude-plugin/marketplace.json`. Key requirements:

- `owner` must be an object with `name` (not a string)
- `plugins` must be an array of objects (not an object map)
- Each plugin entry needs a `source` field pointing to a relative directory containing `.claude-plugin/plugin.json`
- The source directory must follow `./plugins/<name>` convention

Multiple iterations were needed — `"source": "."` was rejected, and the final working structure required the plugin to live inside a `plugins/` subdirectory of the marketplace.

### 4. Keeping the plugin source editable

Rather than copying the plugin into the marketplace wrapper, used a symlink so edits to `~/.claude/godot-compound/` are immediately reflected:

```
~/.claude/godot-compound-marketplace/plugins/godot-compound → ~/.claude/godot-compound
```

## Final directory structure

```
~/.claude/
├── godot-compound/                          # The actual plugin (source of truth)
│   ├── .claude-plugin/
│   │   └── plugin.json                      # Plugin manifest
│   ├── CLAUDE.md
│   ├── agents/
│   │   ├── research/
│   │   │   ├── gc-best-practices-researcher.md
│   │   │   ├── gc-framework-docs-researcher.md
│   │   │   ├── gc-git-history-analyzer.md
│   │   │   ├── gc-learnings-researcher.md
│   │   │   └── gc-repo-research-analyst.md
│   │   ├── review/
│   │   │   ├── gc-code-simplicity-reviewer.md
│   │   │   └── gc-pattern-recognition-specialist.md
│   │   └── workflow/
│   │       ├── gc-bug-reproduction-validator.md
│   │       ├── gc-pr-comment-resolver.md
│   │       └── gc-spec-flow-analyzer.md
│   ├── commands/
│   │   ├── gc/
│   │   │   ├── brainstorm.md                # /gc:brainstorm
│   │   │   ├── compound.md                  # /gc:compound
│   │   │   ├── plan.md                      # /gc:plan
│   │   │   ├── review.md                    # /gc:review
│   │   │   └── work.md                      # /gc:work
│   │   ├── changelog.md
│   │   ├── deepen-plan.md
│   │   ├── generate_command.md
│   │   ├── heal-skill.md
│   │   ├── lfg.md
│   │   ├── report-bug.md
│   │   ├── reproduce-bug.md
│   │   ├── resolve_parallel.md
│   │   ├── resolve_todo_parallel.md
│   │   ├── slfg.md
│   │   └── triage.md
│   └── skills/
│       ├── brainstorming/
│       ├── compound-docs/
│       ├── create-agent-skills/
│       ├── document-review/
│       ├── file-todos/
│       ├── git-worktree/
│       ├── orchestrating-swarms/
│       ├── resolve-pr-parallel/
│       └── setup/
│
├── godot-compound-marketplace/              # Marketplace wrapper (thin shim)
│   ├── .claude-plugin/
│   │   └── marketplace.json                 # Marketplace manifest
│   └── plugins/
│       └── godot-compound -> ~/.claude/godot-compound  # Symlink
│
└── settings.json                            # Plugin registered here
```

## settings.json changes

The install added two entries:

```jsonc
// In enabledPlugins:
"godot-compound@godot-compound-marketplace": true

// In extraKnownMarketplaces (added automatically by `marketplace add`):
"godot-compound-marketplace": {
  "source": { /* local path reference */ }
}
```

## File contents for reproduction

### ~/.claude/godot-compound/.claude-plugin/plugin.json

```json
{
  "name": "godot-compound",
  "version": "0.1.0",
  "description": "Godot 4 + GDScript development tools. Agents, skills, and commands for the Plan → Work → Review → Compound loop.",
  "author": { "name": "Alan" },
  "license": "MIT",
  "repository": "https://github.com/CuriousCrow123/godot-compound",
  "keywords": ["godot", "gdscript", "game-development", "code-review", "workflow-automation", "knowledge-management"],
  "mcpServers": {
    "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" }
  }
}
```

### ~/.claude/godot-compound-marketplace/.claude-plugin/marketplace.json

```json
{
  "name": "godot-compound-marketplace",
  "owner": { "name": "Alan" },
  "metadata": { "description": "Local marketplace for godot-compound plugin", "version": "1.0.0" },
  "plugins": [
    {
      "name": "godot-compound",
      "description": "Godot 4 + GDScript development tools for the Plan, Work, Review, Compound loop.",
      "version": "0.1.0",
      "author": { "name": "Alan" },
      "tags": ["godot", "gdscript", "game-development"],
      "source": "./plugins/godot-compound"
    }
  ]
}
```

## Installation commands (for reproduction)

```bash
# 1. Fix plugin.json author field (if not already done)
# Edit ~/.claude/godot-compound/.claude-plugin/plugin.json
# Change "author": "Alan" → "author": { "name": "Alan" }

# 2. Validate the plugin
claude plugin validate ~/.claude/godot-compound

# 3. Create marketplace wrapper
mkdir -p ~/.claude/godot-compound-marketplace/.claude-plugin
mkdir -p ~/.claude/godot-compound-marketplace/plugins
ln -sf ~/.claude/godot-compound ~/.claude/godot-compound-marketplace/plugins/godot-compound
# Then write marketplace.json (see contents above)

# 4. Register marketplace and install
claude plugin marketplace add ~/.claude/godot-compound-marketplace
claude plugin install godot-compound

# 5. Verify (in a new session)
claude -p "Confirm you can see /gc:plan, /gc:work, /gc:review" --max-budget-usd 0.10
```

## Verification result

```
> Just confirm you can see the /gc:plan, /gc:work, and /gc:review commands.
YES, YES, YES
```

## Maintenance notes

- **Updating the plugin:** Edit files directly in `~/.claude/godot-compound/`. The symlink means changes are live immediately in the next session.
- **Version bumps:** Update `version` in both `plugin.json` and `marketplace.json` to keep them in sync.
- **Uninstalling:** `claude plugin uninstall godot-compound` then optionally `claude plugin marketplace remove godot-compound-marketplace`.
- **Do NOT run `/gc:setup`** — same warning as compound-engineering's `/ce:setup`. It auto-detects web stacks and would overwrite Godot-specific config.
