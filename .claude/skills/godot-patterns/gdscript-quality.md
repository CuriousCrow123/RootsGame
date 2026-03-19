# GDScript Code Quality & Patterns

## Member Ordering

Canonical sequence within every script:

```
class_name / extends / docstring
signals
enums
constants
@export variables
public variables
pseudo-private variables (_ prefix)
@onready variables
virtual methods (_init, _ready, _process, etc.)
signal callbacks (_on_*)
public methods
private methods (_prefixed)
inner classes
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files, variables, functions | snake_case | `player_health`, `take_damage()` |
| Class names, nodes | PascalCase | `BattleManager`, `PlayerSprite` |
| Constants, enum members | UPPER_SNAKE_CASE | `MAX_HEALTH`, `State.IDLE` |
| Pseudo-private | _underscore prefix | `_internal_counter` |
| Booleans | is_, can_, has_ | `is_alive`, `can_attack` |
| Signals | past tense | `damage_taken`, `turn_ended` |
| Files | snake_case.gd | `player_controller.gd` |

## Static Typing

- Every variable, parameter, and return type must be typed
- Use `:=` (inferred) when type is obvious from RHS: `var speed := 5.0`
- Use explicit annotation when ambiguous: `var text: String = array.pop_back()`
- Use typed arrays: `var items: Array[ItemResource] = []`
- Register scripts with `class_name` for type-checked cross-script references

### Project Settings Enforcement

```
Debug > GDScript:
  UNTYPED_DECLARATION → Error
  UNSAFE_PROPERTY_ACCESS → Error
  UNSAFE_METHOD_ACCESS → Error
  UNSAFE_CALL_ARGUMENT → Error
  UNSAFE_CAST → Warn
```

## State Machines

### Enum-Based (2-4 states)

For simple objects: chests, turrets, items.

```gdscript
enum State { IDLE, OPEN, LOCKED }
var _current_state: State = State.IDLE

func _process(delta: float) -> void:
    match _current_state:
        State.IDLE:
            _process_idle(delta)
        State.OPEN:
            _process_open(delta)
```

### Node-Based (5+ states)

For complex characters: player, NPCs.

Parent `StateMachine` node with child `State` nodes implementing:
- `enter()`, `exit()`
- `process_input(event)`, `process_frame(delta)`, `process_physics(delta)`

## Null Avoidance

- Prefer initialized sentinel values: `Vector2.ZERO`, empty arrays, `-1`
- Use guard clauses (early `return`) over deeply nested conditionals

## Built-in Patterns

| Pattern | Godot Implementation |
|---------|---------------------|
| Observer | Signals |
| Singleton | Autoloads |
| Prototype | Scenes (instancing) |
| Flyweight | Resources (cached by path) |

Object pooling is generally unnecessary in GDScript (reference counting, not GC). Full ECS is counterproductive.

## Performance Tips

- `@onready` to cache node references (evaluated once before `_ready`)
- Set properties before `add_child()` (setters can trigger slow updates)
- `preload()` over `load()` for known resources
- `distance_squared_to()` over `distance_to()` for comparisons (avoids sqrt)
- `set_process(false)` on off-screen objects
- Typed GDScript runs 28-59% faster than untyped
