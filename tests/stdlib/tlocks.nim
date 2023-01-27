discard """
  targets: "c cpp js"
  matrix: "--threads:on"
"""

#bug #6049
import uselocks
import std/assertions

var m = createMyType[int]()
doAssert m.use() == 3
