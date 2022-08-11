# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility

- `addr` is now available for all addressable locations,
  `unsafeAddr` is now deprecated and an alias for `addr`.

- `io`, `assertions`, `formatfloat`, and `` dollars.`$` `` for objects are about to move out of the `system` module. You may instead import `std/syncio`, `std/assertions`, `std/formatfloat` and `std/objectdollar`.
  The `-d:nimPreviewSlimSystem` option makes these imports required.

- The `gc:v2` option is removed.

- The `threads:on` option is now the default.

- Optional parameters in combination with `: body` syntax (RFC #405) are now opt-in via
  `experimental:flexibleOptionalParams`.

- The `Math.trunc` polyfill for targeting Internet Explorer was
  previously included in most JavaScript output files.
  Now, it is only included with `-d:nimJsMathTruncPolyfill`.
  If you are targeting Internet Explorer, you may choose to enable this option
  or define your own `Math.trunc` polyfill using the [`emit` pragma](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma).
  Nim uses `Math.trunc` for the division and modulo operators for integers.

- `shallowCopy` is removed for ARC/ORC. Use `move` when possible or combine assignment and
`sink` for optimization purposes.

- `nimPreviewDotLikeOps` is going to be removed or deprecated.

- The `{.this.}` pragma, deprecated since 0.19, has been removed.
- `nil` is no longer a valid value for distinct pointer types.
- The `type Foo = object {.final.}` pragma syntax for types, which was
  deprecated since Nim 0.20.0, has been removed.
- Removed two type pragma syntaxes deprecated since 0.20, namely
  `type Foo = object {.final.}`, and `type Foo {.final.} [T] = object`.

## Standard library additions and changes

[//]: # "Changes:"
- `macros.parseExpr` and `macros.parseStmt` now accept an optional
  filename argument for more informative errors.
- Module `colors` expanded with missing colors from the CSS color standard.
  `colPaleVioletRed` and `colMediumPurple` have also been changed to match the CSS color standard.
- Fixed `lists.SinglyLinkedList` being broken after removing the last node ([#19353](https://github.com/nim-lang/Nim/pull/19353)).
- The `md5` module now works at compile time and in JavaScript.
- `std/smtp` sends `ehlo` first. If the mail server does not understand, it sends `helo` as a fallback.
- Changed `mimedb` to use an `OrderedTable` instead of `OrderedTableRef` to support `const` tables.
- `strutils.find` now uses and defaults to `last = -1` for whole string searches,
  making limiting it to just the first char (`last = 0`) valid.
- `random.rand` now works with `Ordinal`s.

[//]: # "Additions:"
- Added ISO 8601 week date utilities in `times`:
  - Added `IsoWeekRange`, a range type for weeks in a week-based year.
  - Added `IsoYear`, a distinct type for a week-based year in contrast to a regular year.
  - Added a `initDateTime` overload to create a datetime from an ISO week date.
  - Added `getIsoWeekAndYear` to get an ISO week number and week-based year from a datetime.
  - Added `getIsoWeeksInYear` to return the number of weeks in a week-based year.
- Added `std/oserrors` for OS error reporting. Added `std/envvars` for environment variables handling.
- Added `sep` parameter in `std/uri` to specify the query separator.
- Added bindings to [`Array.shift`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/shift)
  and [`queueMicrotask`](https://developer.mozilla.org/en-US/docs/Web/API/queueMicrotask)
  in `jscore` for JavaScript targets.
- Added `UppercaseLetters`, `LowercaseLetters`, `PunctuationChars`, `PrintableChars` sets to `std/strutils`.
- Added `complex.sgn` for obtaining the phase of complex numbers.

[//]: # "Deprecations:"
- Deprecated `selfExe` for Nimscript.
- Deprecated `std/sums`.

[//]: # "Removals:"
- Removed deprecated module `parseopt2`.
- Removed deprecated module `sharedstrings`.
- Removed deprecated module `dom_extensions`.
- Removed deprecated module `LockFreeHash`.
- Removed deprecated module `events`.
- Removed deprecated `oids.oidToString`.
- Removed define `nimExperimentalAsyncjsThen` for `std/asyncjs.then` and `std/jsfetch`.
- Removed deprecated `jsre.test` and `jsre.toString`.
- Removed deprecated `math.c_frexp`.
- Removed deprecated `` httpcore.`==` ``.
- Removed deprecated `std/posix.CMSG_SPACE` and `std/posix.CMSG_LEN` that takes wrong argument types.
- Removed deprecated `osproc.poDemon`, symbol with typo.

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
  ```

- `cstring` is now accepted as a selector in `case` statements, removing the
  need to convert to `string`. On the JS backend, this is translated directly
  to a `switch` statement.

## Compiler changes

- The `gc` switch has been renamed to `mm` ("memory management") in order to reflect the
  reality better. (Nim moved away from all techniques based on "tracing".)
  
- Defines the `gcRefc` symbol which allows writing specific code for the refc GC.

- `nim` can now compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`,
  without requiring `-d:nimVersion140` which is now a noop.

- `--styleCheck`, `--hintAsError` and `--warningAsError` now only applies to the current package.

- The switch `--nimMainPrefix:prefix` has been added to add a prefix to the names of `NimMain` and
  related functions produced on the backend. This prevents conflicts with other Nim
  static libraries.


## Tool changes

- Nim now supports Nimble version 0.14 which added support for lock-files. This is done by
  a simple configuration change setting that you can do yourself too. In `$nim/config/nim.cfg`
  replace `pkgs` by `pkgs2`.

