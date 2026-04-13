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
