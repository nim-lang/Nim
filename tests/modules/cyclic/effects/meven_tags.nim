import ../tunsound_tags {.cyclic.}

proc isEven*(n: int): bool =
  if n == 0:
    stdout.write "io\n"
    return true
  isOdd(n - 1)
