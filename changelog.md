# x.x - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library

- `asyncdispatch.drain` now properly takes into account `selector.hasPendingOperations` and only returns once all pending async operations are guaranteed to have completed.
- `asyncdispatch.drain` now consistently uses the passed timeout value for all iterations of the event loop, and not just the first iteration. This is more consistent with the other asyncdispatch apis, and allows `asyncdispatch.drain` to be more efficient.


### Breaking changes in the compiler

- Implicit conversions for `const` behave correctly now, meaning that code like `const SOMECONST = 0.int; procThatTakesInt32(SOMECONST)` will be illegal now.
  Simply write `const SOMECONST = 0` instead.


## Library additions

- `macros.newLit` now works for ref object types.
- `system.writeFile` has been overloaded to also support `openarray[byte]`.

## Library changes



## Language additions



## Language changes



### Tool changes



### Compiler changes




## Bugfixes

- The `FD` variant of `selector.unregister` for `ioselector_epoll` and `ioselector_select` now properly handle the `Event.User` select event type.
