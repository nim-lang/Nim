discard """
  targets: "c cpp"
"""

var fun2 {.importc.}: int
proc fun1(){.importc.}

fun1()
doAssert fun2 == 10

import ./mexportc
