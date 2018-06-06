discard """
  output:'''1
1
2
3
11
12
13
14
15
2
3
4
2
1
2
3
'''
"""

# check high/low implementations
doAssert high(int) > low(int)
doAssert high(int8) > low(int8)
doAssert high(int16) > low(int16)
doAssert high(int32) > low(int32)
doAssert high(int64) > low(int64)
# doAssert high(uint) > low(uint) # reconsider depending on issue #6620
doAssert high(uint8) > low(uint8)
doAssert high(uint16) > low(uint16)
doAssert high(uint32) > low(uint32)
# doAssert high(uint64) > low(uint64) # reconsider depending on issue #6620
doAssert high(float) > low(float)
doAssert high(float32) > low(float32)
doAssert high(float64) > low(float64)

# bug #6710
var s = @[1]
s.delete(0)


proc foo(a: openArray[int]) =
  for x in a: echo x

foo(toOpenArray([1, 2, 3], 0, 0))

foo(toOpenArray([1, 2, 3], 0, 2))

var arr: array[8..12, int] = [11, 12, 13, 14, 15]

foo(toOpenArray(arr, 8, 12))

var seqq = @[1, 2, 3, 4, 5]
foo(toOpenArray(seqq, 1, 3))

# empty openArray issue #7904
foo(toOpenArray(seqq, 0, -1))
foo(toOpenArray(seqq, 1, 0))
doAssertRaises(IndexError):
  foo(toOpenArray(seqq, 0, -2))

foo(toOpenArray(arr, 9, 8))
foo(toOpenArray(arr, 0, -1))
foo(toOpenArray(arr, 1, 0))
doAssertRaises(IndexError):
  foo(toOpenArray(arr, 10, 8))

# test openArray of openArray
proc oaEmpty(a: openArray[int]) =
  foo(toOpenArray(a, 0, -1))

proc oaFirstElm(a: openArray[int]) =
  foo(toOpenArray(a, 0, 0))

oaEmpty(toOpenArray(seqq, 0, -1))
oaEmpty(toOpenArray(seqq, 1, 0))
oaEmpty(toOpenArray(seqq, 1, 2))
oaFirstElm(toOpenArray(seqq, 1, seqq.len-1))

var arrNeg: array[-3 .. -1, int] = [1, 2, 3]
foo(toOpenArray(arrNeg, -3, -1))
foo(toOpenArray(arrNeg, 0, -1))
foo(toOpenArray(arrNeg, -3, -4))
doAssertRaises(IndexError):
  foo(toOpenArray(arrNeg, -4, -1))
doAssertRaises(IndexError):
  foo(toOpenArray(arrNeg, -1, 0))
doAssertRaises(IndexError):
  foo(toOpenArray(arrNeg, -1, -3))
