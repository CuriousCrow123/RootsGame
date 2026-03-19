# Research: Compound Engineering Plugin on GitHub

> Researched 2026-03-19. Effort level: deep. 38+ unique sources consulted.

## Key Findings

1. **The Compound Engineering Plugin is an open-source (MIT) Claude Code plugin by Every Inc., with 10,600+ GitHub stars and 851 forks in 5 months.** Created by Dan Shipper (CEO) and Kieran Klaassen (GM of Cora) at github.com/EveryInc/compound-engineering-plugin. It operationalizes a four-step development loop — Plan, Work, Review, Compound — where each completed task generates structured knowledge that makes future tasks easier.

2. **The "Compound" step is the distinctive innovation.** When a problem is solved, the `/ce:compound` command runs 5 parallel subagents to extract the solution into a structured Markdown file (YAML frontmatter + problem/solution/prevention body) stored in `docs/solutions/`. Future agents retrieve this knowledge via grep-based search. No other major Claude Code plugin implements this self-teaching pattern.

3. **The plugin ships 29 specialized agents, 45+ skills, and 20+ slash commands.** The `/ce:review` command alone spawns 14+ parallel agents (security, performance, architecture, code simplicity, etc.) with P1/P2/P3 triage. It consumes ~36k tokens of context overhead — a known friction point.

4. **No independent evidence validates the claimed productivity gains.** Every claims 5x developer productivity, but this is self-reported. The METR RCT found AI tools made experienced developers 19% slower (despite perceiving 20% faster). The DORA 2024 report found AI adoption correlated with decreased delivery throughput. These broader findings don't invalidate CE specifically, but they establish that AI productivity perception is systematically biased.

5. **Cross-platform export is a unique competitive advantage.** A Bun/TypeScript CLI converts the plugin to work with OpenCode, Codex, Cursor, Gemini CLI, GitHub Copilot, Kiro, Windsurf, and others — making it the most platform-agnostic structured workflow tool in the space.

---

## Core Identity and Origin

### Summary
The Compound Engineering Plugin is an open-source Claude Code plugin created by Every Inc., a 15-person AI-native media and software company. CEO Dan Shipper and GM Kieran Klaassen developed the methodology while building five internal products (Cora, Spiral, Sparkle, Monologue, Every.to) — each maintained by a single developer.

### Detail
The plugin was created on GitHub on October 9, 2025, with the introducing article ["Compound Engineering: How Every Codes With Agents"](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) published December 11, 2025.

The core philosophy is stated as: **"Each unit of engineering work should make subsequent units easier — not harder."** This inverts the traditional pattern where codebases grow harder to maintain over time.

Kieran Klaassen is the primary hands-on builder, credited with developing the methodology while building Cora (an AI chief of staff/email assistant). Dan Shipper co-authored the methodology and the founding article. A [Creator Economy interview](https://creatoreconomy.so/p/how-to-make-claude-code-better-every-time-kieran-klaassen) describes Klaassen as the "favorite Claude Code power user" and notes the plugin was "embraced by the Claude Code team."

TechCrunch covered the plugin on February 24, 2026 as part of Anthropic's enterprise plugin push, and Will Larson (lethain.com) wrote an [independent analysis](https://lethain.com/everyinc-compound-engineering/) identifying the "Compound" step as the key differentiator enabling a compounding learning effect.

### Open Questions
- Exact contribution split between Shipper and Klaassen on the technical implementation
- Whether Anthropic has any formal relationship with Every or the plugin

---

## Features and Capabilities

### Summary
The plugin provides a complete AI-powered development lifecycle through 6 core commands, 29 specialized agents across 5 categories, 45+ skills, and a Context7 MCP server for framework documentation.

### Detail

**Core Workflow Commands:**
- `/ce:ideate` — Initial ideation
- `/ce:brainstorm` — Collaborative exploration of approaches
- `/ce:plan` — Structured implementation planning
- `/ce:work` — Execution with clarification-first behavior
- `/ce:review` — Multi-agent parallel code review (14+ agents, P1/P2/P3 triage)
- `/ce:compound` — Knowledge capture into docs/solutions/

**Automation Commands:**
- `/lfg` — Full autonomous pipeline from plan to PR
- `/slfg` — Swarm mode with parallel sub-agent execution
- `/deepen-plan` — Stress-tests plans with 40+ agents

**Agent Categories (29 total):**

| Category | Count | Examples |
|----------|-------|---------|
| Review | 15 | security-sentinel, performance-oracle, dhh-rails-reviewer, architecture-strategist, code-simplicity-reviewer |
| Research | 6 | best-practices-researcher, framework-docs-researcher, git-history-analyzer, learnings-researcher |
| Design | 3 | figma-design-sync, design-implementation-reviewer, design-iterator |
| Workflow | 4 | bug-reproduction-validator, lint, pr-comment-resolver, spec-flow-analyzer |
| Documentation | 1 | ankane-readme-writer |

The review agents include persona-based reviewers — `dhh-rails-reviewer` (modeled on DHH's 37signals conventions), `kieran-rails-reviewer`, `kieran-python-reviewer`, and `kieran-typescript-reviewer` — illustrating the opinionated, personality-driven nature of the system.

The plugin follows an **80/20 time allocation**: 80% on planning and review, 20% on code execution and knowledge capture.

**Known friction:** The plugin loads ~36,000 tokens of context at session start ([GitHub issue #63](https://github.com/EveryInc/compound-engineering-plugin/issues/63)), prompting community discussion about splitting into smaller focused plugins. The maintainer prefers keeping it unified.

### Open Questions
- API cost implications of running 14+ parallel review agents
- Detailed `/slfg` swarm mode architecture

---

## The Compound Step: How Knowledge Gets Captured and Reused

### Summary
The `/ce:compound` command runs a 3-phase orchestration that extracts solved problems into structured Markdown files with validated YAML frontmatter, stored in a `docs/solutions/` directory hierarchy. Retrieval is grep-based — no vector database or semantic search.

### Detail

**Orchestration phases:**
1. **Phase 0.5** — Scans MEMORY.md for relevant prior notes
2. **Phase 1** — Runs 5 parallel read-only subagents: Context Analyzer, Solution Extractor, Related Docs Finder, Prevention Strategist, Category Classifier
3. **Phase 2** — Assembles and writes exactly one file to `docs/solutions/[category]/`
4. **Phase 3** (optional) — Invokes domain-specialized review agents depending on problem type

**File format:** Markdown with YAML frontmatter validated against `schema.yaml`. Required fields include `module`, `date`, `problem_type` (13 enum values), `component` (15 enum values), `symptoms`, `root_cause` (15 enum values), `resolution_type` (10 enum values), and `severity`.

**Document body structure:** Problem → Environment → Symptoms → "What Didn't Work" (failed attempts with reasons) → Solution (before/after code) → "Why This Works" (root cause explanation) → Prevention guidance → Related Issues.

**9 category directories:** build-errors/, test-failures/, runtime-errors/, performance-issues/, database-issues/, security-issues/, ui-bugs/, integration-issues/, logic-errors/

**Auto-invoke triggers:** Natural phrases like "that worked," "it's fixed," "problem solved" trigger the command automatically.

**Retrieval:** The Related Docs Finder uses `grep -r "exact error phrase" docs/solutions/` and directory listing. No embedding-based or semantic search exists — findability depends entirely on keyword quality at write time.

**Staleness management:** A companion `/ce:compound-refresh` skill reviews existing docs against the current codebase and archives, updates, or replaces stale documents.

**Important caveat:** The schema's enum values (e.g., `brief_system`, `email_processing` as component names) are specific to Every's internal product Cora, confirming the schema was ported from an internal project rather than being a generic template.

### Open Questions
- Whether `/ce:plan` automatically searches docs/solutions/ during planning, or if retrieval is only reactive
- Whether critical-patterns.md is auto-injected into CLAUDE.md or requires manual promotion

---

## GitHub Presence

### Summary
The canonical repository is github.com/EveryInc/compound-engineering-plugin. As of March 19, 2026: 10,600+ stars, 851 forks, 82 watchers, 43 contributors, 455 commits, 45 releases. MIT license. Primarily TypeScript (81.3%).

### Detail

| Metric | Value |
|--------|-------|
| Repository | github.com/EveryInc/compound-engineering-plugin |
| Organization | EveryInc (544 GitHub followers, 27 repos) |
| Created | October 9, 2025 |
| Stars | 10,600+ |
| Forks | 851 |
| Contributors | 43 |
| Commits | 455 |
| Releases | 45 |
| License | MIT (Copyright 2025 Every) |
| Languages | TypeScript 81.3%, Python 7.9%, JS 4.2%, Ruby 3.4%, Shell 3.2% |
| NPM package | @every-env/compound-plugin |

Key contributors: **Kieran Klaassen** (primary author, "Compound Engineer - GM of Cora, Every"), **Trevin Chow** (tmchow, marketplace releases, active PR merger).

Stars doubled from ~5,132 (January 2026) to 10,600+ (March 2026), indicating accelerating adoption. Notable forks include mbiskach, 8b-is ("Not so official" variant), and hesreallyhim-forks.

### Open Questions
- Dan Shipper's GitHub username and direct commit history in the repo

---

## Architecture and Integration

### Summary
The plugin integrates through Claude Code's native plugin system with a four-layer architecture: user-facing commands → multi-agent orchestration → specialized agent workers with isolated context → skills and MCP servers for domain knowledge.

### Detail

**Installation:** `claude /plugin marketplace add EveryInc/compound-engineering-plugin`

**Plugin directory structure:**
```
plugins/compound-engineering/
├── agents/          # Markdown files with YAML frontmatter
├── commands/        # Slash command definitions
├── skills/          # SKILL.md files + references/templates/scripts
├── hooks/hooks.json # Lifecycle event handlers
└── .mcp.json        # MCP server configuration
```

**Subagents** are Markdown files declaring `name`, `description`, `model`, `tools`, `permissionMode` in YAML frontmatter. Most use `model: inherit`; the lint agent uses `model: haiku` for cost optimization. Subagents have isolated context windows and cannot nest (spawn other subagents).

**Skills** are directories with a `SKILL.md` file that activate automatically when their description matches the task context. They are injected as "Step 0: Discover and Load Skills" before agent iteration.

**MCP Server:** One active server — Context7 (HTTP transport, requires `CONTEXT7_API_KEY`) for framework documentation lookup across 100+ frameworks. Playwright MCP was deprecated in v2.25.0, replaced by the `agent-browser` CLI tool.

**Security restriction:** Plugin subagents cannot use `hooks`, `mcpServers`, or `permissionMode` frontmatter fields. To use those capabilities, agents must be copied to `.claude/agents/` or `~/.claude/agents/`.

**Cross-platform:** `bunx @every-env/compound-plugin sync --target [platform]` converts components for OpenCode, Codex, Gemini CLI, GitHub Copilot, Kiro, Windsurf, and others. Skills sync as symlinks from `~/.claude/skills/`.

### Open Questions
- Whether the plugin actively uses hooks/hooks.json
- Exact .mcp.json configuration syntax for Context7

---

## Community and Adoption

### Summary
Strong early adoption concentrated among Claude Code power users. 10,600+ stars and 851 forks in 5 months, with anecdotal usage at Google and Amazon. Kevin Rose's demo achieved 192k+ views. No verified install counts or community forums exist.

### Detail

Growth has been rapid and accelerating: stars doubled from ~5,132 (January 2026) to 10,600+ (March 2026). A Kevin Rose public demonstration achieved 192,516 views, 580 likes, and 1,149 bookmarks, driving significant viral spread beyond the core developer community.

Practitioner engagement is real but shallow: Hacker News threads show developers adapting the workflow (e.g., "brainstorm → lfg planning → clear context → work → compound"), but no dedicated community forum (Discord, Slack) exists. Discussion happens primarily on GitHub Issues and X/Twitter.

GitHub issue #63 demonstrates engaged friction reporting: users flagged the 36k token overhead, and the maintainer responded with workarounds rather than fragmentation — showing an opinionated design philosophy.

The plugin is expanding to new platforms: Cursor marketplace release on March 19, 2026, with CLI conversion supporting 12+ environments.

### Open Questions
- Actual install/download counts (GitHub stars are a proxy)
- Whether enterprise teams use it at scale beyond anecdotal reports
- Retention rates — do users stick with it long-term?

---

## Competitors and Alternatives

### Summary
The plugin ranks ~#35 by plugin count in the Claude Code ecosystem but carries outsized mindshare (10,600 stars). Its structured 80/20 planning methodology distinguishes it from simpler autonomous-loop plugins and broader AI coding tools.

### Detail

**Within Claude Code ecosystem:**

| Plugin | Installs/Stars | Approach |
|--------|---------------|----------|
| Ralph Loop | 57,000 installs | Simple iterate-and-commit |
| feature-dev (official) | 89,000+ installs | 7-phase development |
| gstack (Garry Tan/YC) | — | CEO-level product thinking |
| RIPER Workflow | — | Research/Innovate/Plan/Execute/Review |
| ContextKit | — | 4-phase planning |
| **Compound Engineering** | **10,600 stars** | **Plan/Work/Review/Compound with knowledge capture** |

The Claude Code ecosystem has grown to 9,000+ plugins with 34,000+ skills.

**Broader AI coding tools:**

| Tool | Stars/Status | Comparison |
|------|-------------|------------|
| Aider | 40,000+ stars | No plugin/workflow system; relies on model flexibility |
| OpenCode | 100,000+ stars | 75+ LLM providers; no structured workflow plugins |
| Cursor | VS Code-native | Extension marketplace; different architectural model |
| GitHub Copilot | 20+ official extensions | Enterprise-controlled, quality-curated |

Compound Engineering's unique advantages: cross-platform export CLI, knowledge compounding via docs/solutions/, and the most comprehensive open-source structured workflow offering. Its unique disadvantages: 36k token overhead, Ruby/Rails-centric schema defaults, and workflow rigidity for small tasks.

### Open Questions
- No head-to-head benchmarks exist between CE and alternatives
- Token cost comparison across structured workflow plugins

---

## Effectiveness and Independent Evidence

### Summary
All effectiveness evidence for Compound Engineering is self-reported by Every. No independent controlled study validates the methodology. Broader AI productivity research raises significant questions about self-reported claims.

### Detail

**Every's claims:** A single developer using the methodology can "do the work of five developers from a few years ago," based on running five products with single-person engineering teams.

**Independent evidence against AI productivity assumptions:**

The METR randomized controlled trial (16 experienced developers, 246 real tasks, July 2025) found AI tools made developers **19% slower** — despite those same developers believing they were **20% faster**. This perception-reality gap is directly relevant: all CE effectiveness evidence is perception-based.

However, METR's February 2026 follow-up acknowledged their study likely underestimates benefits for heavy AI integrators — precisely CE's target users. The original study's 30-50% participant refusal rate for no-AI conditions introduces selection bias.

The DORA 2024 report (39,000 respondents) found a 25% increase in AI adoption correlated with a **1.5% decrease in delivery throughput** and a **7.2% decrease in delivery stability**, even though 75% of individuals reported feeling more productive. RedMonk analyst Rachel Stephens attributed this to a Theory of Constraints problem: code generation is not the bottleneck.

**Structural failure modes identified** (agentic-patterns.com):
1. Documentation discipline burden
2. Prompt/system-prompt bloat over time
3. Rule proliferation causing agent inflexibility
4. Ongoing maintenance demands as patterns change

**Independent practitioner assessment:** Will Larson called it "a cheap, useful experiment" and predicted the practices would "get absorbed into harnesses over the next couple of months." He provided no productivity metrics or endorsement of the 5x claim.

**Stack-specificity concern:** A developer built [Praxis](https://news.ycombinator.com/item?id=47143410) (HN Show) as a stack-agnostic alternative, citing CE being "tightly tied to their project (Cora) and stack (Ruby/Rails)."

### Open Questions
- Will anyone conduct a controlled study of CE specifically?
- Does knowledge compounding actually accelerate later projects, or does prompt bloat offset gains?
- Is the 80/20 planning ratio optimal, or just asserted?

---

## Tensions and Debates

**Comprehensiveness vs. Usability:** The plugin's 36k token overhead and unified design philosophy conflict with users who need only a subset. The maintainer explicitly prefers one integrated plugin over modular pieces, while users and competitors (Praxis) push for lighter alternatives.

**Self-reported productivity vs. measured evidence:** Every claims 5x gains; METR and DORA data suggest AI productivity perception is systematically biased upward. CE's heavy planning/review emphasis might genuinely address quality bottlenecks that DORA identifies as the real constraint — but this is theorized, not measured.

**Stack generality vs. origin specificity:** The schema.yaml uses Cora-specific enums (e.g., `brief_system`, `email_processing`), and one practitioner built an alternative specifically because CE felt tied to Ruby/Rails. Yet the TypeScript CLI and cross-platform export suggest the team is actively working to generalize.

**Grep retrieval vs. semantic search:** The compound step's reliance on lexical grep means knowledge retrieval quality depends entirely on how well keywords were chosen at write time. No embedding-based search is used, which may limit the "compounding" effect at scale.

**Methodology longevity vs. absorption:** Will Larson predicted the practices would "get absorbed into harnesses" within months. If Claude Code itself adopts planning, review, and knowledge capture as native features, the plugin's value proposition may narrow.

---

## Gaps and Limitations

- **No controlled CE-specific effectiveness study exists.** All productivity claims are self-reported by a single company.
- **No install/download counts.** GitHub stars are a proxy; actual usage is unknown.
- **No longitudinal data.** Whether knowledge compounding delivers on its promise over months/years of use is untested.
- **No enterprise-scale evidence.** Usage beyond small teams and individuals is anecdotal.
- **Reddit has zero results** for "compound engineering" — penetration outside the Every/Claude Code orbit is limited.
- **The schema is Cora-specific.** Enum values reference Every's internal product components, not generic categories.
- **Per-agent prompts are not publicly documented** beyond names and brief descriptions.
- **Blocked sources:** medium.com (403 Forbidden), X/Twitter (JS-only rendering).

---

## Sources

### Most Valuable
1. [EveryInc/compound-engineering-plugin (GitHub)](https://github.com/EveryInc/compound-engineering-plugin) — The canonical source for all technical details, stats, and architecture
2. [Compound Engineering: How Every Codes With Agents (every.to)](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) — The founding article explaining the methodology and its origin
3. [METR AI Productivity RCT](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) — The only rigorous controlled study of AI coding productivity
4. [Learning from Every's Compound Engineering (lethain.com)](https://lethain.com/everyinc-compound-engineering/) — The most credible independent analysis
5. [Claude Code Plugins Reference (code.claude.com)](https://code.claude.com/docs/en/plugins-reference) — Official docs explaining how the plugin system works
6. [Compound Engineering Guide (every.to)](https://every.to/guides/compound-engineering) — Detailed workflow guide with agent roles and system architecture
7. [DORA 2024 Report Analysis (RedMonk)](https://redmonk.com/rstephens/2024/11/26/dora2024/) — Industry-scale data on AI adoption vs. delivery metrics
8. [DeepWiki: compound-engineering-plugin](https://deepwiki.com/kieranklaassen/compound-engineering-plugin) — Automated architectural analysis with component distribution details

### Full Source List

| Source | Facet | Type | Date | Key contribution |
|--------|-------|------|------|-----------------|
| [GitHub: EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) | All | Primary repo | Active 2026 | Canonical source for stats, features, installation |
| [Compound Engineering: How Every Codes With Agents](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) | Core, Features | Founder article | Dec 2025 | Origin story, methodology, 80/20 philosophy |
| [Compound Engineering Guide](https://every.to/guides/compound-engineering) | Core, Features | Official guide | Jan 2026 | Detailed workflow, agent roles, system files |
| [Compound Engineering: The Definitive Guide](https://every.to/source-code/compound-engineering-the-definitive-guide) | Core | Practitioner article | Feb 2026 | Credits Klaassen, 7k stars at time of writing |
| [Learning from Every's CE (lethain.com)](https://lethain.com/everyinc-compound-engineering/) | Core, Effectiveness | Independent blog | 2025-26 | Credible external analysis, absorption prediction |
| [Inside Every (Lenny's Newsletter)](https://www.lennysnewsletter.com/p/inside-every-dan-shipper) | Core | Journalism | 2025-26 | Profiles Every as 15-person AI-native company |
| [Kieran Klaassen interview (Creator Economy)](https://creatoreconomy.so/p/how-to-make-claude-code-better-every-time-kieran-klaassen) | Core, Features | Interview | 2025-26 | /lfg details, "embraced by Claude Code team" |
| [Plugin README (GitHub)](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/README.md) | Features, Architecture | Documentation | Active 2026 | Full agent/skill/command reference |
| [Claude Code Sub-agents docs](https://code.claude.com/docs/en/sub-agents) | Architecture | Official docs | 2026 | Subagent frontmatter, isolation, restrictions |
| [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) | Architecture | Official docs | 2026 | Plugin system schema, directory structure |
| [DeepWiki analysis](https://deepwiki.com/kieranklaassen/compound-engineering-plugin) | Architecture, Features | Auto-generated wiki | 2026 | 4-layer architecture, component distribution |
| [Claude Plugin Hub listing](https://www.claudepluginhub.com/plugins/everyinc-compound-engineering-plugins-compound-engineering-3) | Features | Third-party directory | 2026 | 29-agent inventory with categories |
| [GitHub: EveryInc org](https://github.com/EveryInc) | GitHub | Primary source | 2026 | Organization profile, 544 followers, 27 repos |
| [GitHub: kieranklaassen](https://github.com/kieranklaassen) | GitHub | Primary source | 2026 | "Compound Engineer - GM of Cora, Every" |
| [GitHub: LICENSE](https://github.com/EveryInc/compound-engineering-plugin/blob/main/LICENSE) | GitHub | Primary source | 2025 | MIT license, Copyright Every |
| [GitHub: Releases](https://github.com/EveryInc/compound-engineering-plugin/releases) | GitHub | Primary source | 2026 | 45 releases, tmchow as release author |
| [GitHub: Activity](https://github.com/EveryInc/compound-engineering-plugin/activity) | GitHub | Primary source | 2026 | Daily commits, active PR merging |
| [GitHub Issue #63](https://github.com/EveryInc/compound-engineering-plugin/issues/63) | Community | Community feedback | Dec 2025 | 36k token overhead, modularity debate |
| [METR RCT Study](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) | Effectiveness | RCT research | Jul 2025 | 19% slowdown, perception bias documented |
| [METR Design Update](https://metr.org/blog/2026-02-24-uplift-update/) | Effectiveness | Research update | Feb 2026 | Selection bias, underestimation for heavy users |
| [METR Study participation (domenic.me)](https://domenic.me/metr-ai-productivity/) | Effectiveness | Participant account | 2025 | Pattern-adoption failure, context degradation |
| [DORA 2024 (RedMonk)](https://redmonk.com/rstephens/2024/11/26/dora2024/) | Effectiveness | Analyst report | Nov 2024 | AI adoption vs. delivery throughput/stability |
| [Compounding Engineering Pattern (agentic-patterns.com)](https://www.agentic-patterns.com/patterns/compounding-engineering-pattern/) | Effectiveness | Pattern documentation | 2025 | 4 structural failure modes identified |
| [Acceleration and CE (spletzer.com)](https://www.spletzer.com/2026/02/a-tale-of-acceleration-and-compound-engineering/) | Effectiveness | Practitioner blog | Feb 2026 | Anecdotal speed gains, measurement caveats |
| [Praxis (HN Show)](https://news.ycombinator.com/item?id=47143410) | Effectiveness | HN submission | 2026 | Stack-agnostic alternative, generalizability concern |
| [HN thread: compound engineering](https://news.ycombinator.com/item?id=46752095) | Community | Forum discussion | 2026 | Practitioner workflow adaptations |
| [CE Reading List (torqsoftware.com)](https://reading.torqsoftware.com/notes/software/ai-ml/agentic-coding/2026-01-19-compound-engineering-claude-code/) | Community | Aggregator | Jan 2026 | Kevin Rose demo metrics, star growth tracking |
| [Ry Walker Research](https://rywalker.com/research/compound-engineering-plugin) | Competitors | Independent analysis | 2026 | "Most complete open-source option," limitations |
| [awesome-claude-code (GitHub)](https://github.com/hesreallyhim/awesome-claude-code) | Competitors | Community curation | 2026 | Competing workflow frameworks listed |
| [awesome-claude-plugins (GitHub)](https://github.com/quemsah/awesome-claude-plugins) | Competitors | Analytics repo | 2026 | Rank #35 by plugin count |
| [Top Claude Code Plugins (firecrawl.dev)](https://www.firecrawl.dev/blog/best-claude-code-plugins) | Competitors | Commercial roundup | 2026 | Install counts for Ralph Loop, Context7, etc. |
| [Claude Code vs Cursor vs Copilot (adventureppc.com)](https://www.adventureppc.com/blog/claude-code-vs-cursor-vs-github-copilot-the-definitive-ai-coding-tool-comparison-for-2026) | Competitors | Comparison article | 2026 | Platform-level ecosystem comparison |
| [GitHub Copilot vs Claude Code (aiskill.market)](https://aiskill.market/blog/github-copilot-vs-claude-code) | Competitors | Industry blog | 2026 | Curated vs. open extension model architectures |
| [alexop.dev: Claude Code Full Stack](https://alexop.dev/posts/understanding-claude-code-full-stack/) | Architecture | Technical blog | 2026 | Integration pattern overview |
| [Colin McNamara: Skills, Agents, MCP](https://colinmcnamara.com/blog/understanding-skills-agents-and-mcp-in-claude-code) | Architecture | Technical blog | 2026 | Decision framework for extension types |
| [Uncharted: AI Agents + CE](https://www.thisisuncharted.co/p/ai-agents-100x-engineers-every) | Community | Newsletter | 2026 | Organizational adoption gap analysis |
| [Anthropic Agentic Coding Trends 2026](https://www.libertify.com/interactive-library/agentic-coding-trends-2026-anthropic-report/) | Effectiveness | Vendor report | 2026 | Enterprise case studies, "27% additionality" metric |
| [ce-compound SKILL.md (GitHub)](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/ce-compound/SKILL.md) | Compound Mechanics | Primary source | 2026 | Full orchestration logic, phase sequence |
| [compound-docs SKILL.md (GitHub)](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/compound-docs/SKILL.md) | Compound Mechanics | Primary source | 2026 | Documentation process, grep retrieval, validation |
| [compound-docs schema.yaml (GitHub)](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/compound-docs/schema.yaml) | Compound Mechanics | Primary source | 2026 | YAML frontmatter schema, enum values |
| [resolution-template.md (GitHub)](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/compound-docs/assets/resolution-template.md) | Compound Mechanics | Primary source | 2026 | Document body structure template |
