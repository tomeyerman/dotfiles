## Restarting the claude-mem Worker on Windows

The plugin's own CLI (`worker-cli.js restart`) has a Windows-only startup race that causes the new worker to clean-exit ~700ms after spawn with the log line `"Worker already running (PID alive), refusing to start duplicate"`. Investigate locally before fetching external docs — the plugin source is authoritative and ships with this machine.

**Platform scope:** every failure mode in this file has only been encountered on **Windows** so far. The non-Windows start path differs — `worker-cli.js` spawns `worker-service.cjs` directly as a detached, `unref`'d process (no PowerShell `Start-Process`, no `worker-wrapper.cjs` intermediary), so the wrapper/PID race and the orphaned-socket symptoms below haven't surfaced on Linux/macOS.

### The race

1. `worker-cli.js` `start` launches `worker-wrapper.cjs` via PowerShell `Start-Process -PassThru` and gets back the wrapper's PID.
2. CLI immediately writes that wrapper PID to `~/.claude-mem/worker.pid`.
3. Wrapper spawns the inner `worker-service.cjs`.
4. Inner reads `worker.pid`, sees the wrapper PID is alive (it is — wrapper is its own parent), and exits 0 via the duplicate-instance guard (`worker-service.cjs` near line 11422 in v13.2.0; search `"refusing to start duplicate"`).
5. Wrapper sees inner gone, exits.

There is no `existingPid !== process.pid && existingPid !== process.ppid` check in the guard, and `CLAUDE_MEM_MANAGED=true` (set by the wrapper) does not gate it. Upstream tracks this in GitHub issues #363, #367, #371, #373.

### Reliable restart

```powershell
$bun = "$env:USERPROFILE\.bun\bin\bun.exe"
$cli = "$env:USERPROFILE\.claude\plugins\marketplaces\thedotmack\plugin\scripts\worker-cli.js"
& $bun $cli stop
Remove-Item "$env:USERPROFILE\.claude-mem\worker.pid" -ErrorAction SilentlyContinue
& $bun $cli start
```

Deleting the stale pid file between `stop` and `start` lets the race resolve the right way (inner reads no file → proceeds). If `start` still fails, retry — it's timing-dependent.

### When restart silently no-ops: orphaned socket + stale spawn.lock (post-crash)

A *distinct* failure mode from the race above. After an abrupt worker death (killed via `taskkill /T /F`, OOM, etc.) the crash can leave stale state that makes **every** restart — including the "Reliable restart" above — silently fail. Recognise it by: worker dead, `…/api/health` refused, **no `bun` process**, yet `worker-cli.js start` reports `Failed to start: Process died during startup` (that message is the *wrapper* dying, not a diagnosis). A large uncheckpointed `~/.claude-mem/claude-mem.db-wal` is the corroborating crash signature.

The inner worker's real log is **`~/.claude-mem/logs/claude-mem-YYYY-MM-DD.log`** — NOT `worker-*.log` (which holds only `[wrapper]` lines). Read it to see why the inner bailed.

**Blocker 1 — orphaned LISTENING socket.** `netstat -ano | findstr :37777` shows `LISTENING` on a PID that no longer exists (`tasklist /FI "PID eq <pid>"` → "No tasks"; `Get-CimInstance Win32_Process -Filter "ProcessId=<pid>"` → empty; raw TCP connect → refused). The dead worker's listen socket is wedged in the TCP table. **Windows has no command to free a dead process's socket — only a reboot clears it.** While it persists, the inner's `listen()` hits `EADDRINUSE` → loud `Worker failed to start. Is port 37777 in use?` + exit 1 in the claude-mem log. (On Windows the *first* server guard `Yl(port)` is a `/api/health` fetch, so a refusing orphan reads as "not in use" and is NOT caught there — the bind is what fails.)

**Blocker 2 — stale `spawn.lock`.** `~/.claude-mem/spawn.lock` = `{"pid":<dead>,…}`. The inner boots (logs `Cached SKILL.md / viewer.html / onboarding explainer at boot`) then logs `Another launcher holds the spawn lock — skipping lazy-spawn` and exits 0 — deferring to a launcher that no longer exists.

**Clear the stale state (reboot-free path):**
```powershell
$d = "$env:USERPROFILE\.claude-mem"
& "$env:USERPROFILE\.bun\bin\bun.exe" "$env:USERPROFILE\.claude\plugins\marketplaces\thedotmack\plugin\scripts\worker-cli.js" stop
Remove-Item "$d\worker.pid","$d\spawn.lock","$d\.worker-start-attempted" -ErrorAction SilentlyContinue
# port 37777 stays wedged → point the worker at a free port; both worker and hooks read this:
# edit ~/.claude-mem/settings.json: "CLAUDE_MEM_WORKER_PORT": "37787"
```

**Caveat:** clearing the locks + moving the port removes the *known* blockers, but in practice the worker may still exit 0 right after the boot-cache lines without binding (cause not fully pinned — it dies in its own boot/dispatch stage before the server guards, emitting nothing further). **The only reliable fix is a reboot** — it frees the orphaned socket and resets all post-crash state and any competing wedged launchers from other sessions. Treat the no-reboot path as a stopgap; after rebooting, revert `CLAUDE_MEM_WORKER_PORT` to `37777`.

**Unblock a wedged session while the worker stays down.** After `CLAUDE_MEM_HOOK_FAIL_LOUD_THRESHOLD` (default `3`) consecutive failures, the `UserPromptSubmit` session-init hook *blocks prompt submission* (`claude-mem worker unreachable for N consecutive hooks`); the counter persists in `~/.claude-mem/state/hook-failures.json`. To make the hook proceed gracefully instead of blocking (reversible — revert once the worker is healthy):
```powershell
# settings.json: raise "CLAUDE_MEM_HOOK_FAIL_LOUD_THRESHOLD" well above the counter (e.g. "1000000")
'{"consecutiveFailures":0,"lastFailureAt":0}' | Set-Content "$env:USERPROFILE\.claude-mem\state\hook-failures.json"
```
The hook re-reads claude-mem's `settings.json` per invocation, so the stuck session works on the next prompt (no Claude Code restart needed). Memory capture/injection stays off until the worker is healthy.

### Verifying

- Health: `Invoke-RestMethod http://127.0.0.1:37777/api/health` (port from `CLAUDE_MEM_WORKER_PORT`, default 37777). Expect `status: ok`, `initialized: true`, `mcpReady: true`.
- Bun process: `Get-Process -Name bun`. Note the health endpoint's `pid` is the inner worker, while `~/.claude-mem/worker.pid` holds the wrapper's PID — mismatch is normal.

### Diagnosing

- Today's log: `~/.claude-mem/logs/worker-YYYY-MM-DD.log` (and `.log.err`). The `[wrapper]` lines tell you whether the inner exited cleanly (race) vs crashed.
- Plugin source on Windows: `~/.claude/plugins/marketplaces/thedotmack/plugin/scripts/`. The `cache\thedotmack\claude-mem\<version>\scripts\` copy is identical (same SHA1).
- A worker resident-set climbing past ~500MB+ has historically indicated a memory leak — restart is a reasonable first response.
