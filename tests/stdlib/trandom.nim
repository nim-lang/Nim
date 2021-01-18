discard """
  joinable: false
  targets: "c js"
"""

import std/[random, stats]

randomize(233)

proc main =
  var occur: array[1000, int]

  for i in 0..100_000:
    let x = rand(high(occur))
    inc occur[x]

  doAssert max(occur) <= 140 and min(occur) >= 60 # gives some slack

  var a = [0, 1]
  shuffle(a)
  doAssert a in [[0,1], [1,0]]

  doAssert rand(0) == 0
  doAssert sample("a") == 'a'

  when compileOption("rangeChecks"):
    doAssertRaises(RangeDefect):
      discard rand(-1)

    doAssertRaises(RangeDefect):
      discard rand(-1.0)

  # don't use causes integer overflow
  doAssert compiles(rand[int](low(int) .. high(int)))


main()

import math

block:
  when not defined(js):
    doAssert almostEqual(rand(12.5), 4.012897747078944)
    doAssert almostEqual(rand(2233.3322), 879.702755321298)

  type DiceRoll = range[0..6]
  doAssert rand(DiceRoll).int == 4

var rs: RunningStat
for j in 1..5:
  for i in 1 .. 100_000:
    rs.push(gauss())
  doAssert abs(rs.mean-0) < 0.08, $rs.mean
  doAssert abs(rs.standardDeviation()-1.0) < 0.1
  let bounds = [3.5, 5.0]
  for a in [rs.max, -rs.min]:
    doAssert a >= bounds[0] and a <= bounds[1]
  rs.clear()

block:
  type DiceRoll = range[3..6]
  var flag = false
  for i in 0..<100:
    if rand(5.DiceRoll) < 3:
      flag = true
  doAssert flag # because of: rand(max: int): int
