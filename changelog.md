# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility



## Standard library additions and changes

- Added `sugar.debugs` debug helper that injects debugging code in-between a block of code with given frequency.


## Language changes



## Compiler changes

- `nim` can now compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`,
  without requiring `-d:nimVersion140` which is now a noop.


## Tool changes



