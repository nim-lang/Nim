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

### Library changes


### Language additions


### Language changes


### Tool changes

### Compiler changes

### Bugfixes
