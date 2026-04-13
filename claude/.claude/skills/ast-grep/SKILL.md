---
name: ast-grep
description: >
  Structural code search using ast-grep (tree-sitter AST patterns). Use for any search that needs
  syntax awareness: finding interface implementations, class hierarchies, method signatures with
  specific return types, attribute usage, DI registrations, constructor injection patterns, or
  type declarations. Use whenever the user says "find all implementations of", "find all classes
  that extend", "find methods returning", "find all uses of attribute", "structural search",
  "find where X is registered", "who implements", or "what inherits from". Also use proactively
  when Grep alone cannot express the search (e.g., distinguishing a type name used as a base class
  vs. a variable name). Do NOT use for simple text/string searches, log messages, comments, or
  config values -- Grep is faster for those.
trigger: /ast-grep
---

# ast-grep — Structural Code Search

Search codebases using tree-sitter AST patterns instead of text regex. Finds code by its syntactic
structure, so `class $NAME : IFoo` matches class declarations inheriting `IFoo` regardless of
whitespace, modifiers, or surrounding code.

## When to Use ast-grep vs Grep

| Need | Tool | Why |
|------|------|-----|
| Classes implementing an interface | ast-grep | Structure matters — Grep can't distinguish base-list from variable usage |
| Method declarations with a specific return type | ast-grep | Needs AST node kind `method_declaration` |
| Attribute usage on classes or methods | ast-grep | Pattern or YAML rule on `attribute` kind |
| Constructor injection patterns | ast-grep | Structural match on primary constructors or ctor parameters |
| DI registration calls | ast-grep | Pattern match on method invocations |
| A specific string, log message, or comment | Grep | Text search — ast-grep adds no value |
| A simple identifier or symbol name | Grep | Faster, simpler |
| Config keys or values (JSON/YAML) | Grep | Text matching is sufficient |

## Preflight

Before first use, verify ast-grep is installed:

```bash
sg --version
```

If not found, install via bun: `bun install -g @ast-grep/cli`, then copy the binary:
```bash
cp "$HOME/.bun/install/global/node_modules/@ast-grep/cli-win32-x64-msvc/ast-grep.exe" "$HOME/.bun/bin/sg.exe"
```

## Two Search Modes

ast-grep has two search modes. Choosing correctly is critical for C#.

### Mode 1: Pattern (`sg run -p`)

Use for: **class declarations, expressions, statements, method calls, attribute-decorated classes.**

Patterns are C# code fragments with meta-variables. They work when the fragment is parseable as
a standalone valid C# construct.

```bash
sg run -p 'PATTERN' -l csharp PATH --json=stream 2>/dev/null | head -N
```

**What works as patterns:**
- `public class $NAME { $$$BODY }` — find all public classes
- `public class $NAME : $BASE { $$$BODY }` — class with single base type
- `[HierarchyRoot] public class $NAME : $BASE { $$$BODY }` — attributed class with base
- `Console.WriteLine($$$ARGS)` — method call expressions
- `return $EXPR;` — return statements
- `$OBJ.$METHOD($$$ARGS)` — any method call on any object
- `services.AddSingleton<$IFACE, $IMPL>()` — specific DI registration call
- `await $EXPR` — any await expression

**What does NOT work as patterns (use YAML rules instead):**
- Method declarations (`public void Foo()` — parsed as `local_function_statement`, not `method_declaration`)
- Property declarations
- Interface declarations with members
- Patterns where `$NAME` would need to match a generic name like `Foo<T>` in isolation

### Mode 2: YAML Rule (`sg scan -r`)

Use for: **method declarations, property declarations, finding implementations of a specific
interface by name, any search that needs `kind` filtering or relational constraints (`has`,
`inside`, `precedes`, `follows`).**

Write a temporary YAML rule file:

```bash
cat > /tmp/sg_rule.yaml << 'YAML'
id: my-search
language: csharp
rule:
  kind: NODE_KIND
  has:
    kind: CHILD_KIND
    regex: PATTERN
YAML
sg scan -r /tmp/sg_rule.yaml PATH --json=stream 2>/dev/null | head -N
```

**Common YAML rule patterns:**

Find all method declarations:
```yaml
rule:
  kind: method_declaration
```

Find async methods:
```yaml
rule:
  kind: method_declaration
  has:
    kind: modifier
    regex: async
```

Find classes implementing a specific interface:
```yaml
rule:
  kind: class_declaration
  has:
    kind: base_list
    has:
      kind: identifier
      regex: ^IMyInterface$
```

Find classes with a specific attribute:
```yaml
rule:
  kind: class_declaration
  has:
    kind: attribute
    has:
      kind: identifier
      regex: ^HierarchyRoot$
```

Find methods inside a specific class:
```yaml
rule:
  kind: method_declaration
  inside:
    kind: class_declaration
    has:
      kind: identifier
      regex: ^MyClassName$
```

Find properties with a specific type:
```yaml
rule:
  kind: property_declaration
  has:
    kind: predefined_type
    regex: ^string$
```

## Meta-Variable Syntax (for Pattern Mode)

| Syntax | Matches | Example |
|--------|---------|---------|
| `$NAME` | Exactly one AST node | `class $NAME` matches a class name |
| `$$$ITEMS` | Zero or more nodes | `{ $$$BODY }` matches any block contents |
| Literal code | Itself | `return true;` matches that exact statement |

Patterns must be syntactically valid C# fragments. They are NOT regex.

## C# Tree-Sitter Node Kinds Reference

When writing YAML rules, use these `kind` values:

| Kind | Matches |
|------|---------|
| `class_declaration` | `class Foo { }` |
| `interface_declaration` | `interface IFoo { }` |
| `struct_declaration` | `struct Bar { }` |
| `record_declaration` | `record Baz(...)` |
| `enum_declaration` | `enum Color { }` |
| `method_declaration` | Methods inside types |
| `constructor_declaration` | Constructors |
| `property_declaration` | Properties |
| `field_declaration` | Fields |
| `attribute` | `[Foo]` — a single attribute |
| `attribute_list` | `[Foo, Bar]` — the bracket group |
| `base_list` | `: IFoo, BaseClass` |
| `parameter_list` | `(int x, string y)` |
| `parameter` | Single parameter |
| `modifier` | `public`, `async`, `static`, etc. |
| `identifier` | A name token |
| `predefined_type` | `int`, `string`, `bool`, etc. |
| `generic_name` | `List<T>`, `Task<bool>` |
| `invocation_expression` | Method calls |
| `using_directive` | `using System;` |
| `namespace_declaration` | `namespace Foo { }` |
| `file_scoped_namespace_declaration` | `namespace Foo;` |

When in doubt about the node kind for a specific syntax, dump the AST:
```bash
sg run -p 'YOUR_KNOWN_MATCH' -l csharp FILE --debug-query=cst 2>&1 | head -40
```

## Performance Guidelines for Large Repos

The ServiceTitan monorepo has 54K+ .cs files. A full scan takes ~20 seconds.

1. **ALWAYS limit output**: pipe through `| head -N` (start with 20) or `| wc -l` for count
2. **Narrow the PATH**: search `Modules/Telecom/` not the entire repo root
3. **Redirect stderr**: `2>/dev/null` suppresses parse warnings on non-C# files
4. **Exclude build artifacts**: not needed — ast-grep with `-l csharp` only processes `.cs` files, and the tree-sitter parser handles generated code fine. If results include unwanted dirs, narrow PATH instead.
5. **Get a count first** before dumping all results:
   ```bash
   sg run -p 'PATTERN' -l csharp PATH --json=stream 2>/dev/null | wc -l
   ```
6. **Combine with grep for post-filtering** when the structural match is broad but you need a specific name:
   ```bash
   sg run -p 'public class $NAME { $$$BODY }' -l csharp PATH --json=stream 2>/dev/null | grep 'Invoice'
   ```

## JSON Output Format

With `--json=stream`, each line is one JSON object:

```json
{
  "text": "matched code text",
  "range": {"start": {"line": N, "column": N}, "end": {"line": N, "column": N}},
  "file": "path/to/file.cs",
  "lines": "matched lines with context",
  "language": "CSharp",
  "metaVariables": {"single": {"NAME": {"text": "ActualName"}}, "multi": {}, "transformed": {}},
  "ruleId": "rule-id",
  "labels": [{"text": "...", "range": {...}, "style": "primary|secondary"}]
}
```

- `file` — the matched file path
- `range.start.line` — zero-based line number
- `text` — the full matched code snippet
- `metaVariables.single.NAME.text` — captured value of `$NAME` (pattern mode)
- `labels` with `style: "secondary"` — sub-matches from YAML `has` clauses

## Crafting New Patterns (AST Dump Workflow)

When you need to match unfamiliar C# syntax:

1. Find one example file containing the code you want to match
2. Match it with a broad known-working pattern and dump the CST:
   ```bash
   sg run -p 'class $NAME' -l csharp FILE --debug-query=cst 2>&1 | head -60
   ```
3. Read the node kinds and structure from the CST output
4. Write a YAML rule using those node kinds
5. Test on the single file first, then expand to the full repo

## Common Pitfalls

1. **Method declarations need YAML rules** — `public void Foo() { }` as a pattern parses as a local function, not a method declaration. Always use `kind: method_declaration` in a YAML rule.
2. **Bash can mangle `$$$`** — in some shells, `$$$` is interpreted. Single quotes protect against this, but if you see numbers replacing your meta-variables, the shell is the problem.
3. **`--lang csharp` is required** — without it, ast-grep may pick the wrong parser or skip .cs files.
4. **Start broad, then narrow** — if a specific pattern returns nothing, simplify it. Remove modifiers, reduce meta-variables, or switch from pattern to YAML rule.
5. **Generic types in patterns** — `List<$T>` works, but matching a class whose name is generic (like `class Foo<T>`) requires either a broad `class $NAME` or a YAML rule with `kind: class_declaration`.
6. **Zero-based line numbers** — JSON output uses zero-based lines, not one-based.

## Quick Reference

```bash
# Find all public classes in a directory
sg run -p 'public class $NAME { $$$BODY }' -l csharp PATH --json=stream 2>/dev/null | head -20

# Find classes implementing a specific interface (YAML rule)
cat > /tmp/sg_rule.yaml << 'YAML'
id: find-impl
language: csharp
rule:
  kind: class_declaration
  has:
    kind: base_list
    has:
      kind: identifier
      regex: ^IMyInterface$
YAML
sg scan -r /tmp/sg_rule.yaml PATH --json=stream 2>/dev/null | head -20

# Find async methods (YAML rule)
cat > /tmp/sg_rule.yaml << 'YAML'
id: find-async
language: csharp
rule:
  kind: method_declaration
  has:
    kind: modifier
    regex: async
YAML
sg scan -r /tmp/sg_rule.yaml PATH --json=stream 2>/dev/null | head -20

# Find attributed classes
sg run -p '[HierarchyRoot] public class $NAME : $BASE { $$$BODY }' -l csharp PATH --json=stream 2>/dev/null | head -20

# Find method calls on a specific type
sg run -p '$OBJ.RegisterSinglePerHubLazy<$$$ARGS>()' -l csharp PATH --json=stream 2>/dev/null | head -20

# Count matches
sg run -p 'public class $NAME { $$$BODY }' -l csharp PATH --json=stream 2>/dev/null | wc -l

# Dump AST for pattern crafting
sg run -p 'class $NAME' -l csharp FILE --debug-query=cst 2>&1 | head -60
```
