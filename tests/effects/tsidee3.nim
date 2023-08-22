discard """
  output: "5"
"""

var
  global: int

proc dontcare(x: int): int {.noSideEffect.} = return x

proc noSideEffect(x, y: int, p: proc (a: int): int {.noSideEffect.}): int {.noSideEffect.} =
  return x + y + dontcare(x)

echo noSideEffect(1, 3, dontcare) #OUT 5
