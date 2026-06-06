## Code Search Tooling: How and When to Use Each Tool

When searching local code, pick the tool by **two axes**, not by habit:

1. **What kind of question is it?** — literal *text*, code *shape*, or semantic *meaning*.
2. **Can a fresh index be afforded right now?** — semantic tools borrow precision from a persistent index that must be built, kept warm, and kept in sync with disk. When that index can't stay fresh, its precision is an illusion.

The governing principle: **a stateless tool that re-reads disk every run can never be stale; a stateful index can silently return confidently-wrong answers.** On an actively-built monorepo, freshness beats semantic precision.

### Decision matrix

| Question | Tool | Why |
|---|---|---|
| Locate a declaration by name (class, interface, struct, record, method, property, field, enum, type) | **ast-grep (`sg`)** | AST-filtered, stateless, zero setup, single call |
| All real references / rename blast radius — **big or hot repo** (a large, actively-built monorepo) | **ast-grep + verify candidates** | Over-match is *visible and auditable*; never stale |
| All real references / rename blast radius — **small repo, index warm & fresh** | octocode `lspFindReferences` (conditional) | Semantic binding resolution beats shape — *only when fresh* |
| Call graph (who calls who) | small/warm repo → `lspCallHierarchy`; else ast-grep call sites + read to confirm | Call graph is LSP's one real edge over ast-grep |
| Literal text (log message, error string, comment, config key, JSON/YAML value, URL, path, ticket number, verbatim substring) | **Grep / ripgrep** | It's text, not a code entity |

### ast-grep is the default for code entities

When the search target is the **name of a code entity**, use ast-grep (the `sg` CLI), not Grep — for both *locating* declarations and (with a verification pass) *finding references*. This includes PascalCase identifiers, camelCase method names, and any symbol that exists as a named declaration. Do not wait for the user to invoke `/ast-grep`; run `sg` yourself.

**Trigger phrases that always route to ast-grep** (code-identifier searches regardless of verb):

- **"find all references to X"** / "where is X referenced" / "find references"
- "find all usages of X" / "where is X used" / "find all uses of"
- "find where X is defined" / "where is X declared" / "find the definition of"
- "find all implementations of" / "classes that extend" / "what inherits from" / "who implements"
- "find all call sites of" / "everywhere X is called"
- "find methods returning T" / "methods that accept Y" / "methods with attribute Z"
- "find DI registrations for" / "find constructor injection of"
- "find all instances of class X" / "where is X instantiated"

**Why Grep fails here:** a Grep for `OrderController` returns matches from `.github/CODEOWNERS`, `*.md` design docs, and the declaration itself — *only if* the default file-type filter happens to include `.cs`, which it often doesn't on the first call. That's 3–4 sequential calls to converge. `sg` with `-l csharp` filters to parsed C# source in one call, and AST filtering eliminates false positives in strings, comments, and identifiers that merely contain the substring. For code entities Grep is slower *and* less precise — the inverse of the usual tradeoff.

**"ast-grep + verify" for references:** ast-grep matches references by *shape*, so three unrelated `Process()` methods all match. This over-match is the *honest* failure mode — you get a candidate list and confirm the real ones by reading the few call sites or adding an AST constraint (receiver type, namespace, enclosing class). Bounded, fresh work — unlike a stale LSP answer you can't tell is wrong.

### octocode LSP is conditional, not the reflexive choice

`lspGotoDefinition` / `lspFindReferences` / `lspCallHierarchy` query the language server's resolved symbol graph — real bindings, not same-spelling collisions. That is genuinely *above* ast-grep for semantic questions. **But** it depends on a persistent index, which on a very large solution (tens of thousands of `.cs` files) breaks three ways: it takes **hours** to build, gets **killed** during builds/test runs (evicting the index), and goes **stale** — returning a wrong reference set without erroring.

**How octocode's LSP actually works** (octocode *spawns and manages the server itself* — it does not attach to your editor's):
- It bundles **only** the TypeScript/JavaScript server. Every other language's binary must be installed and on PATH. For C# it shells out to **`csharp-ls`** (`dotnet tool install -g csharp-ls`, or point `OCTOCODE_CSHARP_SERVER_PATH` at it) — **not** OmniSharp. `csharp-ls` is Roslyn/MSBuild-based, so it still pays the full solution-load cost, and is historically weaker than OmniSharp on huge solutions.
- It pools clients keyed on `(workspaceRoot, languageId)` and keeps them warm, but with an **idle timeout** — after a gap the client is evicted and the next call spawns cold (re-loads the solution).
- **Silent grep fallback:** when no server can be produced (csharp-ls absent, or the workspace won't load), `lspFindReferences` does **not** error — it degrades to a grep/ripgrep path and returns text matches *dressed as semantic references*. This is the silent-degradation failure mode this rule exists to prevent.

Therefore:

- **On a very large solution: treat LSP as effectively unavailable.** Default to ast-grep + verify for references. Beyond staleness, `csharp-ls` loading a solution that large is slow/fragile, and if it can't, you silently get grep results that look semantic.
- **On small repos** (a standalone library or service repo): LSP is worth it *only when* `csharp-ls` is installed (`dotnet tool list -g` / `where csharp-ls`) **and** the index is warm and post-dates the last build.
- **Before trusting `lspFindReferences`, confirm csharp-ls is installed and the workspace loaded** — otherwise the "references" may be grep output. And **state the freshness assumption out loud** ("assuming the index is warm and post-dates your last build") so it can be vetoed.
- For Roslyn-grade C# semantics without a persistent LSP, a one-shot Roslyn/`dotnet` analysis is the stateless equivalent — but it needs a build, so it collides with the same contention. Reserve it for a deliberate, high-stakes rename.

octocode's *text* tier (`localSearchCode`) is ripgrep under the hood — same blind spots as plain Grep for entity names. Its value over Grep is ergonomics (parallel multi-query, discovery mode, match-count ranking, `sort=modified`), not AST precision.

### How to invoke ast-grep

Invocation guide, pattern syntax, YAML rule recipes, and language reference:

- `~/.claude/commands/ast-grep.md` — general usage, pattern vs YAML modes, debug workflow
- `~/.claude/references/ast-grep-csharp.md` — **required reading before any C# pattern**; C# method declarations parse as `local_function_statement` in pattern mode, which silently returns wrong results.

Quick form (language-agnostic):
```bash
sg run -p 'PATTERN' -l LANGUAGE PATH --json=stream 2>/dev/null | head -20
```

Find identifier occurrences across C# code (fast first-pass for "references to X"):
```bash
sg run -p 'IDENTIFIER_NAME' -l csharp PATH --json=stream 2>/dev/null | head -20
```

For large repos (tens of thousands of .cs files, where a full scan can take ~20s), always cap with `| head -N` and narrow `PATH` to a relevant subtree.

### Framework-discovered classes (ASP.NET controllers, DI-registered services)

Some classes — MVC controllers, ASP.NET middleware, hosted services — are instantiated by the framework via reflection and attribute routing. They may legitimately have zero compile-time references outside their own file. When reporting results for such a class, note this explicitly rather than implying the search missed something. The structural search is still the right tool; a zero-reference result is a real finding.
