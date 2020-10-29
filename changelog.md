# v1.6.x - yyyy-mm-dd



## Standard library additions and changes

- `prelude` now works with the JavaScript target.

- Added `ioutils` module containing `duplicate` and `duplicateTo` to duplicate `FileHandle` using C function `dup` and `dup2`.

- The JSON module can now handle integer literals and floating point literals of arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are kept as string literals and
  one can use external BigNum libraries to handle these. The `parseFloat` family of functions also has now optional
  `rawIntegers` and `rawFloats` parameters that can be used to enforce that all integer or float literals remain
  in the "raw" string form so that client code can easily treat small and large numbers uniformly.

- Added `randState` template that exposes the default random number generator. Useful for library authors.

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
- Removed `ospaths` module, was deprecated since `0.19`, use `os` instead.
- Removed `sharedlists.initSharedList`, was deprecated and produces undefined behaviour.

- There is a new experimental feature called "strictFuncs" which makes the definition of
  `.noSideEffect` stricter. [See](manual_experimental.html#stricts-funcs)
  for more information.

- "for-loop macros" (see [the manual](manual.html#macros-for-loop-macros)) are no longer
  an experimental feature. In other words, you don't have to write pragma
  `{.experimental: "forLoopMacros".}` if you want to use them.

- Added a ``.noalias`` pragma. It is mapped to C's ``restrict`` keyword for the increased
  performance this keyword can enable.

- `items` no longer compiles with enum with holes as its behavior was error prone, see #14004
- `system.deepcopy` has to be enabled explicitly for `--gc:arc` and `--gc:orc` via
  `--deepcopy:on`.

- Remove `sharedlists.initSharedList`, was deprecated and produces undefined behaviour.
- Removed `ospaths` module, was deprecated since `0.19`, use `os` instead.
- Added a `std/effecttraits` module for introspection of the inferred effects.
  We hope this enables `async` macros that are precise about the possible exceptions that
  can be raised.
- The pragma blocks `{.gcsafe.}: ...` and `{.noSideEffect.}: ...` can now also be
  written as `{.cast(gcsafe).}: ...` and `{.cast(noSideEffect).}: ...`. This is the new
  preferred way of writing these, emphasizing their unsafe nature.


## Compiler changes

- Added `--declaredlocs` to show symbol declaration location in messages.
- Source+Edit links now appear on top of every docgen'd page when `nim doc --git.url:url ...` is given.


## Tool changes
