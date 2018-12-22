## v0.20.0 - XX/XX/2018

### Changes affecting backwards compatibility

- The ``isLower``, ``isUpper`` family of procs in strutils/unicode
  operating on **strings** have been
  deprecated since it was unclear what these do. Note that the much more
  useful procs that operator on ``char`` or ``Rune`` are not affected.

- `strutils.editDistance` has been deprecated,
  use `editdistance.editDistance` or `editdistance.editDistanceAscii`
  instead.

- The OpenMP parallel iterator \``||`\` now supports any `#pragma omp directives`
  and not just `#pragma omp parallel for`. See
  [OpenMP documentation](https://www.openmp.org/wp-content/uploads/OpenMP-4.5-1115-CPP-web.pdf).

  The default annotation is `parallel for`, if you used OpenMP without annotation
  the change is transparent, if you used annotations you will have to prefix
  your previous annotations with `parallel for`.

- The `unchecked` pragma was removed, instead use `system.UncheckedArray`.
- The undocumented ``#? strongSpaces`` parsing mode has been removed.
- The `not` operator is now always a unary operator, this means that code like
  ``assert not isFalse(3)`` compiles.


#### Breaking changes in the standard library

- `osproc.execProcess` now also takes a `workingDir` parameter.

- `options.UnpackError` is no longer a ref type and inherits from `System.Defect` instead of `System.ValueError`.

- nre's `RegexMatch.{captureBounds,captures}[]`  no longer return `Option` or
  `nil`/`""`, respectivly. Use the newly added `n in p.captures` method to
  check if a group is captured, otherwise you'll recieve an exception.

- nre's `RegexMatch.{captureBounds,captures}.toTable` no longer accept a
  default parameter. Instead uncaptured entries are left empty. Use
  `Table.getOrDefault()` if you need defaults.

- nre's `RegexMatch.captures.{items,toSeq}` now returns an `Option[string]`
  instead of a `string`. With the removal of `nil` strings, this is the only
  way to indicate a missing match. Inside your loops, instead of `capture ==
  ""` or `capture == nil`, use `capture.isSome` to check if a capture is
  present, and `capture.get` to get its value.

- nre's `replace()` no longer throws `ValueError` when the replacement string
  has missing captures. It instead throws `KeyError` for named captures, and
  `IndexError` for un-named captures. This is consistant with
  `RegexMatch.{captureBounds,captures}[]`.

- splitFile now correctly handles edge cases, see #10047

#### Breaking changes in the compiler

- The compiler now implements the "generic symbol prepass" for `when` statements
  in generics, see bug #8603. This means that code like this does not compile
  anymore:

```nim
proc enumToString*(enums: openArray[enum]): string =
  # typo: 'e' instead 'enums'
  when e.low.ord >= 0 and e.high.ord < 256:
    result = newString(enums.len)
  else:
    result = newString(enums.len * 2)
```

- ``discard x`` is now illegal when `x` is a function symbol.
- Implicit imports via ``--import: module`` in a config file are now restricted
  to the main package.


### Library additions

- There is a new stdlib module `std/editdistance` as a replacement for the
  deprecated `strutils.editDistance`.

- There is a new stdlib module `std/wordwrap` as a replacement for the
  deprecated `strutils.wordwrap`.

- Added `split`, `splitWhitespace`, `size`, `alignLeft`, `align`,
  `strip`, `repeat` procs and iterators to `unicode.nim`.

- Added `or` for `NimNode` in `macros`.

- Added `system.typeof` for more control over how `type` expressions
  can be deduced.

- Added `macros.isInstantiationOf` for checking if the proc symbol
  is instantiation of generic proc symbol.

- Added the parameter ``isSorted`` for the ``sequtils.deduplicate`` proc.
- There is a new stdlib module `std/diff` to compute the famous "diff"
  of two texts by line.

- Added `os.relativePath`.
- Added `parseopt.remainingArgs`.
- Added `os.getCurrentCompilerExe` (implmented as `getAppFilename` at CT),
  can be used to retrive the currently executing compiler.


### Library changes

- The string output of `macros.lispRepr` proc has been tweaked
  slightly. The `dumpLisp` macro in this module now outputs an
  indented proper Lisp, devoid of commas.

- In `strutils` empty strings now no longer matched as substrings
  anymore.

- Complex type is now generic and not a tuple anymore.

- The `ospaths` module is now deprecated, use `os` instead. Note that
  `os` is available in a NimScript environment but unsupported
  operations produce a compile-time error.

- The `parseopt` module now supports a new flag `allowWhitespaceAfterColon`
  (default value: true) that can be set to `false` for better Posix
  interoperability. (Bug #9619.)

- `os.joinPath` and `os.normalizePath` handle edge cases like ``"a/b/../../.."``
  differently.


### Language additions

- Vm suport for float32<->int32 and float64<->int64 casts was added.
- There is a new pragma block `noSideEffect` that works like
  the `gcsafe` pragma block.
- added os.getCurrentProcessId()
- User defined pragmas are now allowed in the pragma blocks
- Pragma blocks are now longer eliminated from the typed AST tree to preserve
  pragmas for further analysis by macros

### Language changes

- The standard extension for SCF (source code filters) files was changed from
  ``.tmpl`` to ``.nimf``,
  it's more recognizable and allows tools like github to recognize it as Nim,
  see [#9647](https://github.com/nim-lang/Nim/issues/9647).
  The previous extension will continue to work.

### Tool changes
- `jsondoc` now include a `moduleDescription` field with the module
  description. `jsondoc0` shows comments as it's own objects as shown in the
  documentation.

### Compiler changes
- The deprecated `fmod` proc is now unavailable on the VM'.

### Bugfixes
