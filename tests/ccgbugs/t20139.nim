discard """
  joinable: false
"""

# bug #20139
import m1/defs as md1
import m2/defs as md2

doAssert $(md1.MyObj(field1: 1)) == "(field1: 1)"
doAssert $(md2.MyObj(field2: 1)) == "(field2: 1)"
