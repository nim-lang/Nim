discard """
  nimout: "proc (x: int; y: float): int {.nimcall.}"
"""

# bug #11496
import std/macros

{.experimental: "dynamicBindSym".}

proc foo(x: int; y: float): int = x

macro macroB(call: untyped): untyped =
  let inst = call.findChild(it.kind == nnkIdent).strVal.bindSym().getTypeInst()
  echo inst.repr

macroB(foo(2, 2'f))
