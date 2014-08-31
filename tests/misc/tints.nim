discard """
  file: "tints.nim"
  output: "Success"
"""
# Test the different integer operations

var testNumber = 0

template test(opr, a, b, c: expr): stmt {.immediate.} =
  # test the expression at compile and runtime
  block:
    const constExpr = opr(a, b)
    when constExpr != c:
      {.error: "Test failed " & $constExpr & " " & $c.}
    inc(testNumber)
    #Echo("Test: " & $testNumber)
    var aa = a
    var bb = b
    var varExpr = opr(aa, bb)
    assert(varExpr == c)

test(`+`, 12'i8, -13'i16, -1'i16)
test(`shl`, 0b11, 0b100, 0b110000)
test(`shl`, 0b11'i32, 0b100'i64, 0b110000'i64)
test(`shl`, 0b11'i32, 0b100'i32, 0b110000'i32)

test(`or`, 0xf0f0'i16, 0x0d0d'i16, 0xfdfd'i16)
test(`and`, 0xf0f0'i16, 0xfdfd'i16, 0xf0f0'i16)

test(`shr`, 0xffffffffffffffff'i64, 0x4'i64, 0x0fffffffffffffff'i64)
test(`shr`, 0xffff'i16, 0x4'i16, 0x0fff'i16)
test(`shr`, 0xff'i8, 0x4'i8, 0x0f'i8)

test(`shr`, 0xffffffff'i64, 0x4'i64, 0x0fffffff'i64)
test(`shr`, 0xffffffff'i32, 0x4'i32, 0x0fffffff'i32)

test(`shl`, 0xffffffffffffffff'i64, 0x4'i64, 0xfffffffffffffff0'i64)
test(`shl`, 0xffff'i16, 0x4'i16, 0xfff0'i16)
test(`shl`, 0xff'i8, 0x4'i8, 0xf0'i8)

test(`shl`, 0xffffffff'i64, 0x4'i64, 0xffffffff0'i64)
test(`shl`, 0xffffffff'i32, 0x4'i32, 0xfffffff0'i32)

echo("Success") #OUT Success

