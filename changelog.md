## v0.18.0 - dd/mm/yyyy

### Changes affecting backwards compatibility

- Moved basic2d/basic3d from the stdlib into separate Nimble packages. These
  packages are deprecated however: use ``glm``, ``arraymancer``, ``neo`` or
  another package.
- Arrays of char cannot be converted to ``cstring`` anymore, pointers to
  arrays of char can! This means ``$`` for arrays can finally exist
  in ``system.nim`` and do the right thing.
- ``echo`` now works with strings that contain ``\0`` (the binary zero is not
  shown) and ``nil`` strings are equal to empty strings.
- JSON: Deprecated `getBVal`, `getFNum`, and `getNum` in favour to
  `getBool`, `getFloat`, `getBiggestInt`. Also `getInt` procedure was added.
- `reExtended` is no longer default for the `re` constructor in the `re`
  module.
- The overloading rules changed slightly so that constrained generics are
  preferred over unconstrained generics. (Bug #6526)
- Removed wrappers for PDCurses and libuv from the stdlib into separate Nimble
  packages.
