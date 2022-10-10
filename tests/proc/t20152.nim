proc foo() =
  iterator it():int {.closure.} =
    yield 1
  proc useIter() {.nimcall.} =
    var iii = it # <-- illegal capture
    doAssert iii() == 1
  useIter()
foo()