discard """
  cmd: "nim $target $options --excessiveStackTrace:off $file"
"""

import std/stackframes

const expected = """
tstackframes.nim(50)     tstackframes
tstackframes.nim(41)     main ("main",)
tstackframes.nim(35)     main2 ("main2", 5, 1)
tstackframes.nim(35)     main2 ("main2", 4, 2)
tstackframes.nim(35)     main2 ("main2", 3, 3)
tstackframes.nim(34)     main2 ("main2", 2, 4)
tstackframes.nim(33)     bar ("bar ",)
"""




# line 20
var count = 0

proc main1(n: int) =
  setFrameMsg $("main1", n)
  if n > 0:
    main1(n-1)

proc main2(n: int) =
  count.inc
  setFrameMsg $("main2", n, count)
  proc bar() =
    setFrameMsg $("bar ",)
    if n < 3: raise newException(CatchableError, "on purpose")
  bar()
  main2(n-1)

import strutils
proc main() =
  setFrameMsg $("main", )
  try:
    main2(5)
  except CatchableError:
    main1(10) # goes deep and then unwinds; sanity check to ensure `setFrameMsg` from inside
              # `main1` won't invalidate the stacktrace; if StackTraceEntry.frameMsg
              # were a reference instead of a copy, this would fail.
    let e = getCurrentException()
    let trace = e.getStackTrace
    doAssert trace.startsWith(expected), "\n" & trace

main()
