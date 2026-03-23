# RPG UI/UX Best Practices Research

Comprehensive research on UI/UX design for 2D pixel-art and stylized RPGs, drawing from analysis of successful titles (Cassette Beasts, Octopath Traveler, Persona 5, Final Fantasy, Undertale/Deltarune, Sea of Stars) and current 2024-2026 industry trends.

---

## 1. Menu Systems

### The Flat vs. Nested Debate

The core tension in RPG menu design is between **flat layouts** (all options visible at once) and **nested hierarchies** (options organized into submenus). Research consistently shows that each additional nesting level compounds navigation failure rates exponentially.

**Best practice: Tab-based flat structure with max 2 levels of depth.**

| Approach | Strengths | Weaknesses | Example |
|----------|-----------|------------|---------|
| Flat tabs | Fast scanning, low click count | Can overwhelm with too many tabs | Skyrim (inventory/quests/skills as tabs) |
| Nested tree | Organized, scalable to many features | Hides options, slow navigation | Hogwarts Legacy (widely criticized as clunky) |
| Hybrid (tabs + one sublevel) | Best of both; organized but shallow | Requires careful information architecture | Persona 5, Sea of Stars |

**Specific patterns that work in RPGs:**

- **Top-level tabs for major categories** (Items, Equipment, Party, Quests, Settings) with content panels that change without full screen transitions
- **L/R bumper or Tab key to switch categories** -- this is now a universal convention in JRPGs and players expect it
- **Radial/quick menus for combat** -- Skyrim's favorites wheel, FF7R's ATB command menu. These reduce menu time during action sequences
- **Cursor memory** -- menus should remember the last selected item/tab when reopened. Forcing players back to the top of a menu every time is a common indie mistake

### Inventory Design

Inventory is the most-used menu in any RPG. Key findings:

- **Grid layout with icons** outperforms pure text lists for item recognition speed. Cassette Beasts uses a list-based sticker inventory and players found it cumbersome enough that a "Deluxe Inventory" mod with sorting became one of the most popular mods
- **Sorting and filtering are not optional.** At minimum: sort by name, type/category, rarity, recency. Cassette Beasts lacked sorting at launch and received consistent complaints
- **Item tooltips should appear on hover/selection**, not require a separate button press. Show name, description, stats, and equippable-by information in a detail panel
- **Stack counts must be immediately visible** on the icon itself, not hidden in a tooltip
- **New item indicators** (dot, glow, "NEW" badge) prevent players from losing track of recent acquisitions. Octopath Traveler was criticized for lacking this

### Equipment Screens

- **Show stat deltas** (green +2 / red -1 arrows) when comparing equipment. This is table stakes -- every successful RPG does this
- **Octopath Traveler's equipment screen was specifically criticized** for hiding weapon-specific attack values behind hover states, requiring extra clicks to understand actual damage output
- **Show the equipped item alongside the candidate item** side by side, not in sequence
- **Preview the character's appearance** when equipment changes visuals (applies more to 3D, but pixel art games like Sea of Stars show updated sprites)

### Party Management

- **Character cards with portrait, level, HP/MP bar, and role indicator** arranged in a vertical or horizontal list
- **Drag-to-reorder or simple swap buttons** for party order. Do not make party reordering require navigating through submenus
- **Active vs. reserve party** should be visually distinct (full opacity vs. dimmed, or separate columns)

### Settings Menu

- **Tab structure**: Controls, Audio, Video, Accessibility, Gameplay
- **Live preview** for visual settings (brightness, resolution) before committing
- **Reset to defaults** button per category, not just globally
- **Show current keybindings inline** with each action description, not in a separate reference screen

---

## 2. HUD Design

### The Minimal-But-Informative Principle

Modern RPG HUD design follows the rule: **show only what the player needs right now, hide everything else.**

**Core HUD elements for a 2D RPG (always visible during exploration):**

| Element | Placement Convention | Notes |
|---------|---------------------|-------|
| Health bar | Top-left or bottom-left | Red fill is universal. Show numerical value optionally |
| Mana/resource bar | Below health bar | Blue/purple fill convention |
| Minimap | Top-right corner | Optional -- many pixel art RPGs skip this in favor of a full map screen |
| Currency | Near minimap or bottom-right | Only show when relevant (shops, loot) |
| Quest indicator | Subtle, edge of screen | Arrow or marker pointing toward objective |

**What to hide or show contextually:**

- **Interaction prompts** ("E to interact") -- show only when near an interactable object. Undertale and Deltarune do not show interaction prompts at all; the player just presses a button when facing something. This works for simple interaction models but fails when there are multiple interactable objects nearby
- **Item pickup toasts** -- brief notification that fades after 2-3 seconds. Sea of Stars and Cassette Beasts both use this pattern
- **Combat HUD** -- only visible during battle. This is a separate HUD layer, not the exploration HUD
- **Status effects** -- icon row near health bar, visible only when active

### Dialogue Boxes

Dialogue UI is where players spend a huge amount of time in RPGs. Findings from analyzing multiple titles:

- **Bottom-of-screen text box** is the dominant convention (Undertale, Deltarune, Cassette Beasts, Sea of Stars, classic Final Fantasy). Top-of-screen boxes are less common and can obscure navigation
- **Character portrait** (or name plate) on the left side of the dialogue box. Expressions should change to match dialogue tone when possible
- **Typewriter text reveal** at an adjustable speed is now expected. Players should be able to press a button to instantly reveal the full line, then press again to advance
- **Choice responses** should be clearly selectable with visual highlight on the focused option. Octopath Traveler's yes/no prompts were praised for requiring deliberate selection rather than having a default, preventing accidental choices
- **Dialogue box opacity/style**: semi-transparent dark background with white text is the safest default, but the box style should match the game's overall UI theme

### Battle HUD

From analyzing Final Fantasy, Persona 5, Sea of Stars, and Cassette Beasts:

- **Party status panel**: compact HP/MP bars with character name/icon, typically on the right or bottom of screen
- **Enemy information**: HP bar (visible or hidden by design choice), weakness icons (Sea of Stars shows these above enemies), turn order indicator
- **Action menu**: typically bottom-left or bottom-center. Categories: Attack, Skills/Magic, Items, Defend/Guard, Flee. Persona 5 maps these to face buttons for speed
- **Turn order timeline**: increasingly common in modern JRPGs (Octopath, Sea of Stars). Shows upcoming turns as character icons in a horizontal strip, usually at the top of screen
- **Damage numbers**: float up from the target. Color-coded: white for normal, yellow/orange for critical, green for healing, blue for mana restoration

---

## 3. Typography and Readability

### Font Selection for Pixel Art Games

The font decision is one of the highest-impact UI choices in a pixel art RPG.

**Two viable strategies:**

1. **Pixel font throughout** -- maintains aesthetic consistency. Works best when the game commits fully to a retro look (Undertale, Deltarune). Risk: readability suffers at small sizes and on high-DPI screens
2. **Pixel font for headers, clean sans-serif for body text** -- the pragmatic choice for games targeting modern players. Sea of Stars and Cassette Beasts take this approach. Headers and labels use a stylized font; dialogue and descriptions use a highly readable font

**Key typography rules:**

- **Minimum body text size: 24px at 1080p** (equivalent to roughly 16pt). The Game Accessibility Guidelines recommend an easily readable default font size, and 24px at 1080p is the floor for comfortable reading at TV distance
- **High contrast is non-negotiable.** Dark text on light background or light text on dark background. Avoid colored text on colored backgrounds. WCAG 2.1 AA standard requires 4.5:1 contrast ratio for normal text and 3:1 for large text
- **Letter spacing matters more in pixel fonts** than in regular fonts. Characters must be distinct and not blend together. Test with difficult pairs: rn vs m, I vs l vs 1, O vs 0
- **Line height**: 1.4x-1.6x the font size for dialogue text. Tighter spacing (1.2x) is acceptable for stat labels and compact UI elements
- **Avoid ornate/decorative fonts for anything the player reads frequently.** Reserve fancy fonts for title screens and section headers only
- **Font hinting**: if using a pixel font, ensure it aligns to the pixel grid at your target resolution. Sub-pixel rendering on a pixel font looks blurry and defeats the purpose

**Specific font recommendations for pixel art RPGs:**

- **Body/dialogue**: m5x7, m3x6, Pixel Operator, Silver (all free, designed for readability at small pixel sizes)
- **Headers/labels**: Press Start 2P, VCR OSD Mono, or a custom pixel font that matches the game's personality
- **Fallback strategy**: ship a scalable (vector) version of each font for accessibility scaling, even if the default rendering is pixel-aligned

### Text Rendering in Godot

- Godot 4's default font rendering handles both bitmap and TTF/OTF fonts well
- For pixel-perfect text: use a bitmap font with `texture_filter` set to `Nearest` on the Label/RichTextLabel node
- For scalable text: use TTF/OTF with MSDF rendering enabled for clean scaling at any size
- RichTextLabel supports BBCode for inline formatting (bold, color, size changes), which is useful for highlighting keywords in item descriptions and dialogue

---

## 4. Color Palettes for UI

### Making UI Feel Cohesive With the Game World

The most common indie RPG mistake with color is treating UI as separate from the game world's palette. Research from multiple design analyses points to consistent principles:

**Strategy 1: Derive UI colors from the game's environment palette**

Pick 2-3 colors from the game's world art and use them as the foundation for UI elements. This is what Sea of Stars does -- its menu backgrounds use muted versions of the environment's blue-purple palette, making menus feel like a natural extension of the world rather than a separate system.

**Strategy 2: Monochromatic with one accent color**

Persona 5's approach: the entire UI is built around red, black, and white. The monochromatic base creates visual hierarchy through contrast (white text on black, black text on red panels), while the single accent color (red) carries thematic meaning (rebellion, passion). This works because the limited palette forces the designers to create hierarchy through size, weight, and position rather than relying on many different colors.

**Strategy 3: Warm earth tones for fantasy RPGs**

For a Cassette Beasts-style game with a colorful world: use warm, desaturated tones for UI chrome (panel borders, backgrounds) and reserve saturated colors for functional elements (health red, mana blue, elemental type colors).

### Functional Color Coding

Certain color associations are so deeply ingrained in RPG players that violating them causes confusion:

| Function | Expected Color | Notes |
|----------|---------------|-------|
| Health/HP | Red | Universal. Do not use red for mana |
| Mana/MP/SP | Blue or purple | |
| Healing | Green | Both in damage numbers and item icons |
| Poison/status ailment | Purple/green | Purple for magical debuffs, green for poison specifically |
| Critical hit | Yellow/orange | |
| Physical damage | White | |
| XP/progression | Gold/yellow | |
| Rarity: common | White or gray | |
| Rarity: uncommon | Green | |
| Rarity: rare | Blue | |
| Rarity: epic/legendary | Purple / orange | |
| Stat increase (equip comparison) | Green text/arrow | |
| Stat decrease (equip comparison) | Red text/arrow | |

**Critical rule**: Never convey information by color alone. Always pair color with a second indicator: icon shape, text label, pattern, or position. This is both an accessibility requirement and a general clarity improvement.

### Background Colors and Mood

Research from the game UI color analysis shows that background color affects perception:

- **Dark/black backgrounds** convey danger, seriousness, or sophistication. Classic FF blue-black menus established this convention for JRPGs
- **White/light backgrounds** feel clean and modern but can cause eye strain in long sessions
- **Semi-transparent dark overlays** (the most common RPG choice) maintain awareness of the game world while providing readable contrast for text. Opacity of 70-85% is the sweet spot -- transparent enough to see the world, opaque enough for text readability

---

## 5. Accessibility

### The Non-Negotiable Three (Baseline)

Every RPG should ship with these three accessibility features. They are low-effort to implement and eliminate the largest accessibility barriers:

1. **Subtitles for all dialogue** -- with adjustable size and optional speaker name coloring
2. **Remappable controls** -- all input actions should be rebindable. Show the current binding on-screen in button prompts (not hardcoded "Press E" but dynamic glyphs that update when rebinding)
3. **High contrast mode** -- a toggle that increases text contrast, adds outlines to UI elements, and ensures no information is conveyed by color alone

### Visual Accessibility

**Colorblind modes:**

- Do not simply apply a color filter over the entire game. This is the lazy approach and makes the game look worse for everyone
- Instead, **use icon shapes alongside colors** for all functional color coding. Cassette Beasts' type icons are a good example -- each element type has a distinct icon shape, so even without color the types are distinguishable. The redesign analysis noted that status ailment icons needed improvement because they relied too heavily on color
- **Offer palette swaps** for the most critical color pairs: red/green (deuteranopia/protanopia, ~8% of males), blue/yellow (tritanopia, ~0.01% of population), and full achromacy
- **Test with a colorblind simulator** like Color Oracle before shipping

**Font scaling:**

- Allow text size to be adjusted from 80% to 200% of default
- UI layout must respond to font scaling without breaking. This means using Godot's container-based layout system, not absolute positioning
- The Game Accessibility Guidelines specify: "Use an easily readable default font size" as a basic requirement, and "Allow the font size to be adjusted" as an advanced requirement

**Contrast:**

- WCAG 2.1 AA: 4.5:1 contrast ratio for normal text, 3:1 for large text (18pt+) and UI components
- Provide at least two contrast options: default and high contrast
- Test against both light and dark backgrounds that appear in your game

### Motor Accessibility

- **Button hold vs. button tap**: any action requiring holding a button should have a toggle alternative
- **Menu navigation speed**: cursor repeat speed in menus should be adjustable. Octopath Traveler was specifically criticized for "horrendously slow" cursor repeat speed in inventory
- **One-button confirm/cancel**: do not require multi-button combinations for basic menu navigation
- Sea of Stars was criticized for requiring "holding down three different buttons" for traversal actions -- avoid this pattern

### Cognitive Accessibility

- **Tutorial/help catalogue** accessible from the pause menu. Sea of Stars does this well with categorized "How to Play" entries covering Traversal, Combat, and Survival
- **Quest log with clear current objectives** -- not just a journal of past events, but explicit next-step guidance
- **Visual indicators for interactable objects** -- subtle but present. A small icon, particle effect, or highlight that distinguishes interactable objects from background decoration
- **Adjustable text speed** in dialogue -- some players read faster, some slower
- **Auto-advance option** for dialogue (with adjustable pause duration)

---

## 6. Case Study Breakdown: What Each Game Gets Right

### Persona 5 -- Style as Function

- **What works**: The UI is the game's identity. Red/black/white palette with sharp angular shapes creates immediate recognition. Every menu transition is animated with character poses, making menu navigation feel like gameplay rather than administrative overhead
- **Design secret**: The team used "line of sight" -- white lines drawn at the center of menu screens to guide the player's gaze. Changes in angle and contrast provide context without relying on color coding
- **Key lesson for indie devs**: You do not need Persona 5's animation budget. The takeaway is **commit to a visual motif** (angles, curves, a specific shape language) and apply it consistently across all UI elements. Even simple geometric consistency elevates a UI from generic to memorable
- **Caution**: Persona 5's style-over-function approach was deliberate marketing strategy driven by low predecessor sales. The style works because it was designed to grab attention. A half-hearted imitation looks worse than a clean, simple UI

### Octopath Traveler -- Restraint and Its Costs

- **What works**: "Minimal but with a heart" -- clean panels, limited color palette, decluttered screens. The job selection screen (circular menu) shows that even a restrained UI can have moments of visual flair
- **What fails**: Text readability on transparent backgrounds was poor. Stat comparisons were "impossible to read with certainty" in shops. Enemy selection in battle "does not follow normal grid navigation." The overall assessment: "boring" rather than broken -- white text on semi-transparent black panels prioritized reusability over design excellence
- **Key lesson**: Minimalism requires more design effort, not less. Every element must earn its place, and the remaining elements must be impeccably readable. Cutting visual ornamentation without increasing clarity creates a dull UI, not an elegant one

### Undertale/Deltarune -- Maximizing Constraint

- **What works**: The battle UI (FIGHT, ACT, ITEM, MERCY) is instantly iconic with just four buttons. Dialogue boxes are simple white-on-black with character personality conveyed through font choices, text speed variations, and box shaking/movement. The UI does more with less than almost any other RPG
- **Key lesson**: Personality can come from behavior, not just appearance. Undertale's dialogue boxes shake, resize, and change fonts to convey emotion. The menu is functionally identical to any other RPG's, but the animations and text effects make it feel unique. This is achievable on any budget

### Sea of Stars -- Modern Retro Done Right

- **What works**: Clean combat UI with weakness icons above enemies. Tab-based pause menu with How-to-Play catalogue. Brightness slider. Relics system as accessibility modifiers (difficulty aids integrated into game fiction)
- **What fails**: No mouse support on PC. Keyboard navigation was unclear in early versions. Traversal required awkward multi-button holds
- **Key lesson**: Integrating accessibility into game fiction (relics that help with timing, etc.) is elegant because it removes the stigma of "easy mode" while providing genuine accessibility value

### Cassette Beasts -- Lessons From Player Friction

- **What works**: The visual style (cassette-dot pattern, marker font for branding) creates a cohesive identity. Type icons use distinct shapes alongside colors. The overall aesthetic matches the game's 80s/90s cassette culture theme
- **What fails**: Inventory lacked sorting (fixed by community mod). Sticker management was tedious. The UI redesign analysis noted that status ailment icons relied too heavily on color differentiation
- **Key lesson**: Launch with sorting and filtering. It is tempting to defer these features, but players interact with inventory hundreds of times per playthrough. Small friction compounds into major frustration. Also: icon design must be shape-distinct, not just color-distinct

### Final Fantasy (Classic) -- The Template

- **The blue menu**: FF's dark blue gradient menu with white text and cursor-based navigation established the JRPG menu paradigm that persists today. It works because: high contrast (white on dark blue), consistent layout across all menus, clear cursor indication, sound feedback on navigation
- **ATB evolution**: The visible ATB gauge (introduced in FFV) taught players that clear presentation of timing information bolsters the experience. Modern implementations (FF7 Rebirth) blend real-time action with strategic slow-motion menu commands
- **Key lesson**: The classic FF menu template is a proven baseline. For an indie RPG, starting with this template and adding personality through color, shape, and animation is a lower-risk approach than inventing a novel UI paradigm

---

## 7. Current Trends (2024-2026)

### What Players and Designers Are Praising

1. **Diegetic UI elements** -- UI that exists within the game world (a journal the character physically holds, a map on a table) rather than floating HUD elements. This trend works best for immersive sims and action RPGs but can inspire contextual touches in traditional RPGs (e.g., the save point being a physical object in the world)

2. **Progressive disclosure in HUDs** -- showing information only when relevant. Ammo count appears when aiming, health bar fades in only when damaged, quest markers appear only near objectives. Celeste popularized this for platformers; RPGs are adopting it for exploration HUDs

3. **Dark mode by default** -- most new RPGs default to dark UI themes. Players spend hours in menus; bright white backgrounds cause eye strain. Dark backgrounds with light text are the expectation now

4. **Micro-animations on menu transitions** -- subtle slides, fades, and scale animations when switching tabs or opening panels. These take milliseconds to implement in Godot (Tween nodes) but make the UI feel responsive and polished. The absence of transition animations makes a UI feel like a placeholder

5. **Integrated accessibility options** -- not buried in a sub-sub-menu but prominently placed. Some games (The Last of Us Part II, Forza Horizon 5) show accessibility options during first-time setup. Indie games are following suit

6. **Resource/tool consolidation in UI** -- Lospec.com for palette discovery, Game UI Database (55,000+ screenshots across 1,300+ games, v2.0 released January 2025) for reference, itch.io asset packs for prototyping

### Common Indie RPG UI Mistakes (Avoid These)

1. **Over-designing before gameplay works.** Building elaborate menus for a game whose core loop is not yet fun. Build an MVP UI Kit first (Main Menu, HUD, Pause/Settings, Game Over), test the game with placeholder UI, then invest in polish

2. **Inconsistent button/panel styles across screens.** When button shapes, sizes, colors, or hover states change from one menu to another, the UI feels unfinished. Build a Godot Theme resource early and apply it globally

3. **Tiny text at 1080p.** Many indie devs work on large monitors at close range and choose font sizes that are unreadable on a TV or laptop. Test at actual viewing distance. 24px minimum at 1080p

4. **No keyboard/controller support in menus.** If the game supports controllers for gameplay, every menu must also be fully navigable with a controller. Focus states on all interactive elements are required

5. **Laggy menu transitions.** Menus should open/close in under 200ms. Animations longer than that feel sluggish. Persona 5's animated transitions work because they are fast (under 300ms) despite being visually elaborate

6. **Missing cursor memory.** Reopening a menu should return to the last selected item, not reset to the top. This is especially painful in inventory screens

7. **No confirmation on destructive actions.** Selling items, discarding equipment, or overwriting saves must require explicit confirmation. Octopath Traveler's deliberate yes/no prompt design was praised specifically for this

8. **Color-only information encoding.** Using only red/green to indicate stat changes, or only color to distinguish item rarity tiers, without shape/text backup

---

## 8. Godot 4 Implementation Notes

These are Godot-specific notes relevant to implementing the patterns above, consistent with the project's existing architecture (HUD autoload, CanvasLayer-based UI).

### Theme System

- **Create a master Theme resource** (`res://resources/themes/main_theme.tres`) and set it as the Project Default Theme in Project Settings. This ensures all Control nodes inherit consistent styling unless overridden
- Define StyleBoxes for Panel, Button (normal/hover/pressed/disabled/focus), and Label. Use the theme for fonts, font sizes, colors, and margins
- Theme overrides on individual nodes should be rare -- they are a maintenance burden. If you find yourself overriding the same property on many nodes, update the theme instead

### Layout

- **Use Container nodes** (VBoxContainer, HBoxContainer, MarginContainer, GridContainer) for all menu layouts. Avoid absolute positioning -- it breaks at different aspect ratios and when font scaling is applied
- **Anchors and margins** on the root Control of each UI scene for screen-edge positioning (health bar anchored top-left, minimap anchored top-right)
- **size_flags_horizontal/vertical** on children within containers to control stretch behavior

### Animation

- **Tween** for menu open/close animations. A simple 150ms ease-out scale from 0.95 to 1.0 + alpha from 0 to 1 makes menus feel responsive without being slow
- **AnimationPlayer** for more complex multi-property animations (Persona 5-style character poses during menu transitions, if desired)

### Input Handling

- Per the project's existing convention: use `_input()` (not `_unhandled_input()`) for menu toggle actions that might overlap with focus navigation keys
- For menu navigation: Godot's built-in focus system (`focus_neighbor_*`, `focus_next`, `focus_previous`) handles D-pad/arrow key navigation automatically when set up correctly on Button/Container nodes
- **Controller glyph display**: detect the active input device and swap button prompt textures accordingly (keyboard icons vs. Xbox vs. PlayStation glyphs)

### Accessibility in Godot

- Font scaling: store a `ui_scale` setting and multiply all font sizes by it. Apply via theme overrides or by regenerating the theme at the new scale
- High contrast mode: swap the active Theme resource between `main_theme.tres` and `high_contrast_theme.tres`
- Colorblind mode: use a post-processing shader on a CanvasLayer above the game but below UI, or provide alternative icon sets that use patterns instead of colors

---

## 9. Recommended Reference Resources

| Resource | URL | Use For |
|----------|-----|---------|
| Game UI Database | https://gameuidatabase.com/ | Screenshots of 1,300+ games' UI by screen type, element, color |
| Lospec Palette List | https://lospec.com/palette-list | Pixel art color palettes with community ratings |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com/full-list/ | Comprehensive checklist organized by disability type and difficulty |
| Persona 5 UI Analysis (Ridwan Khan) | https://ridwankhan.com/the-ui-and-ux-of-persona-5-183180eb7cce | Deep dive into P5's design decisions |
| Persona 5 UI Development Panel | https://personacentral.com/persona-5-panel-concept-development-ui/ | Atlus designers explain their process |
| Octopath Traveler UI/UX Review | https://www.ramblingaboutgames.com/blog/octopath-uiux | Detailed critique with specific improvement suggestions |
| Cassette Beasts UI Redesign | https://medium.com/@davy_delbeke/redesigning-cassette-beasts-ui-a1c49452ea59 | UX designer's analysis of CB's interface problems |
| Colors in Game UI (Dakota Galayde) | https://www.galaydegames.com/blog/colors-i | Color psychology and palette analysis across multiple games |
| Indie Game UX Playbook (iABDI) | https://www.iabdi.com/designblog/2026/1/22/the-indie-game-ux-playbook-10-essential-questions-answered | 2026 guide for indie game UX decisions |
| NoahType Game Font Guide | https://noahtype.com/how-to-choose-fonts-for-game-screen-readability/ | Font selection methodology for games |

---

## 10. Summary: Priority Checklist for RootsGame

Ordered by impact-to-effort ratio, highest first:

1. **Create a Godot Theme resource** and apply it project-wide. Define Panel, Button, Label styles once. This prevents the inconsistency problem that plagues most indie RPGs
2. **Establish the tab-based menu structure early** -- Items, Equipment, Party, Quests, Settings as top-level tabs. Use L1/R1 (controller) or Tab/Shift+Tab (keyboard) to switch
3. **Pick two fonts**: one pixel/stylized font for headers and labels, one clean readable font for body text and dialogue. Test at 1080p on a TV-distance screen
4. **Derive UI colors from the game world palette.** Pick 2-3 colors from environment art as the base. Reserve saturated colors for functional coding (HP red, MP blue, etc.)
5. **Build inventory with sorting/filtering from day one.** Do not defer this -- it is the most-interacted-with menu and the most common source of player complaints in indie RPGs
6. **Implement the three accessibility essentials**: subtitles, remappable controls, high contrast mode. Add font scaling as a fast follow
7. **Add micro-animations to menu transitions** (150-200ms Tweens). This single change makes the entire UI feel more polished
8. **Use shape + color for all functional indicators.** Never encode information in color alone. This serves both accessibility and general clarity
9. **Test with a colorblind simulator** (Color Oracle) before any public release
10. **Reference Game UI Database** when designing each new screen. Search by screen type (inventory, equipment, battle HUD) and study 3-5 examples before designing your own
