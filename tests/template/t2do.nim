discard """
  output: "8.0"
"""

# bug #2057

proc mpf_get_d(x: int): float = float(x)
proc mpf_cmp_d(a: int; b: float): int = 0

template toFloatHelper(result: expr; tooSmall, tooLarge: stmt) {.immediate.} =
  result = mpf_get_d(a)
  if result == 0.0 and mpf_cmp_d(a,0.0) != 0:
    tooSmall
  if result == Inf:
    tooLarge

proc toFloat*(a: int): float =
  toFloatHelper(result)
    do: raise newException(ValueError, "number too small"):
        raise newException(ValueError, "number too large")

echo toFloat(8)
