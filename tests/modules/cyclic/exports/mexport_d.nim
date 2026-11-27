import mexport_b {.cyclic.}

proc fd*(): int = fb(4) + 1
proc hidden*(): int = 0
