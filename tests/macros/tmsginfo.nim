discard """
  nimout: '''tmsginfo.nim(21, 1) Warning: foo1 [User]
tmsginfo.nim(22, 13) template/generic instantiation of `foo2` from here
tmsginfo.nim(15, 10) Warning: foo2 [User]
tmsginfo.nim(23, 1) Hint: foo3 [User]
tmsginfo.nim(19, 7) Hint: foo4 [User]
'''
"""

import macros

macro foo1(y: untyped): untyped =
  warning("foo1", y)
macro foo2(y: untyped): untyped =
  warning("foo2")
macro foo3(y: untyped): untyped =
  hint("foo3", y)
macro foo4(y: untyped): untyped =
  hint("foo4")

proc x1() {.foo1.} = discard
proc x2() {.foo2.} = discard
proc x3() {.foo3.} = discard
proc x4() {.foo4.} = discard
