discard """
  targets: "c cpp js"
  matrix: "--experimental:vmopsDanger"
"""

import std/sysrand


template main() =
  block:
    var x = array[5, byte].default
    doAssert urandom(x)

  block:
    var x = newSeq[byte](5)
    doAssert urandom(x)

  block:
    var x = @[byte(0), 0, 0, 0, 0]
    doAssert urandom(x)

  block:
    var x = @[byte(1), 2, 3, 4, 5]
    doAssert urandom(x)

  block:
    doAssert urandom(0).len == 0
    doAssert urandom(10).len == 10
    doAssert urandom(20).len == 20
    doAssert urandom(120).len == 120
    doAssert urandom(113).len == 113
    doAssert urandom(1234) != urandom(1234) # unlikely to fail in practice

main()
