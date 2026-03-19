---
name: godot-patterns
description: "Godot 4 architectural patterns for GDScript scene composition, resource management, and signal-based communication. Use when generating, reviewing, or refactoring GDScript code or Godot scenes."
user-invocable: false
---

# Godot 4 Patterns Reference

Domain knowledge for Godot 4 + GDScript development. Three reference files provide detailed guidance:

- [Scene Architecture](./scene-architecture.md) — composition, signals, dependency injection, scene unique nodes, groups
- [GDScript Quality](./gdscript-quality.md) — member ordering, naming conventions, typing rules, state machines, patterns
- [Resource System](./resource-system.md) — `res://` paths, `.uid` files, Resource sharing pitfalls, `.duplicate()`, loading patterns

## Core Principles (Quick Reference)

1. **Composition over inheritance.** Assemble entities from single-purpose child nodes. Limit scene inheritance to one layer.
2. **"Call down, signal up."** Parents call children's methods. Children emit signals. Siblings communicate through shared parent.
3. **Resources hold data; Nodes hold behavior.** Custom Resource classes for item definitions, stat blocks, configs. Nodes only where scene-tree integration is needed.
4. **Static typing is mandatory.** Every variable, parameter, and return type must be typed. Typed GDScript runs 28-59% faster.
5. **Performance is architectural.** `set_process(false)` on off-screen objects, `process_mode = DISABLED` for subtrees, Server APIs for high-count entities.
