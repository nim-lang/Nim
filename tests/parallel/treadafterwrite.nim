discard """
  errormsg: "'foo' not disjoint from 'foo'"
  line: 23
  disabled: "true"
"""

# bug #1597

import strutils, math, threadpool

type
  BoxedFloat = object
    value: float

proc term(k: float): ptr BoxedFloat =
  var temp = 4 * math.pow(-1, k) / (2*k + 1)
  result = cast[ptr BoxedFloat](allocShared(sizeof(BoxedFloat)))
  result.value = temp

proc pi(n: int): float =
  var ch = newSeq[ptr BoxedFloat](n+1)
  parallel:
    for k in 0..ch.high:
      let foo = (spawn term(float(k)))
      assert foo != nil
  for k in 0..ch.high:
    var temp = ch[k][].value
    result += temp
    deallocShared(ch[k])

echo formatFloat(pi(5000))
