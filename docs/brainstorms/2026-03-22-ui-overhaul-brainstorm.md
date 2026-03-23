# UI Overhaul Brainstorm

**Date:** 2026-03-22
**Status:** Draft
**Scope:** Full UI overhaul — core menus, HUD & overlays, dialogue system

## What We're Building

A complete UI overhaul for RootsGame, establishing a cohesive visual identity and reskinnable design system. The UI should feel **clean and modern** (Cassette Beasts / Sea of Stars tier), with **polished transitions** and **keyboard+mouse-first** input.

### Scope Includes

- **Project-wide Theme resource** — single source of truth for colors, fonts, margins, StyleBoxes
- **Core menus** — game menu tabs (inventory, quests, stats, pause), settings/options, confirmation dialogs
- **HUD & overlays** — health/status bars, quest tracker, item toasts
- **Dialogue system** — custom balloon with portraits, styled panels, animated text, expression support
- **Transition animations** — slide-ins, fades, micro-animations on every state change

### Scope Excludes

- Battle UI (deferred until battle system is built)
- Gamepad support (keyboard+mouse first; gamepad can be added later)

### Gamepad-Proofing Rules (enforce now to avoid painful retrofit)

Research identifies these as critical for future gamepad support. Follow during implementation even though gamepad is out of scope:

1. **Always use input actions** — never raw key codes (project already does this)
2. **Always set focus neighbors** on every interactive Control node
3. **Build a ButtonPrompt component** that maps input actions to display glyphs
4. **Avoid hover-only interactions** — anything reachable by hover must be reachable by focus/selection
5. **No drag-and-drop** — use select-then-action patterns for inventory
6. **Test keyboard-only navigation** regularly — if keyboard-only works, gamepad is ~80% done

## Why This Approach

**Approach chosen: Theme-First Foundation**

Build the Theme resource and design system first, then restyle every existing screen, then add missing screens.

**Rationale:**
- The game's art direction isn't locked yet — a flexible Theme system lets the visual identity evolve without reworking screen layouts
- Research shows scattered `theme_override_*` properties and inline sub_resources (current state) become unmaintainable as UI grows
- Every new screen automatically inherits the style, reducing per-screen design decisions
- Godot's Theme cascade (like CSS) means one change propagates everywhere
- This is the #1 recommendation from both the Godot community and indie RPG UI research

**Implementation order:**
1. Theme resource (colors, fonts, StyleBoxes, type variations)
2. Restyle existing menus (game menu tabs, dialogue balloon)
3. Custom dialogue balloon with portrait support
4. HUD redesign (health, status, quest tracker)
5. New screens (settings menu, confirmation dialogs, stats tab)
6. Transition/animation polish pass

**Alternatives considered:**
- *Screen-by-screen overhaul:* Faster visible progress but risks inconsistency and rework when extracting shared patterns
- *Parallel tracks:* Good separation of concerns but integration risk when merging style and layout

## Key Decisions (quick reference)

| Decision | Choice | Details in |
|----------|--------|------------|
| Visual mood | Clean & modern, Sea of Stars reference | Visual Style section |
| Color palette | Warm amber/earth, dark translucent panels | Color Palette table |
| Typography | Pixel headers + sans-serif body | Typography table |
| Panel design | Dark translucent + amber border | Panel Design table |
| Icons | Simple outlined line-art | Icons & Decoration table |
| Input priority | Keyboard + mouse first | — |
| Animation | Polished, variable timing per type | Animation Specifications table |
| Art flexibility | Reskinnable via single Theme resource | Design System Architecture |
| Dialogue | Portraits + custom styled balloon | Dialogue System table |
| Inventory | Card/tile items, context actions, sorting | Inventory Interactions section |
| HUD | Contextual/progressive disclosure, modular | HUD Behavior section |
| Quest tab | Expandable accordion, manual active tracking | Quest Tab section |
| Notifications | Top-right, slide-in, stacking, auto-dismiss | Notification System section |
| Settings | Audio + Display + Controls tabs | Settings Menu section |
| Confirmations | Centered modal for quit/load/save-overwrite | Confirmation Dialogs section |

### Design System Architecture

| Component | Approach |
|-----------|----------|
| Theme resource | Project-wide `.tres` in Project Settings for shared defaults. Sub-themes for distinct UI branches (dialogue, HUD, menus) that override only what they need |
| StyleBoxes | `StyleBoxFlat` for all panels (corner radius, borders, shadows). Swap to `StyleBoxTexture` with 9-slice if hand-drawn frames are needed later |
| Type variations | Named variants like `HeaderLabel`, `DimLabel`, `AccentButton` for contextual styles without per-node overrides |
| CanvasLayer convention | HUD: 100, Menus: 110, Modals: 120, Transitions: 200 (formalize existing ad-hoc layering) |

### Visual Style (Sea of Stars-inspired, warm earth palette)

**Reference:** Sea of Stars' clean dark panels with warm accents — adapted to an amber/earth direction.

#### Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Panel background | Dark warm brown | `#2a1f18` at ~75-80% opacity | All panel/frame backgrounds. Translucent, world visible |
| Panel border | Amber | `#c87533` | 1-2px thin border on panels. Defines edges warmly |
| Accent / highlight | Amber | `#c87533` | Selected items, active tabs, interactive element highlights |
| Primary text | Warm off-white | `#f0e6d6` | Main body text, item names, menu labels |
| Secondary text | Muted tan | `#a89880` | Descriptions, hints, inactive items, metadata |
| Header bar | Slightly lighter than panel | `#3a2a20` or accent-tinted | Integrated header bars across panel tops |
| Divider lines | Muted amber | ~`#5a4a38` | 1px horizontal separators between list items |
| HP (functional) | Brick red | warm-shifted red | Health bars, damage indicators |
| MP (functional) | Teal blue | warm-shifted blue | Mana/magic bars |
| Heal (functional) | Sage green | warm-shifted green | Healing effects, positive status |
| Warning (functional) | Orange | warm-shifted orange | Low HP, expiring buffs |

#### Typography

| Role | Style | Size (at 1080p) |
|------|-------|-----------------|
| Headers / titles | Pixel or stylized font | 24-28px |
| Body text | Clean sans-serif (Noto Sans, Inter, or similar) | 18-20px |
| Small / metadata | Same sans-serif | 14-16px (exception to minimum for non-critical text like timestamps, version numbers) |
| Minimum for readable content | — | 24px floor (body text, item names, menu labels) |

#### Panel Design

| Property | Value |
|----------|-------|
| Background | `StyleBoxFlat`, dark brown (#2a1f18), ~75-80% alpha |
| Border | 1-2px amber (#c87533) on all sides |
| Corner radius | Parameterized in Theme (TBD — experiment during implementation) |
| Header | Integrated bar, slightly lighter/accent-tinted across top |
| Dividers | 1px thin lines in muted amber between items/sections |
| Padding | Moderate (10-14px) |
| Drop shadow | 4-6px, black at 15-20% opacity. Improves readability over varied backgrounds. Parameterized in Theme |

#### Icons & Decoration

| Element | Style |
|---------|-------|
| Tab icons | Simple outlined/line-art in accent or text color |
| Action icons | Same outlined style, consistent weight |
| Status icons | Outlined, color-coded by function |
| Item rarity | Deferred until item/loot system defines rarity tiers |

#### Animation Specifications

| Animation Type | Duration | Easing | Details |
|---------------|----------|--------|---------|
| Menu open/close | 0.2s (snappy) | Ease-out (appear), Ease-in (disappear) | Slide from right + fade |
| Tab switching | 0.2s (snappy) | Ease-in-out | Crossfade or slide between tab contents |
| Scene transitions | 0.4s (smooth) | Ease-in-out | Fade to black, then fade in |
| Notifications | 0.3s (medium) | Ease-out (appear), Ease-in (disappear) | Slide in from right edge |
| Hover/focus effects | 0.1s | Ease-out | Subtle brighten, slight scale (1.02x) |
| Selection indicators | Continuous | — | Animated underline, pulsing border, or sliding highlight between items |
| Dialogue text | Variable | — | Typewriter reveal, skippable |

### Dialogue System

| Component | Approach |
|-----------|----------|
| Balloon | Custom scene replacing addon example. Own script, styled via project Theme |
| Portraits | Character portrait TextureRect alongside dialogue text. Supports expression swaps via dialogue commands |
| Text reveal | Typewriter effect with configurable speed. Skippable on input |
| Choices | Styled buttons with hover/focus effects matching Theme |
| Integration | Same Dialogue Manager backend. Custom balloon registered as the balloon scene |

### Screens to Build or Restyle

| Screen | Current State | Target |
|--------|--------------|--------|
| Game menu shell | Basic TabContainer, default theme | Styled tabs with icons, smooth tab transitions |
| Inventory tab | Read-only Label list | Card/tile-style items with icons, name, brief stats. Context action menu (actions TBD). Sorting support |
| Quest tab | Read-only Label list | Quest cards with status indicators, expandable details, active quest selection |
| Stats tab | "Coming Soon" placeholder | Character stats display (when stat system exists) |
| Pause tab | 4 plain buttons | Styled buttons, confirmation on Quit and Load |
| Settings menu | Does not exist | Audio (master/music/SFX), display (resolution/fullscreen/VSync), controls (rebinding or reference) |
| Dialogue balloon | Addon example template | Custom styled balloon with portrait support |
| Item toast | Minimal fade tween | Icon + name + quantity, stacking support, slide-in animation |
| Quest indicator | Basic labels | Styled overlay matching Theme |
| Health/status HUD | Does not exist | Modular HUD system. Elements appear contextually (on change) and fade. Specific elements TBD |

## Research References

- [rpg-ui-ux-best-practices.md](../research/rpg-ui-ux-best-practices.md) — Design patterns from Cassette Beasts, Persona 5, Octopath, Sea of Stars, Undertale, FF
- [rpg-ui-best-practices.md](../research/rpg-ui-best-practices.md) — Godot 4 implementation patterns for Themes, Controls, animation, focus

### Key Research Takeaways

- **Flat tab-based layouts** with max 2 levels of depth beat nested hierarchies (all reference games)
- **"Show only what the player needs now"** — progressive disclosure HUDs that hide elements when irrelevant
- **Sorting is non-negotiable** for inventory (Cassette Beasts launched without it and got criticized)
- **Font minimum 24px at 1080p** for readability. Two-tier font strategy (display + body) works well
- **Functional color coding** (HP red, MP blue, rarity tiers) represents player expectations that shouldn't be violated
- **`grab_focus.call_deferred()`** on menu open is the #1 Godot UI pitfall — every menu must do this
- **`.duplicate()` StyleBoxes** before runtime modification (Godot shares Resources by path)
- **ScrollContainer + VBoxContainer with instanced scenes** beats ItemList for RPG inventories
- **Modal dialogs need full-screen MOUSE_FILTER_STOP** to block input to lower layers

## Detailed Design Decisions

### Inventory Interactions

- **Display format:** Card/tile-style items as default view. Each tile shows icon, name, and brief stats visible without selecting. Research note: cards show ~12-15 items at 1080p, so provide a compact list toggle for players with large inventories (50+ items).
- **Item actions:** Design a context action menu system (select-then-action, not drag-and-drop) — this pattern works for both mouse and future gamepad support. Don't commit to specific actions yet.
- **Sorting & filtering:** Must be included from the start. Sort by type, name, recency. Category filters. (Research: Cassette Beasts was criticized for launching without sorting.)

### HUD Behavior

- **Visibility (exploration):** Contextual/progressive disclosure. HUD elements appear when relevant (HP bar when damaged, quest tracker when objective updates) and fade after ~5 seconds. Minimal screen clutter.
- **Visibility (combat):** Persistent. HP, MP, status effects always visible during battle. Research: hiding HP during combat impairs resource management decisions.
- **Settings toggle:** "Always show HP bar" option for players who prefer persistent visibility during exploration.
- **Architecture:** Modular — each HUD element is an independent scene that can be added/removed. Specific elements to include TBD during planning.
- **Design principle:** "Show only what the player needs now" (exploration). "Show everything the player needs to decide" (combat).

### Settings Menu

- **Categories:** Audio, Display, Controls (three tabs or sections)
- **Audio:** Master volume, music volume, SFX volume (sliders)
- **Display:** Resolution, fullscreen/windowed toggle, VSync toggle
- **Controls:** Key rebinding or at minimum a controls reference screen
- **Accessibility:** Not in initial scope but design the settings system to accommodate adding categories later

### Quest Tab

- **Display format:** Expandable accordion list. Single-column list where clicking a quest expands it inline to show objectives, details, quest giver, and rewards.
- **Status indicators:** Visual badges for quest state (active, completed, failed).
- **Active quest tracking:** Player manually selects which quest to track. Only the active quest shows objectives on the HUD quest indicator. A "Track" button or star icon in the expanded quest view. Tracked quest always appears at top, expanded by default.
- **Scaling guardrails:** Add category filters (Active / Completed / Failed) to reduce visible list. Add "Collapse All" button once 10+ quests exist. If the game grows to 20+ simultaneous active quests, plan migration to list + detail panel layout.

### Confirmation Dialogs

- **Actions requiring confirmation:** Quit game, load save (overwrites current progress), overwrite existing save slot.
- **Style:** Centered modal. Small panel centered on screen with question text + Confirm/Cancel buttons. Dim/darken the background behind the modal.
- **Input blocking:** Full-screen `MOUSE_FILTER_STOP` behind the modal for mouse. Also `grab_focus.call_deferred()` on first button + closed focus loop (focus neighbors) to prevent keyboard/gamepad from escaping the modal.

### Notification System

- **Types supported:** Item acquired, quest started/updated/completed, game saved. Core gameplay feedback notifications.
- **Position:** Top-right corner, stacking downward. Out of the way of gameplay and dialogue.
- **Behavior:** Slide in from right edge with fade. Auto-dismiss after ~3 seconds. Stack multiple notifications with slight vertical offset.
- **Architecture:** Single notification manager (likely on HUD) that accepts typed notification requests and manages the queue/stack.

## Open Questions

1. **Portrait format** — Bust portraits, head-only icons, or full character art? What size/aspect ratio? (Deferred — design balloon to accommodate flexible sizes)
2. **Stats system** — What stats will the game have? (Needed to design the stats tab, deferred until stat system is designed)
3. **Specific font files** — Which exact pixel font for headers? Which sans-serif for body? (Decide during Theme implementation with visual testing)
