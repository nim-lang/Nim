# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes

- Added `bindParams`, `bindParam` to `db_sqlite` for binding parameters into a `SqlPrepared` statement.
- Add `tryInsert`,`insert` procs to db_* libs accept primary key column name.
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

  For a transistion period, define `nimInheritHandles` to enable file handle
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

## Language changes
- In the newruntime it is now allowed to assign discriminator field without restrictions as long as case object doesn't have custom destructor. Discriminator value doesn't have to be a constant either. If you have custom destructor for case object and you do want to freely assign discriminator fields, it is recommended to refactor object into 2 objects like this:

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
- getImpl() on enum type symbols now returns field syms instead of idents. This helps
  with writing typed macros. Old behavior for backwards compatiblity can be restored
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

- Added `thiscall` calling convention as specified by Microsoft, mostly for hooking purpose

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
- new hint: `--hint:msgOrigin` will show where a compiler msg (hint|warning|error) was generated; this
  helps in particular when it's non obvious where it came from either because multiple locations generate
  the same message, or because the message involves runtime formatting.
- new flag `--backend:js|c|cpp|objc (or -b:js etc), to change backend; can be used with any command
  (eg nim r, doc, check etc); safe to re-assign.
- new flag `--doccmd:cmd` to pass additional flags for runnableExamples, eg: `--doccmd:-d:foo --threads`
  use `--doccmd:skip` to skip runnableExamples and rst test snippets.
- new flag `--usenimcache` to output to nimcache (whatever it resolves to after all commands are processed)
  and avoids polluting both $pwd and $projectdir. It can be used with any command.
- `runnableExamples "-b:cpp -r:off": code` is now supported, allowing to override how an example is compiled and run,
  for example to change backend or compile only.
- `nim doc` now outputs under `$projectPath/htmldocs` when `--outdir` is unspecified (with or without `--project`);
  passing `--project` now automatically generates an index and enables search.
  See [docgen](docgen.html#introduction-quick-start) for details.

## Tool changes
