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

## What Gets Stripped

| CE Component | Action | Reason |
|---|---|---|
| dhh-rails-reviewer | Remove | Rails-specific persona |
| kieran-rails-reviewer | Remove | Rails-specific patterns |
| kieran-typescript-reviewer | Remove | TypeScript-specific |
| kieran-python-reviewer | Remove | Python-specific |
| julik-frontend-races-reviewer | Remove | DOM/frontend races |
| agent-native-reviewer | Remove | Web app agent/user parity — irrelevant for games |
| data-migration-expert | Remove | Database migrations |
| schema-drift-detector | Remove | Rails schema.rb |
| deployment-verification-agent | Remove | Web deployment |
| data-integrity-guardian | Remove | Database integrity |
| figma-design-sync | Remove | Figma integration |
| design-implementation-reviewer | Remove | Web design comparison |
| design-iterator | Remove | Web design iteration |
| ankane-readme-writer | Remove | Ruby gem READMEs |
| dhh-rails-style skill | Remove | Rails coding style |
| andrew-kane-gem-writer skill | Remove | Ruby gems |
| dspy-ruby skill | Remove | Ruby LLM framework |
| every-style-editor skill | Remove | Every's editorial style |
| proof skill | Remove | Proof web editor |
| agent-browser skill | Remove | Web browser automation |
| frontend-design skill | Remove | Web frontend design |
| rclone skill | Remove | Cloud storage (not needed for game dev) |
| test-browser command | Remove | Web browser testing |
| feature-video command | Remove | Web feature recording |

## What Gets Replaced

| CE Component | Godot Replacement | Purpose |
|---|---|---|
| lint agent (standardrb + erblint) | gdscript-lint (gdformat + gdlint) | Code formatting and style |
| Rails test examples in /ce:work | GUT headless test commands | Test execution |
| Figma sync in /ce:work | Remove (no equivalent needed) | — |
| Browser screenshots in /ce:work | Remove (manual playtesting) | — |
| Database migration agents in /ce:review | Resource safety reviewer | Check .tres/.tscn integrity |
| Web-centric architecture-strategist | godot-architecture-reviewer | Scene composition, signals, autoloads |
| compound-docs schema.yaml (Cora enums) | Godot-specific schema (scene_composition, signal_wiring, resource_management, etc.) | Knowledge capture categories |

## What Gets Kept (Stack-Agnostic)

- **Research agents:** best-practices-researcher, framework-docs-researcher, learnings-researcher, repo-research-analyst, git-history-analyzer
- **Review agents:** code-simplicity-reviewer, performance-oracle, security-sentinel, pattern-recognition-specialist
- **Skills:** brainstorming, context-management, craft-prompt, plan, research, extend-plan, extend-research, git-worktree, create-agent-skills
- **Commands:** ce:plan (rewritten), ce:work (rewritten), ce:review (rewritten), ce:compound (rewritten), ce:brainstorm (rewritten), deepen-plan (rewritten), lfg, slfg
- **Infrastructure:** compound docs loop, file-todos, learnings search

## New Godot-Specific Components

### Agents to Build
- **gdscript-reviewer** — Static typing, member ordering, naming conventions, signal naming
- **godot-architecture-reviewer** — Composition over inheritance, call down/signal up, scene encapsulation, autoload discipline
- **resource-safety-reviewer** — .tres/.tscn integrity, .duplicate() checks, res:// reference safety, .uid sidecars
- **gdscript-lint** — gdformat + gdlint (already built)

### Skills to Build
- **godot-patterns** — Scene architecture, GDScript quality, Resource system (already built)
- **gdscript-lint** — Format and lint checks (already built)
- **compound-godot** — Godot-specific schema for knowledge capture

### Command Rewrites
All 5 core commands rewritten to reference:
- GUT instead of Rails/npm test commands
- gdtoolkit instead of standardrb/erblint
- Scene validation instead of database migrations
- Godot-specific acceptance criteria patterns

## Project-Specific Extension Layer

The plugin provides generic Godot CE tooling. RootsGame adds project-specific extensions via `.claude/agents/` and `.claude/skills/`:
- Monster-collection-specific review patterns
- Battle system architecture validation
- RPG data modeling checks (Species/Instance two-tier pattern)

This separation means the plugin is shareable; project-specific knowledge stays local.

## Resolved Questions

- **Naming:** `godot-compound` — short, clear, matches the pattern
- **Scope of /ce:work rewrite:** Keep incremental commit logic and todo tracking — useful even solo for session focus and clean git history
- **Agent prompt handling:** Rewrite all examples for Godot — replace Rails/TypeScript examples with GDScript equivalents in every agent (including "stack-agnostic" ones like performance-oracle, security-sentinel)
- **All-at-once scope:** Fork everything systematically in one pass, ensuring every agent and skill is tailored for Godot
- **Repo structure:** Separate repository (not inside RootsGame). Required for marketplace distribution and clean separation between game code and tooling.
- **Coexistence with CE:** Keep both plugins permanently. Use `/gc:` namespace prefix for godot-compound commands (`/gc:plan`, `/gc:work`, `/gc:review`, `/gc:compound`, `/gc:brainstorm`) to avoid collisions with `/ce:` commands. CE stays for any non-Godot side projects.

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
