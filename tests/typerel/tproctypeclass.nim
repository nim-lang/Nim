import std/assertions

proc main =
  iterator closureIter(): int {.closure.} =
    yield 1
    yield 2
  iterator inlineIter(): int {.inline.} =
    yield 1
    yield 2
  proc procNotIter(): int = 1

  doAssert closureIter is iterator
  doAssert inlineIter is iterator
  doAssert procNotIter isnot iterator

  doAssert closureIter isnot proc
  doAssert inlineIter isnot proc
  doAssert procNotIter is proc

  doAssert typeof(closureIter) is iterator
  doAssert typeof(inlineIter) is iterator
  doAssert typeof(procNotIter) isnot iterator

  doAssert typeof(closureIter) isnot proc
  doAssert typeof(inlineIter) isnot proc
  doAssert typeof(procNotIter) is proc

  block:
    proc fn1(iter: iterator {.closure.}) = discard
    proc fn2[T: iterator {.closure.}](iter: T) = discard

    fn1(closureIter)
    fn2(closureIter)

    doAssert not compiles(fn1(procNotIter))
    doAssert not compiles(fn2(procNotIter))

    doAssert not compiles(fn1(inlineIter))
    doAssert not compiles(fn2(inlineIter))

  block: # concrete iterator type
    proc fn1(iter: iterator(): int) = discard
    proc fn2[T: iterator(): int](iter: T) = discard

    fn1(closureIter)
    fn2(closureIter)

    doAssert not compiles(fn1(procNotIter))
    doAssert not compiles(fn2(procNotIter))

    doAssert not compiles(fn1(inlineIter))
    doAssert not compiles(fn2(inlineIter))

  proc takesNimcall[T: proc {.nimcall.}](p: T) = discard
  proc takesClosure[T: proc {.closure.}](p: T) = discard
  proc takesAnyProc[T: proc](p: T) = discard

  proc nimcallProc(): int {.nimcall.} = 1
  proc closureProc(): int {.closure.} = 2

  doAssert nimcallProc is proc {.nimcall.}
  takesNimcall(nimcallProc)
  doAssert closureProc isnot proc {.nimcall.}
  doAssert not compiles(takesNimcall(closureProc))

  doAssert nimcallProc isnot proc {.closure.}
  doAssert not compiles(takesClosure(nimcallProc))
  doAssert closureProc is proc {.closure.}
  takesClosure(closureProc)
  
  doAssert nimcallProc is proc
  takesAnyProc(nimcallProc)
  doAssert closureProc is proc
  takesAnyProc(closureProc)

  block: # supposed to test that sameType works 
    template ensureNotRedefine(Ty): untyped =
      proc foo[T: Ty](x: T) = discard
      doAssert not (compiles do:
        proc bar[T: Ty](x: T) = discard
        proc bar[T: Ty](x: T) = discard)
    ensureNotRedefine proc
    ensureNotRedefine iterator
    ensureNotRedefine proc {.nimcall.}
    ensureNotRedefine iterator {.nimcall.}
    ensureNotRedefine proc {.closure.}
    ensureNotRedefine iterator {.closure.}

main()
