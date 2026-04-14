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
