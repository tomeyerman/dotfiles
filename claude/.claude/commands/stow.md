---
description: Deploy dotfiles symlinks via stow/dploy. Use after adding new portable files.
disable-model-invocation: true
argument-hint: "[package name, default: claude]"
allowed-tools: Bash(dploy *) Bash(stow *) Bash(readlink *) Bash(ls *) Bash(uname *)
---

Deploy dotfiles symlinks for a stow package.

User context: $ARGUMENTS

## Steps

### 1. Resolve the dotfiles repo path

```bash
readlink ~/.claude/CLAUDE.md
```

Extract the repo root by stripping `/claude/.claude/CLAUDE.md` from the symlink target.

### 2. Determine the package

If the user specified a package name, use it. Otherwise default to `claude`.

### 3. Detect platform and deploy

```bash
uname -s
```

- **Linux/macOS** (output contains `Linux` or `Darwin`):
  ```bash
  cd <repo-root> && stow <package>
  ```
- **Windows** (output contains `MINGW`, `MSYS`, or `CYGWIN`, or uname fails):
  The target depends on the package:
  - `claude` → `dploy stow <repo>/claude/.claude ~/.claude`
  - `nvim` → `dploy stow <repo>/nvim/.config/nvim ~/.config/nvim`
  - Others follow the same pattern: `dploy stow <repo>/<package>/<target-subpath> ~/<target-subpath>`

### 4. Verify

```bash
ls -la ~/.claude/CLAUDE.md  # for claude package — should show symlink arrow
```

Report which symlinks were created or updated.

## Gotcha: Stow folds directories

Stow creates **one symlink per directory** when every child would be stowed (directory folding). For the `claude` package this means `~/.claude/commands`, `~/.claude/references`, `~/.claude/rules`, and `~/.claude/scripts` are each a single directory symlink into the repo — not per-file symlinks. Only `~/.claude/CLAUDE.md` is an individual file symlink.

Consequences:
- **New files added to the repo appear automatically** under the folded directories — re-running stow is a no-op and is not needed just because a new file landed in `claude/.claude/commands/`.
- **`rm ~/.claude/commands/foo.md` deletes `foo.md` from the repo** (it'll show up in `git status` as a deletion). To remove a deployed file, delete it from the repo.
- Edits through `~/.claude/` paths write through to the repo — commit from the repo.
- Re-stowing is only needed when adding a **new top-level entry** directly under `~/.claude/` (e.g., a new `~/.claude/scripts/` directory when none existed before).

If a file appears as a regular file (not a symlink) at `~/.claude/commands/foo.md`, don't assume stow needs to run — that file is reachable *through* the parent directory symlink and is already the repo copy.
