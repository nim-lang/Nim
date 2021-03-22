import unittest, strutils

block: # parseutils
  check: parseBiggestUInt("0") == 0'u64
  check: parseBiggestUInt("18446744073709551615") == 0xFFFF_FFFF_FFFF_FFFF'u64
  expect(ValueError):
    discard parseBiggestUInt("18446744073709551616")
