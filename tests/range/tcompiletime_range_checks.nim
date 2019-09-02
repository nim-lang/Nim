template reject(e) =
  static: assert(not compiles(e))

template accept(e) =
  static: assert(compiles(e))

type
  UnsignedRange   = 0'u64 .. 100'u64
  SemiOutOfBounds = 0x7ffffffffffffe00'u64 .. 0x8000000000000100'u64
  FullOutOfBounds = 0x8000000000000000'u64 .. 0x8000000000000200'u64

  FullNegativeRange = -200 .. -100
  HalfNegativeRange = -50 .. 50
  FullPositiveRange = 100 .. 200

reject(int32(0x80000000'i64))
accept(int32(0x7fffffff'i64))

reject(uint64(-1'i64))
accept(uint64(0'i64))

reject(FullNegativeRange(0xff'u32))
reject(HalfNegativeRange(0xffffffffffffffff'u64)) # internal `intVal` is `-1` which would be in range.
accept(HalfNegativeRange(25'u64))
reject(FullPositiveRange(300'u64))

accept(UnsignedRange(50'u64))
reject(UnsignedRange(101'u64))

accept(SemiOutOfBounds(0x7ffffffffffffe00'i64))
reject(SemiOutOfBounds(0x8000000000000000'i64))  #
accept(SemiOutOfBounds(0x8000000000000000'u64))  # the last two literals have internally the same `intVal`.

reject(int32(NaN))
reject(int64(1e100))
reject(uint64(1e100))

# removed cross checks from tarithm.nim
reject(int64(0xFFFFFFFFFFFFFFFF'u64))
reject(int32(0xFFFFFFFFFFFFFFFF'u64))
reject(int16(0xFFFFFFFFFFFFFFFF'u64))
reject( int8(0xFFFFFFFFFFFFFFFF'u64))
