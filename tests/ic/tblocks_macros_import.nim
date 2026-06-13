# test imported macros
import mmacros

exportedMacro:
  const Test0 = 777
assert Test0 == 777

block:
  exportedMacro:
    let x = 123
  assert x == 123

exportedMacroWithBlock:
  const Test1 = 321
assert Test1 == 321
