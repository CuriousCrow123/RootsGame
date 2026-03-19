---
title: "feat: Tailor Compound Engineering for Godot 4"
type: feat
status: superseded-by-godot-compound-plugin-plan
date: 2026-03-19
deepened: 2026-03-19
---

# feat: Tailor Compound Engineering for Godot 4

## Enhancement Summary

**Deepened on:** 2026-03-19
**Sections enhanced:** 4 (Steps 7-10, all Phase B)
**Research agents used:** 6 (gdscript-reviewer design, architecture-reviewer design, resource-safety-reviewer design, compound-godot schema, CE agent authoring best practices, Godot 4.6 review patterns)

### Key Improvements
1. **Concrete agent blueprints**: Each Phase B agent now has numbered review principles with FAIL/PASS GDScript examples, priority ordering, scope boundaries, and a target token budget (90-120 lines, ~900 tokens)
2. **Compound schema roadmap**: Full provisional enum replacement tables (problem_type, component, root_cause, resolution_type) mapped from CE's Cora schema to Godot domains, with incremental adoption strategy
3. **Cross-agent scope boundaries**: Clear ownership matrix prevents gdscript-reviewer, architecture-reviewer, and resource-safety-reviewer from overlapping — each agent's territory is explicitly defined
4. **New tooling discoveries**: graydwarf/godot-gdscript-linter for complexity detection, GUT 9.6.0 + godot-code-coverage for testing, pre-commit hook integration for gdtoolkit

### New Considerations Discovered
- Agent body should NOT restate CLAUDE.md rules — instead embed opinionated FAIL/PASS interpretations (avoids token waste and drift)
- `Resource.duplicate(true)` does NOT deep-copy Array/Dictionary subresources (Godot bug #74918) — resource-safety-reviewer must flag this
- `architecture-strategist` (CE built-in) produces generic output due to no FAIL/PASS examples — monitor and potentially remove from `review_agents`
- Schema should include `schema_version` from day one and `node_types` optional field for grep-based retrieval
- Godot 4.6 Node UIDs reduce scene refactoring breakage but don't eliminate it — resource-safety-reviewer still needed

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

#### Research Insights: gdtoolkit Rule Inventory

**gdlint's 24 rules (3 categories):**

*Naming Checks (14 rules):* `function-name`, `class-name`, `sub-class-name`, `signal-name`, `class-variable-name`, `class-load-variable-name`, `function-variable-name`, `function-preload-variable-name`, `function-argument-name`, `load-constant-name`, `loop-variable-name`, `enum-name`, `enum-element-name`, `constant-name`. All configurable via regex patterns in `.gdlintrc`.

*Format Checks (3 rules):* `max-line-length` (default 100), `max-file-lines`, `trailing-whitespace`.

*Design Checks (7 rules):* `class-definitions-order` (member ordering — most important for team enforcement), `function-arguments-number` (default max 10), `no-elif-return`, `no-else-return`, `unnecessary-pass`, `duplicated-load`, `comparison-with-itself`, `private-method-call` (flags external calls to `_private` methods).

**Most important for team enforcement:** `class-definitions-order`, `max-line-length`, all naming rules, `duplicated-load`.

**Secondary Linting Tool Discovered:**
[graydwarf/godot-gdscript-linter](https://github.com/graydwarf/godot-gdscript-linter) (Feb 2026, MIT) — in-editor plugin detecting long functions, high cyclomatic complexity, magic numbers, missing type hints. Has CLI mode for CI. Consider evaluating as a complement to gdtoolkit after Phase A is stable.

**CI/CD Integration:**
gdtoolkit ships pre-commit hooks. Add to `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/Scony/godot-gdscript-toolkit
    rev: 4.3.3
    hooks:
      - id: gdformat
      - id: gdlint
```

**Testing Framework (for future consideration):**
GUT 9.6.0 targets Godot 4.6 specifically. Command-line runner: `godot --headless -s addons/gut/gut_cmdln.gd`. Coverage via [jamie-pate/godot-code-coverage](https://github.com/jamie-pate/godot-code-coverage). Produces JUnit XML for CI reporting.

### `.tscn` Safety

Scene files have strict structure (five ordered sections, unique ext_resource IDs, specific serialization format). Naive agent edits corrupt scenes. Rule: `.tscn` files are **read-only for all agents**. Resource-safety-reviewer (Phase B) reads and reports but never edits.

### Compound Knowledge During Phase A

The compound-godot schema is deferred to Phase B. If `/ce:compound` fires during Phase A, it uses CE's default Cora-specific schema. Solution docs will have ill-fitting categories (`rails_model`, `hotwire_turbo`, etc.). Mitigation: document in `compound-engineering.local.md` body that compound docs created before Phase B will need re-categorization.

### Godot Version Gating

Minimum: Godot 4.3. `.uid` sidecar features require 4.4+. Phase B agents that check `.uid` files must read Godot version from `project.godot`'s `config/features` key and skip `.uid` checks if < 4.4.

#### Research Insights: Godot 4.6 Specifics

This project targets Godot 4.6.1. Key 4.6 changes affecting review agents:
- **Node UIDs** — Nodes now have unique internal IDs in `.tscn` files. Renaming/moving nodes no longer breaks inherited scene references. This reduces (but does not eliminate) resource-safety-reviewer's workload.
- **No GDScript language changes** in 4.6 vs. 4.4. Static typing enforcement works identically.
- **ObjectDB debugger** can compare snapshots/diffs to track object lifetimes — useful for debugging resource sharing issues.
- **Jolt physics is the default** for new 3D projects (not relevant for this 2D RPG).
- **Glow post-processing change** is the only real breaking change (screen blending mode before tone-mapping). Not relevant for 2D RPG unless using glow effects.

Version gating implementation: Read `project.godot`, find `config/features=PackedStringArray("4.6", "GL Compatibility")`, extract first element as version string. Parse as float for comparison.

### Common Godot 4 RPG Bugs (from research)

Phase B review agents should be designed to catch these high-frequency bugs:
- **`Resource.duplicate(true)` does NOT deep-copy Array/Dictionary subresources** (bug #74918). Duplicating a Resource with `@export var items: Array[ItemResource]` leaves the array shared.
- **`queue_free()` during scene tree modification** causes corruption — use `call_deferred("queue_free")`.
- **Autoload EventBus signals persist across scene changes** — manual cleanup or `CONNECT_ONE_SHOT` needed.
- **Re-entrant state transitions** (state transitioning to itself without proper exit/enter) cause initialization bugs.
- **Save files referencing `res://` paths** break on file moves — save by UID or logical identifier.
- **`resource_local_to_scene` silently fails** with arrays, inherited scenes, and dynamic instantiation (multiple open engine issues).

### Phase B Agent Authoring Guidelines (from CE best practices research)

Cross-cutting guidance for all three Phase B review agents:

**Structure (from analysis of all 29 CE agents):**
- Frontmatter: only `name`, `description` (what + when), `model: inherit`. No `color` for review agents.
- Body: `<examples>` block (2-3 Godot trigger scenarios) → persona paragraph → 8-10 numbered principles with FAIL/PASS GDScript pairs → review procedure → closing philosophy.
- Target: 90-120 lines, ~800-1000 tokens. This is the sweet spot from the Kieran agents (115-133 lines).

**What makes reviews actionable (from comparing effective vs. weak CE agents):**
- Inline FAIL/PASS code examples anchored to specific GDScript patterns (not abstract advice)
- Asymmetric strictness: "Be very strict on existing code modifications, pragmatic on new isolated code"
- Named heuristics ("5-second rule" for naming clarity) give the agent calibrated thresholds
- "Always explain WHY something doesn't meet the bar" — prevents drive-by complaints
- Persona with strong opinions, not just a job title

**What does NOT work:**
- Generic checklists without code examples (security-sentinel pattern)
- Abstract principles like "Check for proper abstraction levels" (architecture-strategist is the weakest CE agent for this reason)
- Restating CLAUDE.md rules verbatim (wastes tokens, creates drift risk)
- Over-specified output templates (get flattened by `/ce:review` synthesis anyway)

**Cross-agent scope ownership matrix:**

| Check domain | gdscript-reviewer | architecture-reviewer | resource-safety-reviewer | gdscript-lint |
|---|---|---|---|---|
| Static typing | **Owns** | — | — | — |
| Member ordering | **Owns** | — | — | Also checks |
| Naming conventions | **Owns** | — | — | Also checks |
| Signal architecture | **Owns** (code-level) | **Owns** (system-level) | — | — |
| Scene composition | — | **Owns** | — | — |
| `_process` abuse | — | **Owns** | — | — |
| `res://` path integrity | — | — | **Owns** | — |
| `.tscn` structure | — | — | **Owns** | — |
| Resource sharing | **Owns** (code-level) | — | **Owns** (file-level) | — |
| Node path fragility | — | Evaluates pattern | Flags structural risk | — |
| Formatting | — | — | — | **Owns** |

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
- [ ] Each review agent is 90-120 lines with FAIL/PASS GDScript examples (not abstract checklists)
- [ ] No scope overlap between agents — each finding attributed to exactly one agent
- [ ] gdscript-reviewer catches: untyped vars, wrong member ordering, bad naming, Resource mutation without `.duplicate()`
- [ ] architecture-reviewer catches: "call up" violations, deep inheritance, `_process` polling, EventBus overuse
- [ ] resource-safety-reviewer catches: broken `res://` paths, missing `.uid` sidecars, `.tscn` section ordering violations
- [ ] compound-godot schema includes `schema_version` and `node_types` optional field
- [ ] Resolution template uses `gdscript` code fences and "Scene changes (manual)" section

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

##### Research Insights

**Agent Structure (from CE agent authoring analysis):**
- Frontmatter: `name: gdscript-reviewer`, `description: "..."`, `model: inherit` (not haiku — code review requires reasoning quality)
- Body structure: `<examples>` block (3 Godot trigger scenarios) → persona paragraph → 10 numbered principles → review procedure → closing philosophy
- Target: 90-120 lines, ~900 tokens. The Kieran agents hit 115-133 lines and produce the most actionable output of all CE review agents.
- Do NOT restate CLAUDE.md rules — embed opinionated FAIL/PASS interpretations instead. CLAUDE.md is already in context; the agent adds calibration.

**10 Review Principles (priority-ordered):**

1. **Critical Deletions & Regressions** — Signal disconnections, `@export` removals that break inspector values in `.tscn`, `class_name` changes that break type references.
2. **Static Typing Discipline** — Project sets UNTYPED_DECLARATION=Error; untyped code won't run. Flag: `var health = 100` (FAIL) → `var health: int = 100` (PASS). Flag: `var result = array.pop_back()` (FAIL, Variant return) → `var result: String = array.pop_back()` (PASS). `:=` acceptable when RHS type is unambiguous.
3. **Resource Safety** — Flag `.tres` mutation without `.duplicate()`: `preload("res://stats.tres").health = 50` (FAIL) → `preload("res://stats.tres").duplicate().health = 50` (PASS). Flag dynamic `load("res://" + var)`. Flag `resource_local_to_scene` (unreliable — known engine bugs in arrays and inherited scenes).
4. **Signal Architecture** — "Call down, signal up." Flag: `get_parent().die()` in child (FAIL) → `health_depleted.emit()` (PASS). Flag: sibling-to-sibling `$"../SiblingB".method()` (FAIL) → parent wires with `connect()` (PASS). Flag EventBus for parent-child communication.
5. **Composition & Scene Architecture** — Flag multi-layer custom inheritance: `class BossFlyingEnemy extends FlyingEnemy` (FAIL) → derive from engine types + compose via child nodes (PASS). Flag monolithic scripts >200 lines handling multiple responsibilities.
6. **Member Ordering** — Enforce canonical GDScript sequence (signals → enums → constants → @export → public → _private → @onready → virtuals → callbacks → public methods → private methods). Flag out-of-order sections.
7. **Naming Conventions (5-Second Rule)** — Flag: `var dead: bool` (FAIL) → `var is_dead: bool` (PASS). Flag: `signal damage(amount)` (FAIL) → `signal damage_taken(amount: int)` (PASS). Flag: `enum state { idle }` (FAIL) → `enum State { IDLE }` (PASS).
8. **Existing Code — Be Very Strict** — Added complexity to existing files needs justification. Prefer extracting to new child nodes over complicating existing scripts.
9. **New Code — Be Pragmatic** — Isolated new code that works is acceptable. Flag obvious improvements but don't block progress.
10. **Core Philosophy** — "Composition over Complexity. The scene tree is your architecture." Nodes are cheap, abstraction is expensive. Duplication over inheritance. Explicit over implicit.

**Edge Cases to Catch:**
- `@onready var sprite: Sprite2D = $Node as Sprite2D` silently returns `null` if type doesn't match — flag `as` casts on `@onready` without null guard
- Emitting signals in `_ready()` is unsafe (listeners may not be ready) — flag without `call_deferred()`
- `super()` forgotten in overridden virtual methods — silently drops parent behavior
- `class_name` pollution — registering `class_name` for internal-only scripts pollutes the global namespace
- Exported Resource arrays (`@export var effects: Array[StatusEffect]`) mutated at runtime without duplicating each element

**RPG-Specific Anti-Patterns:**
- The God Autoload (single autoload holding player state, inventory, quest state, battle state)
- The Inheritance Taxonomy (`Entity > Character > Enemy > BossEnemy > FinalBoss`)
- The Signal Spaghetti Bus (40+ EventBus signals including `player_moved`, `enemy_spawned`)
- The Monolithic Battle Script (800+ line `BattleManager.gd`)
- String-based state machines (`var state: String = "idle"` instead of enums)

#### Step 8: godot-architecture-reviewer agent
- **Trigger:** After 3+ scenes with inter-scene communication
- Combined architecture + performance reviewer (split later if profiling becomes a real concern)
- Covers: composition over inheritance, "call down signal up", scene encapsulation, `_process` abuse, autoload discipline, typed arrays, object pooling
- Version-gates `.uid` checks (read Godot version from `project.godot` `config/features`)
- After creation: add to `compound-engineering.local.md` `review_agents` list
- **Files:** `.claude/agents/godot-architecture-reviewer.md`

##### Research Insights

**Agent Structure:**
- Frontmatter: `name: godot-architecture-reviewer`, `description: "Reviews Godot 4 scene architecture, communication patterns, and performance. Use when adding new scenes, signals, autoloads, or refactoring scene trees."`, `model: inherit`
- Target: 90-120 lines. Use persona with strong opinions ("scene tree is your architecture, not a convenience").

**Review Checklist (3 priority tiers):**

**P0 — Structural Rules (Hard Violations):**
1. **"Call down, signal up" violations** — Detect via grep patterns: `get_parent()\.`, `owner\.`, `\$"\.\./`, `get_node("\.\.")`. Child calling parent methods = violation. Flag sibling-to-sibling coupling: `$"../SiblingNode".method()`.
2. **Scene inheritance depth** — Map inheritance graph by grepping `extends <CustomClassName>` across `.gd` files. Flag any script that extends a custom class that itself extends a custom class (2+ custom layers).
3. **Event Bus misuse** — List all `EventBus.*.emit()` and `EventBus.*.connect()` sites. Flag any pair where both are in the same scene subtree.
4. **Autoload discipline** — Flag autoloads holding entity-level state (player inventory, equipped items). Autoloads should be limited to: EventBus, GameState, SaveManager, AudioManager, SceneTransition.

**P1 — Performance Architecture (Static Detection):**
5. **`_process` abuse** — Flag `_process` bodies that start with an early-return guard checking null/boolean (polling pattern). Flag `Input.is_action_just_pressed` in `_process` (should use `_unhandled_input`). Heuristic regex: `func _process.*:\n\s+if .*(== null|not |is_dead).*:\n\s+return`.
6. **Unbounded instantiation** — Flag `.instantiate()` calls inside `_process`/`_physics_process` without pooling or lifecycle management. Note: only flag high-frequency spawning, not one-off instantiation in event handlers.
7. **Signal connection leaks** — Flag `.connect()` on dynamically created nodes without corresponding `.disconnect()` or `CONNECT_ONE_SHOT`. Especially dangerous with EventBus connections on freeable nodes.
8. **Typed arrays** — Flag `var enemies = []` (untyped) and `var items: Array = []` (unparameterized). PASS: `var enemies: Array[Enemy] = []`.

**P2 — Design Quality (Soft Guidance):**
9. **Scene encapsulation** — Flag external code reaching into scene internals: `$Enemy/Components/HealthComponent.health` (FAIL) → `enemy.get_health()` (PASS). Flag `get_node()` paths with 3+ segments.
10. **Component design** — Flag scripts with too many responsibilities. Metric: monolithic scripts handling movement, combat, animation, and sound.

**Scene Hierarchy Metrics (for read-only .tscn analysis):**

| Metric | Good | Yellow | Red |
|--------|------|--------|-----|
| Scene tree depth | 1-4 levels | 5-6 levels | 7+ |
| Nodes per scene | 1-15 | 16-30 | 30+ |
| Script inheritance layers | 0-1 custom | 2 custom | 3+ |
| Scripts per scene | 1-3 | 4-6 | 7+ |

**Version Gating Implementation:**
Read `project.godot`, find `config/features=PackedStringArray("4.6", ...)`, extract version string (first element). If version < 4.4, skip all `.uid`-related checks. For >= 4.4, verify `.uid` sidecar consistency.

**Scope Boundaries (what this agent does NOT review):**
- Variable naming, formatting, member ordering → gdscript-reviewer
- `res://` path integrity, `.tscn` structural validation, `.uid` sidecar checks → resource-safety-reviewer
- gdformat/gdlint violations → gdscript-lint
- This agent reviews **how systems are composed and communicate** — not how code is written or how files are structured

#### Step 9: resource-safety-reviewer agent
- **Trigger:** After first `.tres` and `.tscn` files exist
- Combined resource integrity + scene structure reviewer
- Covers: `res://` references, dynamic `load()` warnings, `.uid` sidecars (version-gated), Resource sharing (`.duplicate()`), `.tscn` five-section ordering, ext_resource validity, node path fragility
- Declares `.tscn` read-only in instructions (reads and reports, never edits)
- Warns about binary `.res` files it can't inspect
- After creation: add to `compound-engineering.local.md` `review_agents` list
- **Files:** `.claude/agents/resource-safety-reviewer.md`

##### Research Insights

**Agent Structure:**
- Frontmatter: `name: resource-safety-reviewer`, `description: "Reviews Godot resource integrity, scene structure, and res:// reference safety. Use when adding .tres/.tscn files, moving resources, or modifying resource loading."`, `model: inherit`
- This agent is more analytical than persona-based — it performs systematic file cross-referencing. Structure as: prerequisites → check phases → report format.

**Review Dimensions (severity-ordered):**

**CRITICAL (causes crashes or data loss):**
1. **Broken `res://` references** — Grep `res://[^\s"',)\]]+` across .gd/.tscn/.tres/.cfg/project.godot. Map `res://` to project root. Verify each path exists on disk.
2. **`ext_resource` path mismatch** — Extract `path="res://..."` from `[ext_resource]` lines in .tscn/.tres. Cross-reference against filesystem. Report missing files grouped by scene.
3. **Missing `.uid` sidecars** (Godot 4.4+) — For each .gd/.tscn/.tres file (excluding .godot/ and addons/), check that `filename.uid` exists alongside it.
4. **`.tscn` structural corruption** — Read-only validation of five-section ordering: (1) `[gd_scene]` header, (2) `[ext_resource]` entries, (3) `[sub_resource]` entries, (4) `[node]` entries, (5) `[connection]` entries. Verify `ext_resource` ID uniqueness. Verify `load_steps` = ext_resources + sub_resources + 1.

**HIGH (causes runtime bugs):**
5. **Shared Resource mutation** — Grep for `preload("...tres")` and `load("...tres")` without `.duplicate()` on same/next line. Flag `@export var x: SomeResource` where the script mutates `x.property = value` without prior `.duplicate()`. **Critical detail: `Resource.duplicate(true)` does NOT deep-copy Array/Dictionary subresources** (Godot bug #74918) — flag `.duplicate()` on Resources containing exported Arrays.
6. **Dynamic `load()` with concatenation** — Grep: `load(\s*"res://" \s*\+` and `load(\s*[a-zA-Z_]` (variable argument). These are invisible to static analysis and break on rename.
7. **Hardcoded deep node paths** — Grep: `get_node\(\s*"(\.\./){2,}` (2+ parent traversals) and `\$[^%].*\/.*\/` (3+ segments). Flag as fragile.

**MEDIUM (maintenance risk):**
8. **Orphaned `.uid` sidecars** — `.uid` file exists but parent resource was deleted.
9. **Binary `.res` files** — Glob `**/*.res`, flag as uninspectable by text tools.
10. **`load()` where `preload()` works** — Static string passed to `load()` instead of `preload()` loses compile-time checking.

**`.tscn` Five-Section Structure (reference):**
```
Section 1: [gd_scene load_steps=N format=3 uid="uid://..."]
Section 2: [ext_resource type="..." uid="uid://..." path="res://..." id="1_abc"]
Section 3: [sub_resource type="..." id="SubResource_xyz"]
Section 4: [node name="Root" type="Node2D"]  (root has no parent attr)
Section 5: [connection signal="pressed" from="Button" to="." method="_on_pressed"]
```

**Agent Workflow (3 phases):**
1. **Collection**: Glob all .gd/.tscn/.tres/.cfg/.uid/.res files (excluding .godot/ and addons/)
2. **Per-dimension scan**: Run each check category using Grep/Read/Bash
3. **Report**: Group findings by severity (CRITICAL → HIGH → MEDIUM → LOW) with file paths and line numbers

**Scope Boundaries:**
- Owns: `res://` path integrity, `.tscn`/`.tres` structural validation, `.uid` consistency, resource sharing analysis, binary `.res` flagging, `project.godot` path references
- Does NOT own: GDScript style/naming (gdscript-reviewer), scene design patterns (architecture-reviewer), formatting (gdscript-lint)
- Overlap boundary with architecture-reviewer: node path fragility (`get_node("../../...")`) — this agent flags the structural risk, architecture-reviewer evaluates the communication pattern

#### Step 10: compound-godot skill + schema
- **Trigger:** After solving 3-5 real Godot problems worth documenting
- Use CE's `compound-docs/schema.yaml` as the structural template. Replace Cora-specific enums with values derived from the actual problems encountered — do not pre-define categories speculatively.
- Create `docs/solutions/` category directories based on the problems that actually recur, not a predetermined taxonomy.
- **Files:** `.claude/skills/compound-godot/SKILL.md`, `schema.yaml`, `assets/resolution-template.md`

##### Research Insights

**Schema Design Strategy:**
- Add `schema_version: 1` from day one to support non-breaking growth.
- The full enum lists below are the **universe of likely values** to draw from — the initial schema should contain ONLY values needed for the first 3-5 actual problems, plus 2-3 obvious near-neighbors.
- Never add `other` as an enum value — it defeats categorization. When a problem doesn't fit, that's the signal to add a new enum value.
- Enum extension is always additive — never rename or remove existing values.
- Add `node_types` optional field (array of Godot node type names, e.g., `["CharacterBody2D", "Area2D"]`) for grep-based retrieval.

**Provisional Enum Tables (reference universe — derive actual schema from real problems):**

**`problem_type` (replaces CE's 13 values):**

| Value | Replaces CE | Description |
|---|---|---|
| `parse_error` | `build_error` | GDScript parse errors, shader compilation, scene load failures |
| `runtime_error` | (kept) | Null access, invalid paths, assertion failures |
| `performance_issue` | (kept) | Process abuse, scene tree bloat, untyped hotpaths |
| `scene_corruption` | (new) | `.tscn` damaged by edits, merges, UID mismatches |
| `resource_error` | (new) | `.tres`/`.res` loading, sharing bugs, circular references |
| `import_error` | (new) | Resource import pipeline failures |
| `ui_bug` | (kept) | Control node hierarchy, theme, focus, input |
| `signal_issue` | (new) | Signal connection/disconnection, event bus misuse |
| `logic_error` | (kept) | Game logic: damage calc, state machines, turn order |
| `integration_issue` | (kept) | MCP, GDExtension, addon, editor-to-runtime gaps |
| `developer_experience` | (kept) | Tooling, editor setup, VS Code, linting |
| `workflow_issue` | (kept) | Git + `.tscn` conflicts, resource renaming, CI |
| `best_practice` | (kept) | Documenting patterns adopted |

Dropped: `test_failure` (add when GUT integrated), `database_issue`, `security_issue`, `documentation_gap` (fold into `best_practice`).

**`component` (replaces CE's 15 Cora-specific values):**

| Value | Replaces CE | Description |
|---|---|---|
| `scene_tree` | `rails_model` | Scene hierarchy, node composition, instantiation |
| `resource_system` | `rails_view` | `.tres`/`.res` files, Resource subclasses, preload/load |
| `signal_wiring` | `hotwire_turbo` | Signal connections, event bus, callable binding |
| `physics_collision` | `service_object` | CharacterBody2D, Area2D, collision layers/masks |
| `animation_system` | — | AnimationPlayer, AnimationTree, sprite frames |
| `navigation` | — | NavigationAgent2D, NavigationRegion2D, pathfinding |
| `tilemap` | — | TileMap layers, TileSet, terrain, atlas |
| `audio` | — | AudioStreamPlayer, bus routing |
| `input_system` | — | InputMap, InputEvent, action mapping |
| `ui_controls` | `frontend_stimulus` | Control nodes, themes, containers, focus |
| `autoload` | `authentication` | Autoloaded singletons, global state |
| `save_load` | `database` | Serialization, file I/O, game state persistence |
| `state_machine` | — | Player/NPC state machines (add when implemented) |
| `gdscript_tooling` | `testing_framework` | gdformat, gdlint, editor settings |
| `project_config` | `development_workflow` | project.godot, export presets, editor settings |

Start with engine systems (first 12) + tooling (last 2). Add game systems (`battle_system`, `dialog_system`, `inventory`) only as implemented.

**`root_cause` (replaces CE's 15 values):**

| Value | Replaces CE | Description |
|---|---|---|
| `resource_sharing` | `missing_include` | Shared Resource mutated without `.duplicate()` |
| `uid_mismatch` | — | `.uid` sidecar out of sync |
| `scene_structure_invalid` | — | `.tscn` section ordering violated |
| `circular_reference` | — | Resource ↔ PackedScene cycle |
| `node_path_fragile` | `missing_association` | Hardcoded `get_node()` path broken by reparenting |
| `signal_disconnected` | — | Signal not connected, connected to freed object |
| `autoload_order` | `async_timing` | Autoload initialization order dependency |
| `untyped_code` | — | Missing static typing causing runtime error |
| `logic_error` | (kept) | Algorithm/game logic bug |
| `api_misuse` | `wrong_api` | Deprecated or incorrect Godot API |
| `process_callback_abuse` | — | Unnecessary `_process`/`_physics_process` |
| `config_error` | (kept) | project.godot or editor setting wrong |
| `import_cache_stale` | — | `.import/` directory out of date |
| `missing_dependency` | — | Plugin, addon, or external tool not installed |

**`resolution_type` (replaces CE's 10 values):**

| Value | Replaces CE | Description |
|---|---|---|
| `code_fix` | (kept) | Changed GDScript source |
| `scene_fix` | `migration` | Modified `.tscn`/`.tres` in editor (agents can't do this — document what human must do) |
| `config_change` | (kept) | Changed project.godot, export presets, editor settings |
| `resource_fix` | — | Regenerated, re-imported, or restructured resources |
| `dependency_update` | (kept) | Updated addon, plugin, or tool version |
| `environment_setup` | (kept) | Installed/configured external tool |
| `workflow_improvement` | (kept) | Improved dev process |
| `architecture_change` | — | Restructured scene tree, signal wiring, or node composition |
| `pattern_adoption` | `documentation_update` | Adopted a Godot pattern |

**Category Directories:**
Do NOT pre-create. Create each `docs/solutions/<category>/` directory only when the first solution document targeting that category is written. Provisional mapping: `parse-errors/`, `runtime-errors/`, `performance-issues/`, `scene-corruption/`, `resource-errors/`, `import-errors/`, `ui-bugs/`, `signal-issues/`, `logic-errors/`, `integration-issues/`, `developer-experience/`, `workflow-issues/`, `best-practices/`.

**Resolution Template Changes (from CE's `resolution-template.md`):**
- Replace `rails_version` with `godot_version` (optional, pattern: `^\d+\.\d+(\.\d+)?$`)
- Add `node_types` optional field (array of Godot node types)
- Replace Ruby code fences with `gdscript`
- Replace "Database migration" subsection with "Scene changes (manual)" — what the human must change in the Godot editor since agents cannot edit `.tscn`
- Replace "Rails Version" in Environment section with "Godot Version" + "Renderer" (Forward+, Mobile, Compatibility)
- Add "Node Types" line to Environment section
- Keep overall document structure intact (Problem → Environment → Symptoms → What Didn't Work → Solution → Why This Works → Prevention → Related Issues — this structure is framework-agnostic)

**Retrieval Optimization:**
- `symptoms` must include exact Godot error messages verbatim — these are the highest-value grep targets (Godot errors are distinctive)
- `tags` should include: Godot error code (e.g., `UNSAFE_PROPERTY_ACCESS`), node types in lowercase-hyphenated form (`character-body-2d`), API method involved (`queue-free`), conceptual category (`resource-sharing`)
- `module` should use game system names developers think in ("Battle System", not "combat_manager.gd")

**Incremental Schema Growth Protocol:**
1. First 3-5 problems: build initial schema with only values used + 2-3 obvious near-neighbors
2. After 10 solutions: review whether any tags cluster into missing enum values
3. After 20 solutions: full schema review, potentially splitting broad categories
4. Version bump `schema_version` when adding enum values; old docs remain valid

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
| `Resource.duplicate(true)` doesn't deep-copy Arrays | H | H | resource-safety-reviewer must flag `.duplicate()` on Resources with exported Array fields. Document workaround: manually duplicate each element in `_ready()`. (Godot bug #74918) |
| Phase B agents produce generic web-dev advice | M | M | Calibrate with FAIL/PASS GDScript examples in agent body. Monitor output on first 3 reviews; adjust if Godot context from `compound-engineering.local.md` body is insufficient. |
| Review agent overlap causes duplicate findings | M | L | Scope ownership matrix (see Phase B Agent Authoring Guidelines) defines clear boundaries. `/ce:review` synthesizer deduplicates. |
| `architecture-strategist` (CE built-in) unhelpful for Godot | H | L | Monitor output in Phase A. Remove from `review_agents` list and replace with `godot-architecture-reviewer` once built. |

## Future Considerations

- **Phase B triggers in persistent memory**: Consider adding Phase B readiness checklist to Claude's memory system so it can proactively suggest building agents when triggers are met.
- **Godot 5.x**: All tooling targets Godot 4.x only. Version-gating in agents should make 5.x migration incremental.
- **Community Godot CE preset**: If this setup works well, it could become a shareable CE configuration for the Godot community (via `bunx @every-env/compound-plugin sync`).
- **gdtoolkit alternatives**: GDQuest's Rust-based GDScript formatter is faster but formatting-only (no linting). Monitor for a full Rust-based lint tool.
- **GUT integration**: GUT 9.6.0 targets Godot 4.6. After Phase B, consider adding a `gdscript-test-runner` agent using `godot --headless -s addons/gut/gut_cmdln.gd` with JUnit XML output for CI. Coverage via [jamie-pate/godot-code-coverage](https://github.com/jamie-pate/godot-code-coverage).
- **graydwarf/godot-gdscript-linter**: In-editor plugin with cyclomatic complexity detection and magic number flagging. Has CLI mode. Evaluate as a complement to gdtoolkit once Phase A is stable.
- **Custom `.tscn` validator**: No off-the-shelf `.tscn` validation tool exists (community proposal [godot-proposals#10196](https://github.com/godotengine/godot-proposals/issues/10196) is unimplemented). Consider building a lightweight Python script for CI that validates ext_resource paths, section ordering, and ID uniqueness.
- **Pre-commit hooks**: gdtoolkit's `.pre-commit-hooks.yaml` enables `gdformat` and `gdlint` as pre-commit hooks. Add after CI pipeline is established.

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
