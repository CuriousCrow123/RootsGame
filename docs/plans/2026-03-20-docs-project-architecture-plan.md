---
title: "docs: Project Architecture Reference"
type: docs
status: completed
date: 2026-03-20
origin: docs/brainstorms/2026-03-20-project-architecture-docs-brainstorm.md
---

# Project Architecture Reference

## Overview

Write a comprehensive `docs/PROJECT_ARCHITECTURE.md` that describes how every system in RootsGame works — current state, projected extensions, and rationale for non-obvious choices. Single file, systems-first organization, dual audience (human context recovery + AI agent orientation).

## Problem Statement / Motivation

Architecture knowledge is currently scattered across CLAUDE.md (prescriptive rules), `.claude/rules/` (scoped patterns), plan documents (historical implementation details), brainstorms (decision rationale), and the code itself. No single document answers "how does X work?" for any system. An agent starting a new session or a developer returning from a break must reconstruct this from source — slow and error-prone.

## Proposed Solution

A single `docs/PROJECT_ARCHITECTURE.md` following the 17-section outline from the brainstorm (see brainstorm: [docs/brainstorms/2026-03-20-project-architecture-docs-brainstorm.md](docs/brainstorms/2026-03-20-project-architecture-docs-brainstorm.md)), with gap resolutions from SpecFlow analysis incorporated.

### Gap Resolutions

SpecFlow analysis identified 13 gaps. Resolutions carried into the implementation:

| Gap | Resolution | Section |
|-----|-----------|---------|
| Camera system absent from outline | Add as subsection of World & Scene Management | §9 |
| Input Map absent from outline | Add as subsection of Game Modes (input actions table + gating) | §13 |
| Dialogue Balloon ownership unclear | Owned by Dialogue System (instantiated by addon, not HUD) | §6 |
| Signal Architecture doesn't fit standard template | Use signal map table format instead (signal / emitter / consumer / purpose) | §12 |
| Projected Systems Summary doesn't fit standard template | Use categorized list with back-references to inline `[PROJECTED]` markers | §17 |
| Physics Layers section is thin | Keep terse — table of layers + masks per entity type. Skip forced "How it works" prose | §14 |
| Contract description convention undefined | Describe mechanics, link to CLAUDE.md for normative rules. Never restate rules verbatim | All |
| `.claude/rules/` files not acknowledged | Reference existence in relevant sections ("See also: `.claude/rules/<file>`") | §4, §9, §10, §11 |
| No maintenance trigger defined | Add "Maintenance" section with update triggers | End of doc |
| No freshness marker | Add "Current as of: YYYY-MM-DD" at document top | Top |
| `extra_game_states` bridge spans 3 sections | §6 (Dialogue) owns full explanation; §7 and §8 back-reference | §6, §7, §8 |
| `connect_to_player()` spans Entity + UI | §11 (UI) owns pattern; §4 (Entity) documents player's public API | §4, §11 |
| Scene reload guarantee affects multiple systems | §10 (Persistence) covers the cross-system timing with a flow diagram | §10 |

### Scope Boundary Convention

**CLAUDE.md** prescribes rules ("you must do X"). **PROJECT_ARCHITECTURE.md** describes mechanics ("this is how X works"). When a system implements a CLAUDE.md-prescribed contract, the architecture doc:
1. Names the contract and links to CLAUDE.md
2. Describes the implementation mechanics (how SaveManager validates, how WorldState iterates)
3. Does NOT restate the rule text

**`.claude/rules/`** contain scoped patterns auto-injected when editing specific files. The architecture doc references their existence in relevant sections but does not duplicate their content.

## Technical Approach

### Document Structure

```
docs/PROJECT_ARCHITECTURE.md
├── Header (title, "Current as of" date, audience note)
├── §1  Project Overview
├── §2  Directory Structure
├── §3  Autoload Architecture
├── §4  Entity System
├── §5  State Machine
├── §6  Dialogue System (owns extra_game_states bridge)
├── §7  Quest System (back-refs §6 for dialogue bridge)
├── §8  Inventory System (back-refs §6 for dialogue bridge)
├── §9  World & Scene Management (includes Camera subsection)
├── §10 World State & Persistence (includes save/load flow)
├── §11 UI System (owns connect_to_player pattern)
├── §12 Signal Architecture (table format, not standard template)
├── §13 Game Modes (includes Input Map subsection)
├── §14 Physics Layers (terse table)
├── §15 Resource Patterns
├── §16 Testing
├── §17 Projected Systems Summary (categorized list + back-refs)
└── §18 Maintenance (update triggers, related docs)
```

### Per-Section Template (standard sections)

```markdown
## [Section Name]

[What it does — 1-2 sentences]

**Key files:**
- `scripts/path/to/file.gd` — brief role
- `scenes/path/to/scene.tscn` — brief role

### How It Works

[Implementation details, contracts, data flow. Use code snippets sparingly — only for contracts or non-obvious patterns.]

### Why This Way

[Rationale for non-obvious choices. Omit if the approach is conventional.]

### [PROJECTED] Extensions

[Inline markers for planned future work.]
```

**Exceptions:** §12 (Signal Architecture) uses a signal map table. §14 (Physics Layers) uses a compact table. §17 (Projected Systems Summary) uses a categorized list with section back-references.

**Length discipline:** This is a reference document — concise beats comprehensive. Target 150-300 words per standard section. Use tables and bullet lists over prose. Code snippets only for contracts or non-obvious patterns (3-8 lines max). If a section exceeds 400 words, split or trim. §3 (Autoloads) and §10 (Persistence) may run longer due to interdependency maps and flow sequences — that's acceptable if the extra length is structural (tables, lists), not narrative.

### Source Material

Each section draws from specific files. The author should read these before writing:

| Section | Primary Sources |
|---------|----------------|
| §1 Overview | `project.godot`, brainstorm, plan frontmatter |
| §2 Directory | `ls -R` output, file headers |
| §3 Autoloads | All 7 scripts in `scripts/autoloads/` + `addons/dialogue_manager/dialogue_manager.gd` registration |
| §4 Entity | `scripts/player/player_controller.gd`, `scripts/interactables/*.gd`, `scenes/player/player.tscn`, `scenes/interactables/*.tscn` |
| §5 State Machine | `shared/state_machine/*.gd`, `scripts/player/player_states/*.gd` |
| §6 Dialogue | `addons/dialogue_manager/`, `resources/dialogue/npc_greeting.dialogue`, `scripts/interactables/npc_interactable.gd` |
| §7 Quest | `resources/quests/*.gd`, `resources/quests/fetch_quest.tres`, `scripts/quest/quest_tracker.gd` |
| §8 Inventory | `resources/items/*.gd`, `resources/items/key_item.tres`, `scripts/inventory/inventory.gd` |
| §9 World/Scene | `scripts/autoloads/scene_manager.gd`, `scenes/world/*.tscn`, `scripts/camera/camera_follow.gd`, `scripts/interactables/door_interactable.gd` |
| §10 Persistence | `scripts/autoloads/world_state.gd`, `scripts/autoloads/save_manager.gd` |
| §11 UI | `scripts/autoloads/hud.gd`, `scripts/ui/*.gd`, `scenes/ui/*.tscn` |
| §12 Signals | All `.gd` files (grep for `signal `, `.connect(`, `.emit(`) |
| §13 Game Modes | `scripts/autoloads/game_state.gd`, `project.godot` input map, player states |
| §14 Physics | `project.godot` layer names, entity collision_layer/mask values |
| §15 Resources | `resources/items/item_data.gd`, `resources/quests/quest_data.gd`, `resources/quests/quest_step_data.gd` |
| §16 Testing | `tests/unit/*.gd`, `tests/integration/*.gd` |
| §17 Projected | Plan phases, brainstorm build order, `GameMode.BATTLE`/`CUTSCENE` enum values |

## Implementation Phases

Phases are organizational groupings, not hard dependencies. The implementer can write sections in any order. The grouping reflects a natural reading order: orient (§1-§2) → foundations (§3-§5) → gameplay (§6-§8) → infrastructure (§9-§11) → cross-cutting (§12-§16) → wrap-up (§17-§18).

### Phase 1: Structural Sections (§1-§2)

Write the foundational sections that orient readers before diving into systems.

- [x] **§1 Project Overview** — tech stack (Godot 4.6.1, GDScript, 3D orthographic), current milestone (Phase 4 completed — playable loop with 2 rooms, save/load, quests), inspiration (Cassette Beasts-style RPG, core mechanic TBD)
- [x] **§2 Directory Structure** — annotated tree of `scripts/`, `scenes/`, `resources/`, `shared/`, `tests/`, `addons/`, `docs/` with purpose notes per folder

### Phase 2: Core Systems (§3-§5)

The foundational systems that everything else builds on.

- [x] **§3 Autoload Architecture** — all 7 autoloads in load order, responsibilities, interdependency map (who references whom), why `.gd`-only (link CLAUDE.md)
- [x] **§4 Entity System** — Player composition (CharacterBody3D + child nodes), interactable duck-typing contract (`interact(player)`), player's public API (`get_inventory()`, `get_quest_tracker()`, `nearest_interactable_changed`). Reference `.claude/rules/interactable-patterns.md`
- [x] **§5 State Machine** — StateMachine/State base classes, transition model (`state_finished` signal), player states (Idle/Walk/Interact), GameMode gating in states

### Phase 3: Gameplay Systems (§6-§8)

The systems that create the playable loop.

- [x] **§6 Dialogue System** — Dialogue Manager addon (stateless/headless), `.dialogue` file syntax, **`extra_game_states` bridge pattern** (NPC passes `[quest_tracker, inventory, self]`, DM resolves method calls), dialogue balloon lifecycle, `is_instance_valid` guard
- [x] **§7 Quest System** — QuestData/QuestStepData resources (linked-list steps), QuestTracker lifecycle (INACTIVE→ACTIVE→COMPLETE), dialogue-driven logic (back-ref §6 for bridge), save contract (resource_path for reload). Reference `.claude/rules/autoload-patterns.md` for typed dict rebuild
- [x] **§8 Inventory System** — ItemData resource (read-only definition), flat `Array[Dictionary]` storage (`{item_id, quantity}`), signals (`item_added`/`item_removed`), save contract, back-ref §6 for `has_item()`/`remove_item()` via dialogue

### Phase 4: Infrastructure Systems (§9-§11)

Scene management, persistence, and UI.

- [x] **§9 World & Scene Management** — room structure (Node3D + GridMap + entities + spawn Marker3Ds), SceneManager transition flow (fade → snapshot → change_scene_to_file → await scene_changed → restore → position → fade), persistent player pattern (reparented to root, duplicate detection), **Camera subsection** (per-room Camera3D with `camera_follow.gd`, group-based player lookup, lerp follow). Reference `.claude/rules/autoload-patterns.md`
- [x] **§10 World State & Persistence** — two-tier architecture (WorldState for session state, SaveManager for disk), registrar pattern with assert validation, save format (JSON at `user://saves/save_001.json`), atomic write, **load sequence flow** (reload scene → wait scene_changed → overwrite WorldState → restore → restore remaining saveables), clear-then-rebuild contract (link CLAUDE.md). Reference `.claude/rules/autoload-patterns.md` and `.claude/rules/interactable-patterns.md`
- [x] **§11 UI System** — HUD autoload (instantiates 4 UI scenes), **`connect_to_player()` pattern** (HUD calls via `.call()` when `player_registered` fires), pause menu lifecycle (GameMode.MENU, tree pause, save/load gating), `process_mode = PROCESS_MODE_ALWAYS`. Reference `.claude/rules/ui-patterns.md`

### Phase 5: Cross-Cutting & Reference Sections (§12-§16)

Sections that span systems or serve as reference tables.

- [x] **§12 Signal Architecture** — signal map table (signal name / emitter / consumer(s) / purpose), "call down signal up" principle, EventBus policy (intentionally empty — no signal currently needs it), group-based `.call()` dispatch pattern
- [x] **§13 Game Modes** — GameState enum (OVERWORLD, BATTLE, MENU, DIALOGUE, CUTSCENE), current mode transitions, synchronous `set_mode()` emission, **Input Map subsection** (table of 7 actions + keys + consuming systems + mode gating)
- [x] **§14 Physics Layers** — compact table of 4 layers + per-entity collision_layer and collision_mask assignments
- [x] **§15 Resource Patterns** — two-layer pattern (Resource for data, Node for behavior), 3 custom resource types (ItemData, QuestData, QuestStepData), `.duplicate()` rule (link CLAUDE.md), `preload()` preference
- [x] **§16 Testing** — GUT framework, 6 unit tests + 3 integration tests, what each covers, test naming pattern

### Phase 6: Projected & Maintenance (§17-§18)

- [x] **§17 Projected Systems Summary** — consolidated list of all `[PROJECTED]` markers with section back-references: combat/battle system (§5 state machine, §13 game modes), navigation (§9 world), art migration (§4 entities, §9 world), audio (new system), extended quest types (§7), item categories/equipment (§8)
- [x] **§18 Maintenance** — update triggers (new autoload, new resource type, new system-level script), related docs (CLAUDE.md for rules, `.claude/rules/` for scoped patterns, `docs/plans/` for implementation history)
- [x] **Final pass** — add "Current as of: 2026-03-20" header, verify all section cross-references resolve, check that every `[PROJECTED]` inline marker has a §17 entry

## Acceptance Criteria

- [ ] Single file at `docs/PROJECT_ARCHITECTURE.md`
- [ ] All 18 sections present (17 from brainstorm + Maintenance)
- [ ] Every autoload, script, scene, and resource type in the project is mentioned in at least one section
- [ ] Gap resolutions implemented: Camera in §9, Input Map in §13, Dialogue Balloon in §6, signal map table in §12
- [ ] `[PROJECTED]` markers appear inline in relevant sections AND consolidated in §17
- [ ] CLAUDE.md rules are linked, not restated
- [ ] `.claude/rules/` files are referenced in relevant sections
- [ ] Cross-references work: §6↔§7↔§8 (dialogue bridge), §4↔§11 (connect_to_player), §10 (load sequence spans systems)
- [ ] "Current as of" date at document top
- [ ] No prescriptive rules (that's CLAUDE.md's job) — purely descriptive

## Sources & References

- **Origin brainstorm:** [docs/brainstorms/2026-03-20-project-architecture-docs-brainstorm.md](docs/brainstorms/2026-03-20-project-architecture-docs-brainstorm.md) — key decisions: single file, systems-first, inline `[PROJECTED]`, descriptive not prescriptive, dual audience
- **Foundation plan:** [docs/plans/2026-03-19-feat-rpg-playable-loop-foundation-plan.md](docs/plans/2026-03-19-feat-rpg-playable-loop-foundation-plan.md) — implementation history and architectural decisions
- **RPG brainstorm:** [docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md](docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md) — original architecture decisions (3D ortho, two-layer pattern, Dialogue Manager choice)
- **Scene transition retrospective:** [docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md](docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md) — 7 bugs that shaped current autoload/timing patterns
- **Cassette Beasts reference:** [docs/research/cassette-beasts-technical-reference.md](docs/research/cassette-beasts-technical-reference.md) — inspiration game technical breakdown
