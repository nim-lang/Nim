discard """
  msg: '''
proc init(foo128049: int; bar128051: typedesc[int]): int =
  foo128049
'''
"""

import macros

macro foo1(): untyped =
  result = newStmtList()
  result.add quote do:
    proc init(foo: int, bar: typedesc[int]): int =
      foo

expandMacros:
  foo1()

doAssert init(1, int) == 1
