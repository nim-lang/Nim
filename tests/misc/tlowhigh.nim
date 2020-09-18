discard """
    action: run
    output: '''
18446744073709551615
9223372036854775807
4294967295
0
0
'''
"""

var x: range[-1'f32..1'f32]
doAssert x.low == -1'f32
doAssert x.high == 1'f32
doAssert x.type.low == -1'f32
doAssert x.type.high == 1'f32
var y: range[-1'f64..1'f64]
doAssert y.low == -1'f64
doAssert y.high == 1'f64
doAssert y.type.low == -1'f64
doAssert y.type.high == 1'f64

# bug #11972
var num: uint8
doAssert num.high.float == 255.0

echo high(uint64)
echo high(int64)
echo high(uint32)

echo low(uint64)
echo low(uint32)
