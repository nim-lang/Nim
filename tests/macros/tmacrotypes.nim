discard """
  nimout: '''void; ntyVoid; void; void
int; ntyInt; int; int
proc (); ntyProc; proc[void]; proc ()
proc (a: int; b: float): int; ntyProc; proc[int, int, float]; proc (a: int; b: float): int  
"""

import macros

macro checkType(ex: typed; expected: string): untyped =
  echo ex.getTypeInst.repr, "; ", ex.typeKind, "; ", ex.getType.repr, "; ", ex.getTypeImpl.repr

proc voidProc = echo "hello"
proc intProc(a: int, b: float): int = 10

checkType(voidProc(), "void")
checkType(intProc(10, 20.0), "int")
checkType(voidProc, "procTy")
checkType(intProc, "procTy")
