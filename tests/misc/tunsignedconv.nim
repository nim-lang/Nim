# Tests unsigned literals and implicit conversion between uints and ints

var h8:uint8 = 128
var h16:uint16 = 32768
var h32:uint32 = 2147483648'u32
var h64:uint64 = 9223372036854775808'u64
var foobar:uint64 = 9223372036854775813'u64 # Issue 728

var v8:uint8 = 10
var v16:uint16 = 10
var v32:uint32 = 10
var v64:uint64 = 10

# u8 + literal produces u8:
var a8: uint8 = v8 + 10
var a16: uint16 = v16 + 10

when false:
  var d8  = v8 + 10'i8
  var d16 = v8 + 10'i16
  var d32 = v8 + 10'i32

when false:
  # these don't work yet because unsigned.nim is stupid. XXX We need to fix this.
  var f8  = v16 + 10'u8
  var f16 = v16 + 10'u16
  var f32 = v16 + 10'u32

  var g8  = v32 + 10'u8
  var g16 = v32 + 10'u16
  var g32 = v32 + 10'u32

var ar: array[0..20, int]
var n8 = ar[v8]
var n16 = ar[v16]
var n32 = ar[v32]
var n64 = ar[v64]


block t4176:
  var yyy: uint8 = 0
  yyy = yyy - 127
  doAssert type(yyy) is uint8

# bug #13661

proc fun(): uint = cast[uint](-1)
const x0 = fun()

doAssert typeof(x0) is uint

discard $x0

# bug #13671

const x1 = cast[uint](-1)
discard $(x1,)

# bug #13698
let n: csize = 1 # xxx should that be csize_t or is that essential here?
doAssert $n.int32 == "1"


block: # issue #14522
  block:
    let a = 0xFF000000_00000000.uint64
    doAssert a is uint64
    let a2 = 0xFF000000_00000000'i64
    doAssert a2 is int64
    doAssert cast[uint64](a2) == a
    doAssert cast[int64](a2) == a2
  block:
    let a = 0xFF000000_00000000
    doAssert a is uint64
    let a2 = 0xFF000000_0000000 # shorter than cutoff => int64
    doAssert a2 is int64 # IMO this should be uint64 because of 0x prefix
  block:
    let a = 18374686479671623680
    doAssert a is uint64

import stdtest/testutils

doAssertParserRaises(ValueError): "18374686479671623680'i64"
doAssertParserRaises(ValueError): "183746864796716236804" # too big to fit uint64

block: # issue #14529
  # BUG: `0xFF000000_0000000000000` should be an error
  # doAssertParserRaises(ValueError): "0xFF000000_0000000000" # too big to fit uint64
  discard
