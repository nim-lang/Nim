discard """
  action: compile
"""

type Foo[T] = object
  when true:
    x: float

type Bar = object
  when true:
    x: float

import std/macros

macro test() =
  let a = getImpl(bindSym"Foo")[^1]
  let b = getImpl(bindSym"Bar")[^1]
  doAssert treeRepr(a) == treeRepr(b)

test()
