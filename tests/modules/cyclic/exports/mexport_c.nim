import mexport_a {.cyclic.}

type C* = object
  x*: int
proc fc*(): int = fa() + 3
