discard """
  output: '''ok.'''
"""

from math import countBits

# Trivial test cases:

assert countBits(0x00u8) == 0
assert countBits(0x00i8) == 0
assert countBits(0x0000u16) == 0
assert countBits(0x0000i16) == 0
assert countBits(0x00000000u32) == 0
assert countBits(0x00000000i32) == 0
assert countBits(0x0000000000000000u64) == 0
assert countBits(0x0000000000000000i64) == 0

assert countBits(0xFFu8) == 8
assert countBits(-0x01i8) == 8
assert countBits(0xFFFFu16) == 16
assert countBits(-0x0001i16) == 16
assert countBits(0xFFFFFFFFu32) == 32
assert countBits(-0x00000001i32) == 32
assert countBits(0xFFFFFFFFFFFFFFFFu64) == 64
assert countBits(-0x0000000000000001i64) == 64

# Pseudorandomly generated test cases:

assert countBits(0x3Au8) == 4
assert countBits(0xCFu8) == 6

assert countBits(0x57i8) == 5
assert countBits(-0x26i8) == 5

assert countBits(0x52D3u16) == 8
assert countBits(0xAE11u16) == 7

assert countBits(0x270Bi16) == 7
assert countBits(-0x14E9i16) == 10

assert countBits(0x2645FF7Eu32) == 20
assert countBits(0xEEF7AD2Fu32) == 23

assert countBits(0x78DC90B6i32) == 16
assert countBits(-0x24FC9206i32) == 19

assert countBits(0x7551227A13420B20u64) == 24
assert countBits(0xDDC992D8CE90712Du64) == 32

assert countBits(0x5D6D6A6A01DE8A36i64) == 32
assert countBits(-0x0991174FDC4A9E3Bi64) == 33

echo "ok."
