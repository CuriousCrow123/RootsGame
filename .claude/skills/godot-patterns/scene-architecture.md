# Scene Architecture & Composition

## Scene Design

- Scenes are the primary design unit. One controller script per root node, named after the scene.
- Single responsibility per node — extract functionality into child nodes, don't expand scripts.
- Limit scene inheritance to one layer. Prefer instanced subscenes for deeper reuse.
- Reparenting nodes in inherited scenes resets child instance parameters — known structural trap.

## Composition Pattern

Game entities assemble from single-purpose child nodes:

```
Player (CharacterBody2D)
├── MovementComponent (Node)
├── HealthComponent (Node)
├── AnimationComponent (Node)
├── CollisionShape2D
└── Sprite2D
```

Each component has one script, remains "blind" to its surroundings. The root node's script orchestrates.

## Dependency Injection (Three Mechanisms)

1. **Signals** — child emits, parent or sibling connects
2. **Exported properties** — `@export var target: Node` assigned in inspector
3. **Public methods** — called by parent at composition time

**Never use hardcoded node paths** like `get_node("../../OtherNode")`. They break on restructuring.

## Scene Unique Nodes

Use `%NodeName` for robust internal references:

```gdscript
@onready var health_bar: ProgressBar = %HealthBar
```

Preferred over `get_node("Path/To/HealthBar")`.

## Signal Architecture

### "Call Down, Signal Up"

- Parents call methods on children directly
- Children emit signals upward
- Siblings communicate through shared parent that wires them

### When to Use Signals vs. Direct Calls

| Signals | Direct Calls |
|---------|-------------|
| Sender doesn't know who listens | Exactly one receiver |
| Multiple systems react to one event | Return value needed |
| Connections are optional | Internal to a component |

### Event Bus

Single autoloaded script holding signal definitions. Use ONLY for genuinely cross-system events:
- Player death, quest completion, achievement unlocked
- NOT for parent-child communication (use direct wiring instead)

```gdscript
# events.gd (autoload)
signal player_died
signal quest_completed(quest_id: String)
signal item_collected(item: ItemResource)
```

### Signal Naming

- snake_case, past-tense: `health_depleted`, `item_collected`, `door_opened`
- Bookends: `_started` / `_finished`
- Callbacks: `_on_[node_name]_[signal_name]`

### Connection Best Practices

- Use typed callable syntax: `node.signal.connect(callable)`
- Connect in `_ready()`, disconnect in `_exit_tree()` if source outlives listener
- Guard duplicates: `if not signal.is_connected(callable)` before `connect()` in reopenable UI
- Signal execution order is NOT guaranteed — don't depend on subscriber order

### Anti-Patterns

- **Signal bubbling** — re-emitting child signals through parent nodes
- **Multi-step connections** — chaining signals through 3+ intermediaries

## Groups

Use for category-based operations on dynamically spawned nodes:

```gdscript
# Tag nodes
add_to_group("enemies")

# Find all
var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
```

## Container Nodes

Use plain Node2D containers named "Enemies", "Collectibles", "NPCs" for logical grouping.

## Scale to Project Size

For small projects (<10k lines, <100 scenes, solo, <6 months): apply rigor where it reduces bugs, not where it adds ceremony.
