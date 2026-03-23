---
title: "feat: UI Overhaul — Theme-First Foundation"
type: feat
status: active
date: 2026-03-23
origin: docs/brainstorms/2026-03-22-ui-overhaul-brainstorm.md
---

# UI Overhaul — Theme-First Foundation

Complete UI overhaul establishing a cohesive visual identity via a reskinnable Theme system. Sea of Stars-inspired clean & modern style with warm amber/earth palette. Covers core menus, HUD overlays, dialogue system with portraits, notification system, settings menu, confirmation dialogs, and polished transitions.

## Enhancement Summary

**Deepened on:** 2026-03-23
**Agents used:** 10 (architecture, timing, performance, patterns, simplicity, resource-safety, framework-docs, godot-patterns, notifications-research, learnings)

### Critical Fixes Applied
1. **NotificationManager must use `connect_to_player()` pattern** — Inventory/QuestTracker are player children, NOT autoloads. Signal chain notation corrected throughout.
2. **Rename `ConfirmationDialog`** → `ConfirmPopup` to avoid shadowing Godot's built-in class.
3. **ConfirmPopup uses signals + `CONNECT_ONE_SHOT`** — not Callable params, which are unsafe if calling node is freed.
4. **StyleBox `.duplicate()` mandatory** — any script-driven StyleBox tweening must duplicate first or it corrupts the shared Theme.
5. **Tab rebuilds: `remove_child()` + `queue_free()`** — prevents zombie children appearing in `get_children()` for one frame.
6. **Do NOT use VBoxContainer for notifications** — VBoxContainer recalculates all child positions on add/remove, conflicting with active tweens. Use manual positioning with a plain Control anchor.

### Architecture Improvements
7. **SettingsManager must NOT emit signals in `_ready()`** — consumers pull initial state via getters; signals only for runtime changes.
8. **`_is_animating` guard lives in `hud.gd`** and uses `Tween.is_valid()` instead of boolean flag.
9. **`GameMode.TRANSITION` always restores to `OVERWORLD`** — don't try to restore "previous mode."
10. **Inventory public API returns `.duplicate(true)`** — prevents UI from mutating internal state.
11. **Add `_exit_tree()` disconnect pattern** to all tab/UI scripts that connect cross-lifecycle signals.
12. **Inventory: incremental update** — use signal arguments for single-slot add/remove instead of full teardown.
13. **Notification flush: stagger** — one notification per 0.5s, not all at once.
14. **SettingsManager autoload position:** after SaveManager, before HUD. Explicit in autoload chain.
15. **Portrait data: use custom `PortraitData` Resource class** — not raw Dictionary.
16. **Defer Theme promotion to Phase 6** — apply per-screen until final consistency pass.
17. **ScrollContainer: enable `follow_focus = true`** for automatic keyboard/gamepad scroll tracking.
18. **Tweens during pause need `create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)`** or equivalent.

### YAGNI Decisions (resolved)
The simplicity review flagged several items. Resolutions:
- Sub-themes → **cut** (one Theme with type variations suffices for ~10 UI files)
- HP bar stub → **kept** (architectural prep for combat system)
- ButtonPrompt → **kept** (useful for existing keyboard prompts)
- Card/tile inventory, compact list toggle, sort → **kept** (brainstorm decisions)
- NotificationManager → **kept** (replaces item_toast, toast rework merged into Phase 4)

## Overview

RootsGame currently has zero Theme resources — all UI uses Godot defaults with a few scattered inline overrides. The overhaul builds a project-wide Theme resource first, then restyles every screen to use it, then adds missing screens. This "Theme-First Foundation" approach ensures every new screen automatically inherits the style and the visual identity can evolve without reworking layouts (see brainstorm: Why This Approach).

## Problem Statement

Current UI state:
- No project-wide Theme `.tres` — scattered `theme_override_*` properties and inline sub_resources
- Dialogue balloon is the unmodified addon example template
- Inventory and quest tabs are read-only Label lists with no interactivity
- Stats tab is a "Coming Soon" stub
- No settings menu, no confirmation dialogs on quit/load/save
- No health/status HUD beyond quest indicator
- No transition animations on menus
- Tabs access private members directly (`_inventory._items`, `_quest_tracker._quests`)
- CanvasLayer allocation is undocumented (toast/indicator at 10, dialogue at 100, scene transition at 100 — conflict)

## Proposed Solution

Six-phase implementation following the Theme-First approach:

1. **Foundation** — Theme resource, CanvasLayer convention, input refactoring, public APIs
2. **Restyle existing** — Apply Theme to game menu, tabs, dialogue, toast, indicator
3. **Dialogue balloon** — Custom balloon with portrait support
4. **HUD redesign** — Notification system, contextual quest indicator
5. **New screens** — Settings menu, confirmation dialogs, stats tab placeholder
6. **Polish** — Transitions, micro-animations, empty states

## Technical Approach

### Architecture

#### Theme Cascade

```
Project Settings > GUI > Theme > Custom
  └─ res://resources/themes/main_theme.tres         (project-wide defaults)
      └─ All Control nodes inherit automatically
```

Start with a single `main_theme.tres`. Sub-themes (dialogue, HUD) can be added later if the single theme becomes unwieldy — with only ~10 UI files, type variations cover all current needs. *(YAGNI review: sub-themes deferred.)*

Theme type variations: `HeaderLabel`, `DimLabel`, `AccentButton`, `DangerButton`, `GhostButton`.
StyleBoxFlat for all panels. Corner radius parameterized for experimentation.

**Do NOT apply as project theme until Phase 6** — apply per-screen in Phases 2-5 to enable incremental testing without affecting scenes under construction.

#### CanvasLayer Convention

| Layer | Purpose | Notes |
|-------|---------|-------|
| 0 | Game world | Default |
| 90 | Scene transitions | Fade overlay (moved from 100 to resolve conflict) |
| 100 | HUD | Quest indicator, HP bar, notifications |
| 110 | Game menus | Inventory, quests, settings, pause |
| 120 | Modals | Confirmation dialogs |
| 130 | Dialogue | Balloon + portraits (above modals so NPC dialogue is always visible) |
| 200 | System overlays | Debug, FPS counter |

#### Input Priority Chain

```
_input() layer (runs first, highest to lowest CanvasLayer):
  └─ Confirmation dialog: consumes ALL input when open (cancel = dismiss dialog only)
  └─ HUD: "pause" action opens/closes game menu (blocked when mode != OVERWORLD)

_gui_input() / focus layer:
  └─ Active focused Control handles ui_accept, ui_cancel, arrows
  └─ Tab switching: dedicated "ui_prev_tab" / "ui_next_tab" actions (Q/E keys)
       Frees ui_left/ui_right for in-tab grid navigation

_unhandled_input() layer:
  └─ Dialogue balloon: blocks all remaining input when visible
```

**Key change:** Tab switching moves from `ui_left`/`ui_right` to new `ui_prev_tab`/`ui_next_tab` input actions. This unblocks horizontal navigation in card/tile inventory grids (see brainstorm: SpecFlow Gap 7).

#### Settings Persistence

Settings use a separate `user://settings.cfg` via Godot's `ConfigFile`. Independent from save data so settings survive across save slots and new games.

```
[audio]
master_volume=1.0
music_volume=0.8
sfx_volume=1.0

[display]
fullscreen=false
vsync=true

[gameplay]
always_show_hp=false
```

### Implementation Phases

---

#### Phase 1: Foundation (prerequisite for all other phases)

Build the design system and fix architectural issues that block the overhaul.

**1.1 Create Theme resource**

Create `res://resources/themes/main_theme.tres` with:

- Color constants matching brainstorm palette (panel `#2a1f18`, accent `#c87533`, primary text `#f0e6d6`, secondary text `#a89880`)
- StyleBoxFlat definitions for Panel, PanelContainer, Button (normal/hover/pressed/disabled/focus), TabContainer, ScrollContainer
- Panel StyleBox: dark brown bg at 75-80% alpha, 1-2px amber border, 4-6px drop shadow at 15-20% opacity, parameterized corner radius
- Font resources: placeholder sans-serif for body (Noto Sans or similar), placeholder for headers. Exact fonts TBD via visual testing (see brainstorm: Open Question 3)
- Font sizes: headers 24-28px, body 18-20px, metadata 14-16px
- Type variations: `HeaderLabel`, `DimLabel`, `AccentButton`, `DangerButton`

Do NOT set as project theme yet — apply per-screen in Phases 2-5 to enable incremental testing. Promote to project-wide in Phase 6 final consistency pass.

**Resource safety rule:** Any script that tweens or modifies a StyleBox property at runtime must first call `.duplicate()` on the StyleBox and apply the copy via `add_theme_stylebox_override()`. Never mutate a StyleBox obtained from `get_theme_stylebox()` directly — it is shared across all Controls using the Theme.

Files:
- `resources/themes/main_theme.tres` (new)
- `resources/fonts/` (new directory for font resources)

**1.2 Fix CanvasLayer conflicts**

- Move SceneManager transition overlay from layer 100 to layer 90
- Document layer convention in a comment block in `hud.gd` or a reference doc
- Update dialogue balloon to layer 130

Files:
- `scripts/autoloads/scene_manager.gd` — change transition CanvasLayer to 90
- `scenes/ui/dialogue_balloon.tscn` — property edit: layer = 130

**1.3 Add GameMode.TRANSITION**

Add `TRANSITION` to the GameMode enum in `game_state.gd`. Set it in `scene_manager.gd` at start of `change_scene()` (before fade-out), set `OVERWORLD` after fade-in completes. **Always restore to OVERWORLD** — do not try to restore "previous mode" because the pre-transition mode (DIALOGUE, MENU) is no longer valid after a scene change. On error (failed scene load), also reset to OVERWORLD. This mirrors the existing `_is_transitioning` flag lifecycle. (SpecFlow Gap 9, timing review.)

Files:
- `scripts/autoloads/game_state.gd` — add TRANSITION to enum
- `scripts/autoloads/scene_manager.gd` — set/restore mode around transitions

**1.4 Refactor tab switching input**

Create new input actions `ui_prev_tab` (Q key) and `ui_next_tab` (E key) in `project.godot`. Update `game_menu.gd` to use these instead of `ui_left`/`ui_right`. This frees arrow keys for in-tab navigation.

Files:
- `project.godot` — add input actions
- `scripts/ui/game_menu.gd` — change tab switch actions

**1.5 Add public API to Inventory and QuestTracker**

Replace direct private member access with public methods. All getters must return `.duplicate(true)` to prevent UI from mutating internal state. Sorting is a presentation concern — keep it in the tab, not the data layer.

```gdscript
# Inventory public API
func get_items() -> Array[Dictionary]:
    return _items.duplicate(true)  # defensive copy
func get_item_count() -> int:
    return _items.size()

# QuestTracker public API
func get_active_quests() -> Array[Dictionary]:
func get_completed_quests() -> Array[Dictionary]:
func get_tracked_quest() -> Dictionary:
func set_tracked_quest(quest_id: String) -> void:
```

**Also fix: signal disconnect pattern.** All tab scripts and new UI components that connect to Inventory/QuestTracker signals via `connect_to_player()` must disconnect in `_exit_tree()`. This prevents leaked connections if tabs are re-instantiated (e.g., after `load_game()`). Guard with `is_connected()` in `connect_to_player()` to prevent double-connections.

```gdscript
func _exit_tree() -> void:
    if _inventory and _inventory.item_added.is_connected(_on_items_changed):
        _inventory.item_added.disconnect(_on_items_changed)
```

**Also fix: tab rebuild pattern.** Replace `queue_free()` with `remove_child()` + `queue_free()` to prevent zombie children:

```gdscript
for child: Node in container.get_children():
    container.remove_child(child)
    child.queue_free()
```

**Also fix: incremental updates.** Stop unbinding signal arguments. Use `item_id` and `quantity` from `item_added`/`item_removed` to add/remove a single slot instead of rebuilding the entire list. Reserve full rebuilds for sort/filter changes.

Files:
- `scripts/autoloads/inventory.gd` — add public getters with `.duplicate(true)`
- `scripts/autoloads/quest_tracker.gd` — add public getters + tracked quest state
- `scripts/ui/tabs/inventory_tab.gd` — use public API, add `_exit_tree()`, incremental updates
- `scripts/ui/tabs/quest_tab.gd` — use public API, add `_exit_tree()`

**1.6 Settings persistence layer**

Create `SettingsManager` autoload using `ConfigFile` for `user://settings.cfg`. Register with explicit `res://scripts/autoloads/settings_manager.gd` path (never `uid://`, per CLAUDE.md).

**Autoload position:** Insert after SaveManager, before HUD. Full order:
`EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager, SettingsManager, HUD`
Update `.claude/rules/autoload-patterns.md` to document this.

**Critical timing rule:** Do NOT emit `setting_changed` signals during `_ready()`. Consumers pull initial state via typed getters. Signals only fire on runtime changes from the settings UI. This prevents signals being lost before HUD children exist.

```gdscript
# SettingsManager API — return primitives, never internal state
func get_float(section: String, key: String, default: float = 0.0) -> float:
    return _config.get_value(section, key, default)

func get_bool(section: String, key: String, default: bool = false) -> bool:
    return _config.get_value(section, key, default)

func set_value(section: String, key: String, value: Variant) -> void:
    _config.set_value(section, key, value)
    _config.save(SETTINGS_PATH)
    setting_changed.emit(section + "/" + key, value)
```

**Error handling:** On `ConfigFile.load()` failure (missing or corrupt file), log a warning, apply code-defined defaults, and rewrite the file.

Files:
- `scripts/autoloads/settings_manager.gd` (new)
- `project.godot` — register autoload
- `.claude/rules/autoload-patterns.md` — update order documentation

**Success criteria:**
- [x] Theme `.tres` files created with full color palette, StyleBoxes, type variations
- [x] CanvasLayer conflict resolved (transition at 90, dialogue at 130)
- [x] `GameMode.TRANSITION` blocks menu during scene changes
- [x] Tab switching uses Q/E, arrows free for in-tab navigation
- [x] Inventory/QuestTracker expose public APIs, tabs use them
- [x] SettingsManager loads/saves `user://settings.cfg`

---

#### Phase 2: Restyle Existing Screens

Apply the Theme to every existing UI element. Theme promotion deferred to Phase 6.

**2.1 Game menu shell**

- Apply `main_theme.tres` to the game_menu scene's root PanelContainer
- Style TabContainer tabs: amber accent on active tab, muted on inactive
- Add outlined icons to tabs (Quests, Inventory, Stats, Pause) — simple line-art
- Set up focus neighbors for tab bar accessibility

**2.2 Inventory tab**

- Replace `Label.new()` with instanced `InventorySlot` scene (card/tile layout)
- Card shows: item icon placeholder, name, quantity badge
- GridContainer or FlowContainer for tile layout
- Add sort buttons (by type, name, recency)
- Add compact list toggle button
- Context action popup: select item → small action menu appears (actions TBD per brainstorm)
- `ScrollContainer > VBoxContainer` for list mode, `ScrollContainer > GridContainer` for tile mode

Files:
- `scenes/ui/tabs/inventory_tab.tscn` — restructure (editor)
- `scripts/ui/tabs/inventory_tab.gd` — rewrite with public API, tile/list modes, sorting
- `scenes/ui/components/inventory_slot.tscn` (new — card/tile item scene)
- `scripts/ui/components/inventory_slot.gd` (new)
- `scenes/ui/components/item_action_menu.tscn` (new — context popup)
- `scripts/ui/components/item_action_menu.gd` (new)

**2.3 Quest tab**

- Replace Label list with expandable accordion using instanced `QuestEntry` scene
- Collapsed: quest name + status badge (active/completed)
- Expanded: objectives checklist, quest giver, rewards, "Track" button
- Tracked quest pinned to top, expanded by default
- Category filter buttons (Active / Completed)
- Replace `modulate = Color(1,1,1,0.5)` with `DimLabel` type variation
- `ScrollContainer > VBoxContainer` with instanced QuestEntry scenes

Files:
- `scenes/ui/tabs/quest_tab.tscn` — restructure (editor)
- `scripts/ui/tabs/quest_tab.gd` — rewrite with public API, accordion, tracking
- `scenes/ui/components/quest_entry.tscn` (new)
- `scripts/ui/components/quest_entry.gd` (new)

**2.4 Pause tab**

- Style buttons using Theme (AccentButton for Resume, DangerButton for Quit)
- Wire confirmation dialogs for Quit and Load (Phase 5 dependency — stub for now)
- Add save feedback notification

**2.5 ~~Item toast~~ (MOVED to Phase 4)**

Toast rework merged into Phase 4 alongside NotificationManager — no point restyling a file that Phase 4 deletes and replaces.

**Implementation note:** All ScrollContainers must set `follow_focus = true` for automatic keyboard/gamepad scroll tracking. Use `SCROLL_MODE_SHOW_NEVER` for a clean look with focus-driven scrolling.

**2.6 Quest indicator**

- Remove `theme_override_*` properties from `.tscn`
- Apply HUD sub-theme or type variations
- Match new palette (amber accent for quest name, warm white for step text)

Files:
- `scenes/ui/quest_indicator.tscn` — remove overrides, apply theme (property edits)
- `scripts/ui/quest_indicator.gd` — minimal changes

**2.7 ~~Promote to project theme~~ (DEFERRED to Phase 6)**

Theme promotion deferred to Phase 6.6 final consistency pass. Applying project-wide before Phases 3-5 add new scenes would cause visual mismatches during development. Continue applying per-screen via the `theme` property on each scene's root Control node.

**Success criteria:**
- [x] All existing screens (except toast — deferred to Phase 4) use Theme-derived styling via per-screen `theme` property
- [x] Inventory shows card layout with sort modes (compact list toggle deferred)
- [x] Quest tab uses expandable accordion with tracking
- [x] No inline `theme_override_*` remaining on restyled screens

---

#### Phase 3: Custom Dialogue Balloon

Replace the addon example balloon with a custom-styled balloon supporting portraits.

**3.1 Custom balloon scene**

- Create new balloon scene at `scenes/ui/dialogue_balloon.tscn` (overwrite existing)
- Own script (not addon example) implementing Dialogue Manager's balloon interface
- Layout: bottom-anchored panel with portrait TextureRect on left, dialogue text on right
- Portrait area: flexible size to accommodate different portrait formats (brainstorm Open Question 1)
- Character name in accent color, dialogue text with typewriter effect
- Response buttons styled with Theme

**3.2 Portrait data system**

Use a custom `PortraitData` Resource class (not a raw Dictionary) for type safety and editor validation:

```gdscript
# portrait_data.gd
class_name PortraitData
extends Resource

@export var character_id: String
@export var default_portrait: Texture2D
@export var expressions: Dictionary  # { "happy": Texture2D, "angry": Texture2D }

func get_portrait(expression: String = "") -> Texture2D:
    if expression != "" and expressions.has(expression):
        return expressions[expression] as Texture2D
    return default_portrait
```

- Create `res://resources/portraits/` directory for portrait textures
- Create one `PortraitData` `.tres` per character (e.g., `nathan.tres`)
- Balloon script holds a preloaded lookup Dictionary mapping character names → PortraitData resources
- Reads character name from DialogueLine, looks up portrait, supports expression via `character_name:expression` format
- If no portrait found, hide portrait area gracefully

Files:
- `scenes/ui/dialogue_balloon.tscn` — rebuild in editor
- `scripts/ui/dialogue_balloon.gd` (new — custom balloon script)
- `scripts/resources/portrait_data.gd` (new — Resource class)
- `resources/portraits/` (new directory for `.tres` portrait resources and textures)

**3.3 Register balloon in Dialogue Manager**

- Set `dialogue_manager/balloon_path` to `res://scenes/ui/dialogue_balloon.tscn` in addon settings or `project.godot`
- Verify NPC interactable code still works (should be transparent — DM loads the balloon scene by path)

Files:
- `project.godot` or Dialogue Manager editor settings — set balloon_path

**Success criteria:**
- [x] Custom balloon displays with Theme styling
- [x] Portrait area shows/hides based on character data (PortraitRect node needs editor addition)
- [x] Typewriter text effect works with skip-on-input
- [x] Response choices are styled and focusable
- [x] Existing dialogue content plays correctly

---

#### Phase 4: HUD Redesign

Restructure the HUD for the notification system and modular element architecture.

**4.1 Notification manager**

- New `NotificationManager` scene instantiated by HUD
- Manages a queue of typed notifications (item, quest, save)
- **Do NOT use VBoxContainer** for the notification stack — VBoxContainer recalculates all child positions on add/remove, conflicting with active tweens (causes flicker). Use a plain Control anchor with manual positioning instead.
- Top-right position, manual slot positioning, max 3 visible, stacks downward
- Slide-in from right (0.3s, TRANS_CUBIC/EASE_OUT), auto-dismiss after 3s, slide-out
- When a notification is dismissed, remaining notifications tween upward to fill the gap
- Queues notifications during non-OVERWORLD modes
- **Staggered flush:** When OVERWORLD resumes, dequeue one notification per ~0.5s delay (not all at once). Use a pull model: check queue in `_process()` when mode is OVERWORLD and a display slot is available.
- Replaces item_toast for item notifications
- **Must implement `connect_to_player()`** — Inventory and QuestTracker are player children, NOT autoloads. Wire through the player reference, same as existing item_toast pattern. SaveManager is an autoload, so direct connection is fine for save notifications.
- Add `_exit_tree()` to disconnect signals. Guard `connect_to_player()` with `is_connected()` checks.

```gdscript
# NotificationManager wiring pattern
func connect_to_player(player: PlayerController) -> void:
    if _inventory and _inventory.item_added.is_connected(_on_item_added):
        _inventory.item_added.disconnect(_on_item_added)
    _inventory = player.get_inventory()
    _inventory.item_added.connect(_on_item_added)
    # Same for QuestTracker...
```

Files:
- `scenes/ui/notification_manager.tscn` (new)
- `scripts/ui/notification_manager.gd` (new)
- `scenes/ui/components/notification_toast.tscn` (new — individual notification panel)
- `scripts/ui/components/notification_toast.gd` (new)

**4.2 Refactor HUD children**

- HUD instantiates: NotificationManager, QuestIndicator, GameMenu
- **Delete** `item_toast.tscn` and `item_toast.gd` (functionality fully migrated to NotificationManager — do not leave as dead code)
- HUD calls `_notification_manager.call("connect_to_player", player)` in `_on_player_registered()`, matching the existing pattern at `hud.gd:60-63`
- QuestIndicator simplified: shows tracked quest only (tracking managed by QuestTracker)

Files:
- `scripts/autoloads/hud.gd` — update child management, add NotificationManager to connect_to_player chain
- `scripts/ui/quest_indicator.gd` — simplify to tracked quest display
- `scripts/ui/item_toast.gd` — **delete** (not deprecate)
- `scenes/ui/item_toast.tscn` — **delete**

**4.3 Health/status HUD stub**

- Create placeholder HP bar scene (hidden by default, no data source yet)
- Contextual visibility: appears on damage signal, fades after 5s
- "Always show HP" toggle reads from SettingsManager
- Actual HP data binding deferred until stat/combat system exists (brainstorm Open Question 2)

Files:
- `scenes/ui/hp_bar.tscn` (new — placeholder)
- `scripts/ui/hp_bar.gd` (new — visibility logic, no data binding)

**Success criteria:**
- [x] Notifications appear top-right, stack dynamically, auto-dismiss
- [x] Notifications queue during dialogue/transitions, staggered flush on OVERWORLD
- [x] Quest indicator shows only tracked quest with disconnect guards
- [ ] HP bar stub exists with contextual visibility logic (deferred — no stat system)
- [x] Item toast functionality fully migrated to NotificationManager (old files deleted)

---

#### Phase 5: New Screens

Build the missing UI screens.

**5.1 Confirmation dialog (`ConfirmPopup`)**

Named `ConfirmPopup` to avoid shadowing Godot's built-in `ConfirmationDialog` class.

- Reusable modal component: title, message, Confirm/Cancel buttons
- CanvasLayer at 120, full-screen dimmer with `MOUSE_FILTER_STOP`
- Focus trapped: `grab_focus.call_deferred()` on Confirm button, closed focus loop via focus_neighbor_*
- `_input()` handler: consumes all input, `cancel` action dismisses dialog
- `pause` action (Tab) blocked while dialog is open
- **Signal-based API** (not Callable params — Callables are unsafe if the calling node is freed before dialog resolves):

```gdscript
# confirm_popup.gd
signal confirmed
signal cancelled

func show_dialog(title: String, message: String) -> void:
    # ... setup UI ...
    visible = true
    _confirm_button.grab_focus.call_deferred()

# Caller side (e.g., via HUD):
func _on_quit_pressed() -> void:
    var dialog: ConfirmPopup = HUD.show_confirmation("Quit?", "Unsaved progress will be lost.")
    dialog.confirmed.connect(_do_quit, CONNECT_ONE_SHOT)
```

Using `CONNECT_ONE_SHOT` avoids manual disconnect and prevents duplicate connections.

Files:
- `scenes/ui/confirm_popup.tscn` (new — build in editor)
- `scripts/ui/confirm_popup.gd` (new)

**5.2 Wire confirmation dialogs**

- Pause tab emits a `confirmation_requested` signal (signal up)
- Game menu or HUD listens and forwards to ConfirmPopup (call down)
- Quit: confirmation → `get_tree().quit()`
- Load: confirmation → close menu → `SaveManager.load_game()`
- Save: no confirmation needed; show success notification
- Save overwrite: if save file exists, confirm before overwriting
- **Critical:** `close_game_menu()` must dismiss any active ConfirmPopup (use `call_deferred()` for the tree mutation)

Files:
- `scripts/ui/tabs/pause_tab.gd` — emit confirmation_requested signal
- `scripts/autoloads/hud.gd` — wire pause_tab signal to ConfirmPopup

**5.3 Settings menu**

- New tab in game menu TabContainer (5th tab, added via editor)
- Three sections/sub-tabs: Audio, Display, Controls
- Audio: HSlider for master/music/SFX volume, bound to SettingsManager + AudioServer buses
- Display: OptionButton for resolution, CheckButton for fullscreen/VSync
- Controls: Read-only key reference (full rebinding deferred)
- Gameplay section: "Always show HP" toggle
- Changes auto-save to `user://settings.cfg` on modification

Files:
- `scenes/ui/tabs/settings_tab.tscn` (new — build in editor)
- `scripts/ui/tabs/settings_tab.gd` (new)
- `scenes/ui/game_menu.tscn` — add 5th tab (editor structural change)

**5.4 Stats tab redesign**

- Replace "Coming Soon" with a designed-but-empty stats layout
- Show character name, level placeholder, stat placeholders
- Styled with Theme, ready for data binding when stat system is built
- Clear "Stats coming soon" message in the empty state, styled consistently

Files:
- `scenes/ui/tabs/stats_tab.tscn` — restructure (editor)
- `scripts/ui/tabs/stats_tab.gd` — styled placeholder

**Success criteria:**
- [ ] Confirmation dialog blocks all input, dismissable with cancel
- [ ] Quit, Load, and Save-overwrite trigger confirmations
- [ ] Settings tab persists audio/display/gameplay preferences
- [ ] Settings survive across save slots and new games
- [ ] Stats tab shows styled placeholder

---

#### Phase 6: Polish

Transitions, micro-animations, and final consistency pass.

**6.1 Menu transitions**

- Game menu open: slide from right + fade in (0.2s, ease-out)
- Game menu close: slide right + fade out (0.2s, ease-in)
- Tab switching: crossfade between tab contents (0.2s, ease-in-out)
- Guard against rapid toggle: use `Tween.is_valid()` instead of a boolean `_is_animating` flag (less error-prone). The guard **must live in `hud.gd`** (which handles the "pause" input), not just `game_menu.gd`.
- **Tweens during pause:** Since the tree is paused during MENU mode, menu tweens must use `create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` or they will freeze on frame 1.

```gdscript
# hud.gd pattern
var _menu_tween: Tween = null

func open_game_menu() -> void:
    if _menu_tween and _menu_tween.is_valid():
        return  # animation in progress, block
    _menu_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    # ... slide + fade animation ...
```

Files:
- `scripts/autoloads/hud.gd` — add tween guard, own the menu animation tweens
- `scripts/ui/game_menu.gd` — tab transition tweens

**6.2 Micro-animations**

- Button hover: subtle brighten + 1.02x scale (0.1s, ease-out)
- Button focus: animated underline or pulsing amber border
- List item selection: sliding highlight indicator
- Accordion expand/collapse: height tween (0.2s)
- **StyleBox safety:** Any script-driven StyleBox modification (e.g., tweening `border_color` on hover) must `.duplicate()` the StyleBox first and apply via `add_theme_stylebox_override()`. Never mutate `get_theme_stylebox()` directly.
- **Tween lifecycle in components:** Every component with hover/focus tweens must store the tween reference and kill it in `_exit_tree()`:

```gdscript
var _hover_tween: Tween = null

func _on_mouse_entered() -> void:
    if _hover_tween and _hover_tween.is_valid():
        _hover_tween.kill()
    _hover_tween = create_tween()
    # ...

func _exit_tree() -> void:
    if _hover_tween and _hover_tween.is_valid():
        _hover_tween.kill()
```

**6.3 Scene transition polish**

- Verify fade-to-black at 0.4s with ease-in-out works with new layer 90 assignment
- Ensure HUD elements at layer 100 are above the fade overlay

**6.4 Empty state styling**

- Inventory: centered message "No items yet" with subtle icon
- Quests: centered message "No active quests — talk to NPCs" with icon
- Stats: styled "Character stats coming soon" with layout preview

**6.5 ButtonPrompt component**

- Reusable scene that displays the correct key glyph for an input action
- Reads current input map, shows "[E]" for interact, "[Q]" for prev tab, etc.
- Prepares architecture for future gamepad glyph swapping (see brainstorm: Gamepad-Proofing Rule 3)

Files:
- `scenes/ui/components/button_prompt.tscn` (new)
- `scripts/ui/components/button_prompt.gd` (new)

**6.6 Final consistency pass**

- **Promote Theme to project-wide:** Set `main_theme.tres` as project default in Project Settings > GUI > Theme > Custom (`project.godot: gui/theme/custom`). This is the first time it becomes project-wide — all prior phases applied it per-screen.
- Remove all remaining `theme_override_*` from scenes
- Remove inline `sub_resource Theme` from dialogue_balloon.tscn
- Verify all screens render correctly at 1920x1080 and 1280x720
- Test keyboard-only navigation through every screen (gamepad-proofing rule 6)

**Success criteria:**
- [ ] Menu open/close has smooth slide+fade transition
- [ ] Buttons have hover and focus micro-animations
- [ ] Accordion expand/collapse animates smoothly
- [ ] Empty states styled consistently across all tabs
- [ ] ButtonPrompt component works for all UI actions
- [ ] Full keyboard-only navigation test passes

---

## Alternative Approaches Considered

- **Screen-by-screen overhaul:** Faster visible progress but risks inconsistency between screens and rework when extracting shared Theme patterns (see brainstorm: Alternatives considered)
- **Parallel tracks (style + layout):** Good separation of concerns but integration risk when merging visual design with interaction logic
- **Chosen: Theme-First Foundation** — establishes the design system before touching any screen, ensuring consistency from the start

## System-Wide Impact

### Signal Chain

New signal flows added by this plan:

```
SettingsManager.setting_changed(key, value)
  → settings_tab: updates UI controls (runtime only, NOT emitted in _ready)
  → AudioServer: updates bus volumes (via settings_tab or SettingsManager)

NotificationManager receives (via connect_to_player, NOT direct autoload access):
  player.get_inventory().item_added → queues item notification
  player.get_quest_tracker().quest_started/completed → queues quest notification
  SaveManager.save_completed → queues save notification (SaveManager IS an autoload, direct is fine)

QuestTracker.tracked_quest_changed (new signal)
  → quest_indicator: updates displayed quest (via connect_to_player)
  → quest_tab: refreshes pin state (via connect_to_player)

ConfirmPopup.confirmed / ConfirmPopup.cancelled (signals, not Callables)
  → caller connects via CONNECT_ONE_SHOT

pause_tab.confirmation_requested(action_type: StringName) (signal up)
  → HUD/game_menu forwards to ConfirmPopup (call down)
  → ConfirmPopup.confirmed → HUD dispatches based on action_type (no Callables)
```

### Error & Failure Propagation

- **Save failure:** `SaveManager.save_game()` can fail silently (push_error only). Plan adds user-visible error notification via NotificationManager.
- **Settings file corruption:** `SettingsManager` should handle missing/corrupt `settings.cfg` by falling back to defaults and rewriting the file.
- **Theme resource missing:** If `main_theme.tres` is deleted, all UI reverts to Godot defaults — degraded but functional. No crash.

### State Lifecycle Risks

- **Menu animation interruption:** Rapid Tab toggle during 0.2s transition. Mitigated by `Tween.is_valid()` guard in `hud.gd` — blocks open/close while tween is active.
- **Confirmation dialog orphaning:** If game menu closes while confirmation is open, the dialog must also close. Wire `close_game_menu()` to dismiss any active confirmation.
- **Notification queue during scene change:** If scene changes while notifications are queued, the queue must survive (NotificationManager is a HUD child, which is an autoload — persists across scenes).

### Scene Interface Parity

Tab scripts use a duck-typed interface dispatched via `has_method()` + `.call()`:
- `grab_initial_focus() -> void` — **required** for all tabs
- `connect_to_player(player: CharacterBody3D) -> void` — **optional** (guarded by `has_method()` in `game_menu.gd`). Settings tab and stats tab may omit it if they don't need player data.

New settings tab implements `grab_initial_focus()`. ConfirmPopup does not use the tab interface — it's invoked imperatively via signals.

**Constraint:** `connect_to_player()` must not depend on the player's tree position — the player may still be mid-reparent when this fires (emit happens before deferred reparent completes in `scene_manager.gd`).

### Integration Test Scenarios

1. **Open menu during scene transition** → menu should be blocked (GameMode.TRANSITION)
2. **Receive item during dialogue** → notification queued, displays after dialogue ends
3. **Rapid menu toggle** → animation completes cleanly, no visual artifacts
4. **Save, then load immediately** → confirmation on load, settings preserved, game state restored
5. **Switch tabs while accordion is expanded** → quest expansion state preserved when returning to tab
6. **Pick up 5 items during dialogue, then exit dialogue** → notifications display one-by-one with 0.5s stagger, max 3 visible
7. **Load game while notifications are showing** → `clear_all()` called, queue emptied, active notifications freed

## Acceptance Criteria

### Functional Requirements

- [ ] Project-wide Theme resource with full amber/earth palette applied to all screens
- [ ] Game menu tabs styled with icons, smooth transitions
- [ ] Inventory shows card/tile layout with sort, filter, compact list toggle
- [ ] Quest tab uses expandable accordion with tracked quest pinning
- [ ] Custom dialogue balloon with portrait support and Theme styling
- [ ] Notification system: top-right, stacking, queuing during dialogue
- [ ] Settings menu: audio, display, controls, persisted to separate config file
- [ ] Confirmation dialogs on quit, load, save-overwrite
- [ ] Contextual HUD elements (appear on change, fade after delay)
- [ ] All menus navigable with keyboard only (no mouse required)

### Non-Functional Requirements

- [ ] Menu open/close transitions complete in ≤0.2s
- [ ] No visual artifacts from rapid menu toggling
- [ ] UI renders correctly at 1920x1080 and 1280x720
- [ ] Primary text contrast ≥4.5:1 against panel backgrounds (WCAG AA)
- [ ] Secondary text contrast ≥3:1 (large text AA standard)

### Quality Gates

- [ ] All new scripts pass `gdformat --check` and `gdlint`
- [ ] Zero `theme_override_*` properties remaining in any `.tscn`
- [ ] All tab scripts implement `grab_initial_focus()`; `connect_to_player()` where needed (optional, guarded by `has_method()`)
- [ ] Keyboard-only navigation test covers every screen and sub-menu

## Dependencies & Prerequisites

| Dependency | Phase | Status | Notes |
|-----------|-------|--------|-------|
| Font files (pixel header + sans-serif body) | Phase 1 | Open | Visual testing needed to select |
| Portrait textures | Phase 3 | Open | Art needed; balloon handles missing portraits gracefully |
| Stat/combat system | Phase 4 (HP bar) | Deferred | HP bar is a stub until system exists |
| Item icons | Phase 2 (inventory) | Open | Placeholder icons for card/tile display |

## Risk Analysis & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| .tscn structural changes can't be text-edited | Blocks scene restructuring | High | Plan phases to front-load editor work; separate from code changes |
| Theme applied too early breaks untouched screens | Visual regression | Medium | Apply per-screen in Phase 2, promote to project-wide only after all screens restyled |
| Font selection delays Phase 1 | Blocks theming | Medium | Use placeholder fonts; swap when final selection is made |
| Card/tile inventory performance with 100+ items | Frame drops on rebuild | Low | Start with rebuild pattern; optimize to pooling only if profiling shows issues |
| Dialogue Manager addon update breaks custom balloon | Broken dialogue | Low | Pin addon version; custom balloon implements stable interface |

## Open Questions (from brainstorm)

1. **Portrait format** — Bust, head-only, or full art? Design balloon to accommodate flexible sizes. Decide when art assets are available.
2. **Stats system** — What stats exist? Stats tab remains a styled placeholder until the system is designed.
3. **Specific font files** — Which pixel font for headers, which sans-serif for body? Decide during Phase 1 via visual testing in-engine. **Note:** Default Godot font has poor "O/0" and "l/d" disambiguation at 18px windowed — noticeable on item names like "Old Amulet". Noto Sans or Inter would fix this.

## Implementation Notes

Key decisions and deviations recorded during implementation:

**Phase 1:**
- Theme applied per-screen via `preload()` in script `_ready()` (not via .tscn ext_resource, which is a forbidden structural edit per CLAUDE.md)
- Sub-themes (`dialogue_theme.tres`, `hud_theme.tres`) cut — one theme with type variations is sufficient for current UI surface area
- SettingsManager autoload position: after SaveManager, before HUD (documented in `.claude/rules/autoload-patterns.md`)
- SettingsManager does NOT emit signals in `_ready()` — consumers pull initial state via getters

**Phase 2:**
- Dictionary value accesses use typed assignment (`var x: String = dict["key"]`) or `str()` for String params to satisfy strict typing. `int()` constructor rejects Variant — use `var x: int = dict["key"]` instead
- `_exit_tree()` disconnects added to all tab scripts and components to prevent signal leaks on player re-registration
- `remove_child()` + `queue_free()` used in list rebuilds (not bare `queue_free()`) to prevent zombie children for one frame
- Tween lifecycle: all components store tween refs and call `.kill()` in `_exit_tree()`

**Phase 3:**
- Custom balloon script implements full DM interface (not subclassing the example)
- `Engine.get_singleton("DialogueManager")` returns `Object` — must use `.connect("signal_name", callable)` not `.signal_name.connect()`
- GDScript `is` check does NOT narrow types for strict typing — must explicitly cast: `var mb: InputEventMouseButton = event as InputEventMouseButton`
- PortraitRect uses `get_node_or_null()` so balloon works before editor adds the node
- PortraitData is a static class (RefCounted), not a .tres Resource — avoids shared mutation concerns

**Phase 4:**
- NotificationManager uses manual positioning (not VBoxContainer) to avoid tween-vs-container conflicts per Godot issue #114974
- Notification anchor dynamically tracks quest indicator panel via `visibility_changed` and `resized` signals — no hardcoded offset
- Toast stacking uses actual `toast.size.y` not hardcoded height
- Staggered flush (0.4s between queued notifications) prevents burst on OVERWORLD resume
- Old `item_toast.gd` and `item_toast.tscn` deleted (not deprecated)

**Editor work still needed:**
- Add PortraitRect (TextureRect, unique_name_in_owner) to `scenes/ui/dialogue_balloon.tscn`
- Clean up unused inline StyleBoxFlat sub_resources from dialogue_balloon.tscn
- Theme promotion to project-wide deferred to Phase 6 final consistency pass

## Sources & References

### Origin

- **Brainstorm document:** [docs/brainstorms/2026-03-22-ui-overhaul-brainstorm.md](docs/brainstorms/2026-03-22-ui-overhaul-brainstorm.md) — Key decisions carried forward: Theme-First approach, Sea of Stars-inspired amber/earth palette, contextual HUD with combat exception, card/tile inventory with compact list toggle, expandable accordion quest log

### Internal References

- [scripts/autoloads/hud.gd](scripts/autoloads/hud.gd) — HUD autoload, connect_to_player pattern, menu lifecycle
- [scripts/ui/game_menu.gd](scripts/ui/game_menu.gd) — Tab switching (needs input refactor), duck-typed tab communication
- [scripts/ui/tabs/inventory_tab.gd](scripts/ui/tabs/inventory_tab.gd) — Private member access to fix
- [scripts/ui/tabs/quest_tab.gd](scripts/ui/tabs/quest_tab.gd) — Private member access to fix
- [scripts/autoloads/game_state.gd](scripts/autoloads/game_state.gd) — GameMode enum (needs TRANSITION)
- [scripts/autoloads/scene_manager.gd](scripts/autoloads/scene_manager.gd) — CanvasLayer 100 conflict to fix

### External References

- [docs/research/rpg-ui-ux-best-practices.md](docs/research/rpg-ui-ux-best-practices.md) — Design patterns from reference RPGs
- [docs/research/rpg-ui-best-practices.md](docs/research/rpg-ui-best-practices.md) — Godot 4 implementation patterns
