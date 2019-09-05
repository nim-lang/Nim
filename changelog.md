# v1.1 - XXXX-XX-XX


## Changes affecting backwards compatibility

- The switch ``-d:nimBinaryStdFiles`` does not exist anymore. Instead
  stdin/stdout/stderr are binary files again. This change only affects
  Windows.
- On Windows console applications the code-page is set at program startup
  to UTF-8. Use the new switch `-d:nimDontSetUtf8CodePage` to disable this
  feature.

- The language definition and compiler are now stricter about ``gensym``'ed
  symbols in hygienic templates. See the section in the
  [manual](https://nim-lang.org/docs/manual.html#templates-hygiene-in-templates)
  for further details. Use the compiler switch `--oldgensym:on` for a
  transition period.


### Breaking changes in the standard library

- We removed `unicode.Rune16` without any deprecation period as the name
  was wrong (see the [RFC](https://github.com/nim-lang/RFCs/issues/151) for details)
  and we didn't find any usages of it in the wild. If you still need it, add this
  piece of code to your project:

```nim

type
  Rune16* = distinct int16

```

- `exportc` now uses C instead of C++ mangling with `nim cpp`, matching behavior of `importc`, see #10578
  Use the new `exportcpp` to mangle as C++ when using `nim cpp`.

### Breaking changes in the compiler

- A bug allowing `int` to be implicitly converted to range types of smaller size (e.g `range[0'i8..10'i8]`) has been fixed.


## Library additions

- `encodings.getCurrentEncoding` now distinguishes between the console's
  encoding and the OS's encoding. This distinction is only meaningful on
  Windows.
- Added `system.getOsFileHandle` which is usually more useful
  than `system.getFileHandle`. This distinction is only meaningful on
  Windows.

## Library changes

- Added `os.delEnv` and `nimscript.delEnv`. (#11466)

- Enabled Oid usage in hashtables. (#11472)

- Added `unsafeColumnAt` procs, that return unsafe cstring from InstantRow. (#11647)

- Make public `Sha1Digest` and `Sha1State` types and `newSha1State`,
  `update` and `finalize` procedures from `sha1` module. (#11694)

- Added the `std/monotimes` module which implements monotonic timestamps.

- Consistent error handling of two `exec` overloads. (#10967)

## Language additions

- Inline iterators returning `lent T` types are now supported, similarly to iterators returning `var T`:
```nim
iterator myitems[T](x: openarray[T]): lent T
iterator mypairs[T](x: openarray[T]): tuple[idx: int, val: lent T]
```

## Language changes

- `uint64` is now finally a regular ordinal type. This means `high(uint64)` compiles
  and yields the correct value.


### Tool changes

- The Nim compiler now does not recompile the Nim project via ``nim c -r`` if
  no dependent Nim file changed. This feature can be overridden by
  the ``--forceBuild`` command line option.
- The Nim compiler now warns about unused module imports. You can use a
  top level ``{.used.}`` pragma in the module that you want to be importable
  without producing this warning.
- The "testament" testing tool's name was changed
  from `tester` to `testament` and is generally available as a tool to run Nim
  tests automatically.


### Compiler changes

- VM can now cast integer type arbitrarily. (#11459)


## Bugfixes
