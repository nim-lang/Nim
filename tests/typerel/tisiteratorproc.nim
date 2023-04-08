import std/assertions

iterator myIter1(): int {.closure.} =
  yield 1
  yield 2
iterator myIter2(): int {.inline.} =
  yield 1
  yield 2
proc myFun(): int = 1

doAssert myIter1 is iterator
doAssert myIter2 is iterator
doAssert myFun isnot iterator

doAssert myIter1 isnot proc
doAssert myIter2 isnot proc
doAssert myFun is proc

doAssert typeof(myIter1) is iterator
doAssert typeof(myIter2) is iterator
doAssert typeof(myFun) isnot iterator

doAssert typeof(myIter1) isnot proc
doAssert typeof(myIter2) isnot proc
doAssert typeof(myFun) is proc

proc fn1(iter: iterator {.closure.}) = echo "ok1"
proc fn2[T: iterator {.closure.}](iter: T) = echo "ok2"

fn1(myIter1)
fn2(myIter1)

doAssert not compiles(fn1(myFun))
doAssert not compiles(fn2(myFun))
