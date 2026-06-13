# test imported macros
import mmacros

block:
  exportedMacro:
    let x = 123
  assert x == 123
