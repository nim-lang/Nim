## v0.20.0 - XX/XX/2019


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

  Furthermore, an overload with positive stepping is available.

- The `unchecked` pragma was removed, instead use `system.UncheckedArray`.

- The undocumented ``#? strongSpaces`` parsing mode has been removed.

- The `not` operator is now always a unary operator, this means that code like
  ``assert not isFalse(3)`` compiles.

- `getImpl` on a `var` or `let` symbol will now return the full `IdentDefs`
  tree from the symbol declaration instead of just the initializer portion.
- it is now possible to use statement list expressions after keywords with
  indentation: raise, return, discard, yield. This helps parsing code produced 
  by Nim template expansion where stmtListExpr can appear in place of any expression.
  Example:
```nim
  raise 
    var e = new(Exception)
    e.msg = "My Exception msg"
    e
```

- To use multi-methods, explicit `--multimethods:on` is now needed.


#### Breaking changes in the standard library

- `osproc.execProcess` now also takes a `workingDir` parameter.

- `options.UnpackError` is no longer a ref type and inherits from `system.Defect`
  instead of `system.ValueError`.

- `system.ValueError` now inherits from `system.CatchableError` instead of `system.Defect`.

- The procs `parseutils.parseBiggsetInt`, `parseutils.parseInt`,
  `parseutils.parseBiggestUInt` and `parseutils.parseUInt` now raise a
  `ValueError` when the parsed integer is outside of the valid range.
  Previously they sometimes raised a `OverflowError` and sometimes returned `0`.

- `streams.StreamObject` now restricts its fields to only raise `system.Defect`,
  `system.IOError` and `system.OSError`.
  This change only affects custom stream implementations.

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

- `isNil` is no longer false for undefined in the JavaScript backend:
  now it's true for both nil and undefined.
  Use `isNull` or `isUndefined` if you need exact equallity:
  `isNil` is consistent with `===`, `isNull` and `isUndefined` with `==`.

- several deprecated modules were removed: `ssl`, `matchers`, `httpserver`,
  `unsigned`, `actors`, `parseurl`

- two poorly documented and not used modules (`subexes`, `scgi`) were moved to
  graveyard (they are available as Nimble packages)



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
  can be used to retrieve the currently executing compiler.

- Added `xmltree.toXmlAttributes`.

- Added ``std/sums`` module for fast summation functions.

- Added `Rusage`, `getrusage`, `wait4` to posix interface.

- Added the `posix_utils` module.

- Added `system.default`.


### Library changes

- The string output of `macros.lispRepr` proc has been tweaked
  slightly. The `dumpLisp` macro in this module now outputs an
  indented proper Lisp, devoid of commas.

- Added `macros.signatureHash` that returns a stable identifier
  derived from the signature of a symbol.

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

- `securehash` is moved to `lib/deprecated`


### Language additions

- Vm support for float32<->int32 and float64<->int64 casts was added.
- There is a new pragma block `noSideEffect` that works like
  the `gcsafe` pragma block.
- added os.getCurrentProcessId()
- User defined pragmas are now allowed in the pragma blocks
- Pragma blocks are no longer eliminated from the typed AST tree to preserve
  pragmas for further analysis by macros
- Custom pragmas are now supported for `var` and `let` symbols.
- Tuple unpacking is now supported for constants and for loop variables.


### Language changes

- The standard extension for SCF (source code filters) files was changed from
  ``.tmpl`` to ``.nimf``,
  it's more recognizable and allows tools like github to recognize it as Nim,
  see [#9647](https://github.com/nim-lang/Nim/issues/9647).
  The previous extension will continue to work.
- Pragma syntax is now consistent. Previous syntax where type pragmas did not
  follow the type name is now deprecated. Also pragma before generic parameter
  list is deprecated to be consistent with how pragmas are used with a proc. See
  [#8514](https://github.com/nim-lang/Nim/issues/8514) and
  [#1872](https://github.com/nim-lang/Nim/issues/1872) for further details.


### Tool changes
- `jsondoc` now include a `moduleDescription` field with the module
  description. `jsondoc0` shows comments as it's own objects as shown in the
  documentation.
- `nimpretty`: --backup now defaults to `off` instead of `on` and the flag was
  un-documented; use `git` instead of relying on backup files.


### Compiler changes
- The deprecated `fmod` proc is now unavailable on the VM'.
- A new `--outdir` option was added.
- The compiled JavaScript file for the project produced by executing `nim js`
  will no longer be placed in the nimcache directory.
- The `--hotCodeReloading` has been implemented for the native targets.
  The compiler also provides a new more flexible API for handling the
  hot code reloading events in the code.

### Bugfixes
