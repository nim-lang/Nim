# v1.6.x - yyyy-mm-dd



## Changes affecting backward compatibility

- Deprecated `std/mersenne`.

- `system.delete` had a most surprising behavior when the index passed to it was out of
  bounds (it would delete the last entry then). Compile with `-d:nimStrictDelete` so
  that an index error is produced instead. But be aware that your code might depend on
  this quirky behavior so a review process is required on your part before you can
  use `-d:nimStrictDelete`. To make this review easier, use the `-d:nimAuditDelete`
  switch, it pretends that `system.delete` is deprecated so that it is easier to see
  where it was used in your code.

  `-d:nimStrictDelete` will become the default in upcoming versions.


- `cuchar` is now deprecated as it aliased `char` where arguably it should have aliased `uint8`.
  Please use `char` or `uint8` instead.

- `repr` now doesn't insert trailing newline; previous behavior was very inconsistent,
  see #16034. Use `-d:nimLegacyReprWithNewline` for previous behavior.

- A type conversion from one enum type to another now produces an `[EnumConv]` warning.
  You should use `ord` (or `cast`, but the compiler won't help, if you misuse it) instead.
  ```
  type A = enum a1, a2
  type B = enum b1, b2
  echo a1.B # produces a warning
  echo a1.ord.B # produces no warning
  ```

- A dangerous implicit conversion to `cstring` now triggers a `[CStringConv]` warning.
  This warning will become an error in future versions! Use an explicit conversion
  like `cstring(x)` in order to silence the warning.

- There is a new warning for *any* type conversion to enum that can be enabled via
  `.warning[AnyEnumConv]:on` or `--warning:AnyEnumConv:on`.

- Type mismatch errors now show more context, use `-d:nimLegacyTypeMismatch` for previous
  behavior.

- `math.round` now is rounded "away from zero" in JS backend which is consistent
  with other backends. See #9125. Use `-d:nimLegacyJsRound` for previous behavior.

- Changed the behavior of `uri.decodeQuery` when there are unencoded `=`
  characters in the decoded values. Prior versions would raise an error. This is
  no longer the case to comply with the HTML spec and other languages
  implementations. Old behavior can be obtained with
  `-d:nimLegacyParseQueryStrict`. `cgi.decodeData` which uses the same
  underlying code is also updated the same way.
- Custom pragma values have now an API for use in macros.

- On POSIX systems, the default signal handlers used for Nim programs (it's
  used for printing the stacktrace on fatal signals) will now re-raise the
  signal for the OS default handlers to handle.

  This lets the OS perform its default actions, which might include core
  dumping (on select signals) and notifying the parent process about the cause
  of termination.

- On POSIX systems, we now ignore `SIGPIPE` signals, use `-d:nimLegacySigpipeHandler`
  for previous behavior.

- `hashes.hash` can now support `object` and `ref` (can be overloaded in user code),
  if `-d:nimEnableHashRef` is used.

- `hashes.hash(proc|ptr|ref|pointer)` now calls `hash(int)` and honors `-d:nimIntHash1`,
  `hashes.hash(closure)` has also been improved.

- The unary slice `..b` was deprecated, use `0..b` instead.

- Removed `.travis.yml`, `appveyor.yml.disabled`, `.github/workflows/ci.yml.disabled`.

- `random.initRand(seed)` now produces non-skewed values for the 1st call to `rand()` after
  initialization with a small (< 30000) seed. Use `-d:nimLegacyRandomInitRand` to restore
  previous behavior for a transition time, see PR #17467.

- `jsonutils` now serializes/deserializes holey enums as regular enums (via `ord`) instead of as strings.
  Use `-d:nimLegacyJsonutilsHoleyEnum` for a transition period. `toJson` now serializes `JsonNode`
  as is via reference (without a deep copy) instead of treating `JsonNode` as a regular ref object,
  this can be customized via `jsonNodeMode`.

- `json` and `jsonutils` now serialize NaN, Inf, -Inf as strings, so that
  `%[NaN, -Inf]` is the string `["nan","-inf"]` instead of `[nan,-inf]` which was invalid json.


- `strformat` is now part of `include std/prelude`.

- Deprecated `proc reversed*[T](a: openArray[T], first: Natural, last: int): seq[T]` in `std/algorithm`.

- In `std/macros`, `treeRepr,lispRepr,astGenRepr` now represent SymChoice nodes in a collapsed way,
  use `-d:nimLegacyMacrosCollapseSymChoice` to get previous behavior.

- The configuration subsystem now allows for `-d:release` and `-d:danger` to work as expected.
  The downside is that these defines now have custom logic that doesn't apply for
  other defines.

- Renamed `-d:nimCompilerStackraceHints` to `-d:nimCompilerStacktraceHints`.

- In `std/dom`, `Interval` is now a `ref object`, same as `Timeout`. Definitions of `setTimeout`,
  `clearTimeout`, `setInterval`, `clearInterval` were updated.

## Standard library additions and changes

- `strformat`:
  added support for parenthesized expressions.
  added support for const string's instead of just string literals


- `system.addFloat` and `system.$` now can produce string representations of floating point numbers
  that are minimal in size and that "roundtrip" (via the "Dragonbox" algorithm). This currently has
  to be enabled via `-d:nimFpRoundtrips`. It is expected that this behavior becomes the new default
  in upcoming versions.

- Fixed buffer overflow bugs in `net`

- Exported `sslHandle` from `net` and `asyncnet`.

- Added `sections` iterator in `parsecfg`.

- Make custom op in macros.quote work for all statements.

- On Windows the SSL library now checks for valid certificates.
  It uses the `cacert.pem` file for this purpose which was extracted
  from `https://curl.se/ca/cacert.pem`. Besides
  the OpenSSL DLLs (e.g. libssl-1_1-x64.dll, libcrypto-1_1-x64.dll) you
  now also need to ship `cacert.pem` with your `.exe` file.

- `typetraits`:
  `distinctBase` now is identity instead of error for non distinct types.
  Added `enumLen` to return the number of elements in an enum.
  Added `HoleyEnum` for enums with holes, `OrdinalEnum` for enums without holes.
  Added `hasClosure`.
  Added `pointerBase` to return `T` for `ref T | ptr T`.

- `prelude` now works with the JavaScript target.
  Added `sequtils` import to `prelude`.
  `prelude` can now be used via `include std/prelude`, but `include prelude` still works.

- Added `almostEqual` in `math` for comparing two float values using a machine epsilon.

- Added `clamp` in `math` which allows using a `Slice` to clamp to a value.

- The JSON module can now handle integer literals and floating point literals of
  arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are
  kept as string literals and one can use external BigNum libraries to handle these.
  The `parseFloat` family of functions also has now optional `rawIntegers` and
  `rawFloats` parameters that can be used to enforce that all integer or float
  literals remain in the "raw" string form so that client code can easily treat
  small and large numbers uniformly.

- Added `BackwardsIndex` overload for `JsonNode`.

- `json.%`,`json.to`, `jsonutils.formJson`,`jsonutils.toJson` now work with `uint|uint64`
  instead of raising (as in 1.4) or giving wrong results (as in 1.2).

- `jsonutils` now handles `cstring` (including as Table key), and `set`.

- added `jsonutils.jsonTo` overload with `opt = Joptions()` param.

- `jsonutils.toJson` now supports customization via `ToJsonOptions`.

- Added an overload for the `collect` macro that inferes the container type based
  on the syntax of the last expression. Works with std seqs, tables and sets.

- Added `randState` template that exposes the default random number generator.
  Useful for library authors.

- Added `random.initRand()` overload with no argument which uses the current time as a seed.

- `random.initRand(seed)` now allows `seed == 0`.

- Added `std/sysrand` module to get random numbers from a secure source
  provided by the operating system.

- Added `std/enumutils` module. Added `genEnumCaseStmt` macro that generates case statement to parse string to enum.
  Added `items` for enums with holes.
  Added `symbolName` to return the enum symbol name ignoring the human readable name.
  Added `symbolRank` to return the index in which an enum member is listed in an enum.

- Removed deprecated `iup` module from stdlib, it has already moved to
  [nimble](https://github.com/nim-lang/iup).

- various functions in `httpclient` now accept `url` of type `Uri`. Moreover `request` function's
  `httpMethod` argument of type `string` was deprecated in favor of `HttpMethod` enum type.

- `nodejs` backend now supports osenv: `getEnv`, `putEnv`, `envPairs`, `delEnv`, `existsEnv`.

- Added `cmpMem` to `system`.

- `doAssertRaises` now correctly handles foreign exceptions.

- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors.

- Added `getPort` to `asynchttpserver`.

- `--gc:orc` is now 10% faster than previously for common workloads. If
  you have trouble with its changed behavior, compile with `-d:nimOldOrc`.

- `os.FileInfo` (returned by `getFileInfo`) now contains `blockSize`,
  determining preferred I/O block size for this file object.

- Added `os.getCacheDir()` to return platform specific cache directory.

- Added a simpler to use `io.readChars` overload.

- Added `**` to jsffi.

- `writeStackTrace` is available in JS backend now.

- Added `decodeQuery` to `std/uri`.

- `strscans.scanf` now supports parsing single characters.

- `strscans.scanTuple` added which uses `strscans.scanf` internally,
  returning a tuple which can be unpacked for easier usage of `scanf`.

- Added `setutils.toSet` that can take any iterable and convert it to a built-in `set`,
  if the iterable yields a built-in settable type.

- Added `setutils.fullSet` which returns a full built-in `set` for a valid type.

- Added `setutils.complement` which returns the complement of a built-in `set`.

- Added `setutils.[]=`.

- Added `math.isNaN`.

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

- Added `socketstream` module that wraps sockets in the stream interface

- Added `sugar.dumpToString` which improves on `sugar.dump`.

- Added `math.signbit`.

- Removed the optional `longestMatch` parameter of the `critbits._WithPrefix` iterators (it never worked reliably)

- In `lists`: renamed `append` to `add` and retained `append` as an alias;
  added `prepend` and `prependMoved` analogously to `add` and `addMoved`;
  added `remove` for `SinglyLinkedList`s.

- Deprecated `any`. See https://github.com/nim-lang/RFCs/issues/281

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

- Added `os.isAdmin` to tell whether the caller's process is a member of the
  Administrators local group (on Windows) or a root (on POSIX).

- Added experimental `linenoise.readLineStatus` to get line and status (e.g. ctrl-D or ctrl-C).

- Added `compilesettings.SingleValueSetting.libPath`.

- `std/wrapnils` doesn't use `experimental:dotOperators` anymore, avoiding
  issues like https://github.com/nim-lang/Nim/issues/13063 (which affected error messages)
  for modules importing `std/wrapnils`.
  Added `??.` macro which returns an `Option`.
  `std/wrapnils` can now be used to protect against `FieldDefect` errors in
  case objects, generates optimal code (no overhead compared to manual
  if-else branches), and preserves lvalue semantics which allows modifying
  an expression.

- Added `math.frexp` overload procs. Deprecated `c_frexp`, use `frexp` instead.

- `parseopt.initOptParser` has been made available and `parseopt` has been
  added back to `prelude` for all backends. Previously `initOptParser` was
  unavailable if the `os` module did not have `paramCount` or `paramStr`,
  but the use of these in `initOptParser` were conditionally to the runtime
  arguments passed to it, so `initOptParser` has been changed to raise
  `ValueError` when the real command line is not available. `parseopt` was
  previously excluded from `prelude` for JS, as it could not be imported.

- Added `system.prepareStrMutation` for better support of low
  level `moveMem`, `copyMem` operations for Orc's copy-on-write string
  implementation.

- Added `std/strbasics` for high performance string operations.
  Added `strip`, `setSlice`, `add(a: var string, b: openArray[char])`.

- `std/options` changed `$some(3)` to `"some(3)"` instead of `"Some(3)"`
  and `$none(int)` to `"none(int)"` instead of `"None[int]"`.

- Added `algorithm.merge`.

- Added `std/jsfetch` module [Fetch](https://developer.mozilla.org/docs/Web/API/Fetch_API) wrapper for JavaScript target.

- Added `std/jsheaders` module [Headers](https://developer.mozilla.org/en-US/docs/Web/API/Headers) wrapper for JavaScript target.

- Added `std/jsformdata` module [FormData](https://developer.mozilla.org/en-US/docs/Web/API/FormData) wrapper for JavaScript target.

- `system.addEscapedChar` now renders `\r` as `\r` instead of `\c`, to be compatible
  with most other languages.

- Removed support for named procs in `sugar.=>`.

- Added `jscore.debugger` to [call any available debugging functionality, such as breakpoints.](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/debugger).

- Added `std/channels`.

- Added `htmlgen.portal` for [making "SPA style" pages using HTML only](https://web.dev/hands-on-portals).

- Added `ZZZ` and `ZZZZ` patterns to `times.nim` `DateTime` parsing, to match time
  zone offsets without colons, e.g. `UTC+7 -> +0700`.

- Added `jsconsole.dir`, `jsconsole.dirxml`, `jsconsole.timeStamp`.

- Added dollar `$` and `len` for `jsre.RegExp`.

- Added `std/tasks`.

- Added `hasDataBuffered` to `asyncnet`.

- Added `std/tempfiles`.

- Added `genasts.genAst` that avoids the problems inherent with `quote do` and can
  be used as a replacement.

- Added `copyWithin` [for `seq` and `array` for JavaScript targets](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/copyWithin).

- Fixed premature garbage collection in asyncdispatch, when a stack trace override is in place.

- Added setCurrentException for JS backend.

- Added `dom.scrollIntoView` proc with options

- Added `dom.setInterval`, `dom.clearInterval` overloads.

- Deprecated `sequtils.delete` and added an overload taking a `Slice` that raises a defect
  if the slice is out of bounds, likewise with `strutils.delete`.

## Language changes

- `nimscript` now handles `except Exception as e`.

- The `cstring` doesn't support `[]=` operator in JS backend.

- nil dereference is not allowed at compile time. `cast[ptr int](nil)[]` is rejected at compile time.

- `os.copyFile` is now 2.5x faster on OSX, by using `copyfile` from `copyfile.h`;
  use `-d:nimLegacyCopyFile` for OSX < 10.5.

- The required name of case statement macros for the experimental
  `caseStmtMacros` feature has changed from `match` to `` `case` ``.

- `typedesc[Foo]` now renders as such instead of `type Foo` in compiler messages.

- The unary minus in `-1` is now part of the integer literal, it is now parsed as a single token.
  This implies that edge cases like `-128'i8` finally work correctly.

- Custom numeric literals (e.g. `-128'bignum`) are now supported.

- Tuple expressions are now parsed consistently as
  `nnkTupleConstr` node. Will affect macros expecting nodes to be of `nnkPar`.

- `nim e` now accepts arbitrary file extensions for the nimscript file,
  although `.nims` is still the preferred extension in general.

- Added `iterable[T]` type class to match called iterators, which enables writing:
  `template fn(a: iterable)` instead of `template fn(a: untyped)`

- A new import syntax `import foo {.all.}` now allows to import all symbols (public or private)
  from `foo`. It works in combination with all pre-existing import features.
  This reduces or eliminates the need for workarounds such as using `include` (which has known issues)
  when you need a private symbol for testing or making some internal APIs public just because
  another internal module needs those.
  It also helps mitigate the lack of cyclic imports in some cases.

- Added a new module `std/importutils`, and an API `privateAccess`, which allows access to private fields
  for an object type in the current scope.

- `typeof(voidStmt)` now works and returns `void`.

- The `gc:orc` algorithm was refined so that custom container types can participate in the
  cycle collection process.

- On embedded devices `malloc` can now be used instead of `mmap` via `-d:nimAllocPagesViaMalloc`.
  This is only supported for `--gc:orc` or `--gc:arc`.


## Compiler changes

- Added `--declaredLocs` to show symbol declaration location in messages.

- You can now enable/disable VM tracing in user code via `vmutils.vmTrace`.

- Deprecated `TaintedString` and `--taintmode`.

- Deprecated `--nilseqs` which is now a noop.

- Added `--spellSuggest` to show spelling suggestions on typos.

- Added `--filenames:abs|canonical|legacyRelProj` which replaces --listFullPaths:on|off

- Added `--processing:dots|filenames|off` which customizes `hintProcessing`

- Added `--unitsep:on|off` to control whether to add ASCII unit separator `\31` before a newline
 for every generated message (potentially multiline), so tooling can tell when messages start and end.

- Source+Edit links now appear on top of every docgen'd page when
  `nim doc --git.url:url ...` is given.

- Added `nim --eval:cmd` to evaluate a command directly, see `nim --help`.

- VM now supports `addr(mystring[ind])` (index + index assignment)

- Added `--hintAsError` with similar semantics as `--warningAsError`.

- TLS: OSX now uses native TLS (`--tlsEmulation:off`), TLS now works with importcpp non-POD types,
  such types must use `.cppNonPod` and `--tlsEmulation:off`should be used.

- Now array literals(JS backend) uses JS typed arrays when the corresponding js typed array exists,
  for example `[byte(1), 2, 3]` generates `new Uint8Array([1, 2, 3])`.

- docgen: rst files can now use single backticks instead of double backticks and correctly render
  in both rst2html (as before) as well as common tools rendering rst directly (e.g. github), by
  adding: `default-role:: code` directive inside the rst file, which is now handled by rst2html.

- Added `-d:nimStrictMode` in CI in several places to ensure code doesn't have certain hints/warnings

- Added `then`, `catch` to `asyncjs`, for now hidden behind `-d:nimExperimentalAsyncjsThen`.

- `--newruntime` and `--refchecks` are deprecated.

- Added `unsafeIsolate` and `extract` to `std/isolation`.

- `--hint:CC` now goes to stderr (like all other hints) instead of stdout.

- `--hint:all:on|off` is now supported to select or deselect all hints; it
  differs from `--hints:on|off` which acts as a (reversible) gate.
  Likewise with `--warning:all:on|off`.

- json build instructions are now generated in `$nimcache/outFileBasename.json`
  instead of `$nimcache/projectName.json`. This allows avoiding recompiling a given project
  compiled with different options if the output file differs.

- `--usenimcache` (implied by `nim r main`) now generates an output file that includes a hash of
  some of the compilation options, which allows caching generated binaries:
  nim r main # recompiles
  nim r -d:foo main # recompiles
  nim r main # uses cached binary
  nim r main arg1 arg2 # ditto (runtime arguments are irrelevant)

- The style checking of the compiler now supports a `--styleCheck:usages` switch. This switch
  enforces that every symbol is written as it was declared, not enforcing
  the official Nim style guide. To be enabled, this has to be combined either
  with `--styleCheck:error` or `--styleCheck:hint`.


## Tool changes

- Latex doc generation is revised: output `.tex` files should be compiled
  by `xelatex` (not by `pdflatex` as before). Now default Latex settings
  provide support for Unicode and do better job for avoiding margin overflows.

- Implemented `doc2tex` compiler command which converts documentation in
  `.nim` files to Latex.

- The rst parser now supports markdown table syntax.
  Known limitations:
  - cell alignment is not supported, i.e. alignment annotations in a delimiter
    row (`:---`, `:--:`, `---:`) are ignored,
  - every table row must start with `|`, e.g. `| cell 1 | cell 2 |`.

- `fusion` is now un-bundled from nim, `./koch fusion` will
  install it via nimble at a fixed hash.

- testament: added `nimoutFull: bool` spec to compare full output of compiler
  instead of a subset.
