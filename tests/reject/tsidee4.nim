discard """
  file: "tsidee4.nim"
  line: 15
  errormsg: "type mismatch"
"""

var
  global: int

proc dontcare(x: int): int = return x

proc noSideEffect(x, y: int, p: proc (a: int): int {.noSideEffect.}): int {.noSideEffect.} = 
  return x + y + dontcare(x)
  
echo noSideEffect(1, 3, dontcare) #ERROR_MSG type mismatch


