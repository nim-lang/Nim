discard """
  errormsg: "type mismatch: got <string> but expected 'ptr'"
  line: 20
"""

import typetraits

type
  Vec[N: static[int]; T] = distinct array[N, T]

var x = Vec([1, 2, 3])

static:
  assert x.type.name == "Vec[3, system.int]"

var str1: string = "hello, world!"
var ptr1: ptr = addr(str1)

var str2: string = "hello, world!"
var ptr2: ptr = str2

block: # built in typeclass inference
  proc tupleA(): tuple = return (1, 2)
  proc tupleB(): tuple = (1f, 2f)
  assert typeof(tupleA()) is (int, int)
  assert typeof(tupleB()) is (float32, float32)

  proc a(val: int or float): tuple = 
    when typeof(val) is int:
      (10, 10)
    else:
      (30f, 30f)

  assert typeof(a(10)) is (int, int)
  assert typeof(a(10.0)) is (float32, float32)

  proc b(val: int or float): set = 
    when typeof(val) is int:
      {10u8, 3}
    else:
      {'a', 'b'}
  assert typeof(b(10)) is set[uint8]
  assert typeof(b(10.0)) is set[char]