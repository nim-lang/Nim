discard """
  matrix: "--gc:arc; --gc:refc"
"""
import std/assertions
proc hello() =
  raise newException(ValueError, "You are wrong")

var flag = false

try:
  hello()
except ValueError as e:
  flag = true
  doAssert len(getStackTraceEntries(e)) > 0
  doAssert len(getStackTraceEntries(e)) > 0

doAssert flag
