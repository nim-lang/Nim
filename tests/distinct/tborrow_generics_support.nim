##[
This testcase checks several things:

1. Shows that generics are supported for borrow
   operations.
2. It aims to show these issues are now fixed:
   - #4121 distinct seq[T]
   - #19097 distinct Table[A, B]
   - #6026 type Amount[date: static[int]] = distinct float and +
   - #3564 distinct array[4, float32] and []
   - #2684 distinct seq[T] and []
]##

import std/tables


block:
  type vec4 = distinct array[4, float32]

  proc `[]`(v: vec4, i: int): float32 {.borrow.}
  proc `[]=`(v: var vec4, i: int, va: float32) {.borrow.}

  var v: vec4
  v[0] = 1.234'f32
  doAssert v[0] == 1.234'f32


block:
  type MySeq [T] = distinct seq[T]
  proc `[]`[T](s: MySeq[T], i: int): T {.borrow.}
  let points = MySeq(@[ (x: 1, y: 2), (x: 5, y: 6) ])
  doAssert points[0] == (x: 1, y: 2,)


block:
  type HeapQueue[T] = distinct seq[T]
  proc len[T](h: HeapQueue[T]): int {.borrow.}

  var hq: HeapQueue[float32]
  doAssert hq.len == 0


block:
  type
    DefaultTable[A, B] = distinct Table[A, B]

  proc mgetOrPut[A, B](t: var DefaultTable[A, B]; key: A; val: B): var B {.borrow.}

  proc `[]`[A, B](tab: var DefaultTable[A, B], key: A): var B {.inline.} =
    tab.mgetOrPut(key, default(B))

  var nested:DefaultTable[string,DefaultTable[string,DefaultTable[string,seq[string]]]]

  nested["key1"]["key2"]["key3"] = @["1", "2", "3"]
  doAssert nested["key1"]["key2"]["key3"] == @["1", "2", "3"]


block:
  type Amount[date: static[int]] = distinct float

  proc `+`[T:static[int]](x, y: Amount[T]): Amount[T] {.borrow.}

  var a0 = Amount[0](5.0)
  var a1 = Amount[0](5.0)
  var a2 = Amount[1](5.0)
  var a3 = Amount[1](5.0)

  doAssert compiles((block:
    var s0 = a0 + a1))

  let s0 = a0 + a1
  doAssert s0.float == 10.0

  let s1 = a2 + a3
  doAssert s1.float == 10.0

  doAssert not compiles((block:
    let s2 = a0 + a2))

  doAssert a0 is Amount[0]
  doAssert a1 is Amount[0]
  doAssert a2 is Amount[1]
  doAssert a3 is Amount[1]
  doAssert a0 isnot Amount[1]
