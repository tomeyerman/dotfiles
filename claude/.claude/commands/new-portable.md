---
description: Create a new portable Claude Code config file (rule, command, or reference) in the dotfiles repo and deploy it.
disable-model-invocation: true
argument-hint: "<type: rule|command|reference> <name>"
allowed-tools: Write Read Edit Bash(dploy *) Bash(stow *) Bash(readlink *) Bash(uname *)
---

Create a new portable Claude Code config file in the dotfiles repo, deploy it via stow, and register it.

User context: $ARGUMENTS

## Steps

### 1. Parse arguments

Extract the file type and name from the user's input:
- **type**: `rule`, `command`, or `reference`
- **name**: the filename without extension (e.g., `my-rule` becomes `my-rule.md`)

If either is missing, ask the user.

### 2. Locate the dotfiles repo

```bash
REPO=$(readlink ~/.claude/CLAUDE.md | sed 's|/claude/.claude/CLAUDE.md||')
```

### 3. Create the file with appropriate frontmatter

**Rule** (`<repo>/claude/.claude/rules/<name>.md`):
```markdown
## <Title>

<Rule content here>
```

**Command** (`<repo>/claude/.claude/commands/<name>.md`):
```yaml
---
description: <One-line description>
disable-model-invocation: true
argument-hint: "[arguments]"
allowed-tools: Read Grep Glob
---

<Command instructions here>

User context: $ARGUMENTS
```

**Reference** (`<repo>/claude/.claude/references/<name>.md`):
```markdown
# <Title>

<Reference content here>
```

Write the file with the template. If the user provided content or a description, incorporate it.

### 4. Deploy the symlink

Detect platform and run stow/dploy (same logic as `/stow` command):
- **Linux/macOS**: `cd <repo> && stow claude`
- **Windows**: `dploy stow <repo>/claude/.claude ~/.claude`

### 5. Verify the symlink

```bash
ls -la ~/.claude/<type>s/<name>.md
```

Confirm it points back to the dotfiles repo.

### 6. Update the manifest

Edit `<repo>/claude/.claude/rules/dotfiles-setup.md` — add the new file to the appropriate line in the "Symlinked files" section.

Report the file path and symlink status to the user.
