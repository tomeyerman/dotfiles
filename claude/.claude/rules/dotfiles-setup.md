## Dotfiles-Managed Config

Many files in `~/.claude/` are **symlinks** to a dotfiles repo (`tomeyerman/dotfiles` on GitHub). Do not move, delete, or replace them with regular files — edits write through the symlink automatically.

To find the dotfiles repo location on this machine, follow any symlink: `readlink ~/.claude/CLAUDE.md`

### Symlinked files (portable, tracked in dotfiles)
- `CLAUDE.md`
- `rules/context7.md`, `rules/csharp-style.md`, `rules/proactive-guidance.md`, `rules/dotfiles-setup.md`
- `commands/ast-grep.md`, `commands/diff-coverage.md`, `commands/stow.md`, `commands/new-portable.md`, `commands/prompt-review.md`
- `references/ast-grep-csharp.md`, `references/claude-prompting-best-practices.md`
- `scripts/diff_coverage.py`

### Local-only files (not symlinked, machine-specific)
- `rules/work-*.md`, `rules/machine-local.md`
- `commands/copilot-dialogue.md`, `commands/copilot-prompt.md`, `commands/es-logs.md`, `commands/port-forward.md`
- `settings.json`, `plugins/`, `projects/`

### Deployment
- **Windows:** `uv tool install dploy` then `dploy stow <dotfiles-repo>/claude/.claude ~/.claude` (requires [uv](https://docs.astral.sh/uv/) and Windows Developer Mode enabled for symlink creation)
- **Linux/macOS:** `cd <dotfiles-repo> && stow claude`

### When editing symlinked files
- Edits go directly to the dotfiles repo — commit from there when ready.
- To add a new portable file: create it in `<dotfiles-repo>/claude/.claude/`, then re-run the stow command to create the symlink.
- To add a machine-local file: create it directly in `~/.claude/` (not in the dotfiles repo).
- Skills (`~/.claude/skills/`) should be commands (`~/.claude/commands/`) instead — the Skill tool doesn't follow symlinks on Windows.
