# x.x - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library



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

- Fixed "`writeFile` and `write(f, str)` skip null bytes on Windows" ([#12315](https://github.com/nim-lang/Nim/issues/12315))
