# Research: Claude Research & Planning Skills Design

> Researched 2026-03-18. Effort level: standard. 14 unique sources consulted.

## Key Findings

1. **The "extend" pattern is: read artifact → fan-out parallel research → merge back.** Both `extend-research` and `extend-plan` follow the same structure: read an existing file, identify gaps or sections to deepen, spawn parallel subagents to research each, then synthesize findings back into the original document. The compound engineering plugin's `/deepen-plan` implements this by spawning 40+ agents per plan.

2. **Skills chain through files on disk, not programmatic invocation.** Claude Code skills cannot call other skills directly. Chaining works because `/research` writes a report to `research/<slug>.md`, `/extend-research` reads that file and enhances it, `/plan` reads it and produces `docs/plans/<name>.md`, and `/extend-plan` reads the plan and deepens it. Each skill is self-contained but convention-aware.

3. **Two competing "deepen" strategies exist: parallel research and iterative interrogation.** The compound engineering approach spawns many research agents autonomously. Pierce Lamb's `/deep-plan` asks iterative clarifying questions instead. A hybrid that does both — research first, then surface specific questions from gaps — would be stronger than either alone.

4. **SKILL.md design should use progressive disclosure and stay under 500 lines.** Metadata (~100 tokens) is always in context, the full body loads when triggered, and reference files load on demand. Descriptions must be third-person and include specific trigger conditions. The `argument-hint` field guides user input.

5. **The main context orchestrates — subagents cannot spawn subagents.** This architectural constraint means extend/deepen skills must fan out all research from the main context in a single message, then synthesize results when agents return. Multi-level nesting requires sequential orchestration phases.

## Skill Authoring Patterns

### Summary
Claude Code skills are `SKILL.md` files with YAML frontmatter in a named directory under `.claude/skills/` (project-local) or `~/.claude/skills/` (global). The description field is the primary trigger mechanism — Claude matches user intent to skill descriptions to decide activation.

### Detail
**Essential frontmatter for your skills:**
```yaml
---
name: extend-research
description: >
  Extends and deepens an existing research report by identifying gaps,
  spawning parallel research agents to fill them, and merging findings
  back into the original document. Use when a research report exists
  and needs more depth, additional sources, or gap-filling.
argument-hint: "[path to research report] [--effort quick|standard|deep]"
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, TodoWrite, Agent
---
```

Key structural patterns from the official Anthropic docs and compound engineering:
- **`$ARGUMENTS`** substitutes user input into the skill body
- **`${CLAUDE_SKILL_DIR}`** references bundled files relative to the skill directory
- **`allowed-tools`** restricts tool access (important for research-only skills that should never write code)
- **`context: fork`** runs the skill as an isolated subagent (useful for read-only exploration)
- **`disable-model-invocation: true`** prevents auto-triggering (for destructive or side-effect-heavy skills)

The "plan-validate-execute" pattern from Anthropic's best practices guide is directly applicable: generate a structured artifact (plan/research), validate against criteria (stop conditions), then proceed. Multi-phase skills should use checklist tracking via TodoWrite.

### Open Questions
- Should `extend-research` and `extend-plan` be user-invocable only, or should Claude auto-trigger them when it detects a report/plan could be improved?
- Should they use `context: fork` for isolation, or run in main context to preserve conversational state?

---

## Planning and Research Extension Workflows

### Summary
The compound engineering pipeline (Brainstorm → Plan → Deepen → Work → Review → Compound) is the most mature public implementation. "Extend" skills follow a consistent pattern: discover artifact → analyze for gaps → parallel research → merge → validate.

### Detail
**The workflow chain your skills should support:**

```
/research "topic"
    → writes research/<topic>.md

/extend-research research/<topic>.md
    → reads report, identifies gaps/low-confidence areas
    → spawns parallel agents to fill gaps
    → merges findings, updates report in place

/plan "feature based on research"
    → reads research report (if referenced)
    → spawns local research agents (repo patterns, CLAUDE.md)
    → optionally spawns external research agents
    → writes plans/<date>-<name>-plan.md

/extend-plan plans/<name>-plan.md
    → reads plan, identifies sections needing depth
    → spawns parallel research agents per section
    → merges best practices, edge cases, code examples
    → updates plan in place
```

**Key design decisions from the compound engineering plugin:**

The `/deepen-plan` skill (which maps to your `extend-plan`):
1. Parses the plan structure into a "section manifest"
2. Discovers ALL available skills/agents and matches them to plan sections
3. Spawns one subagent per matched skill — all in parallel
4. Also discovers documented learnings from `docs/solutions/`
5. Launches per-section research agents (Explore type) for external best practices
6. Uses Context7 MCP for framework documentation
7. Runs ALL review agents against the plan
8. Synthesizes everything, deduplicates, and merges back

This is comprehensive but heavy (40+ agents). For a personal setup, a lighter approach — 3-5 targeted research agents based on identified gaps — likely delivers 80% of the value.

**The two deepening strategies:**

| Approach | How it works | Best for |
|----------|-------------|----------|
| Parallel research | Spawn agents to autonomously research gaps | Known unknowns, factual depth |
| Iterative interrogation | Ask clarifying questions, refine based on answers | Unknown unknowns, tacit requirements |

Your `extend-research` would primarily use parallel research (since the gaps are in external knowledge). Your `extend-plan` could hybrid both — research first, then surface questions from remaining gaps.

### Open Questions
- How many parallel agents is optimal? Compound engineering uses 40+, but diminishing returns and context coherence are real concerns.
- Should extend skills always update in place, or optionally create a `-deepened` variant?

---

## Skill Chaining and File-Based Handoff

### Summary
Skills chain through convention: each skill writes to a predictable location, and the next skill reads from there. The main context orchestrates — subagents are isolated and cannot spawn sub-subagents.

### Detail
**The handoff pattern:**

```
Skill A writes → known file path → Skill B reads
```

Specific conventions from existing skills:
- `/research` writes to `research/<slug>.md` or `docs/research/<slug>.md`
- `/plan` (cce) writes to `plans/YYYY-MM-DD-NNN-<type>-<name>-plan.md`
- `/brainstorm` (cce) writes to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`
- `/deepen-plan` reads from the plan path (passed as `$ARGUMENTS`) and writes back in place

**Discovery patterns for extend skills:**

When no path is provided, extend skills should discover candidates:
1. List recent files in the expected directory (e.g., `ls -la research/*.md`)
2. If multiple candidates, ask the user which to extend
3. Read the file and validate it has the expected structure

**Fan-out/fan-in orchestration:**

Since subagents cannot spawn subagents, all parallelism must originate from the main context:

```
Main context:
  1. Read artifact, identify N gaps
  2. Launch N Agent subagents in ONE message (parallel)
  3. Wait for all returns
  4. Synthesize structured returns into artifact
  5. Write updated artifact to disk
```

Each subagent should return a strictly structured format (not prose) to minimize noise in the parent context. The context-management skill recommends: "Every extra token in a return is noise in the parent's context forever."

**Dynamic context injection** (`!`command``) is powerful for extend skills:
```markdown
## Current Research Report
!`cat $ARGUMENTS`
```
This loads the file content at skill activation time, before Claude sees it.

### Open Questions
- Should extend skills use intermediate files (like the research skill's `phase2_findings.md`) or keep everything in context?
- How to handle extend skills when the original artifact was written by a different session (different context, possibly different conventions)?

---

## Tensions and Debates

### Heavy orchestration (40+ agents) vs. lightweight extension (3-5 agents)
- **Heavy:** Compound engineering's `/deepen-plan` spawns agents for every available skill, every review agent, every learning document. Maximizes coverage.
- **Light:** Anthropic's own guidance says "start simple, add complexity only when it demonstrably improves outcomes."
- **Assessment:** For a personal setup without a large team's institutional knowledge base (docs/solutions/, dozens of custom agents), 3-5 targeted agents per section is likely optimal. Scale up only if results are consistently shallow.

### Planning-heavy (80/20) vs. iterative action
- **Planning-heavy:** Compound engineering allocates 80% effort to planning and review. Deep plans prevent rework.
- **Iterative:** Anthropic warns that "for highly uncertain tasks, extensive upfront planning might be wasted effort."
- **Resolution:** Planning is most valuable when the problem is understood but the implementation path is complex. For exploratory work, lighter planning + faster iteration wins.

### In-place update vs. versioned artifacts
- **In-place:** Compound engineering's `/deepen-plan` updates the plan file directly. Simple, one source of truth.
- **Versioned:** No skill currently creates `-deepened` variants, but git provides version history.
- **Assessment:** In-place update with git history is the pragmatic choice. Offer `-deepened` suffix as an option for users who want explicit comparison.

## Gaps and Limitations

- **No "extend-research" reference implementation exists publicly.** All documented "extend/deepen" patterns target plans, not research reports. The design must be extrapolated from the research skill's output format and the deepen-plan's input pattern.
- **Token economics of parallel research are undocumented.** No source addresses how many parallel agents you can spawn before context or API costs become prohibitive.
- **Cross-session artifact discovery is fragile.** Skills that read prior output assume consistent file paths and formats. No validation or schema enforcement exists.
- **No empirical comparison** of planning-heavy vs. lightweight workflows in terms of actual development outcomes.

## Sources

### Most Valuable
1. **[Anthropic: Extend Claude with skills](https://code.claude.com/docs/en/skills)** — Definitive reference for SKILL.md format, frontmatter, and invocation control
2. **[Anthropic: Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)** — Progressive disclosure, evaluation-driven development, anti-patterns
3. **[Anthropic: Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)** — Canonical agent workflow taxonomy (chaining, orchestration, evaluation)
4. **[Every: Compound Engineering Guide](https://every.to/guides/compound-engineering)** — Full Plan/Work/Review/Compound lifecycle with deepen-plan details
5. **[Compound Engineering Plugin (GitHub)](https://github.com/EveryInc/compound-engineering-plugin)** — Reference implementation with 29 agents and 19 skills
6. **[Anthropic: Create custom subagents](https://code.claude.com/docs/en/sub-agents)** — Subagent isolation, preloaded skills, persistent memory, chaining constraints

### Full Source List
| Source | Facet | Type | Key contribution |
|--------|-------|------|-----------------|
| [Extend Claude with skills](https://code.claude.com/docs/en/skills) | Authoring | Official docs | All frontmatter fields, invocation control, dynamic injection |
| [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) | Authoring | Official docs | Progressive disclosure, evaluation patterns, anti-patterns |
| [Equipping agents with Agent Skills](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills) | Authoring | Official blog | Architecture overview, security model |
| [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) | Workflows | Official blog | Chaining, orchestration, evaluation taxonomy |
| [Compound Engineering](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) | Workflows | Industry | Philosophy and practical workflow |
| [Compound Engineering Guide](https://every.to/guides/compound-engineering) | Workflows | Industry | Detailed deepen-plan and 80/20 principle |
| [Compound Engineering Plugin](https://github.com/EveryInc/compound-engineering-plugin) | Chaining | Open source | Reference implementation of full pipeline |
| [Create custom subagents](https://code.claude.com/docs/en/sub-agents) | Chaining | Official docs | Subagent isolation, memory, skill preloading |
| [Planning with Files](https://github.com/OthmanAdi/planning-with-files) | Workflows | Community | File-based persistent planning pattern |
| [alexop.dev Customization Guide](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/) | Authoring, Chaining | Community | Practical skill/command/subagent comparison |
| [Claude Code Skills Setup (DEV)](https://dev.to/padawanabhi/claude-code-skills-how-to-set-them-up-and-use-them-1chm) | Authoring | Community | Triggering validation tips |
| [Task Tool Orchestration (DEV)](https://dev.to/bhaidar/the-task-tool-claude-codes-agent-orchestration-system-4bf2) | Chaining | Community | Foreground/background agent execution |
| [Advanced Slash Commands](https://www.giangallegos.com/day-13-advanced-slash-commands-parameters-and-chaining/) | Chaining | Community | Chaining as workflow habit |
| [Building /deep-plan](https://pierce-lamb.medium.com/building-deep-plan-a-claude-code-plugin-for-comprehensive-planning-30e0921eb841) | Workflows | Community | Iterative question-asking deepening pattern |
