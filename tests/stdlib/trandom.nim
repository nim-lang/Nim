discard """
  joinable: false
  targets: "c js"
"""

import std/[random, math, os, stats, sets, tables]

randomize(233)

proc main() =
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


block: # random int
  block: # there might be some randomness
    var set = initHashSet[int](128)

    for i in 1..1000:
      incl(set, rand(high(int)))
    doAssert len(set) == 1000

  block: # single number bounds work
    var rand: int
    for i in 1..1000:
      rand = rand(1000)
      doAssert rand <= 1000
      doAssert rand >= 0

  block: # slice bounds work
    var rand: int
    for i in 1..1000:
      rand = rand(100..1000)
      doAssert rand <= 1000
      doAssert rand >= 100

  block: # again gives new numbers
    var rand1 = rand(1000000)
    when not defined(js):
      os.sleep(200)

    var rand2 = rand(1000000)
    doAssert rand1 != rand2

block: # random float
  block: # there might be some randomness
    var set = initHashSet[float](128)

    for i in 1..100:
      incl(set, rand(1.0))
    doAssert len(set) == 100

  block: # single number bounds work
    var rand: float
    for i in 1..1000:
      rand = rand(1000.0)
      doAssert rand <= 1000.0
      doAssert rand >= 0.0

  block: # slice bounds work
    var rand: float
    for i in 1..1000:
      rand = rand(100.0..1000.0)
      doAssert rand <= 1000.0
      doAssert rand >= 100.0

  block: # again gives new numbers
    var rand1: float = rand(1000000.0)
    when not defined(js):
      os.sleep(200)

    var rand2: float = rand(1000000.0)
    doAssert rand1 != rand2

block: # random sample
  block: # "non-uniform array sample unnormalized int CDF
    let values = [10, 20, 30, 40, 50] # values
    let counts = [4, 3, 2, 1, 0]      # weights aka unnormalized probabilities
    var histo = initCountTable[int]()
    let cdf = counts.cumsummed        # unnormalized CDF
    for i in 0 ..< 5000:
      histo.inc(sample(values, cdf))
    doAssert histo.len == 4              # number of non-zero in `counts`
    # Any one bin is a binomial random var for n samples, each with prob p of
    # adding a count to k; E[k]=p*n, Var k=p*(1-p)*n, approximately Normal for
    # big n.  So, P(abs(k - p*n)/sqrt(p*(1-p)*n))>3.0) =~ 0.0027, while
    # P(wholeTestFails) =~ 1 - P(binPasses)^4 =~ 1 - (1-0.0027)^4 =~ 0.01.
    for i, c in counts:
      if c == 0:
        doAssert values[i] notin histo
        continue
      let p = float(c) / float(cdf[^1])
      let n = 5000.0
      let expected = p * n
      let stdDev = sqrt(n * p * (1.0 - p))
      doAssert abs(float(histo[values[i]]) - expected) <= 3.0 * stdDev

  block: # non-uniform array sample normalized float CDF
    let values = [10, 20, 30, 40, 50]     # values
    let counts = [0.4, 0.3, 0.2, 0.1, 0]  # probabilities
    var histo = initCountTable[int]()
    let cdf = counts.cumsummed            # normalized CDF
    for i in 0 ..< 5000:
      histo.inc(sample(values, cdf))
    doAssert histo.len == 4                  # number of non-zero in ``counts``
    for i, c in counts:
      if c == 0:
        doAssert values[i] notin histo
        continue
      let p = float(c) / float(cdf[^1])
      let n = 5000.0
      let expected = p * n
      let stdDev = sqrt(n * p * (1.0 - p))
      # NOTE: like unnormalized int CDF test, P(wholeTestFails) =~ 0.01.
      doAssert abs(float(histo[values[i]]) - expected) <= 3.0 * stdDev
