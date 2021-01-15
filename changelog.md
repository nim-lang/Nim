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

- Added an overload for the `collect` macro that inferes the container type based
  on the syntax of the last expression. Works with std seqs, tables and sets.

- Added `randState` template that exposes the default random number generator.
  Useful for library authors.

- Added std/enumutils module containing `genEnumCaseStmt` macro that generates
  case statement to parse string to enum.

- Removed deprecated `iup` module from stdlib, it has already moved to
  [nimble](https://github.com/nim-lang/iup).

- various functions in `httpclient` now accept `url` of type `Uri`. Moreover `request` function's
  `httpMethod` argument of type `string` was deprecated in favor of `HttpMethod` enum type.

- `nodejs` backend now supports osenv: `getEnv`, `putEnv`, `envPairs`, `delEnv`, `existsEnv`.

- Added `cmpMem` to `system`.

- `doAssertRaises` now correctly handles foreign exceptions.

- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors.

- `--gc:orc` is now 10% faster than previously for common workloads. If
  you have trouble with its changed behavior, compile with `-d:nimOldOrc`.


- `os.FileInfo` (returned by `getFileInfo`) now contains `blockSize`,
  determining preferred I/O block size for this file object.

- `repr` now doesn't insert trailing newline; previous behavior was very inconsistent,
  see #16034. Use `-d:nimLegacyReprWithNewline` for previous behavior.

- Added `**` to jsffi.

- `writeStackTrace` is available in JS backend now.

- Added `decodeQuery` to `std/uri`.
- `strscans.scanf` now supports parsing single characters.
- `strscans.scanTuple` added which uses `strscans.scanf` internally, returning a tuple which can be unpacked for easier usage of `scanf`.

- Added `setutils.toSet` that can take any iterable and convert it to a built-in set,
  if the iterable yields a built-in settable type.

- Added `math.isNaN`.

- `echo` and `debugEcho` will now raise `IOError` if writing to stdout fails.  Previous behavior
  silently ignored errors.  See #16366.  Use `-d:nimLegacyEchoNoRaise` for previous behavior.

- Added `jsbigints` module, arbitrary precision integers for JavaScript target.

- Added `math.copySign`.
- Added new operations for singly- and doubly linked lists: `lists.toSinglyLinkedList`
  and `lists.toDoublyLinkedList` convert from `openArray`s; `lists.copy` implements
  shallow copying; `lists.add` concatenates two lists - an O(1) variation that consumes
  its argument, `addMoved`, is also supplied.

- Added `sequtils` import to `prelude`.

- Added `euclDiv` and `euclMod` to `math`.
- Added `httpcore.is1xx` and missing HTTP codes.
- Added `jsconsole.jsAssert` for JavaScript target.

- Added `posix_utils.osReleaseFile` to get system identification from `os-release` file on Linux and the BSDs.
  https://www.freedesktop.org/software/systemd/man/os-release.html

- Added `BackwardsIndex` overload for `JsonNode`.

- `math.round` now is rounded "away from zero" in JS backend which is consistent
with other backends. see #9125. Use `-d:nimLegacyJsRound` for previous behavior.
- Added `socketstream` module that wraps sockets in the stream interface

- Changed the behavior of `uri.decodeQuery` when there are unencoded `=`
  characters in the decoded values. Prior versions would raise an error. This is
  no longer the case to comply with the HTML spec and other languages
  implementations. Old behavior can be obtained with
  `-d:nimLegacyParseQueryStrict`. `cgi.decodeData` which uses the same
  underlying code is also updated the same way.




- Added `math.signbit`.

- Removed the optional `longestMatch` parameter of the `critbits._WithPrefix` iterators (it never worked reliably)

## Language changes

- The `=destroy` hook no longer has to reset its target, as the compiler now automatically inserts
  `wasMoved` calls where needed.
- In the newruntime it is now allowed to assign to the discriminator field
  without restrictions as long as case object doesn't have custom destructor.
  The discriminator value doesn't have to be a constant either. If you have a
  custom destructor for a case object and you do want to freely assign discriminator
  fields, it is recommended to refactor object into 2 objects like this:

  ```nim
  type
    MyObj = object
      case kind: bool
        of true: y: ptr UncheckedArray[float]
        of false: z: seq[int]

  proc `=destroy`(x: MyObj) =
    if x.kind and x.y != nil:
      deallocShared(x.y)
      x.y = nil
  ```
  Refactor into:
  ```nim
  type
    MySubObj = object
      val: ptr UncheckedArray[float]
    MyObj = object
      case kind: bool
      of true: y: MySubObj
      of false: z: seq[int]

  proc `=destroy`(x: MySubObj) =
    if x.val != nil:
      deallocShared(x.val)
      x.val = nil
  ```
- `getImpl` on enum type symbols now returns field syms instead of idents. This helps
  with writing typed macros. Old behavior for backwards compatibility can be restored
  with command line switch `--useVersion:1.0`.
- ``let`` statements can now be used without a value if declared with
  ``importc``/``importcpp``/``importjs``/``importobjc``.
- The keyword `from` is now usable as an operator.
- Exceptions inheriting from `system.Defect` are no longer tracked with
  the `.raises: []` exception tracking mechanism. This is more consistent with the
  built-in operations. The following always used to compile (and still does):

```nim

proc mydiv(a, b): int {.raises: [].} =
  a div b # can raise an DivByZeroDefect

```

  Now also this compiles:

```nim

proc mydiv(a, b): int {.raises: [].} =
  if b == 0: raise newException(DivByZeroDefect, "division by zero")
  else: result = a div b

```

  The reason for this is that `DivByZeroDefect` inherits from `Defect` and
  with `--panics:on` `Defects` become unrecoverable errors.

- Added the `thiscall` calling convention as specified by Microsoft, mostly for hooking purpose
- Deprecated `{.unroll.}` pragma, was ignored by the compiler anyways, was a nop.
- Remove `strutils.isNilOrWhitespace`, was deprecated.
- Remove `sharedtables.initSharedTable`, was deprecated and produces undefined behavior.
- Removed `asyncdispatch.newAsyncNativeSocket`, was deprecated since `0.18`.
- Remove `dom.releaseEvents` and `dom.captureEvents`, was deprecated.

- Remove `sharedlists.initSharedList`, was deprecated and produces undefined behaviour.

- There is a new experimental feature called "strictFuncs" which makes the definition of
  `.noSideEffect` stricter. [See](manual_experimental.html#stricts-funcs)
  for more information.

- "for-loop macros" (see [the manual](manual.html#macros-for-loop-macros)) are no longer
  an experimental feature. In other words, you don't have to write pragma
  `{.experimental: "forLoopMacros".}` if you want to use them.

- Added a ``.noalias`` pragma. It is mapped to C's ``restrict`` keyword for the increased
  performance this keyword can enable.
- Deprecated `TaintedString` and Taint mode.
- `nimscript` now handles `except Exception as e`.

- The `cstring` doesn't support `[]=` operator in JS backend.

- nil dereference is not allowed at compile time. `cast[ptr int](nil)[]` is rejected at compile time.


## Compiler changes

- Added `--declaredlocs` to show symbol declaration location in messages.

- Source+Edit links now appear on top of every docgen'd page when
  `nim doc --git.url:url ...` is given.

- Added `nim --eval:cmd` to evaluate a command directly, see `nim --help`.

- VM now supports `addr(mystring[ind])` (index + index assignment)
- Type mismatch errors now show more context, use `-d:nimLegacyTypeMismatch` for previous
  behavior.


## Tool changes

- The rst parser now supports markdown table syntax.
  Known limitations:
  - cell alignment is not supported, i.e. alignment annotations in a delimiter
    row (`:---`, `:--:`, `---:`) are ignored,
  - every table row must start with `|`, e.g. `| cell 1 | cell 2 |`.
