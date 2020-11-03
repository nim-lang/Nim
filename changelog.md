# v1.6.x - yyyy-mm-dd



## Standard library additions and changes

- `prelude` now works with the JavaScript target.

- Added `ioutils` module containing `duplicate` and `duplicateTo` to duplicate `FileHandle` using C function `dup` and `dup2`.
- Added `almostEqual` in `math` for comparing two float values using a machine epsilon.

- The JSON module can now handle integer literals and floating point literals of arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are kept as string literals and
  one can use external BigNum libraries to handle these. The `parseFloat` family of functions also has now optional
  `rawIntegers` and `rawFloats` parameters that can be used to enforce that all integer or float literals remain
  in the "raw" string form so that client code can easily treat small and large numbers uniformly.

- Added `randState` template that exposes the default random number generator. Useful for library authors.

- Added std/enumutils module containing `genEnumCaseStmt` macro that generates case statement to parse string to enum.

- Removed deprecated `iup` module from stdlib, it has already moved to [nimble](https://github.com/nim-lang/iup).

## Language changes



## Compiler changes

- Added `--declaredlocs` to show symbol declaration location in messages.
- Source+Edit links now appear on top of every docgen'd page when `nim doc --git.url:url ...` is given.


## Tool changes
