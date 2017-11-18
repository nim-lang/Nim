discard """
  output:""
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
