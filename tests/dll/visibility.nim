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
  var bar {.exportc.}: int
  proc foo() {.exportc.} =
    echo "failed"
elif isMainModule:
  import dynlib

  let handle = loadLib(LibName)

  template check(sym: untyped) =
    const s = astToStr(sym)
    if handle.symAddr(s) != nil:
      echo s, " is exported"

  check foo
  check bar
