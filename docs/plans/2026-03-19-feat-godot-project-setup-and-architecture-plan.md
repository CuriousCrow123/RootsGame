---
title: "feat: Initialize Godot 4 Project with RPG Architecture"
type: feat
status: completed
date: 2026-03-19
deepened: 2026-03-19
completed: 2026-03-19
---

# feat: Initialize Godot 4 Project with RPG Architecture

## Enhancement Summary

**Deepened on:** 2026-03-19
**Research sources:** Context7 Godot 4.4 docs, GUT 9.x docs, 6 web searches, godot-patterns skill (3 reference files), godot-best-practices.md (43 sources)
**Review agents used:** architecture-strategist, security-sentinel, performance-oracle, code-simplicity-reviewer, pattern-recognition-specialist

### Key Improvements
1. **[CRITICAL] SaveManager security fix** — `ResourceLoader.load()` on `.tres` files can execute arbitrary GDScript. Replaced with JSON-based serialization or type-checked loading with security comment.
2. **[HIGH] SceneManager signal timing fix** — `scene_change_finished` emitted before scene actually changes. Fixed with `await get_tree().process_frame` and error handling for async loading.
3. **[HIGH] YAGNI reduction** — Marked SaveManager, SceneManager, and pre-defined EventBus signals as deferrable. Minimum viable foundation identified: git + project.godot + main scene + VS Code + empty EventBus + GUT.
4. **[MEDIUM] `.gitattributes` merge strategy fix** — Removed `merge=union` for `.tscn` files (corrupts structured scene files).
5. **[MEDIUM] StateMachine member ordering fix** — Signal callback `_on_state_finished` moved before public method `transition_to`.
6. **New: `set_active()` method** on StateMachine for off-screen optimization.
7. **New: GUT CI/headless best practices** — Two-step import-then-test pattern for reliable headless testing.
8. **New: Species data loading strategy** — Guidance on preload vs lazy-load for scaling to hundreds of `.tres` data files.

### New Considerations Discovered
- `GameState.flags` should use typed Dictionary (`Dictionary[StringName, Variant]`) in Godot 4.4+
- `State.finished` signal should be renamed to `state_finished` for noun_verb consistency
- EventBus/SceneManager signal overlap needs documented resolution
- GameState setter could fire signal before listeners connect if default enum value changes
- GUT headless requires two-step process: `--import --quit` then test run

---

## Overview

Bootstrap the RootsGame Godot 4.4+ project from an empty directory into a fully configured, architecturally sound foundation for a Cassette Beasts-style monster-collection RPG. Covers git initialization, Godot project setup, VS Code integration, folder structure, autoload services, base classes (state machines, Resources), GUT testing, and a minimal runnable main scene. This plan is complementary to the existing [CE customization plan](2026-03-19-feat-godot-ce-customization-plan.md), which layers AI tooling on top of the foundation built here.

## Problem Statement

RootsGame currently contains only `docs/` (research and reference materials) and `.obsidian/` (knowledge base). No Godot project, no git repository, no VS Code configuration, and no game code exists. Before any game development — or before the CE customization plan can be executed — the project foundation must be built.

## Proposed Solution

A single-pass setup executed in strict dependency order across 7 phases. Each phase produces verifiable artifacts. The architecture follows Godot best practices synthesized from 43+ sources (see `docs/reference/godot-best-practices.md`).

### Key Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| File naming | `snake_case.gd` | Godot community standard, `gdlint` compatible, case-sensitivity safe across platforms |
| Script location | Co-located with scenes | `player.gd` next to `player.tscn` — one folder per entity |
| Autoload pattern | Individual service autoloads (4-6) | Simpler than Services-in-one-node pattern for a solo project; upgrade path exists |
| State machine | Node-based (State + StateMachine base classes) | Needed for 5+ state entities (player, battle); enum-based used ad hoc for simple objects |
| Data modeling | Two-tier Resources (Species template + Instance) | Separates static game data from mutable runtime state; serializes natively |
| Communication | "Call down, signal up" + EventBus for cross-system | Cardinal Godot rule; EventBus only for genuinely homeless signals |
| Typing | Static typing enforced via project settings | 28-59% perf gain + catches errors at parse time + enables LSP completions |
| Formatter | `gdformat` (gdtoolkit) only | Single source of truth; VS Code `formatOnSave` disabled to avoid formatter conflicts |
| Battle/overworld | Separate scene trees with SceneManager transitions | Avoids state management nightmares of shared scene trees |
| Dialog system | Deferred (custom vs Dialogic 2 decision after prototyping) | Too early to commit; both viable |

### Critical Resolutions (from SpecFlow analysis)

These ambiguities were identified during analysis and resolved here:

1. **MCP servers in this plan:** None. MCP is handled by the [CE customization plan](2026-03-19-feat-godot-ce-customization-plan.md). This plan creates the `project.godot` that godot-mcp requires.
2. **Static typing in `project.godot`:** Written programmatically. `project.godot` is INI-like text; the `[debug]` section accepts `gdscript/warnings/untyped_declaration=2` directly. Verified empirically.
3. **File naming:** `snake_case.gd` (not `kebab-case.gd`). The reference doc's `kebab-case` recommendation is overridden — it conflicts with `gdlint` and Godot's official style guide.
4. **GUT installation:** Git submodule into `addons/gut/`. Reproducible, CLI-compatible, no GUI required.
5. **Formatter conflict:** Disable VS Code `formatOnSave`. Use `gdformat` as the sole formatter (invoked via lint agent or manually).
6. **Main scene:** Create a minimal `scenes/main/main.tscn` so F5 works immediately.
7. **Autoload location:** `scripts/autoloads/` directory.
8. **`.obsidian/`:** Added to `.gitignore` (personal knowledge base config).

### YAGNI Assessment (from Simplicity Review)

The simplicity reviewer identified that several components are premature for a project with zero game code. The plan retains them as **scaffolding** with the understanding that they establish patterns — but each is marked with its deferral status:

| Component | Verdict | Rationale |
|---|---|---|
| EventBus (empty shell) | **Keep** | Zero cost, establishes the pattern, signals added as needed |
| GameState | **Keep but simplify** | Mode enum is useful immediately for input handling; flags dict deferred |
| SceneManager | **Defer until Phase 2 feature** | One scene exists; `get_tree().change_scene_to_file()` suffices for now |
| SaveManager | **Defer until saveable data exists** | No Resources to serialize; security concerns require careful design |
| State machine base classes | **Keep** | First consumer (player controller) is the next planned feature |
| Deep folder structure | **Slim down** | Create only directories that contain files; add others on first use |
| GUT smoke test | **Keep 1 test** | Framework verification; remove `test_static_typing_enforced` |

**Minimum viable foundation:** git + `project.godot` + `main.tscn` + `.vscode/` + empty EventBus + GameState (mode enum only) + StateMachine base classes + GUT with 1 smoke test. Everything else is created when the first feature demands it.

## Technical Approach

### Architecture

```
res://
├── project.godot
├── .gitignore
├── .gitattributes
├── addons/                         # Third-party (GUT, future addons)
│   └── gut/                        #   GUT testing framework (git submodule)
├── scripts/
│   └── autoloads/                  # Global singletons
│       ├── event_bus.gd            #   Cross-system signal relay
│       └── game_state.gd           #   Game mode, progression flags
├── scenes/
│   └── main/
│       └── main.tscn               # Minimal entry point scene
├── entities/                       # Self-contained game objects (created on first use)
├── data/                           # Game data as .tres Resources (created on first use)
├── shared/                         # Cross-entity shared resources
│   └── state_machine/              #   StateMachine + State base classes
│       ├── state.gd
│       └── state_machine.gd
├── tests/                          # GUT test scripts
│   └── unit/
│       └── test_example.gd         #   Smoke test to verify GUT works
└── .vscode/
    ├── settings.json
    ├── launch.json
    └── extensions.json
```

> **Note:** Directories like `ui/`, `battle/`, `world/`, `data/monsters/`, etc. are created when the first file that belongs there is written. `mkdir -p` takes 0.1 seconds — do not create empty directories with `.gitkeep` files.

### Autoload Definitions

| Name | File | Purpose | Signals |
|---|---|---|---|
| `EventBus` | `scripts/autoloads/event_bus.gd` | Signal relay for decoupled cross-system communication | Empty initially — add signals as systems are built |
| `GameState` | `scripts/autoloads/game_state.gd` | Current game mode enum | `game_state_changed` |

> **Deferred autoloads:** `SceneManager` and `SaveManager` are built when their first consumer exists. See YAGNI Assessment above.

> **Autoload consolidation rule:** If autoload count exceeds 5-6, consolidate into a `Services` facade autoload to prevent hidden coupling accumulation. (Source: architecture review, referencing Manuel Sanchez Dev's experience with large RPGs.)

### Research Insights: Autoloads

**Best Practices (from Context7 Godot 4.4 docs):**
- Autoloads are globally accessible singletons — use them for truly global state, not per-scene concerns
- No cross-autoload dependencies in `_ready()` — maintain this as an invariant
- AudioManager autoload (future): defer audio bank preloading to after the first frame renders to avoid blocking startup

**Performance (from performance review):**
- All planned autoloads are constant-cost singletons with negligible initialization
- Even at 8-12 autoloads, there is no measurable performance impact

### Base Classes

**StateMachine** (`shared/state_machine/state_machine.gd`):
- Manages child `State` nodes
- Delegates `_process`, `_physics_process`, `_unhandled_input` to current state
- Exposes `transition_to(target_state_path: String, data: Dictionary)` method
- **NEW: `set_active(active: bool)` method** — disables all three callbacks for off-screen optimization

**State** (`shared/state_machine/state.gd`):
- Abstract base: `enter()`, `exit()`, `handle_input()`, `update()`, `physics_update()`
- Emits `state_finished(next_state_path: String, data: Dictionary)` signal (renamed from bare `finished` for noun_verb consistency)
- All methods are virtual no-ops by default

### Research Insights: State Machines

**Best Practices (from web research + GDQuest + Shaggy Dev):**
- Node-based approach allows visualizing states in the editor without plugins
- Each state in a separate script keeps code compartmentalized and short
- Hierarchical states: subclass a base state and call `super()` to inherit physics behavior
- Concurrent state machines: separate movement from attack with independent state machines
- **Data management:** State machines are for state-dependent logic. Character stats, stamina, etc. belong on the entity, not in states
- Co-locate entity-specific states with the entity (e.g., `entities/player/states/idle_state.gd`), not in `shared/`

**Performance (from performance review):**
- Delegation overhead is negligible: one null check + one typed method call per frame (~microseconds)
- With static typing enforced, GDScript uses faster typed dispatch paths
- Real concern is the number of active state machines — use `set_active(false)` on off-screen entities
- For a Cassette Beasts-style RPG: at most 10-15 active state machines simultaneously

### Implementation Phases

#### Phase 1: Git Repository

**What:** Initialize git with proper ignore and merge configuration.
**Files:** `.gitignore`, `.gitattributes`
**Depends on:** Nothing
**Verification:** `git status` shows clean repo with `docs/` tracked

Steps:
1. `git init`
2. Create `.gitignore`:
   ```
   # Godot
   .godot/
   .import/
   export.cfg
   export_presets.cfg
   export_credentials.cfg
   *.translation

   # Export artifacts
   *.pck
   *.apk
   *.aab
   *.ipa

   # Signing keys
   *.key
   *.keystore
   *.jks

   # Environment / secrets
   .env
   *.env
   *.secret

   # OS
   .DS_Store
   Thumbs.db

   # Editor
   .obsidian/
   *.tmp

   # Mono (future-proofing)
   .mono/
   data_*/
   mono_crash.*.json

   # Android build
   android/build/
   ```

   > **Research insight (security review):** Added patterns for export artifacts (`.pck`, `.apk`), signing keys (`.keystore`, `.jks`), environment files (`.env`), and Android build directory. These prevent accidental commit of secrets and large binaries.

3. Create `.gitattributes`:
   ```
   # Normalize line endings
   * text=auto eol=lf

   # Godot text files
   *.gd text
   *.tscn text
   *.tres text
   *.cfg text
   *.godot text
   *.import text
   ```

   > **Research insight (architecture review):** Removed `*.tscn merge=union` and `*.tres merge=union`. Union merge on `.tscn` files can silently produce corrupt scenes — duplicate `ext_resource` IDs that Godot cannot parse. For a solo project, merge conflicts are unlikely, and manual resolution is safer than automatic corruption. (Source: [Godot proposals #1281](https://github.com/godotengine/godot-proposals/issues/1281), [Godot VCS docs](https://docs.godotengine.org/en/4.4/tutorials/best_practices/version_control_systems.html))

4. Remove existing `.DS_Store`: `find . -name .DS_Store -delete`
5. Initial commit: `git add . && git commit -m "docs: add research and reference materials"`

#### Phase 2: Godot Project Initialization

**What:** Generate `project.godot` with correct settings, enforce static typing.
**Files:** `project.godot` (auto-generated + manually edited)
**Depends on:** Phase 1
**Verification:** `godot --headless --path . --quit` exits cleanly; `.godot/` directory created

Steps:
1. Verify Godot installation: `godot --version` (must be 4.4+)
2. Create minimal `project.godot`:
   ```ini
   ; Engine configuration file.
   ; It's best edited using the editor UI and not directly,
   ; since the parameters that go here are not all obvious.
   ;
   ; Format:
   ;   [section] key=value

   config_version=5

   [application]

   config/name="RootsGame"
   config/features=PackedStringArray("4.4", "GL Compatibility")
   run/main_scene="res://scenes/main/main.tscn"

   [debug]

   gdscript/warnings/untyped_declaration=2
   gdscript/warnings/unsafe_property_access=2
   gdscript/warnings/unsafe_method_access=2
   gdscript/warnings/unsafe_call_argument=2
   gdscript/warnings/unsafe_cast=1
   ```
   Note: `=2` means Error, `=1` means Warn. `unsafe_cast` is Warn because casts from `Variant` returns (like `get_node()`) are unavoidable.

   > **Research insight (performance review):** Static typing enforcement is both a correctness and performance lever. Godot 4's compiler generates faster bytecode for typed operations — avoiding Variant boxing/unboxing for arithmetic, using direct dispatch for method calls, and known-offset access for properties. The 28-59% improvement applies primarily to math-heavy inner loops. For a turn-based RPG, the greater value is **correctness at parse time**. (Sources: [beep.blog benchmarks](https://www.beep.blog/2024-02-14-gdscript-typing/), [Boden McHale: ~47% improvement](https://www.bodenmchale.com/2025/02/24/improve-godot-performance-using-static-types/), [Simon Dalvai](https://simondalvai.org/blog/godot-static-typing/))

3. Run `godot --headless --path . --quit` to generate `.godot/` import cache
4. Commit `.uid` sidecar files immediately if any are generated

#### Phase 3: Folder Structure

**What:** Create only the directories that will contain files in this plan.
**Files:** Directories listed in Architecture section
**Depends on:** Phase 2
**Verification:** `find . -type d | sort` matches expected structure

Steps:
1. Create directories that contain files:
   ```bash
   mkdir -p addons scripts/autoloads scenes/main \
     shared/state_machine tests/unit .vscode
   ```
2. **Do not create empty directories** like `entities/player/`, `data/monsters/`, `ui/`, `battle/`, `world/`, etc. Create them when the first file is written there.

> **Research insight (simplicity review):** The original plan created 20+ directories, most empty, requiring `.gitkeep` maintenance. `mkdir -p` takes 0.1 seconds — create directories on first use, not speculatively.

#### Phase 4: VS Code Configuration

**What:** Configure VS Code for Godot development.
**Files:** `.vscode/settings.json`, `.vscode/launch.json`, `.vscode/extensions.json`
**Depends on:** Phase 2 (project.godot must exist for LSP)
**Verification:** VS Code opens with GDScript syntax highlighting; LSP connects when Godot is running

`.vscode/settings.json`:
```json
{
  "godotTools.lsp.serverPort": 6005,
  "godotTools.lsp.headless": true,
  "godotTools.debugger.port": 6007,
  "[gdscript]": {
    "editor.defaultFormatter": "geequlim.godot-tools",
    "editor.formatOnSave": false,
    "editor.tabSize": 4,
    "editor.insertSpaces": true
  },
  "files.associations": {
    "*.gd": "gdscript",
    "*.tscn": "gdscene",
    "*.tres": "gdresource",
    "*.gdshader": "gdshader"
  },
  "search.exclude": {
    ".godot/": true,
    "**/.godot": true
  }
}
```

Note: `formatOnSave: false` — formatting is handled by `gdformat` via the lint agent to avoid two-formatter conflicts.

`.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Main Scene",
      "type": "godot",
      "request": "launch",
      "scene": "main"
    },
    {
      "name": "Launch Current Scene",
      "type": "godot",
      "request": "launch",
      "scene": "current"
    },
    {
      "name": "Attach to Running Instance",
      "type": "godot",
      "request": "launch",
      "address": "127.0.0.1",
      "port": 6007
    }
  ]
}
```

`.vscode/extensions.json`:
```json
{
  "recommendations": [
    "geequlim.godot-tools",
    "alfish.godot-files"
  ]
}
```

#### Phase 5: Architectural Scaffolding

**What:** Create autoloads, base classes, and register them in `project.godot`.
**Files:** 4 `.gd` files + update `project.godot`
**Depends on:** Phase 3
**Verification:** Each script parses without errors (`gdlint` passes); autoloads registered

**5a. State Machine Base Classes**

`shared/state_machine/state.gd`:
```gdscript
class_name State
extends Node
## Base class for state machine states. Override virtual methods in subclasses.


signal state_finished(next_state_path: String, data: Dictionary)


func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
```

> **Research insight (pattern review):** Signal renamed from bare `finished` to `state_finished` for consistency with the `noun_past_verb` naming pattern used by all other signals in the codebase (`battle_started`, `save_completed`, `game_state_changed`).

`shared/state_machine/state_machine.gd`:
```gdscript
class_name StateMachine
extends Node
## Generic state machine. Add State nodes as children. Set initial_state in inspector.


@export var initial_state: State

var current_state: State


func _ready() -> void:
	for child: Node in get_children():
		if child is State:
			child.state_finished.connect(_on_state_finished)
	if initial_state:
		current_state = initial_state
		current_state.enter("")


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_state_finished(next_state_path: String, data: Dictionary) -> void:
	transition_to(next_state_path, data)


func transition_to(target_state_path: String, data: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		push_warning("State not found: %s" % target_state_path)
		return
	var previous_state_path: String = ""
	if current_state:
		previous_state_path = current_state.name
		current_state.exit()
	current_state = get_node(target_state_path) as State
	current_state.enter(previous_state_path, data)


func set_active(active: bool) -> void:
	set_process(active)
	set_physics_process(active)
	set_process_unhandled_input(active)
```

> **Research insights:**
> - **Member ordering fix (pattern review):** `_on_state_finished` (signal callback) now appears before `transition_to` (public method), matching the canonical ordering: virtual methods → signal callbacks → public methods.
> - **New: `set_active()` method (performance review):** Enables parent entities to deactivate their state machine when off-screen, disabling all three frame callbacks. Use with `VisibleOnScreenEnabler2D` or manual distance checks.
> - **Performance (performance review):** Delegation overhead is negligible (~microseconds per frame). With static typing, GDScript uses faster typed dispatch. At most 10-15 active state machines expected simultaneously for a Cassette Beasts-style RPG.

**5b. Autoload Scripts**

`scripts/autoloads/event_bus.gd`:
```gdscript
extends Node
## Global signal bus for cross-system events. Use sparingly.
## Only for signals with no natural owner in the scene hierarchy.
##
## Add signals here as systems are built. Do not pre-define signals
## that have no producers or consumers yet.
##
## Architectural rule: If a signal can be connected by a shared parent
## in the scene tree, it should NOT be on the EventBus. Only genuinely
## "homeless" signals belong here (e.g., player_died, quest_completed).
```

> **Research insight (simplicity review + architecture review):** The original plan pre-defined 4 signals (`battle_started`, `battle_ended`, `scene_transition_requested`, `notification_requested`) with zero producers or consumers. These are removed — add signals when the system that emits them is built. Pre-defining API for nonexistent systems is speculative design.
>
> **Architecture review note:** If `scene_transition_requested` is added later, document whether scene changes go through EventBus signal OR direct SceneManager call — do not leave both paths available without a documented rule.

`scripts/autoloads/game_state.gd`:
```gdscript
extends Node
## Tracks global game mode. Used for input handling and system coordination.


signal game_state_changed(new_state: GameMode)


enum GameMode {
	OVERWORLD,
	BATTLE,
	MENU,
	DIALOGUE,
	CUTSCENE,
}


var current_mode: GameMode = GameMode.OVERWORLD


func set_mode(new_mode: GameMode) -> void:
	if current_mode != new_mode:
		current_mode = new_mode
		game_state_changed.emit(current_mode)
```

> **Research insights:**
> - **Setter safety (pattern review):** The original used a property setter (`set(value)`) which fires during variable initialization. If the default were changed to a non-first enum value, the signal would fire before any listeners connect. Using an explicit `set_mode()` method avoids this timing issue and makes the mutation point grep-findable.
> - **YAGNI (simplicity review):** Removed `flags: Dictionary` and its accessors (`set_flag`, `get_flag`, `has_flag`). Progression flags are deferred until save system design. When added, use `Dictionary[StringName, bool]` (Godot 4.4 typed dictionaries) instead of untyped `Variant` values.
> - **Type safety (pattern review + architecture review):** When flags are added, restrict value types to prevent injection of `Object`, `Callable`, `RID`, or `Signal` types from tampered save data.

**5c. Register Autoloads in `project.godot`**

Append to `project.godot`:
```ini
[autoload]

EventBus="*res://scripts/autoloads/event_bus.gd"
GameState="*res://scripts/autoloads/game_state.gd"
```

> **Autoload rule (documented for CLAUDE.md):** No cross-autoload dependencies in `_ready()`. All autoloads must be independent at initialization time.

**5d. Minimal Main Scene**

Create `scenes/main/main.tscn` — a Node2D root with a Label displaying "RootsGame". This is the simplest valid scene so F5 works immediately.

#### Phase 6: GUT Testing Framework

**What:** Install GUT and create a smoke test.
**Files:** `addons/gut/` (submodule), `.gutconfig.json`, `tests/unit/test_example.gd`
**Depends on:** Phase 2
**Verification:** GUT tests pass via headless CLI

Steps:
1. Add GUT as git submodule (pin to a specific tagged release):
   ```bash
   git submodule add https://github.com/bitwes/Gut.git addons/gut
   cd addons/gut && git checkout v9.5.0 && cd ../..  # pin to known-good release
   ```

   > **Research insight (security review):** Pin the submodule to a specific tagged release commit and verify with `git submodule status`. Consider vendoring GUT directly if supply-chain risk is a concern. Ensure GUT addon is excluded from production exports via export filter.

2. Create `.gutconfig.json`:
   ```json
   {
     "dirs": ["res://tests/unit/", "res://tests/integration/"],
     "prefix": "test_",
     "suffix": ".gd",
     "should_exit": true,
     "should_exit_on_success": true,
     "log_level": 1,
     "include_subdirs": true,
     "ignore_pause": true
   }
   ```

   > **Research insight (GUT 9.x docs via Context7):** Added `ignore_pause` for headless reliability. Full `.gutconfig.json` options include `double_strategy`, `opacity`, `should_maximize`, and `unit_test_name` for granular control. Default config location is `res://.gutconfig.json`.

3. Create smoke test `tests/unit/test_example.gd`:
   ```gdscript
   extends GutTest


   func test_gut_framework_works() -> void:
   	assert_true(true, "GUT framework is operational")
   ```

   > **Research insight (simplicity review):** Reduced from 2 tests to 1. The original `test_static_typing_enforced` tested GDScript's assignment operator, not typing enforcement (which is enforced by project settings, not tests).

4. Run tests using two-step headless pattern:
   ```bash
   # Step 1: Clean headless import (registers all resources/classes)
   godot --headless --import --quit

   # Step 2: Run GUT
   godot --headless -d -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit
   ```

   > **Research insight (GUT CI best practices):** The two-step pattern prevents test failures caused by unregistered resources. For CI, add `--display-driver headless --audio-driver Dummy --disable-render-loop` flags and set `GODOT_DISABLE_LEAK_CHECKS=1` to avoid false negatives from leak logs. (Source: [GUT CLI docs](https://gut.readthedocs.io/en/latest/Command-Line.html), [CI-tested GUT for Godot 4](https://medium.com/@kpicaza/ci-tested-gut-for-godot-4-fast-green-and-reliable-c56f16cde73d))

   > **Headless test skipping:** Override `should_skip_script()` in tests that require a display server:
   > ```gdscript
   > func should_skip_script():
   >     if DisplayServer.get_name() == "headless":
   >         return "Skip input tests when running headless"
   > ```

#### Phase 7: Godot Editor One-Time Settings (Manual)

**What:** Configure Godot editor for VS Code integration. These CANNOT be automated.
**Depends on:** Phase 2 + Phase 4
**Verification:** Double-clicking a script in Godot opens it in VS Code

Checklist (manual steps in Godot editor GUI):
- [ ] Editor > Editor Settings > Text Editor > External: "Use External Editor" = ON
- [ ] Exec Path: `/Applications/Visual Studio Code.app/Contents/MacOS/Electron`
- [ ] Exec Flags: `{project} --goto {file}:{line}:{col}`
- [ ] Network > Language Server > Remote Port: `6005`
- [ ] Text Editor > Script: "Auto Reload Scripts on External Change" = ON
- [ ] Enable "Save on Focus Loss"
- [ ] Enable "Import Resources When Unfocused"
- [ ] Code Completion Delay: `0.01`, Idle Parse Delay: `0.1`
- [ ] Debug > Script Editor: "Debug With External Editor" = ON
- [ ] **NEW:** Text Editor > Completion > "Add Type Hints" = ON (auto-generates type hints)

Note: Static typing enforcement is already in `project.godot` (Phase 2) and does NOT need to be set here.

## Deferred Components (Build When Needed)

### SceneManager (Deferred until 2+ scenes exist)

When the first scene transition is needed, create `scripts/autoloads/scene_manager.gd`:

```gdscript
extends Node
## Handles scene transitions. Call change_scene() instead of using
## get_tree().change_scene_to_file() directly.


signal scene_change_started
signal scene_change_finished

var _is_transitioning: bool = false


func change_scene(path: String) -> void:
	if _is_transitioning:
		push_warning("Scene transition already in progress, ignoring: %s" % path)
		return
	_is_transitioning = true
	scene_change_started.emit()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame  # wait for deferred scene swap to complete
	_is_transitioning = false
	scene_change_finished.emit()


func change_scene_async(path: String) -> void:
	if _is_transitioning:
		push_warning("Scene transition already in progress, ignoring: %s" % path)
		return
	_is_transitioning = true
	scene_change_started.emit()
	ResourceLoader.load_threaded_request(path)

	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path)

	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("Failed to load scene: %s (status: %d)" % [path, status])
		_is_transitioning = false
		return

	var scene: PackedScene = ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame  # wait for new scene to enter tree
	_is_transitioning = false
	scene_change_finished.emit()
```

> **Research insights (architecture + performance + pattern reviews):**
> - **Signal timing fix:** `scene_change_finished` now emits after `await get_tree().process_frame`, ensuring the new scene is actually loaded and its `_ready()` methods have run.
> - **Error handling:** Async loading now checks for `THREAD_LOAD_FAILED` and `THREAD_LOAD_INVALID_RESOURCE` instead of spinning forever on failure.
> - **Transition guard:** `_is_transitioning` flag prevents double-transition bugs from rapid input (e.g., double-tapping a door trigger).
> - **Fade transitions:** When visual transitions are needed, use a CanvasLayer with ColorRect and AnimationPlayer. The CanvasLayer renders on top of everything; ColorRect should ignore mouse events (`mouse_filter = IGNORE`). (Source: [GDQuest Scene Transitions](https://www.gdquest.com/tutorial/godot/2d/scene-transition-rect/))

### SaveManager (Deferred until saveable data exists)

When save/load is needed, **use JSON-based serialization, not `ResourceLoader.load()`**:

```gdscript
extends Node
## JSON-based save/load system. Uses FileAccess for security.
## SECURITY: Never use ResourceLoader.load() on user-writable save files.
## .tres files can embed and execute arbitrary GDScript.


signal save_completed(slot: int)
signal load_completed(slot: int)

const SAVE_DIR: String = "user://saves/"
const MAX_SLOTS: int = 10


func save_game(slot: int, data: Dictionary) -> Error:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("Invalid save slot: %d" % slot)
		return ERR_PARAMETER_RANGE_ERROR
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path: String = SAVE_DIR + "slot_%d.json" % slot
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit(slot)
	return OK


func load_game(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("Invalid save slot: %d" % slot)
		return {}
	var path: String = SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json_string: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_string)
	if parsed is Dictionary:
		load_completed.emit(slot)
		return parsed as Dictionary
	push_error("Save file corrupted: %s" % path)
	return {}


func has_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	var path: String = SAVE_DIR + "slot_%d.json" % slot
	return FileAccess.file_exists(path)
```

> **Research insights (security review — CRITICAL):**
> - **Arbitrary code execution risk:** `ResourceLoader.load()` on `.tres` files can execute arbitrary GDScript embedded in `script/source` properties. Save files live in `user://saves/`, a user-writable directory. A crafted `.tres` save file could access the filesystem, exfiltrate data, or corrupt game state.
> - **JSON-based saves eliminate the attack surface entirely.** `FileAccess` + `JSON.parse_string()` cannot execute code. Trade-off: you lose automatic nested Resource serialization. Build explicit `to_dict()` / `from_dict()` methods on your data classes.
> - **Slot bounds validation (security review):** Added `MAX_SLOTS` constant and bounds checking to prevent unbounded file creation.
> - **Alternative if Resources are required:** Use [Godot Safe Resource Loader](https://github.com/godot-safe-resource-loader) addon or `FileAccess.store_var()` / `get_var()` for code-execution-free binary serialization. (Source: [GDQuest Save Game](https://www.gdquest.com/library/save_game_godot4/), [GDQuest Save Formats](https://www.gdquest.com/tutorial/godot/best-practices/save-game-formats/))

## System-Wide Impact

### Interaction Graph

Project initialization creates `project.godot` → enables Godot LSP → enables VS Code IntelliSense → enables CE customization plan artifacts. Autoload registration in `project.godot` → autoloads available at runtime → game scripts can reference `EventBus`, `GameState`, etc.

### State Lifecycle Risks

- **Partial `project.godot`:** If the file is malformed (missing `config_version=5`), Godot refuses to open the project. Mitigation: validate with `godot --headless --path . --quit` after every edit.
- **Autoload ordering:** Autoloads initialize in the order listed in `[autoload]`. The current ordering is safe (EventBus and GameState are independent).
- **GUT submodule not initialized after clone:** New clones must run `git submodule update --init`. Document in CLAUDE.md.
- **GameState setter timing (pattern review):** Using explicit `set_mode()` method instead of property setter avoids signal emission during variable initialization.

### API Surface Parity

Not applicable — this is project bootstrapping, not feature development.

### Species Data Loading Strategy (Future)

> **Research insight (performance review):** When the `data/` directory fills with hundreds of `.tres` files:
> - `preload()` all data Resources (small, no textures) in a registry — startup cost is linear but manageable for data-only Resources
> - Have Resources reference texture paths as `String` rather than `Texture2D`, loading visuals asynchronously when needed
> - Never `preload()` large assets (sprites, audio) — use `ResourceLoader.load_threaded_request()` for those
> - Editor may slow with hundreds of `.tres` files in a single directory — use subdirectories

## Acceptance Criteria

### Functional Requirements

- [ ] `git status` shows a clean repository with all scaffolding committed
- [ ] `godot --headless --path . --quit` exits with code 0
- [ ] `godot --version` reports 4.4+
- [ ] VS Code opens the project with GDScript syntax highlighting
- [ ] LSP connects when Godot runs (completions work in `.gd` files)
- [ ] F5 in VS Code launches the main scene (a window appears with "RootsGame" label)
- [ ] Both autoloads are accessible from any script (e.g., `GameState.current_mode`)
- [ ] Static typing is enforced: an untyped `var x = 1` produces a parse error
- [ ] GUT tests pass: two-step headless pattern
- [ ] `gdformat --check .` passes on all `.gd` files
- [ ] `gdlint .` passes on all `.gd` files

### Non-Functional Requirements

- [ ] No files in `.godot/` are committed
- [ ] No `.DS_Store` files in the repository
- [ ] No export artifacts, signing keys, or `.env` files in the repository
- [ ] All `.gd` files use static typing
- [ ] No empty directories with `.gitkeep` files

### Quality Gates

- [ ] All acceptance criteria pass in a fresh clone (after `git submodule update --init`)
- [ ] Phase 7 manual checklist completed (developer self-attestation)

## Success Metrics

- A fresh `git clone` + `git submodule update --init` + `godot --headless --path . --quit` produces a working project
- The CE customization plan can be executed immediately after this plan completes
- First game script (player controller, monster resource, etc.) can be written with full LSP support and type checking

## Dependencies & Prerequisites

| Dependency | Required Version | Check Command | Install |
|---|---|---|---|
| Godot | 4.4+ | `godot --version` | Download from godotengine.org |
| Git | Any | `git --version` | `brew install git` |
| pipx | Any | `pipx --version` | `brew install pipx` |
| gdtoolkit | 4.x | `gdformat --version` | `pipx install "gdtoolkit==4.*"` |
| Node.js | 18+ | `node --version` | `brew install node` (for CE MCP) |
| VS Code | Any | `code --version` | Download from code.visualstudio.com |
| godot-tools ext | Latest | VS Code Extensions panel | Install `geequlim.godot-tools` |
| godot-files ext | Latest | VS Code Extensions panel | Install `alfish.godot-files` |

## Risk Analysis & Mitigation

| Risk | L | I | Mitigation |
|---|---|---|---|
| `project.godot` format incorrect | L | H | Validate with `godot --headless --path . --quit` after creation |
| Godot not installed or wrong version | M | H | Phase 2 Step 1 verifies before proceeding |
| LSP port mismatch (6005 vs other) | H | H | Hardcoded in both `.vscode/settings.json` and Phase 7 checklist |
| GUT submodule fails (network, permissions) | L | M | Fallback: manual download to `addons/gut/` |
| Autoload ordering causes null refs | L | M | All autoloads are independent; no cross-autoload deps in `_ready()` |
| `gdformat`/`gdlint` not installed | M | L | Prerequisite check in Phase 0; install instructions in CLAUDE.md |
| Static typing settings not honored | L | H | Written directly in `project.godot`; verified in acceptance criteria |
| `.obsidian/` committed accidentally | M | L | In `.gitignore` from Phase 1 |
| Godot 4.4 `.uid` bug (#104188) | L | M | Commit `.uid` files early; aware of rename risk |
| **NEW:** Save file code execution | L | H | JSON-based saves instead of ResourceLoader.load() |
| **NEW:** `.tscn` merge corruption | L | H | Removed `merge=union` from `.gitattributes` |
| **NEW:** GUT supply-chain compromise | L | M | Pin submodule to tagged release; verify commit hash |

## Future Considerations

- **SceneManager:** Created when the second scene exists. Use the corrected implementation in Deferred Components section above.
- **SaveManager:** Created when saveable data exists. Use JSON-based implementation for security. See Deferred Components section above.
- **Base Resource classes** (MonsterSpecies, MoveData, ItemData): Deferred until game design is further along. Follow the Species template + Instance two-tier pattern.
- **Battle system scaffolding:** Deferred. The `battle/` directory and state machine base classes are ready.
- **Player controller:** First real game code — will use the StateMachine and State base classes. Co-locate states with the entity (`entities/player/states/`).
- **Dialog system:** Decision deferred (Dialogic 2 vs custom). Both integrate cleanly with this architecture.
- **Audio management:** Add an `AudioManager` autoload when audio assets exist. Defer audio bank preloading to after the first frame renders to avoid blocking startup.
- **Git LFS:** Add when binary assets (sprites, audio) become substantial. Currently unnecessary for an empty project.
- **CI/CD:** Add `gdformat --check` and `gdlint` to CI when a pipeline is set up. Use the two-step GUT headless pattern.
- **Autoload consolidation:** If autoload count exceeds 5-6, consolidate into a Services facade autoload.
- **GameState flags:** When progression tracking is needed, add `flags: Dictionary[StringName, bool]` (typed dictionary). Validate flag types if populated from save data.

## End-to-End Smoke Test

After all phases complete, run this verification sequence:

```bash
# 1. Prerequisites
godot --version          # Must show 4.4+
gdformat --version       # Must exist
gdlint --version         # Must exist

# 2. Project validity
godot --headless --path . --quit    # Must exit 0

# 3. Linting
gdformat --check .       # Must pass
gdlint .                 # Must pass

# 4. Tests (two-step headless pattern)
godot --headless --import --quit
godot --headless -d -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit

# 5. Launch (manual)
# Open in VS Code, press F5 — window should appear with "RootsGame" label

# 6. LSP (manual)
# Open any .gd file in VS Code — completions should work
# Type `var x = 1` — should show a type error
```

## Sources & References

### Internal References

- [docs/reference/godot-best-practices.md](docs/reference/godot-best-practices.md) — Architectural patterns (43 sources)
- [docs/reference/godot-vscode-claude-setup.md](docs/reference/godot-vscode-claude-setup.md) — VS Code + Godot integration reference
- [docs/plans/2026-03-19-feat-godot-ce-customization-plan.md](docs/plans/2026-03-19-feat-godot-ce-customization-plan.md) — Companion plan for CE tooling layer
- [.claude/skills/godot-patterns/](../../.claude/skills/godot-patterns/) — Scene architecture, GDScript quality, Resource system reference files

### External References

- [Godot Official: Project Organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [Godot Official: Autoloads](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Godot Official: Static Typing](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/static_typing.html)
- [Godot Official: Version Control Systems](https://docs.godotengine.org/en/4.4/tutorials/best_practices/version_control_systems.html)
- [GDQuest: Finite State Machine](https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/)
- [GDQuest: Event Bus Pattern](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)
- [GDQuest: Save/Load with Resources](https://www.gdquest.com/library/save_game_godot4/)
- [GDQuest: Save Game Formats](https://www.gdquest.com/tutorial/godot/best-practices/save-game-formats/)
- [GDQuest: Scene Transitions](https://www.gdquest.com/tutorial/godot/2d/scene-transition-rect/)
- [abmarnie: Godot Architecture Guide](https://github.com/abmarnie/godot-architecture-organization-advice)
- [GitHub: Godot .gitignore](https://github.com/github/gitignore/blob/main/Godot.gitignore)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [GUT CLI Documentation](https://gut.readthedocs.io/en/latest/Command-Line.html)
- [GUT 9.6.0 Documentation](https://gut.readthedocs.io/)
- [CI-tested GUT for Godot 4](https://medium.com/@kpicaza/ci-tested-gut-for-godot-4-fast-green-and-reliable-c56f16cde73d)
- [beep.blog: GDScript Static Typing Benchmarks](https://www.beep.blog/2024-02-14-gdscript-typing/)
- [Boden McHale: Static Typing Performance](https://www.bodenmchale.com/2025/02/24/improve-godot-performance-using-static-types/)
- [Simon Dalvai: Godot Static Types](https://simondalvai.org/blog/godot-static-typing/)
- [Shaggy Dev: State Machines](https://shaggydev.com/2023/10/08/godot-4-state-machines/)
- [Shaggy Dev: Advanced State Machines](https://shaggydev.com/2023/11/28/godot-4-advanced-state-machines/)
- [Godot Showcase: Cassette Beasts](https://godotengine.org/article/godot-showcase-cassette-beasts/)
- [Godot Proposals #1281: .tscn merging](https://github.com/godotengine/godot-proposals/issues/1281)

### Review Agent Findings

- **Architecture Strategist:** SceneManager signal timing bug, EventBus/SceneManager signal overlap, `.gitattributes` merge=union risk, autoload consolidation trigger
- **Security Sentinel:** CRITICAL: ResourceLoader.load() code execution on save files, incomplete .gitignore, untyped GameState flags, GUT supply-chain risk
- **Performance Oracle:** SceneManager async error handling (infinite loop), StateMachine set_active() for off-screen optimization, Species data loading strategy
- **Code Simplicity Reviewer:** 70% of planned scaffolding is YAGNI, minimum viable foundation identified, defer SaveManager/SceneManager/pre-defined signals
- **Pattern Recognition Specialist:** StateMachine member ordering violation, State.finished lacks subject noun, GameState setter type annotation missing, SceneManager timing confirmed
