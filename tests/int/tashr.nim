discard """
  output: ''''''
  targets: '''c js'''
"""

# issue #6255, feature request
# arithmetic right shift

var x1 = -123'i8
var x2 = -123'i16
var x3 = -123'i32
var x4 = -123'i64
var x5 = -123

block codegen_test:
  doAssert ashr(x1, 1) == -62
  doAssert ashr(x2, 1) == -62
  doAssert ashr(x3, 1) == -62
  doAssert ashr(x4, 1) == -62
  doAssert ashr(x5, 1) == -62

block semfold_test:
  doAssert ashr(-123'i8 , 1) == -62
  doAssert ashr(-123'i16, 1) == -62
  doAssert ashr(-123'i32, 1) == -62
  doAssert ashr(-123'i64, 1) == -62
  doAssert ashr(-123    , 1) == -62

static: # VM test
  doAssert ashr(-123'i8 , 1) == -62
  doAssert ashr(-123'i16, 1) == -62
  doAssert ashr(-123'i32, 1) == -62
  doAssert ashr(-123'i64, 1) == -62
  doAssert ashr(-123    , 1) == -62

  var y1 = -123'i8
  var y2 = -123'i16
  var y3 = -123'i32
  var y4 = -123'i64
  var y5 = -123

  doAssert ashr(y1, 1) == -62
  doAssert ashr(y2, 1) == -62
  doAssert ashr(y3, 1) == -62
  doAssert ashr(y4, 1) == -62
  doAssert ashr(y5, 1) == -62
