discard """
  targets: "c js"
  matrix: "; -d:danger" # for stricter tests
"""

import std/[monotimes, times]

# template main =
proc main =
  block:
    let d = initDuration(nanoseconds = 10)
    let t1 = getMonoTime()
    let t2 = t1 + d

    doAssert t2 - t1 == d
    doAssert t1 == t1
    doAssert t1 != t2
    doAssert t2 - d == t1
    doAssert t1 < t2
    doAssert t1 <= t2
    doAssert t1 <= t1
    doAssert not(t2 < t1)
    doAssert t1 < high(MonoTime)
    doAssert low(MonoTime) < t1

  block:
    const n = when defined(js): 20000 else: 1000000 # keep test under ~ 1sec
    var c1 = 0
    var c2 = 0
    for i in 0..<n:
      # this could fail with getTime instead of getMonoTime, as expected
      let a = getMonoTime()
      let b = getMonoTime()
      echo (b - a, a, b)
      if b < a: c1.inc
      if b <= a: c2.inc
      # when defined(windows) and not defined(js):
      #   # bug #18158
      #   doAssert b >= a
      # else:
      #   doAssert b > a
    echo (c1, c2, n)

main()
# static: main() # xxx support
