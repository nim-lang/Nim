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
  test "randomize() again gives new numbers":
    randomize()
    var rand1 = random(1000000)
    randomize()
    var rand2 = random(1000000)
    check rand1 != rand2


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
  test "randomize() again gives new numbers":
    randomize()
    var rand1:float = random(1000000.0)
    randomize()
    var rand2:float = random(1000000.0)
    check rand1 != rand2

