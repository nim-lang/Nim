import tcyclic_procs {.cyclic.}

type
  B* = object
  Color* {.pure.} = enum
    light, dark

converter toFloat*(c: Celsius): float = float(c)

proc fromB*(): int = 2

proc useA*(): int = fromA()

proc isOdd*(n: int): bool =
  if n == 0: false else: isEven(n - 1)

proc factB*(n: int): int = fact(n)

proc truncInt*(x: float): int = int(x)

proc shade*(): string = $Color.dark
