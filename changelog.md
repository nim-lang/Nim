# v1.1 - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library



### Breaking changes in the compiler

- Implicit conversions for `const` behave correctly now, meaning that code like `const SOMECONST = 0.int; procThatTakesInt32(SOMECONST)` will be illegal now.
  Simply write `const SOMECONST = 0` instead.


## Library additions



## Library changes



## Language additions



## Language changes



### Tool changes



### Compiler changes




## Bugfixes
