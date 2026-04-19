---
description: Build a fleshed-out Claude prompt from a rough seed, asking clarifying questions as needed.
disable-model-invocation: true
argument-hint: "<rough prompt idea or goal> [--quick]"
allowed-tools: Read Write WebFetch AskUserQuestion
---

Build a fleshed-out Claude prompt from a rough seed idea, asking clarifying questions (one batched round) when answers would meaningfully change the output. Sibling to `/prompt-review` — same rubric, opposite direction: review audits a complete prompt, build scaffolds one from a seed.

User context: $ARGUMENTS

## Steps

### 1. Resolve the seed

Parse `$ARGUMENTS`:
- **Empty** → ask the user for the rough idea or goal and stop.
- **Contains `--quick`** → strip the flag from the seed text and set quick-mode for step 4.
- **Otherwise** → treat `$ARGUMENTS` as the seed.

Briefly echo the resolved seed so the user can confirm what's being built.

### 2. Load the best-practices reference

Read `~/.claude/references/claude-prompting-best-practices.md` — the same condensed rubric `/prompt-review` uses. This is the rubric to apply when drafting.

Use `WebFetch` to retrieve `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices.md` only if **any** of these hold:
- The user asks for "latest" / "current" guidance.
- The seed targets a model newer than what the reference covers.
- The reference file is missing or clearly stale.

Otherwise stay offline.

### 3. Identify missing dimensions

Scan the seed against these axes (same 10 as `/prompt-review`). For each, classify as:
- **Self-evident** — the seed already answers it.
- **Safe default** — you can fill it in with a reasonable default (note in step 6's "What I assumed").
- **Load-bearing unknown** — the answer would meaningfully reshape the drafted prompt; ask the user.

Axes:

1. **Clarity & directness** — task statement, success criteria
2. **Context** — audience, domain, background, input data shape
3. **Examples / few-shot** — could 1–3 I/O examples disambiguate?
4. **Structure** — XML tags or delimiters to separate instructions / context / data / output spec?
5. **Role** — would a specific persona sharpen the response?
6. **Output format** — prose, JSON, markdown report, code, structured list?
7. **Tool use** — does the prompt need tool access (search, MCP, code execution)?
8. **Thinking / effort** — appropriate `effort` level or `budget_tokens`?
9. **Agentic patterns** — multi-step / long-horizon? State tracking, overeagerness guards?
10. **Model fit** — right model class (Opus / Sonnet / Haiku)?

### 4. Ask clarifying questions (skip if `--quick`)

**If quick-mode:** skip this step entirely. Every load-bearing unknown becomes an assumption.

**Otherwise:** use **ONE** `AskUserQuestion` call with 2–4 of the load-bearing unknowns from step 3. Hard rules:
- **One round only.** Do not loop asking follow-ups. After the user answers, proceed to draft with assumptions for anything still unresolved.
- **Only ask when the answer reshapes the output.** If the default is obviously fine, don't bother asking — put it in "What I assumed."
- **Batch related questions.** 2–4 questions per call, not one per message.

Typical question candidates (pick the ones whose answers matter most for this seed):

- **Target model?** Opus (hard reasoning / ambiguous problems) / Sonnet (most routine work) / Haiku (fast, cheap, subagent-scale).
- **What will the output be used for?** One-shot response shown to you / feeds into another tool / displayed to end users.
- **Expected output format?** Prose / JSON / markdown report / code only / structured list.
- **Does the prompt need tool access?** If yes, which tools?
- **Can you share 1–2 examples of ideal output?** Examples beat rubric-based inference.
- **Any non-obvious constraints?** Tone, length, audience, things to avoid.

### 5. Refuse truly abstract seeds

If the seed is so vague there's nothing to build on — e.g., `"help me with my app"`, `"write a prompt"`, `"make something"` — do NOT manufacture a prompt. Respond that the seed is too abstract and ask what specifically Claude should do, what the output should look like, and what the user has already tried. Stop.

This mirrors `/prompt-review` step 6 and prevents hallucinated scaffolding. A rich enough seed is a concrete *task* ("summarize support tickets for a weekly exec report") — not a domain ("customer support").

### 6. Draft the prompt

Apply the best-practices rubric. Shape the prompt to what it actually needs — don't force a template on simple prompts or strip structure from complex ones. General guidelines:

- **Role** — only add if it sharpens the response; skip for generic tasks.
- **Structure** — use XML tags (`<input>`, `<context>`, `<examples>`) when there are distinct sections; plain markdown is fine for short prompts.
- **Output format** — specify explicitly. Positive framing ("return JSON matching this schema") over negative ("don't include prose").
- **Examples** — include if the user provided them, or scaffold 1–2 placeholder examples the user can fill in (and flag that in "What I assumed").
- **Model fit** — surface the recommended model in "Design choices," not inside the prompt body.

### 7. Produce and persist the output

Write the built prompt to `./.claude/prompts/<slug>.md` in the current working directory. **Do NOT echo the three sections to chat** — the file is the single artifact. Chat gets only the kickoff line at the end.

**File structure — three sections:**

```
## Built prompt

<full prompt text, wrapped in a code fence so markdown viewers render it as a verbatim block instead of interpreting its headings, XML tags, and emphasis as document structure. If the prompt body contains a run of N backticks, use N+1 backticks for the fence.>

## Design choices

- <concrete structural choice + why, e.g., "Used `<ticket>` XML tags because the input is multi-paragraph user text that shouldn't be confused with instructions.">
- <one bullet per non-obvious decision>

## What I assumed

- <each default filled in without asking>
- <mark assumptions the user is most likely to want to override>
```

**Path rules:**

- Do NOT use `~/.claude/prompts/` — the file must live with the repo.
- **Slug derivation:** kebab-case from the resolved seed, truncated to ~50 chars, stop words and punctuation stripped. *Example:* `"Review and grade MD files in this repository"` → `review-and-grade-md-files`. No random suffixes — the slug should be readable and predictable.
- **Conflict handling:** if the target filename already exists, append `-2`, `-3`, etc., until unused. Do NOT clobber a prior build.
- `Write` creates missing parent directories automatically, so no separate `mkdir` step is needed.

**Kickoff:** after writing, print one line to chat:

> *Prompt written to `.claude/prompts/<slug>.md`. In a fresh session: `Read .claude/prompts/<slug>.md and execute the prompt.`*

### 8. Design-choice quality bar

Every "Design choices" bullet must name the exact structural or rubric-driven decision — mirroring `/prompt-review`'s suggestion quality bar.

- Good: *"Put the output schema at the end, after the instructions and context, so the model has the task in mind when it sees the format constraint."*
- Bad: *"Improved structure."*

If you can't name the concrete choice, the bullet isn't worth including.
