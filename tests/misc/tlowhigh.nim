discard """
    action: run
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