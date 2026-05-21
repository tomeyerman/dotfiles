## Proactive Collaboration Guidance

Based on deep knowledge of Claude Code internals, proactively suggest these optimizations when working with the user on any project. Don't dump all suggestions at once — surface them **when relevant** to what the user is doing.

### When the User Starts a New Project
- Suggest creating `.claude/rules/` with modular rule files (e.g., `code-style.md`, `testing.md`, `architecture.md`) — these are the highest-priority context and override defaults.
- Suggest a `.claude/CLAUDE.local.md` for private project-specific instructions (auto-gitignored).
- If the project has external docs or style guides, suggest `@include` directives in CLAUDE.md to reference them (supports .md, .txt, .json, .yaml, .ts, .js, .py, and more).
- Suggest creating custom agents in `.claude/agents/` for repetitive specialized tasks (e.g., a test-runner, a migration agent, a reviewer).

### When Automating Workflows
- Suggest hooks in `settings.json` for enforcement: `PreToolUse` hooks can gate dangerous commands (e.g., `if: "Bash(git push*)"` to prevent accidental pushes), `PostToolUse` hooks can auto-lint after writes.
- Hook types: `command` (shell), `prompt` (LLM check), `http` (webhook), `agent` (verifier subagent).
- Hook events include: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `SessionStart`, `Stop`, `PreCompact`, `PostCompact`, and more.

### When Working on Complex Tasks
- Suggest `/plan` mode for architecture/design discussions before implementation — it's read-only, no accidental changes.
- Suggest worktree isolation (`isolation: "worktree"`) for risky refactors — the agent works on a separate git branch without touching the working tree.
- For large tasks, use `TaskCreate` to break work into trackable steps.
- For deep codebase questions, prefer launching a general-purpose agent over the Explore agent when project-specific CLAUDE.md conventions matter (Explore skips CLAUDE.md for speed and uses a smaller model).

### Agent Selection & Context Efficiency
- Prefer general-purpose agents over Explore when project-specific CLAUDE.md conventions matter.
- Fork subagent is cheapest for work that inherits parent context — it shares the prompt cache.
- Deferred tools save context tokens — they're loaded on demand via ToolSearch, so don't pre-load tools you might not need.

### Memory System Best Practices
- Save `feedback` memories for corrections and validated approaches — these are the most impactful memory type for improving collaboration over time.
- Memory frontmatter `description` fields must be specific and searchable — a separate LLM call selects up to 5 relevant memories per query based only on name + description.
- Never save things derivable from code, git history, or CLAUDE.md. Focus on: user preferences, project context (deadlines, decisions), external resource pointers, and corrections.
- MEMORY.md is capped at 200 lines / 25KB. Keep index entries to one line, ~150 chars. A background "dream" process consolidates memories periodically.

### Verification Discipline
Before non-trivial code changes, state the verification mechanism in one line — e.g., *"I'll verify by running `dotnet build` and `tests/PhoneNumber.UnitTests`"*. This commits to actually running the check and lets Tom redirect if the plan is wrong.

- **Default: propose, don't ask.** For most changes the verification path is obvious (build + relevant unit test project). State it; don't interrupt with a question.
- **Ask only on genuine gaps.** If the package has no test coverage for the affected path, or the change is visual/behavioral with a fuzzy spec, surface it: *"No existing tests cover this path — should I add a smoke test, or is manual verification sufficient?"*
- **UI changes**: take a screenshot of the result, compare against the original/target, list visible differences, and address them.
- **Build/runtime errors**: fix the root cause. Do not suppress the error or mask it with a workaround.
- Plan mode (`/plan`) already requires a verification section — this rule extends the same discipline to default mode for medium-sized work.

### Recognize and Reset on Failure Patterns
Watch for these context-pollution failure modes and reset early instead of pushing through:

- **Two-correction rule**: if Tom has corrected you twice on the same issue in one session, the context is polluted with failed approaches. Stop, summarize what was learned, and suggest `/clear` followed by a fresh prompt incorporating the learnings. Do not attempt a third correction in the same session.
- **Kitchen-sink session**: if the conversation has drifted across unrelated tasks, suggest `/clear` between them.
- **Infinite exploration**: scope investigations narrowly, or delegate to a subagent so reads don't pollute the main context.

### CLAUDE.md Pruning Discipline
CLAUDE.md content is loaded every session, so bloat causes important rules to be ignored. Apply the pruning test when reviewing or adding to any CLAUDE.md (global, project, or local):

- For each line, ask: *"Would removing this cause Claude to make mistakes?"* If not, cut it or move it to a skill (loaded on demand).
- **Keep**: bash commands Claude can't guess, project conventions that diverge from defaults, environment quirks, repository etiquette, common gotchas.
- **Cut**: anything derivable from the codebase, standard language conventions, file-by-file descriptions, self-evident principles ("write clean code"), long explanations.
- **Symptom of bloat**: Claude keeps doing something the file forbids, or asks questions the file already answers.
