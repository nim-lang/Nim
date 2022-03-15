discard """
  output: '''-1abc'''
"""
import std/assertions
var
  a {.compileTime.} = 2
  b = -1
  c {.compileTime.} = 3
  d = "abc"

static:
  doAssert a == 2
  doAssert c == 3

echo b, d
