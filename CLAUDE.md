# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Cross-platform dotfiles managed with GNU Stow. Each top-level directory is a **stow package** — its contents mirror the target home directory structure and get symlinked into place.

## Stow Packages

| Package | Target | What it configures |
|---------|--------|--------------------|
| `alacritty` | `~/.config/alacritty/` | Alacritty terminal |
| `bashrc` | `~/` | Bash shell (`.bashrc`) |
| `claude` | `~/.claude/` | Claude Code (CLAUDE.md, rules, commands, references, scripts) |
| `ghostty` | `~/.config/ghostty/` | Ghostty terminal |
| `inputrc` | `~/` | Readline (`.inputrc`) |
| `nvim` | `~/.config/nvim/` | Neovim (lazy.nvim plugin manager, Lua config) |
| `starship` | `~/.config/` | Starship prompt |

## Deployment Commands

```bash
# Linux/macOS — from repo root
stow <package>          # deploy one package
stow alacritty bashrc claude ghostty inputrc nvim starship  # deploy all

# Windows — requires dploy (pip install dploy)
dploy stow <repo>/<package>/<target-subpath> <home-target>
# Example: dploy stow claude/.claude ~/.claude
```

`archsetup.sh` installs Arch Linux dependencies and stows all non-claude packages.

## Claude Package Structure

The `claude` package is the most complex. Its contents symlink to `~/.claude/`:

- `CLAUDE.md` — global user instructions (applies to all projects)

Files inside `claude/` are **deployed artifacts** — treat them like `.bashrc` or `alacritty.toml`. Edit them when asked, but don't audit or "improve" them as part of repo maintenance.

- `rules/` — modular rule files loaded automatically (context7, csharp-style, dotfiles-setup, proactive-guidance)
- `commands/` — slash commands (ast-grep, diff-coverage, stow, new-portable)
- `references/` — reference docs bundled with commands (ast-grep-csharp)
- `scripts/` — helper scripts called by commands (diff_coverage.py)

Additional machine-local files live directly in `~/.claude/` (not in this repo): `rules/machine-local.md`, `rules/work-*.md`, `commands/copilot-dialogue.md`, `commands/copilot-prompt.md`, `commands/es-logs.md`, `commands/port-forward.md`, `settings.json`, `plugins/`.

## Verifying Deployment

```bash
# Confirm symlinks point back to this repo
readlink ~/.claude/CLAUDE.md       # should show path into this repo's claude/.claude/
ls -la ~/.claude/rules/            # symlinked rules show -> ../../dotfiles/...
```

## Adding a New Stow Package

1. Create `<package-name>/` at repo root, mirroring the target home directory structure
2. Add the package to `archsetup.sh` if it should be deployed on Arch Linux
3. Run `stow <package-name>` (or `dploy stow`) to deploy

## Gotchas

- **Symlink awareness**: Edits to `~/.claude/CLAUDE.md` write through to this repo. Commit from here, not from `~/.claude/`.
- **Skills → Commands on Windows**: The Claude Code Skill tool doesn't follow symlinks on Windows. Use `commands/` (slash commands) instead of `skills/` for portable items.
- **Adding new portable files**: Create in `<repo>/claude/.claude/<path>`, then re-run stow/dploy to create the symlink. Update the symlinked-files list in `rules/dotfiles-setup.md`.
- **Neovim plugin manager**: lazy.nvim bootstraps itself on first run — no manual install step needed. Plugin specs live in `nvim/.config/nvim/lua/plugins/`.
- **`.bak` files in nvim**: Files like `telescope.lua.bak` and `neo-tree.lua.bak` are intentionally disabled plugin configs kept for reference.
- **Concurrent sessions**: Multiple Claude Code sessions may edit files in this repo simultaneously. Re-read files before editing if the session has been running a while.

## Workflow Commands

- `/stow [package]` — deploy symlinks after adding new portable files (default: `claude` package)
- `/new-portable <rule|command|reference> <name>` — scaffold a new portable config file, stow it, and update the manifest
