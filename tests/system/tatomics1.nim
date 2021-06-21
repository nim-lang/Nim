discard """
  targets: "c cpp js"
"""

var x = 10
atomicInc(x)
doAssert x == 11
atomicDec(x)
doAssert x == 10
