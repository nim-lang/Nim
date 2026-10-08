import tcyclic_effects {.cyclic.}

proc fb*(x: int): int = fa(x)
proc gb*(): int {.raises: [].} = ga()
