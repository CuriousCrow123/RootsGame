# Phase 2: Merged Research Findings

**Topic:** Best practices for prompt engineering, context window management, Claude agent/orchestration, tools/skills/commands
**Date:** 2026-03-18
**Effort:** deep
**Total sources:** 49 unique sources across 6 facets
**Overall confidence:** high across all facets

## Coverage Summary

| Facet | Sources | Confidence | Key Tensions | Notable Gaps |
|-------|---------|------------|-------------|--------------|
| Prompt Engineering Fundamentals | 8 | high | XML tags vs simplicity; few-shot vs zero-shot for modern models | Production prompt CI/CD workflows |
| Context Window Management | 9 | high | Summarization vs masking; RAG vs long context | 1M token degradation curves |
| Claude Agent Orchestration | 8 | high | Simplicity vs capability; frameworks vs raw APIs | Cost optimization for multi-agent |
| Tool Use & Function Calling | 8 | high | Strict schemas vs reasoning quality; tool count limits | Tool description benchmarks |
| Claude Code Skills/Commands | 7 | high | Skills vs subagents for delegation; legacy commands vs skills | Skill performance at scale |
| Agentic Patterns & Reliability | 9 | high | Simple vs framework approaches; parallel vs blocking guardrails | Long-running agent patterns |

---

## Facet 1: PROMPT_ENGINEERING_FUNDAMENTALS

### Summary
Current best practices center on clarity, specificity, and structured formatting. The field has matured with convergence on core principles: be direct, use examples (few-shot), encourage step-by-step reasoning (CoT), structure with XML tags/delimiters, and iterate systematically. Modern Claude models require less aggressive prompting.

### Key Findings
- Clarity and specificity are #1 across all sources. Anthropic: "Show your prompt to a colleague with minimal context -- if they'd be confused, Claude will be too."
- XML tags reduce misinterpretation; 3-5 examples recommended for few-shot
- Few-shot CoT consistently delivers superior results (Prompt Report, 1,500+ papers)
- Explaining WHY behind instructions improves output vs. just WHAT
- Positive framing outperforms negative: "use flowing prose" > "don't use markdown"
- Long-context prompts: documents at top, query at bottom (up to 30% quality improvement)
- Modern models need less aggressive prompting; Claude 4.6 may overtrigger with old prompts
- Prompt Report identified 58 text-based techniques in 6 categories
- Automated optimization (DSPy) outperformed 20hrs manual engineering in 10 minutes
- Prompt compression saves 50-65% tokens with no quality loss
- Start simple, add complexity only when addressing specific problems

### Sources (8)
- Anthropic Claude API Docs (platform.claude.com)
- Anthropic Blog (claude.com/blog)
- Lakera Guide
- The Prompt Report (Schulhoff et al., 1,500+ papers)
- DAIR.AI Prompt Engineering Guide
- Arize AI Blog
- arxiv 2406.06608

---

## Facet 2: CONTEXT_WINDOW_MANAGEMENT

### Summary
Effective management requires treating context as a finite resource with diminishing returns. Place relevant info at beginning/end (avoid "lost in the middle"), use compaction, structured note-taking, sub-agent isolation, prompt caching, and just-in-time retrieval. More tokens ≠ better output.

### Key Findings
- Documents at top + query at bottom: up to 30% quality improvement (Anthropic)
- "Lost in the Middle": 30%+ performance degradation in middle positions (Liu et al., Stanford/ACL 2024)
- Observation masking matched/beat LLM summarization with 50%+ cost savings (JetBrains)
- Summarization caused agents to run 13-15% longer by obscuring stopping signals
- Four core strategies: compaction, structured note-taking, sub-agent isolation, just-in-time retrieval
- Token budget: System 10-15%, Tools 15-20%, Knowledge 30-40%, History 20-30%, Buffer 10-15%
- Prompt caching: up to 90% cost reduction, 85% latency reduction
- Claude Sonnet 4.6/4.5 have built-in context awareness with token budget tracking
- RAG and long context are complementary (60% identical answers; RAG faster, long context better for reasoning)
- Ask Claude to "quote relevant parts first" to cut through noise in long documents
- Sometimes starting fresh is better than compacting -- Claude can rediscover state from filesystem

### Sources (9)
- Anthropic Context Windows docs
- Anthropic "Effective context engineering for AI agents"
- Anthropic Long context tips
- Anthropic Prompt Caching docs
- Chroma Research "Context Rot" (18 models tested)
- Liu et al. "Lost in the Middle" (Stanford/ACL 2024)
- JetBrains Research
- Maxim AI
- Redis blog

---

## Facet 3: CLAUDE_AGENT_ORCHESTRATION

### Summary
Anthropic advocates starting with the simplest architecture, favoring composable workflow patterns over autonomous multi-agent systems. The orchestrator-worker pattern with detailed task delegation, parallel subagent execution, and external memory is recommended, supported by the Claude Agent SDK and Claude Code agent teams.

### Key Findings
- "Find the simplest solution possible, and only increase complexity when needed" (Anthropic)
- Six composable patterns: prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer, autonomous agents
- Multi-agent Opus 4 + Sonnet 4 outperformed single-agent Opus 4 by 90.2%
- Token economics: agents use ~4x chat tokens; multi-agent uses ~15x
- Detailed task delegation is essential -- vague instructions cause duplication and gaps
- Claude Agent SDK: subagents get own description, system prompt, restricted tools, optional different model
- Claude Code: subagents (lightweight, report back) vs agent teams (full sessions, inter-agent messaging)
- Tool-testing agents that rewrote flawed descriptions reduced task completion time by 40%
- Parallel subagent spawning (3-5) + parallel tool calls reduced research time by up to 90%
- Builder-validator pattern: separate builder from reviewer to avoid shared blind spots
- Recommended team size: 3-5 teammates, 5-6 tasks each
- Frameworks "often create extra layers of abstraction that obscure underlying prompts" (Anthropic)

### Sources (8)
- Anthropic "Building Effective Agents"
- Anthropic Engineering multi-agent research system
- Claude Agent SDK docs
- Claude Code agent teams docs
- Claude Code subagents docs
- Anthropic blog on Agent SDK
- claudefa.st
- DEV Community

---

## Facet 4: TOOL_USE_AND_FUNCTION_CALLING

### Summary
Tool descriptions are the single most important factor in tool performance. MCP provides the standardized protocol for connecting Claude to external services. Production systems require defensive design with error recovery, human-in-the-loop gates, and strict schema validation.

### Key Findings
- Tool descriptions are "by far the most important factor" -- use 3-4 sentences minimum (Anthropic)
- Tool Search Tool reduces token consumption by 85%, preserves 95% of context
- Programmatic Tool Calling: 37% token reduction, eliminates 19+ inference passes
- `strict: true` guarantees schema conformance for production
- Consolidate related operations into single tool with `action` parameter
- MCP primitives: Tools (model-controlled), Resources (app-controlled), Prompts (user-controlled)
- MCP: client-server architecture, STDIO for local, Streamable HTTP for remote, OAuth 2.1 for auth
- Tool accuracy degrades with quantity; limit to 5-10 per query
- GPT-4o only 28% accurate on chained/nested API calls (NESTFUL benchmark)
- Tool responses should return semantic identifiers, include only necessary fields
- Explicitly instruct parallel tool use in system prompts
- ACL 2025: restrictive schemas can "significantly degrade model performance"

### Sources (8)
- Anthropic tool use docs (overview + implementation)
- Anthropic engineering blog (advanced tool use)
- MCP architecture docs
- WorkOS MCP features guide
- DEV Community (tool integration analysis)
- Auth0 (MCP spec updates)
- MIT CSAIL / ACL 2025 (PLAY2PROMPT)

---

## Facet 5: CLAUDE_CODE_SKILLS_COMMANDS

### Summary
Claude Code provides layered extensibility: skills (markdown-based), slash commands (unified with skills), hooks (lifecycle events), subagents (isolated workers), and CLAUDE.md files. Skills follow the open Agent Skills standard (agentskills.io) for cross-tool compatibility.

### Key Findings
- Skills and commands are unified; skills recommended as modern format with frontmatter, supporting files
- `disable-model-invocation: true` prevents auto-triggering; `user-invocable: false` hides from menu
- Five bundled skills: /batch, /simplify, /loop, /debug, /claude-api
- Skills follow agentskills.io open standard (works across Claude Code, Cursor, Gemini CLI, Codex CLI)
- CLAUDE.md hierarchy: global > project root > subdirectory, supports @include
- Hooks: 27 lifecycle events, 4 handler types (command, HTTP, prompt, agent)
- PreToolUse is the only hook that can block actions
- Subagents: built-in (Explore/Plan/general-purpose) + custom in .claude/agents/
- Skill description budget: 2% of context window, 16K char fallback
- `!`command`` syntax enables dynamic context injection in skills
- Settings: three-level JSON hierarchy (user > project > local)
- Keep SKILL.md under 500 lines; move reference material to supporting files
- Subagents support persistent cross-session memory via MEMORY.md

### Sources (7)
- Anthropic skills docs
- Anthropic hooks docs
- Anthropic subagents docs
- Batsov blog
- okhlopkov.com setup guide
- Shipyard cheat sheet
- Builder.io blog

---

## Facet 6: AGENTIC_PATTERNS_AND_RELIABILITY

### Summary
Reliable agentic systems require layered defense: composable patterns, structured error handling, multi-level guardrails, human-in-the-loop checkpoints, and observability. Failures in multi-agent systems stem more from inter-agent misalignment and poor termination logic than base model limitations.

### Key Findings
- "Most successful implementations used simple, composable patterns" not complex frameworks (Anthropic)
- 10-step process at 99% per-step = ~90.4% end-to-end (compounding failure rates)
- 14 failure modes in 3 categories: specification/design, inter-agent misalignment, verification/termination
- "Improvements in base model capabilities will be insufficient" for systemic issues (arxiv)
- Layered error handling: retries with backoff + circuit breakers + fallback chains
- Classify errors: repairable (LLM self-corrects), transient (auto-retry), fatal (log + propagate)
- Instructor library: self-healing validation -- LLM receives structured errors, corrects output
- Three-layer guardrail pipeline: input, processing, output validation
- Propose-commit pattern for human-in-the-loop: hard separation between proposing and executing
- "Poka-yoke" tool design: make mistakes harder (e.g., require absolute paths)
- Post-action state verification: assert expected changes actually occurred
- Loop termination: max iterations, verifier agents, loop-detection for circular conversations
- LangChain survey (n=1,340): 89% have observability; quality is #1 production blocker (32%)

### Sources (9)
- Anthropic "Building Effective Agents"
- arxiv 2503.13657 (multi-agent failure modes)
- Portkey.ai (retries/fallbacks/circuit breakers)
- GoCodeo (error recovery strategies)
- Permit.io (human-in-the-loop)
- OpenAI Agents SDK (guardrails)
- Instructor docs (self-healing validation)
- LangChain "State of Agent Engineering" survey
- arxiv 2509.18847 (self-correction patterns)
