import math
import unittest
import sets

suite "random int":
  test "there might be some randomness":
    var set = initSet[int](128)
    randomize()
    for i in 1..1000:
      incl(set, random(high(int)))
    check len(set) == 1000
  test "single number bounds work":
    randomize()
    var rand: int
    for i in 1..1000:
      rand = random(1000)
      check rand < 1000
      check rand > -1
  test "slice bounds work":
    randomize()
    var rand: int
    for i in 1..1000:
      rand = random(100..1000)
      check rand < 1000
      check rand >= 100

suite "random float":
  test "there might be some randomness":
    var set = initSet[float](128)
    randomize()
    for i in 1..100:
      incl(set, random(1.0))
    check len(set) == 100
  test "single number bounds work":
    randomize()
    var rand: float
    for i in 1..1000:
      rand = random(1000.0)
      check rand < 1000.0
      check rand > -1.0
  test "slice bounds work":
    randomize()
    var rand: float
    for i in 1..1000:
      rand = random(100.0..1000.0)
      check rand < 1000.0
      check rand >= 100.0

when not defined(NimrodVM) and not defined(ECMAScript):
  suite "float checks":
    var DBL_MIN {.importc, header: "<math.h>", noinit.}: float
    test "floatCheck":
      check:
        floatCheck(DBL_MIN/10) == Subnormal
        floatCheck(0.0) == Zero
        floatCheck(1/0.0) == Infinite
        floatCheck(0.0/0.0) == NotANumber
        floatCheck(1.0) == Normal

    test "the various shortcuts":
      check:
        isSub(DBL_MIN/10) == true
        isZero(DBL_MIN/10) == false
        isZero(0.0) == true
        isInf(1/0.0) == true
        isNaN(0.0/0.0) == true
