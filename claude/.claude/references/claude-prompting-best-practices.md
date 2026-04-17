# Claude Prompting Best Practices — Review Rubric

Condensed checklist distilled from Anthropic's [Claude prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices.md). Use this as the rubric when reviewing prompts. For full detail or the very latest guidance, `WebFetch` the live URL.

## How to use this rubric

For each axis below, check the prompt against the bullets. When you find an issue, quote the offending excerpt and propose a specific, named fix (not vague advice like "clarify" or "improve"). Skip axes that don't apply and mark them N/A in the output — explicitly naming skipped axes signals they were considered.

---

## 1. Clarity & directness
- Task stated as an imperative, not a vague request.
- Success criteria explicit: what does "done" look like? What makes an answer correct?
- Ambiguous qualifiers defined ("short", "good", "relevant" — relative to what?).
- Core ask at the top or clearly marked — no buried lede inside a wall of context.
- One task per prompt when possible. If multiple, number them.

**Positive:** *"Extract all email addresses from the document below. Return a JSON array of strings, sorted alphabetically, deduplicated case-insensitively."*
**Negative:** *"Look at this and tell me what you see."*

## 2. Context
- Audience specified (technical / non-technical, domain expertise).
- Relevant background / domain info included (not assumed).
- Constraints listed: length, tone, things to avoid, performance budget.
- Input data clearly separated from instructions.
- State *why* the task matters when it would affect approach (e.g., "for a production migration" vs. "for a throwaway experiment").

## 3. Examples / few-shot
- 1–3 input/output pairs for tasks with ambiguous output shape, subjective judgment, or tricky edge cases.
- Examples cover at least one edge case when the task has them (empty input, adversarial input, boundary values).
- Examples wrapped in `<example>` / `<examples>` XML tags (or equivalent consistent delimiters).
- Example quality matters more than quantity — one clear example beats three contradictory ones.

## 4. Structure (XML tags and markdown)
- Distinct sections for instructions, context, examples, and input data.
- XML tags preferred for structured inputs Claude will reference by name (`<document>`, `<user_query>`, `<output_format>`, `<constraints>`).
- Instructions at the top; long input data at the bottom (closer to the generation position = better recall on long contexts).
- Consistent tag names when multiple items of the same type appear (all documents in `<document>` tags, etc.).
- For long documents, consider numbering or indexing items so Claude can reference them.

## 5. Role assignment
- Use a persona when the task benefits from domain framing — e.g., *"You are a senior security reviewer auditing authentication code."*
- Skip roleplay for routine tasks; forced personas add tokens and rarely help.
- Role should be specific ("senior .NET perf engineer with BenchmarkDotNet experience") not generic ("a helpful assistant").
- System prompt is the right place for role — not the user turn.

## 6. Output format control
- Format stated **positively** ("Return JSON matching the schema below") not negatively ("Don't write prose").
- Schema or template provided for structured outputs (JSON schema, XML tag tree, or literal example).
- Delimiters mark where the output begins and ends.
- If the model over-explains, add: *"Reply with only the requested output — no preamble, commentary, or summary."*
- Prompt style should match desired output style (formal prompt → formal output; casual → casual).
- For markdown: state explicitly when markdown IS or ISN'T wanted — don't leave it to guess.

## 7. Tool use (skip if no tools)
- Tools named explicitly in the prompt when Claude should use them (*"Use the `search` tool to..."*).
- Parallel-call guidance when multiple independent lookups are needed: *"When you need to look up several items, call `search` for each in a single response."*
- Tool selection constraints stated: *"Prefer `grep` over `bash` for file search."*
- Stop conditions explicit when tools could recurse or loop.

## 8. Thinking / effort (skip if N/A)
- For Claude 4.x models, match `effort` level to task depth.
- For extended thinking with `budget_tokens`, allocate real budget for genuinely hard reasoning — not for surface tasks.
- Avoid boilerplate *"think step by step"* — modern Claude decides thinking depth adaptively.
- Don't ask for chain-of-thought *in the output* when what you really want is better reasoning — use extended thinking instead.

## 9. Agentic patterns (skip if one-shot)
- **State tracking**: long-horizon tasks need an explicit progress/plan mechanism.
- **Subagent orchestration**: clear boundaries on what each subagent owns; what context it inherits; what it returns.
- **Autonomy/safety balance**: guardrails on destructive or expensive actions (explicit confirmation required? dry-run first?).
- **Overeagerness**: tell the model when to stop — *"Only modify files listed in the plan. Don't refactor surrounding code."*
- **Test-hardcoding guard**: forbid hardcoding expected outputs when writing tests.
- **Hallucination mitigation**: require citations from provided sources, or explicitly allow *"say 'I don't know' if the sources don't cover it."*
- **File creation discipline**: tell the model not to create intermediate docs/plans/summaries unless asked.

## 10. Model fit
- **Opus 4.x** — deep reasoning, long-horizon agents, ambiguous or architecturally hard tasks.
- **Sonnet 4.x** — balanced cost/performance for most day-to-day dev work.
- **Haiku 4.x** — speed- or cost-sensitive high-throughput tasks, simple extraction/classification.
- If the prompt is simple, suggest a cheaper model. If it's a complex multi-step reasoning task on Haiku, suggest Sonnet or Opus.
- Model name should appear somewhere (system, config, or prompt) so the review can match guidance.

---

## Common red flags (fast scan)

- Negative-only instructions ("don't do X") with no positive alternative.
- Wall of text with no delimiters or section headers.
- Abstract qualifiers ("be creative", "be helpful") with no concrete criteria.
- Mixed input data and instructions with no separator — model can't tell which is which.
- No example for a task with subjective or ambiguous output.
- Target model not named in a size/cost-sensitive context.
- Prefill or assistant-turn manipulation used as a format hack (migrate to system prompt or explicit format spec).
- Chain-of-thought requested in output when extended thinking would serve better.

## When to check the live Anthropic doc

WebFetch `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices.md` if:
- The user asks for "latest" / "current" guidance.
- The prompt targets a model newer than Claude 4.7.
- A review axis seems outdated compared to what the user describes.

Otherwise, this condensed rubric is the primary source — it's lighter on context tokens and covers the axes that matter for ~95% of reviews.
