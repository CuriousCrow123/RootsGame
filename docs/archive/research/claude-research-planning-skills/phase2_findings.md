# Phase 2: Research Findings

## Coverage Summary
- **Facet 1 (Skill Authoring):** High confidence — 5 sources including 3 official Anthropic docs
- **Facet 2 (Planning Workflows):** Medium confidence — 7 sources, core patterns well-documented but extend-research specifics sparse
- **Facet 3 (Skill Chaining):** Medium-high confidence — 7 sources, official docs authoritative on mechanics

---

## Facet 1: Skill Authoring Best Practices

**SUMMARY:** Claude Code skills are SKILL.md files with YAML frontmatter and markdown instructions. Progressive disclosure loads metadata first (~100 tokens), full body when relevant (<500 lines), and bundled resources on demand. Description field is the primary trigger mechanism.

**KEY_FINDINGS:**
- SKILL.md is the only required file. Frontmatter needs `name` and `description`. Description is most important — Claude uses it to decide activation.
- Progressive disclosure at 3 levels: metadata always in context, body loads on relevance, references load on demand.
- Descriptions must be third person ("Processes Excel files"). Include what it does AND when to use it.
- Key frontmatter: `disable-model-invocation`, `user-invocable`, `context: fork`, `allowed-tools`, `agent`, `argument-hint`.
- `$ARGUMENTS` substitution enables passing user input. `${CLAUDE_SKILL_DIR}` for skill directory path.
- Multi-phase skills use checklist patterns with plan-validate-execute.
- Keep SKILL.md under 500 lines; use references/ for overflow.
- Only add what Claude doesn't already know.

**TENSIONS:** Naming conventions inconsistent (gerund vs imperative). Frontmatter requirements differ between Claude Code and API platform.

**SOURCES:**
- code.claude.com/docs/en/skills | Anthropic official
- platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices | Anthropic official
- claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills | Anthropic blog

---

## Facet 2: Planning and Research Extension Workflows

**SUMMARY:** The compound engineering pipeline (Brainstorm → Plan → Deepen → Work → Review → Compound) is the most developed public example. "Extend/deepen" skills spawn parallel research agents to enrich an initial artifact. 80% of effort goes to planning and review.

**KEY_FINDINGS:**
- Canonical pipeline: Plan → Work → Review → Compound with optional Brainstorm and Deepen-Plan.
- /deepen-plan spawns 40+ parallel agents to research and enhance an existing plan document.
- Two competing "deepen" patterns: (1) parallel research agents, (2) iterative question-asking (Pierce Lamb's /deep-plan).
- Anthropic recommends starting simple, adding complexity only when demonstrably improving outcomes.
- File-based planning prevents goal drift — filesystem as persistent memory vs. context as volatile RAM.
- Skill chaining is a workflow habit, not a built-in feature. Output on disk becomes input for next skill.

**TENSIONS:** Over-planning vs. iterative action. Parallel research depth vs. context coherence. Question-asking vs. autonomous research for deepening.

**SOURCES:**
- every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents | Every
- every.to/guides/compound-engineering | Every
- anthropic.com/research/building-effective-agents | Anthropic
- github.com/EveryInc/compound-engineering-plugin | Every Inc

---

## Facet 3: Skill Chaining and Extension Patterns

**SUMMARY:** Skills chain through file-based handoff and explicit orchestration — not programmatic invocation. Subagents cannot spawn other subagents. The main context orchestrates sequential/parallel work, passing results via disk or prompt context.

**KEY_FINDINGS:**
- Skills are context injections, not callable functions. Cannot call other skills programmatically.
- File-based handoff is the primary chaining mechanism. Subagents write to disk, next phase reads.
- Subagents cannot spawn other subagents (architectural constraint).
- `context: fork` runs a skill as isolated subagent.
- Preloading skills into subagents enables domain-aware delegation.
- Dynamic context injection (`!`command``) lets skills read live state before Claude sees content.
- Persistent subagent memory enables cross-session knowledge compounding.
- Fan-out/fan-in (parallel Explore subagents → synthesize) is the dominant multi-agent pattern.

**TENSIONS:** Implicit vs. explicit chaining. Context isolation vs. information sharing.

**SOURCES:**
- code.claude.com/docs/en/skills | Anthropic official
- code.claude.com/docs/en/sub-agents | Anthropic official
- github.com/EveryInc/compound-engineering-plugin | Every Inc
