---
review_agents: [gc-gdscript-lint, gc-gdscript-reviewer, gc-godot-architecture-reviewer, gc-resource-safety-reviewer, gc-code-simplicity-reviewer]
plan_review_agents: [gc-code-simplicity-reviewer]
---

# Review Context

This is a **Godot 4.6 + GDScript RPG** (RootsGame). All reviews must apply Godot-specific patterns.

## Domain Rules

- **Architecture:** Composition over inheritance. "Call down, signal up." Scene inheritance limited to one layer. Event Bus for cross-system signals only.
- **Code quality:** Static typing mandatory. Member ordering follows GDScript style guide. Signals named in past tense. Booleans prefixed with `is_`/`can_`/`has_`.
- **Resource safety:** Flag any raw `mv`/`git mv` on resource files. Flag `.tres` loads without `.duplicate()` in mutable contexts. Flag dynamic `load()` with string concatenation.
- **Scene safety:** `.tscn` files must NOT be edited by agents. Read and report only.
- **Performance:** Flag `_process` callbacks that could be replaced by signals. Flag untyped variables. Flag deep inheritance (>1 layer).