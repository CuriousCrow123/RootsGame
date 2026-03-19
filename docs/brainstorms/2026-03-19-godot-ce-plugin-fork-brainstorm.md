---
topic: Fork CE Plugin for Godot
date: 2026-03-19
status: complete
participants: [alan, claude]
---

# Fork Compound Engineering Plugin for Godot

## What We're Building

A forked version of the Compound Engineering plugin (v2.38.1) stripped of all web/Rails/TypeScript content and rebuilt for Godot 4 + GDScript development. Designed as a standalone Claude Code plugin that can be shared with the Godot community, while allowing project-specific extensions.

## Why This Approach

### Problem
CE's 5 core commands (`/ce:plan`, `/ce:work`, `/ce:review`, `/ce:compound`, `/ce:brainstorm`) carry web-centric prompts that:
1. **Waste tokens** — Rails test examples, Figma sync, browser testing, database migration agents consume context even when skipped (~36k tokens total overhead)
2. **Give wrong advice** — Web framing causes agents to suggest N+1 query checks, Turbo patterns, DOM lifecycle concerns for a game project
3. **Scale poorly** — As the codebase grows, tighter context means more competition between web baggage and actual game code

### Why Full Fork (not Selective Fork or Clean-Room)
- **Selective Fork** keeps two plugins loaded, risking command collisions and still carrying some CE overhead
- **Clean-Room** loses the compound knowledge loop, research agent ecosystem, and deepen-plan infrastructure — these are genuinely valuable
- **Full Fork** gives complete control, zero web baggage, and preserves CE's proven patterns (Plan → Work → Review → Compound) while making them Godot-native

### Trade-offs Accepted
- Heavy upfront work: ~29 agents, ~45 skills, ~20 commands to audit
- Maintenance burden: must manually port useful CE improvements
- No upstream updates: diverges from CE's evolution

## Key Decisions

1. **Full fork of CE v2.38.1** — not a wrapper, not a clean-room build
2. **Strip all web content** — Rails, TypeScript, React, Figma, Playwright, browser testing, database migrations, DHH/Kieran persona reviewers
3. **Replace with Godot equivalents** — GUT testing, gdtoolkit linting, scene validation, Resource safety, signal architecture review
4. **Two-layer design** — generic Godot CE plugin (shareable) + project-specific extensions (RootsGame-specific agents/skills)
5. **Keep the compound knowledge loop** — `/ce:compound` with Godot-specific schema (scene_composition, signal_architecture, resource_management, etc.)
6. **Keep research agents** — best-practices-researcher, framework-docs-researcher, learnings-researcher, repo-research-analyst are stack-agnostic
7. **MIT license** — fork inherits CE's MIT license, shareable as open-source

## Full Audit Results

Every CE agent, skill, and command assessed for Godot relevance (2026-03-19 audit).

### Agents: REMOVE (15)

| Agent | Reason |
|---|---|
| dhh-rails-reviewer | Rails-specific persona |
| kieran-rails-reviewer | Rails-specific patterns |
| kieran-typescript-reviewer | TypeScript-specific |
| kieran-python-reviewer | Python-specific |
| agent-native-reviewer | Web app agent/user parity — irrelevant for games |
| data-migration-expert | Database migrations |
| schema-drift-detector | Rails schema.rb |
| data-integrity-guardian | Database integrity |
| security-sentinel | OWASP/web attack surfaces — `.tres` security handled by resource-safety-reviewer |
| figma-design-sync | Figma-to-HTML/CSS — Godot uses `.tscn` |
| design-implementation-reviewer | Web design comparison |
| design-iterator | Web design iteration |
| ankane-readme-writer | Ruby gem READMEs |
| every-style-editor | Every's editorial style |
| lint (CE version) | Uses standardrb/erblint — replaced by gdscript-lint |

### Agents: KEEP (10 — stack-agnostic)

| Agent | Notes |
|---|---|
| best-practices-researcher | Generic research methodology |
| framework-docs-researcher | Useful with Context7 for Godot docs |
| learnings-researcher | Searches docs/solutions/ — works for any domain |
| repo-research-analyst | Repo structure analysis — generic |
| git-history-analyzer | Git archaeology — generic |
| code-simplicity-reviewer | YAGNI principles — universal |
| pattern-recognition-specialist | Pattern/anti-pattern detection — generic |
| pr-comment-resolver | PR feedback resolution — generic |
| bug-reproduction-validator | Bug repro methodology — generic |
| spec-flow-analyzer | User flow analysis — generic |

### Agents: REWRITE for Godot (4)

| CE Agent | Godot Replacement | What Changes |
|---|---|---|
| architecture-strategist | godot-architecture-reviewer | Scene composition, signals, autoloads, inheritance depth instead of services/controllers |
| performance-oracle | godot-performance-reviewer | Scene tree traversal, draw calls, `_process` abuse, typed GDScript instead of N+1/SQL |
| julik-frontend-races-reviewer | godot-timing-reviewer | Signal emission timing, async loading races, `_process` vs `_input` ordering instead of DOM lifecycle |
| deployment-verification-agent | godot-export-verifier | Export build verification, asset integrity instead of SQL migrations |

### Skills: REMOVE (9)

| Skill | Reason |
|---|---|
| agent-browser | Web browser automation |
| andrew-kane-gem-writer | Ruby gems |
| dhh-rails-style | Rails conventions |
| dspy-ruby | Ruby LLM framework |
| every-style-editor | Every's style guide |
| frontend-design | Web frontend (HTML/CSS) |
| gemini-imagegen | Google image generation API |
| proof | Proof web editor sharing |
| rclone | Cloud storage — not needed for game dev |

### Skills: KEEP (9 — stack-agnostic)

| Skill | Notes |
|---|---|
| brainstorming | Generic methodology |
| compound-docs | Knowledge capture — works for any domain |
| context-management | Context window health — generic |
| create-agent-skills | Skill authoring — generic |
| document-review | Document quality review — generic |
| file-todos | Review findings tracking |
| git-worktree | Git worktree management — generic |
| orchestrating-swarms | Multi-agent coordination — generic |
| resolve-pr-parallel | Parallel PR resolution — generic |

### Skills: REWRITE for Godot (2)

| CE Skill | Godot Replacement | What Changes |
|---|---|---|
| setup | godot-setup | Detect `project.godot`, Godot version, GUT, gdtoolkit instead of Rails/Node/Python |
| compound-docs schema | compound-godot schema | Cora enums → Godot domains (scene_composition, signal_wiring, resource_management, etc.) |

### Commands: REMOVE (3)

| Command | Reason |
|---|---|
| test-browser | Web browser testing |
| test-xcode | iOS testing |
| feature-video | Web feature recording |

### Commands: KEEP (10 — stack-agnostic)

| Command | Notes |
|---|---|
| deepen-plan | Plan enhancement — generic |
| lfg | Autonomous pipeline — generic |
| slfg | Swarm pipeline — generic |
| simplify | Code quality review — generic |
| loop | Recurring task — generic |
| changelog | Git changelog — generic |
| triage | Finding triage — generic |
| resolve_todo_parallel | Todo resolution — generic |
| report-bug | Plugin bug report — generic |
| heal-skill | Skill repair — generic |

### Commands: REWRITE for Godot (5 core)

| CE Command | Godot Command | What Changes |
|---|---|---|
| /ce:plan | /gc:plan | GUT test references, gdtoolkit, scene validation criteria |
| /ce:work | /gc:work | GUT headless tests, no Figma/browser, Godot-specific acceptance patterns |
| /ce:review | /gc:review | Godot agent list, no database migration conditionals |
| /ce:compound | /gc:compound | Godot schema categories |
| /ce:brainstorm | /gc:brainstorm | Remove Proof sharing, game design focus |

## What Gets Replaced (Summary)

| CE Component | Godot Replacement | Purpose |
|---|---|---|
| lint agent (standardrb + erblint) | gdscript-lint (gdformat + gdlint) | Code formatting and style |
| Rails test examples in /gc:work | GUT headless test commands | Test execution |
| Figma sync in /gc:work | Remove (no equivalent needed) | — |
| Browser screenshots in /gc:work | Remove (manual playtesting) | — |
| Database migration agents in /gc:review | Resource safety reviewer | Check .tres/.tscn integrity |
| architecture-strategist | godot-architecture-reviewer | Scene composition, signals, autoloads |
| performance-oracle | godot-performance-reviewer | Scene tree, draw calls, _process abuse |
| julik-frontend-races-reviewer | godot-timing-reviewer | Signal timing, async loading, frame ordering |
| deployment-verification-agent | godot-export-verifier | Export build verification |
| security-sentinel | (removed — covered by resource-safety-reviewer) | — |
| compound-docs schema.yaml (Cora enums) | Godot-specific schema | Knowledge capture categories |

## What Gets Kept (Stack-Agnostic)

- **Research agents:** best-practices-researcher, framework-docs-researcher, learnings-researcher, repo-research-analyst, git-history-analyzer
- **Review agents:** code-simplicity-reviewer, pattern-recognition-specialist
- **Skills:** brainstorming, context-management, craft-prompt, plan, research, extend-plan, extend-research, git-worktree, create-agent-skills
- **Commands:** ce:plan (rewritten), ce:work (rewritten), ce:review (rewritten), ce:compound (rewritten), ce:brainstorm (rewritten), deepen-plan (rewritten), lfg, slfg
- **Infrastructure:** compound docs loop, file-todos, learnings search

## New Godot-Specific Components

### Agents: New (3)
- **gdscript-reviewer** — Static typing, member ordering, naming conventions, signal naming, FAIL/PASS GDScript examples
- **resource-safety-reviewer** — .tres/.tscn integrity, .duplicate() checks, res:// reference safety, .uid sidecars, .tres code execution
- **gdscript-lint** — gdformat + gdlint (already built in RootsGame, port to plugin)

### Agents: Rewritten from CE (4)
- **godot-architecture-reviewer** (from architecture-strategist) — Scene composition, call down/signal up, autoload discipline, inheritance depth. GDScript FAIL/PASS examples instead of services/controllers.
- **godot-performance-reviewer** (from performance-oracle) — Scene tree traversal, `_process`/`_physics_process` abuse, typed GDScript perf, draw calls, `set_process(false)` for off-screen. GDScript examples instead of N+1/SQL.
- **godot-timing-reviewer** (from julik-frontend-races-reviewer) — Signal emission timing, `await` race conditions, async resource loading, `_process` vs `_input` ordering. GDScript examples instead of DOM lifecycle.
- **godot-export-verifier** (from deployment-verification-agent) — Export build verification, asset integrity, scene reference validation. GDScript/Godot examples instead of SQL migrations.

### Skills: New (1)
- **compound-godot** — Godot-specific schema for knowledge capture (scene_composition, signal_wiring, resource_management, gdscript_patterns, etc.)

### Skills: Already Built (port to plugin) (2)
- **godot-patterns** — Scene architecture, GDScript quality, Resource system
- **gdscript-lint** — Format and lint checks

### Skills: Rewritten from CE (1)
- **godot-setup** (from setup) — Detect `project.godot`, Godot version, GUT, gdtoolkit instead of Rails/Node/Python

### Commands: Rewritten (5 core + 5 utilities)
All `/gc:` commands rewritten to reference:
- GUT instead of Rails/npm test commands
- gdtoolkit instead of standardrb/erblint
- Scene/Resource validation instead of database migrations
- Godot-specific acceptance criteria patterns
- No Figma, browser testing, or Proof sharing

### Totals

| Category | Keep | Rewrite | New | Remove |
|---|---|---|---|---|
| Agents | 10 | 4 | 3 | 15 |
| Skills | 9 | 2 | 1 | 9 |
| Commands | 10 | 5 | 0 | 3 |
| **Total** | **29** | **11** | **4** | **27** |

## Project-Specific Extension Layer

The plugin provides generic Godot CE tooling. RootsGame adds project-specific extensions via `.claude/agents/` and `.claude/skills/`:
- Monster-collection-specific review patterns
- Battle system architecture validation
- RPG data modeling checks (Species/Instance two-tier pattern)

This separation means the plugin is shareable; project-specific knowledge stays local.

## Resolved Questions

- **Naming:** `godot-compound` — short, clear, matches the pattern
- **Scope of /ce:work rewrite:** Keep incremental commit logic and todo tracking — useful even solo for session focus and clean git history
- **Agent prompt handling:** Rewrite all examples for Godot — replace Rails/TypeScript examples with GDScript equivalents in every agent (including "stack-agnostic" ones like performance-oracle, pattern-recognition-specialist)
- **All-at-once scope:** Fork everything systematically in one pass, ensuring every agent and skill is tailored for Godot
- **Repo structure:** Separate repository (not inside RootsGame). Required for marketplace distribution and clean separation between game code and tooling.
- **Coexistence with CE:** Keep both plugins permanently. **All** godot-compound commands use the `/gc:` namespace prefix — no exceptions. This includes commands that CE ships without prefix. Full mapping:
  - `/gc:plan`, `/gc:work`, `/gc:review`, `/gc:compound`, `/gc:brainstorm` (core workflow)
  - `/gc:deepen-plan`, `/gc:lfg`, `/gc:slfg` (automation)
  - `/gc:simplify`, `/gc:loop` (utilities)
  - CE stays for non-Godot side projects with its own `/ce:` and unprefixed commands.

## Implementation Methodology

Three principles guide every agent, skill, and command built for `godot-compound`:

### 1. Cross-Analyze with Godot Best Practices Research

Every new or rewritten component must be validated against `docs/reference/godot-best-practices.md` (43 sources) and the `godot-patterns` skill reference files. Specifically:

- **Agents:** Each FAIL/PASS example must trace back to a documented pattern or anti-pattern in the research. No invented rules — if it's not in the research, it's not in the agent.
- **Skills:** Reference content must be a distilled, agent-consumable version of the research findings, not a rewrite from memory.
- **Commands:** Workflow steps (testing, linting, validation) must match the tooling and processes validated in the research (GUT two-step headless, gdtoolkit, `godot --headless` validation).

This prevents hallucinated patterns and ensures the plugin encodes real Godot community wisdom.

### 2. Validate Real-World Practicality via Web Research

Before building each component, research whether the patterns it checks for actually come up in real Godot development:

- **For each review agent:** Search for real Godot forum posts, GitHub issues, and community discussions where the pattern/anti-pattern caused actual bugs. If nobody has ever hit the problem, the agent is speculative — defer or remove it.
- **For each skill:** Verify the workflow it supports is something Godot developers actually do. E.g., is headless export testing a real practice? Do teams actually use `.tres` for save files?
- **For schema categories:** Validate that the compound knowledge categories map to problems Godot developers actually encounter and search for.

Use web search with queries like `"godot 4" site:forum.godotengine.org [pattern]`, `"godot" site:github.com/godotengine/godot/issues [problem]`, and GDQuest/Shaggy Dev tutorials to confirm real-world relevance.

### 3. Follow CE's Orchestration Patterns

The fork must preserve CE's proven orchestration architecture — not just the concepts, but the specific structural patterns that make agents effective:

- **Agent structure:** Study `kieran-rails-reviewer.md` and `performance-oracle.md` as templates. Note how they use persona framing, numbered review principles, FAIL/PASS code blocks, priority ordering, and explicit scope boundaries. Godot agents must follow the same structural patterns with GDScript content.
- **Skill structure:** Study `compound-docs/SKILL.md` and `brainstorming/SKILL.md`. Note how they use phased execution, parallel sub-agent dispatch, YAML frontmatter validation, and template-based output. Godot skills must follow the same orchestration patterns.
- **Command structure:** Study `ce/work.md` and `ce/review.md`. Note the task-execution-loop pattern, incremental commit evaluation, conditional agent dispatch, and quality-gate checklists. Godot commands must follow the same workflow architecture with Godot-specific content.
- **Token budgets:** CE agents target 90-120 lines (~900 tokens). Skills use reference files loaded on demand (150-250 lines each). Commands can be longer but should minimize examples-as-instructions. Match these budgets in the fork.

The goal is that someone familiar with CE instantly recognizes the patterns in `godot-compound` — same architecture, different domain.

## Open Questions

- **Plugin distribution:** Claude Code marketplace, GitHub repo, or both?
- **CE version tracking:** How to track useful CE improvements for manual porting? Watch CE releases? RSS?

## Success Criteria

- Zero web-specific tokens in any command prompt
- `/gc:review` dispatches only Godot-relevant agents
- `/gc:compound` captures Godot solutions with findable categories
- `/gc:work` references GUT tests and gdtoolkit, not Rails/npm
- Plugin installable by any Godot developer via `claude /plugin add`
- Token overhead reduced from ~36k to <15k
- `/gc:` and `/ce:` commands coexist without collisions
