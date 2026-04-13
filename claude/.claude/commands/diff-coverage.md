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

### Step 1: Run tests with coverage

```
dotnet test <test-project> --collect:"Code Coverage" --results-directory "TestResults" [-s <runsettings>]
```

If tests fail, report the failures and stop — don't proceed with broken coverage data.

### Step 2: Merge coverage files

```
dotnet-coverage merge -o "TestResults/output.xml" -f xml "TestResults/**/*.coverage" --remove-input-files
```

### Step 3: Identify changed source files

Run `git diff --name-only <base-branch>...HEAD -- '*.cs'` to get the list of changed C# files. Build the `filefilters` string for reportgenerator from these filenames (e.g., `+*FileName1*;+*FileName2*`).

### Step 4: Generate Cobertura XML

```
reportgenerator "-reports:TestResults/output.xml" -reporttypes:Cobertura "-targetdir:TestResults/cobertura" "-filefilters:<filters-from-step-3>"
```

### Step 5: Run diff coverage script

```
python ~/.claude/scripts/diff_coverage.py --base-branch <base> --cobertura TestResults/cobertura/Cobertura.xml [--target <target>]
```

**Script flags:**
- `--base-branch` — branch to diff against (default: `develop`)
- `--cobertura` — path to Cobertura XML (default: `TestResults/cobertura/Cobertura.xml`)
- `--target` — target coverage % (default: `90`)
- `--sources` — explicit source file list (default: auto-detect from diff)

### Step 6: Report results

Present the output clearly. If coverage is below target, highlight which files/lines are uncovered and suggest what tests could improve coverage.

## Prerequisites

If either tool is missing, tell the user to install them:
- `dotnet tool install -g dotnet-coverage`
- `dotnet tool install -g dotnet-reportgenerator-globaltool`

