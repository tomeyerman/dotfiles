---
description: Generate a review prompt for GitHub Copilot CLI without running the dialogue. Writes the prompt to a temp file for manual use.
disable-model-invocation: false
argument-hint: "[--did=<uuid>] [unstaged | staged | committed into <target-branch> | plan]"
allowed-tools: Bash(git diff*) Bash(git merge-base*) Bash(python *)
---

Generate a Copilot CLI review prompt and write it to the dialogue directory. This skill only produces the prompt — it does not invoke Copilot.

User context: $ARGUMENTS

## Step 0: Resolve Dialogue ID

Check whether the user context contains a `--did=<uuid>` argument. If it does, use that value as the dialogue ID (`DID`). If not, generate one:

```bash
DID=$(python -c "import uuid; print(uuid.uuid4())")
```

All dialogue files are written to `.dialogues/${DID}/` (relative to project root). Create the directory:

```bash
mkdir -p .dialogues/${DID}
```

## Step 1: Determine Review Type and Gather Context

Strip `--did=<uuid>` from the arguments before processing. Use the remaining arguments to determine the review type and target. If no remaining arguments, use the priority order below.

Determine whether this is a **code review** or a **plan review**:

**Code Review** — The user must specify one of these review scopes:

- **`unstaged`** — Review unstaged working tree changes. Diff command: `git diff`
- **`staged`** — Review staged (indexed) changes. Diff command: `git diff --cached`
- **`committed into <target-branch>`** — Review all commits on the current branch that are not yet in `<target-branch>`. Compute the merge base first:
  ```bash
  MERGE_BASE=$(git merge-base HEAD <target-branch>)
  ```
  Diff command: `git diff $MERGE_BASE...HEAD`

If the user did not specify a scope, ask them which one they want. Do not guess or auto-detect.

**Plan Review** — Review an implementation plan:

- Use the plan file path from the system prompt if available (Claude Code provides this in plan mode)
- Otherwise, use the most recently modified `.md` file in `~/.claude/plans/`
- Read the plan file contents

Build a clear description of what is being reviewed and its intent (if known from conversation context).

## Step 2: Failure Handling

Before constructing the prompt, check for these pre-flight failures:

- **Not a git repo** → skip diff gathering; require user-specified files or a plan file
- **No diff / no changes** → inform the user there's nothing to review; ask if they want to review specific files instead
- **Copilot CLI not found** → warn: "Copilot CLI is required to use this prompt. Install: `winget install GitHub.Copilot` or see https://docs.github.com/copilot"
- **Copilot auth failure** → warn: "Run `copilot auth` to authenticate before using this prompt"
- **Plan references files that don't exist** → warn about missing files, proceed with the files that do exist
- **No plan file found** (for plan review) → inform the user no plan was found in `~/.claude/plans/`

## Step 3: Construct the Prompt

Write the review prompt to `.dialogues/${DID}/prompt.txt`.

The review prompt should include:
- **For code review:** Tell Copilot the exact diff command to run based on the user's chosen scope. Do not paste the diff into the prompt — Copilot has access to the repo via `--add-dir` and can run the command itself.
  - Unstaged: "Review the unstaged changes in this repository. Run `git diff` to see them."
  - Staged: "Review the staged changes in this repository. Run `git diff --cached` to see them."
  - Committed: "Review the commits on this branch that are not yet merged into `<target-branch>`. Run `git diff <merge-base>...HEAD` to see them." (Use the merge base computed in Step 1.)
- **For plan review:** Tell Copilot to read the plan file at its path (Copilot can access it via `--add-dir`). Do not paste the plan content into the prompt. Include the file paths of key source files the plan references so Copilot knows where to look.
- This instruction: "Write your complete review to the file `.dialogues/${DID}/round1-review.md`. Do not print your review to stdout — write it to the file. At the very end of the file, on its own line, write your current conversation/session ID in the format: `<!-- session-id: <your-session-id> -->`"
- This instruction: "Number each issue sequentially (e.g., Issue 1, Issue 2). For each issue, state: the file path and line number(s), a severity (HIGH/MEDIUM/LOW), and your specific concern. Only raise issues that affect correctness, security, performance, or maintainability — do not flag style preferences or minor naming quibbles. If there are no material issues, say so."
- This instruction: "For every issue you raise or claim you make, cite the specific file path and line number(s), or the specific section of the plan. If referencing documentation, include the URL or doc page. Be direct and specific — this is a peer review dialogue, not a rubber stamp."
- **For plan review, also include:** "Evaluate this implementation plan for: correctness of assumptions about the current codebase, completeness (are there missing steps or edge cases?), risks or potential issues with the proposed approach, and whether better alternatives exist. Reference the actual source files provided to validate or challenge the plan's claims. For each claim you make about the current codebase, mark it as VERIFIED (you checked the supplied source files) or INFERRED (based on general knowledge or assumptions)."

## Step 4: Present to User

After writing the prompt file, tell the user:

1. The file path: `.dialogues/${DID}/prompt.txt`
2. The dialogue ID (`DID`) so the user can reference it later
3. A suggested command to run it manually:
   ```
   copilot -p "Read and follow the review instructions in .dialogues/${DID}/prompt.txt" -s --allow-all --model gpt-5.4 --add-dir "$(pwd)"
   ```
