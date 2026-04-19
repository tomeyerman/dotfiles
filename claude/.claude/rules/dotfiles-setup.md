## Dotfiles-Managed Config

Many files in `~/.claude/` are **symlinks** to a dotfiles repo (`tomeyerman/dotfiles` on GitHub). Do not move, delete, or replace them with regular files — edits write through the symlink automatically.

To find the dotfiles repo location on this machine, follow any symlink: `readlink ~/.claude/CLAUDE.md`

### What's symlinked (granularity matters)

**Directory symlinks** — the entire directory points into the repo. Every file inside lives in the repo.

- `~/.claude/commands/` → `<repo>/claude/.claude/commands/`
- `~/.claude/rules/` → `<repo>/claude/.claude/rules/`
- `~/.claude/references/` → `<repo>/claude/.claude/references/`
- `~/.claude/scripts/` → `<repo>/claude/.claude/scripts/`

**File symlinks** — individual top-level files.

- `~/.claude/CLAUDE.md` → `<repo>/claude/.claude/CLAUDE.md`

Everything else at the top level of `~/.claude/` (`settings.json`, `plans/`, `plugins/`, `projects/`, `sessions/`, `skills/`, etc.) is machine-local — not a symlink.

### Consequences of directory-level symlinks

Because `commands/`, `rules/`, `references/`, and `scripts/` are **directory** symlinks (not per-file):

- **Adding a portable file is stow-free.** Creating `~/.claude/commands/foo.md` (or `<repo>/claude/.claude/commands/foo.md` — same path through the symlink) makes it live on this machine immediately. Re-stow only when adding a **new top-level entry**: a new top-level file, or a new subdirectory that needs its own directory symlink.
- **Machine-local files inside these dirs still land in the repo on disk.** A file at `~/.claude/rules/work-corp.md` is physically stored in the dotfiles repo and shows as untracked in `git status`. Use `.gitignore` patterns (see repo-root `.gitignore`) to keep them out of commits.

### Machine-local files that live inside symlinked dirs

These sit inside the symlinked directories on disk, so they need `.gitignore` coverage to stay out of commits:

- `rules/work-*.md`, `rules/machine-local.md`
- `commands/copilot-dialogue.md`, `commands/copilot-prompt.md`, `commands/es-logs.md`, `commands/port-forward.md`

### Deployment

- **Windows:** `uv tool install dploy` then `dploy stow <repo>/claude/.claude ~/.claude` (requires [uv](https://docs.astral.sh/uv/) and Windows Developer Mode enabled for symlink creation)
- **Linux/macOS:** `cd <repo> && stow claude`

### When editing symlinked files

- Edits go directly to the dotfiles repo — commit from there when ready.
- Skills (`~/.claude/skills/`) should be commands (`~/.claude/commands/`) instead — the Skill tool doesn't follow symlinks on Windows.
