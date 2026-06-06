# ast-grep C# Reference

C#-specific patterns, tree-sitter node kinds, and gotchas for ast-grep structural search.

## Critical: Pattern Mode Limitations in C#

In C#, method declarations as patterns (`public void Foo() { }`) are parsed by tree-sitter as
`local_function_statement`, NOT `method_declaration`. This means **pattern mode silently matches
the wrong node kind**. Always use YAML rules with `kind: method_declaration` for methods.

**What works as patterns in C#:**
- `public class $NAME { $$$BODY }` — class declarations
- `public class $NAME : $BASE { $$$BODY }` — class with single base type
- `[HierarchyRoot] public class $NAME : $BASE { $$$BODY }` — attributed class with base
- `Console.WriteLine($$$ARGS)` — method call expressions
- `return $EXPR;` — return statements
- `$OBJ.$METHOD($$$ARGS)` — any method call on any object
- `services.AddSingleton<$IFACE, $IMPL>()` — specific DI call
- `await $EXPR` — any await expression

**What does NOT work as patterns (use YAML rules instead):**
- Method declarations — parsed as `local_function_statement`
- Property declarations
- Interface declarations with members
- Patterns where `$NAME` would need to match a generic name like `Foo<T>` in isolation

## C# Tree-Sitter Node Kinds

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
| `try_statement` | `try { } catch { }` |
| `object_creation_expression` | `new Foo()` |

## C# YAML Rule Recipes

Find classes implementing a specific interface:
```yaml
rule:
  kind: class_declaration
  has:
    kind: base_list
    has:
      kind: identifier
      regex: ^IMyInterface$
      stopBy: end
    stopBy: end
```

Find async methods:
```yaml
rule:
  kind: method_declaration
  has:
    kind: modifier
    regex: async
    stopBy: end
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
      stopBy: end
    stopBy: end
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
      stopBy: end
    stopBy: end
```

Find properties with a specific type:
```yaml
rule:
  kind: property_declaration
  has:
    kind: predefined_type
    regex: ^string$
    stopBy: end
```

Find async methods without try-catch:
```yaml
rule:
  all:
    - kind: method_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          kind: try_statement
          stopBy: end
```

Find constructor injection (primary constructors):
```yaml
rule:
  kind: class_declaration
  has:
    kind: parameter_list
    stopBy: end
```

## Large Monorepo Tips

In a very large C# repo (tens of thousands of .cs files), a full structural scan can take many seconds.

1. **ALWAYS limit output**: `| head -N` (start with 20) or `| wc -l` for count
2. **Narrow the PATH**: search a specific module/subtree, not the entire repo root
3. **Redirect stderr**: `2>/dev/null` suppresses parse warnings
4. **Get a count first** before dumping all results
5. **Combine with grep for post-filtering** when the structural match is broad:
   ```bash
   sg run -p 'public class $NAME { $$$BODY }' -l csharp PATH --json=stream 2>/dev/null | grep 'Invoice'
   ```
