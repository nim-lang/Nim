discard """
  nimout: '''void
int'''
"""

import macros

macro checkType(ex: stmt; expected: expr): stmt =
  var t = ex.getType()
  echo t

proc voidProc = echo "hello"
proc intProc(a: int, b: float): int = 10

checkType(voidProc(), "void")
checkType(intProc(10, 20.0), "int")
