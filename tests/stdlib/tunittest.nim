import unittest, sequtils


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

var
  a = 1
  b = -1
  c = 1

#unittests are sequential right now
suite "suite with only teardown":
  teardown:
    b = 2

  test "unittest with only teardown 1":
    check a == c

  test "unittest with only teardown 2":
    check b > a

suite "suite with only setup":
  setup:
    var testVar = "from setup"

  test "unittest with only setup 1":
    check testVar == "from setup"
    check b > a
    b = -1

  test "unittest with only setup 2":
    check b < a

suite "suite with none":
  test "unittest with none":
    check b < a

suite "suite with both":
  setup:
    a = -2

  teardown:
    c = 2

  test "unittest with both 1":
    check b > a

  test "unittest with both 2":
    check c == 2
