# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility


## Standard library additions and changes

[//]: # "Changes:"


[//]: # "Additions:"

[//]: # "Deprecations:"


[//]: # "Removals:"


## Language changes

- [Tag tracking](https://nim-lang.github.io/Nim/manual.html#effect-system-tag-tracking) supports the definition of forbidden tags by the `.forbids` pragma
  which can be used to disable certain effects in proc types.
- [Case statement macros](https://nim-lang.github.io/Nim/manual.html#macros-case-statement-macros) are no longer experimental,
  meaning you no longer need to enable the experimental switch `caseStmtMacros` to use them.
- Full command syntax and block arguments i.e. `foo a, b: c` are now allowed
  for the right-hand side of type definitions in type sections. Previously
  they would error with "invalid indentation".
- `defined` now accepts identifiers separated by dots, i.e. `defined(a.b.c)`.
  In the command line, this is defined as `-d:a.b.c`. Older versions can
  use accents as in ``defined(`a.b.c`)`` to access such defines.
- [Macro pragmas](https://nim-lang.github.io/Nim/manual.html#userminusdefined-pragmas-macro-pragmas) changes:
  - Templates now accept macro pragmas.
  - Macro pragmas for var/let/const sections have been redesigned in a way that works
    similarly to routine macro pragmas. The new behavior is documented in the
    [experimental manual](https://nim-lang.github.io/Nim/manual_experimental.html#extended-macro-pragmas).
  - Pragma macros on type definitions can now return `nnkTypeSection` nodes as well as `nnkTypeDef`,
    allowing multiple type definitions to be injected in place of the original type definition.

    ```nim
    import macros
    macro multiply(amount: static int, s: untyped): untyped =
      let name = $s[0].basename
      result = newNimNode(nnkTypeSection)
      for i in 1 .. amount:
        result.add(newTree(nnkTypeDef, ident(name & $i), s[1], s[2]))
    type
      Foo = object
      Bar {.multiply: 3.} = object
        x, y, z: int
      Baz = object
    # becomes
    type
      Foo = object
      Bar1 = object
        x, y, z: int
      Bar2 = object
        x, y, z: int
      Bar3 = object
        x, y, z: int
      Baz = object
    ```

- Redefining templates with the same signature implicitly was previously
  allowed to support certain macro code. A `{.redefine.}` pragma has been
  added to make this work explicitly, and a warning is generated in the case
  where it is implicit. This behavior only applies to templates, redefinition
  is generally disallowed for other symbols.

- A new form of type inference called [top-down inference](https://nim-lang.github.io/Nim/manual_experimental.html#topminusdown-type-inference)
  has been implemented for a variety of basic cases. For example, code like the following now compiles:

  ```nim
  let foo: seq[(float, byte, cstring)] = @[(1, 2, "abc")]
- Alias-style templates and macros can now optionally be annotated with the
  `{.alias.}` pragma. For templates, this has the behavior of disallowing
  redefinitions.
- The `{.alias.}` pragma has been added to annotate templates and macros
  meant to be used in [alias-style](https://nim-lang.github.io/Nim/manual_experimental.html#aliasminusstyle-templates-and-macros).
  Currently the only semantic behavior of this pragma is that templates with
  it cannot be implicitly redefined.

  ```nim
  type Foo = object
    bar: int
  
  var foo = Foo(bar: 10)
  template bar: int {.alias.} = foo.bar
  assert bar == 10
  bar = 15
  assert bar == 15
  var foo2 = Foo(bar: -10)
  # redefinition error:
  template bar: int {.alias.} = foo.bar
  ```
  
- A new form of type inference called [top-down inference](https://nim-lang.github.io/Nim/manual_experimental.html#topminusdown-type-inference)
  has been implemented for a variety of basic cases. For example, code like the following now compiles:
  
  ```nim
  let foo: seq[(float, byte, cstring)] = @[(1, 2, "abc")]
  ```

- `cstring` is now accepted as a selector in `case` statements, removing the
  need to convert to `string`. On the JS backend, this is translated directly
  to a `switch` statement.

- Nim now supports `out` parameters and ["strict definitions"](https://nim-lang.github.io/Nim/manual_experimental.html#strict-definitions-and-nimout-parameters).
- Nim now offers a [strict mode](https://nim-lang.github.io/Nim/manual_experimental.html#strict-case-objects) for `case objects`.


## Compiler changes




## Tool changes

