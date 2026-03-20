# Project Architecture Documentation Brainstorm

**Date:** 2026-03-20
**Status:** Complete — ready for `/gc:plan`

## What We're Building

A single comprehensive architecture document (`docs/PROJECT_ARCHITECTURE.md`) that captures the current state of the RootsGame project — every system, pattern, contract, and convention — plus projected patterns for future systems. Serves dual audience: human context recovery after breaks and AI agent orientation.

## Why This Approach

### Single Document over Multi-File

One file is easier to point Claude at, easier to Ctrl+F, and has a single maintenance burden. The project is still small enough (~19 custom scripts, 12 scenes, 3 resource types) that a single doc won't bloat. When the project grows significantly, sections can be split out.

### Systems-First Organization

Organized by system/subsystem rather than by architectural layer or gameplay flow. Each section answers "how does X work?" independently. This mirrors how both humans and AI agents typically query: "tell me about the save system" not "tell me about the persistence layer."

### Inline `[PROJECTED]` Markers

Future/planned patterns are tagged inline with `[PROJECTED]` rather than separated into subsections. This keeps projected patterns close to the current implementation they'll extend, making it easy to see where the system is headed without splitting the reader's attention.

### Rationale Included

The "why" behind architectural choices is included because the project has made several non-obvious decisions (persistent player reparenting, WorldState as two-tier bridge, empty EventBus, `.gd`-only autoloads) that would puzzle a reader without context.

## Key Decisions

1. **Format:** Single `docs/PROJECT_ARCHITECTURE.md`
2. **Audience:** Both human (context recovery) and AI (session orientation)
3. **Organization:** Systems-first reference — one section per system
4. **Future patterns:** Inline `[PROJECTED]` tags
5. **Scope:** Current state + projected patterns + rationale for non-obvious choices
6. **Not duplicating CLAUDE.md:** Architecture doc describes *how things work*; CLAUDE.md prescribes *rules to follow*. Minimal overlap.

## Document Outline

### Top-Level Sections

1. **Project Overview** — What RootsGame is, tech stack, current milestone status
2. **Directory Structure** — Annotated tree showing where things live
3. **Autoload Architecture** — All 7 autoloads, load order, responsibilities, interdependencies
4. **Entity System** — Player composition, interactable pattern, duck-typing contracts
5. **State Machine** — Reusable StateMachine/State framework, player states
6. **Dialogue System** — Dialogue Manager integration, extra_game_states bridge, `.dialogue` file patterns
7. **Quest System** — QuestData/QuestStepData resources, QuestTracker lifecycle, dialogue-driven logic
8. **Inventory System** — ItemData resources, flat dictionary storage, save contract
9. **World & Scene Management** — Room structure, SceneManager transitions, persistent player, spawn points
10. **World State & Persistence** — Two-tier state (WorldState session + SaveManager disk), registrar pattern, save format, load sequence
11. **UI System** — HUD autoload, `connect_to_player()` pattern, pause menu lifecycle
12. **Signal Architecture** — "Call down, signal up" map, EventBus policy, group-based dispatch
13. **Game Modes** — GameState enum, mode transitions, input gating
14. **Physics Layers** — Layer assignments and mask configurations
15. **Resource Patterns** — Two-layer pattern (Resource for data, Node for behavior), custom resource types
16. **Testing** — GUT framework, unit vs integration test patterns, what's covered
17. **Projected Systems Summary** — Consolidated view of all `[PROJECTED]` patterns (mirrors inline markers for quick scanning): combat/battle, navigation, art migration, audio, plus incremental extensions to existing systems

### Per-Section Template

Each section follows:
- **What it does** (1-2 sentences)
- **Key files** (paths to scripts, scenes, resources)
- **How it works** (implementation details, contracts, data flow)
- **Why this way** (rationale for non-obvious choices, only when relevant)
- **`[PROJECTED]`** (inline markers for planned extensions)

## What This Is NOT

- **Not a replacement for CLAUDE.md** — CLAUDE.md stays as the prescriptive rules file. Architecture doc is descriptive.
- **Not a plan** — No implementation steps or phase ordering. Use existing plan docs for that.
- **Not ADRs** — Architecture Decision Records go in `docs/decisions/`. This doc references rationale inline but doesn't use ADR format.
- **Not a tutorial** — Assumes reader familiarity with Godot 4 and GDScript basics.
