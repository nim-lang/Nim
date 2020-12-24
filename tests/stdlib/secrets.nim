discard """
  targets: "c cpp"
"""

import std/secrets


doAssert urandom(0).len == 0
doAssert urandom(10).len == 10
doAssert urandom(20).len == 20
doAssert urandom(120).len == 120
