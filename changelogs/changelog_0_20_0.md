## v0.20.0 - 2019-06-06


### Changes affecting backwards compatibility

- `shr` is now sign preserving. Use `-d:nimOldShiftRight` to enable
  the old behavior globally.

- The ``isLower``, ``isUpper`` family of procs in strutils/unicode
  operating on **strings** have been
  deprecated since it was unclear what these do. Note that the much more
  useful procs that operate on ``char`` or ``Rune`` are not affected.

- `strutils.editDistance` has been deprecated,
  use `editdistance.editDistance` or `editdistance.editDistanceAscii`
  instead.

- The OpenMP parallel iterator \``||`\` now supports any `#pragma omp directive`
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

- Methods are now ordinary "single" methods, only the first parameter is
  used to select the variant at runtime. For backwards compatibility
  use the new `--multimethods:on` switch.

- Generic methods are now deprecated; they never worked well.

- Compile time checks for integer and float conversions are now stricter.
  For example, `const x = uint32(-1)` now gives a compile time error instead
  of being equivalent to `const x = 0xFFFFFFFF'u32`.

- Using `typed` as the result type in templates/macros now means
  "expression with a type". The old meaning of `typed` is preserved
  as `void` or no result type at all.

- A bug allowed `macro foo(): int = 123` to compile even though a
  macro has to return a `NimNode`. This has been fixed.

- With the exception of `uint` and `uint64`, conversion to unsigned types
  are now range checked during runtime.

- Macro arguments of type `typedesc` are now passed to the macro as
  `NimNode` like every other type except `static`. Use `typed` for a
  behavior that is identical in new and old
  Nim. See the RFC [Pass typedesc as NimNode to macros](https://github.com/nim-lang/RFCs/issues/148)
  for more details.


#### Breaking changes in the standard library

- `osproc.execProcess` now also takes a `workingDir` parameter.

- `std/sha1.secureHash` now accepts `openArray[char]`, not `string`. (Former
   successful matches should keep working, though former failures will not.)

- `options.UnpackError` is no longer a ref type and inherits from `system.Defect`
  instead of `system.ValueError`.

- `system.ValueError` now inherits from `system.CatchableError` instead of `system.Defect`.

- The procs `parseutils.parseBiggestInt`, `parseutils.parseInt`,
  `parseutils.parseBiggestUInt` and `parseutils.parseUInt` now raise a
  `ValueError` when the parsed integer is outside of the valid range.
  Previously they sometimes raised an `OverflowError` and sometimes they
  returned `0`.

- The procs `parseutils.parseBin`, `parseutils.parseOct` and `parseutils.parseHex`
  were not clearing their `var` parameter `number` and used to push its value to
  the left when storing the parsed string into it. Now they always set the value
  of the parameter to `0` before storing the result of the parsing, unless the
  string to parse is not valid (then the value of `number` is not changed).

- `streams.StreamObject` now restricts its fields to only raise `system.Defect`,
  `system.IOError` and `system.OSError`.
  This change only affects custom stream implementations.

- nre's `RegexMatch.{captureBounds,captures}[]`  no longer return `Option` or
  `nil`/`""`, respectively. Use the newly added `n in p.captures` method to
  check if a group is captured, otherwise you'll receive an exception.

- nre's `RegexMatch.{captureBounds,captures}.toTable` no longer accept a
  default parameter. Instead uncaptured entries are left empty. Use
  `Table.getOrDefault()` if you need defaults.

- nre's `RegexMatch.captures.{items,toSeq}` now returns an `Option[string]`
  instead of a `string`. With the removal of `nil` strings, this is the only
  way to indicate a missing match. Inside your loops, instead
  of `capture == ""` or `capture == nil`, use `capture.isSome` to check if a capture is
  present, and `capture.get` to get its value.

- nre's `replace()` no longer throws `ValueError` when the replacement string
  has missing captures. It instead throws `KeyError` for named captures, and
  `IndexError` for unnamed captures. This is consistent with
  `RegexMatch.{captureBounds,captures}[]`.

- `splitFile` now correctly handles edge cases, see #10047.

- `isNil` is no longer false for undefined in the JavaScript backend:
  now it's true for both nil and undefined.
  Use `isNull` or `isUndefined` if you need exact equality:
  `isNil` is consistent with `===`, `isNull` and `isUndefined` with `==`.

- several deprecated modules were removed: `ssl`, `matchers`, `httpserver`,
  `unsigned`, `actors`, `parseurl`

- two poorly documented and not used modules (`subexes`, `scgi`) were moved to
  graveyard (they are available as Nimble packages)

- procs `string.add(int)` and `string.add(float)` which implicitly convert
  ints and floats to string have been deprecated.
  Use `string.addInt(int)` and `string.addFloat(float)` instead.

- ``case object`` branch transitions via ``system.reset`` are deprecated.
  Compile your code with ``-d:nimOldCaseObjects`` for a transition period.

- base64 module: The default parameter `newLine` for the `encode` procs
  was changed from `"\13\10"` to the empty string `""`.


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

- Added `os.getCurrentCompilerExe` (implemented as `getAppFilename` at CT),
  can be used to retrieve the currently executing compiler.

- Added `xmltree.toXmlAttributes`.

- Added ``std/sums`` module for fast summation functions.

- Added `Rusage`, `getrusage`, `wait4` to the posix interface.

- Added the `posix_utils` module.

- Added `system.default`.

- Added `sequtils.items` for closure iterators, allows closure iterators
  to be used by the `mapIt`, `filterIt`, `allIt`, `anyIt`, etc.


### Library changes

- The string output of `macros.lispRepr` proc has been tweaked
  slightly. The `dumpLisp` macro in this module now outputs an
  indented proper Lisp, devoid of commas.

- Added `macros.signatureHash` that returns a stable identifier
  derived from the signature of a symbol.

- In `strutils` empty strings now no longer matched as substrings
  anymore.

- The `Complex` type is now a generic object and not a tuple anymore.

- The `ospaths` module is now deprecated, use `os` instead. Note that
  `os` is available in a NimScript environment but unsupported
  operations produce a compile-time error.

- The `parseopt` module now supports a new flag `allowWhitespaceAfterColon`
  (default value: true) that can be set to `false` for better Posix
  interoperability. (Bug #9619.)

- `os.joinPath` and `os.normalizePath` handle edge cases like ``"a/b/../../.."``
  differently.

- `securehash` was moved to `lib/deprecated`.

- The switch ``-d:useWinAnsi`` is not supported anymore.

- In `times` module, procs `format` and `parse` accept a new optional
  `DateTimeLocale` argument for formatting/parsing dates in other languages.


### Language additions

- Vm support for float32<->int32 and float64<->int64 casts was added.
- There is a new pragma block `noSideEffect` that works like
  the `gcsafe` pragma block.
- added `os.getCurrentProcessId`.
- User defined pragmas are now allowed in the pragma blocks.
- Pragma blocks are no longer eliminated from the typed AST tree to preserve
  pragmas for further analysis by macros.
- Custom pragmas are now supported for `var` and `let` symbols.
- Tuple unpacking is now supported for constants and for loop variables.
- Case object branches can be initialized with a runtime discriminator if
  possible discriminator values are constrained within a case statement.

### Language changes

- The standard extension for SCF (source code filters) files was changed from
  ``.tmpl`` to ``.nimf``,
  it's more recognizable and allows tools like Github to recognize it as Nim,
  see [#9647](https://github.com/nim-lang/Nim/issues/9647).
  The previous extension will continue to work.

- Pragma syntax is now consistent. Previous syntax where type pragmas did not
  follow the type name is now deprecated. Also pragma before generic parameter
  list is deprecated to be consistent with how pragmas are used with a proc. See
  [#8514](https://github.com/nim-lang/Nim/issues/8514) and
  [#1872](https://github.com/nim-lang/Nim/issues/1872) for further details.

- Hash sets and tables are initialized by default. The explicit `initHashSet`,
  `initTable`, etc. are not needed anymore.


### Tool changes

- `jsondoc` now includes a `moduleDescription` field with the module
  description. `jsondoc0` shows comments as its own objects as shown in the
  documentation.
- `nimpretty`: --backup now defaults to `off` instead of `on` and the flag was
  undocumented; use `git` instead of relying on backup files.
- `koch` now defaults to build the latest *stable* Nimble version unless you
  explicitly ask for the latest master version via `--latest`.


### Compiler changes

- The deprecated `fmod` proc is now unavailable on the VM.
- A new `--outdir` option was added.
- The compiled JavaScript file for the project produced by executing `nim js`
  will no longer be placed in the nimcache directory.
- The `--hotCodeReloading` has been implemented for the native targets.
  The compiler also provides a new more flexible API for handling the
  hot code reloading events in the code.
- The compiler now supports a ``--expandMacro:macroNameHere`` switch
  for easy introspection into what a macro expands into.
- The `-d:release` switch now does not disable runtime checks anymore.
  For a release build that also disables runtime checks
  use `-d:release -d:danger` or simply `-d:danger`.


### Bugfixes
