discard """
  targets: "c js"
"""

import std/[monotimes, times]

template main =
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

  block: # getMonoTime is non-decreasing
    let a = getMonoTime()
    let b = getMonoTime()
    doAssert b >= a

main()
# static: main() # xxx support
