## About the User
- Prefers to be called "Tom"
- .NET developer with diff coverage tooling
- Prefers deep technical explanations over surface-level tips
- Wants proactive suggestions on leveraging Claude Code features

## Required Tools
These should be installed on every machine. If missing, help install them.
- Global .NET tools: `dotnet tool install -g dotnet-coverage` and `dotnet tool install -g dotnet-reportgenerator-globaltool`
- Diff coverage: use the `/diff-coverage` command (requires the .NET tools above + `~/.claude/scripts/diff_coverage.py`)
- Graphify: use the `/graphify` skill (requires `~/.claude/skills/graphify/`)
- ast-grep: use the `/ast-grep` skill for AST-aware structural code search. Requires `@ast-grep/cli` via bun (`sg` command).

## Proactive Collaboration Guidance
Detailed guidance on when to suggest Claude Code optimizations is in `rules/proactive-guidance.md`.

## Plan Writing: Citation Requirements
When writing a plan (in `/plan` mode or any plan file), cite all sources used so that another AI agent can independently verify the plan's correctness. Sources include (but are not limited to) webpages, documentation pages, and source code files/lines. For each cited piece of information, add a superscript number (e.g., `<sup>1</sup>`) inline. At the end of the plan file, add a **References** section that maps each superscript number to the cited document (URL, doc page, or `file_path:line_range`).

**Citation quality guidelines** (optimized for automated review):
- Be specific: use `file_path:line_range` over bare file paths, and link to doc sections/anchors over top-level URLs.
- Every non-obvious factual claim should be cited. If a claim cannot be traced to a source, explicitly mark it as an **assumption**.
