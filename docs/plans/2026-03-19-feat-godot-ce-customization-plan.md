---
title: "feat: Tailor Compound Engineering for Godot 4"
type: feat
status: phase-a-complete
date: 2026-03-19
---

# feat: Tailor Compound Engineering for Godot 4

## Overview

Layer Godot-specific agents, skills, a compound schema, and MCP configuration on top of the Compound Engineering plugin (v2.38.1) so the Plan → Work → Review → Compound loop produces Godot-aware feedback instead of Rails/TypeScript defaults. Two-phase rollout: Phase A gives code-generation support from day one; Phase B adds review agents and compound knowledge as code accumulates.

## Problem Statement / Motivation

CE ships 29 agents tuned for web development. RootsGame is a Godot 4 + GDScript RPG. Without Godot-specific tooling:
- `/ce:review` dispatches agents that check for Rails conventions, N+1 queries, and Turbo/Stimulus patterns — none relevant
- Generated code may violate Godot patterns (untyped variables, deep inheritance, `_process` abuse, Resource sharing bugs)
- Compound knowledge capture uses Cora-specific enums (`brief_system`, `email_processing`) that don't map to Godot domains
- No automated GDScript linting — CE's lint agent runs `standardrb` and `erblint`

## Proposed Solution

### Two-Phase Rollout

**Phase A (build now — 6 artifacts):** Infrastructure for code generation.

| Artifact | Purpose |
|---|---|
| `CLAUDE.md` | Godot rules, static typing mandate, resource safety, `.tscn` read-only |
| `compound-engineering.local.md` | CE integration: `review_agents` list + Godot review context body |
| `.claude/skills/godot-patterns/` | Auto-loading skill with 3 reference files (composition, GDScript quality, resources) |
| `.claude/agents/gdscript-lint.md` + `.claude/skills/gdscript-lint/` | Automated gdformat + gdlint |
| `.mcp.json` | Context7 MCP (verify Godot coverage; add godot-mcp if needed) |
| `.gdlintrc` | gdlint configuration |

**Phase B (build incrementally):** Review agents and compound knowledge.

| Artifact | Trigger |
|---|---|
| `gdscript-reviewer` agent | After 5-10 `.gd` files |
| `godot-architecture-reviewer` agent | After 3+ scenes with inter-scene communication |
| `resource-safety-reviewer` agent | After first `.tres` and `.tscn` files |
| `compound-godot` skill + schema | After solving 3-5 real Godot problems |
| godot-mcp in `.mcp.json` | After `project.godot` exists (if not added in Phase A) |

### Why Layer, Not Fork

CE's workflow commands (`/ce:plan`, `/ce:work`, `/ce:review`, `/ce:compound`) are framework-agnostic. `/ce:review` dispatches agents from an explicit list in `compound-engineering.local.md`. Replacing that list with Godot agents is the intended customization path — no upstream modification needed.

## Technical Considerations

### CE Agent Dispatch Mechanism

`/ce:review` reads `compound-engineering.local.md` at the project root. YAML frontmatter contains `review_agents: [agent-name, ...]`. The command runs `Task {agent-name}(PR content)` for each. This is NOT description-based matching — agents must be explicitly listed.

**Blocking assumption:** `Task {agent-name}` must resolve agents from `.claude/agents/` (not just the plugin's `agents/` directory). This must be verified before Phase A is considered complete. Test procedure: create a dummy agent in `.claude/agents/test-resolution.md`, reference it in `compound-engineering.local.md`, run `/ce:review`.

### Agent Frontmatter Constraints

- Required fields: `name`, `description`
- Optional: `model` (inherit|haiku|sonnet|opus), `color`, `tools`, `disallowedTools`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`
- Plugin subagents CANNOT use `mcpServers`, `hooks`, or `permissionMode` — these are silently ignored. Agents in `.claude/agents/` CAN use them.
- There is NO `skills` frontmatter field. Domain knowledge must be embedded in the agent body or delivered via auto-loading skills (`user-invocable: false`).

### Skill Auto-Loading

Skills with `user-invocable: false` auto-load when their `description` matches the task context. The description must be specific enough to trigger on GDScript/Godot work but not on unrelated tasks. Target description for godot-patterns:

> "Godot 4 architectural patterns for GDScript scene composition, resource management, and signal-based communication. Use when generating, reviewing, or refactoring GDScript code or Godot scenes."

Reference files linked from SKILL.md load on demand (not counted against the 2% context budget at startup). Target: 150-250 lines each.

### GDScript Linting

gdtoolkit v4.x is the only reliable automated linting tool:
- `gdformat --check .` for formatting violations
- `gdlint .` for 24 lint rules (member ordering, naming, etc.)
- Install via `pipx install "gdtoolkit==4.*"` (NOT `pip3 install` — blocked by PEP 668 on modern macOS)
- Config file: `.gdlintrc` at project root (with dot prefix for auto-discovery)
- Exclude `addons/` and `.godot/` (exact directory names, not globs)

**Do NOT use `godot --check-only` for agent linting:**
- Hangs on errors (drops into interactive debugger in headless mode)
- Does not resolve autoloads → false "Identifier not found" errors
- GDScript warnings (UNSAFE_*, UNTYPED_DECLARATION) not emitted via CLI

### `.tscn` Safety

Scene files have strict structure (five ordered sections, unique ext_resource IDs, specific serialization format). Naive agent edits corrupt scenes. Rule: `.tscn` files are **read-only for all agents**. Resource-safety-reviewer (Phase B) reads and reports but never edits.

### Compound Knowledge During Phase A

The compound-godot schema is deferred to Phase B. If `/ce:compound` fires during Phase A, it uses CE's default Cora-specific schema. Solution docs will have ill-fitting categories (`rails_model`, `hotwire_turbo`, etc.). Mitigation: document in `compound-engineering.local.md` body that compound docs created before Phase B will need re-categorization.

### Godot Version Gating

Minimum: Godot 4.3. `.uid` sidecar features require 4.4+. Phase B agents that check `.uid` files must read Godot version from `project.godot`'s `config/features` key and skip `.uid` checks if < 4.4.

## Integration Risks

All customization is file-based configuration — no callbacks, middleware, or runtime side effects.

- **Single fragile state file**: `compound-engineering.local.md` controls agent dispatch. If `/ce:setup` overwrites it, Godot agents disappear. Mitigation: CLAUDE.md warning.
- **MCP and tooling failures are non-fatal**: Context7 or godot-mcp going down doesn't cascade. gdtoolkit failure is contained to the lint agent. Agents fall back to file reading.
- **Generic CE agents may ignore Godot context**: `code-simplicity-reviewer` and `architecture-strategist` have web-centric system prompts. The `compound-engineering.local.md` body gives them Godot context, but it may not fully override their defaults. Monitor their output quality in Phase A — if unhelpful, remove from `review_agents` list.

## Acceptance Criteria

### Phase A

- [x] CLAUDE.md loaded in fresh session (test: ask about typing rules — should cite static typing mandate)
- [x] `compound-engineering.local.md` controls `/ce:review` dispatch (test: agents in list run, agents not in list don't)
- [x] godot-patterns skill auto-loads when discussing GDScript (test: skill appears in `/skills`, context available during code generation)
- [x] gdscript-lint agent runs gdformat + gdlint successfully (test: lint a deliberately mis-formatted `.gd` file)
- [x] gdscript-lint exits cleanly when no `.gd` files exist
- [x] Context7 MCP starts (test: `claude mcp list`)
- [x] **Blocking**: `.claude/agents/` agents resolvable by CE `Task` dispatch (test: `/ce:review` dispatches gdscript-lint)
- [x] `/ce:setup` warning documented in CLAUDE.md
- [x] CE's `/ce:plan`, `/ce:work`, `/ce:review`, `/ce:compound` still function
- [x] No CE upstream files modified

### Phase B (per agent, as built)

- [ ] Each new agent produces Godot-specific feedback on real code (not generic web-dev advice)
- [ ] `compound-engineering.local.md` updated with each new agent
- [ ] compound-godot schema enums match real problems encountered
- [ ] `.uid` checks version-gated (skip on Godot < 4.4)

## Success Metrics

- Claude generates statically-typed GDScript by default without prompting
- `/ce:review` produces actionable Godot-specific feedback (no Rails/TS noise)
- Compound knowledge captures Godot solutions with findable categories
- gdscript-lint catches formatting and style violations before commits

## Dependencies & Prerequisites

- **Compound Engineering plugin** v2.38.1+ installed
- **pipx** available (`brew install pipx` on macOS)
- **gdtoolkit** v4.x installed via pipx
- **Node.js** 18+ (for Context7 MCP via npx)
- **Godot** 4.3+ installed (for Phase B godot-mcp; not required for Phase A)

## Implementation Phases

### Phase A: Foundation (build now)

#### Step 1: Verify blocking assumption
- Create `.claude/agents/test-resolution.md` (trivial agent with name + description)
- Create temporary `compound-engineering.local.md` with `review_agents: [test-resolution]`
- Run `/ce:review` on any file
- Confirm `Task test-resolution(...)` resolves and runs
- If it fails: investigate alternative resolution (symlinks into plugin dir, or agents in plugin directory)
- Clean up test files after verification
- **Files:** `.claude/agents/test-resolution.md`, `compound-engineering.local.md` (temporary)

#### Step 2: Create CLAUDE.md
- Godot 4 + GDScript project declaration, minimum version 4.3
- Static typing mandate (all vars must be typed, `UNTYPED_DECLARATION` = Error in project settings)
- Composition-over-inheritance, "call down, signal up"
- Resource safety: never raw `mv`/`git mv` on resource files; always update `res://` refs
- `.tscn` files are read-only for agents (no naive edits — corrupt scene structure)
- gdtoolkit lint requirement before commits (`pipx install "gdtoolkit==4.*"`)
- Context7 auto-invocation for Godot API lookups
- Warning: do NOT run `/ce:setup` — it overwrites `compound-engineering.local.md` with web-stack defaults
- Phase B readiness triggers (brief checklist of when to build each deferred agent)
- **Files:** `CLAUDE.md`

#### Step 3: Create `compound-engineering.local.md`
- YAML frontmatter: `review_agents: [gdscript-lint, code-simplicity-reviewer, architecture-strategist]`
- YAML frontmatter: `plan_review_agents: [code-simplicity-reviewer, architecture-strategist]`
- Markdown body: "This is a Godot 4 + GDScript RPG. Evaluate architecture in terms of scene composition, signal-based communication, and Godot-specific patterns. Ignore web, Rails, and TypeScript conventions. Static typing is mandatory. `.tscn` files must not be edited by agents."
- Note: compound docs created before Phase B compound-godot schema will use default CE categories and may need re-categorization.
- **Files:** `compound-engineering.local.md`

#### Step 4: Initialize infrastructure
- Create `.claude/agents/` and `.claude/skills/` directories
- Create `.mcp.json` with Context7 (stdio transport: `npx -y @upstash/context7-mcp@latest`)
- Verify Context7 Godot coverage: run `resolve-library-id godot` — if poor, add godot-mcp to `.mcp.json` now (don't defer to Phase B)
- Generate `.gdlintrc` via `gdlint --dump-default-config`, add `excluded_directories: [".godot", "addons"]`
- **Files:** `.mcp.json`, `.gdlintrc`

#### Step 5: Create godot-patterns skill
- SKILL.md with `user-invocable: false` and specific description (see Technical Considerations)
- Three reference files (150-250 lines each) extracted from `docs/reference/godot-best-practices.md`:
  - `scene-architecture.md` — composition, signals, dependency injection, scene unique nodes, groups
  - `gdscript-quality.md` — member ordering, naming conventions, typing rules, pattern usage
  - `resource-system.md` — `res://` paths, `.uid` files, Resource sharing pitfalls, `.duplicate()`, `.tres` vs `.res`
- Reference files linked from SKILL.md via markdown links (not backticks)
- Do NOT duplicate content already in CLAUDE.md — skill provides deeper reference material
- **Files:** `.claude/skills/godot-patterns/SKILL.md`, `scene-architecture.md`, `gdscript-quality.md`, `resource-system.md`

#### Step 6: Create gdscript-lint agent + skill
- Agent frontmatter: `name: gdscript-lint`, `model: haiku`, `color: yellow`
- Description: "Run GDScript linting and formatting checks using gdtoolkit. Use before committing GDScript code or when checking code style compliance."
- Agent workflow: (1) check `which python3`, (2) check `which gdformat`, (3) glob for `.gd` files — exit cleanly if none, (4) `gdformat --check .` for formatting, (5) `gdlint .` for style rules, (6) auto-fix with `gdformat .` when requested
- Install instructions in agent body: `pipx install "gdtoolkit==4.*"`
- When invoked from review context: scope to changed files if file list is available; otherwise lint all
- Supporting skill: `.claude/skills/gdscript-lint/SKILL.md` with `disable-model-invocation: true` (manual invocation only — side effects)
- **Files:** `.claude/agents/gdscript-lint.md`, `.claude/skills/gdscript-lint/SKILL.md`

#### Phase A Smoke Test
After all artifacts are created:
1. Open new Claude Code session in RootsGame
2. Run `/agents` — confirm gdscript-lint appears
3. Run `/skills` — confirm godot-patterns and gdscript-lint appear
4. Ask Claude "What are the typing rules for this project?" — should cite CLAUDE.md static typing mandate
5. Create a deliberately mis-formatted `.gd` file, invoke gdscript-lint
6. Run `/ce:review` — confirm gdscript-lint, code-simplicity-reviewer, architecture-strategist dispatch

### Phase B: Review & Compound (build incrementally)

#### Step 7: gdscript-reviewer agent
- **Trigger:** After 5-10 `.gd` files exist and Claude generates code violating project patterns
- Follows kieran-rails-reviewer.md format: examples block, persona, review framework
- Embed critical godot-patterns knowledge directly in agent body (no `skills` frontmatter)
- Focus: static typing violations, member ordering, naming conventions, signal naming (past tense), boolean prefixes
- After creation: add to `compound-engineering.local.md` `review_agents` list
- **Files:** `.claude/agents/gdscript-reviewer.md`

#### Step 8: godot-architecture-reviewer agent
- **Trigger:** After 3+ scenes with inter-scene communication
- Combined architecture + performance reviewer (split later if profiling becomes a real concern)
- Covers: composition over inheritance, "call down signal up", scene encapsulation, `_process` abuse, autoload discipline, typed arrays, object pooling
- Version-gates `.uid` checks (read Godot version from `project.godot` `config/features`)
- After creation: add to `compound-engineering.local.md` `review_agents` list
- **Files:** `.claude/agents/godot-architecture-reviewer.md`

#### Step 9: resource-safety-reviewer agent
- **Trigger:** After first `.tres` and `.tscn` files exist
- Combined resource integrity + scene structure reviewer
- Covers: `res://` references, dynamic `load()` warnings, `.uid` sidecars (version-gated), Resource sharing (`.duplicate()`), `.tscn` five-section ordering, ext_resource validity, node path fragility
- Declares `.tscn` read-only in instructions (reads and reports, never edits)
- Warns about binary `.res` files it can't inspect
- After creation: add to `compound-engineering.local.md` `review_agents` list
- **Files:** `.claude/agents/resource-safety-reviewer.md`

#### Step 10: compound-godot skill + schema
- **Trigger:** After solving 3-5 real Godot problems worth documenting
- Use CE's `compound-docs/schema.yaml` as the structural template. Replace Cora-specific enums with values derived from the actual problems encountered — do not pre-define categories speculatively.
- Create `docs/solutions/` category directories based on the problems that actually recur, not a predetermined taxonomy.
- **Files:** `.claude/skills/compound-godot/SKILL.md`, `schema.yaml`, `assets/resolution-template.md`

## Alternative Approaches Considered

| Alternative | Pros | Cons | Why not |
|---|---|---|---|
| Fork CE plugin entirely | Full control over commands and agents | Lose upstream updates, maintenance burden, ~36k token duplication | Layering via `compound-engineering.local.md` is the intended customization path |
| Only add CLAUDE.md rules | Zero new files, immediate value | Passive guidance only — can't enforce patterns during review | Good for Phase A baseline; agents added in Phase B |
| Build a standalone Godot plugin | Clean separation from CE | Duplicates orchestration, compound knowledge loop, and context overhead | CE's workflow loop is the whole point |
| Use godogen skills directly | Already built for Godot with 850+ class API docs | Planning/execution only — no review, no compound knowledge | Missing the review/compound half of the loop |
| Build all agents upfront | Ready when code arrives | Over-engineering for zero files; prompts will be theoretical and need rewriting | Phase B avoids speculative agent design |

## Risk Analysis & Mitigation

| Risk | L | I | Mitigation |
|---|---|---|---|
| `.claude/agents/` not resolvable by CE Task dispatch | M | H | **Verify in Step 1 before proceeding.** Fallback: symlinks into plugin dir. |
| CE upstream update changes `compound-engineering.local.md` format | H | M | Pin CE version if needed. Test dispatch after updates. File is a documented CE feature. |
| Agent prompts hallucinate GDScript APIs | H | H | godot-patterns skill injects correct patterns; Context7 for API verification; agents instructed to verify against docs. |
| `/ce:setup` overwrites `compound-engineering.local.md` | M | M | CLAUDE.md warning with explanation. Setup skill offers Cancel option — risk is user choosing Reconfigure. |
| Context7 lacks Godot documentation | M | M | Verify in Step 4. Add godot-mcp immediately if coverage is poor. |
| Compound docs created during Phase A have misfit categories | M | L | Documented in `compound-engineering.local.md`. Re-categorize when Phase B schema arrives. |
| gdtoolkit version drift reformats codebase | L | H | Pin version in project docs. `gdformat --check` in CI catches drift. |
| Skill context budget exceeded | L | M | SKILL.md under 100 lines; reference files 150-250 lines, loaded on demand. |
| godot-mcp breaks or goes unmaintained | M | L | Pin version. Non-fatal — agents fall back to file reading. |

## Future Considerations

- **Phase B triggers in persistent memory**: Consider adding Phase B readiness checklist to Claude's memory system so it can proactively suggest building agents when triggers are met.
- **Godot 5.x**: All tooling targets Godot 4.x only. Version-gating in agents should make 5.x migration incremental.
- **Community Godot CE preset**: If this setup works well, it could become a shareable CE configuration for the Godot community (via `bunx @every-env/compound-plugin sync`).
- **gdtoolkit alternatives**: GDQuest's Rust-based GDScript formatter is faster but formatting-only (no linting). Monitor for a full Rust-based lint tool.

## Sources & References

### Internal References
- `docs/reference/godot-best-practices.md` — Godot 4 patterns (43 sources)
- `docs/reference/godot-vscode-claude-setup.md` — VS Code + Godot integration
- `docs/reference/claude-agent-tooling-reference.md` — CE architecture reference

### CE Plugin References (pattern templates)
- `~/.claude/plugins/cache/compound-engineering-plugin/.../agents/workflow/lint.md` — Model for gdscript-lint
- `~/.claude/plugins/cache/compound-engineering-plugin/.../agents/review/kieran-rails-reviewer.md` — Model for gdscript-reviewer
- `~/.claude/plugins/cache/compound-engineering-plugin/.../skills/compound-docs/SKILL.md` — Model for compound-godot
- `~/.claude/plugins/cache/compound-engineering-plugin/.../skills/compound-docs/schema.yaml` — Model for schema
- `~/.claude/plugins/cache/compound-engineering-plugin/.../commands/ce/review.md` — Agent dispatch mechanism
- `~/.claude/plugins/cache/compound-engineering-plugin/.../skills/setup/SKILL.md` — How `compound-engineering.local.md` is generated
- `~/.claude/plugins/cache/compound-engineering-plugin/.../skills/create-agent-skills/SKILL.md` — Skill authoring reference

### External References
- [Claude Code: Sub-agents](https://code.claude.com/docs/en/sub-agents) — Agent frontmatter reference
- [Claude Code: Skills](https://code.claude.com/docs/en/skills) — Skill authoring reference
- [Claude Code: MCP](https://code.claude.com/docs/en/mcp) — MCP scoping and configuration
- [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) — GDScript linting/formatting
- [godogen](https://github.com/htdt/godogen) — Godot Claude Code skills with lazy-loaded API docs
- [godot-mcp](https://github.com/Coding-Solo/godot-mcp) — Godot MCP server (2.5k stars)
- [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP) — Alternative Godot MCP server
