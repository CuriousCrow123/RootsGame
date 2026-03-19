# Extended Findings: Godot RPG Fundamentals

Generated 2026-03-18 from 4 gap-fill agents.

## G1: Save Data Migration (PARTIAL)
- Godot has no built-in resource versioning; proposal #7567 unimplemented
- Sequential patch chain (v1→v2→v3) is the cross-engine standard
- Dictionary.merge() with defaults template for backward-compatible loading
- UID references prevent save breakage from scene restructuring
- Failsafe/fallback object pattern for removed content
- Resources are actually MOST fragile for migration (silent data loss on rename/remove)
- 9 new sources

## G2: Accessibility (PARTIAL)
- Godot 4.5 added native AccessKit screen reader support (experimental)
- DisplayServer.tts_speak() API for text-to-speech (platform limitations)
- Community addons: godot-accessibility, NVDA Integration, ColorBlind Accessibility Tool
- Soulblaze RPG devlog: real-world Godot RPG accessibility implementation
- Font scaling requires manual implementation via theme overrides
- Game Accessibility Guidelines and IGDA-GASIG top-10 as industry standards
- European Accessibility Act (June 2025) creates regulatory incentive
- 18 new sources

## G3: Combat AI and Status Effects (YES)
- Gambit system pattern (FF12-inspired): conditions → candidates → weighted selection
- Pokemon-style move scoring pipeline: base 100 + modifiers + threshold filtering
- PokeRogue two-metric AI: User Benefit Score + Target Benefit Score
- Utility AI: multiplicative considerations with response curves
- Two Godot utility AI plugins (Pennycook GDScript, JarkkoPar C++ GDExtension)
- LimboAI for behavior tree approach
- Cassette Beasts: status effects AS type effectiveness (not multipliers)
- Pokemon major/minor status architecture (mutual exclusivity rules)
- The Liquid Fire condition-based status effect pattern for Godot
- ModiBuff library for high-performance modifier systems
- 17 new sources

## G4: Performance and GDExtension (PARTIAL)
- GDScript static typing: 34-59% faster in benchmarks
- C# 4-140x faster for pure computation, negligible difference at single-iteration scale
- GDExtension had critical StringName caching bug (fixed in godot-cpp PR #1176)
- Godot API binding overhead: 49.5x slower than raw engine for raycasts
- godot-rust FFI: 1.4x to 42.8x speedups depending on operation weight
- Scene tree is single-threaded, main scalability bottleneck
- GDScript AOT compilation planned but no timeline
- Community RPG plugins all use GDScript (suggesting sufficient performance in practice)
- 11 new sources

## Stop Condition Check
- Total new sources: 55 (minimum 6 for standard) ✓
- High-priority gaps filled: G1 partial, G2 partial, G3 yes = 3/3 at least partial ✓
- No unresolved contradictions with existing Key Findings ✓
