discard """
  action: run
"""

doAssertRaises(OverflowError): discard low(int8) - 1'i8
doAssertRaises(OverflowError): discard high(int8) + 1'i8
doAssertRaises(OverflowError): discard abs(low(int8))
doAssertRaises(DivByZeroError): discard 1 mod 0
doAssertRaises(DivByZeroError): discard 1 div 0
doAssertRaises(OverflowError): discard low(int8) div -1'i8

doAssertRaises(OverflowError): discard low(int64) - 1'i64
doAssertRaises(OverflowError): discard high(int64) + 1'i64

type E = enum eA, eB
doAssertRaises(OverflowError): discard eA.pred
doAssertRaises(OverflowError): discard eB.succ

doAssertRaises(OverflowError): discard low(int8) * -1
doAssertRaises(OverflowError): discard low(int64) * -1
doAssertRaises(OverflowError): discard high(int8) * 2
doAssertRaises(OverflowError): discard high(int64) * 2

