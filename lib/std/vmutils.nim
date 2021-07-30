##[
Experimental API, subject to change.
]##

proc vmTrace*(on: bool) {.compileTime.} =
  runnableExamples:
    static: vmTrace(true)
    proc fn =
      var a = 1
      vmTrace(false)
    static: fn()

proc debugNimNode*(a: NimNode): string =
  ## Implementation-specific rendering of `a` in the compiler, unstable.
  # This is a vmops, see implementation in `astalgo.debugNimNodeImpl`.
  runnableExamples:
    import std/[macros, strutils]
    macro dbg1(a: auto): string =
      newLit(debugNimNode(a))
    macro dbg2(a): string =
      newLit(debugNimNode(a))
    assert "nfSem" in dbg1(1+2)
    assert "nfSem" notin dbg2(1+2)
