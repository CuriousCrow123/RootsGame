# Interaction, Menu & Camera Improvements — Brainstorm

**Date:** 2026-03-21
**Status:** Brainstorm complete

## What We're Building

Four related improvements to player interaction, UI, and movement:

1. **Specific interaction prompts** — Context-rich world-space prompts (`[E] Talk to Elena`) instead of generic "Press E"
2. **Direction-based interaction priority** — When multiple interactables are nearby, player facing/movement biases selection
3. **Tabbed in-game menu** — Unified menu with Quest, Inventory, Character Stats, and Pause tabs
4. **Camera-relative movement** — Decouple movement from hardcoded `ISO_ANGLE` so it reads from the camera

## Why These Approaches

### 1. Specific Interaction Prompts — Interactable-Owned Label3D Billboard

**What:** Each interactable owns a Label3D child (billboard mode) that displays `[E] <verb> <name>`. Hidden by default. When the nearest interactable changes, the player calls `show_prompt()` on the new nearest and `hide_prompt()` on the previous one ("call down" pattern).

**Prompt text source:** Type-based defaults with optional export overrides:
- NPC → "Talk to" + `npc_name`
- Chest → "Open" + "Chest" (or custom name)
- Door → "Enter" + target area name
- Interactables can override via `@export var display_name` and `@export var action_verb`

**Why this approach:**
- Composition-over-inheritance — each interactable manages its own prompt
- No projection math or per-frame repositioning needed
- Label3D billboards naturally face the camera and scale with distance
- Replaces the current screen-space `interaction_prompt.gd` CanvasLayer

**Alternatives considered:**
- Single shared Label3D on the player (requires per-frame repositioning, harder to customize)
- 2D overlay projected to screen position (consistent size but disconnected from world)
- SubViewport on Sprite3D (overkill for text prompts)

### 2. Direction-Based Interaction Priority — Pluggable Scoring Strategy

**What:** An `@export` enum on the player's interaction system selects one of three scoring strategies when multiple interactables overlap:

| Strategy | Behavior |
|---|---|
| `FACING_BIAS` | Interactables in front get a dot-product bonus, but very close ones behind can still win |
| `FACING_REQUIRED` | Only interactables within a ~90° cone in front are eligible |
| `LAST_MOVEMENT` | Uses the direction of last movement input as the bias vector |

All strategies use dot-product between a direction vector and the vector-to-interactable, combined with distance scoring. The current string-based `_facing_direction` ("up"/"down"/"left"/"right") must be converted to a world-space `Vector3` for dot-product math. With the camera decoupling (Feature 4), facing direction tracking should also shift from cardinal strings to a `Vector3` derived from the last input rotated by camera basis — this keeps Features 2 and 4 consistent.

**Why this approach:**
- All three share the same scoring infrastructure (dot product + distance)
- Single enum + match statement — no need for Strategy pattern objects
- Easy to tune weights via constants
- `@export` makes it testable in-editor

**Alternatives considered:**
- Separate Resource scripts per strategy (over-engineered for three simple variants)
- Single fixed strategy (limits tuning — the "right" feel needs playtesting)

### 3. Tabbed In-Game Menu — TabContainer

**What:** A single `CanvasLayer` scene with Godot's built-in `TabContainer` holding four tab panels:

| Tab | Content |
|---|---|
| Quest | Active/completed quests from QuestTracker |
| Inventory | Items from Inventory system |
| Stats | Character stats (placeholder content initially) |
| Pause | Resume, Save, Load, Quit (migrated from current pause_menu.gd) |

**Navigation:** Top tab bar, clickable or switchable with left/right arrow keys (or Q/E). Within-tab navigation uses up/down arrows for scrolling lists. Tab key opens/closes the menu (same as current pause). Content for Quest and Inventory pulls from existing autoload systems.

**Why this approach:**
- TabContainer provides tab switching, keyboard navigation, and theming out of the box
- Each tab is its own scene — adding new tabs later is just adding a child scene
- Replaces the standalone pause menu, consolidating all menu UI into one system
- `process_mode = PROCESS_MODE_ALWAYS` on the CanvasLayer (same pattern as current pause menu)

**Alternatives considered:**
- Custom tab bar with HBoxContainer + buttons (reinventing built-in functionality)
- Side panel list layout (less natural for JRPG-style menus)
- Starting with fewer tabs (user explicitly wants all four from the start)

### 4. Camera-Relative Movement — Read Camera Basis

**What:** Replace the hardcoded `ISO_ANGLE = -0.7854` constant in `player_controller.gd` with a function that reads the current camera's Y-rotation from its transform basis. Player movement input is rotated by the camera's actual forward direction.

**Why this approach:**
- Minimal change — one function replaces one constant
- Automatically works with any camera angle if rooms use different angles later
- Per-frame camera basis read is negligible cost
- No signal infrastructure needed for a value that rarely (currently never) changes

**Alternatives considered:**
- Camera publishes angle via signal (over-engineered when camera doesn't rotate)
- Keep hardcoded angle (works but couples player to specific camera setup)

## Key Decisions

1. **Prompt format:** `[E] <verb> <name>` with type-based defaults and `@export` overrides
2. **Prompt rendering:** Label3D billboard on each interactable (world-space, not screen-space)
3. **Interaction scoring:** Three selectable strategies via `@export` enum — facing bias, facing required, last movement
4. **Menu structure:** Godot TabContainer with four tabs (Quest, Inventory, Stats, Pause)
5. **Menu navigation:** Top tab bar with arrow key + click navigation
6. **Camera-movement coupling:** Read camera basis at runtime instead of hardcoded angle
7. **Current interaction_prompt.gd:** Will be replaced by the Label3D system (remove CanvasLayer prompt)
8. **Facing direction representation:** Must evolve from cardinal strings to a `Vector3` to support dot-product scoring (Feature 2) and camera-relative orientation (Feature 4). Cardinal strings can still be derived from the vector for animation selection.

## Open Questions

None — all questions resolved during brainstorming.

## Scope Notes

- Character Stats tab will have placeholder content since no stats system exists yet
- Quest and Inventory tabs pull from existing systems but UI layout/design is new
- The three interaction strategies share scoring code — weights can be tuned later via constants
- Camera change is purely a decoupling refactor, not adding new camera angles
