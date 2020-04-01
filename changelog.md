# 1.2 - xxxx-xx-xx


## Changes affecting backwards compatibility

- The Nim compiler now implements a faster way to detect overflows based
  on GCC's `__builtin_sadd_overflow` family of functions. (Clang also
  supports these). Some versions of GCC lack this feature and unfortunately
  we cannot detect this case reliably. So if you get compilation errors like
  "undefined reference to `__builtin_saddll_overflow`" compile your programs
  with `-d:nimEmulateOverflowChecks`.


### Breaking changes in the standard library

- `base64.encode` no longer supports `lineLen` and `newLine`.
  Use `base64.encodeMime` instead.
- `os.splitPath()` behavior synchronized with `os.splitFile()` to return "/"
   as the dir component of "/root_sub_dir" instead of the empty string.
- `sequtils.zip` now returns a sequence of anonymous tuples i.e. those tuples
  now do not have fields named "a" and "b".
- `strutils.formatFloat` with `precision = 0` has the same behavior in all
  backends, and it is compatible with Python's behavior,
  e.g. `formatFloat(3.14159, precision = 0)` is now `3`, not `3.`.
- Global variable `lc` has been removed from sugar.nim.
- `distinctBase` has been moved from sugar.nim to typetraits and now implemented as
  compiler type trait instead of macro. `distinctBase` in sugar module is now deprecated.
- `CountTable.mget` has been removed from `tables.nim`. It didn't work, and it
  was an oversight to be included in v1.0.
- `tables.merge(CountTable, CountTable): CountTable` has been removed.
  It didn't work well together with the existing inplace version of the same proc
  (`tables.merge(var CountTable, CountTable)`).
  It was an oversight to be included in v1.0.
- `options` now treats `proc` like other pointer types, meaning `nil` proc variables
  are converted to `None`.
- `relativePath("foo", "foo")` is now `"."`, not `""`, as `""` means invalid path
  and shouldn't be conflated with `"."`; use -d:nimOldRelativePathBehavior to
  restore the old behavior
- `joinPath(a,b)` now honors trailing slashes in `b` (or `a` if `b` = "")
- `times.parse` now only uses input to compute its result, and not `now`:
  `parse("2020", "YYYY", utc())` is now `2020-01-01T00:00:00Z` instead of
  `2020-03-02T00:00:00Z` if run on 03-02; it also doesn't crash anymore when
  used on 29th, 30th, 31st of each month.
- `httpcore.==(string, HttpCode)` is now deprecated due to lack of practical
  usage. The `$` operator can be used to obtain the string form of `HttpCode`
  for comparison if desired.
- `os.walkDir` and `os.walkDirRec` now have new flag, `checkDir` (default: false).
  If it is set to true, it will throw if input dir is invalid instead of a noop
  (which is the default behaviour, as it was before this change),
  `os.walkDirRec` only throws if top-level dir is invalid, but ignores errors for
  subdirs, otherwise it would be impossible to resume iteration.


### Breaking changes in the compiler

- Implicit conversions for `const` behave correctly now, meaning that code like
  `const SOMECONST = 0.int; procThatTakesInt32(SOMECONST)` will be illegal now.
  Simply write `const SOMECONST = 0` instead.
- The `{.dynlib.}` pragma is now required for exporting symbols when making
  shared objects on POSIX and macOS, which make it consistent with the behavior
  on Windows.
- The compiler is now more strict about type conversions concerning proc
  types: Type conversions cannot be used to hide `.raise` effects or side
  effects, instead a `cast` must be used. With the flag `--useVersion:1.0` the
  old behaviour is emulated.


## Library additions

- `macros.newLit` now works for ref object types.
- `system.writeFile` has been overloaded to also support `openarray[byte]`.
- Added overloaded `strformat.fmt` macro that use specified characters as
  delimiter instead of '{' and '}'.
- introduced new procs in `tables.nim`: `OrderedTable.pop`, `CountTable.del`,
  `CountTable.pop`, `Table.pop`
- To `strtabs.nim`, added `StringTable.clear` overload that reuses the existing mode.
- Added `browsers.osOpen` const alias for the operating system specific *"open"* command.
- Added `sugar.dup` for turning in-place algorithms like `sort` and `shuffle` into
  operations that work on a copy of the data and return the mutated copy. As the existing
  `sorted` does.
- Added `sugar.collect` that does comprehension for seq/set/table collections.
- Added `sugar.capture` for capturing some local loop variables when creating a closure.
  This is an enhanced version of `closureScope`.
- Added `typetraits.tupleLen` to get number of elements of a tuple/type tuple,
  and `typetraits.get` to get the ith element of a type tuple.
- Added `typetraits.genericParams` to return a tuple of generic params from a generic instantiation
- Added `os.normalizePathEnd` for additional path sanitization.
- Added `times.fromUnixFloat,toUnixFloat`, subsecond resolution versions of `fromUnix`,`toUnixFloat`.
- Added `wrapnils` module for chains of field-access and indexing where the LHS can be nil.
  This simplifies code by reducing need for if-else branches around intermediate maybe nil values.
  E.g. `echo ?.n.typ.kind`
- Added `minIndex`, `maxIndex` and `unzip` to the `sequtils` module.
- Added `os.isRelativeTo` to tell whether a path is relative to another
- Added `resetOutputFormatters` to `unittest`
- Added `expectIdent` to the `macros` module.
- Added `os.isValidFilename` that returns `true` if `filename` argument is valid for crossplatform use.

- Added a `with` macro for easy function chaining that's available
  everywhere, there is no need to concern your APIs with returning the first argument
  to enable "chaining", instead use the dedicated macro `with` that
  was designed for it. For example:

```nim

type
  Foo = object
    col, pos: string

proc setColor(f: var Foo; r, g, b: int) = f.col = $(r, g, b)
proc setPosition(f: var Foo; x, y: float) = f.pos = $(x, y)

var f: Foo
with(f, setColor(2, 3, 4), setPosition(0.0, 1.0))
echo f

```

- Added `times.isLeapDay`
- Added a new module, `std / compilesettings` for querying the compiler about
  diverse configuration settings.
- `base64` adds URL-Safe Base64, implements RFC-4648 Section-7.
- Added `net.getPeerCertificates` and `asyncnet.getPeerCertificates` for
  retrieving the verified certificate chain of the peer we are connected to
  through an SSL-wrapped `Socket`/`AsyncSocket`.
- Added `distinctBase` overload for values: `assert 12.MyInt.distinctBase == 12`

## Library changes

- `asyncdispatch.drain` now properly takes into account `selector.hasPendingOperations`
  and only returns once all pending async operations are guaranteed to have completed.
- `asyncdispatch.drain` now consistently uses the passed timeout value for all
  iterations of the event loop, and not just the first iteration.
  This is more consistent with the other asyncdispatch apis, and allows
  `asyncdispatch.drain` to be more efficient.
- `base64.encode` and `base64.decode` was made faster by about 50%.
- `htmlgen` adds [MathML](https://wikipedia.org/wiki/MathML) support
  (ISO 40314).
- `macros.eqIdent` is now invariant to export markers and backtick quotes.
- `htmlgen.html` allows `lang` on the `<html>` tag and common valid attributes.
- `macros.basename` and `basename=` got support for `PragmaExpr`,
  so that an expression like `MyEnum {.pure.}` is handled correctly.
- `httpclient.maxredirects` changed from `int` to `Natural`, because negative values
  serve no purpose whatsoever.
- `httpclient.newHttpClient` and `httpclient.newAsyncHttpClient` added `headers`
  argument to set initial HTTP Headers, instead of a hardcoded empty `newHttpHeader()`.
- `parseutils.parseUntil` has now a different behaviour if the `until` parameter is
  empty. This was required for intuitive behaviour of the strscans module
  (see bug #13605).
- `std/oswalkdir` was buggy, it's now deprecated and reuses `std/os` procs
- `net.newContext` now performs SSL Certificate checking on Linux and OSX.
  Define `nimDisableCertificateValidation` to disable it globally.
- new syntax for lvalue references: `var b {.byaddr.} = expr` enabled by `import pragmas`
- new module `std/stackframes`, in particular `setFrameMsg` which enables
  custom runtime annotation of stackframes, see #13351 for examples. Turn on/off via
  `--stackTraceMsgs:on/off`

## Language additions

- An `align` pragma can now be used for variables and object fields, similar
  to the `alignas` declaration modifier in C/C++.

- `=sink` type bound operator is now optional. Compiler can now use combination
  of `=destroy` and `copyMem` to move objects efficiently.

- `var a {.foo.}: MyType = expr` now lowers to `foo(a, MyType, expr)` for non builtin pragmas,
  enabling things like lvalue references, see `pragmas.byaddr`

- `macro pragmas` can now be used in type sections.

## Language changes

- Unsigned integer operators have been fixed to allow promotion of the first operand.
- Conversions to unsigned integers are unchecked at runtime, imitating earlier Nim
  versions. The documentation was improved to acknowledge this special case.
  See https://github.com/nim-lang/RFCs/issues/175 for more details.


### Tool changes

- Fix Nimpretty must not accept negative indentation argument because breaks file.


### Compiler changes

- JS target indent is all spaces, instead of mixed spaces and tabs, for
  generated JavaScript.
- The Nim compiler now supports the ``--asm`` command option for easier
  inspection of the produced assembler code.
- The Nim compiler now supports a new pragma called ``.localPassc`` to
  pass specific compiler options to the C(++) backend for the C(++) file
  that was produced from the current Nim module.
- The compiler now inferes "sink parameters". To disable this for a specific routine,
  annotate it with `.nosinks`. To disable it for a section of code, use
  `{.push sinkInference: off.}`...`{.pop.}`.
- The compiler now supports a new switch `--panics:on` that turns runtime
  errors like `IndexError` or `OverflowError` into fatal errors that **cannot**
  be caught via Nim's `try` statement. `--panics:on` can improve the
  runtime efficiency and code size of your program significantly.
- The compiler now warns about inheriting directly from `system.Exception` as
  this is **very bad** style. You should inherit from `ValueError`, `IOError`,
  `OSError` or from a different specific exception type that inherits from
  `CatchableError` and cannot be confused with a `Defect`.
- The error reporting for Nim's effect system has been improved.


## Bugfixes

- The `FD` variant of `selector.unregister` for `ioselector_epoll` and
  `ioselector_select` now properly handle the `Event.User` select event type.
- `joinPath` path normalization when `/` is the first argument works correctly:
  `assert "/" / "/a" == "/a"`. Fixed the edgecase: `assert "" / "" == ""`.
- `xmltree` now adds indentation consistently to child nodes for any number
  of children nodes.
