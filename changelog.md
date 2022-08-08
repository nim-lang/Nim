# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility

- `addr` is now available for all addressable locations,
  `unsafeAddr` is now deprecated and an alias for `addr`.

- `io` and `assertions` are about to move out of the `system` module.
  You may instead import `std/syncio` and `std/assertions`.
  The `-d:nimPreviewSlimSystem` option makes these imports required.

- The `gc:v2` option is removed.

- The `threads:on` option is now the default.

- Optional parameters in combination with `: body` syntax (RFC #405) are now opt-in via
  `experimental:flexibleOptionalParams`.

- The `Math.trunc` polyfill for targeting Internet Explorer was
  previously emitted for every JavaScript output file except if
  the symbol `nodejs` was defined via `-d:nodejs`. Now, it is only
  emitted if the symbol `nimJsMathTruncPolyfill` is defined. If you are
  targeting Internet Explorer, you may choose to enable this option
  or define your own `Math.trunc` polyfill using the [`emit` pragma](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma). Nim uses
  `Math.trunc` for the division and modulo operators for integers.

- `shallowCopy` is removed for ARC/ORC. Use `move` when possible or combine assignment and
`sink` for optimization purposes.

- `nimPreviewDotLikeOps` is going to be removed or deprecated.

## Standard library additions and changes

[//]: # "Changes:"
- `macros.parseExpr` and `macros.parseStmt` now accept an optional
  filename argument for more informative errors.
- Module `colors` expanded with missing colors from the CSS color standard.
  `colPaleVioletRed` and `colMediumPurple` have also been changed to match the CSS color standard.
- Fixed `lists.SinglyLinkedList` being broken after removing the last node ([#19353](https://github.com/nim-lang/Nim/pull/19353)).
- `md5` now works at compile time and in JavaScript.
- `std/smtp` sends `ehlo` first. If the mail server does not understand, it sends `helo` as a fallback.
- Changed `mimedb` to use an `OrderedTable` instead of `OrderedTableRef` to support `const` tables.
- `strutils.find` now use and default to `last=-1` for whole string searches, making limiting it to just the first char (`last=0`) valid.
- `random.rand` now works with `Ordinal`s.

[//]: # "Additions:"
- Added `times.IsoWeekRange`, a range type to represent the number of weeks in an ISO week-based year.
- Added `times.IsoYear`, a distinct int type to prevent bugs from confusing the week-based year and the regular year.
- Added `times.initDateTime` to create a datetime from a weekday, and ISO 8601 week number and week-based year.
- Added `times.getIsoWeekAndYear` to get an ISO week number along with the corresponding ISO week-based year from a datetime.
- Added `times.getIsoWeeksInYear` to return the number of weeks in an ISO week-based year.
- Added `std/oserrors` for OS error reporting. Added `std/envvars` for environment variables handling.
- Added `sep` parameter in `std/uri` to specify the query separator.
- Added bindings to [`Array.shift`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/shift)
  and [`queueMicrotask`](https://developer.mozilla.org/en-US/docs/Web/API/queueMicrotask)
  in `jscore` for JavaScript targets.
- Added `UppercaseLetters`, `LowercaseLetters`, `PunctuationChars`, `PrintableChars` sets to `std/strutils`.

[//]: # "Deprecations:"
- Deprecated `selfExe` for Nimscript.
- Deprecated `std/sums`.

[//]: # "Removals:"
- Removed deprecated `std/sharedstrings`.
- Removed deprecated `oids.oidToString`.
- Removed define `nimExperimentalAsyncjsThen` for `std/asyncjs.then` and `std/jsfetch`.
- Removed deprecated `jsre.test` and `jsre.toString`.
- Removed deprecated `math.c_frexp`.
- Removed deprecated `` httpcore.`==` ``.
- Removed deprecated `std/dom_extensions`.
- Removed deprecated `std/posix.CMSG_SPACE` and `std/posix.CMSG_LEN` that takes wrong argument types.
- Removed deprecated `osproc.poDemon`, symbol with typo.

## Language changes

- [Tag tracking](manual.html#tag-tracking) supports the definition of forbidden tags by the `.forbids` pragma
  which can be used to disable certain effects in proc types.
- [Case statement macros](manual.html#macros-case-statement-macros) are no longer experimental,
  meaning you no longer need to enable the experimental switch `caseStmtMacros` to use them.
- Templates now accept [macro pragmas](https://nim-lang.github.io/Nim/manual.html#userminusdefined-pragmas-macro-pragmas).
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
- Full command syntax and block arguments i.e. `foo a, b: c` are now allowed
  for the right-hand side of type definitions in type sections. Previously
  they would error with "invalid indentation".
- `defined` now accepts identifiers separated by dots, i.e. `defined(a.b.c)`.
  In the command line, this is defined as `-d:a.b.c`. Older versions can
  use accents as in ``defined(`a.b.c`)`` to access such defines.

- Defines the `gcRefc` symbol which allows writing specific code for the refc GC.

## Compiler changes

- `nim` can now compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`,
  without requiring `-d:nimVersion140` which is now a noop.

- `--styleCheck` now only applies to the current package.


## Tool changes

- The `gc` switch has been renamed to `mm` ("memory management") in order to reflect the
  reality better. (Nim moved away from all techniques based on "tracing".)

- Nim now supports Nimble version 0.14 which added support for lock-files. This is done by
  a simple configuration change setting that you can do yourself too. In `$nim/config/nim.cfg`
  replace `pkgs` by `pkgs2`.

- There is a new switch `--nimMainPrefix:prefix` to influence the `NimMain` that the
  compiler produces. This is particularly useful for generating static libraries.
