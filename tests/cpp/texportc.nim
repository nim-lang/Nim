discard """
  targets: "c cpp"
"""

var fun0 {.importc.}: int
proc fun1() {.importc.}
proc fun2() {.importc: "$1".}
proc fun3() {.importc: "fun3Bis".}

doAssert fun0 == 10
fun1()
fun2()
fun3()

import ./mexportc
