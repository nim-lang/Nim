# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility


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



- An experimental option `genericsOpenSym` has been added to allow captured
  symbols in generic routine bodies to be replaced by symbols injected locally
  by templates/macros at instantiation time. `bind` may be used to keep the
  captured symbols over the injected ones regardless of enabling the option.

  Since this change may affect runtime behavior, the experimental switch
  `genericsOpenSym` needs to be enabled, and a warning is given in the case
  where an injected symbol would replace a captured symbol not bound by `bind`
  and the experimental switch isn't enabled.

  ```nim
  const value = "captured"
  template foo(x: int, body: untyped) =
    let value {.inject.} = "injected"
    body

  proc old[T](): string =
    foo(123):
      return value # warning: a new `value` has been injected, use `bind` or turn on `experimental:genericsOpenSym`
  echo old[int]() # "captured"

  {.experimental: "genericsOpenSym".}

  proc bar[T](): string =
    foo(123):
      return value
  assert bar[int]() == "injected" # previously it would be "captured"

  proc baz[T](): string =
    bind value
    foo(123):
      return value
  assert baz[int]() == "captured"
  ```

## Compiler changes


## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

