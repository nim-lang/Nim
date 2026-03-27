import tcyclicimports_proc

proc b*(x: int): int =
  if x <= 0:
    0
  else:
    a(x - 1)
