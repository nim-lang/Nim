#
#
#           The Nim Compiler
#        (c) Copyright 2024 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

## Code specialization instead of the old, incredibly slow 'genericAssign'
## implementation.

proc specializeAssignT(p: BProc, destAccessor, srcAccessor: Rope, typ: PType)

proc specializeAssignN(p: BProc, destAccessor, srcAccessor: Rope, n: PNode;
                      typ: PType) =
  if n == nil: return
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      specializeAssignN(p, destAccessor, srcAccessor, n[i], typ)
  of nkRecCase:
    if (n[0].kind != nkSym): internalError(p.config, n.info, "specializeAssignN")
    let disc = n[0].sym
    if disc.loc.snippet == "": fillObjectFields(p.module, typ)
    if disc.loc.t == nil:
      internalError(p.config, n.info, "specializeAssignN()")
    let destDiscField = dotField(destAccessor, disc.loc.snippet)
    let srcDiscField = dotField(srcAccessor, disc.loc.snippet)
    
    # For case objects, we need to handle branch switching carefully
    # First, check if we need to reset the destination if branches differ
    p.s(cpsStmts).addSwitchStmt(srcDiscField):
      for i in 1..<n.len:
        let branch = n[i]
        assert branch.kind in {nkOfBranch, nkElse}
        var caseBuilder: SwitchCaseBuilder
        p.s(cpsStmts).addSwitchCase(caseBuilder):
          if branch.kind == nkOfBranch:
            genCaseRange(p, branch, caseBuilder)
          else:
            p.s(cpsStmts).addCaseElse(caseBuilder)
        do:
          specializeAssignN(p, destAccessor, srcAccessor, lastSon(branch), typ)
          p.s(cpsStmts).addBreak()
    # Assign the discriminator
    specializeAssignT(p, destDiscField, srcDiscField, disc.loc.t)
  of nkSym:
    let field = n.sym
    if field.typ.kind == tyVoid: return
    if field.loc.snippet == "": fillObjectFields(p.module, typ)
    if field.loc.t == nil:
      internalError(p.config, n.info, "specializeAssignN()")
    specializeAssignT(p, dotField(destAccessor, field.loc.snippet),
                      dotField(srcAccessor, field.loc.snippet), field.loc.t)
  else: internalError(p.config, n.info, "specializeAssignN()")

proc specializeAssignT(p: BProc, destAccessor, srcAccessor: Rope, typ: PType) =
  if typ == nil: return

  case typ.kind
  of tyGenericInst, tyGenericBody, tyTypeDesc, tyAlias, tyDistinct, tyInferred,
     tySink, tyOwned:
    specializeAssignT(p, destAccessor, srcAccessor, skipModifier(typ))
  of tyArray:
    let arraySize = lengthOrd(p.config, typ.indexType)
    if typ.elementType.kind in {tyString, tyRef, tySequence}:
      # Need element-wise assignment for GC-tracked types
      var i: TLoc = getTemp(p, getSysType(p.module.g.graph, unknownLineInfo, tyInt))
      p.s(cpsStmts).addForRangeExclusive(i.snippet, cIntValue(0), cIntValue(arraySize)):
        specializeAssignT(p, subscript(destAccessor, i.snippet),
                          subscript(srcAccessor, i.snippet), typ.elementType)
    elif containsGarbageCollectedRef(typ.elementType):
      # Complex elements that may contain GC refs
      var i: TLoc = getTemp(p, getSysType(p.module.g.graph, unknownLineInfo, tyInt))
      p.s(cpsStmts).addForRangeExclusive(i.snippet, cIntValue(0), cIntValue(arraySize)):
        specializeAssignT(p, subscript(destAccessor, i.snippet),
                          subscript(srcAccessor, i.snippet), typ.elementType)
    else:
      # Simple bulk copy for value types
      p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "nimCopyMem"),
        cCast(CPointer, destAccessor),
        cCast(CConstPointer, srcAccessor),
        cSizeof(getTypeDesc(p.module, typ)))
  of tyObject:
    var x = typ.baseClass
    if x != nil: x = x.skipTypes(skipPtrs)
    specializeAssignT(p, destAccessor.parentObj(p.module), srcAccessor.parentObj(p.module), x)
    if typ.n != nil:
      if typ.sym != nil and sfImportc in typ.sym.flags:
        # imported C struct, use nimCopyMem
        p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "nimCopyMem"),
          cCast(CPointer, cAddr(destAccessor)),
          cCast(CConstPointer, cAddr(srcAccessor)),
          cSizeof(getTypeDesc(p.module, typ)))
      else:
        specializeAssignN(p, destAccessor, srcAccessor, typ.n, typ)
  of tyTuple:
    let typ = getUniqueType(typ)
    for i, a in typ.ikids:
      specializeAssignT(p, dotField(destAccessor, "Field" & $i),
                        dotField(srcAccessor, "Field" & $i), a)
  of tyString, tyRef:
    # Use unsureAsgnRef for proper GC reference counting
    p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "unsureAsgnRef"),
      cCast(ptrType(CPointer), cAddr(destAccessor)),
      srcAccessor)
  of tySequence:
    when defined(nimSeqsV2):
      # For seq v2, we need deep assignment
      let elemType = typ.elementType
      if elemType.kind in {tyString, tyRef, tySequence} or containsGarbageCollectedRef(elemType):
        # Call genericAssign for complex sequence assignment
        # This is the one case where we still need the runtime function for now
        p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "genericAssign"),
          cCast(CPointer, cAddr(destAccessor)),
          cCast(CPointer, cAddr(srcAccessor)),
          genTypeInfoV1(p.module, typ, p.currLineInfo))
      else:
        # Simple sequence copy using unsureAsgnRef
        p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "unsureAsgnRef"),
          cCast(ptrType(CPointer), cAddr(destAccessor)),
          srcAccessor)
    else:
      # Legacy sequences, use unsureAsgnRef or genericAssign
      if containsGarbageCollectedRef(typ.elementType):
        p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "genericAssign"),
          cCast(CPointer, cAddr(destAccessor)),
          cCast(CPointer, cAddr(srcAccessor)),
          genTypeInfoV1(p.module, typ, p.currLineInfo))
      else:
        p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "unsureAsgnRef"),
          cCast(ptrType(CPointer), cAddr(destAccessor)),
          srcAccessor)
  of tyProc:
    if typ.callConv == ccClosure:
      # Closures need special handling for environment
      p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "unsureAsgnRef"),
        cCast(ptrType(CPointer), cAddr(dotField(destAccessor, "ClE_0"))),
        dotField(srcAccessor, "ClE_0"))
      p.s(cpsStmts).addFieldAssignment(destAccessor, "ClP_0",
                                       dotField(srcAccessor, "ClP_0"))
    else:
      p.s(cpsStmts).addAssignment(destAccessor, srcAccessor)
  of tyChar, tyBool, tyEnum, tyRange, tyInt..tyUInt64:
    p.s(cpsStmts).addAssignment(destAccessor, srcAccessor)
  of tyCstring, tyPointer, tyPtr:
    p.s(cpsStmts).addAssignment(destAccessor, srcAccessor)
  of tyVar, tyLent:
    # vars/lents are references, just copy the pointer
    p.s(cpsStmts).addAssignment(destAccessor, srcAccessor)
  of tySet:
    case mapSetType(p.config, typ)
    of ctArray:
      let t = getTypeDesc(p.module, typ)
      p.s(cpsStmts).addCallStmt(cgsymValue(p.module, "nimCopyMem"),
        destAccessor,
        srcAccessor,
        cSizeof(t))
    of ctInt8, ctInt16, ctInt32, ctInt64:
      p.s(cpsStmts).addAssignment(destAccessor, srcAccessor)
    else:
      raiseAssert "unexpected set type kind"
  of tyNone, tyEmpty, tyNil, tyUntyped, tyTyped, tyGenericInvocation,
      tyGenericParam, tyOrdinal, tyOpenArray, tyForward, tyVarargs,
      tyUncheckedArray, tyError, tyBuiltInTypeClass, tyUserTypeClass,
      tyUserTypeClassInst, tyCompositeTypeClass, tyAnd, tyOr, tyNot,
      tyAnything, tyStatic, tyFromExpr, tyConcept, tyVoid, tyIterable:
    discard

proc specializeAssign(p: BProc, dest, src: TLoc) =
  specializeAssignT(p, rdLoc(dest), rdLoc(src), dest.t)
