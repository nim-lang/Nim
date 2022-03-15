discard """
  targets: "c cpp js"
"""
import std/assertions
var x = 10
atomicInc(x)
doAssert x == 11
atomicDec(x)
doAssert x == 10
