# v1.6.0 - 2021-10-14



# Major new features

With so many new features, pinpointing the most salient ones is a subjective exercise,
but here are a select few:


## `iterable[T]`

The `iterable[T]` type class was added to match called iterators,
which solves a number of long-standing issues related to iterators.
Example:

```nim
iterator iota(n: int): int =
  for i in 0..<n: yield i

# previously, you'd need `untyped`, which caused other problems such as lack
# of type inference, overloading issues, and MCS.
template sumOld(a: untyped): untyped = # no type inference possible
  var result: typeof(block:(for ai in a: ai))
  for ai in a: result += ai
  result

assert sumOld(iota(3)) == 0 + 1 + 2

# now, you can write:
template sum[T](a: iterable[T]): T =
  # `template sum(a: iterable): auto =` would also be possible
  var result: T
  for ai in a: result += ai
  result

assert sum(iota(3)) == 0 + 1 + 2 # or `iota(3).sum`
```

In particular iterable arguments can now be used with the method call syntax. For example:
```nim
import std/[sequtils, os]
echo walkFiles("*").toSeq # now works
```
See PR [#17196](https://github.com/nim-lang/Nim/pull/17196) for additional details.


## Strict effects

The effect system was refined and there is a new `.effectsOf` annotation that does
explicitly what was previously done implicitly. See the
[manual](https://nim-lang.github.io/Nim/manual.html#effect-system-effectsof-annotation)
for more details.
To write code that is portable with older Nim versions, use this idiom:

```nim
when defined(nimHasEffectsOf):
  {.experimental: "strictEffects".}
else:
  {.pragma: effectsOf.}

proc mysort(s: seq; cmp: proc(a, b: T): int) {.effectsOf: cmp.}
```

To enable the new effect system, compile with `--experimental:strictEffects`.
See also [#18777](https://github.com/nim-lang/Nim/pull/18777) and RFC
[#408](https://github.com/nim-lang/RFCs/issues/408).


## Private imports and private field access

A new import syntax `import foo {.all.}` now allows importing all symbols
(public or private) from `foo`.
This can be useful for testing purposes or for more flexibility in project organization.

Example:
```nim
from system {.all.} as system2 import nil
echo system2.ThisIsSystem # ThisIsSystem is private in `system`
import os {.all.} # weirdTarget is private in `os`
echo weirdTarget # or `os.weirdTarget`
```

Added a new module `std/importutils`, and an API `privateAccess`, which allows access
to private fields for an object type in the current scope.

Example:
```nim
import times
from std/importutils import privateAccess
block:
  let t = now()
  # echo t.monthdayZero # Error: undeclared field: 'monthdayZero' for type times.DateTime
  privateAccess(typeof(t)) # enables private access in this scope
  echo t.monthdayZero # ok
```

See PR [#17706](https://github.com/nim-lang/Nim/pull/17706) for additional details.


## `nim --eval:cmd`

Added `nim --eval:cmd` to evaluate a command directly, e.g.: `nim --eval:"echo 1"`.
It defaults to `e` (nimscript) but can also work with other commands, e.g.:
```bash
find . | nim r --eval:'import strutils; for a in stdin.lines: echo a.toUpper'
```

```bash
# use as a calculator:
nim --eval:'echo 3.1 / (1.2+7)'
# explore a module's APIs, including private symbols:
nim --eval:'import os {.all.}; echo weirdTarget'
# use a custom backend:
nim r -b:js --eval:"import std/jsbigints; echo 2'big ** 64'big"
```

See PR [#15687](https://github.com/nim-lang/Nim/pull/15687) for more details.


## Round-trip float to string

`system.addFloat` and `system.$` now can produce string representations of
floating point numbers that are minimal in size and possess round-trip and correct
rounding guarantees (via the
[Dragonbox](https://raw.githubusercontent.com/jk-jeon/dragonbox/master/other_files/Dragonbox.pdf) algorithm).
This currently has to be enabled via `-d:nimPreviewFloatRoundtrip`.
It is expected that this behavior becomes the new default in upcoming versions,
as with other `nimPreviewX` define flags.

Example:
```nim
from math import round
let a = round(9.779999999999999, 2)
assert a == 9.78
echo a # with `-d:nimPreviewFloatRoundtrip`: 9.78, like in python3 (instead of  9.779999999999999)
```


## New `std/jsbigints` module

Provides arbitrary precision integers for the JS target. See PR
[#16409](https://github.com/nim-lang/Nim/pull/16409).
Example:
```nim
import std/jsbigints
assert 2'big ** 65'big == 36893488147419103232'big
echo 0xdeadbeef'big shl 4'big # 59774856944n
```


## New `std/sysrand` module
Cryptographically secure pseudorandom number generator,
allows generating random numbers from a secure source provided by the operating system.
Example:
```nim
import std/sysrand
assert urandom(1234) != urandom(1234) # unlikely to fail in practice
```
See PR [#16459](https://github.com/nim-lang/Nim/pull/16459).


## New module: `std/tempfiles`

Allows creating temporary files and directories, see PR
[#17361](https://github.com/nim-lang/Nim/pull/17361) and followups.
```nim
import std/tempfiles
let tmpPath = genTempPath("prefix", "suffix.log", "/tmp/")
# tmpPath looks like: /tmp/prefixpmW1P2KLsuffix.log

let dir = createTempDir("tmpprefix_", "_end")
# created dir looks like: getTempDir() / "tmpprefix_YEl9VuVj_end"

let (cfile, path) = createTempFile("tmpprefix_", "_end.tmp")
# path looks like: getTempDir() / "tmpprefix_FDCIRZA0_end.tmp"
cfile.write "foo"
cfile.setFilePos 0
assert readAll(cfile) == "foo"
close cfile
assert readFile(path) == "foo"
```


## User-defined literals

Custom numeric literals (e.g. `-128'bignum`) are now supported.
Additionally, the unary minus in `-1` is now part of the integer literal, i.e.
it is now parsed as a single token.
This implies that edge cases like `-128'i8` finally work correctly.
Example:
```nim
func `'big`*(num: cstring): JsBigInt {.importjs: "BigInt(#)".}
assert 0xffffffffffffffff'big == (1'big shl 64'big) - 1'big
```


## Dot-like operators

With `-d:nimPreviewDotLikeOps`, dot-like operators (operators starting with `.`,
but not with `..`) now have the same precedence as `.`, so that `a.?b.c` is now
parsed as `(a.?b).c` instead of `a.?(b.c)`.
A warning is generated when a dot-like operator is used without `-d:nimPreviewDotLikeOps`.

An important use case is to enable dynamic fields without affecting the
built-in `.` operator, e.g. for `std/jsffi`, `std/json`, `pkg/nimpy`. Example:
```nim
import std/json
template `.?`(a: JsonNode, b: untyped{ident}): JsonNode =
  a[astToStr(b)]
let j = %*{"a1": {"a2": 10}}
assert j.?a1.?a2.getInt == 10
```


## Block arguments now support optional parameters

This solves a major pain point for routines accepting block parameters,
see PR [#18631](https://github.com/nim-lang/Nim/pull/18631) for details:

```nim
template fn(a = 1, b = 2, body) = discard
fn(1, 2): # already works
  bar
fn(a = 1): # now works
  bar
```

Likewise with multiple block arguments via `do`:
```nim
template fn(a = 1, b = 2, body1, body2) = discard
fn(a = 1): # now works
  bar1
do:
  bar2
```


# Other new features

## New and deprecated modules

The following modules were added (they are discussed in the rest of the text):
- `std/enumutils`
- `std/genasts`
- `std/importutils`
- `std/jsbigints`
- `std/jsfetch`
- `std/jsformdata`
- `std/jsheaders`
- `std/packedsets`
- `std/setutils`
- `std/socketstreams`
- `std/strbasics`
- `std/sysrand`
- `std/tasks`
- `std/tempfiles`
- `std/vmutils`

- Deprecated `std/mersenne`.
- Removed deprecated `std/iup` module from stdlib; it has already moved to
  [nimble](https://github.com/nim-lang/iup).


## New `std/jsfetch` module

Provides a wrapper for JS Fetch API.
Example:
```nim
# requires -d:nimExperimentalAsyncjsThen
import std/[jsfetch, asyncjs, jsconsole, jsffi, sugar]
proc fn {.async.} =
  await fetch("https://api.github.com/users/torvalds".cstring)
    .then((response: Response) => response.json())
    .then((json: JsObject) => console.log(json))
    .catch((err: Error) => console.log("Request Failed", err))
discard fn()
```


## New `std/tasks` module

Provides basic primitives for creating parallel programs.
Example:
```nim
import std/tasks
var num = 0
proc hello(a: int) = num+=a

let b = toTask hello(13) # arguments must be isolated, see `std/isolation`
b.invoke()
assert num == 13
b.invoke() # can be called again
assert num == 26
```


## New module: `std/genasts`

Provides an API `genAst` that avoids the problems inherent with `quote do` and can
be used as a replacement.
Example showing how this could be used for writing a simplified version of `unittest.check`:
```nim
import std/[genasts, macros, strutils]
macro check2(cond: bool): untyped =
  assert cond.kind == nnkInfix, "$# not implemented" % $cond.kind
  result = genAst(cond, s = repr(cond), lhs = cond[1], rhs = cond[2]):
    # each local symbol we access must be explicitly captured
    if not cond:
      doAssert false, "'$#'' failed: lhs: '$#', rhs: '$#'" % [s, $lhs, $rhs]
let a = 3
check2 a*2 == a+3
if false: check2 a*2 < a+1 # would error with: 'a * 2 < a + 1'' failed: lhs: '6', rhs: '4'
```

See PR [#17426](https://github.com/nim-lang/Nim/pull/17426) for details.


## New module: `std/setutils`

- Added `setutils.toSet` that can take any iterable and convert it to a built-in `set`,
  if the iterable yields a built-in settable type.
- Added `setutils.fullSet` which returns a full built-in `set` for a valid type.
- Added `setutils.complement` which returns the complement of a built-in `set`.
- Added `setutils.[]=`.


## New module: `std/enumutils`

- Added `genEnumCaseStmt` macro that generates
  case statement to parse string to enum.
- Added `items` for enums with holes.
- Added `symbolName` to return the `enum` symbol name ignoring the human-readable name.
- Added `symbolRank` to return the index in which an `enum` member is listed in an enum.


## `system`

- Added `system.prepareMutation` for better support of low
  level `moveMem`, `copyMem` operations for `gc:orc`'s copy-on-write string
  implementation.
- `system.addEscapedChar` now renders `\r` as `\r` instead of `\c`, to be compatible
  with most other languages.
- Added `cmpMem` to `system`.
- `doAssertRaises` now correctly handles foreign exceptions.
- `addInt` now supports unsigned integers.

Compatibility notes:
- `system.delete` had surprising behavior when the index passed to it was out of
  bounds (it would delete the last entry then). Compile with `-d:nimStrictDelete` so
  that an index error is produced instead. Be aware however that your code might depend on
  this quirky behavior so a review process is required on your part before you can
  use `-d:nimStrictDelete`. To make this review easier, use the `-d:nimAuditDelete`
  switch, which pretends that `system.delete` is deprecated so that it is easier
  to see where it was used in your code.
  `-d:nimStrictDelete` will become the default in upcoming versions.
- `cuchar` is now deprecated as it aliased `char` where arguably it should have aliased `uint8`.
  Please use `char` or `uint8` instead.
- `repr` now doesn't insert trailing newlines; the previous behavior was very inconsistent,
  see [#16034](https://github.com/nim-lang/Nim/pull/16034).
  Use `-d:nimLegacyReprWithNewline` for the previous behavior.
  `repr` now also renders ASTs correctly for user defined literals, setters, `do`, etc.
- Deprecated `any`. See RFC [#281](https://github.com/nim-lang/RFCs/issues/281).
- The unary slice `..b` was deprecated, use `0..b` instead.


## `std/math`

- Added `almostEqual` for comparing two float values using a machine epsilon.
- Added `clamp` which allows using a `Slice` to clamp to a value.
- Added `ceilDiv` for integer division that rounds up.
- Added `isNaN`.
- Added `copySign`.
- Added `euclDiv` and `euclMod`.
- Added `signbit`.
- Added `frexp` overload procs. Deprecated `c_frexp`, use `frexp` instead.

Compatibility notes:
- `math.round` now rounds "away from zero" in the JS backend, which is consistent
  with other backends. See [#9125](https://github.com/nim-lang/Nim/pull/9125).
  Use `-d:nimLegacyJsRound` for the previous behavior.


## Random number generators: `std/random`, `std/sysrand`, `std/oids`

- Added `std/sysrand` module (see details above).
- Added `randState` template that exposes the default random number generator.
  Useful for library authors.
- Added `initRand()` overload with no argument which uses the current time as a seed.
- `initRand(seed)` now allows `seed == 0`.
- Fixed overflow bugs.
- Fix `initRand` to avoid random number sequences overlapping, refs
  [#18744](https://github.com/nim-lang/Nim/pull/18744).
- `std/oids` now uses `std/random`.

Compatibility notes:
- Deprecated `std/mersenne`.
- `random.initRand(seed)` now produces non-skewed values for the first call to
  `rand()` after initialization with a small (< 30000) seed.
  Use `-d:nimLegacyRandomInitRand` to restore previous behavior for a transition
  time, see PR [#17467](https://github.com/nim-lang/Nim/pull/17467).


## `std/json`, `std/jsonutils`

- With `-d:nimPreviewJsonutilsHoleyEnum`, `jsonutils` now can serialize/deserialize
  holey enums as regular enums (via `ord`) instead of as strings.
  It is expected that this behavior becomes the new default in upcoming versions.
 `toJson` now serializes `JsonNode` as is via reference (without a deep copy)
   instead of treating `JsonNode` as a regular ref object,
  this can be customized via `jsonNodeMode`.
- `std/json` and `std/jsonutils` now serialize `NaN`, `Inf`, `-Inf` as strings,
  so that `%[NaN, -Inf]` is the string `["nan","-inf"]` instead of `[nan,-inf]`
  which was invalid JSON.
- `std/json` can now handle integer literals and floating point literals of
  arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are
  kept as string literals and one can use external BigNum libraries to handle these.
  The `parseFloat` family of functions also has now optional `rawIntegers` and
  `rawFloats` parameters that can be used to enforce that all integer or float
  literals remain in the "raw" string form so that client code can easily treat
  small and large numbers uniformly.
- Added `BackwardsIndex` overload for `JsonNode`.
- `json.%`,`json.to`, `jsonutils.fromJson`,`jsonutils.toJson` now work with `uint|uint64`
  instead of raising (as in 1.4) or giving wrong results (as in 1.2).
- `std/jsonutils` now handles `cstring` (including as Table key), and `set`.
- Added `jsonutils.jsonTo` overload with `opt = Joptions()` param.
- `jsonutils.toJson` now supports customization via `ToJsonOptions`.
- `std/json`, `std/jsonutils` now support round-trip serialization when
  `-d:nimPreviewFloatRoundtrip` is used.


## `std/typetraits`, `std/compilesettings`

- `distinctBase` now is identity instead of error for non distinct types.
- `distinctBase` now allows controlling whether to be recursive or not.
- Added `enumLen` to return the number of elements in an enum.
- Added `HoleyEnum` for enums with holes, `OrdinalEnum` for enums without holes.
- Added `hasClosure`.
- Added `pointerBase` to return `T` for `ref T | ptr T`.
- Added `compilesettings.SingleValueSetting.libPath`.


## networking: `std/net`, `std/asyncnet`, `std/htmlgen`, `std/httpclient`, `std/asyncdispatch`, `std/asynchttpserver`, `std/httpcore`

- Fixed buffer overflow bugs in `std/net`.
- Exported `sslHandle` from `std/net` and `std/asyncnet`.
- Added `hasDataBuffered` to `std/asyncnet`.
- Various functions in `std/httpclient` now accept `url` of type `Uri`.
  Moreover, the `request` function's `httpMethod` argument of type `string` was
  deprecated in favor of `HttpMethod` `enum` type; see
  [#15919](https://github.com/nim-lang/Nim/pull/15919).
- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors.
- Added `getPort` to `std/asynchttpserver` to resolve OS-assigned `Port(0)`;
  this is usually recommended instead of hardcoding ports which can lead to
  "Address already in use" errors.
- Fixed premature garbage collection in `std/asyncdispatch`, when a stacktrace
  override is in place.
- Added `httpcore.is1xx` and missing HTTP codes.
- Added `htmlgen.portal` for [making "SPA style" pages using HTML only](https://web.dev/hands-on-portals).

Compatibility notes:
- On Windows, the SSL library now checks for valid certificates.
  For this purpose it uses the `cacert.pem` file, which was extracted
  from `https://curl.se/ca/cacert.pem`. Besides
  the OpenSSL DLLs (e.g. `libssl-1_1-x64.dll`, `libcrypto-1_1-x64.dll`) you
  now also need to ship `cacert.pem` with your `.exe` file.


## `std/hashes`

- `hashes.hash` can now support `object` and `ref` (can be overloaded in user code),
  if `-d:nimPreviewHashRef` is used. It is expected that this behavior
  becomes the new default in upcoming versions.
- `hashes.hash(proc|ptr|ref|pointer)` now calls `hash(int)` and honors `-d:nimIntHash1`.
  `hashes.hash(closure)` has also been improved.


## OS: `std/os`, `std/io`, `std/socketstream`, `std/linenoise`, `std/tempfiles`

- `os.FileInfo` (returned by `getFileInfo`) now contains `blockSize`,
  determining preferred I/O block size for this file object.
- Added `os.getCacheDir()` to return platform specific cache directory.
- Improved `os.getTempDir()`, see PR [#16914](https://github.com/nim-lang/Nim/pull/16914).
- Added `os.isAdmin` to tell whether the caller's process is a member of the
  Administrators local group (on Windows) or a root (on POSIX).
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
- Added a simpler to use `io.readChars` overload.
- Added `socketstream` module that wraps sockets in the stream interface.
- Added experimental `linenoise.readLineStatus` to get line and status (e.g. ctrl-D or ctrl-C).


## Environment variable handling

- Empty environment variable values are now supported across OS's and backends.
- Environment variable APIs now work in multithreaded scenarios, by delegating to
  direct OS calls instead of trying to keep track of the environment.
- `putEnv`, `delEnv` now work at compile time.
- NodeJS backend now supports osenv: `getEnv`, `putEnv`, `envPairs`, `delEnv`, `existsEnv`.

Compatibility notes:
- `std/os`: `putEnv` now raises if the first argument contains a `=`.


## POSIX

- On POSIX systems, the default signal handlers used for Nim programs (it's
  used for printing the stacktrace on fatal signals) will now re-raise the
  signal for the OS default handlers to handle.
  This lets the OS perform its default actions, which might include core
  dumping (on select signals) and notifying the parent process about the cause
  of termination.
- On POSIX systems, we now ignore `SIGPIPE` signals, use `-d:nimLegacySigpipeHandler`
  for previous behavior.
- Added `posix_utils.osReleaseFile` to get system identification from `os-release`
  file on Linux and the BSDs.
  ([link](https://www.freedesktop.org/software/systemd/man/os-release.html))
- Removed undefined behavior for `posix.open`.


## `std/prelude`

- `std/strformat` is now part of `include std/prelude`.
- Added `std/sequtils` import to `std/prelude`.
- `std/prelude` now works with the JS target.
- `std/prelude` can now be used via `include std/prelude`, but `include prelude` still works.


## String manipulation: `std/strformat`, `std/strbasics`

- Added support for parenthesized expressions.
- Added support for const strings instead of just string literals.
- Added `std/strbasics` for high-performance string operations.
- Added `strip`, `setSlice`, `add(a: var string, b: openArray[char])`.


## `std/wrapnils`

- `std/wrapnils` doesn't use `experimental:dotOperators` anymore, avoiding
  issues like bug [#13063](https://github.com/nim-lang/Nim/issues/13063)
  (which affected error messages) for modules importing `std/wrapnils`.
- Added `??.` macro which returns an `Option`.
- `std/wrapnils` can now be used to protect against `FieldDefect` errors in
  case objects, generates optimal code (no overhead compared to manual
  if-else branches), and preserves lvalue semantics which allows modifying
  an expression.


## Containers: `std/algorithm`, `std/lists`, `std/sequtils`, `std/options`, `std/packedsets`

- Removed the optional `longestMatch` parameter of the `critbits._WithPrefix`
  iterators (it never worked reliably).
- Added `algorithm.merge`.
- In `std/lists`: renamed `append` to `add` and retained `append` as an alias;
  added `prepend` and `prependMoved` analogously to `add` and `addMoved`;
  added `remove` for `SinglyLinkedList`s.
- Added new operations for singly- and doubly linked lists: `lists.toSinglyLinkedList`
  and `lists.toDoublyLinkedList` convert from `openArray`s; `lists.copy` implements
  shallow copying; `lists.add` concatenates two lists - an O(1) variation that consumes
  its argument, `addMoved`, is also supplied.
  See PRs [#16362](https://github.com/nim-lang/Nim/pull/16362),
  [#16536](https://github.com/nim-lang/Nim/pull/16536).
- New module: `std/packedsets`.
  Generalizes `std/intsets`, see PR [#15564](https://github.com/nim-lang/Nim/pull/15564).

Compatibility notes:
- Deprecated `sequtils.delete` and added an overload taking a `Slice` that raises
  a defect if the slice is out of bounds, likewise with `strutils.delete`.
- Deprecated `proc reversed*[T](a: openArray[T], first: Natural, last: int): seq[T]`
  in `std/algorithm`.
- `std/options` changed `$some(3)` to `"some(3)"` instead of `"Some(3)"`
  and `$none(int)` to `"none(int)"` instead of `"None[int]"`.


## `std/times`

- Added `ZZZ` and `ZZZZ` patterns to `times.nim` `DateTime` parsing, to match time
  zone offsets without colons, e.g. `UTC+7 -> +0700`.
- Added `dateTime` and deprecated `initDateTime`.


## `std/macros` and AST

- New module `std/genasts`, see description above.
- The required name of case statement macros for the experimental
  `caseStmtMacros` feature has changed from `match` to `` `case` ``.
- Tuple expressions are now parsed consistently as
  `nnkTupleConstr` node. Will affect macros expecting nodes to be of `nnkPar`.
- In `std/macros`, `treeRepr,lispRepr,astGenRepr` now represent SymChoice nodes
  in a collapsed way.
  Use `-d:nimLegacyMacrosCollapseSymChoice` to get the previous behavior.
- Made custom op in `macros.quote` work for all statements.


## `std/sugar`

- Added `sugar.dumpToString` which improves on `sugar.dump`.
- Added an overload for the `collect` macro that infers the container type based
  on the syntax of the last expression. Works with std seqs, tables and sets.

Compatibility notes:
- Removed support for named procs in `sugar.=>`.


## Parsing: `std/parsecfg`, `std/strscans`, `std/uri`

- Added `sections` iterator in `parsecfg`.
- `strscans.scanf` now supports parsing single characters.
- Added `strscans.scanTuple` which uses `strscans.scanf` internally,
  returning a tuple which can be unpacked for easier usage of `scanf`.
- Added `decodeQuery` to `std/uri`.
- `parseopt.initOptParser` has been made available and `parseopt` has been
  added back to `std/prelude` for all backends. Previously `initOptParser` was
  unavailable if the `std/os` module did not have `paramCount` or `paramStr`,
  but the use of these in `initOptParser` were conditionally to the runtime
  arguments passed to it, so `initOptParser` has been changed to raise
  `ValueError` when the real command line is not available. `parseopt` was
  previously excluded from `std/prelude` for JS, as it could not be imported.

Compatibility notes:
- Changed the behavior of `uri.decodeQuery` when there are unencoded `=`
  characters in the decoded values. Prior versions would raise an error. This is
  no longer the case to comply with the HTML spec and other languages'
  implementations. Old behavior can be obtained with
  `-d:nimLegacyParseQueryStrict`. `cgi.decodeData` which uses the same
  underlying code is also updated the same way.


## JS stdlib changes

- Added `std/jsbigints` module, which provides arbitrary precision integers for the JS target.
- Added `setCurrentException` for the JS backend.
- `writeStackTrace` is available in the JS backend now.
- Added `then`, `catch` to `std/asyncjs` for promise pipelining, for now hidden
  behind `-d:nimExperimentalAsyncjsThen`.
- Added `std/jsfetch` module [Fetch](https://developer.mozilla.org/docs/Web/API/Fetch_API)
  wrapper for the JS target.
- Added `std/jsheaders` module [Headers](https://developer.mozilla.org/en-US/docs/Web/API/Headers)
  wrapper for the JS target.
- Added `std/jsformdata` module [FormData](https://developer.mozilla.org/en-US/docs/Web/API/FormData)
  wrapper for the JS target.
- Added `jscore.debugger` to [call any available debugging functionality, such as breakpoints](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/debugger).
- Added `jsconsole.dir`, `jsconsole.dirxml`, `jsconsole.timeStamp`.
- Added dollar `$` and `len` for `jsre.RegExp`.
- Added `jsconsole.jsAssert` for the JS target.
- Added `**` to `std/jsffi`.
- Added `copyWithin` [for `seq` and `array` for JS targets](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/copyWithin).
- In `std/dom`, `Interval` is now a `ref object`, same as `Timeout`.
  Definitions of `setTimeout`, `clearTimeout`, `setInterval`, `clearInterval` were updated.
- Added `dom.scrollIntoView` proc with options.
- Added `dom.setInterval`, `dom.clearInterval` overloads.
- Merged `std/dom_extensions` into the `std/dom` module,
  as it was a module with a single line, see RFC [#413](https://github.com/nim-lang/RFCs/issues/413).
- `$` now gives more correct results on the JS backend.


## JS compiler changes

- `cstring` doesn't support the `[]=` operator anymore in the JS backend.
- Array literals now use JS typed arrays when the corresponding JS typed array exists,
  for example `[byte(1), 2, 3]` generates `new Uint8Array([1, 2, 3])`.


## VM and nimscript backend

- VM now supports `addr(mystring[ind])` (index + index assignment).
- `nimscript` now handles `except Exception as e`.
- `nil` dereference is not allowed at compile time. `cast[ptr int](nil)[]` is rejected at compile time.
- `static[T]` now works better, refs [#17590](https://github.com/nim-lang/Nim/pull/17590),
  [#15853](https://github.com/nim-lang/Nim/pull/15853).
- `distinct T` conversions now work in VM.
- `items(cstring)` now works in VM.
- Fix `addr`, `len`, `high` in VM ([#16002](https://github.com/nim-lang/Nim/pull/16002),
  [#16610](https://github.com/nim-lang/Nim/pull/16610)).
- `std/cstrutils` now works in VM.


## OS/platform-specific notes

- Support for Apple silicon/M1.
- Support for 32-bit RISC-V, refs [#16231](https://github.com/nim-lang/Nim/pull/16231).
- Support for armv8l, refs [#18901](https://github.com/nim-lang/Nim/pull/18901).
- Support for CROSSOS, refs [#18889](https://github.com/nim-lang/Nim/pull/18889).
- The allocator for Nintendo Switch, which was nonfunctional because
  of breaking changes in libnx, was removed, in favor of the new `-d:nimAllocPagesViaMalloc` option.
- Allow reading parameters when compiling for Nintendo Switch.
- `--nimcache` now correctly works in a cross-compilation setting.
- Cross compilation targeting Windows was improved.
- This now works from macOS/Linux: `nim r -d:mingw main`



## Performance / memory optimizations

- The comment field in PNode AST was moved to a side channel, reducing overall
  memory usage during compilation by a factor 1.25x
- `std/jsonutils` deserialization is now up to 20x faster.
- `os.copyFile` is now 2.5x faster on macOS, by using `copyfile` from `copyfile.h`;
  use `-d:nimLegacyCopyFile` for macOS < 10.5.
- Float to string conversion is now 10x faster thanks to the Dragonbox algorithm,
  with `-d:nimPreviewFloatRoundtrip`.
- `newSeqWith` is 3x faster.
- CI now supports batching (making Windows CI 2.3X faster).
- Sets now uses the optimized `countSetBits` proc, see PR
  [#17334](https://github.com/nim-lang/Nim/pull/17334).


## Debugging

- You can now enable/disable VM tracing in user code via `vmutils.vmTrace`.
- `koch tools` now builds `bin/nim_dbg` which allows easy access to a debug version
  of Nim without recompiling.
- Added new module `compiler/debugutils` to help with debugging Nim compiler.
- Renamed `-d:nimCompilerStackraceHints` to `-d:nimCompilerStacktraceHints` and
  used it in more contexts; this flag which works in tandem with `--stackTraceMsgs`
  to show user code context in compiler stacktraces.


## Type system

- `typeof(voidStmt)` now works and returns `void`.
- `enum` values can now be overloaded. This needs to be enabled
  via `{.experimental: "overloadableEnums".}`. We hope that this feature allows
  for the development of more fluent (less ugly) APIs.
  See RFC [#373](https://github.com/nim-lang/RFCs/issues/373) for more details.
- A type conversion from one `enum` type to another now produces an `[EnumConv]` warning.
  You should use `ord` (or `cast`, but the compiler won't help, if you misuse it) instead.
  ```nim
  type A = enum a1, a2
  type B = enum b1, b2
  echo a1.B # produces a warning
  echo a1.ord.B # produces no warning
  ```
- A dangerous implicit conversion to `cstring` now triggers a `[CStringConv]` warning.
  This warning will become an error in future versions! Use an explicit conversion
  like `cstring(x)` in order to silence the warning.
- There is a new warning for *any* type conversion to `enum` that can be enabled via
  `.warning[AnyEnumConv]:on` or `--warning:AnyEnumConv:on`.
- Reusing a type name in a different scope now works, refs [#17710](https://github.com/nim-lang/Nim/pull/17710).
- Fixed implicit and explicit generics in procedures, refs [#18808](https://github.com/nim-lang/Nim/pull/18808).


## New-style concepts

Example:
```nim
type
  Comparable = concept # no T, an atom
    proc cmp(a, b: Self): int
```
The new design does not rely on `system.compiles` and may compile faster.
See PR [#15251](https://github.com/nim-lang/Nim/pull/15251)
and RFC [#168](https://github.com/nim-lang/RFCs/issues/168) for details.


## Lexical / syntactic

- Nim now supports a small subset of Unicode operators as operator symbols.
  The supported symbols are: "∙ ∘ × ★ ⊗ ⊘ ⊙ ⊛ ⊠ ⊡ ∩ ∧ ⊓ ± ⊕ ⊖ ⊞ ⊟ ∪ ∨ ⊔".
  To enable this feature, use `--experimental:unicodeOperators`. Note that due
  to parser limitations you **cannot** enable this feature via a
  pragma `{.experimental: "unicodeOperators".}` reliably, you need to enable
  it via the command line or in a configuration file.
- `var a {.foo.} = expr` now works inside templates (except when `foo` is overloaded).


## Compiler messages, error messages, hints, warnings

- Significant improvement to error messages involving effect mismatches,
  see PRs [#18384](https://github.com/nim-lang/Nim/pull/18384),
  [#18418](https://github.com/nim-lang/Nim/pull/18418).
- Added `--declaredLocs` to show symbol declaration location in error messages.
- Added `--spellSuggest` to show spelling suggestions on typos.
- Added `--processing:dots|filenames|off` which customizes `hintProcessing`;
  `--processing:filenames` shows which include/import modules are being compiled as an import stack.
- `FieldDefect` messages now shows discriminant value + lineinfo, in all backends (C, JS, VM)
- Added `--hintAsError` with similar semantics as `--warningAsError`.
- Added `--unitsep:on|off` to control whether to add ASCII unit separator `\31`
  before a newline for every generated message (potentially multiline),
  so tooling can tell when messages start and end.
- Added `--filenames:abs|canonical|legacyRelProj` which replaces `--listFullPaths:on|off`
- `--hint:all:on|off` is now supported to select or deselect all hints; it
  differs from `--hints:on|off` which acts as a (reversible) gate.
  Likewise with `--warning:all:on|off`.
- The style checking of the compiler now supports a `--styleCheck:usages` switch.
  This switch enforces that every symbol is written as it was declared, not enforcing
  the official Nim style guide. To be enabled, this has to be combined either
  with `--styleCheck:error` or `--styleCheck:hint`.
- Type mismatch errors now show more context, use `-d:nimLegacyTypeMismatch` for
  previous behavior.
- `typedesc[Foo]` now renders as such instead of `type Foo` in compiler messages.
- `runnableExamples` now show originating location in stacktraces on failure.
- `SuccessX` message now shows more useful information.
- New `DuplicateModuleImport` warning; improved `UnusedImport` and
  `XDeclaredButNotUsed` accuracy.

Compatibility notes:
- `--hint:CC` now prints to stderr (like all other hints) instead of stdout.


## Building and running Nim programs, configuration system

- JSON build instructions are now generated in `$nimcache/outFileBasename.json`
  instead of `$nimcache/projectName.json`. This allows avoiding recompiling a
  given project compiled with different options if the output file differs.
- `--usenimcache` (implied by `nim r main`) now generates an output file that includes
  a hash of some of the compilation options, which allows caching generated binaries:
  ```bash
    nim r main # recompiles
    nim r -d:foo main # recompiles
    nim r main # uses cached binary
    nim r main arg1 arg2 # likewise (runtime arguments are irrelevant)
  ```
- `nim r` now supports cross compilation from unix to windows when specifying
  `-d:mingw` by using Wine, e.g.:
  `nim r --eval:'import os; echo "a" / "b"'` prints `a\b`.
- `nim` can compile version 1.4.0 as follows:
  `nim c --lib:lib --stylecheck:off -d:nimVersion140 compiler/nim`.
  `-d:nimVersion140` is not needed for bootstrapping, only for building 1.4.0 from devel.
- `nim e` now accepts arbitrary file extensions for the nimscript file,
  although `.nims` is still the preferred extension in general.
- The configuration subsystem now allows for `-d:release` and `-d:danger` to work as expected.
  The downside is that these defines now have custom logic that doesn't apply for
  other defines.


## Multithreading

- TLS: macOS now uses native TLS (`--tlsEmulation:off`). TLS now works with
  `importcpp` non-POD types; such types must use `.cppNonPod` and
  `--tlsEmulation:off`should be used.
- Added `unsafeIsolate` and `extract` to `std/isolation`.
- Added `std/tasks`, see description above.


## Memory management

- `--gc:arc` now bootstraps (PR [#17342](https://github.com/nim-lang/Nim/pull/17342)).
- Lots of improvements to `gc:arc`, `gc:orc`, see PR
  [#15697](https://github.com/nim-lang/Nim/pull/15697),
  [#16849](https://github.com/nim-lang/Nim/pull/16849),
  [#17993](https://github.com/nim-lang/Nim/pull/17993).
- `--gc:orc` is now 10% faster than previously for common workloads.
  If you have trouble with its changed behavior, compile with `-d:nimOldOrc`.
- The `--gc:orc` algorithm was refined so that custom container types can participate in the
  cycle collection process. See the documentation of `=trace` for more details.
- On embedded devices `malloc` can now be used instead of `mmap` via `-d:nimAllocPagesViaMalloc`.
  This is only supported for `--gc:orc` or `--gc:arc`.

Compatibility notes:
- `--newruntime` and `--refchecks` are deprecated,
  use `--gc:arc`, `--gc:orc`, or `--gc:none` as appropriate instead.


## Docgen

- docgen: RST files can now use single backticks instead of double backticks and
  correctly render in both `nim rst2html` (as before) as well as common tools rendering
  RST directly (e.g. GitHub).
  This is done by adding the `default-role:: code` directive inside the RST file
  (which is now handled by `nim rst2html`).
- Source+Edit links now appear on top of every docgen'd page when
  `nim doc --git.url:url ...` is given.
- Latex doc generation is revised: output `.tex` files should be compiled
  by `xelatex` (not by `pdflatex` as before). Now default Latex settings
  provide support for Unicode and better avoid margin overflows.
  The minimum required version is TeXLive 2018 (or an equivalent MikTeX version).
- The RST parser now supports footnotes, citations, admonitions, and short style
  references with symbols.
- The RST parser now supports Markdown table syntax.
  Known limitations:
  - cell alignment is not supported, i.e. alignment annotations in a delimiter
    row (`:---`, `:--:`, `---:`) are ignored
  - every table row must start with `|`, e.g. `| cell 1 | cell 2 |`.
- Implemented `doc2tex` compiler command which converts documentation in
  `.nim` files to Latex.
- docgen now supports syntax highlighting for inline code.
- docgen now supports same-line doc comments:
  ```nim
  func fn*(a: int): int = 42  ## Doc comment
  ```
- docgen now renders `deprecated` and other pragmas.
- `runnableExamples` now works with templates and nested templates.
- `runnableExamples: "-r:off"` now works for examples that should compile but not run.
- `runnableExamples` now renders code verbatim, and produces correct code in all cases.
- docgen now shows correct, canonical import paths in docs.
- docgen now shows all routines in sidebar, and the proc signature is now shown in sidebar.


## Effects and checks

- Significant improvement to error messages involving effect mismatches
- There is a new `cast` section `{.cast(uncheckedAssign).}: body` that disables some
  compiler checks regarding `case objects`. This allows serialization libraries
  to avoid ugly, non-portable solutions. See RFC
  [#407](https://github.com/nim-lang/RFCs/issues/407) for more details.

Compatibility notes:
- Fixed effect tracking for borrowed procs (see [#18882](https://github.com/nim-lang/Nim/pull/18882)).
  One consequence is that, under some circumstances, Nim could previously permit a procedure with side effects to be written with `func` - you may need to change some occurrences of `func` to `proc`.
  To illustrate, Nim versions before 1.6.0 compile the below without error
  ```nim
  proc print(s: string) =
    echo s

  type
    MyString = distinct string

  proc print(s: MyString) {.borrow.}

  func foo(s: MyString) =
    print(s)
  ```
  but Nim 1.6.0 produces the error
  ```
  Error: 'foo' can have side effects
  ```
  similar to how we expect that
  ```nim
  func print(s: string) =
    echo s
  ```
  produces
  ```
  Error: 'print' can have side effects
  ```


## Tools

- Major improvements to `nimgrep`, see PR [#15612
](https://github.com/nim-lang/Nim/pull/15612).
- `fusion` is now un-bundled from Nim, `./koch fusion` will
  install it via Nimble at a fixed hash.
- `testament`: added `nimoutFull: bool` spec to compare full output of compiler
  instead of a subset; many bugfixes to testament.


## Misc/cleanups

- Deprecated `TaintedString` and `--taintmode`.
- Deprecated `--nilseqs` which is now a noop.
- Added `-d:nimStrictMode` in CI in several places to ensure code doesn't have
  certain hints/warnings.
- Removed `.travis.yml`, `appveyor.yml.disabled`, `.github/workflows/ci.yml.disabled`.
- `[skip ci]` now works in azure and CI pipelines, see detail in PR
  [#17561](https://github.com/nim-lang/Nim/pull/17561).
