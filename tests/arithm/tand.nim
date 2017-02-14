discard """
  output: '''int32
int32
1280
1280'''
"""

# bug #5216

import typetraits

echo(name type((0x0A'i8 and 0x7F'i32) shl 7'i32))

let i8 = 0x0A'i8
echo(name type((i8 and 0x7F'i32) shl 7'i32))

echo((0x0A'i8 and 0x7F'i32) shl 7'i32)

let ii8 = 0x0A'i8
echo((ii8 and 0x7F'i32) shl 7'i32)
