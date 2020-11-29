discard """
  output: '''
0 0
0 0
Success'''
"""
# Test the different integer operations

var testNumber = 0

template test(opr, a, b, c: untyped): untyped =
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
when not defined(js):
  test(`shl`, 0b11'i32, 0b100'i64, 0b110000'i64)
test(`shl`, 0b11'i32, 0b100'i32, 0b110000'i32)

test(`or`, 0xf0f0'i16, 0x0d0d'i16, 0xfdfd'i16)
test(`and`, 0xf0f0'i16, 0xfdfd'i16, 0xf0f0'i16)

when not defined(js):
  test(`shr`, 0xffffffffffffffff'i64, 0x4'i64, 0xffffffffffffffff'i64)
test(`shr`, 0xffff'i16, 0x4'i16, 0xffff'i16)
test(`shr`, 0xff'i8, 0x4'i8, 0xff'i8)

when not defined(js):
  test(`shr`, 0xffffffff'i64, 0x4'i64, 0x0fffffff'i64)
test(`shr`, 0xffffffff'i32, 0x4'i32, 0xffffffff'i32)

when not defined(js):
  test(`shl`, 0xffffffffffffffff'i64, 0x4'i64, 0xfffffffffffffff0'i64)
test(`shl`, 0xffff'i16, 0x4'i16, 0xfff0'i16)
test(`shl`, 0xff'i8, 0x4'i8, 0xf0'i8)

when not defined(js):
  test(`shl`, 0xffffffff'i64, 0x4'i64, 0xffffffff0'i64)
test(`shl`, 0xffffffff'i32, 0x4'i32, 0xfffffff0'i32)

# bug #916
proc unc(a: float): float =
  return a

echo int(unc(0.5)), " ", int(unc(-0.5))
echo int(0.5), " ", int(-0.5)

block: # Casts to uint
  template testCast(fromValue: typed, toType: typed, expectedResult: typed) =
    let src = fromValue
    let dst = cast[toType](src)
    if dst != expectedResult:
      echo "Casting ", astToStr(fromValue), " to ", astToStr(toType), " = ", dst.int, " instead of ", astToStr(expectedResult)
    doAssert(dst == expectedResult)

  testCast(-1'i16, uint16, 0xffff'u16)
  testCast(0xffff'u16, int16, -1'i16)

  testCast(0xff'u16, uint8, 0xff'u8)
  testCast(0xffff'u16, uint8, 0xff'u8)

  testCast(-1'i16, uint32, 0xffffffff'u32)
  testCast(0xffffffff'u32, int32, -1)

  testCast(0xfffffffe'u32, int32, -2'i32)
  testCast(0xffffff'u32, int16, -1'i32)

  testCast(-5'i32, uint8, 251'u8)

# issue #7174
let c = 1'u
let val = c > 0
doAssert val 

echo("Success") #OUT Success
