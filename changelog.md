# x.x - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library

- `base64.encode` no longer supports `lineLen` and `newLine` use `base64.encodeMIME` instead.


### Breaking changes in the compiler

- Implicit conversions for `const` behave correctly now, meaning that code like `const SOMECONST = 0.int; procThatTakesInt32(SOMECONST)` will be illegal now.
  Simply write `const SOMECONST = 0` instead.


## Library additions

- `macros.newLit` now works for ref object types.
- `system.writeFile` has been overloaded to also support `openarray[byte]`.

## Library changes

- `asynchttpserver.processClient` is now exported so that a server may be
  written to capture exceptions yielded by this procedure without leaving
  an event loop.
- `base64.encode` and `base64.decode` was made faster by about 50%.
- `htmlgen` adds [MathML](https://wikipedia.org/wiki/MathML) support (ISO 40314).

## Language additions



## Language changes

- Unsigned integer operators have been fixed to allow promotion of the first operand.


### Tool changes



### Compiler changes




## Bugfixes

