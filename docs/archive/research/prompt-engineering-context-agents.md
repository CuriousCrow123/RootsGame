# Research: Best Practices for Prompt Engineering, Context Window Management, Claude Agent/Orchestration, Tools/Skills/Commands

> Researched 2026-03-18. Effort level: deep. 63 unique sources consulted.

## Key Findings

1. **Clarity beats cleverness.** Across every source — Anthropic, OpenAI, academic surveys of 1,500+ papers — the #1 prompt engineering principle is specificity: explain what you want, why you want it, and what format to use. Modern Claude models (4.6) need *less* aggressive prompting than their predecessors; if your prompts used to say "CRITICAL: You MUST...", dial it back.

2. **Context is a budget, not a bucket.** More tokens does not mean better output. Place documents at the top and queries at the bottom (up to 30% quality improvement). Simple observation masking (replacing old tool outputs with placeholders) matches or beats LLM summarization at 50%+ cost savings, and summarization can actually *hurt* agent performance by obscuring stopping signals.

3. **Start simple, add agents only when the value exceeds 15x token cost.** Anthropic's own multi-agent system outperformed single-agent by 90.2%, but used 15x more tokens than chat. The recommended path: direct API calls → composable workflows → orchestrator-workers → full multi-agent, with each step justified by measured improvement.

4. **Tool descriptions are the single most important factor in tool performance.** Write 3-4 sentences minimum per tool. The Tool Search Tool pattern reduces token consumption by 85% by deferring unused tools. Consolidate related operations into single tools with an `action` parameter rather than proliferating specialized tools.

5. **Agentic reliability compounds multiplicatively.** A 10-step process at 99% per-step reliability yields only ~90% end-to-end success. The fix is layered: retries with backoff for transient errors, self-healing validation (feed structured errors back to the LLM), propose-commit patterns for irreversible actions, and post-action state verification.

---

## Prompt Engineering

### Summary
The field has converged on a core set of principles: be direct, use few-shot examples with chain-of-thought reasoning, structure with XML tags or clear delimiters, explain the *why* behind instructions, and iterate systematically. The Prompt Report (Schulhoff et al., 2024) cataloged 58 distinct text-based techniques from 1,500+ papers, but the consistently top-performing approach remains Few-Shot Chain-of-Thought.

### Detail
**Core principles (Anthropic official guidance):**
- Treat Claude like "a brilliant but new employee who lacks context." The golden rule: if a colleague with minimal context would be confused by your prompt, Claude will be too.
- Use XML tags (`<instructions>`, `<context>`, `<example>`) to separate content types. This "significantly reduces misinterpretation," though the Anthropic blog notes tags are "less necessary" for the latest models that handle structure through headings and whitespace.
- Tell the model what TO do, not what NOT to do. Instead of "Do not use markdown," say "Your response should be composed of smoothly flowing prose paragraphs."
- Explain WHY, not just WHAT. Instead of "NEVER use ellipses," say "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the engine won't know how to pronounce them." Claude generalizes from the explanation.
- Provide 3-5 few-shot examples for best results.

**Chain-of-Thought (CoT):**
Few-shot CoT (Wei et al., 2022) "consistently delivered superior results" across benchmarks. Zero-shot CoT ("Let's think step by step" — Kojima et al., 2022) activates reasoning without examples but is less reliable. For modern reasoning models (o1, o3), do *not* tell them to "think step by step" — they do this internally and the extra instruction can interfere.

**Modern model adjustments:**
Claude 4.6 guidance explicitly warns: "If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger." Dial back aggressive language. The best prompt "isn't the longest or most complex — it's the one that achieves your goals reliably with the minimum necessary structure."

**Automated optimization:**
DSPy generated superior prompts in 10 minutes compared to 20 hours of manual engineering, achieving higher F1 scores. Arize found prompt optimization yielded 5.19% improvement on cross-repository coding tasks and 10.87% on within-repository tasks. Repository-specific optimization is "a practical superpower."

**Prompt compression:**
Removing soft phrasing ("could you," "please"), converting to labeled directives, and abstracting repeating patterns can save 50-65% of tokens with no quality loss.

**Prompt testing and CI/CD (gap-fill):**
Production prompt management now has dedicated tooling. The standard workflow: store prompts in version control with SemVer (MAJOR for output format changes, MINOR for new capabilities, PATCH for fixes), trigger automated evals on prompt file changes in PRs, run against a "golden dataset" of 10-20+ curated input/output pairs, score with LLM-as-a-Judge rubrics, and fail the build if quality regresses. Key tools: Promptfoo (open-source, MIT, acquired by OpenAI March 2026), Braintrust, Langfuse (self-hostable), Arize Phoenix. Pin dated model snapshots for reproducibility, use feature flags for A/B testing with 10% cohorts before full rollout.

### Open Questions
- Quantified benchmarks comparing XML tags vs. markdown vs. plain text on Claude 4.6 specifically are not publicly available.
- Cross-model prompt portability (how well prompts optimized for Claude transfer to GPT or Gemini) lacks systematic study.
- Prompt engineering for multimodal inputs (images, video, audio) has sparse guidance beyond basics.

---

## Context Window Management

### Summary
Effective context management treats the window as a finite resource with diminishing returns. The "lost in the middle" problem is real but evolving — newer models show improved but not eliminated positional sensitivity. The four core strategies are compaction, structured note-taking, sub-agent isolation, and just-in-time retrieval.

### Detail
**Positional effects:**
Liu et al. (Stanford/ACL 2024) found 30%+ performance degradation when relevant information is in the middle of the context. Anthropic's own testing shows placing documents at the top with queries at the bottom improves quality by up to 30%. Chroma Research (2025, 18 models tested) found a surprising result: shuffled haystacks consistently improved retrieval performance over logically ordered ones, suggesting models rely on *distinctiveness* more than coherence. Claude models exhibited the "lowest hallucination rates" among tested models, tending to abstain when uncertain.

**Compaction strategies:**
- JetBrains Research found observation masking (replacing old tool outputs with placeholders) "often matched or even slightly beat LLM summarization" while achieving "over 50% cost savings." Summarization unexpectedly caused agents to run 13-15% longer by obscuring stopping signals.
- Hierarchical compression: recent exchanges verbatim, older content compressed into summaries, can reduce usage by up to 80%.
- Claude Sonnet 4.6/4.5 have built-in context awareness — they receive their token budget at conversation start and usage updates after each tool call.

**Token budget allocation:**
| Segment | Allocation |
|---------|-----------|
| System Instructions | 10-15% |
| Tool Context | 15-20% |
| Knowledge Context | 30-40% |
| History Context | 20-30% |
| Buffer Reserve | 10-15% |

**Prompt caching:**
Up to 90% cost reduction and 85% latency reduction. Cached token reads cost only 10% of base input token price. Effective for system prompts, tool definitions, and frequently-referenced documents.

**RAG vs. long context:**
These are complementary, not competing. Both produce identical answers for ~60% of questions. RAG excels at precise factual retrieval with source attribution (~1 second per query). Long context excels at full-document reasoning (30-60 seconds). The hybrid approach: RAG for most queries, long context for complex multi-document reasoning.

**When to start fresh:**
Anthropic advises that sometimes "starting with a brand new context window rather than using compaction" is better, since the latest models can rediscover state from the filesystem using git logs, progress files, and test state. Ask Claude to "quote relevant parts of the documents first before carrying out its task" — this cuts through noise in long-context scenarios.

### Open Questions
- Specific performance degradation curves for Claude's 1M token window (accuracy at 200K vs. 500K vs. 900K) are not publicly benchmarked.
- Optimal compaction trigger point (percentage of window fullness) has no industry consensus.
- Context management for multimodal inputs in large windows is under-studied.

---

## Claude Agent Orchestration

### Summary
Anthropic advocates composable workflow patterns over autonomous multi-agent systems, with the orchestrator-worker pattern as the go-to for complex tasks. The Claude Agent SDK supports native subagent models, and Claude Code offers both lightweight subagents and full agent teams. Detailed task delegation is essential — vague instructions cause duplication and gaps.

### Detail
**The simplicity principle:**
"Find the simplest solution possible, and only increase complexity when needed." Workflows (predefined code paths) should be preferred over agents (dynamic LLM-directed processes) unless flexibility is genuinely required. Frameworks "often create extra layers of abstraction that obscure the underlying prompts and responses."

**Six composable workflow patterns:**
1. **Prompt chaining** — sequential steps, each output feeding the next
2. **Routing** — classify input, route to specialized handler
3. **Parallelization** — section tasks or vote across parallel runs
4. **Orchestrator-workers** — dynamic task decomposition with delegated execution
5. **Evaluator-optimizer** — generate, evaluate against criteria, refine
6. **Autonomous agents** — open-ended, model-directed loops

**Token economics:**
| Mode | Token Multiplier |
|------|-----------------|
| Chat | 1x |
| Single Agent | ~4x |
| Multi-Agent | ~15x |

Multi-agent Opus 4 + Sonnet 4 subagents outperformed single-agent Opus 4 by 90.2% on internal research evaluation. But the 15x cost means multi-agent is justified only when task value exceeds the cost.

**Task delegation:**
Vague instructions like "research semiconductor shortage" caused agents to duplicate work and leave gaps. Lead agents must provide: explicit objectives, output formats, tool/source guidance, and clear task boundaries. Effort scaling rules should be embedded: simple fact-finding = 1 agent with 3-10 tool calls; comparisons = 2-4 subagents; complex research = 10+ subagents.

**Claude Agent SDK:**
Subagents get their own description, system prompt, restricted tool access, and optionally a different (cheaper) model. They use isolated context windows and return only relevant information to the orchestrator. This protects the orchestrator's context from pollution.

**Claude Code multi-agent:**
- **Subagents**: Lightweight, run within a single session, report results back only to the caller. Built-in types: Explore (Haiku, read-only), Plan (inherits model, read-only), general-purpose (all tools).
- **Agent teams** (experimental): Full independent sessions with inter-agent messaging, shared task lists, self-coordination. Recommended: 3-5 teammates, 5-6 tasks each. Beyond that, coordination overhead increases.

**Builder-validator pattern:**
Pair a builder agent with an independent validator, since "an agent that builds code can't objectively review its own output as it has the same blind spots that created bugs."

**Parallelism gains:**
Parallel subagent spawning (3-5 simultaneously) plus parallel tool calls (3+ per subagent) reduced research time by up to 90% for complex queries. Tool-testing agents that rewrote flawed descriptions reduced task completion time by 40%.

### Open Questions
- Cost optimization strategies for multi-agent systems beyond "use cheaper models for subagents" are underdeveloped.
- Security considerations for agent-to-agent trust and permission escalation across agent boundaries are lightly covered.
- Coding tasks are identified as poor candidates for multi-agent unless modules have clear file-ownership boundaries.

---

## Tool Use, Function Calling, and MCP

### Summary
Tool descriptions are "by far the most important factor in tool performance." MCP (Model Context Protocol) provides the standardized open protocol for connecting Claude to external services. Production systems require defensive design with strict schemas, error recovery, and deferred tool loading to manage context efficiently.

### Detail
**Tool description best practices:**
- Write at least 3-4 sentences: what the tool does, when to use it (and when not to), what each parameter means, and important caveats.
- Consolidate related operations into a single tool with an `action` parameter (e.g., one `github_pr` tool instead of `create_pr`, `review_pr`, `merge_pr`).
- Return semantic, stable identifiers (slugs/UUIDs) rather than opaque internal references.
- Include only fields Claude needs to reason about its next step — bloated responses waste context.
- ACL 2025 research (MIT CSAIL, PLAY2PROMPT) found that iteratively optimizing descriptions from execution feedback substantially improves performance vs. static descriptions.

**Tool quantity:**
Accuracy degrades predictably with tool count. Limit to 5-10 most relevant tools per query. The Tool Search Tool pattern addresses this: keep 3-5 most-used tools always loaded, defer the rest. This reduces token consumption by 85% and preserves 95% of context.

**Advanced patterns:**
- **Programmatic Tool Calling**: Claude writes Python to orchestrate tools, yielding 37% token reduction and eliminating 19+ inference passes for 20+ tool workflows.
- **Structured Outputs** (`strict: true`): Guarantees schema conformance, eliminating type mismatches. Recommended for production. However, ACL 2025 research found restrictive schemas can "significantly degrade model performance" by diverting probability mass toward syntax control — use selectively.
- **Parallel tool use**: Explicitly instruct in the system prompt: "Whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially."

**MCP architecture:**
Three core primitives with distinct control semantics:
| Primitive | Control | Purpose |
|-----------|---------|---------|
| Tools | Model-controlled | Executable actions |
| Resources | App-controlled | Read-only data |
| Prompts | User-controlled | Reusable instruction templates |

Client-server architecture: one MCP client per MCP server. Local servers use STDIO transport; remote servers use Streamable HTTP with OAuth 2.1 authentication (mandated June 2025 spec update). Additional primitives: Elicitation (servers request missing info from users), Sampling (servers request LLM completions through the client).

**Error handling:**
- Parse all tool outputs for success/error status
- Feed error messages back to the model for retries (max 3 attempts)
- Never silently swallow execution failures
- Implement ALLOW/DENY/REQUIRE_APPROVAL gates independent of model judgment
- Tool result blocks must come FIRST in user message content arrays (before text), or the API returns 400

### Open Questions
- Optimal tool description length and format lack quantitative benchmarks across model sizes.
- MCP tool versioning and breaking-change handling for production systems with many connected clients is undocumented.
- Cost/latency tradeoffs between native API tools vs. MCP vs. programmatic tool calling at scale lack published data.

---

## Claude Code: Skills, Commands, and Configuration

### Summary
Claude Code provides layered extensibility through skills (markdown-based instruction files with YAML frontmatter), hooks (27 lifecycle event handlers), subagents (isolated specialized workers), and a hierarchical CLAUDE.md configuration system. Skills follow the open Agent Skills standard (agentskills.io), enabling cross-tool compatibility with Cursor, Gemini CLI, Codex CLI, and others.

### Detail
**Skills (the modern format):**
- Custom commands (`.claude/commands/`) and skills (`.claude/skills/<name>/SKILL.md`) are now unified — skills are recommended because they support frontmatter, supporting files, and autonomous invocation.
- Key frontmatter options:
  - `disable-model-invocation: true` — prevents Claude from auto-triggering (use for deploy, commit, send-message)
  - `user-invocable: false` — hides from `/` menu but allows autonomous loading as background knowledge
  - `context: fork` — runs in isolated context window
- `!`command`` syntax runs shell commands before skill content is sent, enabling dynamic injection of PR diffs, git status, or API data.
- Keep SKILL.md under 500 lines; move reference material to supporting files within the skill directory.
- Skill description budget: 2% of context window with 16K character fallback. Run `/context` to check for warnings about excluded skills.
- Five bundled skills: `/batch` (parallel changes across worktrees), `/simplify` (three parallel review agents), `/loop` (recurring execution), `/debug`, `/claude-api`.

**Agent Skills standard:**
Skills follow the agentskills.io open standard. As of March 2026, the same SKILL.md files work across Claude Code, Cursor, Gemini CLI, Codex CLI, and Antigravity IDE.

**Hooks (lifecycle events):**
27 events including `PreToolUse` (the only one that can block actions), `PostToolUse`, `SessionStart`, `Stop`, `SubagentStart/Stop`, `UserPromptSubmit`, `ConfigChange`. Four handler types: command (shell), HTTP (remote endpoint), prompt (single-turn LLM), agent (spawns subagent).

**Subagents:**
- Built-in: Explore (Haiku, read-only), Plan (inherits model, read-only), general-purpose (all tools)
- Custom: defined as markdown in `.claude/agents/` or `~/.claude/agents/`
- Support: tool restrictions, model selection, permission modes, persistent memory (MEMORY.md), MCP server scoping, git worktree isolation

**CLAUDE.md hierarchy:**
Global (`~/.claude/CLAUDE.md`) → project root (`./CLAUDE.md`) → subdirectory CLAUDE.md files, most specific wins. Supports `@include` for modular organization. Can be refreshed mid-session with `#`.

**Settings hierarchy:**
User (`~/.claude/settings.json`) → project (`.claude/settings.json`) → local (`.claude/settings.local.json`) for permissions, hooks, model selection, and token limits.

### Open Questions
- Performance implications of many skills loaded simultaneously are not benchmarked beyond the context budget mechanism.
- The agentskills.io cross-tool compatibility claims lack detailed technical documentation on edge cases.
- Testing and debugging workflows for custom skills have no structured guidance.

---

## Agentic Patterns and Reliability

### Summary
Reliable agentic systems require layered defense: composable patterns, structured error handling with classification, multi-level guardrails, human-in-the-loop checkpoints, and post-action verification. Research on 150+ multi-agent execution traces identified 14 failure modes and concluded that "improvements in base model capabilities will be insufficient" to fix systemic issues.

### Detail
**Compounding failure rates:**
A 10-step process at 99% per-step reliability yields only ~90.4% end-to-end success. This makes individual step reliability paramount and argues for shorter agent loops with verification checkpoints.

**14 failure modes (arxiv 2503.13657, 150+ traces):**
Three categories:
1. **Specification/design**: task violations, step repetition, lost context, unaware of termination
2. **Inter-agent misalignment**: conversation resets, task derailment, ignored input
3. **Verification/termination**: premature termination, incomplete verification

**Error handling layers:**
| Layer | Pattern | When to Use |
|-------|---------|-------------|
| Retries | Exponential backoff + jitter | Transient failures (rate limits, timeouts) |
| Circuit breakers | Remove failing providers after threshold | Persistent provider failures |
| Fallback chains | Route to secondary models/providers | Primary unavailable |
| Self-healing validation | Feed structured errors back to LLM | Schema/format violations |

Classify errors into three types: *repairable* (LLM self-corrects), *transient* (auto-retry), *fatal* (log and propagate). This prevents wasting retries on non-retriable failures. The Instructor library implements self-healing: 2-3 attempts for validation errors, 5 for rate limits.

**Guardrail architecture:**
Three-layer pipeline:
1. **Input guardrails** — validate/filter prompts before model
2. **Processing guardrails** — control context/tools/data access
3. **Output guardrails** — validate responses before returning

OpenAI's Agents SDK implements "tripwire" patterns that immediately halt execution on violations. Tension: running guardrails in parallel saves latency but risks token consumption before a guardrail can halt; blocking mode is safer but slower.

**Human-in-the-loop:**
The **propose-commit pattern**: hard separation between proposing (storing a structured action payload for review) and committing (executing with idempotency keys, precondition validation, post-action verification). Place checkpoints before irreversible, costly, regulated, or high-blast-radius actions. The emerging "human-on-the-loop" paradigm (monitoring rather than approving) suits lower-risk operations.

**Tool design for reliability ("Poka-yoke"):**
Make mistakes harder. Example: requiring absolute file paths instead of relative ones made a model use the method "flawlessly." Post-action state verification: assert that expected changes actually occurred after each step (e.g., verify a file exists after creation).

**Loop termination:**
Maximum iteration counts, designated verifier agents that can terminate conversations, and loop-detection that flags circular/non-progressing patterns.

**Long-running agent reliability (gap-fill):**
Three architectural pillars for multi-hour/multi-day operation:
1. **Durable execution** (Temporal, Restate): persist each step's outcome, resume from checkpoints after failures. Restate implements crash-proof timeouts and compensation patterns that "automatically undo previous actions when later steps fail."
2. **Tiered memory** (Letta/MemGPT pattern): in-context memory (persistent blocks), external memory (auto-recalled history), archival storage. Memory must be "a fundamental part" of agent architecture, not an add-on.
3. **Progress-tracking ledgers** (Microsoft Magentic-One): Task Ledger (outer loop: facts, guesses, plans) and Progress Ledger (inner loop: per-agent assignments) with automatic re-planning when agents stall for more than 2 iterations.

**Industry state (LangChain survey, n=1,340):**
- 89% have observability implemented
- Quality is #1 production blocker (32%)
- 62% have detailed tracing for multi-step reasoning
- Evaluation: hybrid human review (59.8%) + LLM-as-judge (53.3%)
- Only 52% have offline evals, 37% online evals — testing standards are nascent

### Open Questions
- Quantitative benchmarks for how much each reliability pattern improves end-to-end success rates are scarce.
- Recovery from partial completion (rolling back side effects of a failed multi-step agent) has limited practical guidance.
- Cost-reliability tradeoff optimization lacks published data.

---

## Tensions and Debates

### Simplicity vs. Multi-Agent Power
Anthropic strongly advocates starting simple, yet their own research system demonstrates 90.2% improvement from multi-agent orchestration. Resolution: multi-agent is justified only when task value exceeds the ~15x token cost. Most tasks should use composable workflows, not autonomous agents.

### XML Tags and Structured Prompting vs. Natural Language
Anthropic's API docs recommend XML tags; their blog says they're "less necessary" for newer models. The trend is toward less rigid formatting as models improve, but structured prompts remain valuable for complex, multi-document inputs and for ensuring consistent parsing.

### RAG vs. Long Context
Not actually competing. Both produce identical answers for ~60% of questions. RAG wins on cost and latency (~1s vs 30-60s). Long context wins on cross-document reasoning. The pragmatic answer is a hybrid approach.

### Strict Schema Validation vs. Reasoning Quality
`strict: true` guarantees conformance but ACL 2025 research found restrictive schemas can "significantly degrade model performance." Resolution: use strict mode for high-stakes tools where format matters; allow flexibility for reasoning-heavy tasks.

### Summarization vs. Observation Masking for Context Management
JetBrains found masking matched or beat summarization at 50%+ cost savings, with summarization actually *hurting* agent performance by obscuring stopping signals. This challenges the common assumption that intelligent summarization is always superior.

### Frameworks vs. Raw API Calls
Anthropic recommends raw APIs for transparency. CrewAI claims 40% faster time-to-production. The tension is real: frameworks add value for standard patterns but obscure debugging for novel ones. Start raw, adopt a framework only when the pattern stabilizes.

---

## Gaps and Limitations

**Topics with sparse coverage:**
- Quantified benchmarks for Claude 4.6's 1M token window degradation curves
- Cross-model prompt portability studies
- Security patterns for multi-agent trust boundaries
- Multimodal prompt engineering beyond basics
- Cost-reliability tradeoff optimization with published data

**Recency concerns:**
- The Prompt Report (Schulhoff et al.) is from 2024 and predates Claude 4.6 and GPT-5
- MCP ecosystem best practices are still crystallizing after the June 2025 spec update
- Agent Skills standard (agentskills.io) adoption data is limited

**Perspective gaps:**
- Most sources are from tool/platform vendors (Anthropic, OpenAI, LangChain) with inherent bias toward their approaches
- Independent academic evaluation of production agent architectures is limited
- End-user (non-developer) perspectives on agent reliability are absent

---

## Sources

### Most Valuable
1. **[Anthropic — Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)** — The foundational reference for agent architecture: simplicity principle, six composable patterns, workflow vs. agent distinction
2. **[Anthropic — Claude API Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)** — Comprehensive, model-specific prompt engineering reference covering all techniques
3. **[Anthropic Engineering — Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)** — Detailed case study with token economics (4x/15x multipliers), parallelism gains (90%), and delegation lessons
4. **[Anthropic Engineering — Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)** — The four-strategy framework for context management with practical patterns
5. **[The Prompt Report (Schulhoff et al.)](https://arxiv.org/abs/2406.06608)** — Systematic survey of 58 prompting techniques from 1,500+ papers by 32 researchers
6. **[Anthropic — Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use)** — Tool Search Tool (85% token savings), Programmatic Tool Calling (37% reduction), with benchmark data
7. **[arxiv 2503.13657 — Why Do Multi-Agent LLM Systems Fail?](https://arxiv.org/html/2503.13657v1)** — Taxonomy of 14 failure modes from 150+ execution traces
8. **[Claude Code — Skills Documentation](https://code.claude.com/docs/en/skills)** — Complete reference for the modern extensibility system

### Full Source List

| Source | Facet | Type | Key contribution |
|--------|-------|------|-----------------|
| [Anthropic Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) | Prompt Engineering | Documentation | Comprehensive prompt engineering reference for Claude 4.6 |
| [Anthropic Blog — Prompt Engineering](https://claude.com/blog/best-practices-for-prompt-engineering) | Prompt Engineering | Blog | Practical guide emphasizing simplicity |
| [Lakera — Prompt Engineering Guide](https://www.lakera.ai/blog/prompt-engineering-guide) | Prompt Engineering | Industry | 9+ techniques including compression and model-specific guidance |
| [The Prompt Report](https://learnprompting.org/blog/the_prompt_report) | Prompt Engineering | Academic summary | 58 techniques from 1,500+ papers |
| [DAIR.AI — CoT Prompting](https://www.promptingguide.ai/techniques/cot) | Prompt Engineering | Academic | CoT variants reference |
| [DAIR.AI — Prompt Engineering Guide](https://www.promptingguide.ai/) | Prompt Engineering | Academic | 13+ technique categories |
| [Arize — CLAUDE.md Optimization](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning) | Prompt Engineering | Research | 5-11% accuracy improvements from prompt optimization |
| [Schulhoff et al. (arxiv)](https://arxiv.org/abs/2406.06608) | Prompt Engineering | Academic | Original 80-page survey paper |
| [Anthropic — Context Windows](https://platform.claude.com/docs/en/build-with-claude/context-windows) | Context | Documentation | Context mechanics, awareness, compaction |
| [Anthropic — Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Context | Engineering | Four-strategy framework for agent context |
| [Anthropic — Long Context Tips](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/long-context-tips) | Context | Documentation | Document placement, XML structuring |
| [Anthropic — Prompt Caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) | Context | Documentation | 90% cost reduction, 85% latency reduction |
| [Chroma — Context Rot](https://research.trychroma.com/context-rot) | Context | Research | 18-model study on context degradation |
| [Liu et al. — Lost in the Middle](https://arxiv.org/abs/2307.03172) | Context | Academic | 30%+ middle-position degradation |
| [JetBrains — Context Management](https://blog.jetbrains.com/research/2025/12/efficient-context-management/) | Context | Research | Masking vs. summarization comparison |
| [Maxim AI — Context Strategies](https://www.getmaxim.ai/articles/context-window-management-strategies-for-long-context-ai-agents-and-chatbots/) | Context | Industry | Selective injection, compression techniques |
| [Redis — RAG vs Long Context](https://redis.io/blog/rag-vs-large-context-window-ai-apps/) | Context | Industry | Quantitative RAG vs. long context comparison |
| [Anthropic — Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) | Orchestration | Research | Six composable patterns, simplicity principle |
| [Anthropic — Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system) | Orchestration | Engineering | 90.2% improvement, 15x token cost, parallelism |
| [Claude Agent SDK](https://platform.claude.com/docs/en/agent-sdk/overview) | Orchestration | Documentation | SDK capabilities, subagent model |
| [Claude Code — Agent Teams](https://code.claude.com/docs/en/agent-teams) | Orchestration | Documentation | Team architecture, best practices |
| [Claude Code — Subagents](https://code.claude.com/docs/en/sub-agents) | Orchestration | Documentation | Configuration, patterns, memory |
| [Anthropic — Agent SDK Blog](https://claude.com/blog/building-agents-with-the-claude-agent-sdk) | Orchestration | Blog | Design philosophy, context management |
| [claudefa.st — Team Orchestration](https://claudefa.st/blog/guide/agents/team-orchestration) | Orchestration | Community | Builder-validator patterns |
| [DEV Community — Task Tool](https://dev.to/bhaidar/the-task-tool-claude-codes-agent-orchestration-system-4bf2) | Orchestration | Community | Task tool execution modes |
| [Anthropic — Tool Use Overview](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview) | Tool Use | Documentation | Schema definitions, parallel tool use |
| [Anthropic — Implement Tool Use](https://platform.claude.com/docs/en/agents-and-tools/tool-use/implement-tool-use) | Tool Use | Documentation | Description best practices, error handling |
| [Anthropic — Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use) | Tool Use | Engineering | Tool Search Tool, Programmatic Tool Calling |
| [MCP Architecture](https://modelcontextprotocol.io/docs/learn/architecture) | Tool Use | Specification | Client-server model, primitives, transports |
| [WorkOS — MCP Features](https://workos.com/blog/mcp-features-guide) | Tool Use | Industry | Six MCP primitives with patterns |
| [DEV Community — LLM Tool Failures](https://dev.to/terzioglub/why-llm-agents-break-when-you-give-them-tools-and-what-to-do-about-it-f5) | Tool Use | Practitioner | Anti-patterns, NESTFUL benchmark data |
| [Auth0 — MCP Spec Updates](https://auth0.com/blog/mcp-specs-update-all-about-auth/) | Tool Use | Documentation | OAuth 2.1, token security |
| [MIT CSAIL — PLAY2PROMPT](https://sls.csail.mit.edu/publications/2025/WFang_ACL_2025.pdf) | Tool Use | Academic | Iterative tool description optimization |
| [Claude Code — Skills](https://code.claude.com/docs/en/skills) | Claude Code | Documentation | Skills creation, frontmatter, dynamic context |
| [Claude Code — Hooks](https://code.claude.com/docs/en/hooks) | Claude Code | Documentation | 27 lifecycle events, handler types |
| [Claude Code — Subagents](https://code.claude.com/docs/en/sub-agents) | Claude Code | Documentation | Custom subagent configuration |
| [Batsov — Essential Skills](https://batsov.com/articles/2026/03/11/essential-claude-code-skills-and-commands/) | Claude Code | Practitioner | Built-in skills overview |
| [okhlopkov — Claude Code Setup](https://okhlopkov.com/claude-code-setup-mcp-hooks-skills-2026/) | Claude Code | Practitioner | MCP, hooks, skills setup patterns |
| [Shipyard — Cheat Sheet](https://shipyard.build/blog/claude-code-cheat-sheet/) | Claude Code | Industry | Configuration hierarchy, commands |
| [Builder.io — How I Use Claude Code](https://www.builder.io/blog/claude-code) | Claude Code | Practitioner | Workflow patterns |
| [Anthropic — Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) | Reliability | Research | Simplicity, poka-yoke tool design |
| [arxiv 2503.13657 — Multi-Agent Failures](https://arxiv.org/html/2503.13657v1) | Reliability | Academic | 14 failure modes from 150+ traces |
| [Portkey — Retries/Fallbacks/Circuit Breakers](https://portkey.ai/blog/retries-fallbacks-and-circuit-breakers-in-llm-apps/) | Reliability | Industry | Error handling patterns |
| [GoCodeo — Error Recovery](https://www.gocodeo.com/post/error-recovery-and-fallback-strategies-in-ai-agent-development) | Reliability | Industry | Error taxonomy, recovery strategies |
| [Permit.io — Human-in-the-Loop](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo) | Reliability | Industry | Propose-commit pattern |
| [OpenAI — Agents SDK Guardrails](https://openai.github.io/openai-agents-python/guardrails/) | Reliability | Documentation | Input/output/tool guardrails, tripwires |
| [Instructor — Retry Logic](https://python.useinstructor.com/concepts/retrying/) | Reliability | Documentation | Self-healing validation pattern |
| [LangChain — State of Agent Engineering](https://www.langchain.com/state-of-agent-engineering) | Reliability | Survey | 1,340-respondent industry survey |
| [arxiv 2509.18847 — Self-Correction](https://arxiv.org/html/2509.18847v2) | Reliability | Academic | Structured reflection patterns |
| [Promptfoo — CI/CD Integration](https://www.promptfoo.dev/docs/integrations/ci-cd/) | Prompt Testing | Documentation | CI/CD setup for prompt evaluation |
| [Braintrust — Best Eval Tools](https://www.braintrust.dev/articles/best-ai-evals-tools-cicd-2025) | Prompt Testing | Industry | Tool comparison with pricing |
| [PromptBuilder — CI/CD Guide](https://promptbuilder.cc/blog/prompt-testing-versioning-ci-cd-2025) | Prompt Testing | Practitioner | SemVer for prompts, model pinning |
| [Traceloop — Regression Testing](https://www.traceloop.com/blog/automated-prompt-regression-testing-with-llm-as-a-judge-and-ci-cd) | Prompt Testing | Technical | Four-component framework |
| [DEV Community — Versioning Tools 2026](https://dev.to/debmckinney/keep-your-prompts-organized-best-versioning-tools-in-2026-4f95) | Prompt Testing | Practitioner | Tool comparison |
| [LaunchDarkly — Prompt Management](https://launchdarkly.com/blog/prompt-versioning-and-management/) | Prompt Testing | Vendor | Feature-flag prompt rollout |
| [Temporal — AI Agents](https://temporal.io/ai) | Long-Running Agents | Vendor | Durable workflow orchestration |
| [Restate — AI Agents](https://docs.restate.dev/use-cases/ai-agents) | Long-Running Agents | Vendor | Crash-proof execution, compensation |
| [Letta — Stateful Agents](https://www.letta.com/blog/stateful-agents) | Long-Running Agents | Research | Three-tier memory architecture |
| [LangGraph — Persistence](https://docs.langchain.com/oss/python/langgraph/persistence) | Long-Running Agents | Framework | Checkpoint-based state persistence |
| [Microsoft — Magentic-One](https://www.microsoft.com/en-us/research/blog/magentic-one-a-generalist-multi-agent-system-for-solving-complex-tasks/) | Long-Running Agents | Research | Dual-ledger progress tracking |
| [Claude Code on the Web](https://code.claude.com/docs/en/claude-code-on-the-web) | Long-Running Agents | Documentation | Background execution, session persistence |
| [AutoGen — State Management](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/state.html) | Long-Running Agents | Framework | Save/load state patterns |
