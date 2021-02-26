# v1.6.x - yyyy-mm-dd



## Standard library additions and changes

- On Windows the SSL library now checks for valid certificates.
  It uses the `cacert.pem` file for this purpose which was extracted
  from `https://curl.se/ca/cacert.pem`. Besides
  the OpenSSL DLLs (e.g. libssl-1_1-x64.dll, libcrypto-1_1-x64.dll) you
  now also need to ship `cacert.pem` with your `.exe` file.


- Make `{.requiresInit.}` pragma to work for `distinct` types.

- Added a macros `enumLen` for returning the number of items in an enum to the
  `typetraits.nim` module.

- `prelude` now works with the JavaScript target.
  Added `sequtils` import to `prelude`.
  `prelude` can now be used via `include std/prelude`, but `include prelude` still works.

- Added `almostEqual` in `math` for comparing two float values using a machine epsilon.

- The JSON module can now handle integer literals and floating point literals of
  arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are
  kept as string literals and one can use external BigNum libraries to handle these.
  The `parseFloat` family of functions also has now optional `rawIntegers` and
  `rawFloats` parameters that can be used to enforce that all integer or float
  literals remain in the "raw" string form so that client code can easily treat
  small and large numbers uniformly.

- Added `BackwardsIndex` overload for `JsonNode`.

- added `jsonutils.jsonTo` overload with `opt = Joptions()` param.

- Added an overload for the `collect` macro that inferes the container type based
  on the syntax of the last expression. Works with std seqs, tables and sets.

- Added `randState` template that exposes the default random number generator.
  Useful for library authors.

- Added `std/enumutils` module. Added `genEnumCaseStmt` macro that generates case statement to parse string to enum.
  Added `items` for enums with holes.

- Added `typetraits.SomeEnumWithHoles` for enums with holes.

- Removed deprecated `iup` module from stdlib, it has already moved to
  [nimble](https://github.com/nim-lang/iup).

- various functions in `httpclient` now accept `url` of type `Uri`. Moreover `request` function's
  `httpMethod` argument of type `string` was deprecated in favor of `HttpMethod` enum type.

- `nodejs` backend now supports osenv: `getEnv`, `putEnv`, `envPairs`, `delEnv`, `existsEnv`.

- Added `cmpMem` to `system`.

- `doAssertRaises` now correctly handles foreign exceptions.

- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors.

- `--gc:orc` is now 10% faster than previously for common workloads. If
  you have trouble with its changed behavior, compile with `-d:nimOldOrc`.


- `os.FileInfo` (returned by `getFileInfo`) now contains `blockSize`,
  determining preferred I/O block size for this file object.

- Added a simpler to use `io.readChars` overload.

- `repr` now doesn't insert trailing newline; previous behavior was very inconsistent,
  see #16034. Use `-d:nimLegacyReprWithNewline` for previous behavior.

- Added `**` to jsffi.

- `writeStackTrace` is available in JS backend now.

- Added `decodeQuery` to `std/uri`.
- `strscans.scanf` now supports parsing single characters.
- `strscans.scanTuple` added which uses `strscans.scanf` internally, returning a tuple which can be unpacked for easier usage of `scanf`.

- Added `setutils.toSet` that can take any iterable and convert it to a built-in `set`,
  if the iterable yields a built-in settable type.
- Added `setutils.fullSet` which returns a full built-in `set` for a valid type.
- Added `setutils.complement` which returns the complement of a built-in `set`.


- Added `math.isNaN`.

- `echo` and `debugEcho` will now raise `IOError` if writing to stdout fails.  Previous behavior
  silently ignored errors.  See #16366.  Use `-d:nimLegacyEchoNoRaise` for previous behavior.

- Added `jsbigints` module, arbitrary precision integers for JavaScript target.

- Added `math.copySign`.
- Added new operations for singly- and doubly linked lists: `lists.toSinglyLinkedList`
  and `lists.toDoublyLinkedList` convert from `openArray`s; `lists.copy` implements
  shallow copying; `lists.add` concatenates two lists - an O(1) variation that consumes
  its argument, `addMoved`, is also supplied.

- Added `euclDiv` and `euclMod` to `math`.
- Added `httpcore.is1xx` and missing HTTP codes.
- Added `jsconsole.jsAssert` for JavaScript target.

- Added `posix_utils.osReleaseFile` to get system identification from `os-release` file on Linux and the BSDs.
  https://www.freedesktop.org/software/systemd/man/os-release.html

- `math.round` now is rounded "away from zero" in JS backend which is consistent
with other backends. see #9125. Use `-d:nimLegacyJsRound` for previous behavior.
- Added `socketstream` module that wraps sockets in the stream interface

- Changed the behavior of `uri.decodeQuery` when there are unencoded `=`
  characters in the decoded values. Prior versions would raise an error. This is
  no longer the case to comply with the HTML spec and other languages
  implementations. Old behavior can be obtained with
  `-d:nimLegacyParseQueryStrict`. `cgi.decodeData` which uses the same
  underlying code is also updated the same way.

- Added `sugar.dumpToString` which improves on `sugar.dump`.

- Added `math.signbit`.


- Removed the optional `longestMatch` parameter of the `critbits._WithPrefix` iterators (it never worked reliably)
- In `lists`: renamed `append` to `add` and retained `append` as an alias;
  added `prepend` and `prependMoved` analogously to `add` and `addMoved`;
  added `remove` for `SinglyLinkedList`s.

- Deprecated `any`. See https://github.com/nim-lang/RFCs/issues/281

- Added `std/sysrand` module to get random numbers from a secure source 
provided by the operating system.

- Added optional `options` argument to `copyFile`, `copyFileToDir`, and
  `copyFileWithPermissions`. By default, on non-Windows OSes, symlinks are
  followed (copy files symlinks point to); on Windows, `options` argument is
  ignored and symlinks are skipped.
- On non-Windows OSes, `copyDir` and `copyDirWithPermissions` copy symlinks as
  symlinks (instead of skipping them as it was before); on Windows symlinks are
  skipped.
- On non-Windows OSes, `moveFile` and `moveDir` move symlinks as symlinks
  (instead of skipping them sometimes as it was before).
- Added optional `followSymlinks` argument to `setFilePermissions`.

- Added `random.initRand()` overload with no argument which uses the current time as a seed.

- Added experimental `linenoise.readLineStatus` to get line and status (e.g. ctrl-D or ctrl-C).

- Added `compilesettings.SingleValueSetting.libPath`

- `std/wrapnils` doesn't use `experimental:dotOperators` anymore, avoiding
  issues like https://github.com/nim-lang/Nim/issues/13063 (which affected error messages)
  for modules importing `std/wrapnils`.
  Added `??.` macro which returns an `Option`.

- Added `math.frexp` overload procs. Deprecated `c_frexp`, use `frexp` instead.

- `parseopt.initOptParser` has been made available and `parseopt` has been
  added back to `prelude` for all backends. Previously `initOptParser` was
  unavailable if the `os` module did not have `paramCount` or `paramStr`,
  but the use of these in `initOptParser` were conditionally to the runtime
  arguments passed to it, so `initOptParser` has been changed to raise
  `ValueError` when the real command line is not available. `parseopt` was
  previously excluded from `prelude` for JS, as it could not be imported.

- On POSIX systems, the default signal handlers used for Nim programs (it's
  used for printing the stacktrace on fatal signals) will now re-raise the
  signal for the OS default handlers to handle.

  This lets the OS perform its default actions, which might include core
  dumping (on select signals) and notifying the parent process about the cause
  of termination.

- `hashes.hash` now supports `object`, but can be overloaded.

- Added `strip` and `setSlice` to `std/strbasics`.

- Added to `wrapnils` an option-like API via `??.`, `isSome`, `get`.

- `std/options` changed `$some(3)` to `"some(3)"` instead of `"Some(3)"`
  and `$none(int)` to `"none(int)"` instead of `"None[int]"`.


## Language changes

- `nimscript` now handles `except Exception as e`.

- The `cstring` doesn't support `[]=` operator in JS backend.

- nil dereference is not allowed at compile time. `cast[ptr int](nil)[]` is rejected at compile time.

- `typetraits.distinctBase` now is identity instead of error for non distinct types.

- `os.copyFile` is now 2.5x faster on OSX, by using `copyfile` from `copyfile.h`;
  use `-d:nimLegacyCopyFile` for OSX < 10.5.

- The required name of case statement macros for the experimental
  `caseStmtMacros` feature has changed from `match` to `` `case` ``.

- `typedesc[Foo]` now renders as such instead of `type Foo` in compiler messages.

## Compiler changes

- Added `--declaredlocs` to show symbol declaration location in messages.

- Deprecated `TaintedString` and `--taintmode`.

- Source+Edit links now appear on top of every docgen'd page when
  `nim doc --git.url:url ...` is given.

- Added `nim --eval:cmd` to evaluate a command directly, see `nim --help`.

- VM now supports `addr(mystring[ind])` (index + index assignment)

- Type mismatch errors now show more context, use `-d:nimLegacyTypeMismatch` for previous
  behavior.

- Added `--hintAsError` with similar semantics as `--warningAsError`.

- TLS: OSX now uses native TLS (`--tlsEmulation:off`), TLS now works with importcpp non-POD types,
  such types must use `.cppNonPod` and `--tlsEmulation:off`should be used.

- Now array literals(JS backend) uses JS typed arrays when the corresponding js typed array exists, for example `[byte(1), 2, 3]` generates `new Uint8Array([1, 2, 3])`.

- docgen: rst files can now use single backticks instead of double backticks and correctly render
  in both rst2html (as before) as well as common tools rendering rst directly (e.g. github), by
  adding: `default-role:: code` directive inside the rst file, which is now handled by rst2html.

- Added `-d:nimStrictMode` in CI in several places to ensure code doesn't have certain hints/warnings

- Added `then`, `catch` to `asyncjs`, for now hidden behind `-d:nimExperimentalAsyncjsThen`.

## Tool changes

- The rst parser now supports markdown table syntax.
  Known limitations:
  - cell alignment is not supported, i.e. alignment annotations in a delimiter
    row (`:---`, `:--:`, `---:`) are ignored,
  - every table row must start with `|`, e.g. `| cell 1 | cell 2 |`.

- `fusion` is now un-bundled from nim, `./koch fusion` will
  install it via nimble at a fixed hash.
