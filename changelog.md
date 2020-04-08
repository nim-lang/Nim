# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes


## Language changes


## Compiler changes

- Specific warnings can now be turned into errors via `--warningAsError[X]:on|off`.
- The `define` and `undef` pragmas have been de-deprecated.
- JavaScript backend adds compile-time optional `let` variable declarations,
  compile Nim with `-d:nimJsVar` for `var` and without for `let`,
  for a transition period, for more information see https://caniuse.com/let

## Tool changes

