# Phase 2: Research Findings

**Topic:** Compound Engineering Plugin on GitHub
**Date:** 2026-03-19
**Total unique sources:** 38+
**Blocked sources:** 2 (medium.com 403, X/Twitter JS-only)

## Coverage Summary

| Facet | Confidence | Sources | Key Gap |
|-------|-----------|---------|---------|
| CORE_IDENTITY | High | 8 | Exact public launch date unclear |
| FEATURES_AND_CAPABILITIES | High | 7 | Per-agent prompt logic not public |
| GITHUB_PRESENCE | High | 8 | Full contributor list not loadable |
| ARCHITECTURE_AND_INTEGRATION | High | 8 | Plugin-level hooks usage unclear |
| COMMUNITY_AND_ADOPTION | Medium | 9 | No verified install counts |
| COMPETITORS_AND_ALTERNATIVES | Medium | 10 | No head-to-head benchmarks |

---

## FACET: CORE_IDENTITY

**SUMMARY:** The Compound Engineering Plugin is an open-source Claude Code plugin built by Every Inc. — an AI-native media and software company — conceived by CEO Dan Shipper and General Manager Kieran Klaassen while building their internal products. Its purpose is to operationalize a four-step development methodology (Plan, Work, Review, Compound) that creates a self-reinforcing learning loop where each engineering task makes future tasks progressively easier through systematic knowledge capture and reuse.

**KEY_FINDINGS:**
- Repository at `github.com/EveryInc/compound-engineering-plugin`, MIT license, 10,000+ GitHub stars as of March 2026
- Created by Dan Shipper (CEO, Every) and Kieran Klaassen (GM of Cora, Every)
- Every Inc. is a 15-person AI-native media/software company running 5 products (Cora, Spiral, Sparkle, Monologue, Every.to)
- Core philosophy: "Each unit of engineering work should make subsequent units easier — not harder"
- Provides 6 primary workflow commands, 25+ specialized agents, 45+ skills, Context7 MCP server
- Supports 12+ platforms via cross-platform CLI converter
- Article introducing methodology published December 11, 2025
- Every claims "a single developer can do the work of five developers a few years ago"
- TechCrunch covered it February 24, 2026 as part of Anthropic's enterprise plugin push
- Will Larson (lethain.com) identified the "Compound" step as the key differentiator

**TENSIONS:** Star count varies across sources (7,000 → 10,600) reflecting growth over time, not disagreement.

**GAPS:** Exact public launch date vs. creation date unclear. Individual contribution split between Shipper and Klaassen not documented. No independent audits of productivity claims.

---

## FACET: FEATURES_AND_CAPABILITIES

**SUMMARY:** The plugin provides a full AI-powered development workflow built around Brainstorm → Plan → Work → Review → Compound → Repeat. It ships with 25-29 specialized agents in five categories, 45+ skills, and 20+ slash commands designed so each unit of engineering work builds institutional knowledge.

**KEY_FINDINGS:**
- 29 agents: 15 review, 6 research, 3 design, 4 workflow, 1 documentation
- Review agents include security-sentinel, performance-oracle, architecture-strategist, dhh-rails-reviewer, kieran-rails-reviewer, etc.
- Research agents: best-practices-researcher, framework-docs-researcher, git-history-analyzer, learnings-researcher, repo-research-analyst
- Design agents: figma-design-sync, design-implementation-reviewer, design-iterator (screenshot-analyze-improve cycles)
- Core commands: /ce:ideate, /ce:brainstorm, /ce:plan, /ce:work, /ce:review, /ce:compound
- /lfg runs full autonomous pipeline; /slfg runs swarm mode with parallel sub-agents
- /deepen-plan stress-tests plans with 40+ agents
- /ce:review spawns 14+ specialized review agents in parallel, triaged by P1/P2/P3
- 80% of time in plan/review phases, 20% in work/compound
- Structured knowledge system: docs/solutions/, docs/brainstorms/, todos/
- Context7 MCP server for 100+ framework documentation lookups
- Known issue: ~36k tokens of context overhead (GitHub issue #63)

**TENSIONS:** Agent count varies (25-29) across sources reflecting active development. "Compound" step sometimes done manually vs. automatically.

**GAPS:** Per-agent prompt logic not publicly documented. API cost implications of parallel agents not addressed. /slfg swarm mode not fully documented.

---

## FACET: GITHUB_PRESENCE

**SUMMARY:** The plugin lives at github.com/EveryInc/compound-engineering-plugin, owned by EveryInc. Created October 9, 2025, MIT licensed, 10.6k stars, 851 forks, 43 contributors, 455 commits, 45 releases as of March 2026.

**KEY_FINDINGS:**
- Canonical repo: github.com/EveryInc/compound-engineering-plugin
- Organization: EveryInc (544 GitHub followers, 27 repositories)
- Created: October 9, 2025
- Stats (March 19, 2026): 10.6k stars, 851 forks, 82 watchers, 43 contributors, 455 commits, 45 releases
- License: MIT (Copyright 2025 Every)
- Primary language: TypeScript (81.3%), Python (7.9%), JavaScript (4.2%), Ruby (3.4%), Shell (3.2%)
- Key contributors: Kieran Klaassen (primary), Trevin Chow (tmchow, marketplace releases)
- NPM package: @every-env/compound-plugin
- Notable forks exist: mbiskach, 8b-is, hesreallyhim-forks, michaelpersonal
- 38 open issues, 11 open PRs, daily commit activity
- Stars doubled from ~5,132 (January 2026) to 10,600+ (March 2026)

**TENSIONS:** None substantive.

**GAPS:** Full contributor list not renderable. Dan Shipper's GitHub username and commit history not identified.

---

## FACET: ARCHITECTURE_AND_INTEGRATION

**SUMMARY:** The plugin integrates through Claude Code's native plugin system, bundling slash commands, specialized subagents, reusable skills, and an MCP server (Context7) into a standard plugin directory structure. Architecture is four-layered: user-facing commands → multi-agent orchestration → specialized agent workers → skills/MCP for domain knowledge.

**KEY_FINDINGS:**
- Installed via `claude /plugin marketplace add EveryInc/compound-engineering-plugin`
- Plugin directory structure: agents/, commands/, skills/, hooks/hooks.json, .mcp.json
- Subagents are Markdown files with YAML frontmatter (name, description, model, tools, permissionMode, etc.)
- 27 agents: most use `model: inherit`, lint agent uses `model: haiku` for cost optimization
- Skills are SKILL.md files with optional references/, templates/, scripts/ subdirectories
- Skills activate automatically when description matches task context ("Step 0: Discover and Load Skills")
- One active MCP server: Context7 (HTTP transport, requires CONTEXT7_API_KEY)
- Playwright MCP deprecated in v2.25.0, replaced by agent-browser CLI
- Plugin hooks respond to lifecycle events (SessionStart, PreToolUse, PostToolUse, etc.)
- Plugin subagents restricted from hooks, mcpServers, permissionMode frontmatter for security
- Cross-platform CLI: `bunx @every-env/compound-plugin sync --target [platform]`
- Subagents have isolated context windows, no nesting (cannot spawn other subagents)

**TENSIONS:** Component counts vary across versions (24-29 agents, 13-21 commands, 11-16 skills).

**GAPS:** Whether plugin uses hooks/hooks.json not confirmed. Individual agent prompt content not public. .mcp.json configuration syntax not accessible.

---

## FACET: COMMUNITY_AND_ADOPTION

**SUMMARY:** Strong early adoption: 10,600+ stars, 851 forks, 43 contributors in ~5 months. Users span individual developers to engineers at Google and Amazon. Concentrated among Claude Code power users rather than mainstream teams.

**KEY_FINDINGS:**
- Stars doubled from 5,132 (Jan 2026) to 10,600+ (Mar 2026) — accelerating adoption
- Used by engineers at Google and Amazon (anecdotal)
- Kevin Rose demo achieved 192,516 views, 580 likes, 1,149 bookmarks
- Will Larson endorsed it as "a cheap, useful experiment"
- Active HN discussion with practitioners describing real workflow adaptations
- GitHub issue #63 (36k token overhead) shows engaged community reporting real friction
- Teaching/evangelism dynamic: users actively teaching others the methodology
- Cross-platform releases (Cursor marketplace, March 2026) expanding reach
- No verified Discord/Slack community found — discussion primarily on GitHub Issues and X/Twitter

**TENSIONS:** Comprehensiveness vs. usability — 36k token overhead penalizes users needing only subset. Maintainer prefers unified plugin over modular split. Productivity claims (5x) warrant independent verification.

**GAPS:** No verified install counts. No longitudinal retention data. Enterprise adoption beyond anecdotes unverified. No non-English community analysis.

---

## FACET: COMPETITORS_AND_ALTERNATIVES

**SUMMARY:** The plugin occupies a distinct niche as a structured workflow-oriented Claude Code plugin. Ranks ~#35 by plugin count but carries significant mindshare (10,475 stars). Closest competitors: feature-dev (89k installs), gstack (YC), RIPER Workflow, ContextKit. Broader competitors: Aider (40k+ stars), OpenCode (100k+ stars), Cursor, GitHub Copilot.

**KEY_FINDINGS:**
- Described as "the most complete open-source option available" for systematic AI workflows
- Differentiator: 80/20 planning-to-execution ratio vs. simpler autonomous-loop plugins
- Ralph Loop: 57,000 installs, simpler iterate-and-commit approach
- feature-dev: 89,000+ installs, 7-phase development (official)
- gstack: Garry Tan/YC, CEO-level product thinking
- RIPER Workflow: Research/Innovate/Plan/Execute/Review separation
- Cross-platform export is unique competitive advantage
- Claude Code ecosystem: 9,000+ plugins, 34,000+ skills
- Aider: 40,000+ GitHub stars, no equivalent plugin system
- OpenCode: 100,000+ GitHub stars, 75+ LLM providers, no structured workflow plugins
- Context7 (71,800 installs) and Frontend Design (96,400 installs) are complementary, not competitive
- Battle-tested across 5 production products at Every

**TENSIONS:** Workflow complexity vs. simplicity — most developers prefer lower-friction approaches. Platform lock-in debate around Anthropic model integration.

**GAPS:** No head-to-head benchmarks. No install count for compound-engineering-plugin specifically. No enterprise-scale usage data. No token-cost comparative analysis.

---

## Iteration 1: Gap Fill

### COMPOUND_STEP_MECHANICS

**SUMMARY:** The /ce:compound command runs a 3-phase orchestration: Phase 0.5 scans MEMORY.md, Phase 1 runs 5 parallel research subagents (read-only), Phase 2 assembles a single Markdown file into docs/solutions/[category]/. Retrieval is grep-based — no vector DB or semantic search. Files use YAML frontmatter validated against a schema.yaml with enum-constrained fields.

**KEY_FINDINGS:**
- 5 parallel subagents: Context Analyzer, Solution Extractor, Related Docs Finder, Prevention Strategist, Category Classifier
- File format: Markdown with YAML frontmatter (module, date, problem_type, component, symptoms, root_cause, resolution_type, severity)
- 9 category directories: build-errors/, test-failures/, runtime-errors/, performance-issues/, database-issues/, security-issues/, ui-bugs/, integration-issues/, logic-errors/
- Document body: Problem, Environment, Symptoms, "What Didn't Work", Solution (before/after code), "Why This Works", Prevention, Related Issues
- Retrieval is purely grep/lexical — findability depends on keyword quality at write time
- Auto-invoke triggers: "that worked," "it's fixed," "working now," "problem solved"
- Companion /ce:compound-refresh reviews and archives stale solutions
- Compact-safe mode for context-constrained sessions skips parallel agents
- Post-doc menu: continue, promote to critical-patterns.md, cross-link, add to skill, create new skill
- Schema is CORA-specific (Every's internal product) — enum values reference specific internal components

**CONFIDENCE:** high (6 primary sources from GitHub repo)

### EFFECTIVENESS_AND_CRITICISM

**SUMMARY:** No independent controlled study validates Compound Engineering specifically. The METR RCT found AI tools made experienced developers 19% slower (despite perceiving 20% speedup). The DORA 2024 report found 25% AI adoption increase correlated with 1.5% throughput decrease. All CE effectiveness evidence is self-reported by Every.

**KEY_FINDINGS:**
- METR RCT (16 developers, 246 tasks): AI made experienced developers 19% slower, with systematic perception bias
- METR follow-up: study likely underestimates benefits for heavy AI integrators (CE's target users)
- DORA 2024 (39k respondents): AI adoption correlated with decreased delivery throughput and stability
- Will Larson: cautiously positive, no metrics, predicted methodology absorption into tooling
- agentic-patterns.com identified 4 structural failure modes: documentation burden, prompt bloat, rule rigidity, maintenance demands
- Praxis (HN Show) built as stack-agnostic alternative due to CE being tied to Ruby/Rails
- Reddit: zero results for "compound engineering" — low penetration outside Every/Claude Code orbit
- 80/20 planning ratio is asserted as design principle with no empirical basis cited
- No longitudinal data on whether knowledge compounding actually accelerates later projects

**CONFIDENCE:** low-to-medium (no CE-specific evidence exists; surrounding landscape evidence complicates claims)
