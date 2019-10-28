# x.x - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library

- `base64.encode` no longer supports `lineLen` and `newLine` use `base64.encodeMIME` instead.
- `os.splitPath()` behavior synchronized with `os.splitFile()` to return "/" as the dir component of "/root_sub_dir" instead of the empty string.


### Breaking changes in the compiler

- Implicit conversions for `const` behave correctly now, meaning that code like `const SOMECONST = 0.int; procThatTakesInt32(SOMECONST)` will be illegal now.
  Simply write `const SOMECONST = 0` instead.


## Library additions

- `macros.newLit` now works for ref object types.
- `system.writeFile` has been overloaded to also support `openarray[byte]`.

## Library changes

- `asyncdispatch.drain` now properly takes into account `selector.hasPendingOperations` and only returns once all pending async operations are guaranteed to have completed.
- `asyncdispatch.drain` now consistently uses the passed timeout value for all iterations of the event loop, and not just the first iteration. This is more consistent with the other asyncdispatch apis, and allows `asyncdispatch.drain` to be more efficient.
- `base64.encode` and `base64.decode` was made faster by about 50%.
- `htmlgen` adds [MathML](https://wikipedia.org/wiki/MathML) support (ISO 40314).

## Language additions



## Language changes

- Unsigned integer operators have been fixed to allow promotion of the first operand.


### Tool changes



### Compiler changes




## Bugfixes

- The `FD` variant of `selector.unregister` for `ioselector_epoll` and `ioselector_select` now properly handle the `Event.User` select event type.
