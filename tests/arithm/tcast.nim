discard """
  output: '''
B0
B1
B2
B3
'''
"""

template crossCheck(ty: untyped, exp: untyped) =
  let rt = ty(exp)
  const ct = ty(exp)
  if $rt != $ct:
    echo "Got ", ct
    echo "Expected ", rt

block:
  when true:
    echo "B0"
    crossCheck(int8, 0'i16 - 5'i16)
    crossCheck(int16, 0'i32 - 5'i32)
    crossCheck(int32, 0'i64 - 5'i64)

    echo "B1"
    crossCheck(uint8, 0'u8 - 5'u8)
    crossCheck(uint16, 0'u16 - 5'u16)
    crossCheck(uint32, 0'u32 - 5'u32)
    crossCheck(uint64, 0'u64 - 5'u64)

    echo "B2"
    crossCheck(uint8, uint8.high + 5'u8)
    crossCheck(uint16, uint16.high + 5'u16)
    crossCheck(uint32, uint32.high + 5'u32)
    crossCheck(uint64, (-1).uint64 + 5'u64)

    echo "B3"
    crossCheck(int8, 0'u8 - 5'u8)
    crossCheck(int16, 0'u16 - 5'u16)
    crossCheck(int32, 0'u32 - 5'u32)
    crossCheck(int64, 0'u64 - 5'u64)

  # crossCheck(int8, 0'u16 - 129'u16)
  # crossCheck(uint8, 0'i16 + 257'i16)

  # Signed integer {under,over}flow is guarded against

  # crossCheck(int8, int8.high + 5'i8)
  # crossCheck(int16, int16.high + 5'i16)
  # crossCheck(int32, int32.high + 5'i32)
  # crossCheck(int64, int64.high + 5'i64)

  # crossCheck(int8, int8.low - 5'i8)
  # crossCheck(int16, int16.low - 5'i16)
  # crossCheck(int32, int32.low - 5'i32)
  # crossCheck(int64, int64.low - 5'i64)

  # crossCheck(uint8, 0'i8 - 5'i8)
  # crossCheck(uint16, 0'i16 - 5'i16)
  # crossCheck(uint32, 0'i32 - 5'i32)
  # crossCheck(uint64, 0'i64 - 5'i64)
