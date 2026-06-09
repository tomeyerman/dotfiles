<#
.SYNOPSIS
  Undo git-vfs-upgrade-prep.ps1: restore ssh-agent auto-start, re-enable global
  FSMonitor, and re-enable the Git maintenance scheduled tasks.

.DESCRIPTION
  Run this AFTER the Git for Windows installer reports success. It is the exact
  inverse of git-vfs-upgrade-prep.ps1 and is safe to run more than once.

.NOTES
  FSMonitor daemons are NOT restarted here - they respawn lazily on the next
  `git status` in each repo, automatically using the freshly-installed binary.
  Your SSH keys reload on the next login git-bash via the restored ~/.profile.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$profilePath = Join-Path $HOME '.profile'
$profileBak  = "$profilePath.git-upgrade-bak"

Write-Host "Installed Git version: $(git --version)" -ForegroundColor Cyan

# 1. Restore ~/.profile
Write-Host "`n[1/3] Restoring ~/.profile..." -ForegroundColor Yellow
if (Test-Path $profileBak) {
    Move-Item -LiteralPath $profileBak -Destination $profilePath -Force
    "      restored ~/.profile"
} elseif (Test-Path $profilePath) {
    "      ~/.profile already present, no backup to restore - nothing to do"
} else {
    "      WARNING: neither ~/.profile nor backup found"
}

# 2. Re-enable global FSMonitor
Write-Host "`n[2/3] Re-enabling global core.fsmonitor..." -ForegroundColor Yellow
git config --global core.fsmonitor true
"      core.fsmonitor (global) = $(git config --global --get core.fsmonitor)"

# 3. Re-enable Git maintenance tasks
Write-Host "`n[3/3] Re-enabling Git maintenance scheduled tasks..." -ForegroundColor Yellow
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -like 'Git Maintenance*' -or ($_.Actions.Arguments -match 'maintenance\s+run')
}
if ($tasks) {
    $tasks | Enable-ScheduledTask | Out-Null
    $tasks | ForEach-Object { "      enabled: $($_.TaskName) [$((Get-ScheduledTask -TaskName $_.TaskName).State)]" }
} else {
    "      (no git maintenance tasks found)"
}

Write-Host "`n=== Restore complete ===" -ForegroundColor Green
"  FSMonitor daemons will respawn lazily on the next 'git status' per repo."
