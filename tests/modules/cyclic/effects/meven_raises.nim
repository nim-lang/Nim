import ../tunsound_raises {.cyclic.}

proc isEven*(n: int): bool =
  if n < 0: raise newException(ValueError, "neg")
  n == 0 or isOdd(n - 1)
