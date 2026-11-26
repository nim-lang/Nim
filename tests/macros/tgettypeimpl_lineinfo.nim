discard """
  action: run
"""

# `getTypeImpl` must not hand out the type's own field symbol nodes:
# changing the line info of a returned name changed it for every later
# `getTypeImpl` of the same type.

import std/macros

type
  Obj = object
    field: int
  Tup = tuple[field: int]
  Prc = proc(param: int)

proc nameNode(T: NimNode): NimNode =
  let impl = T.getTypeInst[1].getTypeImpl
  case impl.kind
  of nnkObjectTy: impl[2][0][0]
  of nnkTupleTy: impl[0][0]
  of nnkProcTy: impl[0][1][0]
  else: raiseAssert $impl.kind

macro nameInfo(T: typedesc): string =
  newLit T.nameNode.lineInfo

macro changeNameInfo(T: typedesc): untyped =
  T.nameNode.setLineInfo("changed.nim", 1, 1)
  newEmptyNode()

const
  objInfo = nameInfo(Obj)
  tupInfo = nameInfo(Tup)
  prcInfo = nameInfo(Prc)

changeNameInfo(Obj)
changeNameInfo(Tup)
changeNameInfo(Prc)

doAssert nameInfo(Obj) == objInfo, nameInfo(Obj) & " != " & objInfo
doAssert nameInfo(Tup) == tupInfo, nameInfo(Tup) & " != " & tupInfo
doAssert nameInfo(Prc) == prcInfo, nameInfo(Prc) & " != " & prcInfo
