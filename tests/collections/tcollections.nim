discard """
  file: "tcollections.nim"
  output: '''
'''
"""

import deques, sequtils


block tapply:
  var x = @[1, 2, 3]
  x.apply(proc(x: var int) = x = x+10)
  x.apply(proc(x: int): int = x+100)
  x.applyIt(it+5000)
  doAssert x == @[5111, 5112, 5113]


block tdeques:
  proc index(self: Deque[int], idx: Natural): int =
    self[idx]

  proc main =
    var testDeque = initDeque[int]()
    testDeque.addFirst(1)
    assert testDeque.index(0) == 1

  main()


block tmapit:
  var x = @[1, 2, 3]
  # This mapIt call will run with preallocation because ``len`` is available.
  var y = x.mapIt($(it+10))
  doAssert y == @["11", "12", "13"]

  type structureWithoutLen = object
    a: array[5, int]

  iterator items(s: structureWithoutLen): int {.inline.} =
    yield s.a[0]
    yield s.a[1]
    yield s.a[2]
    yield s.a[3]
    yield s.a[4]

  var st: structureWithoutLen
  st.a[0] = 0
  st.a[1] = 1
  st.a[2] = 2
  st.a[3] = 3
  st.a[4] = 4

  # this will run without preallocating the result
  # since ``len`` is not available
  var r = st.mapIt($(it+10))
  doAssert r == @["10", "11", "12", "13", "14"]
