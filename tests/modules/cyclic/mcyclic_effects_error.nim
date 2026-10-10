import tcyclic_effects_error {.cyclic.}

proc fb*(x: int): int =
  if x == 1: raise newException(ValueError, "boom")
  fa(x)
