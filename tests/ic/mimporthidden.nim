proc pub*(x: int): int = x + 1

proc secret(): int = 7      # no `*`
proc hiddenToo(x: int): int = x
