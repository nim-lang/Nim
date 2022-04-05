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

# bug #14616

let limit = 1'u64

let rangeVar = 0'u64 ..< limit

doAssert repr(rangeVar) == """[a = 0,
b = 0]"""

# bug #15210

let a3 = not 0'u64
var success = false
try:
  discard a3.int64
except RangeDefect:
  success = true

doAssert success, "conversion should fail at runtime"

template main() =
  # xxx move all tests under here so it gets tested in CT and RT
  block: # bug #17572
    type T = distinct uint64
    func f(x: uint64): auto =
      let a = T(x)
      (x, a.uint64)
    const x = 1'u64 shl 63 or 7
    const b = T(x)
    doAssert b.uint64 == 9223372036854775815'u64
    doAssert $b.uint64 == "9223372036854775815"
    doAssert f(x) == (9223372036854775815'u64, 9223372036854775815'u64)

static: main()
main()
