discard """
  errormsg: "number out of range: '0x123'u8'"
"""

# Bug #1179

# Unsigneds

# 8 bit
let ref1 = 128'u8 shr 7
let hex1 = 0x80'u8 shr 7
let oct1 = 0o200'u8 shr 7
let dig1 = 0b10000000'u8 shr 7

doAssert(ref1 == 1)
doAssert(ref1 == hex1)
doAssert(ref1 == oct1)
doAssert(ref1 == dig1)

# 16 bit
let ref2 = 32768'u16 shr 15
let hex2 = 0x8000'u16 shr 15
let oct2 = 0o100000'u16 shr 15
let dig2 = 0b1000000000000000'u16 shr 15

doAssert(ref2 == 1)
doAssert(ref2 == hex2)
doAssert(ref2 == oct2)
doAssert(ref2 == dig2)

# 32 bit
let ref3 = 2147483648'u32 shr 31
let hex3 = 0x80000000'u32 shr 31
let oct3 = 0o20000000000'u32 shr 31
let dig3 = 0b10000000000000000000000000000000'u32 shr 31

doAssert(ref3 == 1)
doAssert(ref3 == hex3)
doAssert(ref3 == oct3)
doAssert(ref3 == dig3)

# Below doesn't work for lexer stage errors...
# doAssert(compiles(0xFF'u8) == true)
# doAssert(compiles(0xFFF'u16) == true)
# doAssert(compiles(0x7FFF'i16) == true)

# doAssert(compiles(0x123'u8) == false)
# doAssert(compiles(0x123'i8) == false)
# doAssert(compiles(0x123123'u16) == false)
# doAssert(compiles(0x123123'i16) == false)

# Should compile #
let boundOkHex1 = 0xFF'u8
let boundOkHex2 = 0xFFFF'u16
let boundOkHex3 = 0x7FFF'i16

let boundOkHex4 = 0x80'i8
let boundOkHex5 = 0xFF'i8
let boundOkHex6 = 0xFFFF'i16
let boundOkHex7 = 0x7FFF'i16

# Should _not_ compile #
let boundBreakingHex1 = 0x123'u8
let boundBreakingHex2 = 0x123'i8
let boundBreakingHex3 = 0x123123'u16
let boundBreakingHex4 = 0x123123'i16
