discard """
  targets: "c cpp js"
"""

import std/sysrand


doAssert urandom(0).len == 0
doAssert urandom(10).len == 10
doAssert urandom(20).len == 20
doAssert urandom(120).len == 120
doAssert urandom(113).len == 113
doAssert urandom(1234) != urandom(1234) # unlikely to fail in practice
