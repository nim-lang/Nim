# v1.6.x - yyyy-mm-dd



## Standard library additions and changes

- `prelude` now works with the JavaScript target.

- Added `ioutils` module containing `duplicate` and `duplicateTo` to duplicate `FileHandle` using C function `dup` and `dup2`.

- Added `parseEnumRange` to `strutils` module parse enum but considering only range of enum values. Used in compiler internals.

## Language changes



## Compiler changes

- Added `--declaredlocs` to show symbol declaration location in messages.
- Source+Edit links now appear on top of every docgen'd page when `nim doc --git.url:url ...` is given.


## Tool changes
