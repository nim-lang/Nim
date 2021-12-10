# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility

- The `Math.trunc` polyfill for targeting Internet Explorer was
  previously emitted for every JavaScript output file except if
  the symbol `nodejs` was defined via `-d:nodejs`. Now, it is only
  emitted if the symbol `nimJsMathTruncPolyfill` is defined. If you are
  targeting Internet Explorer, you may choose to enable this option
  or define your own `Math.trunc` polyfill using the [`emit` pragma](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma). Nim uses
  `Math.trunc` for the division and modulo operators for integers.

- Optional parameters in combination with `: body` syntax (RFC #405) are now opt-in via
  `experimental:flexibleOptionalParams`.

- `std/sharedstrings` module is removed.

## Standard library additions and changes

- `macros.parseExpr` and `macros.parseStmt` now accept an optional
  filename argument for more informative errors.

## `std/smtp`

- Sends `ehlo` first. If the mail server does not understand, it sends `helo` as a fallback.

## Language changes

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
- [Case statement macros](manual.html#macros-case-statement-macros) are no longer experimental,
  meaning you no longer need to enable the experimental switch `caseStmtMacros` to use them.

## Compiler changes

- `nim` can now compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`,
  without requiring `-d:nimVersion140` which is now a noop.


## Tool changes

- The `gc` switch has been renamed to `mm` ("memory management") in order to reflect the
  reality better. (Nim moved away from all techniques based on "tracing".)

- Nim now supports Nimble version 0.14 which added support for lock-files. This is done by
  a simple configuration change setting that you can do yourself too. In `$nim/config/nim.cfg`
  replace `pkgs` by `pkgs2`.

- There is a new switch `--nimMainPrefix:prefix` to influence the `NimMain` that the
  compiler produces. This is particularly useful for generating static libraries.
