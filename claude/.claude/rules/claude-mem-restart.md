## Restarting the claude-mem Worker on Windows

The plugin's own CLI (`worker-cli.js restart`) has a Windows-only startup race that causes the new worker to clean-exit ~700ms after spawn with the log line `"Worker already running (PID alive), refusing to start duplicate"`. Investigate locally before fetching external docs — the plugin source is authoritative and ships with this machine.

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

### Verifying

- Health: `Invoke-RestMethod http://127.0.0.1:37777/api/health` (port from `CLAUDE_MEM_WORKER_PORT`, default 37777). Expect `status: ok`, `initialized: true`, `mcpReady: true`.
- Bun process: `Get-Process -Name bun`. Note the health endpoint's `pid` is the inner worker, while `~/.claude-mem/worker.pid` holds the wrapper's PID — mismatch is normal.

### Diagnosing

- Today's log: `~/.claude-mem/logs/worker-YYYY-MM-DD.log` (and `.log.err`). The `[wrapper]` lines tell you whether the inner exited cleanly (race) vs crashed.
- Plugin source on Windows: `~/.claude/plugins/marketplaces/thedotmack/plugin/scripts/`. The `cache\thedotmack\claude-mem\<version>\scripts\` copy is identical (same SHA1).
- A worker resident-set climbing past ~500MB+ has historically indicated a memory leak — restart is a reasonable first response.
