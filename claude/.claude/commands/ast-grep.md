Structural code search using ast-grep (tree-sitter AST patterns). Use for any search that needs syntax awareness: finding interface implementations, class hierarchies, method signatures with specific return types, attribute usage, DI registrations, constructor injection patterns, or type declarations. Use whenever the user says "find all implementations of", "find all classes that extend", "find methods returning", "find all uses of attribute", "structural search", "find where X is registered", "who implements", or "what inherits from". Also use proactively when Grep alone cannot express the search (e.g., distinguishing a type name used as a base class vs. a variable name). Do NOT use for simple text/string searches, log messages, comments, or config values -- Grep is faster for those.

User context: $ARGUMENTS

# ast-grep — Structural Code Search

Search codebases using tree-sitter AST patterns instead of text regex. Finds code by its syntactic
structure rather than text, enabling searches like "find all classes implementing interface X"
that are impossible with regex.

**If searching C# code, read `~/.claude/references/ast-grep-csharp.md` for C#-specific patterns,
tree-sitter node kinds, and critical gotchas before proceeding.**

## When to Use ast-grep vs Grep

| Need | Tool | Why |
|------|------|-----|
| Type/class hierarchies and inheritance | ast-grep | Structure matters — Grep can't distinguish base-list from variable usage |
| Method declarations with specific signatures | ast-grep | Needs AST node kind matching |
| Attribute/decorator usage on declarations | ast-grep | Pattern or YAML rule on attribute kind |
| Constructor/DI injection patterns | ast-grep | Structural match on constructors or parameters |
| Specific function/method call patterns | ast-grep | Pattern match on invocation expressions |
| A specific string, log message, or comment | Grep | Text search — ast-grep adds no value |
| A simple identifier or symbol name | Grep | Faster, simpler |
| Config keys or values (JSON/YAML) | Grep | Text matching is sufficient |

## Preflight

Verify ast-grep is installed:

```bash
sg --version
```

If not found, install via bun: `bun install -g @ast-grep/cli`. On Windows, the bun shim may be
broken — copy the real binary:
```bash
cp "$HOME/.bun/install/global/node_modules/@ast-grep/cli-win32-x64-msvc/ast-grep.exe" "$HOME/.bun/bin/sg.exe"
```

## Two Search Modes

### Mode 1: Pattern (`sg run -p`)

Use for: **class/type declarations, expressions, statements, function/method calls.**

Patterns are code fragments with meta-variables. They work when the fragment is parseable as
a standalone valid construct in the target language.

```bash
sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | head -N
```

**Meta-variable syntax:**

| Syntax | Matches | Example |
|--------|---------|---------|
| `$NAME` | Exactly one AST node | `class $NAME` matches a class name |
| `$$$ITEMS` | Zero or more nodes | `{ $$$BODY }` matches any block contents |
| Literal code | Itself | `return true;` matches that exact statement |

Patterns must be syntactically valid code fragments in the target language. They are NOT regex.

**Examples (language-agnostic):**
- `$OBJ.$METHOD($$$ARGS)` — any method call on any object
- `await $EXPR` — any await expression
- `return $EXPR;` — return statements
- `console.log($$$ARGS)` — specific function calls (JS/TS)
- `def $NAME($$$PARAMS):` — function definitions (Python)

### Mode 2: YAML Rule (`sg scan -r` or `--inline-rules`)

Use for: **anything requiring `kind` filtering, relational constraints (`has`, `inside`,
`precedes`, `follows`), or composite logic (`all`, `any`, `not`).** Also required when
pattern mode silently matches the wrong node type (language-specific — check the reference
file for your language).

**Option A: Inline rules (preferred — no temp files):**
```bash
sg scan --inline-rules "id: my-search
language: LANGUAGE
rule:
  kind: NODE_KIND
  has:
    kind: CHILD_KIND
    regex: PATTERN
    stopBy: end" PATH --json=stream 2>/dev/null | head -N
```

Note: escape `$` as `\$` in inline rules when using double quotes.

**Option B: Rule file (for complex rules or when escaping is awkward):**
```bash
cat > /tmp/sg_rule.yaml << 'YAML'
id: my-search
language: LANGUAGE
rule:
  kind: NODE_KIND
  has:
    kind: CHILD_KIND
    regex: PATTERN
    stopBy: end
YAML
sg scan -r /tmp/sg_rule.yaml PATH --json=stream 2>/dev/null | head -N
```

**Critical: Always use `stopBy: end` in relational rules.** Without it, `has` and `inside` stop
searching at the first non-matching child node instead of traversing the entire subtree. This
causes silent missed matches.

**Common YAML rule patterns (language-agnostic):**

Find nodes of a specific kind:
```yaml
rule:
  kind: function_declaration  # varies by language
```

Find nodes containing a specific pattern:
```yaml
rule:
  kind: function_declaration
  has:
    pattern: await $EXPR
    stopBy: end
```

Find nodes inside a specific context:
```yaml
rule:
  kind: call_expression
  inside:
    kind: class_declaration
    stopBy: end
```

Find code missing expected patterns:
```yaml
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          kind: try_statement
          stopBy: end
```

## Crafting New Patterns (AST Dump Workflow)

When you need to match unfamiliar syntax in any language:

1. Find one example file containing the code you want to match
2. Dump the CST to see the tree-sitter node structure:
   ```bash
   sg run -p 'KNOWN_MATCH' -l LANGUAGE FILE --debug-query=cst 2>&1 | head -60
   ```
3. Read the node kinds from the CST output
4. Write a YAML rule using those node kinds
5. Test on the single file first, then expand to the full repo

Available debug formats:
- `--debug-query=cst` — Concrete Syntax Tree (all nodes including punctuation)
- `--debug-query=ast` — Abstract Syntax Tree (named nodes only)
- `--debug-query=pattern` — How ast-grep interprets your pattern

## JSON Output Format

With `--json=stream`, each line is one JSON object:

```json
{
  "text": "matched code text",
  "range": {"start": {"line": N, "column": N}, "end": {"line": N, "column": N}},
  "file": "path/to/file",
  "lines": "matched lines with context",
  "language": "LanguageName",
  "metaVariables": {"single": {"NAME": {"text": "ActualName"}}, "multi": {}, "transformed": {}},
  "ruleId": "rule-id",
  "labels": [{"text": "...", "range": {...}, "style": "primary|secondary"}]
}
```

Key fields:
- `file` — matched file path
- `range.start.line` — zero-based line number
- `text` — full matched code snippet
- `metaVariables.single.NAME.text` — captured value of `$NAME` (pattern mode)
- `labels` with `style: "secondary"` — sub-matches from YAML `has` clauses

## Performance Guidelines for Large Repos

1. **ALWAYS limit output**: `| head -N` (start with 20) or `| wc -l` for count
2. **Narrow the PATH**: search a specific subdirectory, not the entire repo
3. **Redirect stderr**: `2>/dev/null` suppresses parse warnings
4. **Specify the language**: `-l LANGUAGE` avoids processing irrelevant files
5. **Get a count first** before dumping all results:
   ```bash
   sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | wc -l
   ```
6. **Combine with grep for post-filtering** when the structural match is broad:
   ```bash
   sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | grep 'keyword'
   ```

## Common Pitfalls

1. **Some declaration types need YAML rules** — In many languages, certain declarations parse as different node kinds when written as standalone code fragments vs. inside a class/module. If a pattern returns no results unexpectedly, try a YAML rule with `kind` instead.
2. **Missing `stopBy: end`** — Relational rules (`has`, `inside`) without `stopBy: end` stop at the first non-matching child. This silently misses matches. Always add it.
3. **Shell can mangle `$`** — `$NAME` and `$$$` may be interpreted by the shell. Use single quotes for patterns. For `--inline-rules` with double quotes, escape as `\$`.
4. **`--lang` is required** — without it, ast-grep may pick the wrong parser or skip files.
5. **Start broad, then narrow** — if a pattern returns nothing, simplify it. Remove modifiers, reduce meta-variables, or switch from pattern to YAML rule.
6. **Zero-based line numbers** — JSON output uses zero-based lines, not one-based.

## Language Reference Files

For language-specific patterns, node kinds, and gotchas, read the appropriate reference:
- **C#**: `~/.claude/references/ast-grep-csharp.md`

## Quick Reference

```bash
# Pattern search (any language)
sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | head -20

# Inline YAML rule search
sg scan --inline-rules "id: my-search
language: LANGUAGE
rule:
  kind: NODE_KIND
  has:
    pattern: \$PATTERN
    stopBy: end" PATH --json=stream 2>/dev/null | head -20

# Rule file search
cat > /tmp/sg_rule.yaml << 'YAML'
id: my-search
language: LANGUAGE
rule:
  kind: NODE_KIND
YAML
sg scan -r /tmp/sg_rule.yaml PATH --json=stream 2>/dev/null | head -20

# Count matches
sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | wc -l

# Dump AST for pattern crafting
sg run -p 'KNOWN_MATCH' -l LANGUAGE FILE --debug-query=cst 2>&1 | head -60
```
