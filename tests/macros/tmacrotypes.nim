discard """
  nimout: '''intProc; ntyProc; proc[int, int, float]; proc (a: int; b: float): int
void; ntyVoid; void; void
int; ntyInt; int; int
proc (); ntyProc; proc[void]; proc ()
voidProc; ntyProc; proc[void]; proc ()'''
"""

import macros

macro checkType(ex: typed; expected: string): untyped =
  echo ex.getTypeInst.repr, "; ", ex.typeKind, "; ", ex.getType.repr, "; ", ex.getTypeImpl.repr

macro checkProcType(fn: typed): untyped =
  let fn_sym = if fn.kind == nnkProcDef: fn[0] else: fn
  echo fn_sym, "; ", fn_sym.typeKind, "; ", fn_sym.getType.repr, "; ", fn_sym.getTypeImpl.repr
  

proc voidProc = echo "hello"
proc intProc(a: int, b: float): int {.checkProcType.} = 10 

checkType(voidProc(), "void")
checkType(intProc(10, 20.0), "int")
checkType(voidProc, "procTy")
checkProcType(voidProc)
