# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes
- Added support for parenthesized expressions in `strformat`

- Fixed buffer overflow bugs in `net`

- Added `sections` iterator in `parsecfg`.

- Make custom op in macros.quote work for all statements.

  For `net` and `nativesockets`, an `inheritable` flag has been added to all
  `proc`s that create sockets, allowing the user to control whether the
  resulting socket is inheritable. This flag is provided to ease the writing of
  multi-process servers, where sockets inheritance is desired.

  For a transistion period, define `nimInheritHandles` to enable file handle
  inheritance by default. This flag does **not** affect the `selectors` module
  due to the differing semantics between operating systems.

  `system.setInheritable` and `nativesockets.setInheritable` is also introduced
  for setting file handle or socket inheritance. Not all platform have these
  `proc`s defined.

- The file descriptors created for internal bookkeeping by `ioselector_kqueue`
  and `ioselector_epoll` will no longer be leaked to child processes.

- `strutils.formatFloat` with `precision = 0` has been restored to the version
  1 behaviour that produces a trailing dot, e.g. `formatFloat(3.14159, precision = 0)`
  is now `3.`, not `3`.
- `critbits` adds `commonPrefixLen`.

- `relativePath(rel, abs)` and `relativePath(abs, rel)` used to silently give wrong results
  (see #13222); instead they now use `getCurrentDir` to resolve those cases,
  and this can now throw in edge cases where `getCurrentDir` throws.
  `relativePath` also now works for js with `-d:nodejs`.

- JavaScript and NimScript standard library changes: `streams.StringStream` is
  now supported in JavaScript, with the limitation that any buffer `pointer`s
  used must be castable to `ptr string`, any incompatible pointer type will not
  work. The `lexbase` and `streams` modules used to fail to compile on
  NimScript due to a bug, but this has been fixed.
  
  The following modules now compile on both JS and NimScript: `parsecsv`,
  `parsecfg`, `parsesql`, `xmlparser`, `htmlparser` and `ropes`. Additionally
  supported for JS is `cstrutils.startsWith` and `cstrutils.endsWith`, for
  NimScript: `json`, `parsejson`, `strtabs` and `unidecode`. 

- Added `streams.readStr` and `streams.peekStr` overloads to
  accept an existing string to modify, which avoids memory
  allocations, similar to `streams.readLine` (#13857).

- Added high-level `asyncnet.sendTo` and `asyncnet.recvFrom`. UDP functionality.

- `paramCount` & `paramStr` are now defined in os.nim instead of nimscript.nim for nimscript/nimble.
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

- The `times` module now handles the default value for `DateTime` more consistently. Most procs raise an assertion error when given
  an uninitialized `DateTime`, the exceptions are `==` and `$` (which returns `"Uninitialized DateTime"`). The proc `times.isInitialized`
  has been added which can be used to check if a `DateTime` has been initialized.

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
- On Windows the SSL library now checks for valid certificates.
  It uses the `cacert.pem` file for this purpose which was extracted
  from `https://curl.se/ca/cacert.pem`. Besides
  the OpenSSL DLLs (e.g. libssl-1_1-x64.dll, libcrypto-1_1-x64.dll) you
  now also need to ship `cacert.pem` with your `.exe` file.


- Make `{.requiresInit.}` pragma to work for `distinct` types.


- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors
- Added `asyncdispatch.maxDescriptors` that returns the maximum number of
  active async event handles/file descriptors.

- Added `getPort` to `asynchttpserver`.

- `--gc:orc` is now 10% faster than previously for common workloads. If
  you have trouble with its changed behavior, compile with `-d:nimOldOrc`.


- `os.FileInfo` (returned by `getFileInfo`) now contains `blockSize`,
  determining preferred I/O block size for this file object.

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


- Added to `wrapnils` an option-like API via `??.`, `isSome`, `get`.

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

- Added `hasClosure` to `std/typetraits`.

- Added `std/tempfiles`.

- Added `genasts.genAst` that avoids the problems inherent with `quote do` and can
  be used as a replacement.

- Added `copyWithin` [for `seq` and `array` for JavaScript targets](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/copyWithin).

- Fixed premature garbage collection in asyncdispatch, when a stack trace override is in place.

## Language changes
- In newruntime it is now allowed to assign discriminator field without restrictions as long as case object doesn't have custom destructor. Discriminator value doesn't have to be a constant either. If you have custom destructor for case object and you do want to freely assign discriminator fields, it is recommended to refactor object into 2 objects like this: 

- The `=destroy` hook no longer has to reset its target, as the compiler now automatically inserts
  `wasMoved` calls where needed.
- The `=` hook is now called `=copy` for clarity. The old name `=` is still available so there
  is no need to update your code. This change was backported to 1.2 too so you can use the
  more readability `=copy` without loss of compatibility.

- In the newruntime it is now allowed to assign to the discriminator field
  without restrictions as long as case object doesn't have custom destructor.
  The discriminator value doesn't have to be a constant either. If you have a
  custom destructor for a case object and you do want to freely assign discriminator
  fields, it is recommended to refactor object into 2 objects like this:

  ```nim
  type
    MyObj = object
      case kind: bool
        of true: y: ptr UncheckedArray[float]
        of false: z: seq[int]

  proc `=destroy`(x: MyObj) =
    if x.kind and x.y != nil:
      deallocShared(x.y)
      x.y = nil
  ```
  Refactor into:
  ```nim
  type
    MySubObj = object
      val: ptr UncheckedArray[float]
    MyObj = object
      case kind: bool
      of true: y: MySubObj
      of false: z: seq[int]

  proc `=destroy`(x: MySubObj) =
    if x.val != nil:
      deallocShared(x.val)
      x.val = nil
  ```

## Compiler changes


- The style checking of the compiler now supports a `--styleCheck:usages` switch. This switch
  enforces that every symbol is written as it was declared, not enforcing
  the official Nim style guide. To be enabled, this has to be combined either
  with `--styleCheck:error` or `--styleCheck:hint`.

## Tool changes

