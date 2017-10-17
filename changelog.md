## v0.18.0 - dd/mm/yyyy

### Changes affecting backwards compatibility

- Removed basic2d/basic3d out of the stdlib and into Nimble packages.
  These packages deprecated however, use the ``glm``, ``arraymancer``, ``neo``
  or another package.
- Arrays of char cannot be converted to ``cstring`` anymore, pointers to
  arrays of char can! This means ``$`` for arrays can finally exist
  in ``system.nim`` and do the right thing.
- JSON: Deprecated `getBVal`, `getFNum`, and `getNum` in favour to
  `getBool`, `getFloat`, `getBiggestInt`. Also `getInt` procedure was added.
- ``echo`` now works with strings that contain ``\0`` (the binary zero is not
  shown) and ``nil`` strings are equal to empty strings.
