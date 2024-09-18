# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility

- `-d:nimStrictDelete` becomes the default. An index error is produced when the index passed to `system.delete` was out of bounds. Use `-d:nimAuditDelete` to mimic the old behavior for backwards compatibility.
- The default user-agent in `std/httpclient` has been changed to `Nim-httpclient/<version>` instead of `Nim httpclient/<version>` which was incorrect according to the HTTP spec.
- With `-d:nimPreviewNonVarDestructor`, non-var destructors become the default.

## Standard library additions and changes

[//]: # "Changes:"


[//]: # "Additions:"

- Added `newStringUninit` to system, which creates a new string of length `len` like `newString` but with uninitialized content.
- Added `setLenUninit` to system, which doesn't initalize
slots when enlarging a sequence.
- Added `hasDefaultValue` to `std/typetraits` to check if a type has a valid default value.
- Added Viewport API for the JavaScript targets in the `dom` module.

[//]: # "Deprecations:"


[//]: # "Removals:"


## Language changes



- The experimental option `--experimental:openSym` has been added to allow
  captured symbols in generic routine and template bodies respectively to be
  replaced by symbols injected locally by templates/macros at instantiation
  time. `bind` may be used to keep the captured symbols over the injected ones
  regardless of enabling the option, but other methods like renaming the
  captured symbols should be used instead so that the code is not affected by
  context changes.

  Since this change may affect runtime behavior, the experimental switch
  `openSym` needs to be enabled; and a warning is given in the case where an
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

  {.experimental: "openSym".}

  proc bar[T](): string =
    foo(123):
      return value
  assert bar[int]() == "injected" # previously it would be "captured"

  proc baz[T](): string =
    bind value
    foo(123):
      return value
  assert baz[int]() == "captured"

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

  Another experimental switch `genericsOpenSym` exists that enables this behavior
  at instantiation time, meaning templates etc can enable it specifically when
  they are being called. However this does not generate `nnkOpenSym` nodes
  (unless the other switch is enabled) and so doesn't reflect the regular
  behavior of the switch.

  ```nim
  const value = "captured"
  template foo(x: int, body: untyped): untyped =
    let value {.inject.} = "injected"
    {.push experimental: "genericsOpenSym".}
    body
    {.pop.}

  proc bar[T](): string =
    foo(123):
      return value
  echo bar[int]() # "injected"

  template barTempl(): string =
    block:
      var res: string
      foo(123):
        res = value
      res
  assert barTempl() == "injected"
  ```

## Compiler changes


## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

