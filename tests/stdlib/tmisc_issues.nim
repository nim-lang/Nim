discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp js"
"""

import std/assertions

# bug #20227
type
  Data = object
    id: int

  Test = distinct Data

  Object = object
    data: Test


var x: Object = Object(data: Test(Data(id: 12)))
doAssert Data(x.data).id == 12

block: # bug #16771
  type A = object
    n: int

  proc foo(a, b: var A) =
    swap a, b

  var a, b: A
  a.n = 42
  b.n = 1
  doAssert a.n == 42
  doAssert b.n == 1
  a.swap b
  doAssert a.n == 1
  doAssert b.n == 42
  a.foo b
  doAssert a.n == 42
  doAssert b.n == 1

block: # bug #24683
  block:
    var v = newSeq[int](100)
    v[99]= 444
    v.setLen(5)
    v.setLen(100)
    doAssert v[99] == 0

  when not defined(js):
    block:
      var 
        x = @[1, 2, 3, 4, 45, 56, 67, 999, 88, 777]

      x.setLen(0) # zero-fills 1mb of released data

      type
        TGenericSeq = object
          len, reserved: int
        PGenericSeq = ptr TGenericSeq

      when defined(gcRefc):
        cast[PGenericSeq](x).len = 10
      else:
        cast[ptr int](addr x)[] = 10

      doAssert x == @[1, 2, 3, 4, 45, 56, 67, 999, 88, 777]

when not defined(js):
  block:
    var x = high int
    var result = x

    # assert that multiplying highest int by highest int overflows

    doAssertRaises(OverflowDefect):
      x *= x

    doAssertRaises(OverflowDefect):
      result *= x

    # overflow via compound assignment on int
    var a = high(int)
    doAssertRaises(OverflowDefect):
      a += 1

    var b = low(int)
    doAssertRaises(OverflowDefect):
      b -= 1

    var c = high(int)
    doAssertRaises(OverflowDefect):
      c *= 2

    # add smaller signed types too
    var a8 = high(int8)
    doAssertRaises(OverflowDefect):
      a8 += 1

    var b8 = low(int8)
    doAssertRaises(OverflowDefect):
      b8 -= 1

    var c8 = high(int8)
    doAssertRaises(OverflowDefect):
      c8 *= 2

    var a16 = high(int16)
    doAssertRaises(OverflowDefect):
      a16 += 1

    var b16 = low(int16)
    doAssertRaises(OverflowDefect):
      b16 -= 1

    # arithmetic operations that can overflow (non-compound direct ops)
    doAssertRaises(OverflowDefect):
      discard high(int) + 1

    doAssertRaises(OverflowDefect):
      discard low(int) - 1

    doAssertRaises(OverflowDefect):
      discard high(int) * 2

    doAssertRaises(OverflowDefect):
      discard low(int) div -1

    # int8 overflow for signed operations
    doAssertRaises(OverflowDefect):
      discard high(int8) + 1'i8

    doAssertRaises(OverflowDefect):
      discard low(int8) - 1'i8

    doAssertRaises(OverflowDefect):
      discard high(int8) * 2'i8

    # enum overflow, from arithmetics.succ/pred
    type E = enum eA, eB
    doAssertRaises(OverflowDefect):
      discard eB.succ
    doAssertRaises(OverflowDefect):
      discard eA.pred

    # floating-point compound divide should produce inf (not raise by defect)
    var f = 1.0
    f /= 0.0
    # 1.0/0.0 is inf, check not finite
    #doAssert not f.isFinite     # `isFinite` not in this context, but avoid crash
    # simple check ensures it mutated to a very large value
    # (in Nim, `inf` is represented as 1e300*1e300; this compares as true)
    doAssert f == 1.0 / 0.0

    # Additional overflow cases across various integer widths
    doAssertRaises(OverflowDefect):
      discard high(int32) + 1'i32

    doAssertRaises(OverflowDefect):
      discard low(int32) - 1'i32

    doAssertRaises(OverflowDefect):
      discard high(int64) + 1'i64

    doAssertRaises(OverflowDefect):
      discard low(int64) - 1'i64

    doAssertRaises(OverflowDefect):
      discard -low(int64)

    doAssertRaises(OverflowDefect):
      discard abs(low(int8))

    doAssertRaises(OverflowDefect):
      discard high(int32) * 2'i32

    doAssertRaises(OverflowDefect):
      discard high(int64) * 2'i64

    doAssertRaises(OverflowDefect):
      discard low(int32) div -1'i32

    doAssertRaises(OverflowDefect):
      discard low(int64) div -1'i64
