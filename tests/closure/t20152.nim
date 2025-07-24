discard """
  action: compile
"""

proc foo() =
  iterator it():int {.closure.} =
    yield 1
  proc useIter() {.nimcall.} =
    var iii = it # <-- illegal capture
    doAssert iii() == 1
  useIter()
foo()

proc foo2() =
  proc bar() = # Local function, but not a closure, because no captures
    echo "hi"
  proc baz() {.nimcall.} = # Calls local function
    bar()
  baz()
foo2()
