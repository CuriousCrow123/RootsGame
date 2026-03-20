# Handoff: Phase 2 Editor Scene Setup (2026-03-20)

## Overview

Phase 2 editor setup for Steps 3-4 (Items + Quest = Playable Loop). Agent wrote all scripts, resource classes, `.tres` files, dialogue, and tests. You build 3 new scenes and update `test_room.tscn` in the Godot editor following the instructions below.

**What the agent committed:** `53d24cf` on `feat/rpg-playable-loop-foundation`

**Scripts ready for scenes:**
- `scripts/interactables/chest_interactable.gd` — expects StaticBody3D root on collision layer 4
- `scripts/ui/item_toast.gd` — expects CanvasLayer root with `$PanelContainer/Label` path
- `scripts/ui/quest_indicator.gd` — expects CanvasLayer root with `$PanelContainer/VBoxContainer/QuestNameLabel` and `$PanelContainer/VBoxContainer/StepLabel` paths

**Resources ready:**
- `resources/items/key_item.tres` — ItemData for "Old Amulet" (item_id = "quest_amulet")
- `resources/quests/fetch_quest.tres` — QuestData with two steps (get_amulet → return_amulet)

---

## Scene 1: Chest Interactable (`scenes/interactables/chest.tscn`)

### What this scene does

The chest is a StaticBody3D that the player walks up to and presses E to interact with. On first interaction, it adds an item to the player's inventory and marks itself as opened. Subsequent interactions do nothing. The script (`chest_interactable.gd`) handles all the logic — the scene just provides the physics body, collision shape, and visual mesh.

### Expected node tree

```
Chest (StaticBody3D)
├── CollisionShape3D
└── MeshInstance3D
```

### Step-by-step

#### 1. Create a new scene

- Menu bar: **Scene > New Scene**
- In the "Create Root Node" dialog, click **Other Node**
- Search for `StaticBody3D`, select it, click **Create**
- The root node appears in the Scene dock named "StaticBody3D"
- **Double-click** the name "StaticBody3D" in the Scene dock and rename it to `Chest`

#### 2. Attach the chest script

- Select the `Chest` root node in the Scene dock
- In the **Inspector** panel (right side), scroll to the top where it says "Node" section
- Find **Script** — click the empty slot, select **Load**, navigate to `res://scripts/interactables/chest_interactable.gd`, click Open
- **Verification:** The Inspector should now show export properties: `Item`, `Item Quantity`, `Chest Id`. If you don't see these, the script didn't attach correctly — check for errors in the Output panel at the bottom.

#### 3. Configure collision layers

The chest needs to be on collision layer 4 ("interactables") so the player's InteractionArea can detect it.

- Select `Chest` in the Scene dock
- In Inspector, find the **Collision** section (expand it if collapsed)
- **Layer:** You'll see a grid of numbered buttons. **Disable all layers** (click any lit ones to toggle them off), then **enable only bit 4**. The bits are numbered left-to-right: 1, 2, 3, **4**. When you hover over a bit, the tooltip shows the layer name — bit 4 should say "interactables".
  - *If bit 4 doesn't show "interactables":* You may need to configure layer names. Go to **Project > Project Settings > Layer Names > 3D Physics** and verify layer 4 is named "interactables". (This was done in Phase 1.)
  - *Consequence of getting this wrong:* If the chest is on the wrong layer, the player's InteractionArea won't detect it, and the "Press E" prompt will never appear near the chest.
- **Mask:** Leave at default (bit 1 = environment). The chest itself doesn't need to detect other bodies — it's a static object.
  - *Note:* Mask controls what the chest "sees." Since the chest never calls `move_and_slide()` or uses area detection, the mask value doesn't matter functionally, but keeping it at 1 is conventional for static bodies.

**Verification:** Hover over each lit bit in the Layer row. Only bit 4 should be lit, showing tooltip "interactables".

#### 4. Add CollisionShape3D

This gives the chest a physical shape so the player can't walk through it and the InteractionArea can detect it.

- Right-click `Chest` in the Scene dock > **Add Child Node**
- Search for `CollisionShape3D`, select it, click **Create**
- Select the new `CollisionShape3D` in the Scene dock
- In Inspector, find the **Shape** property — it says `<empty>`. Click the dropdown > **New BoxShape3D**
- Click the BoxShape3D resource that appears to expand its properties
- Set **Size:** X = `0.8`, Y = `0.8`, Z = `0.8`
  - *Why 0.8:* Slightly smaller than a 1-unit GridMap tile, so the chest sits comfortably within a tile without overlapping walls. A 1.0 box would align exactly to tile edges, which can cause flickering collision at boundaries.

**Verification:** In the 3D viewport, you should see an orange wireframe box around the chest's origin point.

#### 5. Add MeshInstance3D

This is the visual representation of the chest — what the player sees.

- Right-click `Chest` in the Scene dock > **Add Child Node**
- Search for `MeshInstance3D`, select it, click **Create**
- Select the new `MeshInstance3D`
- In Inspector, find the **Mesh** property > click dropdown > **New BoxMesh**
- Click the BoxMesh resource to expand > Set **Size:** X = `0.8`, Y = `0.8`, Z = `0.8` (match the collision shape)

**(Optional but recommended) Give it a distinct color:**
- Still on MeshInstance3D, find **Material Override** in Inspector
- Click dropdown > **New StandardMaterial3D**
- Click the material to expand its properties
- Under **Albedo** section, click the color swatch next to **Color**
- Pick a brownish or gold color (e.g., `#8B6914` for a wooden chest look)
  - *Why:* Without a custom material, the chest will be the default gray, identical to walls. A distinct color makes it visually identifiable during testing.

**Verification:** The 3D viewport should show a colored box. It should be approximately the same height as the floor tile.

#### 6. Configure the export properties on the root

- Select `Chest` in the Scene dock (the root StaticBody3D)
- In Inspector, you should see these exports from `chest_interactable.gd`:
  - **Item:** Click the empty slot > **Load** > navigate to `res://resources/items/key_item.tres` > Open
    - *What this does:* Assigns the "Old Amulet" ItemData resource. When the player interacts, the script reads `item.item_id` ("quest_amulet") and adds it to the inventory.
    - **Verification:** After loading, the slot should show "ItemData" or "key_item.tres". Click the resource to expand it and verify `item_id` = "quest_amulet", `display_name` = "Old Amulet".
  - **Item Quantity:** `1` (default is fine)
  - **Chest Id:** Type `chest_amulet`
    - *What this does:* This string is used as the save key. Every saveable node must have a globally unique key. If two chests share the same ID, saving one overwrites the other's state.
    - *Consequence of leaving it empty:* The save key would be `""`, colliding with any other saveable node that also has an empty key. Save/load would corrupt state.

#### 7. Add to the "saveable" group

This step tells the SaveManager (built in Phase 3) to include this chest in save files.

- Select `Chest` in the Scene dock
- Look at the panel tabs next to Inspector — click the **Node** tab (it has a green circle icon)
- At the bottom of the Node panel, find the **Groups** section
- In the text field, type `saveable` (all lowercase, no quotes)
- Click **Add**
- **Verification:** You should see "saveable" appear in the groups list below the text field. If you accidentally typed it wrong (e.g., "Saveable" with capital S), remove it and re-add — the SaveManager searches for exactly `"saveable"`.

#### 8. Save the scene

- Menu: **Scene > Save Scene As...**
- Navigate to `res://scenes/interactables/`
  - *If the `interactables` folder doesn't exist:* It should — `npc.tscn` is already there from Phase 1. If you don't see it, check you're in the right directory.
- Filename: `chest.tscn`
- Click **Save**

**Final verification checklist for chest.tscn:**
- [ ] Root node is StaticBody3D named "Chest"
- [ ] Script is `chest_interactable.gd`
- [ ] Collision layer = bit 4 ONLY (hover to confirm tooltip says "interactables")
- [ ] CollisionShape3D has BoxShape3D with size 0.8 x 0.8 x 0.8
- [ ] MeshInstance3D has BoxMesh with matching size and a colored material
- [ ] Export `Item` = key_item.tres, `Chest Id` = "chest_amulet"
- [ ] Node is in the "saveable" group

---

## Scene 2: Item Toast UI (`scenes/ui/item_toast.tscn`)

### What this scene does

A brief notification that appears at the bottom of the screen when the player picks up an item. It fades in, shows "Acquired: quest_amulet" for 2 seconds, then fades out. The script connects to the player's Inventory `item_added` signal automatically at runtime — you don't need to wire any signals manually.

### Expected node tree

```
ItemToast (CanvasLayer)
└── PanelContainer
    └── Label
```

**Critical:** The node names and hierarchy must match exactly. The script accesses nodes via `$PanelContainer/Label`. If you rename "PanelContainer" to "Panel" or nest the Label differently, the script will crash with a null reference at runtime.

### Step-by-step

#### 1. Create a new scene

- **Scene > New Scene > Other Node**
- Search for `CanvasLayer`, select it, click **Create**
- Rename the root to `ItemToast`

#### 2. Attach the script

- Select `ItemToast`
- Inspector > **Script** > Load > `res://scripts/ui/item_toast.gd`
- **Verification:** No export properties should appear (this script has none). If you see an error in the Output panel, the script has a parse issue — check the file.

#### 3. Set the CanvasLayer layer number

- Select `ItemToast`
- Inspector > **Layer:** change from `1` to `10`
  - *Why 10:* CanvasLayer.layer controls rendering order. Higher numbers render on top of lower numbers. The game world renders at layer 0, the interaction prompt and dialogue balloon are at lower CanvasLayer values. Layer 10 ensures the toast always appears on top of everything else, including the dialogue UI.
  - *Consequence of leaving at 1:* The toast might render behind the dialogue balloon or other UI elements. Functionally it still works, but visually it may be hidden.

#### 4. Add PanelContainer

- Right-click `ItemToast` > **Add Child Node** > search `PanelContainer` > Create
- The node should already be named `PanelContainer` — **do NOT rename it**
- Select `PanelContainer` and configure its layout:

**Positioning (bottom-center of screen):**
- In the **2D viewport toolbar** (the bar at the top of the 2D editor view), find the **Anchor Presets** button — it looks like a small cross/anchor icon, or you can find it via the menu **Layout** (on the toolbar)
- Click it and select **Center Bottom** from the preset grid
  - *What this does:* Sets the anchor points so the PanelContainer positions itself relative to the bottom center of the screen, regardless of window size.

**Size and offset:**
- Inspector > **Layout** section (or **Control** section depending on Godot version):
  - **Custom Minimum Size:** X = `300`, Y = `40`
    - *Why:* Ensures the panel is wide enough to display item names. Without a minimum size, it collapses to zero if no text is set initially.
  - **Position > Offset Top** (or Offset Y): `-80`
    - *Why:* Pushes the panel up from the very bottom edge. At the exact bottom, it may overlap with other bottom-anchored UI or be partially off-screen.
    - *How to set this:* After selecting Center Bottom anchor preset, you can manually adjust the Y offset in the Inspector. The exact property name varies — look for "Offset" under the "Layout" or "Transform" section. You can also just drag the panel up in the 2D viewport.
  - If offset properties are confusing, just drag the PanelContainer upward in the 2D viewport until it sits about 80 pixels above the bottom edge.

**Verification:** In the 2D viewport, you should see a grey panel rectangle near the bottom center of the blue screen-size rectangle.

#### 5. Add Label inside PanelContainer

- Right-click `PanelContainer` > **Add Child Node** > search `Label` > Create
- The node should be named `Label` — **do NOT rename it** (script references `$PanelContainer/Label`)
- Select the `Label` node and configure:
  - **Text:** Type `Acquired: Item` (this is placeholder text — overwritten at runtime)
  - **Horizontal Alignment:** `Center` (dropdown in Inspector)
  - **Vertical Alignment:** `Center`
  - *Why center alignment:* The label is inside a container that may be wider than the text. Centering keeps it visually balanced.

**Verification:** The 2D viewport should show the panel at the bottom center with "Acquired: Item" text centered inside it.

#### 6. Save the scene

- **Scene > Save Scene As...** > `res://scenes/ui/item_toast.tscn`

**Final verification checklist for item_toast.tscn:**
- [ ] Root is CanvasLayer named "ItemToast" with Layer = 10
- [ ] Script is `item_toast.gd`
- [ ] PanelContainer is a direct child of ItemToast (NOT renamed)
- [ ] Label is a direct child of PanelContainer (NOT renamed)
- [ ] Label text alignment is centered
- [ ] Panel is positioned at bottom-center of the screen

---

## Scene 3: Quest Indicator UI (`scenes/ui/quest_indicator.tscn`)

### What this scene does

A HUD element at the top-right of the screen showing the active quest name and current step description. It appears when a quest starts, updates as the player completes steps, shows "Complete!" when the quest finishes, then hides after 3 seconds. Like the item toast, it connects to signals automatically at runtime.

### Expected node tree

```
QuestIndicator (CanvasLayer)
└── PanelContainer
    └── VBoxContainer
        ├── QuestNameLabel (Label)
        └── StepLabel (Label)
```

**Critical names:** Both labels MUST be named exactly `QuestNameLabel` and `StepLabel`. The script accesses them via `$PanelContainer/VBoxContainer/QuestNameLabel` and `$PanelContainer/VBoxContainer/StepLabel`. Any deviation causes a null reference crash.

### Step-by-step

#### 1. Create a new scene

- **Scene > New Scene > Other Node**
- Search for `CanvasLayer`, select it, click **Create**
- Rename root to `QuestIndicator`

#### 2. Attach the script

- Select `QuestIndicator`
- Inspector > **Script** > Load > `res://scripts/ui/quest_indicator.gd`

#### 3. Set CanvasLayer layer

- Inspector > **Layer:** `10` (same reasoning as item toast — render on top of everything)

#### 4. Add PanelContainer

- Right-click `QuestIndicator` > **Add Child Node** > `PanelContainer` > Create
- **Do NOT rename** — must stay as `PanelContainer`

**Positioning (top-right of screen):**
- Select `PanelContainer`
- In the 2D viewport toolbar, click the **Anchor Presets** button > select **Top Right**
  - *What this does:* Anchors the panel to the top-right corner. It will stay there regardless of window resize.

**Size and offset:**
- Inspector:
  - **Custom Minimum Size:** X = `250`, Y = `60`
    - *Why:* Needs to fit a quest name line and a step description line stacked vertically. 250px wide is enough for most quest text; 60px tall fits two lines comfortably.
  - Adjust offset so the panel sits slightly inward from the corner:
    - You can drag it in the 2D viewport to be ~10px inward from the right edge and ~10px down from the top
    - Or set offsets manually: X offset around `-260` (pulls left from right edge), Y offset around `10` (pushes down from top)

**Verification:** You should see a grey panel rectangle in the top-right area of the screen rectangle in the 2D viewport.

#### 5. Add VBoxContainer inside PanelContainer

- Right-click `PanelContainer` > **Add Child Node** > search `VBoxContainer` > Create
- **Do NOT rename** — must stay as `VBoxContainer`
  - *What VBoxContainer does:* Arranges its children vertically (stacked top-to-bottom). The quest name will be on top, the step description below it.

#### 6. Add QuestNameLabel (first label)

- Right-click `VBoxContainer` > **Add Child Node** > `Label` > Create
- The node is created as "Label". **You MUST rename it:**
  - Double-click the name "Label" in the Scene dock
  - Type `QuestNameLabel` (exact spelling, exact capitalization)
  - Press Enter
- Select `QuestNameLabel` and configure:
  - **Text:** `Quest Name` (placeholder — overwritten at runtime)
  - **(Optional)** To make it visually distinct from the step text:
    - Inspector > **Theme Overrides > Font Sizes > Font Size:** `16` or `18` (slightly larger)
    - Or: Inspector > **Theme Overrides > Colors > Font Color:** pick a brighter or bolder color

**Verification:** After renaming, the Scene dock should show `QuestNameLabel` (not "Label") as a child of VBoxContainer.

#### 7. Add StepLabel (second label)

- Right-click `VBoxContainer` > **Add Child Node** > `Label` > Create
- **Rename** from "Label" to `StepLabel` (exact spelling, exact capitalization)
- Select `StepLabel` and configure:
  - **Text:** `Current step...` (placeholder)
  - **(Optional)** Smaller or dimmer than QuestNameLabel:
    - **Theme Overrides > Font Sizes > Font Size:** `14`
    - **Theme Overrides > Colors > Font Color:** a slightly muted color (e.g., light grey `#AAAAAA`)

**Verification:** The Scene dock should now show this exact tree:
```
QuestIndicator
└── PanelContainer
    └── VBoxContainer
        ├── QuestNameLabel
        └── StepLabel
```
If either label is misnamed or in the wrong order, the script will crash. Double-check by reading the names exactly.

#### 8. Save the scene

- **Scene > Save Scene As...** > `res://scenes/ui/quest_indicator.tscn`

**Final verification checklist for quest_indicator.tscn:**
- [ ] Root is CanvasLayer named "QuestIndicator" with Layer = 10
- [ ] Script is `quest_indicator.gd`
- [ ] PanelContainer > VBoxContainer > QuestNameLabel + StepLabel hierarchy is exact
- [ ] Both labels are named exactly `QuestNameLabel` and `StepLabel` (case-sensitive)
- [ ] Panel is positioned at top-right of screen
- [ ] Panel has minimum size 250 x 60

---

## Scene Updates: test_room.tscn

Now you need to add the three new scenes into the existing test room and configure the NPC's new export.

### Open the test room

- FileSystem dock (bottom-left): navigate to `res://scenes/world/` > double-click `test_room.tscn`
- You should see the existing room with GridMap, player, NPC, camera, light, InteractionPrompt, etc.

### 1. Instance the chest

- Right-click the root node (`TestRoom`) in the Scene dock > **Instantiate Child Scene** (or "Instance Child Scene" in older Godot versions)
- Navigate to `res://scenes/interactables/chest.tscn` > Open
- A `Chest` node appears in the Scene dock as a child of TestRoom

**Position the chest:**
- Select the `Chest` instance in the Scene dock
- In Inspector > **Transform > Position:**
  - X = `3.0`, Y = `0.0`, Z = `3.0`
  - *These are example values — place the chest wherever makes sense in your room. The important thing:*
    - The chest should be on the floor (Y = 0)
    - It should be reachable by the player (not behind walls)
    - It should NOT overlap the NPC (place them in different areas of the room)
    - It should be within the room boundaries
- You can also drag it in the 3D viewport to position it visually. Hold Ctrl while dragging to snap to grid.

**Verification:**
- The 3D viewport should show the colored box (chest) sitting on the floor of the room
- It should not overlap with the NPC, player spawn point, or walls
- Click on the chest in the 3D viewport — the Inspector should show the `chest_interactable.gd` exports (Item, Chest Id, etc.)

### 2. Instance the item toast

- Right-click `TestRoom` > **Instantiate Child Scene**
- Navigate to `res://scenes/ui/item_toast.tscn` > Open
- An `ItemToast` node appears in the Scene dock

*No positioning needed — it's a CanvasLayer, which renders in screen space (2D overlay), not in 3D world space. Its position in the node tree doesn't affect where it appears on screen.*

**Verification:** You should see `ItemToast` in the Scene dock as a child of TestRoom. You won't see anything new in the 3D viewport (CanvasLayers only appear in 2D view or at runtime).

### 3. Instance the quest indicator

- Right-click `TestRoom` > **Instantiate Child Scene**
- Navigate to `res://scenes/ui/quest_indicator.tscn` > Open
- A `QuestIndicator` node appears in the Scene dock

*Same as item toast — no positioning needed. CanvasLayer handles its own screen-space layout.*

### 4. Configure NPC quest_resource export

This is a new export property added to `npc_interactable.gd`. The NPC needs a reference to the quest resource so the dialogue can call `start_quest(quest_resource)`.

- Find the NPC instance in the Scene dock. It's likely named `NPC` or `Npc` — it's the child of TestRoom that uses `npc_interactable.gd`.
- **Select the NPC instance** by clicking on it in the Scene dock
- In the Inspector, you should now see a new export property that wasn't there before: **Quest Resource** (empty/null)
  - *If you don't see it:* The editor may be caching the old version of the script. Try: close and reopen the scene, or restart the editor. The new export was added in the latest commit.
- Click the **Quest Resource** slot > **Load** > navigate to `res://resources/quests/fetch_quest.tres` > Open
  - *What this does:* When the player talks to the NPC and chooses "I'll help you", the dialogue file calls `do start_quest(quest_resource)`. Dialogue Manager resolves `quest_resource` by finding this property on the NPC (which is passed as one of the `extra_game_states`). Without this assignment, `quest_resource` resolves to `null` and `start_quest` receives `null`, causing an error.
  - **Consequence of not setting this:** Accepting the quest in dialogue will silently fail — `start_quest(null)` does nothing (the quest_id would be empty), and the quest never starts. The quest indicator never appears.

**Verification:** Click the loaded resource in the Inspector to expand it. Confirm you see `quest_id = "fetch_amulet"`, `display_name = "The Old Amulet"`, and two steps.

### 5. (Optional) Add QuestTracker child to player if missing

Check if the Player instance already has a `QuestTracker` child node:

- Expand the Player instance in the Scene dock (click the arrow to reveal children)
- Look for a node named `QuestTracker`
- **If it's already there** (it should be from Phase 1 — it was added to `player.tscn`): you're done with this step
- **If it's NOT there:** Open `scenes/player/player.tscn` and add it:
  - Right-click the `Player` root > **Add Child Node** > search `Node` > Create
  - Rename to `QuestTracker`
  - Attach script: `res://scripts/quest/quest_tracker.gd`
  - Save `player.tscn`
  - *Why:* The `player_controller.gd` script calls `$QuestTracker as QuestTracker`. If this node doesn't exist, the cast returns null, and `player.get_quest_tracker()` returns null. All quest-related dialogue calls will fail silently.

### 6. Save test_room.tscn

- **Ctrl+S** (or Scene > Save Scene)

### 7. Set the dialogue resource on NPC (if not already set)

This should already be done from Phase 1, but verify:

- Select the NPC instance
- Inspector > **Dialogue Resource:** should show `npc_greeting.dialogue`
  - *If empty:* Load `res://resources/dialogue/npc_greeting.dialogue`
- **Dialogue Title:** should be `start`
- **Npc Id:** should be `nathan`

---

## Testing the Complete Loop

After building all scenes and saving, run the game (F5 or Play):

### Expected behavior, step by step

1. **Walk around.** WASD moves the player. Confirm movement works as before.

2. **Walk near the chest.** The "Press E" interaction prompt should appear at the bottom of the screen.
   - *If it doesn't appear:* Check the chest's collision layer (must be bit 4). Also check the player's InteractionArea mask includes bit 4.

3. **Walk away from the chest.** The prompt should disappear.

4. **Walk near the NPC first (before opening chest).** Press E. The dialogue should show:
   > "Welcome, traveler! I've been waiting for someone brave enough to help."
   > "There's an old amulet in that chest. Could you bring it to me?"
   > - I'll help you.
   > - Not right now.

5. **Choose "I'll help you."** The dialogue should respond:
   > "Wonderful! The chest is right over there."
   - The **quest indicator** should appear at the top-right showing the quest name and "Find the amulet in the chest"
   - *If the quest indicator doesn't appear:* Check that `quest_resource` is set on the NPC. Check the Output panel for errors mentioning `start_quest` or `null`.

6. **Walk to the chest.** Press E.
   - The **item toast** should appear at the bottom: "Acquired: quest_amulet"
   - The toast should fade in, display for ~2 seconds, then fade out
   - *If no toast:* Check the Output panel. The toast connects via player group — make sure the player is in the `"player"` group (set in `player_controller.gd` `_ready()`).

7. **Press E on the chest again.** Nothing should happen (chest is already opened).

8. **Walk back to the NPC.** Press E. The dialogue should now show:
   > "You found it! Wonderful!"
   - Then it should call `advance_quest("fetch_amulet")` and `remove_item("quest_amulet")` automatically
   - The dialogue continues: "I can't thank you enough. This amulet means everything to me."
   - The **quest indicator** should update and then show "Complete!"
   - *If the NPC still shows the "Have you found the amulet yet?" dialogue:* The `has_item` check isn't resolving. Verify the Inventory node exists as a child of Player and has the `inventory.gd` script attached.

9. **Talk to the NPC again.** Should show:
   > "Thank you for the amulet! You're a true hero."
   - This confirms `is_quest_complete("fetch_amulet")` resolves correctly.

### Common issues and solutions

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| No "Press E" near chest | Chest not on collision layer 4, or player InteractionArea mask doesn't include layer 4 | Check collision settings on both |
| Toast never appears | ItemToast not instanced in test_room, or player not in "player" group | Instance the scene; check player groups |
| Quest indicator never shows | NPC `quest_resource` not set, or QuestTracker missing from player | Set the export; add QuestTracker node to player.tscn |
| Dialogue error mentioning `start_quest` or `null` | `quest_resource` export on NPC is empty | Load `fetch_quest.tres` in Inspector |
| Dialogue error mentioning `is_quest_active` or method not found | QuestTracker not passed as extra_game_state | Verify `npc_interactable.gd` has `[quest_tracker, inventory, self]` (this is in the committed code) |
| Quest doesn't advance when turning in amulet | `advance_quest` or `remove_item` dialogue mutation not executing | Check Output panel for errors; verify dialogue file has correct `do` syntax |
| "Press E" still shows on opened chest | Expected — the interaction prompt doesn't know if the chest is opened. The prompt shows for any interactable in range. The chest's `interact()` method silently returns if already opened. This is fine for the prototype. |

---

## What Was Actually Done

All scenes built and tested. Two issues discovered and fixed during testing.

### Chest Scene
- [x] Built as instructed
- Collision layer 4, BoxShape3D 0.8^3, item = key_item.tres, chest_id = "chest_amulet", saveable group

### Item Toast Scene
- [x] Built as instructed
- CanvasLayer layer 10, PanelContainer > Label, bottom-center anchored

### Quest Indicator Scene
- [x] Built as instructed
- CanvasLayer layer 10, PanelContainer > VBoxContainer > QuestNameLabel + StepLabel, top-right anchored

### Test Room Updates
- [x] Chest instanced and positioned
- [x] ItemToast instanced
- [x] QuestIndicator instanced
- [x] NPC quest_resource = fetch_quest.tres
- [x] QuestTracker verified on Player (added to player.tscn)

### Testing Results
- [x] Movement works
- [x] Chest interaction works (prompt + pickup + toast)
- [x] Quest offer dialogue works
- [x] Quest indicator appears
- [x] Quest turn-in dialogue works
- [x] Quest completes successfully
- [x] Post-completion dialogue works

### Issues Encountered and Resolved

#### Quest not completing after turning in amulet

- **Symptom:** NPC said "You found it! Wonderful!" but quest indicator never showed "Complete!" and talking to NPC again produced "Have you found the amulet yet?"
- **Cause:** The fetch quest has two steps (get_amulet → return_amulet → complete). The dialogue only called `advance_quest("fetch_amulet")` once, moving from get_amulet to return_amulet but never reaching completion. On the next conversation, `is_quest_active` was true but `has_item` was false (item was removed), so the else branch fired.
- **Fix:** Added a second `do advance_quest("fetch_amulet")` call in the turn-in dialogue. First advance finishes get_amulet → return_amulet, second finishes return_amulet → complete.

#### Quest indicator showing snake_case quest ID

- **Symptom:** Quest indicator showed "fetch_amulet" instead of "The Old Amulet"
- **Cause:** `quest_indicator.gd` set `_quest_name_label.text = quest_id` (the raw string ID) instead of the human-readable display name from QuestData.
- **Fix:** Added `get_display_name(quest_id)` method to QuestTracker that looks up `quest_data.display_name`. Updated quest_indicator.gd to call it.
