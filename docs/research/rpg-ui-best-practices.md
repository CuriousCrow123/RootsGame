# RPG UI Best Practices for Godot 4 + GDScript

Research compiled 2026-03-22. Sources: Godot official docs, GDQuest, community forums, godot-compound skills, and existing RootsGame codebase analysis.

---

## 1. Control Node Architecture

### Container Selection Guide

| Container | Use When | RPG Example |
|-----------|----------|-------------|
| **VBoxContainer** | Vertical stacking with consistent spacing | Quest log entries, menu option lists, stat rows |
| **HBoxContainer** | Horizontal row layout | HP/MP bars side by side, button rows, icon + label pairs |
| **GridContainer** | Grid of uniform slots | Inventory grid, equipment slots, spell selection |
| **MarginContainer** | Padding around content | Wrapping any panel content with breathing room |
| **PanelContainer** | Background rectangle around a single child | Dialog boxes, menu windows, tooltip panels |
| **ScrollContainer** | Content that may overflow | Long item lists, quest logs, chat/dialogue history |
| **CenterContainer** | Centering a child element | Modal confirmation dialogs, "Game Over" text |
| **TabContainer** | Multiple pages sharing one area | Main menu tabs (Inventory, Quests, Stats, Settings) |

### Recommended Nesting Patterns

**Menu window pattern** (used in RootsGame's `game_menu.gd`):
```
CanvasLayer (layer = 110, process_mode = ALWAYS)
  PanelContainer
    TabContainer
      VBoxContainer "Quests"
        ScrollContainer
          VBoxContainer (dynamic children)
      VBoxContainer "Inventory"
        ScrollContainer
          VBoxContainer (dynamic children)
      VBoxContainer "Stats"
        ...
      VBoxContainer "Pause"
        ...
```

**Dialog/popup pattern:**
```
PanelContainer
  MarginContainer
    VBoxContainer
      Label "title"
      Label "body text"
      HBoxContainer
        Button "Confirm"
        Button "Cancel"
```

**HUD element pattern:**
```
MarginContainer (anchored to screen edge)
  HBoxContainer
    TextureRect "icon"
    ProgressBar "health"
    Label "value"
```

### Key Rules

1. **Containers for groups, anchors for isolated elements.** Use containers whenever 2+ elements need automatic arrangement. Use anchors only for single fixed-position elements (like a minimap pinned to a corner).

2. **Set minimum sizes on container children.** GridContainer, CenterContainer, and others collapse children to zero if no minimum size is set. Always configure `custom_minimum_size` on children.

3. **Use `Control` escape nodes for animation.** Containers override children's position/size. To animate a child (e.g., a button bounce), wrap it in a plain `Control` node -- the container controls the `Control` wrapper, while the child inside can be freely transformed.

4. **TabContainer creates tabs from children.** Each direct child becomes a tab using the child's `name` as the title. Override with `set_tab_title()` in code. The tab bar itself gets `focus_mode = FOCUS_NONE` to prevent it from stealing keyboard focus (as RootsGame already does in `game_menu.gd`).

5. **Custom tab switching over default.** For RPG menus with gamepad support, handle tab switching explicitly with input actions rather than relying on TabContainer's built-in keyboard shortcuts. RootsGame uses `ui_left`/`ui_right` in `_input()` with `wrapi()` -- this is the recommended pattern.

### Anti-Patterns

- **Avoid deep anchor chains.** If you find yourself setting anchors on 5+ nested nodes, refactor to containers.
- **Do not use ItemList for RPG inventory.** ItemList has limited styling and no custom child support. Use a ScrollContainer + VBoxContainer/GridContainer with instanced item scenes instead.
- **Never rebuild UI every frame.** Use signal-driven refresh (connect to `item_added`, `quest_completed`, etc.) and rebuild only on data change. RootsGame's `_on_items_changed()` pattern is correct.

---

## 2. Theme System

### Architecture

Themes cascade top-down through the scene tree, similar to CSS. Priority order (highest to lowest):

1. **Node-specific overrides** (`add_theme_*_override()` on individual controls)
2. **Node's own `theme` property** (Theme resource assigned directly)
3. **Nearest ancestor's `theme` property** (walks up the tree)
4. **Project default theme** (Project Settings > GUI > Theme > Custom)

### Recommended Setup for RPGs

**One project-wide Theme resource** assigned in Project Settings > GUI > Theme > Custom. This gives consistent baseline styling across all menus.

```
res://themes/
  rpg_theme.tres          # Main theme resource
  fonts/
    pixel_font.tres       # FontFile for body text
    pixel_font_large.tres # Variation for headers
  styleboxes/             # Optional: external StyleBox .tres for reuse
```

### Theme Item Types

| Type | Purpose | Example |
|------|---------|---------|
| **StyleBox** | Panel backgrounds, button states, input field borders | `StyleBoxFlat` for flat UI, `StyleBoxTexture` for 9-slice art |
| **Color** | Text color, icon modulation | `font_color`, `font_hover_color` |
| **Font** | Text rendering (all settings except size) | Body font, header font |
| **Font Size** | Text size (paired with font) | Body size, title size |
| **Icon** | Textures on buttons, checkboxes | Checkbox checked/unchecked icons |
| **Constant** | Integer values: spacing, margins, flags | `separation` on containers |

### StyleBox Types

- **StyleBoxFlat**: Solid colors, rounded corners, borders, shadows. Best for clean/modern RPG UI or prototyping.
- **StyleBoxTexture**: 9-slice scaling from a texture atlas. Best for hand-drawn or pixel-art RPG frames. Configure `texture_margin_*` to define the non-stretching corners/edges.
- **StyleBoxEmpty**: Transparent/no-draw. Use to "erase" inherited styles on specific controls.
- **StyleBoxLine**: Single line (underline/overline). Rarely used in RPG UI.

### Theme Type Variations

Create variations of base types for contextual styling without duplicating everything:

```gdscript
# In the Theme editor: create type variation "DangerButton" based on "Button"
# Only override what differs (e.g., red font_color, red stylebox border)
# Apply in scene: set the Button's theme_type_variation = "DangerButton"
```

Use cases: `HeaderLabel`, `DimLabel`, `GoldLabel`, `DangerButton`, `SmallButton`.

### Practical Tips

- **Edit themes in the Theme Editor** (bottom panel when a `.tres` theme is selected). It previews all control types live.
- **Duplicate StyleBoxes before overriding.** Theme resources share StyleBox instances. If you modify one in code at runtime, call `.duplicate()` first (same Resource sharing pitfall as game data).
- **Prefer theme items over `modulate` for text dimming.** `modulate` affects children recursively. Theme colors target specific text properties without side effects. (Note: RootsGame's `quest_tab.gd` uses `modulate` for completed quests -- a theme variation like `DimLabel` would be cleaner.)

---

## 3. UI Animation

### Tween vs AnimationPlayer Decision Matrix

| Criterion | Tween | AnimationPlayer |
|-----------|-------|-----------------|
| **Values known at design time** | No -- computed at runtime | Yes -- keyframed in editor |
| **Complexity** | 1-3 properties | Multi-track, multi-node |
| **Iteration speed** | Faster in code | Faster in editor |
| **Reuse** | Code patterns | .anim resources |
| **Sequencing** | Chain with `.tween_*()` calls | Timeline with tracks |
| **Performance** | ~30% faster for simple dynamic anims | Better for complex multi-track |

### Tween Best Practices (from RootsGame patterns)

RootsGame's `item_toast.gd` demonstrates the correct pattern:

```gdscript
# Always kill the previous tween before creating a new one
if _tween and _tween.is_valid():
    _tween.kill()
_tween = create_tween()

# Chain: fade in -> hold -> fade out
_tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
_tween.tween_interval(2.0)
_tween.tween_property(_panel, "modulate:a", 0.0, 0.3)
```

Key rules:
- **Always kill prior tweens** on the same property before starting new ones. Overlapping tweens fight.
- **Use `create_tween()`** (node method) not `get_tree().create_tween()`. Node-bound tweens auto-clean on `queue_free()`.
- **Use `.set_ease()` and `.set_trans()`** for polish: `Tween.EASE_IN_OUT` + `Tween.TRANS_CUBIC` feels natural for menus.
- **Prefer `.tween_property()` over `.tween_method()`** when possible -- property tweens are simpler and more readable.

### Common RPG UI Animations

**Menu open/close slide:**
```gdscript
func _open_menu() -> void:
    visible = true
    modulate.a = 0.0
    var tween: Tween = create_tween()
    tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(self, "modulate:a", 1.0, 0.15)
```

**Notification toast** (fade in, hold, fade out): See `item_toast.gd` pattern above.

**Screen wipe/transition:**
```
TransitionLayer (CanvasLayer, layer = 200)
  ColorRect (full screen, starts transparent)
```
Use AnimationPlayer or Tween to fade to opaque, swap scenes, then fade back. For fancier wipes, replace `ColorRect` with `TextureRect` + a shader that animates a dissolve mask.

### When to Use AnimationPlayer

- **Multi-property orchestration**: A button that scales, changes color, and plays a sound simultaneously.
- **Designer-driven timing**: When artists/designers need to tweak timing in the editor without touching code.
- **Reusable animations**: Save as `.anim` resources and share across scenes.
- **Sprite sheet UI**: Animated icons, character portraits with expressions.

---

## 4. Focus and Navigation

### Core Concepts

- **Focus mode** on each Control: `FOCUS_ALL` (keyboard + mouse), `FOCUS_CLICK` (mouse only), `FOCUS_NONE` (unfocusable). RPG menus should set interactive elements to `FOCUS_ALL`.
- **Focus neighbors**: Define which control receives focus when pressing up/down/left/right. Set in Inspector or code: `focus_neighbor_bottom`, `focus_neighbor_top`, etc.
- **`grab_focus()`**: Programmatically sets focus. Call with `call_deferred()` in `_ready()` or after visibility changes.

### RPG Menu Navigation Pattern

RootsGame's `game_menu.gd` demonstrates the recommended approach:

1. **On menu open**: Call `_set_tab_focus.call_deferred(tab_index)` to focus the first interactive element.
2. **On tab change**: Re-grab focus for the new tab's first element.
3. **Each tab implements `grab_initial_focus()`**: Focuses its first interactive child.

```gdscript
# Tab's focus method
func grab_initial_focus() -> void:
    if _item_list.get_child_count() > 0:
        var first: Control = _item_list.get_child(0) as Control
        if first:
            first.grab_focus()
```

### Common Pitfalls

1. **No initial focus.** If nothing has focus when a menu opens, keyboard/gamepad input does nothing. Always `grab_focus()` on the first element.

2. **Focus escapes the menu.** Tab/arrow keys can navigate to controls outside the current panel. Set `focus_neighbor_*` properties to loop within the menu, or use `focus_next`/`focus_previous` to create a closed ring.

3. **`ui_left`/`ui_right` conflicts.** These are mapped to arrow keys by default, which also drive focus neighbors. RootsGame correctly handles this by consuming tab-switching input in `_input()` with `set_input_as_handled()`.

4. **Dynamically spawned children lose focus setup.** When rebuilding a list (e.g., inventory refresh with `queue_free()` + `add_child()`), focus neighbors are lost. Re-grab focus after rebuilding.

5. **ScrollContainer focus**: ScrollContainer does not auto-scroll to focused children by default. Use `ensure_control_visible()` after a child grabs focus:
   ```gdscript
   child.grab_focus()
   scroll_container.ensure_control_visible(child)
   ```

### Gamepad-Friendly Navigation Checklist

- [ ] Every menu screen has a default focused element on open
- [ ] Tab switching works with shoulder buttons or `ui_left`/`ui_right`
- [ ] Lists auto-focus the first item and wrap at boundaries
- [ ] Modal dialogs trap focus (no escape to background controls)
- [ ] ScrollContainers scroll to follow focus
- [ ] Cancel/back action (`ui_cancel`) closes the current menu layer

---

## 5. Responsive Layout for Pixel Art

### RootsGame Current Setup

```
viewport_width = 1920
viewport_height = 1080
stretch/mode = "canvas_items"
```

### Stretch Mode Comparison

| Mode | Behavior | Best For |
|------|----------|----------|
| **`disabled`** | No scaling. UI stays at exact pixel size. | Desktop-only, fixed resolution |
| **`canvas_items`** | Renders at window resolution, uses base resolution as reference. Sprites stay sharp. | Pixel art with smooth camera/UI (recommended) |
| **`viewport`** | Renders at base resolution, then scales the entire framebuffer. Everything pixelated equally. | Pure retro aesthetic where UI should also be chunky |

### Pixel Art Specific Configuration

1. **Texture filtering**: Set `rendering/textures/canvas_textures/default_texture_filter` to `Nearest` in Project Settings. This keeps pixel art crisp at all scales.

2. **Stretch aspect**: Set to `keep` to maintain aspect ratio with black bars, or `expand` to fill the window (UI anchors must handle extra space).

3. **Integer scaling** (optional): Enable `window/stretch/scale_mode = "integer"` to prevent sub-pixel distortion. Creates black borders at non-integer multiples.

4. **UI at higher resolution than game art**: If using `canvas_items` mode, UI text and panels render at full window resolution while sprites use nearest-neighbor filtering. This gives crisp readable UI over pixel-art gameplay -- the standard approach for modern pixel-art RPGs (Celeste, CrossCode style).

5. **If using `viewport` mode with high-res UI**: Use a separate `SubViewport` for game rendering at low resolution, and draw UI directly on the root viewport at full resolution. This is more complex but allows pixel-perfect game art with smooth UI text.

### Anchor Presets for Common UI Positions

| Element | Anchor Preset | Notes |
|---------|--------------|-------|
| Full-screen menu | Full Rect | Fills available space |
| HP bar (top-left) | Top Left | Fixed position |
| Minimap (top-right) | Top Right | Fixed position |
| Dialog box (bottom) | Bottom Wide | Stretches horizontally, pinned to bottom |
| Notification toast | Top Right or Center Top | Fixed, offset from edge |
| Boss health bar | Bottom Wide | Centered, fixed height |

---

## 6. UI Layering

### CanvasLayer Strategy

CanvasLayers render independently from the game world. Each has a `layer` property (integer) that determines draw order. Higher numbers render on top.

**Recommended layer assignments for RPG:**

| Layer | Purpose | Example |
|-------|---------|---------|
| 0 | Game world (default) | Tilemaps, characters, particles |
| 100 | Persistent HUD | HP bars, minimap, quest indicator |
| 110 | Game menus | Pause menu, inventory (RootsGame uses this) |
| 120 | Modal dialogs | Confirmation prompts, save/load dialogs |
| 150 | Dialogue system | NPC conversation boxes |
| 200 | Screen transitions | Fade-to-black, wipe effects |
| 250 | System overlays | FPS counter, debug console |

### Key Rules

1. **One CanvasLayer per UI "plane."** Do not put HUD and menus on the same CanvasLayer -- they need independent visibility control.

2. **`z_index` only works within the same CanvasLayer.** A Control with `z_index = 100` inside CanvasLayer(layer=1) still renders below everything in CanvasLayer(layer=2). Use CanvasLayer `layer` for major ordering, `z_index` for within-layer sorting.

3. **`process_mode = ALWAYS` for pause-surviving UI.** RootsGame correctly sets this on the game menu CanvasLayer. Without it, pausing the tree hides/freezes the pause menu itself.

4. **Input order is separate from draw order.** CanvasLayers in higher layers receive input first by default. A modal dialog on layer 120 naturally blocks input to the HUD on layer 100, but only if the modal has a full-screen invisible Control consuming clicks.

### Modal Dialog Pattern

```gdscript
# Modal background: full-screen Control that blocks clicks to layers below
var blocker: Control = Control.new()
blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
blocker.mouse_filter = Control.MOUSE_FILTER_STOP  # Blocks mouse to layers below
add_child(blocker)
# Then add the actual dialog panel on top of the blocker
add_child(dialog_panel)
```

### RootsGame's Layering (Current)

The HUD autoload instantiates three CanvasLayer children:
- `item_toast` -- notification popup
- `quest_indicator` -- persistent on-screen marker
- `game_menu` -- tabbed pause menu (layer 110)

This follows the recommended pattern from the godot-patterns skill: "Persistent UI as autoloads, not reparented scene children."

---

## 7. Signal Patterns for UI

### Principle: UI is a Consumer, Not a Producer of Game State

UI reads from game systems and reacts to their signals. UI should never directly mutate game state -- it requests actions through the systems that own the data.

```
Game Systems (Inventory, QuestTracker)
    |--- emit signals (item_added, quest_completed)
    |         |
    |         v
    |    UI Nodes (listen, refresh display)
    |
    |<-- UI calls system methods (use_item, accept_quest)
```

### Connection Patterns

**1. Direct signal connection (preferred for 1:1 relationships):**
```gdscript
# Tab connects to its data source
func connect_to_player(player: PlayerController) -> void:
    _inventory = player.get_inventory()
    _inventory.item_added.connect(_on_items_changed.unbind(2))
```

**2. Event Bus (for cross-system broadcasts):**
```gdscript
# Only for events that multiple unrelated systems care about
EventBus.quest_completed.connect(_on_quest_completed)
```

**3. `connect_to_player()` injection pattern (RootsGame standard):**

The HUD autoload receives the player reference via `SceneManager.player_registered` and propagates it to each UI child via `connect_to_player()`. This avoids UI elements searching for the player themselves.

```gdscript
# HUD autoload
func _on_player_registered(player: PlayerController) -> void:
    _item_toast.call("connect_to_player", player)
    _quest_indicator.call("connect_to_player", player)
    _game_menu.call("connect_to_player", player)
```

### Guard Against Duplicate Connections

For UI that can be re-opened (menus, dialogs), guard against connecting the same signal twice:

```gdscript
if not _inventory.item_added.is_connected(_on_items_changed):
    _inventory.item_added.connect(_on_items_changed)
```

### Signal-Driven Refresh vs Polling

- **Always use signal-driven refresh.** Connect to data-change signals and rebuild the display on change. Never poll in `_process()`.
- **Batch updates.** If multiple signals fire in the same frame (e.g., loading saved inventory), use `call_deferred("_refresh_list")` to collapse into a single rebuild.
- **Handle empty state.** Always show a placeholder when data is empty. RootsGame's `_empty_label.visible = items.is_empty()` is the right pattern.

### Catch-Up Pattern

When UI connects to a signal in `_ready()`, the event may have already fired. Check state after connecting:

```gdscript
func _ready() -> void:
    SceneManager.player_registered.connect(_on_player_registered)
    # Catch-up: player may already exist
    var existing: PlayerController = SceneManager.get_player()
    if existing:
        _on_player_registered(existing)
```

RootsGame's `hud.gd` correctly implements this pattern.

---

## 8. Common Pitfalls Checklist

### Architecture
- [ ] UI autoload is `.gd` not `.tscn` (prevents type inference issues per CLAUDE.md)
- [ ] UI elements never reparent themselves -- they live under HUD autoload
- [ ] CanvasLayers for UI are NOT nested inside other CanvasLayers (causes transform stacking)
- [ ] `process_mode = ALWAYS` on any UI that must work while tree is paused

### Layout
- [ ] All container children have `custom_minimum_size` set
- [ ] ScrollContainers have a maximum height/width or anchors constraining them
- [ ] Full-screen menus use `PRESET_FULL_RECT` anchors
- [ ] No hardcoded pixel positions -- use containers and anchors

### Focus
- [ ] Every openable menu calls `grab_focus()` on its first element
- [ ] `grab_focus()` is called via `call_deferred()` after visibility/tab changes
- [ ] TabContainer tab bar has `focus_mode = FOCUS_NONE`
- [ ] Dynamic lists re-establish focus after rebuilding children

### Theme
- [ ] A project-wide Theme is assigned in Project Settings
- [ ] StyleBoxes are `.duplicate()`d before runtime modification
- [ ] Theme type variations used for contextual styles (instead of per-node overrides)

### Animation
- [ ] Previous tweens are `.kill()`ed before creating new ones on the same property
- [ ] Tweens are created with `create_tween()` (node-bound), not `get_tree().create_tween()`
- [ ] No `await` on tweens in `_ready()` (blocks tree initialization)

### Performance
- [ ] Lists use signal-driven refresh, not `_process()` polling
- [ ] `queue_free()` + rebuild pattern for dynamic lists (not `remove_child()` which leaks)
- [ ] UI nodes not visible on screen have `visible = false` (skips draw)

---

## Sources

### Official Documentation
- [User Interface (UI) index](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [Keyboard/Controller Navigation and Focus](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html)
- [Introduction to GUI Skinning](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html)
- [Multiple Resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Canvas Layers](https://docs.godotengine.org/en/stable/tutorials/2d/canvas_layers.html)
- [StyleBoxFlat](https://docs.godotengine.org/en/stable/classes/class_styleboxflat.html)
- [StyleBoxTexture](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html)
- [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html)

### Community / Educators
- [How to Create UI in Godot 4 (Febucci)](https://blog.febucci.com/2024/11/godots-ui-tutorial-part-one/)
- [Overview of Godot UI Containers (GDQuest)](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers)
- [Making the Most of the Theme Editor (GDQuest)](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/telling_a_story/all_theme_editor_areas)
- [Scene Transitions (GDQuest)](https://www.gdquest.com/tutorial/godot/2d/scene-transition-rect/)
- [Pixel Art Setup in Godot 4 (GDQuest)](https://www.gdquest.com/library/pixel_art_setup_godot4/)
- [Setting Up Pixel Art in Godot 4.4 (itch.io)](https://itch.io/blog/806788/godot-44-settings-for-pixel-art)
- [Making a Slick User Interface (Steven Splint)](https://stevensplint.com/making-a-slick-user-interface-in-godot-part-1/)
- [Tween Best Practices (UhiyamaLab)](https://uhiyama-lab.com/en/notes/godot/tween-smooth-animation/)
- [Display Scaling in Godot 4 (Chickensoft)](https://chickensoft.games/blog/display-scaling)
- [UI Nodes Good Practice (Godot Forum)](https://forum.godotengine.org/t/ui-nodes-good-practice/77720)

### Skill References (godot-compound)
- `godot-patterns/references/scene-architecture.md` -- composition, signals, autoload UI
- `godot-patterns/references/resource-system.md` -- Resource sharing/duplication pitfalls
- `godot-patterns/references/timing-async.md` -- `call_deferred()`, signal timing, catch-up
