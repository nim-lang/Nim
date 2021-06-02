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

  block:
    const n = when defined(js): 20000 else: 1000000 # keep test under ~ 1sec
    for i in 0..<n:
      # this could fail with getTime instead of getMonoTime, as expected
      let a = getMonoTime()
      let b = getMonoTime()
      when not defined(js) and ((defined(linux) and int.sizeof == 8) or defined(windows)):
        # xxx pending bug #18158
        doAssert b >= a
      else:
        doAssert b > a

main()
# static: main() # xxx support
