discard """
  matrix: "--parsem:on"
  errormsg: "b(7) can raise an unlisted exception: ref ValueError"
  line: 19
"""

# Mutual recursion without forward declarations: `a` and `b` need each
# other's effects. Whichever of the two is checked first sees the other's
# effects only as far as they are known at that moment; the exception that
# `a` raises must reach `b` all the same, whichever one that is.

proc a(x: int) =
  if x == 5: raise newException(ValueError, "x")
  if x > 0: b(x - 1)

proc b(x: int) =
  a(x)

proc c() {.raises: [].} = b(7)
