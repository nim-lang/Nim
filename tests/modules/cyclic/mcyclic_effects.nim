import tcyclic_effects {.cyclic.}

proc fb*(x: int): int {.raises: [].} = fa(x)
proc gb*(): int {.raises: [].} = ga()
