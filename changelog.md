# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes

- `uri` adds Data URI Base64, implements RFC-2397.
- Add [DOM Parser](https://developer.mozilla.org/en-US/docs/Web/API/DOMParser)
  to the `dom` module for the JavaScript target.
- The default hash for `Ordinal` has changed to something more bit-scrambling.
  `import hashes; proc hash(x: myInt): Hash = hashIdentity(x)` recovers the old
  one in an instantiation context while `-d:nimIntHash1` recovers it globally.
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

- getImpl() on enum type symbols now return field syms instead of idents. This helps
  with writing typed macros.

## Compiler changes

- Specific warnings can now be turned into errors via `--warningAsError[X]:on|off`.
- The `define` and `undef` pragmas have been de-deprecated.

## Tool changes

