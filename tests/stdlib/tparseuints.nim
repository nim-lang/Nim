discard """
  action: run
  output: '''
[Suite] parseutils'''
"""
import unittest, strutils

suite "parseutils":
  test "uint":
    check: parseBiggestUInt("0") == 0'u64
    check: parseBiggestUInt("18446744073709551615") == 0xFFFF_FFFF_FFFF_FFFF'u64
    expect(ValueError):
      discard parseBiggestUInt("18446744073709551616")
