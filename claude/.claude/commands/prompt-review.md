---
description: Review a Claude prompt and suggest improvements based on Anthropic's prompting best practices.
disable-model-invocation: true
argument-hint: "<prompt text or path to file containing prompt> [--no-rewrite]"
allowed-tools: Read WebFetch
---

Review a Claude prompt and return categorized findings plus a revised version, grounded in Anthropic's prompting best practices.

User context: $ARGUMENTS

## Steps

### 1. Resolve the prompt to review

Parse `$ARGUMENTS`:
- **Empty** → ask the user for the prompt (inline text or file path) and stop.
- **Looks like a file path that exists** → `Read` the file; treat its contents as the prompt under review.
- **Otherwise** → treat `$ARGUMENTS` as the prompt text inline.

If `--no-rewrite` appears anywhere in the arguments, skip the "Revised prompt" section in step 4. Strip it from the prompt text before reviewing.

Briefly echo the resolved prompt (or a one-line summary if long) so the user can confirm what's being reviewed.

### 2. Load the best-practices reference

Read `~/.claude/references/claude-prompting-best-practices.md` — a condensed, categorized checklist distilled from Anthropic's live doc. Use it as the rubric for steps 3 and 4.

Use `WebFetch` to retrieve `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices.md` only if **any** of these hold:
- The user asks for "latest" / "current" guidance.
- The prompt targets a model newer than what the reference covers.
- The reference file is missing or clearly stale for the reviewed prompt.

Otherwise stay offline — the bundled reference is the primary source.

### 3. Run the review across these axes

For each axis, check the prompt against the reference's bullets. Quote specific excerpts from the prompt when citing issues. Axes that don't apply to this prompt go under "N/A" at the end — explicitly naming them shows the user they were considered, not skipped by accident.

1. **Clarity & directness** — task stated unambiguously; success criteria explicit.
2. **Context** — audience, domain, constraints, background, input data.
3. **Examples / few-shot** — would 1–3 input/output examples disambiguate?
4. **Structure** — XML tags or markdown delimiters separating instructions / context / data / output spec?
5. **Role** — would a specific persona sharpen the response?
6. **Output format control** — positive framing, explicit format spec, delimiters marking output boundaries?
7. **Tool use** (only if the prompt uses tools) — explicit trigger language, parallel-call guidance?
8. **Thinking / effort** (only if relevant) — appropriate `effort` level or `budget_tokens`?
9. **Agentic patterns** (only if multi-step / long-horizon) — state tracking, subagent boundaries, overeagerness guards, hallucination mitigations?
10. **Model fit** — right model class for the task (Opus / Sonnet / Haiku)?

### 4. Return findings in this structure

```
## Assessment
<1–2 sentences — overall quality and the top 1–2 levers for improvement>

## Findings
### <Axis name>
- **Issue:** <short description>
  **Excerpt:** "<quoted text from the prompt, trimmed>"
  **Suggestion:** <specific, actionable change — name the exact wording or structure to add>

### <Axis name>
...

### N/A
- <Axis>: <one-line reason it doesn't apply>
- <Axis>: <one-line reason it doesn't apply>

## Revised prompt
<Full rewritten prompt with changes applied.>
```

Omit the "Revised prompt" section if `--no-rewrite` was passed or the original exceeds ~500 lines (rewriting that much is rarely useful — call that out instead and suggest the user apply findings incrementally).

### 5. Suggestion quality bar

Every **Suggestion** must name an exact change. Good: *"Wrap the input document in `<document>` XML tags and move it below the instructions."* Bad: *"Improve structure."* If you can't name the exact change, the finding is probably not worth reporting.

### 6. Under-specified prompts

If the prompt is a one-liner or too abstract to review usefully (e.g., `"Help me with code"`), say so and ask for: target model, intended use case, what the user has already tried, and what went wrong.
