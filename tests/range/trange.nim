discard """
  output: '''
TSubRange: 5 from 1 to 10
#FF3722
'''
"""


block tbug499771:
  type
    TSubRange = range[1 .. 10]
    TEnum = enum A, B, C
  var sr: TSubRange = 5
  echo("TSubRange: " & $sr & " from " & $low(TSubRange) & " to " &
       $high(TSubRange))

  const cset = {A} + {B}
  doAssert A in cset
  doAssert B in cset
  doAssert C notin cset



include compilehelpers
block tmatrix3:
  type
    Matrix[M, N, T] = object
      aij: array[M, array[N, T]]

    Matrix2[T] = Matrix[range[0..1], range[0..1], T]

    Matrix3[T] = Matrix[range[0..2], range[0..2], T]

  proc mn(x: Matrix): Matrix.T = x.aij[0][0]

  proc m2(x: Matrix2): Matrix2.T = x.aij[0][0]

  proc m3(x: Matrix3): auto = x.aij[0][0]

  var
    matn: Matrix[range[0..3], range[0..2], int]
    mat2: Matrix2[int]
    mat3: Matrix3[float]

  doAssert m3(mat3) == 0.0
  doAssert mn(mat3) == 0.0
  doAssert m2(mat2) == 0
  doAssert mn(mat2) == 0
  doAssert mn(matn) == 0

  reject m3(mat2)
  reject m3(matn)
  reject m2(mat3)
  reject m2(matn)



block tn8vsint16:
  type
    n32 = range[0..high(int)]
    n8 = range[0'i8..high(int8)]

  proc `+`(a: n32, b: n32{nkIntLit}): n32 = discard

  proc `-`(a: n8, b: n8): n8 = n8(system.`-`(a, b))

  var x, y: n8
  var z: int16

  # ensure this doesn't call our '-' but system.`-` for int16:
  doAssert z - n8(9) == -9



import strutils
block tcolors:
  type TColor = distinct int32

  proc rgb(r, g, b: range[0..255]): TColor =
    result = TColor(r or g shl 8 or b shl 16)
  proc `$`(c: TColor): string =
    result = "#" & toHex(int32(c), 6)
  echo rgb(34, 55, 255)

  when false:
    type
      TColor = distinct int32
      TColorComponent = distinct int8

    proc red(a: TColor): TColorComponent =
      result = TColorComponent(int32(a) and 0xff'i32)
    proc green(a: TColor): TColorComponent =
      result = TColorComponent(int32(a) shr 8'i32 and 0xff'i32)
    proc blue(a: TColor): TColorComponent =
      result = TColorComponent(int32(a) shr 16'i32 and 0xff'i32)
    proc rgb(r, g, b: range[0..255]): TColor =
      result = TColor(r or g shl 8 or b shl 8)

    proc `+!` (a, b: TColorComponent): TColorComponent =
      ## saturated arithmetic:
      result = TColorComponent(min(ze(int8(a)) + ze(int8(b)), 255))

    proc `+` (a, b: TColor): TColor =
      ## saturated arithmetic for colors makes sense, I think:
      return rgb(red(a) +! red(b), green(a) +! green(b), blue(a) +! blue(b))

    rgb(34, 55, 255)

block:
  type
    R8  = range[0'u8 .. 10'u8]
    R16 = range[0'u16 .. 10'u16]
    R32 = range[0'u32 .. 10'u32]

  var
    x1 = R8(4)
    x2 = R16(4)
    x3 = R32(4)

  doAssert $x1 & $x2 & $x3 == "444"

block:
  var x1: range[0'f..1'f] = 1
  const x2: range[0'f..1'f] = 1
  var x3: range[0'u8..1'u8] = 1
  const x4: range[0'u8..1'u8] = 1

  var x5: range[0'f32..1'f32] = 1'f64
  const x6: range[0'f32..1'f32] = 1'f64

  reject:
    var x09: range[0'i8..1'i8] = 1.int
  reject:
    var x10: range[0'i64..1'i64] = 1'u64

    const x11: range[0'f..1'f] = 2'f
  reject:
    const x12: range[0'f..1'f] = 2

# ensure unsigned array indexing is remains lenient:
var a: array[4'u, string]

for i in 0..<a.len:
  a[i] = "foo"

# Check range to ordinal conversions
block:
  var
    a: int16
    b: range[0'i32..45'i32] = 3
    c: uint16
    d: range[0'u32..46'u32] = 3
  a = b
  c = d
  doAssert a == b
  doAssert c == d
