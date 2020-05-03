discard """
  action: run
"""

doAssertRaises(OverflowDefect): discard low(int8) - 1'i8
doAssertRaises(OverflowDefect): discard high(int8) + 1'i8
doAssertRaises(OverflowDefect): discard abs(low(int8))
doAssertRaises(DivByZeroDefect): discard 1 mod 0
doAssertRaises(DivByZeroDefect): discard 1 div 0
doAssertRaises(OverflowDefect): discard low(int8) div -1'i8

doAssertRaises(OverflowDefect): discard -low(int64)
doAssertRaises(OverflowDefect): discard low(int64) - 1'i64
doAssertRaises(OverflowDefect): discard high(int64) + 1'i64

type E = enum eA, eB
doAssertRaises(OverflowDefect): discard eA.pred
doAssertRaises(OverflowDefect): discard eB.succ

doAssertRaises(OverflowDefect): discard low(int8) * -1
doAssertRaises(OverflowDefect): discard low(int64) * -1
doAssertRaises(OverflowDefect): discard high(int8) * 2
doAssertRaises(OverflowDefect): discard high(int64) * 2

doAssert abs(-1) == 1
doAssert 2 div 2 == 1
doAssert 2 * 3 == 6
