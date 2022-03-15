discard """
  matrix: "--gc:none -d:useMalloc"
"""
import std/assertions
# bug #15617
let x = 4
doAssert x == 4
