discard """
  targets: "c cpp js"
"""

import std/iterates

proc myIter[T](s: seq[T], cont: proc(_: T)) =
  for ai in s: cont ai*10

proc myIter2(a, b: int, cont: proc(a1: int, a2: string)) =
  for ai in a..b:
    cont ai, $ai

template toSeq(T, a: untyped): untyped =
  # type T = typeof(block: (for ai in iterate(a): ai))
  var ret = newSeq[T]()
  for x in iterate a:
    ret.add x
  ret

template main() =
  block:
    var ret: seq[int]
    for x in iterate myIter(@[2,3]):
      ret.add x
    doAssert ret == @[20, 30]

    doAssert toSeq(float, myIter(@[1.5, 2.0])) == @[15.0, 20.0]
    doAssert toSeq(int, myIter(@[3])) == @[30]

  block:
    var ret: seq[(int, string)]
    for k,v in iterate myIter2(2,5):
      ret.add (k,v)
    doAssert ret == @[(2, "2"), (3, "3"), (4, "4"), (5, "5")]

static: main()
main()
