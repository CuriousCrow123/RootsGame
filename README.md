# RootsGame

A Cassette Beasts-style monster-collection RPG built with Godot 4.6 and GDScript.

## Requirements

| Tool | Version | Install |
|------|---------|---------|
| Godot | 4.6+ | [godotengine.org](https://godotengine.org/download/) |
| gdtoolkit | 4.x | `pipx install "gdtoolkit==4.*"` |
| VS Code | Any | [code.visualstudio.com](https://code.visualstudio.com/) |

VS Code extensions (auto-suggested on open):
- [godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) — GDScript language support + LSP
- [godot-files](https://marketplace.visualstudio.com/items?itemName=alfish.godot-files) — `.tscn`/`.tres` syntax highlighting

## Getting Started

```bash
git clone <repo-url>
cd RootsGame

# Validate project
godot --headless --path . --quit

# Run tests
godot --headless --import --quit
godot --headless -d -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit

# Check formatting and lint
gdformat --check scripts/ shared/ tests/
gdlint scripts/ shared/ tests/

# Launch (or press F5 in VS Code)
godot --path .
```

### First-Time Godot Editor Setup

These settings live in Godot's editor preferences, not in the project. Apply once per machine:

1. **Editor > Editor Settings > Text Editor > External**
   - Use External Editor: ON
   - Exec Path: `/Applications/Visual Studio Code.app/Contents/MacOS/Electron`
   - Exec Flags: `{project} --goto {file}:{line}:{col}`
2. **Network > Language Server** — Remote Port: `6005`
3. **Text Editor > Script** — Auto Reload Scripts on External Change: ON
4. **Text Editor > Completion** — Add Type Hints: ON
5. **Interface > Editor** — Save on Focus Loss: ON, Import Resources When Unfocused: ON
6. **Text Editor > Completion** — Code Completion Delay: `0.01`
7. **Text Editor > Script** — Idle Parse Delay: `0.1`, Idle Parse Delay With Errors Found: `0.1`

## Project Structure

```
res://
├── project.godot          # Static typing enforced, autoloads registered
├── scenes/main/           # Entry point scene (F5 launches this)
├── scripts/autoloads/     # Global singletons
│   ├── event_bus.gd       #   Cross-system signal relay (add signals as needed)
│   └── game_state.gd      #   Game mode enum (OVERWORLD, BATTLE, MENU, etc.)
├── shared/state_machine/  # Reusable base classes
│   ├── state.gd           #   Abstract state with enter/exit/update/physics
│   └── state_machine.gd   #   Manages child State nodes, delegates frame callbacks
├── addons/gut/            # GUT 9.6.0 testing framework (vendored)
├── tests/unit/            # Unit tests (prefix: test_)
├── tests/integration/     # Integration tests
└── .vscode/               # VS Code config (LSP port 6005, godot-tools)
```

Directories like `entities/`, `data/`, `ui/`, `battle/`, `world/` are created when the first file that belongs there is written.

## Architecture

### Core Principles

1. **Composition over inheritance.** Entities are assembled from single-purpose child nodes. Limit scene inheritance to one layer.
2. **"Call down, signal up."** Parents call methods on children. Children emit signals. Siblings communicate through a shared parent.
3. **Resources hold data; Nodes hold behavior.** Custom Resource classes for item definitions, stat blocks, configs. Nodes only where scene-tree integration is needed.
4. **Static typing is mandatory.** Every variable, parameter, and return type must be typed. Enforced via project settings (untyped declaration = Error).

### Autoloads

| Name | Purpose |
|------|---------|
| `EventBus` | Signal relay for genuinely cross-system events. Signals added as systems are built — not pre-defined speculatively. |
| `GameState` | Tracks current game mode (`OVERWORLD`, `BATTLE`, `MENU`, `DIALOGUE`, `CUTSCENE`). Call `GameState.set_mode()` to change. |

Rule: if autoload count exceeds 5-6, consolidate into a Services facade. No cross-autoload dependencies in `_ready()`.

### State Machine

For entities with 5+ states (player, NPCs). Simpler objects use enum-based state machines.

```gdscript
# Add as child nodes of a StateMachine node:
class_name IdleState
extends State

func enter(_prev: String, _data: Dictionary = {}) -> void:
    # Setup idle animation

func update(delta: float) -> void:
    if Input.is_action_pressed("move_right"):
        state_finished.emit("MoveState", {})

func physics_update(delta: float) -> void:
    # Physics logic
```

The `StateMachine` node delegates `_process`, `_physics_process`, and `_unhandled_input` to the current state. Call `set_active(false)` to disable all callbacks for off-screen entities.

### Communication Pattern

```
Parent ──calls──> Child method      (direct, typed)
Child  ──emits──> Signal            (decoupled, upward)
Sibling <──wired by──> Parent       (parent connects signals)
Cross-system ──> EventBus           (only when no natural parent exists)
```

### Data Modeling (Planned)

Two-tier Resource pattern for monster-collection data:
- **Species template** (static `.tres`) — base stats, moves, sprite paths
- **Monster instance** (runtime) — level, XP, nickname, current HP

Always `.duplicate()` a Resource before mutating it at runtime.

## Static Typing

Enforced at the project level — untyped code produces parse errors:

```ini
# project.godot [debug] section
gdscript/warnings/untyped_declaration=2      # Error
gdscript/warnings/unsafe_property_access=2   # Error
gdscript/warnings/unsafe_method_access=2     # Error
gdscript/warnings/unsafe_call_argument=2     # Error
gdscript/warnings/unsafe_cast=1              # Warn (casts from Variant are unavoidable)
```

## GDScript Style

- **Files/vars/functions:** `snake_case`
- **Classes/nodes:** `PascalCase`
- **Constants/enum values:** `UPPER_SNAKE_CASE`
- **Pseudo-private:** `_underscore_prefix`
- **Booleans:** `is_`, `can_`, `has_` prefix
- **Signals:** past tense (`damage_taken`, `state_finished`)

Member ordering in every script:
```
class_name / extends / docstring
signals
enums
constants
@export variables
public variables
_private variables
@onready variables
virtual methods (_ready, _process, etc.)
signal callbacks (_on_*)
public methods
_private methods
inner classes
```

## Linting

```bash
gdformat --check .   # Check formatting (tabs, spacing)
gdformat .           # Auto-fix formatting
gdlint .             # Check style rules (member ordering, naming)
```

`gdlint` has no auto-fix — violations must be corrected manually.

## Testing

Uses [GUT](https://github.com/bitwes/Gut) 9.6.0 (vendored in `addons/gut/`).

```bash
# Two-step headless pattern (required for reliable results):
godot --headless --import --quit                    # Step 1: register resources
godot --headless -d -s addons/gut/gut_cmdln.gd \    # Step 2: run tests
  -gconfig=.gutconfig.json -gexit
```

Test files go in `tests/unit/` or `tests/integration/`, prefixed with `test_`.

For tests that require a display server, skip in headless mode:
```gdscript
func should_skip_script():
    if DisplayServer.get_name() == "headless":
        return "Skip input tests when running headless"
```

## Scene Files

**`.tscn` files must not be edited by hand or by agents.** They have strict structure (ordered sections, unique ext_resource IDs). Always use the Godot editor to modify scenes.

## Security Notes

- **Never use `ResourceLoader.load()` on user-writable files.** `.tres` files can embed and execute arbitrary GDScript. Use JSON + `FileAccess` for save data.
- **Never load untrusted `.tres` files** from mods, downloads, or shared saves without sanitization.

## License

TBD
