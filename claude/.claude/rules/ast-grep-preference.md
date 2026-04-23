## Prefer ast-grep for Code Identifier Searches

**Default rule: when the search target is the name of a code entity — a class, interface, struct, record, method, property, field, function, enum, or type — use ast-grep (the `sg` CLI), not Grep.** This includes PascalCase identifiers, camelCase method names, and any symbol that exists as a named declaration in the source. Do not wait for the user to invoke `/ast-grep`; run `sg` yourself.

Grep is the right tool *only* when you are searching for:
- A log message, error string, comment, or documentation phrase
- A config key, JSON/YAML value, URL, path, ticket number, or literal substring
- Text you already know verbatim that isn't a named code entity

### Trigger phrases that always route to ast-grep

All of these are code-identifier searches regardless of the verb:

- **"find all references to X"** / "where is X referenced" / "find references"
- "find all usages of X" / "where is X used" / "find all uses of"
- "find where X is defined" / "where is X declared" / "find the definition of"
- "find all implementations of" / "classes that extend" / "what inherits from" / "who implements"
- "find all call sites of" / "everywhere X is called"
- "find methods returning T" / "methods that accept Y" / "methods with attribute Z"
- "find DI registrations for" / "find constructor injection of"
- "find all instances of class X" / "where is X instantiated"

### Why Grep fails for identifier searches (the observed failure mode)

A Grep for `BandwidthPortOutController` returns matches from:
- `.sistr/CODEOWNERS` (documentation of ownership)
- `*.md` plan and design documents
- The class declaration itself — *if the default file-type filter happens to include `.cs`, which it often does not on the first call*

The user then has to either filter results by hand or re-run Grep with explicit `type: "cs"` or path restrictions, typically 3–4 sequential calls to converge on the real answer. ast-grep with `-l csharp` filters to parsed C# source files in a single call, and further AST-based filtering eliminates false positives in strings, comments, and identifiers that merely contain the substring. For code entities, Grep is slower *and* less precise than ast-grep — the inverse of the usual tradeoff.

### How to invoke ast-grep

The full invocation guide, pattern syntax, YAML rule recipes, and language reference live in:

- `~/.claude/commands/ast-grep.md` — general usage, pattern vs YAML modes, debug workflow
- `~/.claude/references/ast-grep-csharp.md` — **required reading before any C# pattern**; C# method declarations parse as `local_function_statement` in pattern mode, which silently returns wrong results.

Read those files when you need invocation details rather than guessing syntax.

Quick form (language-agnostic):
```bash
sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | head -20
```

Find identifier occurrences across C# code (fast first-pass for "references to X"):
```bash
sg run -p 'IDENTIFIER_NAME' -l csharp PATH --json=stream 2>/dev/null | head -20
```

For large repos (e.g., `D:\ServiceTitan\app` has 54K+ .cs files, ~20s full scan), always cap with `| head -N` and narrow `PATH` to a relevant subtree when possible.

### Framework-discovered classes (ASP.NET controllers, DI-registered services)

Some classes — MVC controllers, ASP.NET middleware, hosted services — are instantiated by the framework via reflection and attribute routing. They may legitimately have zero compile-time references outside their own file. When reporting results for such a class, note this explicitly rather than implying the search missed something. The structural search is still the right tool; a zero-reference result is a real finding.
