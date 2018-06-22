discard """
  output: '''
0
0
1
1
0
0
0
1
'''
"""

# Signed types
block:
  const t0: int8  = 1'i8 shl 8
  const t1: int16 = 1'i16 shl 16
  const t2: int32 = 1'i32 shl 32
  const t3: int64 = 1'i64 shl 64
  echo t0
  echo t1
  echo t2
  echo t3

# Unsigned types
block:
  const t0: uint8  = 1'u8 shl 8
  const t1: uint16 = 1'u16 shl 16
  const t2: uint32 = 1'u32 shl 32
  const t3: uint64 = 1'u64 shl 64
  echo t0
  echo t1
  echo t2
  echo t3
