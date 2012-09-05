import math
import unittest
import sets

suite "random int":
  test "there might be some randomness":
    var set = initSet[int](128)
    for i in 1..10:
      for j in 1..10:
        randomize()
        incl(set, random(high(int)))
    check len(set) == 100
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
  # Enable this once #197 has been resolved
  # test "there might be some randomness":
  #   var set = initSet[float](128)
  #   for i in 1..10:
  #     for j in 1..10:
  #       randomize()
  #       incl(set, random(1.0))
  #   check len(set) == 100
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
