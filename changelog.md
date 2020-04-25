# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes
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
  `system`, `nativesockets`, `net` and `selectors`.

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

- `critbits` adds `commonPrefixLen`.
- `relativePath(rel, abs)` and `relativePath(abs, rel)` used to silently give wrong results
  (see #13222); instead they now use `getCurrentDir` to resolve those cases,
  and this can now throw in edge cases where `getCurrentDir` throws.
  `relativePath` also now works for js with `-d:nodejs`.

- Added `streams.readStr` and `streams.peekStr` overloads to
  accept an existing string to modify, which avoids memory
  allocations, similar to `streams.readLine` (#13857).

## Language changes
- In newruntime it is now allowed to assign discriminator field without restrictions as long as case object doesn't have custom destructor. Discriminator value doesn't have to be a constant either. If you have custom destructor for case object and you do want to freely assign discriminator fields, it is recommended to refactor object into 2 objects like this:
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

## Compiler changes

- Specific warnings can now be turned into errors via `--warningAsError[X]:on|off`.
- The `define` and `undef` pragmas have been de-deprecated.
- New command: `nim r main.nim [args...]` which compiles and runs main.nim, saving
  the binary to $nimcache/main$exeExt, using the same logic as `nim c -r` to
  avoid recompiling when sources don't change. This is now the preferred way to
  run tests, avoiding the usual pain of clobbering your repo with binaries or
  using tricky gitignore rules on posix. Example:
  ```nim
  nim r compiler/nim.nim --help # only compiled the first time
  echo 'import os; echo getCurrentCompilerExe()' | nim r - # this works too
  nim r compiler/nim.nim --fullhelp # no recompilation
  nim r --nimcache:/tmp main # binary saved to /tmp/main
  ```

## Tool changes

