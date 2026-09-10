proc u(k: static int) =
  proc r(_: static int) =
    while k > 0:
      discard
  r(0)

u(0)
