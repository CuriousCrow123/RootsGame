# Research: How to Make Use of Git and Context7 in Agent Workflows (Claude)

> Researched 2026-03-19. Effort level: quick. 14 unique sources consulted.

## Key Findings

1. **Claude Code treats Git as first-class**: it stages, commits, branches, opens PRs, and explores history — all from natural language. The recommended cycle is Explore → Plan → Code → Commit.
2. **Git worktrees enable parallel agent sessions**: `claude --worktree <name>` or subagent `isolation: worktree` creates isolated branches at `.claude/worktrees/<name>/`, allowing multiple Claude sessions to work simultaneously without merge conflicts.
3. **Context7 MCP injects live, version-specific docs into the agent's context**: two sequential tools — `resolve-library-id` then `query-docs` — replace manual doc lookup with 10–15 second automated retrieval (vs. 3–5 minutes manually).
4. **Automatic Context7 invocation** requires a CLAUDE.md rule (e.g., "Always use Context7 when I need library/API documentation"). Without it, every prompt needs "use context7" appended.
5. **Headless CI integration** via `claude -p "..."` with `--allowedTools` scoping enables automated PR review, code migration fan-outs, and git-diff-scoped analysis in CI/CD pipelines.

## Git in Claude Agent Workflows

### Summary
Claude Code handles the full git lifecycle through natural language — staging, committing, branching, PR creation, and history exploration. Its most distinctive capability is native worktree support, enabling multiple isolated parallel sessions. Best practices center on the Explore-Plan-Code-Commit cycle and scoping headless invocations with tool allowlists.

### Detail

**Core Git Capabilities:**
- Claude stages files, writes commit messages with `Co-Authored-By` trailers, creates branches, and opens PRs via `gh pr create` — all from conversational prompts (Anthropic docs).
- Sessions created with `claude --from-pr <number>` are automatically linked to a PR, enabling resumable, PR-scoped agent sessions.
- For history exploration, prompts like "look through ExecutionFactory's git history and summarize how its API came to be" trigger `git log` and related commands automatically.

**Worktree-Based Parallelism:**
- `claude --worktree <name>` creates isolated working directories with dedicated branches (`worktree-<name>`), allowing multiple Claude sessions with zero file conflicts.
- Subagents configured with `isolation: "worktree"` get auto-cleaned worktrees when no changes are made — ideal for batched code migrations across many files.
- incident.io reported an 18% API performance improvement from a single worktree-isolated Claude session, noting Plan Mode was critical because it "eliminates fear of unauthorized modifications."

**CI/Headless Mode:**
- `claude -p "..."` runs headless with scoped tools like `--allowedTools "Bash(git diff *),Bash(git log *)"` for read-only PR review (15–45 seconds per diff).
- The `claude-code-action` GitHub Action (v1.0, August 2025) responds to `@claude` mentions in PR comments and issues, running on the user's own GitHub runner.
- Over 60% of teams integrate Claude Code through GitHub Actions (SFEIR Institute).

**Best Practices:**
- Use the four-phase cycle: Explore (Plan Mode, read-only) → Plan (`Ctrl+G`) → Implement (Normal Mode with tests) → Commit.
- Use a Writer/Reviewer multi-session pattern: Session A implements, Session B (clean context) reviews — mitigating self-review bias.
- Session picker's `B` key filters by current git branch for branch-aware context management.

### Open Questions
- How Claude handles merge conflicts beyond worktree prevention is undocumented.
- Behavior of `--from-pr` for complex multi-commit PR histories is unclear.
- Monorepo-specific strategies with Claude agents are not covered.

---

## Context7 MCP in Claude Agent Workflows

### Summary
Context7 MCP (`@upstash/context7-mcp`) solves stale-training-data problems by fetching live, version-specific library documentation into the LLM's context window at query time. It integrates with Claude Code via a two-tool sequential workflow and can be configured for automatic invocation via CLAUDE.md rules or the Claude Code plugin's Skill system.

### Detail

**Setup:**
- Fastest local setup: `claude mcp add context7 -- npx -y @upstash/context7-mcp@latest` (stdio mode, Node.js 18+ required).
- Remote/HTTP alternative: `claude mcp add --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: YOUR_KEY"`.

**Two-Tool Workflow:**
1. `resolve-library-id` — converts a library name into a Context7-compatible ID (e.g., `/vercel/next.js`). Results ranked by name similarity, snippet count, source reputation, and benchmark score (max 100).
2. `query-docs` — fetches version-specific documentation chunks, configurable token limit (default 5,000).
- Shortcut: skip `resolve-library-id` by specifying IDs directly (e.g., "use library /vercel/next.js/v15.0.0") when the exact library/version is known.

**Automatic Invocation:**
- Add to CLAUDE.md: "Always use Context7 when I need library/API documentation, code generation, or setup/configuration steps."
- The Claude Code plugin adds three layers: (1) a Skill that auto-detects documentation needs, (2) a `docs-researcher` sub-agent running lookups in separate context to prevent conversation bloat, (3) a `/context7:docs <library> [query]` command for on-demand queries.

**Performance:**
- A production case study measured documentation lookup dropping from 3–5 minutes (3–4 manual exchanges) to 10–15 seconds — a 12–20x speedup, saving 45–100 minutes/day (EF-Map blog).
- Library index covers 500+ external libraries and GitHub repositories.

**Pricing:**
- Free tier reduced to ~1,000 requests/month with a 60 requests/hour hard rate limit (as of January 2026). Paid plan ~$10/month. Exact free-tier figure is contested in the community.

### Open Questions
- Indexing lag for brand-new library releases is undocumented.
- Error handling behavior when the Context7 server is unreachable mid-session is unclear.
- No independent (non-competitor) accuracy benchmarks exist.

---

## Tensions and Debates

- **Agent autonomy vs. git safety**: Anthropic docs warn against `--dangerously-skip-permissions` in non-sandboxed environments, but community CI examples sometimes omit this caution. The tension between letting Claude manage git autonomously and maintaining human review is unresolved.
- **Context7 accuracy claims**: A competitor-authored benchmark (neuledge.com) claims Context7 achieves 65% accuracy on newer framework APIs vs. 90% for competitors — but this is not independently verified. Context7's own case studies show significant time savings.
- **Context7 free tier**: Conflicting reports on exact request limits (500 vs. 1,000/month). GitHub issue tracker (#808) shows active rate-limiting complaints.

## Gaps and Limitations

- No detailed documentation on Claude Code's merge conflict resolution behavior.
- No public data on Context7 indexing lag for new library versions.
- No independent benchmarks comparing Context7 to alternatives.
- Monorepo-specific agent strategies are uncovered.
- Several potentially valuable sources were blocked by paywalls (Medium, SitePoint, Dev Genius).

## Sources

### Most Valuable
- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows) — Authoritative reference for git workflows, worktrees, PR linking, and session management.
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) — Explore-Plan-Code-Commit cycle, allowedTools scoping, fan-out scripting.
- [Context7 GitHub Repository](https://github.com/upstash/context7) — Primary source for setup, tool descriptions, and release history.
- [incident.io Blog: Shipping Faster with Claude Code and Git Worktrees](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees) — Real-world team account with measurable outcomes.
- [DeepWiki: Context7 Claude Code Plugin](https://deepwiki.com/upstash/context7/9-claude-code-plugin) — Detailed breakdown of plugin's four components.

### Full Source List
| Source | Facet | Type | Date | Key contribution |
|--------|-------|------|------|-----------------|
| [Common Workflows — Claude Code Docs](https://code.claude.com/docs/en/common-workflows) | Git | Official docs | 2025–2026 | Git lifecycle, worktrees, PR linking |
| [Claude Code Overview](https://code.claude.com/docs/en/overview) | Git | Official docs | 2025–2026 | High-level capability overview |
| [Best Practices — Claude Code Docs](https://code.claude.com/docs/en/best-practices) | Git | Official docs | 2025–2026 | Explore-Plan-Code-Commit, allowedTools |
| [incident.io Engineering Blog](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees) | Git | Industry blog | 2025 | Real-world worktree adoption metrics |
| [claudefa.st Worktree Guide](https://claudefa.st/blog/guide/development/worktree-guide) | Git | Industry guide | 2025–2026 | Subagent isolation, cleanup strategy |
| [SFEIR Institute Headless CI Cheatsheet](https://institute.sfeir.com/en/claude-code/claude-code-headless-mode-and-ci-cd/cheatsheet/) | Git | Training docs | 2025–2026 | CI mode, security controls, PR review |
| [claude-code-action GitHub](https://github.com/anthropics/claude-code-action) | Git | Official repo | Aug 2025 | GitHub Action for @claude mentions |
| [Context7 GitHub Repository](https://github.com/upstash/context7) | Context7 | Official repo | Mar 2026 | Setup, tools, release history |
| [DeepWiki: Context7 Plugin](https://deepwiki.com/upstash/context7/9-claude-code-plugin) | Context7 | Codebase analysis | 2026 | Plugin components breakdown |
| [DeepWiki: Context7 Usage Guide](https://deepwiki.com/upstash/context7/8-usage-guide) | Context7 | Codebase analysis | 2026 | Invocation patterns, token management |
| [Context7 resolve-library-id Docs](https://context7.com/docs/agentic-tools/ai-sdk/tools/resolve-library-id) | Context7 | Official docs | 2026 | Tool schema, ranking criteria |
| [ClaudeLog: Context7 MCP](https://claudelog.com/claude-code-mcps/context7-mcp/) | Context7 | Industry guide | Jan 2026 | Installation, free tier changes |
| [EF-Map: Context7 Integration](https://ef-map.com/blog/context7-mcp-documentation-automation) | Context7 | Case study | 2025–2026 | 12–20x speedup metrics |
| [Trevor Lasn: Context7 MCP](https://www.trevorlasn.com/blog/context7-mcp) | Context7 | Dev blog | 2025–2026 | CLAUDE.md rule config, version pinning |
