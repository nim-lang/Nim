## v0.20.0 - XX/XX/2018

### Changes affecting backwards compatibility

- The ``isLower``, ``isUpper`` family of procs in strutils/unicode
  operating on **strings** have been
  deprecated since it was unclear what these do. Note that the much more
  useful procs that operator on ``char`` or ``Rune`` are not affected.

- `strutils.editDistance` has been deprecated,
  use `editdistance.editDistance` or `editdistance.editDistanceAscii`
  instead.


#### Breaking changes in the standard library


#### Breaking changes in the compiler

### Library additions

- There is a new stdlib module `editdistance` as a replacement for the
  deprecated `strutils.editDistance`.

- Added `split`, `splitWhitespace`, `size`, `alignLeft`, `align`,
  `strip`, `repeat` procs and iterators to `unicode.nim`.

- Added `or` for `NimNode` in `macros`.

- Added `system.typeof` for more control over how `type` expressions
  can be deduced.

### Library changes


### Language additions


### Language changes


### Tool changes
- `jsondoc` now include a `moduleDescription` field with the module
  description. `jsondoc0` shows comments as it's own objects as shown in the
  documentation.

### Compiler changes

### Bugfixes
