---
description: Distill a rough idea into a structured task brief, persist it to .claude/prompts/, then enter plan mode to design the implementation against the brief.
disable-model-invocation: true
argument-hint: "<rough idea or goal> [--quick]"
allowed-tools: Read Write Edit AskUserQuestion EnterPlanMode WebFetch Glob Grep Bash(ls *)
---

Take a rough idea, distill it into a structured task brief, persist it to `./.claude/prompts/<slug>.md`, then enter plan mode so the implementation plan is built against the brief.

Sibling to `/prompt-build` (which produces a reusable Claude prompt as the final artifact) and `/plan` (which plans against an in-conversation task description). `/spec` is the bridge: it produces a brief that's both a clarified spec AND the seed for plan mode.

User context: $ARGUMENTS

## Steps

### 1. Resolve the seed

Parse `$ARGUMENTS`:
- **Empty** → ask the user for the rough idea or goal and stop.
- **Contains `--quick`** → strip the flag from the seed text and set quick-mode for step 4.
- **Otherwise** → treat `$ARGUMENTS` as the seed.

Briefly echo the resolved seed so the user can confirm what's being built.

### 2. Load the best-practices reference (as a rubric, not a template)

Read `~/.claude/references/claude-prompting-best-practices.md` if it exists. Use it as a **checklist of dimensions** the brief should clarify — NOT as a prompt-formatting template. The brief is a task spec for an engineer/AI to plan against, not a Claude prompt with role/structure/output-format sections.

Use `WebFetch` for `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices.md` only if the local copy is missing, clearly stale, or the user asks for "latest" guidance. Otherwise stay offline.

### 3. Identify missing dimensions of the task

Scan the seed against these axes — same spirit as `/prompt-build`'s rubric but oriented toward task-brief dimensions:

1. **Goal** — what is the user trying to accomplish? Feature, fix, refactor, investigation?
2. **Scope** — what's in and out? What's the smallest viable cut?
3. **Constraints** — non-negotiable bounds (tech stack, perf, compatibility, dependencies, deadlines).
4. **Success criteria** — how does the user know it's done? Tests pass? Specific behavior visible? Metric improved?
5. **Existing patterns** — are there functions/utilities/conventions in the codebase to reuse rather than create?
6. **Audience / consumer** — who or what consumes the output? End users, another service, internal tooling, the user themselves?
7. **Dependencies** — does this depend on other in-flight work, external decisions, or unblocked APIs?

Classify each axis as:
- **Self-evident** — the seed already answers it.
- **Safe default** — fill in with a reasonable default (note in the brief's "What I assumed").
- **Load-bearing unknown** — the answer would meaningfully reshape the brief; ask the user.

### 4. Ask clarifying questions (skip if `--quick`)

**If quick-mode:** skip this step entirely. Every load-bearing unknown becomes an assumption.

**Otherwise:** use **ONE** `AskUserQuestion` call with 2–4 of the load-bearing unknowns from step 3. Hard rules (mirror `/prompt-build` step 4):
- **One round only.** After the user answers, proceed with assumptions for anything still unresolved.
- **Only ask when the answer reshapes the output.** If a default is obviously fine, put it in "What I assumed."
- **Batch related questions.** 2–4 per call, not one per message.

### 5. Refuse truly abstract seeds

If the seed is so vague there's nothing to anchor on — e.g., `"improve my app"`, `"make it better"`, `"build a thing"` — do NOT manufacture a brief. Respond that the seed is too abstract and ask what specifically to do, what the success state looks like, and what the user has already tried. Stop.

This mirrors `/prompt-build` step 5 and `/prompt-review` step 6 — prevents hallucinated scaffolding.

### 6. Distill and persist the brief

Write to `./.claude/prompts/<slug>.md` in the **current working directory** (not `~/.claude/prompts/`). Use this structure:

```markdown
# Spec: <one-line title>

## Goal
<2–4 sentences clarifying what to accomplish and why.>

## Scope
**In scope:**
- <bullet>

**Out of scope:**
- <bullet — explicitly call out what NOT to do>

## Constraints & success criteria
**Constraints:**
- <non-negotiable bound — tech stack, perf, compat, deadline>

**Success criteria:**
- <observable signal that the work is done — test passing, metric, behavior visible to user>

## Existing patterns to reuse
- `<file_path:line_range>` — <what's there, why it's relevant>
- <or "none identified" if applicable>

## What I assumed
- <each default filled in without asking>
- <mark assumptions the user is most likely to want to override>
```

**Path rules** (mirror `/prompt-build` step 7):
- Do NOT use `~/.claude/prompts/` — the file must live with the repo.
- **Slug derivation**: kebab-case from the seed, truncated to ~50 chars, stop words and punctuation stripped. *Example*: `"Add Slack notifications when a deploy fails"` → `add-slack-notifications-when-deploy-fails`.
- **Conflict handling**: if the target filename exists, append `-2`, `-3`, etc. Do NOT clobber a prior brief.
- `Write` creates missing parent directories automatically.

**Do NOT echo the brief to chat** — the file is the artifact. Print one line:

> *Brief written to `.claude/prompts/<slug>.md`. Entering plan mode against this brief…*

### 7. Enter plan mode

Call `EnterPlanMode`. Plan mode's first action should be to `Read` the brief at `.claude/prompts/<slug>.md` so the plan is built against the persisted spec, not against drifting conversation memory.

Inside plan mode:
- Treat the brief as the authoritative task description.
- Run the standard plan-mode workflow (Phase 1 explore → Phase 2 design → Phase 3 review → Phase 4 write final plan → Phase 5 ExitPlanMode).
- The plan's **References** section must include `.claude/prompts/<slug>.md` so the plan is auditable against the spec it was built from.

### 8. Quality bar

- The brief must be **executable as a spec** — another engineer or AI could build a plan from it without rejoining the conversation.
- Every "Existing patterns to reuse" entry must cite `file_path:line_range` or be marked as an **assumption**.
- "Out of scope" must be explicitly populated, even if just "none identified" — silence on scope is a leading cause of plan drift.
- If the seed turns out to be a prompt-template request (the *output* should be a reusable Claude prompt, not a feature/tool/fix), suggest `/prompt-build` instead and stop. Don't manufacture a brief for the wrong shape of work.
