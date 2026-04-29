---
description: Append (or create) a HANDOFF.md entry to chain context across Claude Code sessions when the context window is full.
disable-model-invocation: true
argument-hint: "[optional focus note]"
allowed-tools: Read Write Edit Glob Grep Bash(git *) Bash(date *) Bash(pwd *) Bash(ls *)
---

Append (or create) an entry in `HANDOFF.md` in the current working directory so a fresh Claude Code session can pick up where this one left off. Each entry is a chronologically numbered H2 section that captures only what is *not* recoverable from `git log` / `git diff` / the file tree.

User context: $ARGUMENTS

## Steps

### 1. Gather session state

In parallel where possible:
- **Timestamp** — `date '+%Y-%m-%d %H:%M %Z'`
- **Branch** — `git rev-parse --abbrev-ref HEAD 2>/dev/null` (skip if not a git repo)
- **Working dir** — `pwd`
- **Model** — read from your runtime context (e.g., "Opus 4.7 (1M context)"). Do NOT shell out for this.
- **Session goal** — paraphrase the user's original ask from your conversation memory in 1–2 lines. If `$ARGUMENTS` is non-empty, treat it as a focus hint that biases section emphasis (more detail in that area), but do NOT let it replace the actual session goal.

### 2. Inspect existing HANDOFF.md

Three cases:

- **Does not exist** → create with H1 `# Handoff Log` + one-line preamble explaining the file's purpose, then `Session 1`.
- **Exists with prior entries** → find the highest existing `## Session N` (regex `^## Session (\d+)`); the new entry becomes `Session N+1`. Append after a `---` horizontal rule.
- **Exists, malformed or no `## Session` headers** → preserve everything currently in the file; append a `---` rule and start at `Session 1` regardless.

### 3. Compose the entry

Use this template. **Omit any section that has nothing to say** — do not write "N/A" or "None." Favor terseness; link rather than quote.

```markdown
## Session <N> — <YYYY-MM-DD HH:MM TZ>

**Branch:** `<branch>` · **CWD:** `<cwd>` · **Model:** <model> <· focus: $ARGUMENTS if provided>

### Goal
<1–2 line paraphrase of the user's request for this session>

### Work completed
- <action with `file_path:line_range` or PR/commit ref>
- <≤ ~6 bullets; link, don't quote source>

### Key findings & investigations
- <non-obvious learning, dead end, or surprising behavior>
- <"we tried X, it didn't work because Y" — these prevent the next instance from re-running failed experiments>

### References
- `<file_path:line_range>` — <one-line note on what's there>
- <https://docs.example.com/...#anchor> — <one-line note>

### Open threads / next steps
- <unfinished work, hypotheses to test, deferred decisions>
```

**Citation rules** — mirror the global Plan Writing requirement in `~/.claude/CLAUDE.md`:
- Use `file_path:line_range` (e.g., `src/Foo.cs:42-58`), not bare filenames.
- For docs, link to the section/anchor, not the top-level URL.
- Every non-obvious claim in **Findings** should have a matching entry in **References**. If untraceable, mark it explicitly as an **assumption**.

### 4. Write or append

- **Create case** — `Write` `HANDOFF.md` with the H1, preamble, and first entry.
- **Append case** — `Edit` `HANDOFF.md` to insert `\n\n---\n\n<new entry>\n` after the last existing entry (end of file). Do NOT prepend; chronological order is the reading contract.

### 5. Confirm to the user

Print exactly one line:

> *Handoff written to `HANDOFF.md` (Session `<N>`). To resume in a fresh session: open this repo and say "Read HANDOFF.md and continue from the latest session."*

Do NOT echo the entry to chat — the file is the single artifact.

## Quality bar

- A reader should reconstruct enough context to continue work in under one minute of reading.
- The entry should be reproducible by `Read HANDOFF.md` alone; the next instance shouldn't need a second tool call to understand the previous session's state.
- The high-signal sections are **Findings** and **Open threads** — they capture what `git log` cannot. **Work completed** should lean heavily on `file_path:line_range` refs rather than narrating diffs.
- If `$ARGUMENTS` was a focus note, the entry should make it visible in the metadata header — but findings outside that focus still belong in the entry.
