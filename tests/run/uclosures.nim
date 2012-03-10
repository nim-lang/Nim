import unittest

test "loop variables are captured by copy":
  var funcs: seq[proc (): int {.closure.}] = @[]
  
  for i in 0..10:
    funcs.add do -> int: return i * i

  check funcs[0]() == 0
  check funcs[3]() == 9

