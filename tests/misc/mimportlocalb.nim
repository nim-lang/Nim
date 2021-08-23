proc fn1*(): int = 1
proc fn2*(): int = 2
proc fn4*(): int = 4

proc fn3*(x: int): int = 3
proc fn3*(x: float): float = 3.5

type A1* {.pure.} = enum k0, k1
type A2* {.pure.} = enum k2, k3, k0
type A3* = enum g0, g1, g2
