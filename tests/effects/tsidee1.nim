discard """
  file: "tsidee1.nim"
  line: 12
  errormsg: "\'SideEffectLyer\' can have side effects"
"""

var
  global: int

proc dontcare(x: int): int = return x + global

proc SideEffectLyer(x, y: int): int {.noSideEffect.} = #ERROR_MSG 'SideEffectLyer' can have side effects
  return x + y + dontcare(x)

echo SideEffectLyer(1, 3)



