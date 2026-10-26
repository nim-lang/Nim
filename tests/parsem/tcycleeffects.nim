discard """
  matrix: "--parsem:on"
  output: '''
true -1
'''
"""

# The effects of mutually recursive routines without forward declarations are
# the least solution: what each would have if the others' effects were known
# up front, not the worst case.

proc isEven(n: int): bool =
  if n == 0: true else: isOdd(n - 1)

proc isOdd(n: int): bool =
  if n == 0: false else: isEven(n - 1)

proc pure() {.raises: [], gcsafe, noSideEffect.} =
  discard isEven(10)

# A cycle with an edge inside `try`: what `parseA` raises is caught on the way
# back, so `parseB` raises nothing, and neither does anything only calling it.

proc parseA(x: int): int =
  if x == 1: raise newException(ValueError, "one")
  result = parseB(x - 1)

proc parseB(x: int): int =
  if x <= 0: return 0
  try:
    result = parseA(x)
  except ValueError:
    result = -1

proc useB(): int {.raises: [].} = parseB(3)

pure()
echo isEven(10), " ", useB()
