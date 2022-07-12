# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility

- The `Math.trunc` polyfill for targeting Internet Explorer was
  previously emitted for every JavaScript output file except if
  the symbol `nodejs` was defined via `-d:nodejs`. Now, it is only
  emitted if the symbol `nimJsMathTruncPolyfill` is defined. If you are
  targeting Internet Explorer, you may choose to enable this option
  or define your own `Math.trunc` polyfill using the [`emit` pragma](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma). Nim uses
  `Math.trunc` for the division and modulo operators for integers.

- Deprecated `std/sums`.

- Optional parameters in combination with `: body` syntax (RFC #405) are now opt-in via
  `experimental:flexibleOptionalParams`.

- `std/sharedstrings` module is removed.
- Constants `colors.colPaleVioletRed` and `colors.colMediumPurple` changed to match the CSS color standard.

- `addr` is now available for all addressable locations, `unsafeAddr` is deprecated and
becomes an alias for `addr`.

- `io` and `assertions` are about to move out of system; use `-d:nimPreviewSlimSystem`, import `std/syncio` and import `std/assertions`.

- The `gc:v2` option is removed.

- The `threads:on` option becomes the default.

## Standard library additions and changes

[//]: # "Changes:"
- `macros.parseExpr` and `macros.parseStmt` now accept an optional.
  filename argument for more informative errors.
- Module `colors` expanded with missing colors from the CSS color standard.
- Fixed `lists.SinglyLinkedList` being broken after removing the last node ([#19353](https://github.com/nim-lang/Nim/pull/19353)).
- `md5` now works at compile time and in JavaScript.
- `std/smtp` sends `ehlo` first. If the mail server does not understand, it sends `helo` as a fallback.
- Changed mimedb to use an `OrderedTable` instead of `OrderedTableRef`, to use it in a const.
- `strutils.find` now use and default to `last=-1` for whole string searches, making limiting it to just the first char (`last=0`) valid.

[//]: # "Additions:"
- Added `IsoWeekRange`, a range type to represent the number of weeks in an ISO week-based year.
- Added `IsoYear`, a distinct int type to prevent bugs from confusing the week-based year and the regular year.
- Added `initDateTime` in `times` to create a datetime from a weekday, and ISO 8601 week number and week-based year.
- Added `getIsoWeekAndYear` in `times` to get an ISO week number along with the corresponding ISO week-based year from a datetime.
- Added `getIsoWeeksInYear` in `times` to return the number of weeks in an ISO week-based year.
- Added `std/oserrors` for OS error reporting. Added `std/envvars` for environment variables handling.
- Added `sep` parameter in `std/uri` to specify the query separator.
- Added [`Array.shift`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/shift) for JavaScript targets.
- Added [`queueMicrotask`](https://developer.mozilla.org/en-US/docs/Web/API/queueMicrotask) for JavaScript targets.

[//]: # "Deprecations:"
- Deprecated `selfExe` for Nimscript.

[//]: # "Removals:"
- Removed deprecated `oids.oidToString`.
- Removed define `nimExperimentalAsyncjsThen` for `std/asyncjs.then` and `std/jsfetch`.
- Removed deprecated `jsre.test` and `jsre.toString`.
- Removed deprecated `math.c_frexp`.
- Removed deprecated `` httpcore.`==` ``.
- Removed deprecated `std/dom_extensions`.
- Removed deprecated `std/posix.CMSG_SPACE` and `std/posix.CMSG_LEN` that takes wrong argument types.
- Removed deprecated `osproc.poDemon`, symbol with typo.

## Language changes

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
