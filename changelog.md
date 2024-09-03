# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility

- `-d:nimStrictDelete` becomes the default. An index error is produced when the index passed to `system.delete` was out of bounds. Use `-d:nimAuditDelete` to mimic the old behavior for backwards compatibility.
- The default user-agent in `std/httpclient` has been changed to `Nim-httpclient/<version>` instead of `Nim httpclient/<version>` which was incorrect according to the HTTP spec.
- Methods now support implementations based on a VTable by using `--experimental:vtables`. Methods are then confined to be in the same module where their type has been defined.
- With `-d:nimPreviewNonVarDestructor`, non-var destructors become the default.
- A bug where tuple unpacking assignment with a longer tuple on the RHS than the LHS was allowed has been fixed, i.e. code like:
  ```nim
  var a, b: int
  (a, b) = (1, 2, 3, 4)
  ```
  will no longer compile.
- `internalNew` is removed from system, use `new` instead.

- `bindMethod` in `std/jsffi` is deprecated, don't use it with closures.

- JS backend now supports lambda lifting for closures. Use `--legacy:jsNoLambdaLifting` to emulate old behavior.

- `owner` in `std/macros` is deprecated.

- Ambiguous type symbols in generic procs and templates now generate symchoice nodes.
  Previously; in templates they would error immediately at the template definition,
  and in generic procs a type symbol would arbitrarily be captured, losing the
  information of the other symbols. This means that generic code can now give
  errors for ambiguous type symbols, and macros operating on generic proc AST
  may encounter symchoice nodes instead of the arbitrarily resolved type symbol nodes.

- Partial generic instantiation of routines is no longer allowed. Previously
  it compiled in niche situations due to bugs in the compiler.

  ```nim
  proc foo[T, U](x: T, y: U) = echo (x, y)
  proc foo[T, U](x: var T, y: U) = echo "var ", (x, y)

  proc bar[T]() =
    foo[float](1, "abc")

  bar[int]() # before: (1.0, "abc"), now: type mismatch, missing generic parameter
  ```

  As an experimental feature, in situations where generic parameters can be
  inferred from arguments in the call, `auto` can be used in place of
  generic parameters that would be too complex to type normally.

  ```nim
  proc foo[T, U](x: T, y: U) = echo (x, y)
  foo[int, auto](123, ("abc", (false, 1.0))) # (123, ("abc", (false, 1.0)))
  ```

## Standard library additions and changes

[//]: # "Changes:"

- Changed `std/osfiles.copyFile` to allow to specify `bufferSize` instead of a hardcoded one.
- Changed `std/osfiles.copyFile` to use `POSIX_FADV_SEQUENTIAL` hints for kernel-level aggressive sequential read-aheads.
- `std/htmlparser` has been moved to a nimble package, use `nimble` or `atlas` to install it.

[//]: # "Additions:"

- Added `newStringUninit` to system, which creates a new string of length `len` like `newString` but with uninitialized content.
- Added `setLenUninit` to system, which doesn't initialize
slots when enlarging a sequence.
- Added `hasDefaultValue` to `std/typetraits` to check if a type has a valid default value.
- Added Viewport API for the JavaScript targets in the `dom` module.
- Added `toSinglyLinkedRing` and `toDoublyLinkedRing` to `std/lists` to convert from `openArray`s.
- ORC: To be enabled via `nimOrcStats` there is a new API called `GC_orcStats` that can be used to query how many
  objects the cyclic collector did free. If the number is zero that is a strong indicator that you can use `--mm:arc`
  instead of `--mm:orc`.
- A `$` template is provided for `Path` in `std/paths`.
- `std/hashes.hash(x:string)` changed to produce a 64-bit string `Hash` (based
on Google's Farm Hash) which is also often faster than the present one.  Define
`nimStringHash2` to get the old values back.  `--jsbigint=off` mode always only
produces the old values.  This may impact your automated tests if they depend
on hash order in some obvious or indirect way.  Using `sorted` or `OrderedTable`
is often an easy workaround.

[//]: # "Deprecations:"

- Deprecates `system.newSeqUninitialized`, which is replaced by `newSeqUninit`.

[//]: # "Removals:"


## Language changes

- `noInit` can be used in types and fields to disable member initializers in the C++ backend.
- C++ custom constructors initializers see https://nim-lang.org/docs/manual_experimental.html#constructor-initializer
- `member` can be used to attach a procedure to a C++ type.
- C++ `constructor` now reuses `result` instead creating `this`.

- Tuple unpacking changes:
  - Tuple unpacking assignment now supports using underscores to discard values.
    ```nim
    var a, c: int
    (a, _, c) = (1, 2, 3)
    ```
  - Tuple unpacking variable declarations now support type annotations, but
    only for the entire tuple.
    ```nim
    let (a, b): (int, int) = (1, 2)
    let (a, (b, c)): (byte, (float, cstring)) = (1, (2, "abc"))
    ```

- The experimental option `--experimental:openSym` has been added to allow
  captured symbols in generic routine and template bodies respectively to be
  replaced by symbols injected locally by templates/macros at instantiation
  time. `bind` may be used to keep the captured symbols over the injected ones
  regardless of enabling the option, but other methods like renaming the
  captured symbols should be used instead so that the code is not affected by
  context changes.

  Since this change may affect runtime behavior, the experimental switch
  `openSym`, or `genericsOpenSym` and `templateOpenSym` for only the respective
  routines, needs to be enabled; and a warning is given in the case where an
  injected symbol would replace a captured symbol not bound by `bind` and
  the experimental switch isn't enabled.

  ```nim
  const value = "captured"
  template foo(x: int, body: untyped): untyped =
    let value {.inject.} = "injected"
    body

  proc old[T](): string =
    foo(123):
      return value # warning: a new `value` has been injected, use `bind` or turn on `experimental:openSym`
  echo old[int]() # "captured"

  template oldTempl(): string =
    block:
      foo(123):
        value # warning: a new `value` has been injected, use `bind` or turn on `experimental:openSym`
  echo oldTempl() # "captured"

  {.experimental: "openSym".} # or {.experimental: "genericsOpenSym".} for just generic procs

  proc bar[T](): string =
    foo(123):
      return value
  assert bar[int]() == "injected" # previously it would be "captured"

  proc baz[T](): string =
    bind value
    foo(123):
      return value
  assert baz[int]() == "captured"

  # {.experimental: "templateOpenSym".} would be needed here if genericsOpenSym was used

  template barTempl(): string =
    block:
      foo(123):
        value
  assert barTempl() == "injected" # previously it would be "captured"

  template bazTempl(): string =
    bind value
    block:
      foo(123):
        value
  assert bazTempl() == "captured"
  ```

  This option also generates a new node kind `nnkOpenSym` which contains
  exactly 1 `nnkSym` node. In the future this might be merged with a slightly
  modified `nnkOpenSymChoice` node but macros that want to support the
  experimental feature should still handle `nnkOpenSym`, as the node kind would
  simply not be generated as opposed to being removed.

## Compiler changes

- `--nimcache` using a relative path as the argument in a config file is now relative to the config file instead of the current directory.

## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

