
# bug #2752

import future, sequtils

proc myFilter[T](it: (iterator(): T), f: (proc(anything: T):bool)): (iterator(): T) =
  iterator aNameWhichWillConflict(): T {.closure.}=
    for x in it():
      if f(x):
        yield x
  result = aNameWhichWillConflict


iterator testIt():int {.closure.}=
  yield -1
  yield 2

#let unusedVariable = myFilter(testIt, (x: int) => x > 0)

proc onlyPos(it: (iterator(): int)): (iterator(): int)=
  iterator aNameWhichWillConflict(): int {.closure.}=
    var filtered = onlyPos(myFilter(it, (x:int) => x > 0))
    for x in filtered():
      yield x
  result = aNameWhichWillConflict

let x = onlyPos(testIt)
