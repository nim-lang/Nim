# v2.x.x - yyyy-mm-dd


## Changes affecting backward compatibility

- `-d:nimPreviewFloatRoundtrip` becomes the default. `system.addFloat` and `system.$` now can produce string representations of
floating point numbers that are minimal in size and possess round-trip and correct
rounding guarantees (via the
[Dragonbox](https://raw.githubusercontent.com/jk-jeon/dragonbox/master/other_files/Dragonbox.pdf) algorithm). Use `-d:nimLegacySprintf` to emulate old behaviors.

- The `default` parameter of `tables.getOrDefault` has been renamed to `def` to
  avoid conflicts with `system.default`, so named argument usage for this
  parameter like `getOrDefault(..., default = ...)` will have to be changed.

- With `-d:nimPreviewCheckedClose`, the `close` function in the `std/syncio` module now raises an IO exception in case of an error.

- Unknown warnings and hints now gives warnings `warnUnknownNotes` instead of
errors.

- With `-d:nimPreviewAsmSemSymbol`, backticked symbols are type checked in the `asm/emit` statements.

- The bare `except:` now panics on `Defect`. Use `except Exception:` or `except Defect:` to catch `Defect`. `--legacy:noPanicOnExcept` is provided for a transition period.

- With `-d:nimPreviewCStringComparisons`, comparsions (`<`, `>`, `<=`, `>=`) between cstrings switch from reference semantics to value semantics like `==` and `!=`.

- `std/parsesql` has been moved to a nimble package, use `nimble` or `atlas` to install it.

- With `-d:nimPreviewDuplicateModuleError`, importing two modules that share the same name becomes a compile-time error. This includes importing the same module more than once. Use `import foo as foo1` (or other aliases) to avoid collisions.

- Adds the switch `--mangle:nim|cpp`, which selects `nim` or `cpp` style name mangling when used with `debuginfo` on, defaults to `cpp`.

## Standard library additions and changes

[//]: # "Additions:"

- `setutils.symmetricDifference` along with its operator version
  `` setutils.`-+-` `` and in-place version `setutils.toggle` have been added
  to more efficiently calculate the symmetric difference of bitsets.
- `strutils.multiReplace` overload for character set replacements in a single pass.
	Useful for string sanitation. Follows existing multiReplace semantics.

- `std/files` adds:
  - Exports `CopyFlag` enum and `FilePermission` type for fine-grained control of file operations
  - New file operation procs with `Path` support:
    - `getFilePermissions`, `setFilePermissions` for managing permissions
    - `tryRemoveFile` for file deletion
    - `copyFile` with configurable buffer size and symlink handling
    - `copyFileWithPermissions` to preserve file attributes
    - `copyFileToDir` for copying files into directories

- `std/dirs` adds:
  - New directory operation procs with `Path` support:
    - `copyDir` with special file handling options
    - `copyDirWithPermissions` to recursively preserve attributes

- `system.setLenUninit` now supports refc, JS and VM backends.

[//]: # "Changes:"

- `std/math` The `^` symbol now supports floating-point as exponent in addition to the Natural type.
- `min`, `max`, and `sequtils`' `minIndex`, `maxIndex` and `minmax` for `openArray`s now accept a comparison function.
- `system.substr` implementation now uses `copymem` (wrapped C `memcpy`) for copying data, if available at compilation.
- `system.newStringUninit` is now considered free of side-effects allowing it to be used with `--experimental:strictFuncs`.

## Language changes

- An experimental option `--experimental:typeBoundOps` has been added that
  implements the RFC https://github.com/nim-lang/RFCs/issues/380.
  This makes the behavior of interfaces like `hash`, `$`, `==` etc. more
  reliable for nominal types across indirect/restricted imports.

  ```nim
  # objs.nim
  import std/hashes

  type
    Obj* = object
      x*, y*: int
      z*: string # to be ignored for equality

  proc `==`*(a, b: Obj): bool =
    a.x == b.x and a.y == b.y

  proc hash*(a: Obj): Hash =
    $!(hash(a.x) &! hash(a.y))
  ```

  ```nim
  # main.nim
  {.experimental: "typeBoundOps".}
  from objs import Obj # objs.hash, objs.`==` not imported
  import std/tables

  var t: Table[Obj, int]
  t[Obj(x: 3, y: 4, z: "debug")] = 34
  echo t[Obj(x: 3, y: 4, z: "ignored")] # 34
  ```

  See the [experimental manual](https://nim-lang.github.io/Nim/manual_experimental.html#typeminusbound-overloads)
  for more information.

## Compiler changes


## Tool changes

- Added `--stdinfile` flag to name of the file used when running program from stdin (defaults to `stdinfile.nim`)
