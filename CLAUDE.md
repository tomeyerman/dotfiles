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
- `rules/` — modular rule files loaded automatically (context7, csharp-style, dotfiles-setup, proactive-guidance)
- `commands/` — slash commands (ast-grep, diff-coverage, copilot-dialogue, copilot-prompt)
- `references/` — reference docs bundled with commands (ast-grep-csharp)
- `scripts/` — helper scripts called by commands (diff_coverage.py)

Additional machine-local files live directly in `~/.claude/` (not in this repo): `rules/machine-local.md`, `rules/work-*.md`, `commands/es-logs.md`, `commands/port-forward.md`, `settings.json`, `plugins/`.

## Gotchas

- **Symlink awareness**: Edits to `~/.claude/CLAUDE.md` write through to this repo. Commit from here, not from `~/.claude/`.
- **Skills → Commands on Windows**: The Claude Code Skill tool doesn't follow symlinks on Windows. Use `commands/` (slash commands) instead of `skills/` for portable items.
- **Adding new portable files**: Create in `<repo>/claude/.claude/<path>`, then re-run stow/dploy to create the symlink. Update the symlinked-files list in `rules/dotfiles-setup.md`.
- **Neovim plugin manager**: lazy.nvim bootstraps itself on first run — no manual install step needed. Plugin specs live in `nvim/.config/nvim/lua/plugins/`.
- **`.bak` files in nvim**: Files like `telescope.lua.bak` and `neo-tree.lua.bak` are intentionally disabled plugin configs kept for reference.
