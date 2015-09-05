import strutils, os, pegs, strtabs, math, threadpool, times

proc fakeCppDep(x: ptr float) {.importcpp: "fakeCppDep", header: "<vector>".}
proc fakeTimeDep() = echo(times.getDateStr())
proc fakedeps() =
  var x = 0.4
  {.emit: "#if 0\n".}
  fakeCppDep(addr x)
  {.emit: "#endif\n".}

  # this is not true:
  if math.sin(x) > 0.6:
    spawn(fakeTimeDep())

proc main =
  fakedeps()
when isMainModule:
  main()
