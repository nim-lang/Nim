import unittest


proc doThings(spuds: var int): int =
  spuds = 24
  return 99
test "#964":
  var spuds = 0
  check doThings(spuds) == 99
  check spuds == 24


from strutils import toUpper
test "#1384":
  check(@["hello", "world"].map(toUpper) == @["HELLO", "WORLD"])


import options
test "unittest typedescs":
  check(none(int) == none(int))
  check(none(int) != some(1))


test "unittest multiple requires":
  require(true)
  require(true)


import math
from strutils import parseInt
proc defectiveRobot() =
  randomize()
  case random(1..4)
  of 1: raise newException(OSError, "CANNOT COMPUTE!")
  of 2: discard parseInt("Hello World!")
  of 3: raise newException(IOError, "I can't do that Dave.")
  else: assert 2 + 2 == 5
test "unittest expect":
  expect IOError, OSError, ValueError, AssertionError:
    defectiveRobot()
