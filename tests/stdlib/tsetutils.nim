discard """
  targets: "c js"
"""
import std/setutils

doAssert "abcbb".toSet == {'a','b','c'}
doAssert toSet([10u8,12,13]) == {10u8, 12, 13}
doAssert toSet(0u16..30) == {0u16..30}