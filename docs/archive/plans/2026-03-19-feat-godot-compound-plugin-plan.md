---
title: "feat: Build godot-compound Plugin (CE Fork for Godot 4)"
type: feat
status: completed
date: 2026-03-19
deepened: 2026-03-19
origin: docs/brainstorms/2026-03-19-godot-ce-plugin-fork-brainstorm.md
---

# feat: Build godot-compound Plugin (CE Fork for Godot 4)

## Enhancement Summary

**Deepened on:** 2026-03-19 (round 1), 2026-03-19 (round 2: research-driven methodology)
**Sections enhanced:** 9 (Phase 1-5, Technical Approach, Risk Analysis, Research-Driven Methodology, Agent Template)
**Research agents used:** 9 (CE command internals, plugin structure, utility command audit, create-agent-skills review, simplicity/pattern review, Godot pattern sources, agent validation strategy, CE agent structure analysis, open-source Godot projects)

### Key Improvements (Round 1)
1. **Command rewrite specifics**: Line-by-line analysis of all 5 core commands — `brainstorm` needs zero changes, `compound` and `plan` are trivial (~5 spots each), `work` and `review` are moderate (~50-60 web-specific lines each)
2. **Plugin structure requirements**: Documented exact file layout (`.claude-plugin/plugin.json` mandatory, components at root), namespace behavior, marketplace distribution options (GitHub repo, local directory, official submission)
3. **YAGNI critique and phased delivery**: Simplicity review flagged 44 components for 5 source files as disproportionate — plan restructured with Phase 1A (fork+strip) as standalone deliverable, later phases built from researched Godot patterns
4. **Utility command audit**: 5 of 10 "keep" commands are truly stack-agnostic; 5 need `/ce:`→`/gc:` updates + web reference cleanup; `simplify` and `loop` don't exist as commands; `reproduce-bug` needs major rewrite
5. **Agent/skill authoring corrections**: Missing description strings for all 7 agents, gdscript-reviewer overloaded (cap at 7-8 principles), resource-safety-reviewer has workflow in agent body (move to command), godot-setup needs `disable-model-invocation: true`

### Key Improvements (Round 2)
6. **Research-driven methodology**: Concrete 4-step pipeline for building agents from documentation and community patterns instead of project-size gates. Source hierarchy, validation strategy, and agent template defined.
7. **CE agent template extracted**: Quantitative analysis of 4 CE review agents (Kieran, architecture-strategist, performance-oracle, code-simplicity) — frontmatter, structure, principle count, line budgets, FAIL/PASS formatting. Concrete template for Godot agents.
8. **Pattern source bibliography**: 43-source `godot-best-practices.md` covers 6 of 7 agent domains. Export/builds is the gap — requires dedicated research before writing godot-export-verifier.
9. **Validation without a codebase**: Synthetic test fixtures (one `.gd` per principle), cross-validation with gdtoolkit's 24 rules, and Context7 API verification replace project-size triggers.

### New Considerations Discovered (Round 1)
- `ce:brainstorm` is 100% stack-agnostic — can be used verbatim with only namespace rename
- Two proposed commands (`simplify`, `loop`) don't exist in CE's command directory — they may be skills or aliases
- Agent name conflicts between plugins are unresolved by the system — must use unique names or accept the risk
- Plugin CLAUDE.md is loaded as plugin instructions (like project CLAUDE.md) — useful for embedding Godot conventions
- `reproduce-bug.md` references `rails-console-explorer` and `appsignal-log-investigator` — needs near-total rewrite or removal for Godot

### New Considerations Discovered (Round 2)
- CE review agents have two structural archetypes: **code-quality** (Kieran-style: many principles, inline FAIL/PASS pairs, ~115 lines) and **analytical** (performance/architecture: fewer sections, structured output format, ~100-137 lines). Godot agents should match the archetype to their domain.
- FAIL/PASS examples in CE are **single-line inline snippets** with emoji prefixes (`🔴 FAIL:` / `✅ PASS:`), not multi-line code blocks. This is critical for staying within the 90-120 line budget.
- The existing `godot-best-practices.md` is the primary pattern source, but each FAIL/PASS example should cite its specific source (e.g., "GDQuest Signals Best Practices" or "Godot #74918") for traceability.
- gdtoolkit already covers formatting (24 rules) and some naming. Agents should focus on **architectural and semantic patterns** that linting tools cannot catch — composition violations, signal misuse, Resource mutation, timing bugs.

## Overview

Fork the Compound Engineering plugin (v2.38.1, 142 files, ~129k words) into `godot-compound` — a standalone Claude Code plugin for Godot 4 + GDScript development. Strip all web/Rails/TypeScript content, rewrite core commands with `/gc:` namespace, add Godot-specific review agents, and ship as an installable plugin for the Godot community.

This replaces the previous layering approach (see `docs/plans/2026-03-19-feat-godot-ce-customization-plan.md`, status: superseded) with a full fork that eliminates ~36k tokens of web-specific overhead and gives complete control over agent prompts.

## Problem Statement / Motivation

CE's Plan → Work → Review → Compound loop is genuinely valuable, but the web-specific content creates three problems for Godot projects:

1. **Token waste (~36k overhead):** Rails test examples, Figma sync, browser testing, database migration agents, DHH/Kieran persona reviewers all consume context even when skipped
2. **Wrong advice:** Web framing causes agents to suggest N+1 query checks, Turbo patterns, DOM lifecycle concerns for a game project
3. **Scaling pressure:** As the codebase grows, web baggage competes with actual game code for context window space

The layering approach (`compound-engineering.local.md` + `.claude/agents/`) mitigated but didn't solve these problems — web-specific prompts still loaded, generic agents still produced web-centric output, and the compound schema still used Cora-specific enums.

(See brainstorm: `docs/brainstorms/2026-03-19-godot-ce-plugin-fork-brainstorm.md` — Why Full Fork section)

## Proposed Solution

### Architecture: Two-Layer Design

**Layer 1: godot-compound plugin (shareable)**
A standalone Claude Code plugin containing Godot-specific agents, skills, commands, and configuration. Installable by any Godot developer. Lives in a separate repository.

**Layer 2: Project-specific extensions (local)**
RootsGame-specific agents/skills in `.claude/agents/` and `.claude/skills/` that extend the plugin with project-specific patterns (monster-collection review, battle system validation, RPG data modeling).

### Command Namespace

All godot-compound commands use the `/gc:` prefix. No exceptions — this includes commands that CE ships without prefix.

| Command | Purpose |
|---|---|
| `/gc:plan` | Implementation planning with GUT/gdtoolkit references |
| `/gc:work` | Execution with Godot acceptance patterns |
| `/gc:review` | Multi-agent review with Godot agents |
| `/gc:compound` | Knowledge capture with Godot schema |
| `/gc:brainstorm` | Collaborative exploration (game design focus) |
| `/gc:deepen-plan` | Plan enhancement with parallel research |
| `/gc:lfg` | Autonomous pipeline |
| `/gc:slfg` | Swarm pipeline |
| `/gc:simplify` | Code simplification |
| `/gc:loop` | Recurring tasks |

CE stays installed for non-Godot side projects with its own `/ce:` namespace.

(See brainstorm: Resolved Questions — `/gc:` namespace decision)

## Technical Approach

### Plugin Structure Requirements (from research)

The plugin must follow this exact layout:

```
godot-compound/
├── .claude-plugin/
│   └── plugin.json          # REQUIRED — name, version, description
├── agents/
│   ├── review/              # Subdirectories for categories
│   ├── research/
│   └── workflow/
├── commands/
│   └── gc/                  # /gc:plan, /gc:work, etc.
├── skills/
│   ├── godot-patterns/
│   ├── compound-godot/
│   └── godot-setup/
├── .mcp.json                # Context7 MCP config
├── CLAUDE.md                # Plugin-level instructions (loaded like project CLAUDE.md)
├── README.md
└── LICENSE
```

**Key constraints:**
- `.claude-plugin/plugin.json` is the only mandatory file. Minimum: `{"name": "godot-compound"}`
- Component directories (`agents/`, `skills/`, `commands/`) MUST be at plugin root, NOT inside `.claude-plugin/`
- Commands are registered flat — `/gc:plan` is just a file `commands/gc/plan.md` (the colon maps to a directory separator)
- Agent `.md` files are registered by filename. If two plugins define `code-simplicity-reviewer.md`, behavior is undefined — use unique names or accept the risk
- MCP tools are auto-namespaced: `mcp__plugin_godot-compound_context7__query-docs` (no conflict with CE's Context7)
- Plugin CLAUDE.md is loaded independently — embed Godot conventions here for all agents to inherit

**Distribution options:**
1. **Local directory marketplace** — for development/testing. Create `~/claude-plugins/godot-compound-marketplace/plugins/godot-compound/` structure
2. **GitHub repository marketplace** — for sharing. Must have `plugins/godot-compound/` at repo root
3. **Official marketplace** — submit stub to `anthropics/claude-plugins-official/external_plugins/`

### Core Command Rewrite Analysis (from research)

Line-by-line analysis of all 5 core CE commands:

| Command | Stack-Agnostic | Web-Specific Lines | Complexity | Key Changes |
|---|---|---|---|---|
| `ce:brainstorm` | **100%** | 0 | **None** | Namespace rename only |
| `ce:compound` | ~95% | ~15 lines | **Trivial** | Swap agent names, one category rename |
| `ce:plan` | ~95% | ~20 lines | **Trivial** | Replace Ruby examples with GDScript, reword "middleware/callbacks" to "signals/autoloads" |
| `ce:work` | ~80% | ~60 lines | **Moderate** | Remove Figma/browser/deploy sections, rewrite System-Wide Test Check table for Godot, replace test commands with GUT/gdtoolkit |
| `ce:review` | ~80% | ~50 lines | **Moderate** | Remove database migration conditional agents + E2E web/iOS testing, replace with Godot conditional agents (resource-safety on `.tres`/`.tscn` changes) |

**Specific rewrite targets in `/gc:work`:**
- System-Wide Test Check table: "callbacks/middleware/observers" → signals, `_notification()`, autoloads; "DB row, cache, file" → `.tres` Resources, save files, autoload state; "retry middleware" → `push_error()`, `assert()`, null checks
- Remove: Figma Design Sync section, Capture/Upload Screenshots (localhost:3000), Post-Deploy Monitoring
- Replace: `bin/rails test, npm test` → `gdformat --check . && gdlint .` + GUT headless

**Specific rewrite targets in `/gc:review`:**
- Remove: Conditional migration agents section (schema-drift-detector, data-migration-expert, deployment-verification-agent)
- Remove: End-to-End Testing section (project type detection for xcodeproj/Gemfile/package.json, Playwright, Xcode simulator)
- Add: Godot conditional agents (resource-safety-reviewer when `.tres`/`.tscn` changed, godot-export-verifier when export presets changed)
- Replace: GUT/GdUnit4 test suite execution, headless game launch for error checking

### Utility Command Audit (from research)

| Command | Status | Changes Needed |
|---|---|---|
| changelog | **Keep as-is** | None |
| triage | **Keep as-is** | Example-only Rails path (cosmetic) |
| resolve_todo_parallel | **Keep as-is** | None |
| resolve_parallel | **Keep as-is** | None |
| heal-skill | **Keep as-is** | None |
| deepen-plan | **Needs update** | `/ce:` → `/gc:` refs, replace React Query example with GDScript, swap skill example names |
| lfg | **Needs update** | `/ce:` → `/gc:` refs, remove test-browser + feature-video pipeline steps |
| slfg | **Needs update** | Same as lfg |
| report-bug | **Needs update** | Change target repo from `EveryInc/compound-engineering-plugin` to fork repo |
| generate_command | **Needs update** | Replace `bin/rails test`, `bundle exec standardrb` examples with gdtoolkit |
| reproduce-bug | **Major rewrite** | Rails console, AppSignal logs, Playwright throughout — near-total rewrite for Godot or removal |
| simplify | **Not found** | Does not exist as a command in CE 2.38.1 (may be a skill or alias) |
| loop | **Not found** | Does not exist as a command (may be a skill) |

### Full Audit Summary

Every CE component assessed for Godot relevance (brainstorm audit, 2026-03-19):

| Category | Keep | Rewrite | New | Remove | Total |
|---|---|---|---|---|---|
| Agents | 10 | 4 | 3 | 15 | 32→17 |
| Skills | 9 | 2 | 1 | 9 | 21→12 |
| Commands | 10 | 5 | 0 | 3 | 18→15 |
| **Total** | **29** | **11** | **4** | **27** | **71→44** |

### Agents: Final Inventory (17)

**Keep (10 — stack-agnostic):**
best-practices-researcher, framework-docs-researcher, learnings-researcher, repo-research-analyst, git-history-analyzer, code-simplicity-reviewer, pattern-recognition-specialist, pr-comment-resolver, bug-reproduction-validator, spec-flow-analyzer

**Rewrite for Godot (4):**

| CE Agent | Godot Agent | Key Changes |
|---|---|---|
| architecture-strategist | godot-architecture-reviewer | Scene composition, signals, autoloads, inheritance depth. FAIL/PASS GDScript examples. |
| performance-oracle | godot-performance-reviewer | `_process` abuse, scene tree traversal, typed GDScript perf, draw calls. GDScript examples. |
| julik-frontend-races-reviewer | godot-timing-reviewer | Signal emission timing, `await` race conditions, async resource loading, frame ordering. |
| deployment-verification-agent | godot-export-verifier | Export build verification, asset integrity, scene reference validation. |

**New (3):**
- **gdscript-reviewer** — Static typing, member ordering, naming, signal naming, Resource safety code patterns
- **resource-safety-reviewer** — `.tres`/`.tscn` integrity, `.uid` sidecars, `res://` reference safety, `.duplicate()` checks
- **gdscript-lint** — gdformat + gdlint (port from RootsGame `.claude/agents/`)

(See brainstorm: Full Audit Results — Agents sections)

### Skills: Final Inventory (12)

**Keep (9):** brainstorming, compound-docs (structure only), context-management, create-agent-skills, document-review, file-todos, git-worktree, orchestrating-swarms, resolve-pr-parallel

**Rewrite (2):**
- **godot-setup** (from setup) — Detect `project.godot`, Godot version, GUT, gdtoolkit
- **compound-godot** (from compound-docs schema) — Godot-specific enums

**Port from RootsGame (1):**
- **godot-patterns** — Scene architecture, GDScript quality, Resource system references

### Commands: Final Inventory (15)

**Keep (10):** deepen-plan, lfg, slfg, simplify, loop, changelog, triage, resolve_todo_parallel, report-bug, heal-skill

**Rewrite (5 core):** gc:plan, gc:work, gc:review, gc:compound, gc:brainstorm

**Remove (3):** test-browser, test-xcode, feature-video

## Research-Driven Methodology

The plugin is a standalone community tool. Agents, commands, and skills are built from researched patterns — not gated by any single project's codebase maturity.

### Source Hierarchy

Pattern sources are used in priority order. Higher-priority sources override lower ones when they conflict.

| Priority | Source | What It Provides | Coverage |
|---|---|---|---|
| 1 | **Official Godot docs** (docs.godotengine.org) | API behavior, GDScript style guide, static typing guide, export docs | Authoritative but sparse on architectural patterns |
| 2 | **`docs/reference/godot-best-practices.md`** (43 sources, 425 lines) | Synthesized patterns across 6 domains: architecture, code quality, signals, resources, performance, tensions | Primary pattern source — every FAIL/PASS example traces here |
| 3 | **Godot issue tracker** (github.com/godotengine/godot) | Known bugs and gotchas (e.g., `Resource.duplicate(true)` #74918, `.uid` sidecar issues) | Critical for resource-safety and export agents |
| 4 | **Community experts** (GDQuest, KidsCanCode, Shaggy Dev, backat50ft) | Opinionated best practices, real-world architecture case studies | Composition, signals, state machines, Resources |
| 5 | **Context7 MCP** (Godot API docs) | Real-time API verification for method signatures, node types, enums | Use to validate every code example in agent prompts |
| 6 | **Open-source Godot 4 projects** | Real-world code patterns (what good and bad actually looks like) | Pattern mining for FAIL/PASS examples |

**Priority 6 reference projects (curated from research):**

| Project | Best For | Why |
|---|---|---|
| [food-please/godot4-open-rpg](https://github.com/food-please/godot4-open-rpg) | Scene composition, signals, Resources, state machines | GDQuest-style RPG with turn-based combat, inter-scene communication, Resource-based data |
| [Phazorknight/Cogito](https://github.com/Phazorknight/Cogito) | Composition over inheritance | Component-based interaction system (doors, keypads, elevators as composable components) |
| [lampe-games/godot-open-rts](https://github.com/lampe-games/godot-open-rts) | Clean minimal architecture | ~800 lines, well-structured RTS with unit management and command patterns |
| [Orama-Interactive/Pixelorama](https://github.com/Orama-Interactive/Pixelorama) | Production GDScript, autoload management | 9,000+ LoC shipped product on Godot 4.6.1 |
| [dialogic-godot/dialogic](https://github.com/dialogic-godot/dialogic) | Custom Resource hierarchies, gdUnit4 testing | Popular plugin with `class_name` system, signal-based events, automated tests |
| [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) | FAIL examples (untyped code) | 50+ official demos, most lack static typing (issue #868) — natural "before" patterns |
| [gdquest-demos/godot-design-patterns](https://github.com/gdquest-demos/godot-design-patterns) | State machine reference implementation | Isolated, clean pattern implementations |

**Notable gap:** No open-source Godot 4 project enforces all four static typing warnings as Errors at the project-settings level. RootsGame's approach is ahead of the community curve — FAIL examples for untyped code can come from almost any project.

### Agent Building Pipeline

Each agent follows a 4-step pipeline:

#### Step A: Research the Domain

For each agent's domain (e.g., "signal timing" for godot-timing-reviewer):

1. **Read the relevant section** of `docs/reference/godot-best-practices.md`
2. **Web search** for recent (2024-2026) Godot 4 articles, forum threads, and issue reports in the domain
3. **Query Context7** for Godot API docs on relevant classes and methods
4. **Check gdtoolkit rules** — identify which patterns the linter already catches (agents should NOT duplicate linter coverage)

**Output:** A list of 10-15 candidate patterns, each with a source citation.

#### Step B: Select and Prioritize Principles

From the candidate patterns, select 7-8 principles per agent (hard cap — see CE agent analysis below):

1. **Priority-order** by impact: patterns that cause bugs/crashes > patterns that cause maintenance pain > style preferences
2. **Check for overlap** against other agents' scope boundaries (see Cross-Agent Scope Matrix below)
3. **Verify each pattern is real** — must have at least one source citation from Priority 1-4 sources above
4. **Discard anything gdtoolkit already catches** — formatting, basic naming, indentation are the linter's job

#### Step C: Write FAIL/PASS Examples

For each principle, write a single-line FAIL/PASS pair:

- **Format:** `🔴 FAIL: \`bad_example_code\`` / `✅ PASS: \`good_example_code\``
- **Length:** Each example is a single line of GDScript (5-20 words). NOT multi-line code blocks.
- **Validation:** Every example must be verified against Context7 API docs (does this API exist? are the method signatures correct?)
- **Source tracing:** Each principle gets an inline comment citing its source: `(source: GDQuest Signals Best Practices)` or `(source: Godot #74918)`

**Anti-pattern to avoid:** Inventing GDScript examples from assumptions. If you can't find a documented pattern, don't include it.

#### Step D: Validate Against Template

Every agent must pass the CE agent template constraints (see below). Check:
- [ ] Total lines: 90-120 (hard ceiling: 140)
- [ ] Frontmatter: name, description, model fields present
- [ ] Examples block: 3+ invocation examples
- [ ] Principles: 7-8 (never 10+)
- [ ] FAIL/PASS pairs: inline single-line format with emoji prefixes
- [ ] Scope boundary statement: explicit "this agent does / does not review X"
- [ ] No overlap with other agents' scope

### CE Agent Template (from research)

Extracted from quantitative analysis of 4 CE review agents:

| Metric | Code-Quality Type | Analytical Type |
|---|---|---|
| **Use for** | gdscript-reviewer, resource-safety | architecture, performance, timing, export |
| **Total lines** | 90-120 | 100-140 |
| **Principles** | 7-9, each 5-10 lines | 4-6 sections, each 10-15 lines |
| **FAIL/PASS** | Inline emoji pairs per principle | Optional (analytical agents may use frameworks instead) |
| **Output format** | Freeform review | Structured template with severity tiers |
| **Methodology** | "When reviewing: 1..." (5-6 steps) | Multi-pass framework |

**Concrete template:**

```markdown
---
name: <gc-agent-name>
description: "[Verbs] [domain objects] for [concerns]. Use when [trigger]."
model: inherit
---

<examples>
<example>
Context: [Concrete scenario]
user: "[Trigger phrase]"
assistant: "[Response showing invocation]"
<commentary>[Why this agent]</commentary>
</example>
[2+ more examples]
</examples>

You are [Name], [expertise]. Your role is to [mission].

[2-3 sentence persona/context]

## Scope

This agent reviews [X]. It does NOT review [Y] (that's [other-agent]'s domain).

## Principles

### 1. [PRINCIPLE NAME] (source: [citation])

[5-10 line explanation]
- 🔴 FAIL: `bad_example`
- ✅ PASS: `good_example`

### 2. [PRINCIPLE NAME] (source: [citation])
[... repeat 7-8 times ...]

## Review Methodology

1. [First pass]
2. [Second pass]
[... 5-6 steps ...]

[Closing guidance]
```

### Cross-Agent Scope Matrix

Each pattern is owned by exactly one agent. No overlaps.

| Pattern | Owner | NOT |
|---|---|---|
| Static typing, naming, member ordering | gdscript-reviewer | — |
| Signal naming conventions (`past_tense`) | gdscript-reviewer | timing-reviewer |
| Composition vs inheritance structure | architecture-reviewer | gdscript-reviewer |
| "Call down, signal up" violations | architecture-reviewer | timing-reviewer |
| Autoload discipline (what should be autoload) | architecture-reviewer | timing-reviewer |
| Signal emission timing (when signals fire) | timing-reviewer | architecture-reviewer |
| `await` race conditions | timing-reviewer | — |
| `queue_free()` / `call_deferred()` safety | timing-reviewer | — |
| Autoload initialization ORDER | timing-reviewer | architecture-reviewer |
| `.tres`/`.tscn` reference integrity | resource-safety-reviewer | — |
| `Resource.duplicate()` requirements | resource-safety-reviewer | gdscript-reviewer |
| `.uid` sidecar consistency | resource-safety-reviewer | — |
| `preload()` vs `load()` choice | resource-safety-reviewer | performance-reviewer |
| `_process`/`_physics_process` abuse | performance-reviewer | architecture-reviewer |
| Typed vs untyped performance | performance-reviewer | gdscript-reviewer |
| Scene tree traversal costs | performance-reviewer | — |
| Server APIs for high-count entities | performance-reviewer | — |
| Export preset configuration | export-verifier | — |
| Build asset integrity | export-verifier | resource-safety-reviewer |
| Formatting, indentation, whitespace | gdscript-lint (gdtoolkit) | ALL other agents |

**Boundary rule:** When a pattern could belong to two agents, the owner is the one that can write a more specific FAIL/PASS example. Architecture-reviewer owns "should this signal exist?" while timing-reviewer owns "is this signal emitted at the right time?"

### Pattern Source Coverage Assessment

Current coverage of `docs/reference/godot-best-practices.md` + supplemental research against agent domains:

| Agent Domain | Sources in Reference | Supplemental Sources | Coverage | Action Before Agent |
|---|---|---|---|---|
| GDScript code quality | 10 sources | gdtoolkit (24 rules), beep.blog benchmarks | **Strong** | Ready |
| Scene architecture | 9 sources | KidsCanCode recipes, official best practices | **Strong** | Ready |
| Signal patterns | 8 sources | GDQuest signal best practices | **Strong** | Ready |
| Resource system | 7 sources | 12 tracked GitHub issues (#74918, #82348, #77380, #94531, #90597, #104188, etc.) | **Strong** | Ready |
| Performance | 8 sources | Server API docs, SceneTree PR #106244, godot-benchmarks repo | **Strong** | Ready |
| Timing/async | 1 source (partial) | 4 GitHub issues (#93608, godot-docs #6488, #84046, godot-docs #11717), 4 forum threads (queue_free timing, race condition guards, await patterns), gdscript.com coroutine guide | **Fillable** | Create `godot-patterns/timing-async.md` reference file from these sources before writing agent |
| Export/builds | 0 sources | 6 GitHub issues (#86317, #77886, #77007, #80877 meta-tracker, #84401, #108805), platform gotchas (case sensitivity, .remap suffix, DirAccess visibility, SharedArrayBuffer headers) | **Fillable** | Create `godot-patterns/export-builds.md` reference file from these sources before writing agent |

**Before building each agent, verify its domain has adequate source coverage.** For Timing/async and Export/builds, create new reference files in the godot-patterns skill to codify the researched patterns before writing FAIL/PASS examples.

### Validation Without a Codebase

Three validation strategies replace the need for a live project:

#### 1. Synthetic Test Fixtures (Clippy-inspired)

Create `tests/review-fixtures/` in the plugin, one `.gd` per principle:

```
tests/review-fixtures/
  gdscript-reviewer/
    static_typing.gd
    member_ordering.gd
    resource_duplication.gd
    signal_naming.gd
    composition_over_inheritance.gd
  architecture-reviewer/
    call_down_signal_up.gd
    scene_inheritance_depth.gd
  resource-safety-reviewer/
    resource_sharing_pitfall.gd
    uid_sidecar_handling.gd
```

Each fixture uses a consistent format:

```gdscript
## Test: static_typing
## Source: https://docs.godotengine.org/en/stable/.../static_typing.html
## Rule: Every variable, parameter, and return must be explicitly typed.

# --- FAIL EXAMPLES ---
var health = 100  # Missing type annotation
func take_damage(amount):  # Untyped parameter and return
    health -= amount

# --- PASS EXAMPLES ---
var health: int = 100
func take_damage(amount: int) -> void:
    health -= amount
```

#### 2. Cross-Validation with Existing Tools

Agents must NOT duplicate what automated tools already catch:

- **gdtoolkit gdlint** (26 rules): 14 naming, 5 basic, 2 class, 2 design, 4 format, 2 misc
- **Godot built-in warnings** (45 codes): UNTYPED_DECLARATION, UNSAFE_PROPERTY_ACCESS, UNSAFE_METHOD_ACCESS, UNSAFE_CALL_ARGUMENT, etc.

**The gap — patterns only LLM agents can catch:**

| Pattern | Why tools miss it | Agent owner |
|---|---|---|
| Resource sharing pitfall (mutating without `.duplicate()`) | Requires semantic understanding of intent | resource-safety |
| Dynamic `load()` with string concat | gdlint has no rule for this | gdscript |
| Event bus overuse (bus for parent-child comm) | Architectural judgment | architecture |
| Deep scene inheritance (>1 custom layer) | No tool tracks `.tscn` inheritance depth | architecture |
| Signal bubbling (re-emitting child signals) | Requires understanding signal flow | architecture |
| Composition violations (fat scripts vs. child nodes) | Architectural judgment | architecture |
| `preload()` vs `load()` preference | gdlint checks naming, not function choice | resource-safety |
| Missing `.duplicate()` on `@export` Resource arrays | Subtle Godot sharing behavior | resource-safety |
| Hardcoded node paths (`../../SomeNode`) | No existing rule | architecture |
| Properties set after `add_child()` | Performance pattern, no tool checks | performance |

**This gap table is the minimum viable agent scope.** These 10 patterns justify building custom agents. Any agent principle not in this table must demonstrate that it catches something tools cannot.

#### 3. Context7 API Verification

Before finalizing any agent, query Context7 for every Godot API method, class, and enum referenced in FAIL/PASS examples. If the API doesn't exist or has a different signature, the example is wrong.

#### Iterative Refinement Workflow

For each agent, after writing the prompt:

1. **Run agent against its fixtures** — feed each fixture file and capture output
2. **Score against verdict matrix** — True Positive (flagged FAIL line), False Negative (missed FAIL line), False Positive (flagged PASS line), True Negative (PASS clean)
3. **Fix common failures:**
   - False negatives → add missed pattern as explicit FAIL example in prompt
   - False positives → add false-flagged pattern as explicit PASS example in prompt
   - Inconsistent → add specificity: "Flag X ONLY when Y, NOT when Z"
4. **Track coverage:** `gdscript-reviewer: 8/10 patterns correct (v3 of prompt)`
5. **Re-run on expansion** — when new fixtures are added, re-run all to catch regressions

## Implementation Phases

### Phasing Strategy (from simplicity review)

**Critical insight (original):** The simplicity review flagged 44 components for 5 source files as disproportionate. However, the plugin is a standalone community tool — its quality comes from researched patterns, not from one project's codebase maturity. All phases proceed using Godot documentation, community best practices, and online patterns as the source of "experience."

**Adopted approach:** Phase 1 is the minimum viable deliverable. Phases 2-5 are research-driven — agents and commands are built from Godot documentation, community patterns, and online best practices rather than gated by the host project's codebase size. The plugin is a standalone community tool and must not be coupled to any single project's maturity.

| Phase | Deliverable | Approach |
|---|---|---|
| Phase 1 | Fork, strip, namespace, verify | **Done** — token overhead eliminated |
| Phase 2 | Core command rewrites | Replace web tooling references with Godot equivalents (GUT, gdtoolkit, scene validation) |
| Phase 3 | Godot review agents | Build from researched Godot patterns, docs, and community best practices |
| Phase 4 | Skills + schema | Build from Godot documentation and CE schema patterns |
| Phase 5 | Integration + polish | After Phase 2-4 components are built |

### Phase 1: Fork & Strip (foundation)

#### Step 1: Create repository and fork CE
- Create new repository `godot-compound` (separate from RootsGame)
- Copy CE v2.38.1 from `~/.claude/plugins/cache/compound-engineering-plugin/compound-engineering/2.38.1/` as initial commit
- Update `.claude-plugin/plugin.json`: name → `godot-compound`, description → Godot 4 development tools, version → `0.1.0`
- Update LICENSE (MIT inherited), README placeholder
- Create plugin CLAUDE.md with Godot conventions (loaded as plugin instructions for all agents to inherit)
- **Files:** `.claude-plugin/plugin.json`, `CLAUDE.md`, `LICENSE`, `README.md`

##### Research Insight: Plugin Structure
Plugin.json minimum required structure:
```json
{
  "name": "godot-compound",
  "version": "0.1.0",
  "description": "Godot 4 + GDScript development tools. Agents, skills, and commands for the Plan → Work → Review → Compound loop.",
  "author": { "name": "Alan" },
  "license": "MIT",
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```
**Gotcha:** The `author` field must be an object (`{"name": "..."}`) not a plain string. A string passes JSON parsing but fails `claude plugin validate`.

Components (`agents/`, `skills/`, `commands/`) must be at plugin root, not inside `.claude-plugin/`.

**Local plugin installation** — there is no `claude /plugin add <path>` for local directories. Local plugins require a marketplace wrapper:
```bash
# 1. Create marketplace wrapper with symlink to plugin source
mkdir -p ~/.claude/godot-compound-marketplace/.claude-plugin
mkdir -p ~/.claude/godot-compound-marketplace/plugins
ln -sf ~/.claude/godot-compound ~/.claude/godot-compound-marketplace/plugins/godot-compound

# 2. Write marketplace.json (see handoff doc for schema)

# 3. Register and install
claude plugin marketplace add ~/.claude/godot-compound-marketplace
claude plugin install godot-compound
```
The symlink means edits to `~/.claude/godot-compound/` are live immediately in the next session. See `docs/handoffs/2026-03-19-godot-compound-plugin-install.md` for full reproduction steps and marketplace.json schema.

#### Step 2: Remove web-specific agents (15)
- Delete all agents listed in brainstorm "Agents: REMOVE" table
- Verify no remaining agent references these deleted agents
- **Removed:** dhh-rails-reviewer, kieran-rails-reviewer, kieran-typescript-reviewer, kieran-python-reviewer, agent-native-reviewer, data-migration-expert, schema-drift-detector, data-integrity-guardian, security-sentinel, figma-design-sync, design-implementation-reviewer, design-iterator, ankane-readme-writer, every-style-editor, lint (CE version)

#### Step 3: Remove web-specific skills (9)
- Delete all skills listed in brainstorm "Skills: REMOVE" table
- **Removed:** agent-browser, andrew-kane-gem-writer, dhh-rails-style, dspy-ruby, every-style-editor, frontend-design, gemini-imagegen, proof, rclone

#### Step 4: Remove web-specific commands (3)
- **Removed:** test-browser, test-xcode, feature-video

#### Step 5: Rename command namespace
- Rename `commands/ce/` → `commands/gc/`
- Update all internal references from `/ce:` → `/gc:`
- Search-and-replace across all remaining files: `ce:plan` → `gc:plan`, `ce:work` → `gc:work`, etc.
- Rename deprecated `commands/workflows/` aliases if kept, or remove entirely

#### Step 6: Verify stripped plugin loads
- Install locally via marketplace wrapper (see Research Insight above; `claude /plugin add <path>` does not exist)
- Verify `/gc:plan`, `/gc:work`, `/gc:review`, `/gc:compound` resolve
- Verify removed commands don't appear
- Verify no broken references in remaining files

#### Phase 1 Acceptance Criteria
- [x] New repo with CE v2.38.1 as initial commit
- [x] 19 agents removed (15 web + 4 rewrite targets), 10 remain
- [x] 11 skills removed, 9 remain
- [x] 6 commands removed + deprecated aliases, 16 remain (5 core + 11 utility)
- [x] All commands use `/gc:` prefix
- [x] Plugin installs and loads without errors (via local marketplace wrapper + symlink)
- [x] No references to removed components in remaining files
- [x] Web-specific content cleaned from all remaining prompts (reproduce-bug.md pending Phase 5 rewrite, marked with NOTE)

### Phase 2: Rewrite Core Commands (5)

Rewrite each core command to reference Godot tooling instead of web tooling. Follow CE's orchestration patterns exactly — same structural patterns, different domain content.

(See brainstorm: Implementation Methodology — "Follow CE's Orchestration Patterns")

#### Step 7: Rewrite `/gc:plan`
- Replace Rails test references with GUT headless test commands
- Replace standardrb/erblint with gdtoolkit
- Replace database migration criteria with scene/resource validation criteria
- Replace Figma/browser references with Godot-specific acceptance patterns
- Keep: plan structure, research agent dispatch, specflow analysis, detail level options

#### Step 8: Rewrite `/gc:work`
- Replace Rails test execution with GUT: `godot --headless -s addons/gut/gut_cmdln.gd -gexit`
- Remove Figma sync, browser screenshot, database migration sections
- Replace with: gdtoolkit lint checks, scene validation, Resource safety verification
- Keep: incremental commit logic, todo tracking, clarification-first behavior

#### Step 9: Rewrite `/gc:review`
- Replace `review_agents` default list with Godot agents
- Remove database migration conditional agents (schema-drift-detector, data-migration-expert, deployment-verification-agent)
- Add Godot conditional agents: resource-safety-reviewer (when `.tres`/`.tscn` files changed), godot-export-verifier (when export presets changed)
- Keep: parallel agent dispatch, learnings-researcher, severity triage, todo creation
- Context body: Godot architecture rules (composition, signals, `.tscn` read-only)

#### Step 10: Rewrite `/gc:compound`
- Replace Cora-specific schema reference with `compound-godot` schema
- Replace Rails environment detection with Godot version detection
- Replace Ruby code fence examples with GDScript
- Keep: 7-step capture process, YAML validation, decision menu, cross-referencing

#### Step 11: Rewrite `/gc:brainstorm`
- Remove Proof sharing option
- Add game design focus (gameplay mechanics, scene structure, entity composition)
- Keep: collaborative dialogue methodology, AskUserQuestion flow, brainstorm document output

#### Phase 2 Acceptance Criteria
- [x] Each rewritten command references only Godot tooling (GUT, gdtoolkit, scene validation)
- [x] No Rails, npm, Figma, browser, SQL references in any command
- [x] `/gc:plan` produces plans with Godot-specific acceptance criteria
- [x] `/gc:work` runs GUT tests and gdtoolkit checks
- [x] `/gc:review` dispatches Godot agents
- [x] `/gc:compound` validates against Godot schema

### Phase 3: Build Godot Review Agents (7)

Build all new and rewritten agents. Each must follow the Kieran reviewer pattern: persona, numbered principles with FAIL/PASS GDScript examples, priority ordering, scope boundaries. Target 90-120 lines, ~900 tokens per agent.

**Approach:** Follow the Research-Driven Methodology (see above). Each agent goes through the 4-step pipeline: Research Domain → Select Principles → Write FAIL/PASS → Validate Against Template. Use the Cross-Agent Scope Matrix to prevent overlap. Fill source coverage gaps (Timing/async, Export/builds) with dedicated research before writing those agents.

(See brainstorm: Implementation Methodology — "Cross-Analyze with Godot Best Practices Research" and "Validate Real-World Practicality via Web Research")

##### Research Insights: Agent Authoring Corrections (from create-agent-skills review)

**Description strings (highest-priority gap):** Every agent needs a `description:` frontmatter field following the pattern: "[Verbs] [domain objects] for [specific concerns]. Use when [trigger conditions]."

| Agent | Description |
|---|---|
| gdscript-reviewer | "Reviews GDScript files for static typing, member ordering, naming conventions, signal architecture, and Resource safety patterns. Use when .gd files are created or modified." |
| resource-safety-reviewer | "Reviews resource integrity: .tres/.tscn reference validation, .uid sidecar consistency, shared Resource mutation detection, and res:// path safety. Use when resource or scene files are created, moved, or modified." |
| gdscript-lint | "Runs gdformat and gdlint checks on GDScript files for formatting and style compliance. Use when checking code formatting or before commits." |
| godot-architecture-reviewer | "Reviews scene composition, signal flow, autoload usage, and inheritance depth against Godot architecture principles. Use when scenes are created, refactored, or when inter-scene communication changes." |
| godot-performance-reviewer | "Reviews GDScript and scene tree patterns for performance: _process abuse, untyped hotpaths, scene traversal costs, and memory patterns. Use when performance-sensitive code is written or modified." |
| godot-timing-reviewer | "Reviews signal emission timing, await race conditions, call_deferred requirements, queue_free safety, and autoload initialization order. Use when signal flow, async operations, or scene lifecycle code is modified." |
| godot-export-verifier | "Verifies export preset configuration, asset integrity, scene reference completeness, and .uid consistency for build exports. Use when export presets change or before release builds." |

**Structural conventions:**
- **Agents use markdown headings** (CE convention — Kieran agent is canonical example)
- **Skills use XML tags** with `<objective>`, `<quick_start>`, `<success_criteria>` (skill best-practices)
- Do NOT mix these — hybrid XML/markdown in a single file is an anti-pattern

**gdscript-reviewer is overloaded (Step 12 correction):**
The plan calls for 10 principles + edge cases + anti-patterns. At 10 principles with multi-line GDScript FAIL/PASS examples, this will exceed 120 lines significantly. **Cap at 7-8 principles in the body. Move edge cases and anti-patterns to `references/gdscript-edge-cases.md`.** This applies progressive disclosure — the Kieran agent is 115 lines with 9 principles only because its FAIL/PASS examples are single-line.

**resource-safety-reviewer workflow correction (Step 13):**
The plan specifies a "3-phase workflow" inside the agent. CE agents are reviewer personas, not workflow orchestrators. `/gc:review` handles orchestration; agents provide review criteria and FAIL/PASS examples only. **Remove the workflow from the agent body.** Keep severity-ordered checks. The 3-phase workflow belongs in the review command or a reference file.

**godot-timing-reviewer scope overlap (Step 17):**
Signal emission timing and autoload order overlap with architecture-reviewer. Define boundary: **architecture-reviewer owns structural patterns** (should this signal exist?), **timing-reviewer owns execution ordering** (is this signal emitted at the right time?).

**godot-export-verifier research approach (Step 18):**
Build from Godot export documentation and community patterns. Research common export pitfalls (missing assets, platform-specific gotchas, `.uid` consistency) from Godot forums, issue trackers, and official docs. No project-specific triggers needed — the agent should work for any Godot project.

#### Step 12: gdscript-reviewer
- **10 review principles** (priority-ordered): Critical Deletions, Static Typing, Resource Safety, Signal Architecture, Composition, Member Ordering, Naming Conventions, Existing Code Strictness, New Code Pragmatism, Core Philosophy
- **FAIL/PASS examples** for each principle using real GDScript patterns from `docs/reference/godot-best-practices.md`
- **Edge cases:** `@onready` with `as` cast (silent null), signals in `_ready()` (unsafe), forgotten `super()`, `class_name` pollution, exported Resource array mutation
- **Anti-patterns:** God Autoload, Inheritance Taxonomy, Signal Spaghetti Bus, Monolithic Battle Script
- **Frontmatter:** `model: inherit` (needs reasoning quality)

#### Step 13: resource-safety-reviewer
- **Severity-ordered checks:** CRITICAL (broken `res://` refs, `ext_resource` mismatch, missing `.uid`, `.tscn` corruption), HIGH (shared Resource mutation, dynamic `load()`, deep node paths), MEDIUM (orphaned `.uid`, binary `.res`, `load()` vs `preload()`)
- **3-phase workflow:** collection → per-dimension scan → severity-grouped report
- **`.tscn` five-section validation** (read-only): header, ext_resources, sub_resources, nodes, connections
- **Resource mutation detection:** grep for `preload/load` without `.duplicate()`, `@export` Resources mutated in code
- **Critical detail:** `Resource.duplicate(true)` does NOT deep-copy Array/Dict subresources (source: #74918, #82348, #105904; fix merged in PR #100673 — check Godot version)
- **`resource_local_to_scene` gotchas:** fails for nested scenes (#77380), unlinks in inherited scenes (#94531), doesn't work in arrays (#90597), fails for ArrayMesh materials in inherited scenes 4.6 (#115487)
- **Version-gated `.uid` checks:** read `config/features` from `project.godot`; `.uid` sidecar dropped on external rename (#104188, fixed in PR #104248)

#### Step 14: gdscript-lint (port from RootsGame)
- Port existing `.claude/agents/gdscript-lint.md` to plugin `agents/workflow/`
- Port `.claude/skills/gdscript-lint/SKILL.md` to plugin `skills/`
- **Frontmatter:** `model: haiku` (mechanical check, not judgment)

#### Step 15: godot-architecture-reviewer (rewrite architecture-strategist)
- **3 priority tiers:** P0 (structural violations: call-down-signal-up, inheritance depth, EventBus misuse, autoload discipline), P1 (performance: `_process` abuse, unbounded instantiation, signal leaks, typed arrays), P2 (design: scene encapsulation, component design)
- **Scene hierarchy metrics:** depth (good: 1-4, red: 7+), nodes per scene (good: 1-15, red: 30+), inheritance layers (good: 0-1 custom, red: 3+)
- **Grep-based detection patterns** for each violation type
- **Scope boundary:** reviews how systems are composed and communicate — NOT how code is written (gdscript-reviewer) or how files are structured (resource-safety-reviewer)

#### Step 16: godot-performance-reviewer (rewrite performance-oracle)
- Scene tree traversal costs, `_process`/`_physics_process` abuse, untyped hotpaths
- `set_process(false)` for off-screen objects, Server APIs for high-count scenarios
- Typed GDScript performance (28-59% faster), `distance_squared_to()` vs `distance_to()`
- `preload()` vs `load()`, `@onready` caching, property-setting before `add_child()`
- Object pooling guidance (generally unnecessary in GDScript; relevant for action-RPG elements)

#### Step 17: godot-timing-reviewer (rewrite julik-frontend-races-reviewer)
- **Prerequisite:** Create `skills/godot-patterns/references/timing-async.md` from researched sources (4 GitHub issues, 4 forum threads, gdscript.com coroutine guide)
- Signal emission in `_ready()` (listeners not ready), `call_deferred()` requirement
- `await` race conditions in GDScript coroutines (source: gdscript.com coroutine guide)
- `queue_free()` during scene tree modification — `queue_free` on node with async coroutine still lets coroutine run one more frame (source: Godot #93608)
- Deferred call execution timing — docs don't specify WHEN deferred calls execute (source: godot-docs #6488, still open)
- `_process` vs `_unhandled_input` ordering
- Autoload initialization order dependencies
- Signal connection on dynamically created nodes (leak if freed without disconnect)
- `call_group("mobs", "queue_free")` unreliable without frame wait (source: godot-docs #11717)

#### Step 18: godot-export-verifier (rewrite deployment-verification-agent)
- **Prerequisite:** Create `skills/godot-patterns/references/export-builds.md` from researched sources (6 GitHub issues, platform-specific gotchas)
- Export preset validation, resource filter checks
- Resources loaded via `DirAccess` + string concatenation NOT tracked by export system — must be added to export filters or referenced via preload (source: forum, #84401)
- Custom Resources fail to load after export due to circular dependencies (source: #77007, #80877 meta-tracker)
- Missing assets in export — works in editor, crashes in export (source: #86317)
- Platform-specific checks: case sensitivity breaks Windows→Android/Linux (#86317 forum), `.remap` suffix for dynamic loading, SharedArrayBuffer headers for web/threads
- `.uid` sidecar dropped on external rename (source: #104188, fixed in PR #104248)
- Android export breakage on version upgrades (source: #108805)

#### Phase 3 Acceptance Criteria
- [x] Each agent is 90-120 lines with FAIL/PASS GDScript examples (hard ceiling: 140)
- [x] Each agent's FAIL/PASS examples cite a specific source from the Source Hierarchy (Priority 1-4)
- [ ] Every Godot API referenced in FAIL/PASS examples verified via Context7 (deferred)
- [x] All agents match the CE Agent Template structure (frontmatter, examples block, principles, methodology)
- [x] No scope overlap — every pattern maps to exactly one agent per Cross-Agent Scope Matrix
- [x] No duplication with gdtoolkit — agents focus on architectural/semantic patterns, not formatting
- [x] All agents use `model: inherit` except gdscript-lint (`model: haiku`)
- [x] Source coverage gaps (Timing/async, Export/builds) filled with dedicated research before agent creation
- [ ] Synthetic test fixtures created for each agent (one `.gd` per principle) (deferred)
- [ ] Each agent correctly flags its FAIL fixtures and approves its PASS fixtures (deferred)

### Phase 4: Build Godot Skills & Schema (3)

#### Step 19: compound-godot schema
- Fork `compound-docs/schema.yaml`, replace all Cora-specific enums
- Add `schema_version: 1` from day one
- Add `node_types` optional field (Godot node type names for grep retrieval)
- Replace `rails_version` with `godot_version`
- **Initial enum values:** only what's needed for first 3-5 problems + obvious near-neighbors. Full provisional universe documented in previous plan's research insights.
- **Resolution template:** replace Ruby code fences with `gdscript`, "Database migration" → "Scene changes (manual)", add "Renderer" to Environment section
- Do NOT pre-create `docs/solutions/` category directories

**Provisional enum reference (draw from as problems are encountered):**
- `problem_type`: parse_error, runtime_error, performance_issue, scene_corruption, resource_error, import_error, ui_bug, signal_issue, logic_error, integration_issue, developer_experience, workflow_issue, best_practice
- `component`: scene_tree, resource_system, signal_wiring, physics_collision, animation_system, navigation, tilemap, audio, input_system, ui_controls, autoload, save_load, gdscript_tooling, project_config
- `root_cause`: resource_sharing, uid_mismatch, scene_structure_invalid, node_path_fragile, signal_disconnected, autoload_order, untyped_code, logic_error, api_misuse, process_callback_abuse, config_error, import_cache_stale, missing_dependency
- `resolution_type`: code_fix, scene_fix, config_change, resource_fix, dependency_update, environment_setup, workflow_improvement, architecture_change, pattern_adoption

#### Step 20: godot-setup skill (rewrite setup)
- Detect `project.godot` presence and Godot version from `config/features`
- Detect GUT installation (`addons/gut/` directory)
- Detect gdtoolkit installation (`which gdformat`)
- Generate `compound-engineering.local.md` with Godot review agents and context
- No Rails/Node/Python detection
- **Correction (from create-agent-skills review):** Must have `disable-model-invocation: true` in frontmatter — this is a side-effect workflow that generates config files and should not be auto-invoked. Add `allowed-tools: Bash(which *), Bash(cat *), Read`

#### Step 21: Port godot-patterns skill
- Copy from RootsGame `.claude/skills/godot-patterns/` to plugin `skills/`
- Three reference files: scene-architecture.md, gdscript-quality.md, resource-system.md
- Auto-loading (`user-invocable: false`)

#### Phase 4 Acceptance Criteria
- [x] compound-godot schema has `schema_version: 1` and `node_types` field
- [x] Zero Cora-specific enum values in schema
- [x] Resolution template uses `gdscript` code fences and "Scene changes (manual)" section
- [x] godot-setup detects project.godot, Godot version, GUT, gdtoolkit
- [x] godot-patterns skill auto-loads on GDScript/Godot work

### Phase 5: Integration & Polish

#### Step 22: Update utility commands for `/gc:` namespace

##### Research Insight: Utility Command Audit Results

**Truly stack-agnostic (no changes):** changelog, triage, resolve_todo_parallel, resolve_parallel, heal-skill

**Need `/ce:`→`/gc:` + content updates:**
- deepen-plan — replace React Query example with GDScript, swap skill example names
- lfg — remove test-browser + feature-video pipeline steps, update `/ce:` refs
- slfg — same as lfg
- report-bug — change target repo to fork's repo
- generate_command — replace `bin/rails test`, `bundle exec standardrb` examples with gdtoolkit

**Need major rewrite or removal:**
- reproduce-bug — Rails console, AppSignal, Playwright throughout. Rewrite for Godot (headless game launch, GUT test repro) or remove.

**Missing commands (do not exist in CE 2.38.1):**
- `simplify` — not a command (may be a skill invoked by `/ce:review`)
- `loop` — not a command (may be a skill or alias)

#### Step 23: MCP configuration
- Keep Context7 MCP (works for Godot docs)
- Evaluate adding godot-mcp if Context7 Godot coverage is insufficient

#### Step 24: Documentation
- README.md with installation, quick start, command reference
- CHANGELOG.md with initial release notes
- Agent inventory table with descriptions

#### Step 25: Smoke test
1. Install plugin in RootsGame project
2. Verify all `/gc:` commands resolve
3. Run `/gc:review` on existing code — confirm Godot agents dispatch
4. Run `/gc:plan` — confirm GUT/gdtoolkit references
5. Run `/gc:compound` on a test problem — confirm Godot schema validation
6. Verify `/ce:` commands still work (CE plugin coexistence)

#### Step 26: Update RootsGame
- Remove project-local agents/skills that are now in the plugin (gdscript-lint, godot-patterns)
- Keep project-specific extensions in `.claude/agents/` and `.claude/skills/`
- Update `compound-engineering.local.md` to reference plugin agents
- Update CLAUDE.md to reference godot-compound instead of CE customization
- Archive old plan as superseded

#### Phase 5 Acceptance Criteria
- [x] All `/gc:` commands resolve and function
- [x] `/gc:review` dispatches only Godot-relevant agents
- [x] `/gc:compound` validates against Godot schema
- [x] `/ce:` and `/gc:` commands coexist without collisions
- [ ] Token overhead < 15k (down from ~36k) (needs measurement in fresh session)
- [x] Plugin installable via local marketplace wrapper
- [x] RootsGame project-local agents cleaned up

## Alternative Approaches Considered

| Alternative | Pros | Cons | Why not |
|---|---|---|---|
| **Layering (previous plan)** | No fork maintenance; upstream updates free | ~36k token overhead stays; can't control agent prompts; compound schema still Cora-specific | Doesn't solve the core problems at scale |
| **Selective Fork** | Partial control | Two plugins loaded = command collisions, still some CE overhead | Risk of confusion between `/ce:` and custom commands |
| **Clean-Room** | Zero CE code debt | Loses compound knowledge loop, research agent ecosystem, deepen-plan infrastructure | These are genuinely valuable and proven patterns |

(See brainstorm: Why Full Fork section)

## System-Wide Impact

### Interaction with CE Plugin
- Both plugins installed simultaneously
- `/gc:` and `/ce:` namespaces are fully disjoint
- `compound-engineering.local.md` stays for CE configuration; godot-compound may use its own config mechanism or read the same file

### RootsGame Project Changes
- Project-local `.claude/agents/gdscript-lint.md` → removed (now in plugin)
- Project-local `.claude/skills/godot-patterns/` → removed (now in plugin)
- `compound-engineering.local.md` → updated to reference plugin agents
- `CLAUDE.md` → updated to reference godot-compound

### Maintenance Burden
- CE improvements must be manually ported (watch CE releases)
- Stack-agnostic agents may diverge from CE versions over time
- Plugin versioning independent of CE

## Risk Analysis & Mitigation

| Risk | L | I | Mitigation |
|---|---|---|---|
| Heavy upfront work (~44 components to build/port) | H | H | Phased delivery; Phase 1 (strip) provides immediate token reduction value |
| CE upstream improvements missed | H | M | Watch CE releases; maintain a porting checklist; stack-agnostic agents diverge slowly |
| Command namespace collision | L | H | `/gc:` prefix on ALL commands, no exceptions |
| Plugin distribution logistics | M | M | Start with local install + GitHub repo; marketplace later |
| Agent prompts hallucinate GDScript APIs | H | H | Research-Driven Methodology: 4-step pipeline with source citations, Context7 API verification, synthetic test fixtures, and gdtoolkit cross-validation. Every FAIL/PASS example must trace to a Priority 1-4 source. |
| Compound schema speculative enums | M | M | Start with only values from first 3-5 real problems; `schema_version` for non-breaking growth |
| `Resource.duplicate(true)` Array/Dict bug | H | H | resource-safety-reviewer flags `.duplicate()` on Resources with exported Arrays; documented workaround |
| Agent name collision between plugins | M | M | CE and godot-compound both define `code-simplicity-reviewer.md`. System has no formal conflict resolution. Rename in fork (e.g., `gc-code-simplicity-reviewer`) or accept ambiguity. |
| Scope disproportionate to codebase size | H | M | Phase 1 alone provides token reduction value. Later phases built from researched patterns — the plugin is a standalone community tool, not coupled to any single project's codebase size. |
| `simplify` and `loop` commands missing | L | L | These don't exist as CE commands. Investigate whether they are skills or aliases before planning their fork. |
| `reproduce-bug` needs near-total rewrite | M | L | References Rails console, AppSignal, Playwright. Either rewrite for Godot (headless launch, GUT repro) or remove from v0.1. |
| Maintenance burden understated | H | H | Forking 142 files creates permanent obligation. Accept explicitly. Document a "when to re-evaluate merging back to layering" threshold (e.g., if CE token overhead drops below 10k in a future version). |

## Dependencies & Prerequisites

- **Compound Engineering plugin** v2.38.1 (source for fork)
- **Claude Code** with plugin support
- **pipx** + **gdtoolkit** v4.x for linting
- **Node.js** 18+ for Context7 MCP
- **GUT** 9.6.0 for Godot 4.6 test execution
- **Godot** 4.3+ (4.6.1 recommended)
- `docs/reference/godot-best-practices.md` — pattern validation source for all FAIL/PASS examples

## Future Considerations

- **Plugin marketplace distribution:** After v1.0, publish to Claude Code marketplace for community access
- **CE version tracking:** Watch CE releases for useful improvements to manually port (research agents, orchestration patterns)
- **Community contributions:** Accept PRs for new Godot-specific agents (shader-reviewer, animation-reviewer, etc.)
- **GUT integration:** Add a `gdscript-test-runner` agent using headless GUT with JUnit XML output
- **Custom `.tscn` validator:** No off-the-shelf tool exists; consider building a Python script for CI
- **graydwarf/godot-gdscript-linter:** Evaluate as complement to gdtoolkit (cyclomatic complexity, magic numbers)
- **Pre-commit hooks:** gdtoolkit's `.pre-commit-hooks.yaml` for automated formatting checks

## Sources & References

### Origin
- **Brainstorm document:** [docs/brainstorms/2026-03-19-godot-ce-plugin-fork-brainstorm.md](docs/brainstorms/2026-03-19-godot-ce-plugin-fork-brainstorm.md) — Key decisions: full fork (not selective/clean-room), `/gc:` namespace, separate repo, two-layer design, MIT license

### Superseded Plan
- [docs/plans/2026-03-19-feat-godot-ce-customization-plan.md](docs/plans/2026-03-19-feat-godot-ce-customization-plan.md) — Previous layering approach (Phase A complete, Phase B superseded by this plan). Research insights on agent design, compound schema, and gdtoolkit remain valid and are carried forward.

### Internal References
- `docs/reference/godot-best-practices.md` — Godot 4 patterns (43 sources) — validation source for all FAIL/PASS examples
- `docs/reference/claude-agent-tooling-reference.md` — CE architecture reference
- `docs/reference/godot-vscode-claude-setup.md` — VS Code + Godot integration

### CE Plugin References (fork source)
- `~/.claude/plugins/cache/compound-engineering-plugin/compound-engineering/2.38.1/` — Full plugin source (142 files, ~129k words)
- `agents/review/kieran-rails-reviewer.md` — Agent structure template (persona, principles, FAIL/PASS)
- `skills/compound-docs/schema.yaml` — Schema template for compound-godot
- `skills/compound-docs/assets/resolution-template.md` — Resolution document template
- `commands/ce/review.md` — Review command orchestration pattern
- `skills/create-agent-skills/references/best-practices.md` — Skill authoring best practices

### External References — Tools & Docs
- [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) — GDScript linting/formatting (24 rules)
- [GUT 9.6.0](https://github.com/bitwes/Gut) — Godot Unit Testing for 4.6
- [godot-code-coverage](https://github.com/jamie-pate/godot-code-coverage) — Coverage via GUT hooks
- [graydwarf/godot-gdscript-linter](https://github.com/graydwarf/godot-gdscript-linter) — Complexity detection (Feb 2026)
- [Godot 4.6 Release Notes](https://godotengine.org/releases/4.6/) — Node UIDs, no GDScript changes
- [GDScript Style Guide (official)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Static Typing in GDScript (official)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)
- [Optimization Using Servers (official)](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- [UID Changes in Godot 4.4 (blog)](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)

### External References — Tracked GitHub Issues (Agent Pattern Sources)
- Resource.duplicate(true) Array/Dict bug — [#74918](https://github.com/godotengine/godot/issues/74918), [#82348](https://github.com/godotengine/godot/issues/82348), [#105904](https://github.com/godotengine/godot/issues/105904); fix: [PR #100673](https://github.com/godotengine/godot/pull/100673)
- `resource_local_to_scene` failures — [#77380](https://github.com/godotengine/godot/issues/77380), [#94531](https://github.com/godotengine/godot/issues/94531), [#90597](https://github.com/godotengine/godot/issues/90597), [#115487](https://github.com/godotengine/godot/issues/115487)
- `.uid` sidecar dropped on external rename — [#104188](https://github.com/godotengine/godot/issues/104188), fix: [PR #104248](https://github.com/godotengine/godot/pull/104248)
- `queue_free` with async coroutine runs one more frame — [#93608](https://github.com/godotengine/godot/issues/93608)
- Deferred call execution timing undocumented — [godot-docs #6488](https://github.com/godotengine/godot-docs/issues/6488)
- `call_group` + `queue_free` unreliable — [godot-docs #11717](https://github.com/godotengine/godot-docs/issues/11717)
- Export crashes: missing resources — [#86317](https://github.com/godotengine/godot/issues/86317); custom Resources fail on export — [#77886](https://github.com/godotengine/godot/issues/77886); circular dependency — [#77007](https://github.com/godotengine/godot/issues/77007), [#80877](https://github.com/godotengine/godot/issues/80877) (meta-tracker)
- SceneTree traversal optimization — [PR #106244](https://github.com/godotengine/godot/pull/106244)
- `.tscn` validation proposal — [godot-proposals#10196](https://github.com/godotengine/godot-proposals/issues/10196)

### External References — Open-Source Reference Projects
- [food-please/godot4-open-rpg](https://github.com/food-please/godot4-open-rpg) — RPG with composition, signals, Resources
- [Phazorknight/Cogito](https://github.com/Phazorknight/Cogito) — Component-based interaction system
- [lampe-games/godot-open-rts](https://github.com/lampe-games/godot-open-rts) — Clean minimal RTS (~800 LoC)
- [Orama-Interactive/Pixelorama](https://github.com/Orama-Interactive/Pixelorama) — 9k+ LoC production GDScript app
- [dialogic-godot/dialogic](https://github.com/dialogic-godot/dialogic) — Custom Resources, gdUnit4, plugin architecture
- [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) — Official demos (FAIL source: issue #868 re: missing static typing)
- [gdquest-demos/godot-design-patterns](https://github.com/gdquest-demos/godot-design-patterns) — State machine reference
