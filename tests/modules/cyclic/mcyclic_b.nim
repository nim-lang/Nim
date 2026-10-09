import tcyclic_a {.cyclic.}

type
  B* = object
    x*: int
    a*: ref A  # refers to a type the partner declares after its import

proc fromB*(): int = 2

proc takeA*(a: A): int = a.b.x - 1
