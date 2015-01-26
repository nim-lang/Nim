import unsigned

# Bug #1179
let x = 0x80'u8 shr 7
let y = 128'u8 shr 7

doAssert(x == y)

