discard """
  outputsub: "no leak: "
"""

## this test makes sure getOccupiedMem() is constant after a few iterations
## for --gc:bohem, --gc:markAndSweep, --gc:arc, --gc:orc.
## and for other gc, it consists of cycles with constant min/max after a few cycles.
## This ensures we have no leaks.

when defined(GC_setMaxPause):
  GC_setMaxPause 2_000

type
  TTestObj = object of RootObj
    x: string
    s: seq[int]

proc makeObj(): TTestObj =
  result.x = "Hello"
  result.s = @[1,2,3]

const collectAlways = defined(gcMarkAndSweep) or defined(boehmgc)
const isDeterministic = collectAlways or defined(gcArc) or defined(gcOrc)
  ## when isDeterministic, we expect memory to reach a fixed point
  ## after `numIterStable` iterations

var memMax = 0 # peak

when isDeterministic:
  const numIterStable = 3
    # stabilize after this many iterations
else:
  const numCycleStable = when defined(useRealtimeGC): 6 else: 4
    # stabilize after this many cycles; empirically determined
    # after running all combinations of gc's with / without -d:release
  var memPrevious = 0
  var memMin = int.high # right after a peak
  var numCollections = 0

let numIter = when isDeterministic: 1_000 else: 1_000_000
  ## full collection is expensive, and the memory doesn't change after
  ## each iteration so there's no point in a large `numIter` (this was taking
  ## 350s for `nim c -r -d:release --gc:boehm` + `nim c -r --gc:boehm`, 50%
  ## of running time of `testament/testament all`.

proc inProc() =
  for i in 1 .. numIter:
    when collectAlways: GC_fullcollect()
    var obj: TTestObj
    obj = makeObj()
    let mem = getOccupiedMem()
    when isDeterministic:
      if i <= numIterStable:
        memMax = mem
        doAssert memMax <= 50_000 # adjust as needed
      else:
        # memory shouldn't increase after 1st few iterations
        # on linux 386 it somehow takes 3 iters to converge
        doAssert mem <= memMax
    else:
      if mem < memPrevious:
        # a collection happened, it peaked at memPrevious
        # echo (mem, memMin, memMax, numCollections, numIter, i) # for debugging
        numCollections.inc
        if numCollections <= numCycleStable:
          # this is the 1st few collections, we update the min/max
          doAssert memPrevious < 300_000 # adjust as needed
          if memMin < mem: # `<` intentional; the valley may increase 
            memMin = mem
          if memMax < memPrevious:
            memMax = memPrevious
        else:
          # after a collection, we always go back to same level
          doAssert mem <= memMin, $(mem, memMin)

      if numCollections >= numCycleStable:
        # after a few cycles, the max stabilizes
        doAssert mem <= memMax, $(mem, memMax)

      memPrevious = mem

inProc()
let mem = getOccupiedMem()
var msg = "no leak: "
when isDeterministic:
  msg.add $(mem, memMax)
  echo msg
else:
  msg.add $(mem, memMin, memMax, numCollections, numIter)
  echo msg
  # make sure some collections did happen, otherwise the previous tests
  # are meaningless
  doAssert numCollections > 1000 # 3999 on local OSX; leaving some slack
