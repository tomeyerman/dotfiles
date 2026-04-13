---
description: Peer review dialogue between Claude and GitHub Copilot CLI. Use when the user wants a second opinion on code changes or an implementation plan from Copilot.
disable-model-invocation: true
argument-hint: "[review target — e.g., 'staged changes', 'plan', or specific file paths]"
allowed-tools: Bash(copilot *) Bash(timeout *) Bash(mkdir *) Bash(python *)
---

Conduct a structured peer review dialogue with GitHub Copilot CLI on the user's code changes or implementation plan.

User context: $ARGUMENTS

## Prerequisites

- **Copilot CLI** must be installed and authenticated (`copilot --version` to verify)
- **Bash shell** — all commands assume Claude Code's bash shell (this agent is not portable to cmd.exe or PowerShell)
- **Dialogue ID (DID)** — at the start of each dialogue, generate a UUID to serve as the dialogue ID. This keys together all artifacts (prompt, responses, rebuttals) in a single review session:
  ```bash
  DID=$(python -c "import uuid; print(uuid.uuid4())")
  mkdir -p .dialogues/${DID}
  ```
  All dialogue files are written to `.dialogues/${DID}/` (relative to project root): `prompt.txt`, `round1-review.md`, `roundN-rebuttal.md`, `roundN-review.md`, `stderr.txt`

## Dialogue Protocol

### Step 1: Generate the Review Prompt

Invoke `/copilot-prompt --did=${DID} <user's arguments>` to generate the review prompt. It handles scope detection (staged/unstaged/branch/plan), failure cases, and writes the prompt to `.dialogues/${DID}/prompt.txt`.

If `/copilot-prompt` reports an error (no diff, not a git repo, etc.), stop and relay the error to the user.

### Step 2: Round 1 — Send to Copilot for Review

The prompt was written by Step 1 to `.dialogues/${DID}/prompt.txt`. It instructs Copilot to write its review to `.dialogues/${DID}/round1-review.md`.

#### Sending to Copilot

```bash
timeout 300 copilot -p "Read and follow the review instructions in .dialogues/${DID}/prompt.txt" \
  -s --allow-all --no-ask-user \
  --model gpt-5.4 \
  --add-dir "$(pwd)" \
  2>.dialogues/${DID}/stderr.txt
```

After the command completes:
1. Check `.dialogues/${DID}/stderr.txt` for errors. Auth errors are fatal; warnings may be ignorable.
2. Verify `.dialogues/${DID}/round1-review.md` exists. If Copilot didn't create it, report the failure.
3. Read `.dialogues/${DID}/round1-review.md` with the Read tool — this is Copilot's complete review.
4. Extract the Copilot session ID from the last line of the file (format: `<!-- session-id: <id> -->`). Store this as `SESSION_ID` for use with `--resume` in subsequent rounds.

### Step 3: Evaluate Copilot's Feedback

For each numbered issue Copilot raises, classify it:

- **AGREE** — The point is valid. Note it and explain why you agree, citing the relevant code.
- **DISAGREE** — You have evidence the point is incorrect or inapplicable. Draft a rebuttal with specific citations (file paths, line numbers, documentation).
- **CLARIFY** — The point is ambiguous or lacks sufficient evidence. Ask Copilot to be more specific.

Present your evaluation to the user after each round. This is deliberate — it allows the user to intervene early, correct misunderstandings, or skip remaining rounds if the dialogue is converging.

#### Issue Tracker

Maintain a running issue tracker as you progress through rounds. For each issue, track:
- **Issue number** (from Copilot's original numbering)
- **Description** (one-line summary)
- **Status**: AGREE / DISAGREE / CLARIFY / RESOLVED
- **Resolution round** (which round resolved it, if applicable)

Use this tracker to generate the final summary in Step 6.

### Step 4: Rounds 2+ — Rebuttal (if there are DISAGREE or CLARIFY items)

For any points where you disagree or need clarification, write a rebuttal to `.dialogues/${DID}/roundN-rebuttal.md` (where N is the round number). The rebuttal should include:
- Your specific counterarguments or clarification requests, with citations
- This instruction: "Here is a counterargument from another AI reviewer (Claude). Critically evaluate it. Reply point-by-point, referencing each issue by its original number. For each: state AGREE (changed position, with reasoning), DISAGREE (with specific evidence — cite file paths, line numbers, and documentation), or CONCEDE. Do not simply defer or accept the counterargument to be agreeable. Defend your position if you believe it is correct."
- This instruction: "Write your complete response to `.dialogues/${DID}/roundN-review.md`. At the very end of the file, on its own line, write your current conversation/session ID in the format: `<!-- session-id: <your-session-id> -->`"

Then send the rebuttal to Copilot using the session ID from the previous round:

```bash
timeout 300 copilot \
  -p "Read and respond to the rebuttal in .dialogues/${DID}/roundN-rebuttal.md" \
  -s --allow-all --no-ask-user \
  --model gpt-5.4 \
  --resume=$SESSION_ID \
  --add-dir "$(pwd)" \
  2>.dialogues/${DID}/stderr.txt
```

After the command completes, read `.dialogues/${DID}/roundN-review.md` with the Read tool. Update your issue tracker.

### Step 5: Repeat or Conclude

- If all points are resolved (all AGREE from both sides), proceed to summary.
- If disagreements remain, repeat Step 4.
- **Maximum 3 rounds total**, where Round 1 is the initial review. This means at most 2 rebuttal rounds after the initial review. After 3 rounds, any unresolved disagreements go to the user.

### Step 6: Present Summary

Output a structured summary:

```
## Copilot Dialogue Summary

### Agreed Points
- [Issue N] [description] — Both sides agree. [citations]

### Resolved Disagreements
- [Issue N] [description] — Initially disagreed, resolved in round N. [final position + citations]

### Unresolved Disagreements (for user to decide)
- [Issue N] [description]
  - **Claude's position**: [argument + citations]
  - **Copilot's position**: [argument + citations]

### Recommended Actions
- **For code review:** [list of concrete code changes to make, if any]
- **For plan review:** [list of plan amendments — steps to add/remove/modify, risks to document, assumptions to verify]
```

## Rules

1. **Always cite sources.** Every claim about code must include a file path and line number. Every claim about best practices must cite documentation or a concrete rationale.
2. **Be intellectually honest.** If Copilot raises a valid point, accept it. Do not dismiss feedback to "win" the debate.
3. **Keep prompts focused.** Don't dump the entire codebase into Copilot's prompt. Send the relevant diff/files and enough context to review them. If the diff or plan exceeds ~500 lines, chunk it into logical sections (by file or by feature area) and run separate review rounds for each chunk. Summarize prior chunks' findings when starting the next.
4. **Respect the round limit.** Maximum 3 rounds. Escalate to the user rather than looping indefinitely.
