#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

## Code specialization instead of the old, incredibly slow 'genericReset'
## implementation.

proc specializeResetT(p: BProc, accessor: Rope, typ: PType)

proc specializeResetN(p: BProc, accessor: Rope, n: PNode;
                     typ: PType) =
  if n == nil: return
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      specializeResetN(p, accessor, n[i], typ)
  of nkRecCase:
    if (n[0].kind != nkSym): internalError(p.config, n.info, "specializeResetN")
    let disc = n[0].sym
    if disc.loc.r == nil: fillObjectFields(p.module, typ)
    if disc.loc.t == nil:
      internalError(p.config, n.info, "specializeResetN()")
    lineF(p, cpsStmts, "switch ($1.$2) {$n", [accessor, disc.loc.r])
    for i in 1..<n.len:
      let branch = n[i]
      assert branch.kind in {nkOfBranch, nkElse}
      if branch.kind == nkOfBranch:
        genCaseRange(p, branch)
      else:
        lineF(p, cpsStmts, "default:$n", [])
      specializeResetN(p, accessor, lastSon(branch), typ)
      lineF(p, cpsStmts, "break;$n", [])
    lineF(p, cpsStmts, "} $n", [])
    specializeResetT(p, "$1.$2" % [accessor, disc.loc.r], disc.loc.t)
  of nkSym:
    let field = n.sym
    if field.typ.kind == tyVoid: return
    if field.loc.r == nil: fillObjectFields(p.module, typ)
    if field.loc.t == nil:
      internalError(p.config, n.info, "specializeResetN()")
    specializeResetT(p, "$1.$2" % [accessor, field.loc.r], field.loc.t)
  else: internalError(p.config, n.info, "specializeResetN()")

proc specializeResetT(p: BProc, accessor: Rope, typ: PType) =
  if typ == nil: return

  case typ.kind
  of tyGenericInst, tyGenericBody, tyTypeDesc, tyAlias, tyDistinct, tyInferred,
     tySink, tyOwned:
    specializeResetT(p, accessor, lastSon(typ))
  of tyArray:
    let arraySize = lengthOrd(p.config, typ[0])
    var i: TLoc
    getTemp(p, getSysType(p.module.g.graph, unknownLineInfo, tyInt), i)
    linefmt(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",
            [i.r, arraySize])
    specializeResetT(p, ropecg(p.module, "$1[$2]", [accessor, i.r]), typ[1])
    lineF(p, cpsStmts, "}$n", [])
  of tyObject:
    for i in 0..<typ.len:
      var x = typ[i]
      if x != nil: x = x.skipTypes(skipPtrs)
      specializeResetT(p, accessor.parentObj(p.module), x)
    if typ.n != nil: specializeResetN(p, accessor, typ.n, typ)
  of tyTuple:
    let typ = getUniqueType(typ)
    for i in 0..<typ.len:
      specializeResetT(p, ropecg(p.module, "$1.Field$2", [accessor, i]), typ[i])

  of tyString, tyRef, tySequence:
    lineCg(p, cpsStmts, "#unsureAsgnRef((void**)&$1, NIM_NIL);$n", [accessor])

  of tyProc:
    if typ.callConv == ccClosure:
      lineCg(p, cpsStmts, "#unsureAsgnRef((void**)&$1.ClE_0, NIM_NIL);$n", [accessor])
      lineCg(p, cpsStmts, "$1.ClP_0 = NIM_NIL;$n", [accessor])
    else:
      lineCg(p, cpsStmts, "$1 = NIM_NIL;$n", [accessor])
  of tyChar, tyBool, tyEnum, tyInt..tyUInt64:
    lineCg(p, cpsStmts, "$1 = 0;$n", [accessor])
  of tyCstring, tyPointer, tyPtr, tyVar, tyLent:
    lineCg(p, cpsStmts, "$1 = NIM_NIL;$n", [accessor])
  of tySet:
    case mapSetType(p.config, typ)
    of ctArray:
      lineCg(p, cpsStmts, "#nimZeroMem($1, sizeof($2));$n",
          [accessor, getTypeDesc(p.module, typ)])
    of ctInt8, ctInt16, ctInt32, ctInt64:
      lineCg(p, cpsStmts, "$1 = 0;$n", [accessor])
    else:
      doAssert false, "unexpected set type kind"
  of {tyNone, tyEmpty, tyNil, tyUntyped, tyTyped, tyGenericInvocation,
      tyGenericParam, tyOrdinal, tyRange, tyOpenArray, tyForward, tyVarargs,
      tyUncheckedArray, tyProxy, tyBuiltInTypeClass, tyUserTypeClass,
      tyUserTypeClassInst, tyCompositeTypeClass, tyAnd, tyOr, tyNot,
      tyAnything, tyStatic, tyFromExpr, tyConcept, tyVoid, tyIterable}:
    discard

proc specializeReset(p: BProc, a: TLoc) =
  specializeResetT(p, rdLoc(a), a.t)
