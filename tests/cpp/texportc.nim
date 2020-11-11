discard """
  targets: "c cpp"
"""

var fun0 {.importc.}: int
proc fun1() {.importc.}
proc fun2() {.importc: "$1".}
proc fun3() {.importc: "fun3Bis".}

when defined cpp:
  # proc funx1() {.importcpp.} # this does not work yet
  proc funx1() {.importc: "_Z5funx1v".}

doAssert fun0 == 10
fun1()
fun2()
fun3()

when defined cpp:
  funx1()

import ./mexportc
