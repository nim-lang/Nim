#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Accessors for the arguments and the result of a VM callback. Included
## from vm.nim. The arguments live in the VM's stack frame: scalars are
## widened to 64 bits, other values use the VM's memory layout.

import pathutils

when defined(nimPreviewSlimSystem):
  import std/assertions

proc ctx(a: VmArgs): PCtx {.inline.} = cast[PCtx](a.ctxp)

proc numArgs*(a: VmArgs): int =
  result = a.shape.paramOffsets.len

proc argAddr(a: VmArgs; i: Natural): Address =
  doAssert i < a.shape.paramOffsets.len
  result = a.args +! a.shape.paramOffsets[i]

proc getInt*(a: VmArgs; i: Natural): BiggestInt = ld[int64](argAddr(a, i))
proc getBool*(a: VmArgs; i: Natural): bool = getInt(a, i) != 0
proc getFloat*(a: VmArgs; i: Natural): BiggestFloat = ld[float64](argAddr(a, i))

proc getString*(a: VmArgs; i: Natural): string =
  let t = a.shape.paramTypes[i].skipTypes(abstractInst+{tyStatic, tySink, tyOwned})
  if t.kind == tyCstring:
    result = readCString(a.ctx, ld[Address](argAddr(a, i)))
  else:
    result = readString(a.ctx, argAddr(a, i))

proc getNode*(a: VmArgs; i: Natural): PNode =
  ## the argument `i` as a NimNode, or as a literal AST for other types
  let t = a.shape.paramTypes[i]
  result = regToNode(a.ctx, argAddr(a, i), t, a.currentLineInfo)

proc getVar*(a: VmArgs; i: Natural): Address =
  ## the address that a `var` parameter refers to
  result = ld[Address](argAddr(a, i))

proc getVarString*(a: VmArgs; i: Natural): string =
  result = readString(a.ctx, getVar(a, i))

proc setVarString*(a: VmArgs; i: Natural; s: string) =
  assignString(a.ctx, getVar(a, i), s)

proc setResult*(a: VmArgs; v: BiggestInt) = st[int64](a.res, v)
proc setResult*(a: VmArgs; v: BiggestFloat) = st[float64](a.res, v)
proc setResult*(a: VmArgs; v: bool) = st[int64](a.res, ord(v))

proc setResult*(a: VmArgs; v: string) =
  storeString(a.ctx.mem, a.res, v, inConst = false)

proc setResult*(a: VmArgs; n: PNode) =
  let t = a.shape.resultType
  if t == nil: return
  nodeToReg(a.ctx, n, t, a.res)

proc setResultRef*(a: VmArgs; p: Address) =
  ## returns a `ref`; the callee owns it, so we count the reference
  if p != 0: incRef(p)
  st[Address](a.res, p)

proc setResult*(a: VmArgs; v: AbsoluteDir) = setResult(a, v.string)

proc setResult*(a: VmArgs; v: seq[string]) =
  var n = newNode(nkBracket)
  for x in v: n.add newStrNode(nkStrLit, x)
  setResult(a, n)

proc setResult*(a: VmArgs; v: (BiggestInt, BiggestInt)) =
  var tuplen = newNode(nkTupleConstr)
  tuplen.add newIntNode(nkIntLit, v[0])
  tuplen.add newIntNode(nkIntLit, v[1])
  setResult(a, tuplen)
