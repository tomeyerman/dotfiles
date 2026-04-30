Run a diff coverage analysis for the current .NET project to validate test coverage on branch changes.

User context: $ARGUMENTS

**IMPORTANT: If you are in plan mode, call ExitPlanMode immediately before doing anything else. This skill executes a workflow — it must not be treated as a planning task. After the workflow completes, if you exited plan mode to run this skill, call EnterPlanMode to restore the previous mode.**

## Instructions

Execute the full diff coverage workflow end-to-end. Resolve all placeholders automatically by inspecting the project — do not ask the user unless something is genuinely ambiguous.

### Step 0: Resolve parameters

- **Test project**: If the user specified one, use it. Otherwise, find `*Tests*.csproj` files in the repo. If multiple exist, pick the one most relevant to the changed files (or run all of them).
- **Base branch**: If the user specified one, use it. Otherwise, default to `develop`. If `develop` doesn't exist, try `main`, then `master`.
- **Runsettings**: Search for `.runsettings` files in the repo. If one exists, use `-s <path>`. If none exist, omit the flag.
- **Target**: Default 90% unless the user specified otherwise.

### Step 1: Run tests with coverage collection

Use `dotnet-coverage collect` to drive `dotnet test`. This produces a single merged XML directly and bypasses the legacy VS data collector (Vanguard / `CodeCoverage.exe`), which fails on .NET 10 SDK with `Running event not received from CodeCoverage.exe`.

```
dotnet-coverage collect --output "TestResults/output.xml" --output-format xml -- dotnet test <test-project> [-s <runsettings>]
```

**On test failures:** check whether any failing test exercises a changed file (cross-reference the failure stack traces against `git diff --name-only <base-branch>...HEAD`). If a failure touches the changed code, stop and report — coverage on broken behavior is misleading. If failures are clearly unrelated to the diff (different files, different feature areas, pre-existing on the base branch), proceed but **call them out explicitly** in the final report so the user can triage them separately.

> **Why not `dotnet test --collect:"Code Coverage"`?** That path invokes the legacy Microsoft.CodeCoverage VS data collector (`microsoft.codecoverage` package), which spawns `CodeCoverage.exe` (Vanguard). On .NET 10 SDK (10.0.203+) Vanguard times out at startup, the data collector logs `Running event not received from CodeCoverage.exe`, and no `.coverage` files are produced. `dotnet-coverage collect` uses the modern in-proc collector and is the only path that reliably works across SDK versions. It also consolidates the previous "run + separate `dotnet-coverage merge`" pair into a single command.

### Step 2: Identify changed source files

Run `git diff --name-only <base-branch>...HEAD -- '*.cs'` to get the list of changed C# files. Build the `filefilters` string for reportgenerator from these filenames (e.g., `+*FileName1*;+*FileName2*`).

### Step 3: Generate Cobertura XML

```
reportgenerator "-reports:TestResults/output.xml" -reporttypes:Cobertura "-targetdir:TestResults/cobertura" "-filefilters:<filters-from-step-2>"
```

### Step 4: Run diff coverage script

```
python ~/.claude/scripts/diff_coverage.py --base-branch <base> --cobertura TestResults/cobertura/Cobertura.xml [--target <target>]
```

**Script flags:**
- `--base-branch` — branch to diff against (default: `develop`)
- `--cobertura` — path to Cobertura XML (default: `TestResults/cobertura/Cobertura.xml`)
- `--target` — target coverage % (default: `90`)
- `--sources` — explicit source file list (default: auto-detect from diff)

### Step 5: Report results

Present the output clearly. If coverage is below target, highlight which files/lines are uncovered and suggest what tests could improve coverage. If step 1 surfaced unrelated test failures, list them under a separate "Unrelated test failures" section so they don't get conflated with the coverage outcome.

## Prerequisites

If either tool is missing, tell the user to install them:
- `dotnet tool install -g dotnet-coverage`
- `dotnet tool install -g dotnet-reportgenerator-globaltool`

