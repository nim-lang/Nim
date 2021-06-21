import std/stackframes



# line 5
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

proc main() =
  var z = 0
  setFrameMsg "\n  z: " & $z, prefix = ""
  # multiple calls inside a frame are possible
  z.inc
  setFrameMsg "\n  z: " & $z, prefix = ""
  try:
    main2(5)
  except CatchableError:
    main1(10) # goes deep and then unwinds; sanity check to ensure `setFrameMsg` from inside
              # `main1` won't invalidate the stacktrace; if StackTraceEntry.frameMsg
              # were a reference instead of a copy, this would fail.
    let e = getCurrentException()
    let trace = e.getStackTrace
    echo trace

main()
