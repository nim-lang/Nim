discard """
  targets: "cpp"
"""

proc fun1(): cint {.importcpp:"!$1".}
proc fun2(a: cstring): cint {.importcpp:"!fun2".}
proc fun2(): cint {.importcpp:"!$1".}
proc fun2Aux(): cint {.importcpp:"!fun2".}
proc fun3(): cint {.importc.}

doAssert fun1() == 10
doAssert fun2(nil) == 11
doAssert fun2() == 12
doAssert fun2Aux() == 12
doAssert fun3() == 13

import ./m12150

