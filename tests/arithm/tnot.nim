discard """
  output: '''
-5
-5
-5
-5
4
4
4
4
251
65531
4294967291
18446744073709551611
4
4
4
4
'''
"""

# Signed types
block:
  const t0: int8  = not 4
  const t1: int16 = not 4
  const t2: int32 = not 4
  const t3: int64 = not 4
  const t4: int8  = not -5
  const t5: int16 = not -5
  const t6: int32 = not -5
  const t7: int64 = not -5
  echo t0
  echo t1
  echo t2
  echo t3
  echo t4
  echo t5
  echo t6
  echo t7

# Unsigned types
block:
  const t0: uint8  = not 4'u8
  const t1: uint16 = not 4'u16
  const t2: uint32 = not 4'u32
  const t3: uint64 = not 4'u64
  const t4: uint8  = not 251'u8
  const t5: uint16 = not 65531'u16
  const t6: uint32 = not 4294967291'u32
  const t7: uint64 = not 18446744073709551611'u64
  echo t0
  echo t1
  echo t2
  echo t3
  echo t4
  echo t5
  echo t6
  echo t7
