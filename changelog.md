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

- nodejs now supports osenv: `getEnv`, `putEnv`, `envPairs`, `delEnv`, `existsEnv`

- `doAssertRaises` now correctly handles foreign exceptions.

- Add `strmisc.parseFloatThousandSep` designed to parse floats as found in the wild formatted for humans.
- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors

- ``--gc:orc`` is now 10% faster than previously for common workloads. If
  you have trouble with its changed behavior, compile with ``-d:nimOldOrc``.


- `os.FileInfo` (returned by `getFileInfo`) now contains `blockSize`,
  determining preferred I/O block size for this file object.
- `repr` now doesn't insert trailing newline; previous behavior was very inconsistent,
  see #16034. Use `-d:nimLegacyReprWithNewline` for previous behavior.

## Language changes

- `nimscript` now handles `except Exception as e`

- The `cstring` doesn't support `[]=` operator in JS backend.

- nil dereference is not allowed at compile time. `cast[ptr int](nil)[]` is rejected at compile time.

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
