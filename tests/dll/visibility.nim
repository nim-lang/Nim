discard """
  output: ""
"""

const LibName {.used.} =
  when defined(windows):
    "visibility.dll"
  elif defined(macosx):
    "libvisibility.dylib"
  else:
    "libvisibility.so"

when compileOption("app", "lib"):
  var
    bar {.exportc.}: int
    thr {.exportc, threadvar.}: int
  proc foo() {.exportc.} = discard

  var
    exported {.exportc, dynlib.}: int
    exported_thr {.exportc, threadvar, dynlib.}: int
  proc exported_func() {.exportc, dynlib.} = discard
elif isMainModule:
  import dynlib

  let handle = loadLib(LibName)

  template check(sym: untyped) =
    const s = astToStr(sym)
    if handle.symAddr(s) != nil:
      echo s, " is exported"
  template checkE(sym: untyped) =
    const s = astToStr(sym)
    if handle.symAddr(s) == nil:
      echo s, " is not exported"

  check foo
  check bar
  check thr

  checkE exported
  checkE exported_thr
  checkE exported_func
