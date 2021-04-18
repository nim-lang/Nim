discard """
  targets: "c js"
"""

import std/[monotimes, times]

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
