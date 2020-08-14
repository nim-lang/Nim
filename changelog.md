# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes

- Added `bindParams`, `bindParam` to `db_sqlite` for binding parameters into a `SqlPrepared` statement.
- Add `tryInsert`,`insert` procs to `db_*` libs accept primary key column name.
- Added `xmltree.newVerbatimText` support create `style`'s,`script`'s text.
- `uri` adds Data URI Base64, implements RFC-2397.
- Add [DOM Parser](https://developer.mozilla.org/en-US/docs/Web/API/DOMParser)
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
  `nativesockets.setInheritable` is also introduced for setting file handle or
  socket inheritance. Not all platform have these `proc`s defined.

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

- Export `asyncdispatch.PDispatcher.handles` so that an external library can register them.

- Added `deques.toDeque`, which creates a deque from an openArray. The usage is
  similar to procs such as `sets.toHashSet` and `tables.toTable`. Previously,
  it was necessary to create an empty deque and add items manually.
  
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

## Language changes
- The `=destroy` hook no longer has to reset its target, as the compiler now automatically inserts
  `wasMoved` calls where needed.
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
- `getImpl` on enum type symbols now returns field syms instead of idents. This helps
  with writing typed macros. Old behavior for backwards compatibility can be restored
  with command line switch `--useVersion:1.0`.
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

- Added the `thiscall` calling convention as specified by Microsoft, mostly for hooking purpose
- Deprecated `{.unroll.}` pragma, was ignored by the compiler anyways, was a nop.
- Remove `strutils.isNilOrWhitespace`, was deprecated.
- Remove `sharedtables.initSharedTable`, was deprecated and produces undefined behavior.
- Removed `asyncdispatch.newAsyncNativeSocket`, was deprecated since `0.18`.
- Remove `dom.releaseEvents` and `dom.captureEvents`, was deprecated.

- Remove `sharedlists.initSharedList`, was deprecated and produces undefined behaviour.

- There is a new experimental feature called "strictFuncs" which makes the definition of
  `.noSideEffect` stricter. [See](manual_experimental.html#stricts-funcs)
  for more information.


## Compiler changes

- Specific warnings can now be turned into errors via `--warningAsError[X]:on|off`.
- The `define` and `undef` pragmas have been de-deprecated.
- New command: `nim r main.nim [args...]` which compiles and runs main.nim, and implies `--usenimcache`
  so that output is saved to $nimcache/main$exeExt, using the same logic as `nim c -r` to
  avoid recompiling when sources don't change. This is now the preferred way to
  run tests, avoiding the usual pain of clobbering your repo with binaries or
  using tricky gitignore rules on posix. Example:
  ```nim
  nim r compiler/nim.nim --help # only compiled the first time
  echo 'import os; echo getCurrentCompilerExe()' | nim r - # this works too
  nim r compiler/nim.nim --fullhelp # no recompilation
  nim r --nimcache:/tmp main # binary saved to /tmp/main
  ```
- `--hint:processing` is now supported and means `--hint:processing:on`
  (likewise with other hints and warnings), which is consistent with all other bool flags.
  (since 1.3.3).
- `nim doc -r main` and `nim rst2html -r main` now call openDefaultBrowser
- new hint: `--hint:msgOrigin` will show where a compiler msg (hint|warning|error)
  was generated; this helps in particular when it's non obvious where it came from
  either because multiple locations generate the same message, or because the
  message involves runtime formatting.
- new flag `--backend:js|c|cpp|objc` (or -b:js etc), to change backend; can be
  used with any command (eg nim r, doc, check etc); safe to re-assign.
- new flag `--doccmd:cmd` to pass additional flags for runnableExamples,
  e.g.: `--doccmd:-d:foo --threads`
  use `--doccmd:skip` to skip runnableExamples and rst test snippets.
- new flag `--usenimcache` to output to nimcache (whatever it resolves to after
  all commands are processed)
  and avoids polluting both $pwd and $projectdir. It can be used with any command.
- `runnableExamples "-b:cpp -r:off": code` is now supported, allowing to override
  how an example is compiled and run, for example to change backend or compile only.
- `nim doc` now outputs under `$projectPath/htmldocs` when `--outdir` is unspecified
  (with or without `--project`); passing `--project` now automatically generates
  an index and enables search.
  See [docgen](docgen.html#introduction-quick-start) for details.
- Removed the `--oldNewlines` switch.
- Removed the `--laxStrings` switch for mutating the internal zero terminator on strings.
- Removed the `--oldast` switch.
- Removed the `--oldgensym` switch
- `$getType(untyped)` is now "untyped" instead of "expr", `$getType(typed)` is
  now "typed" instead of "stmt".
- Sink inference is now disabled per default and has to enabled explicitly via
  `--sinkInference:on`. *Note*: For the standard library sink inference remains
  enabled. This change is most relevant for the `--gc:arc`, `--gc:orc` memory
  management modes.


## Tool changes
