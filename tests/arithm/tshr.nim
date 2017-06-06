discard """
  output: ''''''
"""

proc T() =
    let VI = -8
    let VI64 = -8'i64
    let VI32 = -8'i32
    let VI16 = -8'i16
    let VI8 = -8'i8
    doAssert( (VI shr 1) == 9223372036854775804)
    doAssert( (VI64 shr 1) == 9223372036854775804)
    doAssert( (VI32 shr 1) == 2147483644)
    doAssert( (VI16 shr 1) == 32764)
    doAssert( (VI8 shr 1) == 124)


T()
static:
    T()
