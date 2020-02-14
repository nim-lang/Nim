discard """
  cmd: "nim $target -d:danger -r $file"
  targets: "c cpp js"
  joinable: false
  timeout: 100.0
"""

## performance regression tests, refs: #13393 and #11764
## this takes into account insertion/retrieval time, plus time to compute hashes
## in various input distributions to ensure we have both high quality hashes
## (few collisions) as well as speedy hash computations.
## We run this benchmark on: c, cpp, js, vm targets to ensure all cases are
## covered.
##
## The spec timeout is a very generous upperbound; it's needed just in case
## a regression causes CI to take forever on this test.

import times, tables

proc toInt64(a: int): int64 = cast[int64](a)
proc toInt32(a: int): int32 = cast[int32](a)
proc toHighOrderBits(a: int): uint64 =
  result = cast[uint64](a) shl 32

proc toSmallFloat(a: int): float =
  result = a.float*1e-20

# block ttables_perf:
template fun() =
  proc TestHashIntInt[Fun](fun: Fun) =
    type T = type(fun(1))
    var tab = initTable[T, string]()
    const n = 100_000 # use that
    for i in 1..n:
      let h = fun(i)
      doAssert h notin tab
      tab[h] = $i
      doAssert tab[h] == $i

  proc runTimingImpl[Fun](fun: Fun, name: string, timeout: float) =
    ## return elapsed time in seconds
    type T = type(fun(1))
    echo "perf test begin: T=" & $T & " " & name

    template epochTime2(): untyped =
      when nimvm: 0.0 # epochTime not defined in vm
      else: times.epochTime()

    let eTime1 = epochTime2()

    var numIter = 50
    when defined(js): numIter = 10
    when nimvm: numIter = 1
    else: discard

    for i in 1 .. numIter:
      TestHashIntInt(fun)
    let eTime2 = epochTime2()
    let runtime = eTime2 - eTime1
    echo "pref test done: runtime: ", runtime, " timeout: ", timeout
    doAssert runtime < timeout # performance regression check, don't make it too tight for CI

  template runTiming(fun, timout) = runTimingImpl(fun, astToStr(fun), timout)
  # leaving some large buffer for timing, but not too much to catch performance regressions
  let timeouts = when defined(js): [8.0, 8.0, 8.0] else: [4.0, 3.0, 5.0]
  # on my local OSX machine I get: [1.44, 0.85, 1.2316, 1.38] for `nim c` and ~1.8 for `nim js`
  # azure CI OSX I get: [2.8, 1.5, 2.98] for `nim c`

  runTiming toInt64, timeouts[0]
  runTiming toInt32, timeouts[1]
  runTiming toHighOrderBits, timeouts[2]
  when false: # disabled to save CI time but easy to turn back on for deubugging
    runTiming toSmallFloat, 3.0

when defined(c) or defined(js): # skip cpp (a bit redundant with c in this case)
  static: fun()
fun()
