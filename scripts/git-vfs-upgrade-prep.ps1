<#
.SYNOPSIS
  Prepare for a Git for Windows (microsoft/git ".vfs" / Scalar build) upgrade by
  removing every process and setting that holds the Git install directory open,
  so the installer can overwrite git.exe / ssh-agent.exe without
  "the following process(es) use Git for Windows" prompts.

.DESCRIPTION
  Two things keep relaunching Git binaries during an upgrade on this machine:

    1. FSMonitor daemons - `core.fsmonitor=true` is set GLOBALLY, so ANY git
       invocation lazily spawns `git fsmonitor--daemon`, which then stays
       resident and locks git.exe. The biggest offender is Warp terminal's
       per-tab git polling (`git diff --shortstat HEAD`), which fires on an
       interval across every open tab. Killing daemons alone is whack-a-mole;
       you must remove the SPAWN TRIGGER (global fsmonitor) first.

    2. Git-bundled ssh-agent - ~/.profile (stock Git-for-Windows template)
       auto-starts ssh-agent in every LOGIN git-bash shell, which locks
       <GitRoot>\usr\bin\ssh-agent.exe. Moving ~/.profile aside stops any
       login shell from re-spawning it.

  This disables both spawn triggers at the source, disables the scheduled Git
  maintenance tasks (which run `git maintenance run` and would respawn a
  daemon), then kills the current offenders. Run git-vfs-upgrade-restore.ps1
  after the installer finishes to undo everything.

.NOTES
  - No admin required: maintenance tasks and the daemons/ssh-agent are all
    per-user processes.
  - Killing ssh-agent clears loaded SSH keys for the session; they reload on the
    next login git-bash (ssh-add) after restore.
  - Leaves the Windows OpenSSH agent service (C:\Windows\System32\OpenSSH\...)
    untouched - only the Git-bundled ssh-agent blocks the installer.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$profilePath = Join-Path $HOME '.profile'
$profileBak  = "$profilePath.git-upgrade-bak"

function Get-GitRoot {
    # ...\Git\cmd\git.exe  ->  ...\Git
    $src = (Get-Command git.exe -ErrorAction SilentlyContinue).Source
    if ($src) { return (Split-Path (Split-Path $src -Parent) -Parent) }
    return 'C:\Program Files\Git'
}
$gitRoot = Get-GitRoot
Write-Host "Git install root: $gitRoot" -ForegroundColor Cyan

function Get-GitDaemons {
    Get-CimInstance Win32_Process -Filter "Name='git.exe'" |
        Where-Object { $_.CommandLine -like '*fsmonitor--daemon*' }
}
function Get-GitSshAgents {
    # Only ssh-agent.exe running from inside the Git install dir (not Windows OpenSSH)
    Get-CimInstance Win32_Process -Filter "Name='ssh-agent.exe'" |
        Where-Object {
            $_.ExecutablePath -and
            $_.ExecutablePath.StartsWith($gitRoot, [System.StringComparison]::OrdinalIgnoreCase)
        }
}
function Get-GitMaintenanceTasks {
    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskName -like 'Git Maintenance*' -or ($_.Actions.Arguments -match 'maintenance\s+run')
    }
}

# 1. Disable Git maintenance tasks (they run `git maintenance run` -> respawns a daemon)
Write-Host "`n[1/4] Disabling Git maintenance scheduled tasks..." -ForegroundColor Yellow
$tasks = Get-GitMaintenanceTasks
if ($tasks) {
    $tasks | Disable-ScheduledTask | Out-Null
    $tasks | ForEach-Object { "      disabled: $($_.TaskName)" }
} else {
    "      (no git maintenance tasks found)"
}

# 2. Disable global FSMonitor so no git invocation can spawn a daemon
Write-Host "`n[2/4] Disabling global core.fsmonitor..." -ForegroundColor Yellow
git config --global core.fsmonitor false
"      core.fsmonitor (global) = $(git config --global --get core.fsmonitor)"

# 3. Move ~/.profile aside so a login git-bash can't auto-start ssh-agent
Write-Host "`n[3/4] Neutralizing ssh-agent auto-start (~/.profile)..." -ForegroundColor Yellow
if (Test-Path $profileBak) {
    "      backup already exists ($([System.IO.Path]::GetFileName($profileBak))) - prep already run, leaving as-is"
} elseif (Test-Path $profilePath) {
    Move-Item -LiteralPath $profilePath -Destination $profileBak -Force
    "      moved ~/.profile -> $([System.IO.Path]::GetFileName($profileBak))"
} else {
    "      no ~/.profile present - nothing to do"
}

# 4. Kill current daemons + Git-bundled ssh-agent (retry briefly in case one is mid-spawn)
Write-Host "`n[4/4] Killing FSMonitor daemons + Git ssh-agent..." -ForegroundColor Yellow
for ($attempt = 1; $attempt -le 3; $attempt++) {
    $procs = @(Get-GitDaemons) + @(Get-GitSshAgents)
    if (-not $procs) { break }
    foreach ($p in $procs) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            "      killed $($p.ProcessId) ($($p.Name))"
        } catch {
            "      could not kill $($p.ProcessId): $($_.Exception.Message)"
        }
    }
    Start-Sleep -Milliseconds 400
}

# Verify
$dCount = @(Get-GitDaemons).Count
$sCount = @(Get-GitSshAgents).Count
Write-Host "`n=== Ready to install? ===" -ForegroundColor Cyan
"  FSMonitor daemons remaining: $dCount"
"  Git ssh-agent remaining:     $sCount"
if ($dCount -eq 0 -and $sCount -eq 0) {
    Write-Host "  OK - run the Git installer now, then run git-vfs-upgrade-restore.ps1" -ForegroundColor Green
} else {
    Write-Host "  WARNING - still running. A LOGIN git-bash (e.g. a Git-Bash terminal tab)" -ForegroundColor Red
    Write-Host "  may be respawning ssh-agent - close it and re-run this script." -ForegroundColor Red
}
