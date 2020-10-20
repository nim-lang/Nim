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

  block: # continue, break
    proc fn1(n: int, cont: proc(_: int)) =
      for ai in 0..<n: cont ai

    var ret: seq[string]
    for x in iterate fn1(5):
      ret.add $x
      if x==2:
        ret.add "continue"
        continue
      if x==3:
        ret.add "break"
        break
      ret.add "after"
    doAssert ret == @["0", "after", "1", "after", "2", "continue", "3", "break"]

static: main()
main()
