discard """
  matrix: "--parsem:on"
  errormsg: "type mismatch: got <int literal(1), int literal(3), proc (x: int): int{.gcsafe.}>"
  line: 18
"""

# `--parsem:on` variant of tests/effects/tsidee4: the top-level call is checked
# before the body of `noSideEffect`, so its error comes first.

var
  global: int

proc dontcare(x: int): int = return global

proc noSideEffect(x, y: int, p: proc (a: int): int {.noSideEffect.}): int {.noSideEffect.} =
  return x + y + dontcare(x)

echo noSideEffect(1, 3, dontcare) #ERROR_MSG type mismatch
