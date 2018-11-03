#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[
Precise stack root enumerations for Nim's GCs
---------------------------------------------

The code generator produces the maximum efficient code for
stack roots (which is not really good, but since this is for
async code where the stack was mostly eliminated anyway, it is
not too bad):

onProcEntry:
  let tmp = rootsLen
  if tmp + 12 < nimPreciseStackRoots:
    roots[tmp] = addr localRef
    roots[tmp+1] = addr localTuple.someRef
    for i in 0..3:
      roots[tmp+1+i] = addr localArray[i]
    for i in 0..4:
      for j in 0..2:
        roots[tmp+1+(i*3)+j] = addr localArray[i][j]

  # we ALWAYS inc here, the GC knows that if rootsLen >= nimPreciseStackRoots
  # we had an overflow and should disable its collections.
  rootsLen += 12

onProcExit:
  rootLen = tmp

]##

proc preciseStackRoots(m: BModule): int =
  if m.g.nimPreciseStackRoots == 0:
    let core = getCompilerProc(m.g.graph, "nimPreciseStackRoots")
    if core == nil or core.kind != skConst:
      m.g.nimPreciseStackRoots = -1
    else:
      m.g.nimPreciseStackRoots = int ast.getInt(core.ast)
  result = m.g.nimPreciseStackRoots

type
  LocalRootsCtx = object
    info: TLineInfo
    indexes: seq[Rope]

proc registerLocalRoot(p: BProc; c: var LocalRootsCtx, accessor: Rope, typ: PType): Rope
proc registerLocalRoot(p: BProc; c: var LocalRootsCtx, accessor: Rope, n: PNode;
                       typ: PType): Rope =
  if n == nil: return
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      result.add registerLocalRoot(p, c, accessor, n.sons[i], typ)
  of nkRecCase:
    localError(p.config, c.info, "cannot create 'case object' on the stack")
  of nkSym:
    let field = n.sym
    if field.typ.kind == tyVoid: return
    if field.loc.r == nil: fillObjectFields(p.module, typ)
    if field.loc.t == nil:
      internalError(p.config, n.info, "registerLocalRoot()")
    result = registerLocalRoot(p, c, "$1.$2" % [accessor, field.loc.r], field.loc.t)
  else: internalError(p.config, n.info, "registerLocalRoot()")

proc indexExpr(p: BProc; c: LocalRootsCtx): Rope =
  result = "GR_+$2" % [rope p.gcFrameLen]
  for index in c.indexes:
    result.add("+")
    result.add(index)

proc registerLocalRoot(p: BProc; c: var LocalRootsCtx, accessor: Rope, typ: PType): Rope =
  if typ == nil: return
  case typ.kind
  of tyGenericInst, tyGenericBody, tyTypeDesc, tyAlias, tyDistinct, tyInferred,
     tySink:
    result = registerLocalRoot(p, c, accessor, lastSon(typ))
  of tyArray:
    let arraySize = lengthOrd(p.config, typ.sons[0])
    if arraySize == 0: return
    let oldSlots = p.gcFrameLen

    inc(p.labels)
    let i = "T" & rope(p.labels) & "_"

    var oldIndex: Rope = nil
    if c.indexes.len > 0:
      oldIndex = c.indexes[^1]
      c.indexes[^1] = "($1*$2)" % [oldIndex, rope(arraySize)]
    c.indexes.add i
    let loopBody = registerLocalRoot(p, c, "$1[$2]" % [accessor, i], typ.sons[1])
    if p.gcFrameLen == oldSlots:
      doAssert loopBody == nil, "loopBody should really have been empty here"
      discard "turned out the array has no refs at all"
    else:
      let perArrayElem = p.gcFrameLen - oldSlots
      p.gcFrameLen = oldSlots + (perArrayElem * arraySize)
      result = "for ($1 = 0; $1 < $2; $1++) {$n$3};$n" % [i, arraySize.rope, loopBody]
    discard c.indexes.pop()
    if oldIndex != nil:
      c.indexes[^1] = oldIndex
  of tyObject:
    for i in countup(0, sonsLen(typ) - 1):
      var x = typ.sons[i]
      if x != nil: x = x.skipTypes(skipPtrs)
      result.add registerLocalRoot(p, c, accessor.parentObj(p.module), x)
    if typ.n != nil:
      result.add registerLocalRoot(p, c, accessor, typ.n, typ)
  of tyTuple:
    let typ = getUniqueType(typ)
    for i in countup(0, sonsLen(typ) - 1):
      result.add registerLocalRoot(p, c, "$1.Field$2" % [accessor, i.rope], typ.sons[i])
  of tyRef:
    result = ropecg(p.module, "#nimRoots[$1] = (void*) &$2;", [indexExpr(p, c), accessor])
    inc p.gcFrameLen
  of tySequence, tyString:
    if tfHasAsgn notin typ.flags:
      result = ropecg(p.module, "#nimRoots[$1] = (void*) &$2;", [indexExpr(p, c), accessor])
      inc p.gcFrameLen
  of tyProc:
    if typ.callConv == ccClosure:
      result = ropecg(p.module, "#nimRoots[$1] = (void*) &$2.ClE_0;", [indexExpr(p, c), accessor])
      inc p.gcFrameLen
  else:
    result = nil

proc declarePreciseStackRoot(p: BProc; t: PType; name: Rope) =
  addf(p.procSec(cpsLocals), "$1 $2;$n", [getTypeDesc(p.module, t), name])
  var c = LocalRootsCtx(info: unknownLineInfo(), indexes: @[])
  add p.prolog, registerLocalRoot(p, c, name, t)

proc initGCFrame(p: BProc): Rope =
  if p.gcFrameLen > 0:
    result = ropecg(p.module,
      "GR_ = #nimRootsLen; if (GR_ + $1 < $2) {$n$3$n}$n#nimRootsLen += $1;$n", [
      rope(p.gcFrameLen), rope preciseStackRoots(p.module), p.prolog])

proc deinitGCFrame(p: BProc): Rope =
  if p.gcFrameLen > 0:
    result = ropecg(p.module, "#nimRootsLen = GR_;")
