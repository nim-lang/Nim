# test variables of type proc

import
  io

var
  x: proc (a, b: int): int {.cdecl.}

proc ha(c, d: int): int {.cdecl.} =
  echo(c + d)
  result = c + d

x = ha
discard x(3, 4)

#OUT 7

