discard """
  output: "could not import: foo"
  exitcode: 1
"""

const LibName {.used.} =
  when defined(windows):
    "visibility.dll"
  elif defined(macosx):
    "libvisibility.dylib"
  else:
    "libvisibility.so"

when compileOption("app", "lib"):
  proc foo() {.exportc.} =
    echo "failed"
elif isMainModule:
  proc foo() {.importc, dynlib: LibName.}
  foo()
