# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes

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


## Compiler changes

- Specific warnings can now be turned into errors via `--warningAsError[X]:on|off`.
- The `define` and `undef` pragmas have been de-deprecated.

## Tool changes

