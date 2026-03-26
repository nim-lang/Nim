import tcyclicimports_noreorder

proc b*(x: int): int =
  a(x - 1)
