# Claude Agent Tooling Reference

Quick-reference for Git workflows, Context7 MCP, and the Compound Engineering plugin as they apply to Claude Code agent development.

> Synthesized from research conducted 2026-03-19. See [Sources](#sources) for full citations.

---

## Table of Contents

- [Git in Claude Agent Workflows](#git-in-claude-agent-workflows)
- [Context7 MCP](#context7-mcp)
- [Compound Engineering Plugin](#compound-engineering-plugin)
- [Integration Patterns](#integration-patterns)
- [Known Limitations and Caveats](#known-limitations-and-caveats)
- [Sources](#sources)

---

## Git in Claude Agent Workflows

### Core Capabilities

Claude Code handles the full git lifecycle through natural language:

| Capability | How |
|------------|-----|
| Stage, commit, branch | Conversational prompts; auto-adds `Co-Authored-By` trailers |
| Open PRs | `gh pr create` via natural language |
| PR-scoped sessions | `claude --from-pr <number>` links session to a PR |
| History exploration | Prompts like "summarize how ExecutionFactory's API evolved" trigger `git log` automatically |
| Branch-aware session picker | Press `B` to filter sessions by current git branch |

### Worktree-Based Parallelism

Worktrees are the primary mechanism for running multiple Claude sessions without file conflicts.

- **CLI**: `claude --worktree <name>` creates an isolated directory with a `worktree-<name>` branch at `.claude/worktrees/<name>/`.
- **Subagents**: `isolation: "worktree"` in agent config. Auto-cleaned when no changes are made.
- **Real-world result**: incident.io reported an 18% API performance improvement from a single worktree-isolated session. Plan Mode was cited as critical — it "eliminates fear of unauthorized modifications."

### Recommended Development Cycle

Four phases, mapped to Claude Code modes:

1. **Explore** — Plan Mode (read-only). Understand the codebase.
2. **Plan** — `Ctrl+G`. Design the approach.
3. **Implement** — Normal Mode. Write code and run tests.
4. **Commit** — Stage, commit, push.

**Writer/Reviewer pattern**: Session A implements, Session B (clean context) reviews — mitigates self-review bias.

### Headless / CI Mode

- `claude -p "..."` runs headless with scoped tools.
- Tool scoping example: `--allowedTools "Bash(git diff *),Bash(git log *)"` for read-only PR review (15–45s per diff).
- Use cases: automated PR review, code migration fan-outs, and git-diff-scoped analysis.
- **GitHub Action**: `claude-code-action` (v1.0, August 2025) responds to `@claude` mentions in PR comments and issues, running on the user's own GitHub runner.
- Over 60% of teams integrate Claude Code through GitHub Actions (SFEIR Institute).

### Safety

- **Agent autonomy vs. git safety**: Anthropic warns against `--dangerously-skip-permissions` in non-sandboxed environments, but community CI examples sometimes omit this caution. The tension between letting Claude manage git autonomously and maintaining human review is unresolved.
- Merge conflict resolution behavior is undocumented.

---

## Context7 MCP

Context7 (`@upstash/context7-mcp`) solves stale-training-data problems by fetching live, version-specific library documentation into the agent's context window at query time, replacing manual doc lookup.

### Setup

**Local (stdio)**:
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
```
Requires Node.js 18+.

**Remote (HTTP)**:
```bash
claude mcp add --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: YOUR_KEY"
```

### Two-Tool Workflow

Always call these sequentially:

1. **`resolve-library-id`** — Converts a library name to a Context7 ID (e.g., `/vercel/next.js`). Results ranked by name similarity, snippet count, source reputation, and benchmark score (max 100).
2. **`query-docs`** — Fetches version-specific documentation chunks. Default token limit: 5,000.

**Shortcut**: Skip step 1 by specifying IDs directly (e.g., "use library /vercel/next.js/v15.0.0") when the exact library/version is known.

### Automatic Invocation

Add to CLAUDE.md:
```
Always use Context7 when I need library/API documentation, code generation,
or setup/configuration steps.
```

The Compound Engineering plugin adds three layers on top:
1. A Skill that auto-detects documentation needs
2. A `docs-researcher` sub-agent running lookups in separate context (prevents conversation bloat)
3. A `/context7:docs <library> [query]` command for on-demand queries

### Performance

- Documentation lookup: **10–15 seconds** vs. 3–5 minutes manually (12–20x speedup).
- Saves an estimated 45–100 minutes/day in documentation-heavy workflows.
- Library index covers 500+ external libraries and GitHub repositories.

### Pricing (as of January 2026)

| Tier | Limit |
|------|-------|
| Free | ~1,000 requests/month, 60 requests/hour hard cap |
| Paid | ~$10/month |

Free-tier figures are contested in the community (some report 500/month).

---

## Compound Engineering Plugin

### Overview

An open-source (MIT) Claude Code plugin by Every Inc. Operationalizes a four-step development loop — **Plan → Work → Review → Compound** — where each completed task generates structured knowledge for future tasks. Ships 29 specialized agents, 45+ skills, and 20+ slash commands.

| Metric | Value |
|--------|-------|
| Repository | [github.com/EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) |
| Stars | 10,600+ |
| Forks | 851 |
| Contributors | 43 |
| License | MIT |
| Languages | TypeScript 81.3%, Python 7.9%, JS 4.2%, Ruby 3.4% |
| Created | October 9, 2025 |

**Installation**: `claude /plugin marketplace add EveryInc/compound-engineering-plugin`

### Core Commands

| Command | Purpose |
|---------|---------|
| `/ce:ideate` | Initial ideation |
| `/ce:brainstorm` | Collaborative exploration of approaches |
| `/ce:plan` | Structured implementation planning |
| `/ce:work` | Execution with clarification-first behavior |
| `/ce:review` | Multi-agent parallel code review (14+ agents, P1/P2/P3 triage) |
| `/ce:compound` | Knowledge capture into `docs/solutions/` |
| `/lfg` | Full autonomous pipeline from plan to PR |
| `/slfg` | Swarm mode with parallel sub-agent execution |
| `/deepen-plan` | Stress-tests plans with 40+ agents |

**80/20 allocation**: 80% planning and review, 20% code execution and knowledge capture.

### Agent Inventory (29 agents)

| Category | Count | Examples |
|----------|-------|---------|
| Review | 15 | security-sentinel, performance-oracle, dhh-rails-reviewer, architecture-strategist, code-simplicity-reviewer |
| Research | 6 | best-practices-researcher, framework-docs-researcher, git-history-analyzer, learnings-researcher |
| Design | 3 | figma-design-sync, design-implementation-reviewer, design-iterator |
| Workflow | 4 | bug-reproduction-validator, lint, pr-comment-resolver, spec-flow-analyzer |
| Documentation | 1 | ankane-readme-writer |

Includes persona-based reviewers (dhh-rails-reviewer, kieran-rails-reviewer, etc.).

### The Compound Step

The distinctive innovation. When a problem is solved, `/ce:compound` runs a 3-phase orchestration:

1. **Phase 0.5** — Scans MEMORY.md for relevant prior notes.
2. **Phase 1** — 5 parallel read-only subagents: Context Analyzer, Solution Extractor, Related Docs Finder, Prevention Strategist, Category Classifier.
3. **Phase 2** — Writes exactly one Markdown file to `docs/solutions/[category]/`.
4. **Phase 3** (optional) — Domain-specialized review agents.

**File format**: Markdown with YAML frontmatter validated against `schema.yaml`. Required frontmatter fields: `module`, `date`, `problem_type` (13 enum values), `component` (15 enum values), `symptoms`, `root_cause` (15 enum values), `resolution_type` (10 enum values), and `severity`. Body structure: Problem → Environment → Symptoms → "What Didn't Work" (failed attempts with reasons) → Solution (before/after code) → "Why This Works" (root cause explanation) → Prevention guidance → Related Issues.

**9 category directories**: build-errors/, test-failures/, runtime-errors/, performance-issues/, database-issues/, security-issues/, ui-bugs/, integration-issues/, logic-errors/

**Retrieval**: Grep-based (`grep -r "exact error phrase" docs/solutions/`). No embedding or semantic search — findability depends on keyword quality at write time.

**Auto-triggers**: Natural phrases like "that worked," "it's fixed," "problem solved."

**Staleness**: `/ce:compound-refresh` reviews existing docs against the current codebase and archives, updates, or replaces stale documents.

**Open questions**: Whether `/ce:plan` automatically searches `docs/solutions/` during planning (or if retrieval is only reactive). Whether `critical-patterns.md` is auto-injected into CLAUDE.md or requires manual promotion.

### Architecture

Four-layer architecture: user-facing commands → multi-agent orchestration → specialized agent workers with isolated context → skills and MCP servers for domain knowledge.

```
plugins/compound-engineering/
├── agents/          # Markdown files with YAML frontmatter
├── commands/        # Slash command definitions
├── skills/          # SKILL.md files + references/templates/scripts
├── hooks/hooks.json # Lifecycle event handlers
└── .mcp.json        # MCP server configuration (Context7)
```

- **Subagents**: Markdown files declaring name, description, model, tools, permissionMode in YAML frontmatter. Most use `model: inherit`; lint agent uses `model: haiku` for cost savings. Cannot nest (no sub-subagents).
- **Skills**: Directories with SKILL.md that activate automatically when their description matches the task context. Injected as "Step 0: Discover and Load Skills" before agent iteration.
- **MCP Server**: One active server — Context7 (HTTP transport, requires `CONTEXT7_API_KEY`) for framework documentation lookup across 100+ frameworks. Playwright MCP was deprecated in v2.25.0, replaced by the `agent-browser` CLI tool.
- **Security restriction**: Plugin subagents cannot use hooks, mcpServers, or permissionMode fields. Copy agents to `.claude/agents/` or `~/.claude/agents/` for those capabilities.
- **Cross-platform**: `bunx @every-env/compound-plugin sync --target [platform]` converts for OpenCode, Codex, Gemini CLI, GitHub Copilot, Kiro, Windsurf, and others. Skills sync as symlinks from `~/.claude/skills/`.

**Open questions**: Whether the plugin actively uses `hooks/hooks.json`. Exact `.mcp.json` configuration syntax for Context7.

### Context Overhead

The plugin loads ~36,000 tokens at session start ([GitHub issue #63](https://github.com/EveryInc/compound-engineering-plugin/issues/63)). The maintainer prefers keeping it unified rather than splitting into smaller plugins.

---

## Integration Patterns

### Context7 + Compound Engineering

The Compound Engineering plugin ships its own Context7 MCP server (HTTP transport, requires `CONTEXT7_API_KEY`). This powers the `framework-docs-researcher` agent and the `/context7:docs` command, keeping doc lookups in separate subagent context to avoid bloating the main conversation.

### Git Worktrees + Multi-Agent Review

The `/ce:review` command can leverage worktree isolation when spawning 14+ parallel review agents, preventing file conflicts between concurrent analysis passes. The `isolation: "worktree"` subagent config handles cleanup automatically.

### Headless CI + Compound Knowledge

CI pipelines using `claude -p "..."` with `--allowedTools` scoping can incorporate compound knowledge by ensuring the `docs/solutions/` directory is committed and available in the CI environment. The `learnings-researcher` agent greps this directory during planning phases.

### Recommended Workflow Combining All Three

1. **Start session** — `claude --worktree feature-x` for isolation
2. **Explore** — Plan Mode; use Context7 for unfamiliar library APIs
3. **Plan** — `/ce:plan` or manual planning with `Ctrl+G`
4. **Implement** — Normal Mode; Context7 auto-invoked via CLAUDE.md rule
5. **Review** — `/ce:review` (14+ parallel agents)
6. **Commit** — Atomic commits following conventional format
7. **Compound** — `/ce:compound` to capture knowledge
8. **PR** — `gh pr create` or `/lfg` for full pipeline

---

## Known Limitations and Caveats

### Git
- Merge conflict resolution behavior is undocumented.
- `--from-pr` behavior with complex multi-commit histories is unclear.
- No monorepo-specific strategies documented.

### Context7
- Indexing lag for brand-new library releases is undocumented.
- Error handling when Context7 server is unreachable mid-session is unclear.
- No independent accuracy benchmarks exist. A competitor-authored benchmark (neuledge.com) claims Context7 achieves 65% accuracy on newer framework APIs vs. 90% for competitors — not independently verified.
- Free tier rate limits are a friction point. Conflicting reports on exact limits (500 vs. 1,000/month). GitHub issue #808 shows active rate-limiting complaints.

### Compound Engineering
- **No independent effectiveness validation.** Every claims 5x productivity; the METR RCT found AI tools made experienced developers 19% slower (while they perceived 20% faster). These findings don't invalidate CE specifically but establish that AI productivity perception is systematically biased.
- The DORA 2024 report (39,000 respondents) found AI adoption correlated with decreased delivery throughput and stability, suggesting code generation may not be the bottleneck.
- Schema enum values (e.g., `brief_system`, `email_processing`) are Cora-specific — customize for your own project.
- Grep-based retrieval may limit knowledge findability at scale compared to semantic search.
- 36k token overhead per session.
- Will Larson predicted the practices would "get absorbed into harnesses" — the plugin's long-term value proposition may narrow as Claude Code adds native planning/review features.

### Structural Risks of Agentic Workflows (agentic-patterns.com)
1. Documentation discipline burden
2. Prompt/system-prompt bloat over time
3. Rule proliferation causing agent inflexibility
4. Ongoing maintenance demands as patterns change

---

## Sources

### Primary References

| Source | Topic | Link |
|--------|-------|------|
| Claude Code Common Workflows | Git lifecycle, worktrees, PR linking | [code.claude.com](https://code.claude.com/docs/en/common-workflows) |
| Claude Code Best Practices | Explore-Plan-Code-Commit, allowedTools | [code.claude.com](https://code.claude.com/docs/en/best-practices) |
| Claude Code Overview | High-level capability overview | [code.claude.com](https://code.claude.com/docs/en/overview) |
| Claude Code Plugins Reference | Plugin system schema | [code.claude.com](https://code.claude.com/docs/en/plugins-reference) |
| Claude Code Sub-agents docs | Subagent frontmatter, isolation, restrictions | [code.claude.com](https://code.claude.com/docs/en/sub-agents) |
| Context7 GitHub Repository | Setup, tools, release history | [github.com/upstash/context7](https://github.com/upstash/context7) |
| Context7 resolve-library-id Docs | Tool schema, ranking criteria | [context7.com](https://context7.com/docs/agentic-tools/ai-sdk/tools/resolve-library-id) |
| DeepWiki: Context7 Plugin | Plugin component breakdown | [deepwiki.com](https://deepwiki.com/upstash/context7/9-claude-code-plugin) |
| DeepWiki: Context7 Usage Guide | Invocation patterns, token management | [deepwiki.com](https://deepwiki.com/upstash/context7/8-usage-guide) |
| incident.io Blog | Worktree adoption metrics | [incident.io](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees) |
| claudefa.st Worktree Guide | Subagent isolation, cleanup strategy | [claudefa.st](https://claudefa.st/blog/guide/development/worktree-guide) |
| SFEIR Institute Headless CI Cheatsheet | CI mode, security controls, PR review | [institute.sfeir.com](https://institute.sfeir.com/en/claude-code/claude-code-headless-mode-and-ci-cd/cheatsheet/) |
| claude-code-action GitHub | GitHub Action for @claude mentions | [github.com](https://github.com/anthropics/claude-code-action) |
| EF-Map Blog | Context7 performance metrics | [ef-map.com](https://ef-map.com/blog/context7-mcp-documentation-automation) |
| ClaudeLog: Context7 MCP | Installation, free tier changes | [claudelog.com](https://claudelog.com/claude-code-mcps/context7-mcp/) |
| Trevor Lasn: Context7 MCP | CLAUDE.md rule config, version pinning | [trevorlasn.com](https://www.trevorlasn.com/blog/context7-mcp) |
| EveryInc/compound-engineering-plugin | Plugin source, stats, architecture | [github.com](https://github.com/EveryInc/compound-engineering-plugin) |
| Compound Engineering founding article | Methodology and origin | [every.to](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) |
| Compound Engineering Guide | Detailed workflow, agent roles, system files | [every.to](https://every.to/guides/compound-engineering) |
| Learning from Every's CE (Larson) | Independent analysis | [lethain.com](https://lethain.com/everyinc-compound-engineering/) |
| METR AI Productivity RCT | Controlled study of AI coding productivity | [metr.org](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) |
| DORA 2024 Report (RedMonk) | AI adoption vs. delivery metrics | [redmonk.com](https://redmonk.com/rstephens/2024/11/26/dora2024/) |
| DeepWiki: CE Plugin | Architecture analysis | [deepwiki.com](https://deepwiki.com/kieranklaassen/compound-engineering-plugin) |
| ce-compound SKILL.md | Full orchestration logic, phase sequence | [github.com](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/ce-compound/SKILL.md) |
| compound-docs SKILL.md | Documentation process, grep retrieval, validation | [github.com](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/compound-docs/SKILL.md) |
| compound-docs schema.yaml | YAML frontmatter schema, enum values | [github.com](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/compound-docs/schema.yaml) |
| resolution-template.md | Document body structure template | [github.com](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/compound-docs/assets/resolution-template.md) |

### Source Research Documents

- [/docs/research/git-and-context7-in-claude-agent-workflows.md](/docs/research/git-and-context7-in-claude-agent-workflows.md) — 14 sources, quick effort
- [/docs/research/compound-engineering-github-plugin.md](/docs/research/compound-engineering-github-plugin.md) — 38+ sources, deep effort
