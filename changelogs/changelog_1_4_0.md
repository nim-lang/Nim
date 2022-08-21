# v1.4.0 - 2020-10-16



## Standard library additions and changes

- Added some enhancements to `std/jsonutils` module.
  * Added a possibility to deserialize JSON arrays directly to `HashSet` and
    `OrderedSet` types and respectively to serialize those types to JSON arrays
    via `jsonutils.fromJson` and `jsonutils.toJson` procedures.
  * Added a possibility to deserialize JSON `null` objects to Nim option objects
    and respectively to serialize Nim option object to JSON object if `isSome`
    or to JSON null object if `isNone` via `jsonutils.fromJson` and
    `jsonutils.toJson` procedures.
  * Added a `Joptions` parameter to `jsonutils.fromJson` currently
    containing two boolean options `allowExtraKeys` and `allowMissingKeys`.
    - If `allowExtraKeys` is `true` Nim's object to which the JSON is parsed is
      not required to have a field for every JSON key.
    - If `allowMissingKeys` is `true` Nim's object to which JSON is parsed is
      allowed to have fields without corresponding JSON keys.
- Added `bindParams`, `bindParam` to `db_sqlite` for binding parameters into a `SqlPrepared` statement.
- Added `tryInsert`,`insert` procs to `db_*` libs which accept primary key column name.
- Added `xmltree.newVerbatimText` support create `style`'s,`script`'s text.
- `uri` module now implements RFC-2397.
- Added [DOM Parser](https://developer.mozilla.org/en-US/docs/Web/API/DOMParser)
  to the `dom` module for the JavaScript target.
- The default hash for `Ordinal` has changed to something more bit-scrambling.
  `import hashes; proc hash(x: myInt): Hash = hashIdentity(x)` recovers the old
  one in an instantiation context while `-d:nimIntHash1` recovers it globally.
- `deques.peekFirst` and `deques.peekLast` now have `var Deque[T] -> var T` overloads.
- File handles created from high-level abstractions in the stdlib will no longer
  be inherited by child processes. In particular, these modules are affected:
  `asyncdispatch`, `asyncnet`, `system`, `nativesockets`, `net` and `selectors`.

  For `asyncdispatch`, `asyncnet`, `net` and `nativesockets`, an `inheritable`
  flag has been added to all `proc`s that create sockets, allowing the user to
  control whether the resulting socket is inheritable. This flag is provided to
  ease the writing of multi-process servers, where sockets inheritance is
  desired.

  For a transition period, define `nimInheritHandles` to enable file handle
  inheritance by default. This flag does **not** affect the `selectors` module
  due to the differing semantics between operating systems.

  `asyncdispatch.setInheritable`, `system.setInheritable` and
  `nativesockets.setInheritable` are also introduced for setting file handle or
  socket inheritance. Not all platforms have these `proc`s defined.

- The file descriptors created for internal bookkeeping by `ioselector_kqueue`
  and `ioselector_epoll` will no longer be leaked to child processes.

- `strutils.formatFloat` with `precision = 0` has been restored to the version
  1 behaviour that produces a trailing dot, e.g. `formatFloat(3.14159, precision = 0)`
  is now `3.`, not `3`.
- Added `commonPrefixLen` to `critbits`.

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

- Added high-level `asyncnet.sendTo` and `asyncnet.recvFrom` UDP functionality.

- `dollars.$` now works for unsigned ints with `nim js`.

- Improvements to the `bitops` module, including bitslices, non-mutating versions
  of the original masking functions, `mask`/`masked`, and varargs support for
  `bitand`, `bitor`, and `bitxor`.

- `sugar.=>` and `sugar.->` changes: Previously `(x, y: int)` was transformed
  into `(x: auto, y: int)`, it now becomes `(x: int, y: int)` for consistency
  with regular proc definitions (although you cannot use semicolons).

  Pragmas and using a name are now allowed on the lefthand side of `=>`. Here
  is an example of these changes:
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

- Fix a bug where calling `close` on io streams in `osproc.startProcess` was a noop and led to
  hangs if a process had both reads from stdin and writes (e.g. to stdout).

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
- Added `rstgen.rstToLatex` a convenience proc for `renderRstToOut` and `initRstGenerator`.
- Added `os.normalizeExe`.
- `macros.newLit` now preserves named vs unnamed tuples.
- Added `random.gauss`, that uses the ratio of uniforms method of sampling from a Gaussian distribution.
- Added `typetraits.elementType` to get the element type of an iterable.
- `typetraits.$` changes: `$(int,)` is now `"(int,)"` instead of `"(int)"`;
  `$tuple[]` is now `"tuple[]"` instead of `"tuple"`;
  `$((int, float), int)` is now `"((int, float), int)"` instead of `"(tuple of (int, float), int)"`
- Added `macros.extractDocCommentsAndRunnables` helper.

- `strformat.fmt` and `strformat.&` support `specifier =`. `fmt"{expr=}"` now
  expands to `fmt"expr={expr}"`.
- Deprecations: instead of `os.existsDir` use `dirExists`, instead of `os.existsFile` use `fileExists`.

- Added the `jsre` module, [Regular Expressions for the JavaScript target.](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions).
- Made `maxLines` argument `Positive` in `logging.newRollingFileLogger`,
  because negative values will result in a new file being created for each logged
  line which doesn't make sense.
- Changed `log` in `logging` to use proper log level for JavaScript,
  e.g. `debug` uses `console.debug`, `info` uses `console.info`, `warn` uses `console.warn`, etc.
- Tables, HashSets, SharedTables and deques don't require anymore that the passed
  initial size must be a power of two - this is done internally.
  Proc `rightSize` for Tables and HashSets is deprecated, as it is not needed anymore.
  `CountTable.inc` takes `val: int` again not `val: Positive`; i.e. it can "count down" again.
- Removed deprecated symbols from `macros` module, some of which were deprecated already in `0.15`.
- Removed `sugar.distinctBase`, deprecated since `0.19`. Use `typetraits.distinctBase`.
- `asyncdispatch.PDispatcher.handles` is exported so that an external low-level libraries can access it.

- `std/with`, `sugar.dup` now support object field assignment expressions:
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

- Added `initUri(isIpv6: bool)` to `uri` module, now `uri` supports parsing ipv6 hostname.

- Added `readLines(p: Process)` to `osproc`.

- Added the below `toX` procs for collections. The usage is similar to procs such as
  `sets.toHashSet` and `tables.toTable`. Previously, it was necessary to create the
  respective empty collection and add items manually.
    * `critbits.toCritBitTree`, which creates a `CritBitTree` from an `openArray` of
       items or an `openArray` of pairs.
    * `deques.toDeque`, which creates a `Deque` from an `openArray`.
    * `heapqueue.toHeapQueue`, which creates a `HeapQueue` from an `openArray`.
    * `intsets.toIntSet`, which creates an `IntSet` from an `openArray`.

- Added `progressInterval` argument to `asyncftpclient.newAsyncFtpClient` to control the interval
  at which progress callbacks are called.

- Added `os.copyFileToDir`.

## Language changes

- The `=destroy` hook no longer has to reset its target, as the compiler now automatically inserts
  `wasMoved` calls where needed.
- The `=` hook is now called `=copy` for clarity. The old name `=` is still available so there
  is no need to update your code. This change was backported to 1.2 too so you can use the
  more readable `=copy` without loss of compatibility.

- In the newruntime it is now allowed to assign to the discriminator field
  without restrictions as long as the case object doesn't have a custom destructor.
  The discriminator value doesn't have to be a constant either. If you have a
  custom destructor for a case object and you do want to freely assign discriminator
  fields, it is recommended to refactor the object into 2 objects like this:

  ```nim
  type
    MyObj = object
      case kind: bool
      of true: y: ptr UncheckedArray[float]
      of false: z: seq[int]

  proc `=destroy`(x: MyObj) =
    if x.kind and x.y != nil:
      deallocShared(x.y)
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
  ```
- `getImpl` on enum type symbols now returns field syms instead of idents. This helps
  with writing typed macros. The old behavior for backwards compatibility can be restored
  with `--useVersion:1.0`.
- The typed AST for proc headers will now have the arguments be syms instead of idents.
  This helps with writing typed macros. The old behaviour for backwards compatibility can
  be restored with `--useVersion:1.0`.
- ``let`` statements can now be used without a value if declared with
  ``importc``/``importcpp``/``importjs``/``importobjc``.
- The keyword `from` is now usable as an operator.
- Exceptions inheriting from `system.Defect` are no longer tracked with
  the `.raises: []` exception tracking mechanism. This is more consistent with the
  built-in operations. The following always used to compile (and still does):
  ```nim
  proc mydiv(a, b): int {.raises: [].} =
    a div b # can raise an DivByZeroDefect
  ```

  Now also this compiles:
  ```nim
  proc mydiv(a, b): int {.raises: [].} =
    if b == 0: raise newException(DivByZeroDefect, "division by zero")
    else: result = a div b
  ```

  The reason for this is that `DivByZeroDefect` inherits from `Defect` and
  with `--panics:on` `Defects` become unrecoverable errors.

- Added the `thiscall` calling convention as specified by Microsoft, mostly for hooking purposes.
- Deprecated the `{.unroll.}` pragma, because it was always ignored by the compiler anyway.
- Removed the deprecated `strutils.isNilOrWhitespace`.
- Removed the deprecated `sharedtables.initSharedTable`.
- Removed the deprecated `asyncdispatch.newAsyncNativeSocket`.
- Removed the deprecated `dom.releaseEvents` and `dom.captureEvents`.

- Removed `sharedlist.initSharedList`, was deprecated and produces undefined behaviour.

- There is a new experimental feature called "strictFuncs" which makes the definition of
  `.noSideEffect` stricter. [See here](manual_experimental.html#stricts-funcs)
  for more information.

- "for-loop macros" (see [the manual](manual.html#macros-for-loop-macros)) are no longer
  an experimental feature. In other words, you don't have to write pragma
  `{.experimental: "forLoopMacros".}` if you want to use them.

- Added the ``.noalias`` pragma. It is mapped to C's ``restrict`` keyword for the increased
  performance this keyword can enable.

- `items` no longer compiles with enums with holes as its behavior was error prone, see #14004.
- `system.deepcopy` has to be enabled explicitly for `--gc:arc` and `--gc:orc` via
  `--deepcopy:on`.

- Added the `std/effecttraits` module for introspection of the inferred effects.
  We hope this enables `async` macros that are precise about the possible exceptions that
  can be raised.
- The pragma blocks `{.gcsafe.}: ...` and `{.noSideEffect.}: ...` can now also be
  written as `{.cast(gcsafe).}: ...` and `{.cast(noSideEffect).}: ...`. This is the new
  preferred way of writing these, emphasizing their unsafe nature.


## Compiler changes

- Specific warnings can now be turned into errors via `--warningAsError[X]:on|off`.
- The `define` and `undef` pragmas have been de-deprecated.
- New command: `nim r main.nim [args...]` which compiles and runs main.nim, and implies `--usenimcache`
  so that the output is saved to $nimcache/main$exeExt, using the same logic as `nim c -r` to
  avoid recompilations when sources don't change.
  Example:
  ```bash
  nim r compiler/nim.nim --help # only compiled the first time
  echo 'import os; echo getCurrentCompilerExe()' | nim r - # this works too
  nim r compiler/nim.nim --fullhelp # no recompilation
  nim r --nimcache:/tmp main # binary saved to /tmp/main
  ```
- `--hint:processing` is now supported and means `--hint:processing:on`
  (likewise with other hints and warnings), which is consistent with all other bool flags.
  (since 1.3.3).
- `nim doc -r main` and `nim rst2html -r main` now call `openDefaultBrowser`.
- Added the new hint `--hint:msgOrigin` will show where a compiler msg (hint|warning|error)
  was generated; this helps in particular when it's non obvious where it came from
  either because multiple locations generate the same message, or because the
  message involves runtime formatting.
- Added the new flag `--backend:js|c|cpp|objc` (or -b:js etc), to change the backend; can be
  used with any command (e.g. nim r, doc, check etc); safe to re-assign.
- Added the new flag `--doccmd:cmd` to pass additional flags for runnableExamples,
  e.g.: `--doccmd:-d:foo --threads`
  use `--doccmd:skip` to skip runnableExamples and rst test snippets.
- Added the new flag `--usenimcache` to output binary files to nimcache.
- `runnableExamples "-b:cpp -r:off": code` is now supported, allowing to override
  how an example is compiled and run, for example to change the backend.
- `nim doc` now outputs under `$projectPath/htmldocs` when `--outdir` is unspecified
  (with or without `--project`); passing `--project` now automatically generates
  an index and enables search.
  See [docgen](docgen.html#introduction-quick-start) for details.
- Removed the `--oldNewlines` switch.
- Removed the `--laxStrings` switch for mutating the internal zero terminator on strings.
- Removed the `--oldast` switch.
- Removed the `--oldgensym` switch.
- `$getType(untyped)` is now "untyped" instead of "expr", `$getType(typed)` is
  now "typed" instead of "stmt".
- Sink inference is now disabled per default and has to enabled explicitly via
  `--sinkInference:on`. *Note*: For the standard library sink inference remains
  enabled. This change is most relevant for the `--gc:arc`, `--gc:orc` memory
  management modes.


## Tool changes

- `nimsuggest` now returns both the forward declaration and the
  implementation location upon a `def` query. Previously the behavior was
  to return the forward declaration only.


## Bugfixes

- Fixed "repr() not available for uint{,8,16,32,64} under --gc:arc"
  ([#13872](https://github.com/nim-lang/Nim/issues/13872))
- Fixed "Critical: 1 completed Future, multiple await: Only 1 await will be awakened (the last one)"
  ([#13889](https://github.com/nim-lang/Nim/issues/13889))
- Fixed "crash on openarray interator with argument in stmtListExpr"
  ([#13739](https://github.com/nim-lang/Nim/issues/13739))
- Fixed "Some compilers on Windows don't work"
  ([#13910](https://github.com/nim-lang/Nim/issues/13910))
- Fixed "httpclient hangs if it recieves an HTTP 204 (No Content)"
  ([#13894](https://github.com/nim-lang/Nim/issues/13894))
- Fixed ""distinct uint64" type corruption on 32-bit, when using {.borrow.} operators"
  ([#13902](https://github.com/nim-lang/Nim/issues/13902))
- Fixed "Regression: impossible to use typed pragmas with proc types"
  ([#13909](https://github.com/nim-lang/Nim/issues/13909))
- Fixed "openssl wrapper corrupts stack on OpenSSL 1.1.1f + Android"
  ([#13903](https://github.com/nim-lang/Nim/issues/13903))
- Fixed "C compile error with --gc:arc on version 1.2.0 "unknown type name 'TGenericSeq'"
  ([#13863](https://github.com/nim-lang/Nim/issues/13863))
- Fixed "var return type for proc doesn't work at c++ backend"
  ([#13848](https://github.com/nim-lang/Nim/issues/13848))
- Fixed "TimeFormat() should raise an error but craches at compilation time"
  ([#12864](https://github.com/nim-lang/Nim/issues/12864))
- Fixed "gc:arc cannot fully support threadpool with FlowVar"
  ([#13781](https://github.com/nim-lang/Nim/issues/13781))
- Fixed "simple 'var openarray[char]' assignment crash when the openarray source is a local string and using gc:arc"
  ([#14003](https://github.com/nim-lang/Nim/issues/14003))
- Fixed "Cant use expressions with `when` in `type` sections."
  ([#14007](https://github.com/nim-lang/Nim/issues/14007))
- Fixed "`for a in MyEnum` gives incorrect results with enum with holes"
  ([#14001](https://github.com/nim-lang/Nim/issues/14001))
- Fixed "Trivial crash"
  ([#12741](https://github.com/nim-lang/Nim/issues/12741))
- Fixed "Enum with holes cannot be used as Table index"
  ([#12834](https://github.com/nim-lang/Nim/issues/12834))
- Fixed "spawn proc that uses typedesc crashes the compiler"
  ([#14014](https://github.com/nim-lang/Nim/issues/14014))
- Fixed "Docs Search `Results` box styling is not Dark Mode Friendly"
  ([#13972](https://github.com/nim-lang/Nim/issues/13972))
- Fixed "--gc:arc -d:useSysAssert undeclared identifier `cstderr` with newSeq"
  ([#14038](https://github.com/nim-lang/Nim/issues/14038))
- Fixed "issues in the manual"
  ([#12486](https://github.com/nim-lang/Nim/issues/12486))
- Fixed "Annoying warning: inherit from a more precise exception type like ValueError, IOError or OSError [InheritFromException]"
  ([#14052](https://github.com/nim-lang/Nim/issues/14052))
- Fixed "relativePath("foo", "/") and relativePath("/", "foo") is wrong"
  ([#13222](https://github.com/nim-lang/Nim/issues/13222))
- Fixed "[regression] `parseEnum` does not work anymore for enums with holes"
  ([#14030](https://github.com/nim-lang/Nim/issues/14030))
- Fixed "Exception types in the stdlib should inherit from `CatchableError` or `Defect`, not `Exception`"
  ([#10288](https://github.com/nim-lang/Nim/issues/10288))
- Fixed "Make debugSend and debugRecv procs public in smtp.nim"
  ([#12189](https://github.com/nim-lang/Nim/issues/12189))
- Fixed "xmltree need add raw text, when add style element"
  ([#14064](https://github.com/nim-lang/Nim/issues/14064))
- Fixed "raises requirement does not propagate to derived methods"
  ([#8481](https://github.com/nim-lang/Nim/issues/8481))
- Fixed "tests/stdlib/tgetaddrinfo.nim fails on NetBSD"
  ([#14091](https://github.com/nim-lang/Nim/issues/14091))
- Fixed "tests/niminaction/Chapter8/sdl/sdl_test.nim fails on NetBSD"
  ([#14088](https://github.com/nim-lang/Nim/issues/14088))
- Fixed "Incorrect escape sequence for example in jsffi library documentation"
  ([#14110](https://github.com/nim-lang/Nim/issues/14110))
- Fixed "HCR: Can not link exported const, in external library"
  ([#13915](https://github.com/nim-lang/Nim/issues/13915))
- Fixed "Cannot import std/unidecode"
  ([#14112](https://github.com/nim-lang/Nim/issues/14112))
- Fixed "macOS: dsymutil should not be called on static libraries"
  ([#14132](https://github.com/nim-lang/Nim/issues/14132))
- Fixed "nim jsondoc -o:doc.json filename.nim fails when sequences without a type are used"
  ([#14066](https://github.com/nim-lang/Nim/issues/14066))
- Fixed "algorithm.sortedByIt template corrupts tuple input under --gc:arc"
  ([#14079](https://github.com/nim-lang/Nim/issues/14079))
- Fixed "Invalid C code with lvalue conversion"
  ([#14160](https://github.com/nim-lang/Nim/issues/14160))
- Fixed "strformat: doc example fails"
  ([#14054](https://github.com/nim-lang/Nim/issues/14054))
- Fixed "Nim doc fail to run for nim 1.2.0 (nim 1.0.4 is ok)"
  ([#13986](https://github.com/nim-lang/Nim/issues/13986))
- Fixed "Exception when converting csize to clong"
  ([#13698](https://github.com/nim-lang/Nim/issues/13698))
- Fixed "[Documentation] overloading using named arguments works but is not documented"
  ([#11932](https://github.com/nim-lang/Nim/issues/11932))
- Fixed "import os + use of existsDir/dirExists/existsFile/fileExists/findExe in config.nims causes "ambiguous call' error"
  ([#14142](https://github.com/nim-lang/Nim/issues/14142))
- Fixed "import os + use of existsDir/dirExists/existsFile/fileExists/findExe in config.nims causes "ambiguous call' error"
  ([#14142](https://github.com/nim-lang/Nim/issues/14142))
- Fixed "runnableExamples doc gen crashes compiler with `except Exception as e` syntax"
  ([#14177](https://github.com/nim-lang/Nim/issues/14177))
- Fixed "[ARC] Segfault with cyclic references (?)"
  ([#14159](https://github.com/nim-lang/Nim/issues/14159))
- Fixed "Semcheck regression when accessing a static parameter in proc"
  ([#14136](https://github.com/nim-lang/Nim/issues/14136))
- Fixed "iterator walkDir doesn't work with -d:useWinAnsi"
  ([#14201](https://github.com/nim-lang/Nim/issues/14201))
- Fixed "cas is wrong for tcc"
  ([#14151](https://github.com/nim-lang/Nim/issues/14151))
- Fixed "proc execCmdEx doesn't work with -d:useWinAnsi"
  ([#14203](https://github.com/nim-lang/Nim/issues/14203))
- Fixed "Use -d:nimEmulateOverflowChecks by default?"
  ([#14209](https://github.com/nim-lang/Nim/issues/14209))
- Fixed "Old sequences with destructor objects bug"
  ([#14217](https://github.com/nim-lang/Nim/issues/14217))
- Fixed "[ARC] ICE when changing the discriminant of a return value"
  ([#14244](https://github.com/nim-lang/Nim/issues/14244))
- Fixed "[ARC] ICE with static objects"
  ([#14236](https://github.com/nim-lang/Nim/issues/14236))
- Fixed "[ARC] "internal error: environment misses: a" in a finalizer"
  ([#14243](https://github.com/nim-lang/Nim/issues/14243))
- Fixed "[ARC] compile failure using repr with object containing `ref seq[string]`"
  ([#14270](https://github.com/nim-lang/Nim/issues/14270))
- Fixed "[ARC] implicit move on last use happening on non-last use"
  ([#14269](https://github.com/nim-lang/Nim/issues/14269))
- Fixed "[ARC] Compiler crash with a recursive non-ref object variant"
  ([#14294](https://github.com/nim-lang/Nim/issues/14294))
- Fixed "htmlparser.parseHtml behaves differently using --gc:arc or --gc:orc"
  ([#13946](https://github.com/nim-lang/Nim/issues/13946))
- Fixed "Invalid return value of openProcess is NULL rather than INVALID_HANDLE_VALUE(-1) in windows"
  ([#14289](https://github.com/nim-lang/Nim/issues/14289))
- Fixed "ARC codegen bug with inline iterators"
  ([#14219](https://github.com/nim-lang/Nim/issues/14219))
- Fixed "Building koch on OpenBSD fails unless the Nim directory is in `$PATH`"
  ([#13758](https://github.com/nim-lang/Nim/issues/13758))
- Fixed "[gc:arc] case object assignment SIGSEGV: destroy not called for primitive type "
  ([#14312](https://github.com/nim-lang/Nim/issues/14312))
- Fixed "Crash when using thread and --gc:arc "
  ([#13881](https://github.com/nim-lang/Nim/issues/13881))
- Fixed "Getting "Warning: Cannot prove that 'result' is initialized" for an importcpp'd proc with `var T` return type"
  ([#14314](https://github.com/nim-lang/Nim/issues/14314))
- Fixed "`nim cpp -r --gc:arc` segfaults on caught AssertionError"
  ([#13071](https://github.com/nim-lang/Nim/issues/13071))
- Fixed "tests/async/tasyncawait.nim is recently very flaky"
  ([#14320](https://github.com/nim-lang/Nim/issues/14320))
- Fixed "Documentation nonexistent quitprocs module"
  ([#14331](https://github.com/nim-lang/Nim/issues/14331))
- Fixed "SIGSEV encountered when creating threads in a loop w/ --gc:arc"
  ([#13935](https://github.com/nim-lang/Nim/issues/13935))
- Fixed "nim-gdb is missing from all released packages"
  ([#13104](https://github.com/nim-lang/Nim/issues/13104))
- Fixed "sysAssert error with gc:arc on 3 line program"
  ([#13862](https://github.com/nim-lang/Nim/issues/13862))
- Fixed "compiler error with inline async proc and pragma"
  ([#13998](https://github.com/nim-lang/Nim/issues/13998))
- Fixed "[ARC] Compiler crash when adding to a seq[ref Object]"
  ([#14333](https://github.com/nim-lang/Nim/issues/14333))
- Fixed "nimvm: sysFatal: unhandled exception: 'sons' is not accessible using discriminant 'kind' of type 'TNode' [FieldError]"
  ([#14340](https://github.com/nim-lang/Nim/issues/14340))
- Fixed "[Regression] karax events are not firing "
  ([#14350](https://github.com/nim-lang/Nim/issues/14350))
- Fixed "odbcsql module has some wrong integer types"
  ([#9771](https://github.com/nim-lang/Nim/issues/9771))
- Fixed "db_sqlite needs sqlPrepared"
  ([#13559](https://github.com/nim-lang/Nim/issues/13559))
- Fixed "[Regression] `createThread` is not GC-safe"
  ([#14370](https://github.com/nim-lang/Nim/issues/14370))
- Fixed "Broken example on hot code reloading"
  ([#14380](https://github.com/nim-lang/Nim/issues/14380))
- Fixed "runnableExamples block with `except` on specified error fails with `nim doc`"
  ([#12746](https://github.com/nim-lang/Nim/issues/12746))
- Fixed "compiler as a library: findNimStdLibCompileTime fails to find system.nim"
  ([#12293](https://github.com/nim-lang/Nim/issues/12293))
- Fixed "5 bugs with importcpp exceptions"
  ([#14369](https://github.com/nim-lang/Nim/issues/14369))
- Fixed "Docs shouldn't collapse pragmas inside runnableExamples/code blocks"
  ([#14174](https://github.com/nim-lang/Nim/issues/14174))
- Fixed "Bad codegen/emit for hashes.hiXorLo in some contexts."
  ([#14394](https://github.com/nim-lang/Nim/issues/14394))
- Fixed "Boehm GC does not scan thread-local storage"
  ([#14364](https://github.com/nim-lang/Nim/issues/14364))
- Fixed "RVO not exception safe"
  ([#14126](https://github.com/nim-lang/Nim/issues/14126))
- Fixed "runnableExamples that are only compiled"
  ([#10731](https://github.com/nim-lang/Nim/issues/10731))
- Fixed "`foldr` raises IndexError when called on sequence"
  ([#14404](https://github.com/nim-lang/Nim/issues/14404))
- Fixed "moveFile does not overwrite destination file"
  ([#14057](https://github.com/nim-lang/Nim/issues/14057))
- Fixed "doc2 outputs in current work dir"
  ([#6583](https://github.com/nim-lang/Nim/issues/6583))
- Fixed "[docgen] proc doc comments silently omitted after 1st runnableExamples"
  ([#9227](https://github.com/nim-lang/Nim/issues/9227))
- Fixed "`nim doc --project` shows '@@/' instead of '../' for relative paths to submodules"
  ([#14448](https://github.com/nim-lang/Nim/issues/14448))
- Fixed "re, nre have wrong `start` semantics"
  ([#14284](https://github.com/nim-lang/Nim/issues/14284))
- Fixed "runnableExamples should preserve source code doc comments, strings, and (maybe) formatting"
  ([#8871](https://github.com/nim-lang/Nim/issues/8871))
- Fixed "`nim doc ..` fails when runnableExamples uses `$`  [devel] [regression]"
  ([#14485](https://github.com/nim-lang/Nim/issues/14485))
- Fixed "`items` is 20%~30% slower than iteration via an index"
  ([#14421](https://github.com/nim-lang/Nim/issues/14421))
- Fixed "ARC: unreliable setLen "
  ([#14495](https://github.com/nim-lang/Nim/issues/14495))
- Fixed "lent is unsafe: after #14447 you can modify variables with "items" loop for sequences"
  ([#14498](https://github.com/nim-lang/Nim/issues/14498))
- Fixed "`var op = fn()` wrongly gives warning `ObservableStores` with `object of RootObj` type"
  ([#14514](https://github.com/nim-lang/Nim/issues/14514))
- Fixed "Compiler assertion"
  ([#14562](https://github.com/nim-lang/Nim/issues/14562))
- Fixed "Can't get `ord` of a value of a Range type in the JS backend "
  ([#14570](https://github.com/nim-lang/Nim/issues/14570))
- Fixed "js: can't take addr of param (including implicitly via `lent`)"
  ([#14576](https://github.com/nim-lang/Nim/issues/14576))
- Fixed "{.noinit.} ignored in for loop -> bad codegen for non-movable types"
  ([#14118](https://github.com/nim-lang/Nim/issues/14118))
- Fixed "generic destructor gives: `Error: unresolved generic parameter`"
  ([#14315](https://github.com/nim-lang/Nim/issues/14315))
- Fixed "Memory leak with arc gc"
  ([#14568](https://github.com/nim-lang/Nim/issues/14568))
- Fixed "escape analysis broken with `lent`"
  ([#14557](https://github.com/nim-lang/Nim/issues/14557))
- Fixed "`wrapWords` seems to ignore linebreaks when wrapping, leaving breaks in the wrong place"
  ([#14579](https://github.com/nim-lang/Nim/issues/14579))
- Fixed "`lent` gives wrong results with -d:release"
  ([#14578](https://github.com/nim-lang/Nim/issues/14578))
- Fixed "Nested await expressions regression: `await a(await expandValue())` doesnt compile"
  ([#14279](https://github.com/nim-lang/Nim/issues/14279))
- Fixed "windows CI docs fails with strange errors"
  ([#14545](https://github.com/nim-lang/Nim/issues/14545))
- Fixed "[CI] tests/async/tioselectors.nim flaky test for freebsd + OSX CI"
  ([#13166](https://github.com/nim-lang/Nim/issues/13166))
- Fixed "seq.setLen sometimes doesn't zero memory"
  ([#14655](https://github.com/nim-lang/Nim/issues/14655))
- Fixed "`nim dump` is roughly 100x slower in 1.3 versus 1.2"
  ([#14179](https://github.com/nim-lang/Nim/issues/14179))
- Fixed "Regression: devel docgen cannot generate document for method"
  ([#14691](https://github.com/nim-lang/Nim/issues/14691))
- Fixed "recently flaky tests/async/t7758.nim"
  ([#14685](https://github.com/nim-lang/Nim/issues/14685))
- Fixed "Bind no longer working in generic procs."
  ([#11811](https://github.com/nim-lang/Nim/issues/11811))
- Fixed "The pegs module doesn't work with generics!"
  ([#14718](https://github.com/nim-lang/Nim/issues/14718))
- Fixed "Defer is not properly working for asynchronous procedures."
  ([#13899](https://github.com/nim-lang/Nim/issues/13899))
- Fixed "Add an ARC test with threads in a loop"
  ([#14690](https://github.com/nim-lang/Nim/issues/14690))
- Fixed "[goto exceptions] {.noReturn.} pragma is not detected in a case expression"
  ([#14458](https://github.com/nim-lang/Nim/issues/14458))
- Fixed "[exceptions:goto] C compiler error with dynlib pragma calling a proc"
  ([#14240](https://github.com/nim-lang/Nim/issues/14240))
- Fixed "Cannot borrow var float64 in infix assignment"
  ([#14440](https://github.com/nim-lang/Nim/issues/14440))
- Fixed "lib/pure/memfiles.nim: compilation error with --taintMode:on"
  ([#14760](https://github.com/nim-lang/Nim/issues/14760))
- Fixed "newWideCString allocates a multiple of the memory needed"
  ([#14750](https://github.com/nim-lang/Nim/issues/14750))
- Fixed "Nim source archive install: 'install.sh' fails with error: cp: cannot stat 'bin/nim-gdb': No such file or directory"
  ([#14748](https://github.com/nim-lang/Nim/issues/14748))
- Fixed "`nim cpp -r tests/exception/t9657` hangs"
  ([#10343](https://github.com/nim-lang/Nim/issues/10343))
- Fixed "Detect tool fails on FreeBSD"
  ([#14715](https://github.com/nim-lang/Nim/issues/14715))
- Fixed "compiler crash: `findUnresolvedStatic` "
  ([#14802](https://github.com/nim-lang/Nim/issues/14802))
- Fixed "seq namespace (?) regression"
  ([#4796](https://github.com/nim-lang/Nim/issues/4796))
- Fixed "Possible out of bounds string access in std/colors parseColor and isColor"
  ([#14839](https://github.com/nim-lang/Nim/issues/14839))
- Fixed "compile error on latest devel with orc and ssl"
  ([#14647](https://github.com/nim-lang/Nim/issues/14647))
- Fixed "[minor] `$` wrong for type tuple"
  ([#13432](https://github.com/nim-lang/Nim/issues/13432))
- Fixed "Documentation missing on devel asyncftpclient"
  ([#14846](https://github.com/nim-lang/Nim/issues/14846))
- Fixed "nimpretty is confused with a trailing comma in enum definition"
  ([#14401](https://github.com/nim-lang/Nim/issues/14401))
- Fixed "Output arguments get ignored when compiling with --app:staticlib"
  ([#12745](https://github.com/nim-lang/Nim/issues/12745))
- Fixed "[ARC] destructive move destroys the object too early"
  ([#14396](https://github.com/nim-lang/Nim/issues/14396))
- Fixed "highlite.getNextToken() crashes if the buffer string is "echo "\"""
  ([#14830](https://github.com/nim-lang/Nim/issues/14830))
- Fixed "Memory corruption with --gc:arc with a seq of objects with an empty body."
  ([#14472](https://github.com/nim-lang/Nim/issues/14472))
- Fixed "Stropped identifiers don't work as field names in tuple literals"
  ([#14911](https://github.com/nim-lang/Nim/issues/14911))
- Fixed "Please revert my commit"
  ([#14930](https://github.com/nim-lang/Nim/issues/14930))
- Fixed "[ARC] C compiler error with inline iterators and imports"
  ([#14864](https://github.com/nim-lang/Nim/issues/14864))
- Fixed "AsyncHttpClient segfaults with gc:orc, possibly memory corruption"
  ([#14402](https://github.com/nim-lang/Nim/issues/14402))
- Fixed "[ARC] Template with a block evaluating to a GC'd value results in a compiler crash"
  ([#14899](https://github.com/nim-lang/Nim/issues/14899))
- Fixed "[ARC] Weird issue with if expressions and templates"
  ([#14900](https://github.com/nim-lang/Nim/issues/14900))
- Fixed "xmlparser does not compile on devel"
  ([#14805](https://github.com/nim-lang/Nim/issues/14805))
- Fixed "returning lent T from a var T param gives codegen errors or SIGSEGV"
  ([#14878](https://github.com/nim-lang/Nim/issues/14878))
- Fixed "[ARC] Weird issue with if expressions and templates"
  ([#14900](https://github.com/nim-lang/Nim/issues/14900))
- Fixed "threads:on + gc:orc + unittest = C compiler errors"
  ([#14865](https://github.com/nim-lang/Nim/issues/14865))
- Fixed "mitems, mpairs doesn't work at compile time anymore"
  ([#12129](https://github.com/nim-lang/Nim/issues/12129))
- Fixed "strange result from executing code in const expression"
  ([#10465](https://github.com/nim-lang/Nim/issues/10465))
- Fixed "Same warning printed 3 times"
  ([#11009](https://github.com/nim-lang/Nim/issues/11009))
- Fixed "type alias for generic typeclass doesn't work"
  ([#4668](https://github.com/nim-lang/Nim/issues/4668))
- Fixed "exceptions:goto Bug devel codegen lvalue NIM_FALSE=NIM_FALSE"
  ([#14925](https://github.com/nim-lang/Nim/issues/14925))
- Fixed "the --useVersion:1.0 no longer works in devel"
  ([#14912](https://github.com/nim-lang/Nim/issues/14912))
- Fixed "template declaration of iterator doesn't compile"
  ([#4722](https://github.com/nim-lang/Nim/issues/4722))
- Fixed "Compiler crash on type inheritance with static generic parameter and equality check"
  ([#12571](https://github.com/nim-lang/Nim/issues/12571))
- Fixed "Nim crashes while handling a cast in async circumstances."
  ([#13815](https://github.com/nim-lang/Nim/issues/13815))
- Fixed "[ARC] Internal compiler error when calling an iterator from an inline proc "
  ([#14383](https://github.com/nim-lang/Nim/issues/14383))
- Fixed ""Cannot instantiate" error when template uses generic type"
  ([#5926](https://github.com/nim-lang/Nim/issues/5926))
- Fixed "Different raises behaviour for newTerminal between Linux and Windows"
  ([#12759](https://github.com/nim-lang/Nim/issues/12759))
- Fixed "Expand on a type (that defines a proc type) in error message "
  ([#6608](https://github.com/nim-lang/Nim/issues/6608))
- Fixed "unittest require quits program with an exit code of 0"
  ([#14475](https://github.com/nim-lang/Nim/issues/14475))
- Fixed "Range type: Generics vs concrete type, semcheck difference."
  ([#8426](https://github.com/nim-lang/Nim/issues/8426))
- Fixed "[Macro] Type mismatch when parameter name is the same as a field"
  ([#13253](https://github.com/nim-lang/Nim/issues/13253))
- Fixed "Generic instantiation failure when converting a sequence of circular generic types to strings"
  ([#10396](https://github.com/nim-lang/Nim/issues/10396))
- Fixed "initOptParser ignores argument after value option with empty value."
  ([#13086](https://github.com/nim-lang/Nim/issues/13086))
- Fixed "[ARC] proc with both explicit and implicit return results in a C compiler error"
  ([#14985](https://github.com/nim-lang/Nim/issues/14985))
- Fixed "Alias type forgets implicit generic params depending on order"
  ([#14990](https://github.com/nim-lang/Nim/issues/14990))
- Fixed "[ARC] sequtils.insert has different behaviour between ARC/refc"
  ([#14994](https://github.com/nim-lang/Nim/issues/14994))
- Fixed "The documentation for "hot code reloading" references a non-existent npm package"
  ([#13621](https://github.com/nim-lang/Nim/issues/13621))
- Fixed "existsDir deprecated but breaking `dir` undeclared"
  ([#15006](https://github.com/nim-lang/Nim/issues/15006))
- Fixed "uri.decodeUrl crashes on incorrectly formatted input"
  ([#14082](https://github.com/nim-lang/Nim/issues/14082))
- Fixed "testament incorrectly reports time for tests, leading to wrong conclusions"
  ([#14822](https://github.com/nim-lang/Nim/issues/14822))
- Fixed "Calling peekChar with Stream returned from osproc.outputStream generate runtime error"
  ([#14906](https://github.com/nim-lang/Nim/issues/14906))
- Fixed "localPassC pragma should come *after* other flags"
  ([#14194](https://github.com/nim-lang/Nim/issues/14194))
- Fixed ""Could not load" dynamic library at runtime because of hidden dependency"
  ([#2408](https://github.com/nim-lang/Nim/issues/2408))
- Fixed "--gc:arc generate invalid code for {.global.} (`«nimErr_» in NIM_UNLIKELY`)"
  ([#14480](https://github.com/nim-lang/Nim/issues/14480))
- Fixed "Using `^` from stdlib/math along with converters gives a match for types that aren't SomeNumber"
  ([#15033](https://github.com/nim-lang/Nim/issues/15033))
- Fixed "[ARC] Weird exception behaviour from doAssertRaises"
  ([#15026](https://github.com/nim-lang/Nim/issues/15026))
- Fixed "[ARC] Compiler crash declaring a finalizer proc directly in 'new'"
  ([#15044](https://github.com/nim-lang/Nim/issues/15044))
- Fixed "[ARC] C compiler error when creating a var of a const seq"
  ([#15036](https://github.com/nim-lang/Nim/issues/15036))
- Fixed "code with named arguments in proc of winim/com can not been compiled"
  ([#15056](https://github.com/nim-lang/Nim/issues/15056))
- Fixed "javascript backend produces javascript code with syntax error in object syntax"
  ([#14534](https://github.com/nim-lang/Nim/issues/14534))
- Fixed "--gc:arc should be ignored in JS mode."
  ([#14684](https://github.com/nim-lang/Nim/issues/14684))
- Fixed "arc: C compilation error with imported global code using a closure iterator"
  ([#12990](https://github.com/nim-lang/Nim/issues/12990))
- Fixed "[ARC] Crash when modifying a string with mitems iterator"
  ([#15052](https://github.com/nim-lang/Nim/issues/15052))
- Fixed "[ARC] SIGSEGV when calling a closure as a tuple field in a seq"
  ([#15038](https://github.com/nim-lang/Nim/issues/15038))
- Fixed "pass varargs[seq[T]] to iterator give empty seq "
  ([#12576](https://github.com/nim-lang/Nim/issues/12576))
- Fixed "Compiler crashes when using string as object variant selector with else branch"
  ([#14189](https://github.com/nim-lang/Nim/issues/14189))
- Fixed "JS compiler error related to implicit return and return var type"
  ([#11354](https://github.com/nim-lang/Nim/issues/11354))
- Fixed "`nkRecWhen` causes internalAssert in semConstructFields"
  ([#14698](https://github.com/nim-lang/Nim/issues/14698))
- Fixed "Memory leaks with async (closure iterators?) under ORC"
  ([#15076](https://github.com/nim-lang/Nim/issues/15076))
- Fixed "strutil.insertSep() fails on negative numbers"
  ([#11352](https://github.com/nim-lang/Nim/issues/11352))
- Fixed "Constructing a uint64 range on a 32-bit machine leads to incorrect codegen"
  ([#14616](https://github.com/nim-lang/Nim/issues/14616))
- Fixed "heapqueue pushpop() proc doesn't compile"
  ([#14139](https://github.com/nim-lang/Nim/issues/14139))
- Fixed "[ARC] SIGSEGV when trying to swap in a literal/const string"
  ([#15112](https://github.com/nim-lang/Nim/issues/15112))
- Fixed "Defer and --gc:arc"
  ([#15071](https://github.com/nim-lang/Nim/issues/15071))
- Fixed "internal error: compiler/semobjconstr.nim(324, 20) example"
  ([#15111](https://github.com/nim-lang/Nim/issues/15111))
- Fixed "[ARC] Sequence "disappears" with a table inside of a table with an object variant"
  ([#15122](https://github.com/nim-lang/Nim/issues/15122))
- Fixed "[ARC] SIGSEGV with tuple assignment caused by cursor inference"
  ([#15130](https://github.com/nim-lang/Nim/issues/15130))
- Fixed "Issue with --gc:arc at compile time"
  ([#15129](https://github.com/nim-lang/Nim/issues/15129))
- Fixed "Writing an empty string to an AsyncFile raises an IndexDefect"
  ([#15148](https://github.com/nim-lang/Nim/issues/15148))
- Fixed "Compiler is confused about call convention of function with nested closure"
  ([#5688](https://github.com/nim-lang/Nim/issues/5688))
- Fixed "Nil check on each field fails in generic function"
  ([#15101](https://github.com/nim-lang/Nim/issues/15101))
- Fixed "{.nimcall.} convention won't avoid the creation of closures"
  ([#8473](https://github.com/nim-lang/Nim/issues/8473))
- Fixed "smtp.nim(161, 40) Error: type mismatch: got <typeof(nil)> but expected 'SslContext = void'"
  ([#15177](https://github.com/nim-lang/Nim/issues/15177))
- Fixed "[strscans] scanf doesn't match a single character with $+ if it's the end of the string"
  ([#15064](https://github.com/nim-lang/Nim/issues/15064))
- Fixed "Crash and incorrect return values when using readPasswordFromStdin on Windows."
  ([#15207](https://github.com/nim-lang/Nim/issues/15207))
- Fixed "Possible capture error with fieldPairs and genericParams"
  ([#15221](https://github.com/nim-lang/Nim/issues/15221))
- Fixed "The StmtList processing of template parameters can lead to unexpected errors"
  ([#5691](https://github.com/nim-lang/Nim/issues/5691))
- Fixed "[ARC] C compiler error when passing a var openArray to a sink openArray"
  ([#15035](https://github.com/nim-lang/Nim/issues/15035))
- Fixed "Inconsistent unsigned -> signed RangeDefect usage across integer sizes"
  ([#15210](https://github.com/nim-lang/Nim/issues/15210))
- Fixed "toHex results in RangeDefect exception when used with large uint64"
  ([#15257](https://github.com/nim-lang/Nim/issues/15257))
- Fixed "Arc sink arg crash"
  ([#15238](https://github.com/nim-lang/Nim/issues/15238))
- Fixed "SQL escape in db_mysql is not enough"
  ([#15219](https://github.com/nim-lang/Nim/issues/15219))
- Fixed "Mixing 'return' with expressions is allowed in 1.2"
  ([#15280](https://github.com/nim-lang/Nim/issues/15280))
- Fixed "os.getFileInfo() causes ICE with --gc:arc on Windows"
  ([#15286](https://github.com/nim-lang/Nim/issues/15286))
- Fixed "[ARC] Sequence "disappears" with a table inside of a table with an object variant"
  ([#15122](https://github.com/nim-lang/Nim/issues/15122))
- Fixed "Documentation regression jsre module missing"
  ([#15183](https://github.com/nim-lang/Nim/issues/15183))
- Fixed "CountTable.smallest/largest() on empty table either asserts or gives bogus answer"
  ([#15021](https://github.com/nim-lang/Nim/issues/15021))
- Fixed "[Regression] Parser regression"
  ([#15305](https://github.com/nim-lang/Nim/issues/15305))
- Fixed "[ARC] SIGSEGV with tuple unpacking caused by cursor inference"
  ([#15147](https://github.com/nim-lang/Nim/issues/15147))
- Fixed "LwIP/FreeRTOS compile error - missing SIGPIPE and more "
  ([#15302](https://github.com/nim-lang/Nim/issues/15302))
- Fixed "Memory leaks with async (closure iterators?) under ORC"
  ([#15076](https://github.com/nim-lang/Nim/issues/15076))
- Fixed "Bug compiling with --gc:arg or --gc:orc"
  ([#15325](https://github.com/nim-lang/Nim/issues/15325))
- Fixed "memory corruption in tmarshall.nim"
  ([#9754](https://github.com/nim-lang/Nim/issues/9754))
- Fixed "typed macros break generic proc definitions"
  ([#15326](https://github.com/nim-lang/Nim/issues/15326))
- Fixed "nim doc2 ignores --docSeeSrcUrl parameter"
  ([#6071](https://github.com/nim-lang/Nim/issues/6071))
- Fixed "The decodeData Iterator from cgi module crash"
  ([#15369](https://github.com/nim-lang/Nim/issues/15369))
- Fixed "|| iterator generates invalid code when compiling with --debugger:native"
  ([#9710](https://github.com/nim-lang/Nim/issues/9710))
- Fixed "Wrong number of variables"
  ([#15360](https://github.com/nim-lang/Nim/issues/15360))
- Fixed "Coercions with distinct types should traverse pointer modifiers transparently."
  ([#7165](https://github.com/nim-lang/Nim/issues/7165))
- Fixed "Error with distinct generic TableRef"
  ([#6060](https://github.com/nim-lang/Nim/issues/6060))
- Fixed "Support images in nim docgen"
  ([#6430](https://github.com/nim-lang/Nim/issues/6430))
- Fixed "Regression. Double sem check for procs."
  ([#15389](https://github.com/nim-lang/Nim/issues/15389))
- Fixed "uri.nim url with literal ipv6 address is printed wrong, and cannot parsed again"
  ([#15333](https://github.com/nim-lang/Nim/issues/15333))
- Fixed "[ARC] Object variant gets corrupted with cursor inference"
  ([#15361](https://github.com/nim-lang/Nim/issues/15361))
- Fixed "`nim doc ..` compiler crash (regression 0.19.6 => 1.0)"
  ([#14474](https://github.com/nim-lang/Nim/issues/14474))
- Fixed "cannot borrow result; what it borrows from is potentially mutated"
  ([#15403](https://github.com/nim-lang/Nim/issues/15403))
- Fixed "memory corruption for seq.add(seq) with gc:arc and d:useMalloc "
  ([#14983](https://github.com/nim-lang/Nim/issues/14983))
- Fixed "DocGen HTML output appears improperly when encountering text immediately after/before inline monospace; in some cases won't compile"
  ([#11537](https://github.com/nim-lang/Nim/issues/11537))
- Fixed "Deepcopy in arc crashes"
  ([#15405](https://github.com/nim-lang/Nim/issues/15405))
- Fixed "pop pragma takes invalid input"
  ([#15430](https://github.com/nim-lang/Nim/issues/15430))
- Fixed "tests/stdlib/tgetprotobyname fails on NetBSD"
  ([#15452](https://github.com/nim-lang/Nim/issues/15452))
- Fixed "defer doesnt work with block, break and await"
  ([#15243](https://github.com/nim-lang/Nim/issues/15243))
- Fixed "tests/stdlib/tssl failing on NetBSD"
  ([#15493](https://github.com/nim-lang/Nim/issues/15493))
- Fixed "strictFuncs doesn't seem to catch simple ref mutation"
  ([#15508](https://github.com/nim-lang/Nim/issues/15508))
- Fixed "Sizeof of case object is incorrect. Showstopper"
  ([#15516](https://github.com/nim-lang/Nim/issues/15516))
- Fixed "[ARC] Internal error when trying to use a parallel for loop"
  ([#15512](https://github.com/nim-lang/Nim/issues/15512))
- Fixed "[ARC] Type-bound assign op is not being generated"
  ([#15510](https://github.com/nim-lang/Nim/issues/15510))
- Fixed "[ARC] Crash when adding openArray proc argument to a local seq"
  ([#15511](https://github.com/nim-lang/Nim/issues/15511))
- Fixed "VM: const case object gets some fields zeroed out at runtime"
  ([#13081](https://github.com/nim-lang/Nim/issues/13081))
- Fixed "regression(1.2.6 => devel): VM: const case object field access gives: 'sons' is not accessible"
  ([#15532](https://github.com/nim-lang/Nim/issues/15532))
- Fixed "Csources: huge size increase (x2.3) in 0.20"
  ([#12027](https://github.com/nim-lang/Nim/issues/12027))
- Fixed "Out of date error message for GC options"
  ([#15547](https://github.com/nim-lang/Nim/issues/15547))
- Fixed "dbQuote additional escape regression"
  ([#15560](https://github.com/nim-lang/Nim/issues/15560))
