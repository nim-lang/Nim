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

- The second parameter of `succ`, `pred`, `inc`, and `dec` in `system` now accepts `SomeInteger` (previously `Ordinal`).

- Bitshift operators (`shl`, `shr`, `ashr`) now apply bitmasking to the right operand in the C/C++/VM/JS backends.

- Adds a new warning `--warning:ImplicitRangeConversion` that detects downsizing implicit conversions to range types (e.g., `int -> range[0..255]` or `range[1..256] -> range[0..255]`) that could cause runtime panics. Safe conversions like `range[0..255] -> range[0..65535]` and explicit casts do not trigger warnings. `int` to `Natural` and `Positive` conversions do not trigger warnings, which can be enabled with `--warning:systemRangeConversion`.

- Procedure compatibility also checks the backend representation of the
parameter and result types, not just their source-level shape. Use
`--legacy:procParamTypeBackendAliases` to restore the older behavior.

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
- `system.setLenUninit` for the `string` type. Allows setting length without initializing new memory on growth.

- `std/parseopt` now supports multiple parser modes via a `CliMode` enum.
  Modes include `Nim` (default, fully compatible) and two new experimental modes:
  `Lax` and `Gnu` for different option parsing behaviors.

- `std/nre2` is added to replace deprecated NRE.

[//]: # "Changes:"

- `std/math` The `^` symbol now supports floating-point as exponent in addition to the Natural type.
- `min`, `max`, and `sequtils`' `minIndex`, `maxIndex` and `minmax` for `openArray`s now accept a comparison function.
- `system.substr` implementation now uses `copymem` (wrapped C `memcpy`) for copying data, if available at compilation.
- `system.newStringUninit` is now considered free of side-effects allowing it to be used with `--experimental:strictFuncs`.
- `std/re` and `std/nre` now use PCRE2. They remain deprecated;
  use https://github.com/nitely/nim-regex or `std/nre2`.
  See: https://github.com/nim-lang/Nim/issues/23668.
- `std/pegs` now correctly lexes UTF-8 bytes inside bare identifier-style
  terminals, so case-insensitive matching of non-ASCII terms (e.g. ``\i café``)
  works without single-quoting.

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

- Fixed a bug where `sizeof(T)` inside a `typedesc` template called from a generic type's
  `when` clause would error with "'sizeof' requires '.importc' types to be '.completeStruct'".
  The issue was that `hasValuelessStatics` in `semtypinst.nim` didn't recognize
  `tyTypeDesc(tyGenericParam)` as an unresolved generic parameter.

## Tool changes

- Added `--raw` flag when generating JSON docs to not render markup.
- Added `--stdinfile` flag to name of the file used when running program from stdin (defaults to `stdinfile.nim`)
- Added `--styleCheck:warning` flag to treat style check violations as warnings.

## Documentation changes

- Added documentation for the `completeStruct` pragma in the manual.
