discard """
  matrix:"-d:nimTest_t16576"
"""
import std/assertions
# bug #16576
doAssert defined(nimTest_t16576)
doAssert not defined(nimMegatest)
