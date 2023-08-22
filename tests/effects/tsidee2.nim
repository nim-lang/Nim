discard """
  output: "5"
"""

var
  global: int

proc dontcare(x: int): int = return x

proc SideEffectLyer(x, y: int): int {.noSideEffect.} =
  return x + y + dontcare(x)

echo SideEffectLyer(1, 3) #OUT 5
