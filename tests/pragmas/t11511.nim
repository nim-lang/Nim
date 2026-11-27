# bug #11511: custom pragmas of a field symbol as `getType` produces it
import macros

template myAttr {.pragma.}
template val(x: int) {.pragma.}

type
  TObj = object
    a {.myAttr.}: int
    b: int
  G[T] = object of RootObj
    x {.myAttr, val(3).}: T
  H = object of G[int]
    y {.val(4).}: int
  R = ref object
    z* {.myAttr.}: int

macro check(t: typedesc): untyped =
  var ty = t.getType[1]
  if ty.typeKind == ntyRef: ty = ty[1]
  ty = ty.getType
  result = nnkBracket.newTree()
  for f in ty[2]:
    result.add newCall(bindSym"hasCustomPragma", f, bindSym"myAttr")

doAssert check(TObj) == [true, false]
doAssert check(G[int]) == [true]
doAssert check(H) == [false]
doAssert check(R) == [true]

macro values(t: typedesc): untyped =
  result = nnkBracket.newTree()
  for f in t.getType[1].getType[2]:
    result.add newCall(bindSym"getCustomPragmaVal", f, bindSym"val")

doAssert values(G[int]) == [3]
doAssert values(H) == [4]
