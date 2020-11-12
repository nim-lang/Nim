# v1.6.x - yyyy-mm-dd



## Standard library additions and changes

- Make `{.requiresInit.}` pragma to work for `distinct` types.

- Added a macros `enumLen` for returning the number of items in an enum to the
  `typetraits.nim` module.

- `prelude` now works with the JavaScript target.

- Added `almostEqual` in `math` for comparing two float values using a machine epsilon.

- The JSON module can now handle integer literals and floating point literals of
  arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are
  kept as string literals and one can use external BigNum libraries to handle these.
  The `parseFloat` family of functions also has now optional `rawIntegers` and
  `rawFloats` parameters that can be used to enforce that all integer or float
  literals remain in the "raw" string form so that client code can easily treat
  small and large numbers uniformly.

- Added `randState` template that exposes the default random number generator.
  Useful for library authors.

- Added std/enumutils module containing `genEnumCaseStmt` macro that generates
  case statement to parse string to enum.

- Removed deprecated `iup` module from stdlib, it has already moved to
  [nimble](https://github.com/nim-lang/iup).

  The following modules now compile on both JS and NimScript: `parsecsv`,
  `parsecfg`, `parsesql`, `xmlparser`, `htmlparser` and `ropes`. Additionally
  supported for JS is `cstrutils.startsWith` and `cstrutils.endsWith`, for
  NimScript: `json`, `parsejson`, `strtabs` and `unidecode`.

- Added `streams.readStr` and `streams.peekStr` overloads to
  accept an existing string to modify, which avoids memory
  allocations, similar to `streams.readLine` (#13857).

- Added high-level `asyncnet.sendTo` and `asyncnet.recvFrom` UDP functionality.

- `dollars.$` now works for unsigned ints with `nim js`

- Improvements to the `bitops` module, including bitslices, non-mutating versions
  of the original masking functions, `mask`/`masked`, and varargs support for
  `bitand`, `bitor`, and `bitxor`.

- `sugar.=>` and `sugar.->` changes: Previously `(x, y: int)` was transformed
  into `(x: auto, y: int)`, it now becomes `(x: int, y: int)` in consistency
  with regular proc definitions (although you cannot use semicolons).

  Pragmas and using a name are now allowed on the lefthand side of `=>`. Here
  is an aggregate example of these changes:
  ```nim
  import sugar

  foo(x, y: int) {.noSideEffect.} => x + y

  # is transformed into

  proc foo(x: int, y: int): auto {.noSideEffect.} = x + y
  ```

- The fields of `times.DateTime` are now private, and are accessed with getters and deprecated setters.

- The `times` module now handles the default value for `DateTime` more consistently.
  Most procs raise an assertion error when given
  an uninitialized `DateTime`, the exceptions are `==` and `$` (which returns `"Uninitialized DateTime"`).
  The proc `times.isInitialized` has been added which can be used to check if
  a `DateTime` has been initialized.

- Fix a bug where calling `close` on io streams in osproc.startProcess was a noop and led to
  hangs if a process had both reads from stdin and writes (eg to stdout).

- The callback that is passed to `system.onThreadDestruction` must now be `.raises: []`.
- The callback that is assigned to `system.onUnhandledException` must now be `.gcsafe`.

- `osproc.execCmdEx` now takes an optional `input` for stdin, `workingDir` and `env`
  parameters.

- Added a `ssl_config` module containing lists of secure ciphers as recommended by
  [Mozilla OpSec](https://wiki.mozilla.org/Security/Server_Side_TLS)

- `net.newContext` now defaults to the list of ciphers targeting
  ["Intermediate compatibility"](https://wiki.mozilla.org/Security/Server_Side_TLS#Intermediate_compatibility_.28recommended.29)
  per Mozilla's recommendation instead of `ALL`. This change should protect
  users from the use of weak and insecure ciphers while still provides
  adequate compatibility with the majority of the Internet.

- A new module `std/jsonutils` with hookable `jsonTo,toJson,fromJson` operations for json
  serialization/deserialization of custom types was added.

- A new proc `heapqueue.find[T](heap: HeapQueue[T], x: T): int` to get index of element ``x``
  was added.
- Added `rstgen.rstToLatex` convenience proc for `renderRstToOut` and `initRstGenerator`
  with `outLatex` output.
- Added `os.normalizeExe`, e.g.: `koch` => `./koch`.
- `macros.newLit` now preserves named vs unnamed tuples; use `-d:nimHasWorkaround14720`
  to keep old behavior.
- Added `random.gauss`, that uses the ratio of uniforms method of sampling from a Gaussian distribution.
- Added `typetraits.elementType` to get element type of an iterable.
- `typetraits.$` changes: `$(int,)` is now `"(int,)"` instead of `"(int)"`;
  `$tuple[]` is now `"tuple[]"` instead of `"tuple"`;
  `$((int, float), int)` is now `"((int, float), int)"` instead of `"(tuple of (int, float), int)"`
- Added `macros.extractDocCommentsAndRunnables` helper

- `strformat.fmt` and `strformat.&` support `= specifier`. `fmt"{expr=}"` now
  expands to `fmt"expr={expr}"`.
- deprecations: `os.existsDir` => `dirExists`, `os.existsFile` => `fileExists`

- Added `jsre` module, [Regular Expressions for the JavaScript target.](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions)
- Made `maxLines` argument `Positive` in `logging.newRollingFileLogger`,
  because negative values will result in a new file being created for each logged
  line which doesn't make sense.
- Changed `log` in `logging` to use proper log level on JavaScript target,
  e.g. `debug` uses `console.debug`, `info` uses `console.info`, `warn` uses `console.warn`, etc.
- Tables, HashSets, SharedTables and deques don't require anymore that the passed
  initial size must be a power of two - this is done internally.
  Proc `rightSize` for Tables and HashSets is deprecated, as it is not needed anymore.
  `CountTable.inc` takes `val: int` again not `val: Positive`; I.e. it can "count down" again.
- Removed deprecated symbols from `macros` module, deprecated as far back as `0.15`.
- Removed `sugar.distinctBase`, deprecated since `0.19`.
- Export `asyncdispatch.PDispatcher.handles` so that an external library can register them.

- `std/with`, `sugar.dup` now support object field assignment expression:
  ```nim
  import std/with

  type Foo = object
    x, y: int

  var foo = Foo()
  with foo:
    x = 10
    y = 20

  echo foo
  ```

- Proc `math.round` is no longer deprecated. The advice to use `strformat` instead
  cannot be applied to every use case. The limitations and the (lack of) reliability
  of `round` are well documented.

- Added `getprotobyname` to `winlean`. Added `getProtoByname` to `nativesockets` which returns a protocol code
  from the database that matches the protocol `name`.

- Added missing attributes and methods to `dom.Navigator` like `deviceMemory`, `onLine`, `vibrate()`, etc.

- Added `strutils.indentation` and `strutils.dedent` which enable indented string literals:
  ```nim
  import strutils
  echo dedent """
    This
      is
        cool!
    """
  ```

- Add `initUri(isIpv6: bool)` to `uri` module, now `uri` supports parsing ipv6 hostname.
- Add `strmisc.parseFloatThousandSep` designed to parse floats as found in the wild formatted for humans.

- Added `initUri(isIpv6: bool)` to `uri` module, now `uri` supports parsing ipv6 hostname.

- Added `readLines(p: Process)` to `osproc` module for `startProcess` convenience.

- Added the below `to` procs for collections. The usage is similar to procs such as
  `sets.toHashSet` and `tables.toTable`. Previously, it was necessary to create the
  respective empty collection and add items manually.
    * `critbits.toCritBitTree`, which creates a `CritBitTree` from an `openArray` of
       items or an `openArray` of pairs.
    * `deques.toDeque`, which creates a `Deque` from an `openArray`.
    * `heapqueue.toHeapQueue`, which creates a `HeapQueue` from an `openArray`.
    * `intsets.toIntSet`, which creates an `IntSet` from an `openArray`.

- Added `progressInterval` argument to `asyncftpclient.newAsyncFtpClient` to control the interval
  at which progress callbacks are called.
- nodejs now supports osenv: `getEnv`, `putEnv`, `envPairs`, `delEnv`, `existsEnv`

- `doAssertRaises` now correctly handles foreign exceptions.

## Language changes

- `nimscript` now handles `except Exception as e`
- The `cstring` doesn't support `[]=` operator in JS backend.



## Compiler changes

- Added `--declaredlocs` to show symbol declaration location in messages.

- Source+Edit links now appear on top of every docgen'd page when
  `nim doc --git.url:url ...` is given.

- Added `nim --eval:cmd` to evaluate a command directly, see `nim --help`.



## Tool changes

- The rst parser now supports markdown table syntax.
  Known limitations:
  - cell alignment is not supported, i.e. alignment annotations in a delimiter
    row (`:---`, `:--:`, `---:`) are ignored,
  - every table row must start with `|`, e.g. `| cell 1 | cell 2 |`.
