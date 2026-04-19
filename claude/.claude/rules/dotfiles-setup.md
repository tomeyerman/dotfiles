## Dotfiles-Managed Config

Many files in `~/.claude/` are **symlinks** to a dotfiles repo (`tomeyerman/dotfiles` on GitHub). Do not move, delete, or replace them with regular files — edits write through the symlink automatically.

To find the dotfiles repo location on this machine, follow any symlink: `readlink ~/.claude/CLAUDE.md`

### How stow decides symlink granularity (folding vs unfolding)

Stow creates a **directory symlink** when it can — one symlink covers the whole directory. This is *folding*. If the target directory already has non-stow files at stow time, stow can't fold (the symlink would hide the existing files) and instead creates the target as a real directory with **per-file symlinks** inside for the package's files. This is *unfolding*.

The granularity for any given path depends on the target's state when stow ran — not on this repo's structure. The same package can produce different symlink shapes on different machines. Don't trust a hardcoded list; check the current machine.

### Checking what's symlinked here

```bash
# Top-level entries in ~/.claude/ — which are symlinks (file or dir)?
ls -la ~/.claude/ | grep '^l'

# Is a given subdir folded (whole-dir symlink) or unfolded (per-file symlinks)?
readlink ~/.claude/commands                # non-empty → folded (the dir itself is a symlink)
ls -la ~/.claude/commands/ | grep '^l'     # listed per-file symlinks → unfolded
```

### Consequences

- **Folded dir** (directory symlink): every file inside is physically in the repo. Creating `~/.claude/commands/foo.md` writes through to `<repo>/claude/.claude/commands/foo.md`. Machine-local files created in a folded dir need `.gitignore` coverage.
- **Unfolded dir** (per-file symlinks): only the package's own files are symlinked; machine-local files created in the target are real local files, not in the repo. `.gitignore` is irrelevant for them.
- **Adding a new portable file**: always add it to `<repo>/claude/.claude/<subdir>/`. If the target subdir is folded, it appears immediately through the dir symlink. If unfolded, re-run stow (or dploy) so it creates the new per-file symlink. When in doubt, re-stow — it's idempotent.

### Known machine-local patterns

The repo's `.gitignore` already covers these so they stay out of commits when the containing dir is folded:

- `rules/work-*.md`, `rules/machine-local.md`
- `commands/copilot-*.md`, `commands/es-logs.md`, `commands/port-forward.md`

If you add a new machine-local file inside a folded dir, extend `.gitignore` to match.

### Deployment

- **Windows:** `uv tool install dploy` then `dploy stow <repo>/claude/.claude ~/.claude` (requires [uv](https://docs.astral.sh/uv/) and Windows Developer Mode enabled for symlink creation)
- **Linux/macOS:** `cd <repo> && stow claude`

### When editing symlinked files

- Edits go directly to the dotfiles repo — commit from there when ready.
- Skills (`~/.claude/skills/`) should be commands (`~/.claude/commands/`) instead — the Skill tool doesn't follow symlinks on Windows.
