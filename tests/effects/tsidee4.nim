discard """
  errormsg: "'noSideEffect' can have side effects"
  file: "tsidee4.nim"
  line: 12
"""

var
  global: int

proc dontcare(x: int): int = return global

proc noSideEffect(x, y: int, p: proc (a: int): int {.noSideEffect.}): int {.noSideEffect.} =
  return x + y + dontcare(x)

echo noSideEffect(1, 3, dontcare) #ERROR_MSG type mismatch
