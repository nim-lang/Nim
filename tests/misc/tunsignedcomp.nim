discard """
  output: ''''''
  disabled: "true"
"""

# All operations involving uint64 are commented out
# as they're not yet supported.
# All other operations are handled by implicit conversions from uints to ints
# uint64 could be supported but would need special implementation of the operators

# unsigned < signed

assert 10'u8 < 20'i8
assert 10'u8 < 20'i16
assert 10'u8 < 20'i32
assert 10'u8 < 20'i64

assert 10'u16 < 20'i8
assert 10'u16 < 20'i16
assert 10'u16 < 20'i32
assert 10'u16 < 20'i64

assert 10'u32 < 20'i8
assert 10'u32 < 20'i16
assert 10'u32 < 20'i32
assert 10'u32 < 20'i64

# assert 10'u64 < 20'i8
# assert 10'u64 < 20'i16
# assert 10'u64 < 20'i32
# assert 10'u64 < 20'i64

# signed < unsigned
assert 10'i8 < 20'u8
assert 10'i8 < 20'u16
assert 10'i8 < 20'u32
# assert 10'i8 < 20'u64

assert 10'i16 < 20'u8
assert 10'i16 < 20'u16
assert 10'i16 < 20'u32
# assert 10'i16 < 20'u64

assert 10'i32 < 20'u8
assert 10'i32 < 20'u16
assert 10'i32 < 20'u32
# assert 10'i32 < 20'u64

assert 10'i64 < 20'u8
assert 10'i64 < 20'u16
assert 10'i64 < 20'u32
# assert 10'i64 < 20'u64

# unsigned <= signed
assert 10'u8 <= 20'i8
assert 10'u8 <= 20'i16
assert 10'u8 <= 20'i32
assert 10'u8 <= 20'i64

assert 10'u16 <= 20'i8
assert 10'u16 <= 20'i16
assert 10'u16 <= 20'i32
assert 10'u16 <= 20'i64

assert 10'u32 <= 20'i8
assert 10'u32 <= 20'i16
assert 10'u32 <= 20'i32
assert 10'u32 <= 20'i64

# assert 10'u64 <= 20'i8
# assert 10'u64 <= 20'i16
# assert 10'u64 <= 20'i32
# assert 10'u64 <= 20'i64

# signed <= unsigned
assert 10'i8 <= 20'u8
assert 10'i8 <= 20'u16
assert 10'i8 <= 20'u32
# assert 10'i8 <= 20'u64

assert 10'i16 <= 20'u8
assert 10'i16 <= 20'u16
assert 10'i16 <= 20'u32
# assert 10'i16 <= 20'u64

assert 10'i32 <= 20'u8
assert 10'i32 <= 20'u16
assert 10'i32 <= 20'u32
# assert 10'i32 <= 20'u64

assert 10'i64 <= 20'u8
assert 10'i64 <= 20'u16
assert 10'i64 <= 20'u32
# assert 10'i64 <= 20'u64

# signed == unsigned
assert 10'i8 == 10'u8
assert 10'i8 == 10'u16
assert 10'i8 == 10'u32
# assert 10'i8 == 10'u64

assert 10'i16 == 10'u8
assert 10'i16 == 10'u16
assert 10'i16 == 10'u32
# assert 10'i16 == 10'u64

assert 10'i32 == 10'u8
assert 10'i32 == 10'u16
assert 10'i32 == 10'u32
# assert 10'i32 == 10'u64

assert 10'i64 == 10'u8
assert 10'i64 == 10'u16
assert 10'i64 == 10'u32
# assert 10'i64 == 10'u64

# unsigned == signed
assert 10'u8 == 10'i8
assert 10'u8 == 10'i16
assert 10'u8 == 10'i32
# assert 10'u8 == 10'i64

assert 10'u16 == 10'i8
assert 10'u16 == 10'i16
assert 10'u16 == 10'i32
# assert 10'u16 == 10'i64

assert 10'u32 == 10'i8
assert 10'u32 == 10'i16
assert 10'u32 == 10'i32
# assert 10'u32 == 10'i64

# assert 10'u64 == 10'i8
# assert 10'u64 == 10'i16
# assert 10'u64 == 10'i32
# assert 10'u64 == 10'i64
