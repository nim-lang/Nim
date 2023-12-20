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

## Standard library additions and changes

[//]: # "Changes:"

- Changed `std/osfiles.copyFile` to allow to specify `bufferSize` instead of a hardcoded one.
- Changed `std/osfiles.copyFile` to use `POSIX_FADV_SEQUENTIAL` hints for kernel-level aggressive sequential read-aheads.
- `std/htmlparser` has been moved to a nimble package, use `nimble` or `atlas` to install it.

[//]: # "Additions:"

- Added `newStringUninit` to system, which creates a new string of length `len` like `newString` but with uninitialized content.
- Added `setLenUninit` to system, which doesn't initalize
slots when enlarging a sequence.
- Added `hasDefaultValue` to `std/typetraits` to check if a type has a valid default value.
- Added Viewport API for the JavaScript targets in the `dom` module.

[//]: # "Deprecations:"

- Deprecates `system.newSeqUninitialized`, which is replaced by `newSeqUninit`.

[//]: # "Removals:"


## Language changes

- `noInit` can be used in types and fields to disable member initializers in the C++ backend. 
- C++ custom constructors initializers see https://nim-lang.org/docs/manual_experimental.htm#constructor-initializer
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

- `--nimcache` using a relative path as the argument in a config file is now relative to the config file instead of the current directory.

## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

