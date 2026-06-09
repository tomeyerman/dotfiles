# scripts

Run-on-demand utility scripts. **Not** a stow package — these are tracked for
portability but invoked by path, not symlinked into `$HOME`.

## Git `.vfs` (Scalar build) upgrade helpers

The microsoft/git "Git for Windows" installer refuses to overwrite `git.exe` /
`ssh-agent.exe` while any process holds them open. On this machine two things
continuously respawn those binaries, so killing them by hand is whack-a-mole:

- **FSMonitor daemons** — `core.fsmonitor` is set **globally**, so any git call
  (notably Warp's per-tab `git diff --shortstat` polling) lazily spawns a
  resident `git fsmonitor--daemon` that locks `git.exe`.
- **Git-bundled `ssh-agent`** — `~/.profile` auto-starts `ssh-agent` in every
  **login** git-bash, locking `<GitRoot>\usr\bin\ssh-agent.exe`.

These scripts disable both spawn triggers at the source (plus the scheduled Git
maintenance tasks), kill the current offenders, then restore everything.

```powershell
# 1. Before launching the installer:
pwsh -File ~/dotfiles/scripts/git-vfs-upgrade-prep.ps1

# 2. Run the Git installer — it should no longer report processes in use.

# 3. After it finishes:
pwsh -File ~/dotfiles/scripts/git-vfs-upgrade-restore.ps1
```

`prep` reports a daemon/agent count of 0 when it's safe to install. If it warns
that something is still running, a **login git-bash tab** is respawning
`ssh-agent` — close it and re-run `prep`. Both scripts are idempotent and need
no admin rights.
