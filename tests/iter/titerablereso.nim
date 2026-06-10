discard """
  action: "run"
"""

import std/[assertions, options, strutils]
from std/sequtils import toSeq

# block: # TODO: make iterable accept closure iterators?
#   template mymap[T, U](s: iterable[T], f: proc(x: T): U): untyped =
#     let res = iterator (): U =
#       for val in s:
#         yield f(val)
#     res

#   proc foo(x: string): string = x & "0"

#   let a = "1\n2\n3\n4".splitLines().mymap(foo).toSeq()
#   echo a
#   echo typeof(a)

block splitIterable: # #22098
  template collect[T](it: iterable[T]): seq[T] =
    var res: seq[T] = @[]
    for x in it:
      res.add x
    res

  const text = "a b c d"
  let words = text.split.collect()
  doAssert words == @["a", "b", "c", "d"]

block optionElements:
  iterator its(_: int; default: Option[string] = none(string)): Option[string] =
    yield some("x")

  var fromCall = none(string)
  for x in its(0):
    fromCall = x
  doAssert fromCall == some("x")

  var fromDot = none(string)
  for x in 0.its:
    fromDot = x
  doAssert fromDot == some("x")

block closureIteratorCallsStayCallable:
  let next = iterator (): string =
    yield "x"

  doAssert next() == "x"
