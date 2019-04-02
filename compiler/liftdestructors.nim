#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements lifting for type-bound operations
## (``=sink``, ``=``, ``=destroy``, ``=deepCopy``).

# included from sempass2.nim

# Todo:
# - specialize destructors for constant arrays of strings
#   (they don't require any)
# - use openArray instead of array to avoid over-specializations
# - make 'owned' mean 'sink' in parameters

import sighashes

type
  TLiftCtx = object
    graph: ModuleGraph
    info: TLineInfo # for construction
    kind: TTypeAttachedOp
    fn: PSym
    asgnForType: PType
    recurse: bool
    c: PContext

proc liftBodyAux(c: var TLiftCtx; t: PType; body, x, y: PNode)
proc liftBody(c: PContext; typ: PType; kind: TTypeAttachedOp;
              info: TLineInfo): PSym {.discardable.}

proc at(a, i: PNode, elemType: PType): PNode =
  result = newNodeI(nkBracketExpr, a.info, 2)
  result.sons[0] = a
  result.sons[1] = i
  result.typ = elemType

proc liftBodyTup(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  for i in 0 ..< t.len:
    let lit = lowerings.newIntLit(c.graph, x.info, i)
    liftBodyAux(c, t.sons[i], body, x.at(lit, t.sons[i]), y.at(lit, t.sons[i]))

proc dotField(x: PNode, f: PSym): PNode =
  result = newNodeI(nkDotExpr, x.info, 2)
  result.sons[0] = x
  result.sons[1] = newSymNode(f, x.info)
  result.typ = f.typ

proc liftBodyObj(c: var TLiftCtx; n, body, x, y: PNode) =
  case n.kind
  of nkSym:
    let f = n.sym
    liftBodyAux(c, f.typ, body, x.dotField(f), y.dotField(f))
  of nkNilLit: discard
  of nkRecCase:
    if c.kind in {attachedSink, attachedAsgn, attachedDeepCopy}:
      ## the value needs to be destroyed before we assign the selector
      ## or the value is lost
      let prevKind = c.kind
      c.kind = attachedDestructor
      liftBodyObj(c, n, body, x, y)
      c.kind = prevKind

    # copy the selector:
    liftBodyObj(c, n[0], body, x, y)
    # we need to generate a case statement:
    var caseStmt = newNodeI(nkCaseStmt, c.info)
    # XXX generate 'if' that checks same branches
    # generate selector:
    var access = dotField(x, n[0].sym)
    caseStmt.add(access)
    # copy the branches over, but replace the fields with the for loop body:
    for i in 1 ..< n.len:
      var branch = copyTree(n[i])
      let L = branch.len
      branch.sons[L-1] = newNodeI(nkStmtList, c.info)

      liftBodyObj(c, n[i].lastSon, branch.sons[L-1], x, y)
      caseStmt.add(branch)
    body.add(caseStmt)
  of nkRecList:
    for t in items(n): liftBodyObj(c, t, body, x, y)
  else:
    illFormedAstLocal(n, c.graph.config)

proc genAddr(g: ModuleGraph; x: PNode): PNode =
  if x.kind == nkHiddenDeref:
    checkSonsLen(x, 1, g.config)
    result = x.sons[0]
  else:
    result = newNodeIT(nkHiddenAddr, x.info, makeVarType(x.typ.owner, x.typ))
    addSon(result, x)

proc newAsgnCall(g: ModuleGraph; op: PSym; x, y: PNode): PNode =
  #if sfError in op.flags:
  #  localError(c.config, x.info, "usage of '$1' is a user-defined error" % op.name.s)
  result = newNodeI(nkCall, x.info)
  result.add newSymNode(op)
  result.add genAddr(g, x)
  result.add y

proc newAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc newOpCall(op: PSym; x: PNode): PNode =
  result = newNodeIT(nkCall, x.info, op.typ.sons[0])
  result.add(newSymNode(op))
  result.add x

proc destructorCall(g: ModuleGraph; op: PSym; x: PNode): PNode =
  result = newNodeIT(nkCall, x.info, op.typ.sons[0])
  result.add(newSymNode(op))
  result.add genAddr(g, x)

proc newDeepCopyCall(op: PSym; x, y: PNode): PNode =
  result = newAsgnStmt(x, newOpCall(op, y))

proc useNoGc(c: TLiftCtx; t: PType): bool {.inline.} =
  result = optNimV2 in c.graph.config.globalOptions and
    (tfHasGCedMem in t.flags or t.isGCedMem)

proc considerAsgnOrSink(c: var TLiftCtx; t: PType; body, x, y: PNode;
                        field: var PSym): bool =
  if optNimV2 in c.graph.config.globalOptions:
    let op = field
    if field != nil and sfOverriden in field.flags:
      if sfError in op.flags:
        incl c.fn.flags, sfError
      else:
        markUsed(c.graph.config, c.info, op, c.graph.usageSym)
      onUse(c.info, op)
      body.add newAsgnCall(c.graph, op, x, y)
      result = true
  elif tfHasAsgn in t.flags:
    var op: PSym
    if sameType(t, c.asgnForType):
      # generate recursive call:
      if c.recurse:
        op = c.fn
      else:
        c.recurse = true
        return false
    else:
      op = field
      if op == nil:
        op = liftBody(c.c, t, c.kind, c.info)
    if sfError in op.flags:
      incl c.fn.flags, sfError
    else:
      markUsed(c.graph.config, c.info, op, c.graph.usageSym)
    onUse(c.info, op)
    # We also now do generic instantiations in the destructor lifting pass:
    if op.ast[genericParamsPos].kind != nkEmpty:
      assert t.typeInst != nil
      op = c.c.instTypeBoundOp(c.c, op, t.typeInst, c.info, attachedAsgn, 1)
      field = op
      #echo "trying to use ", op.ast
      #echo "for ", op.name.s, " "
      #debug(t)
      #return false
    assert op.ast[genericParamsPos].kind == nkEmpty
    body.add newAsgnCall(c.graph, op, x, y)
    result = true

proc addDestructorCall(c: var TLiftCtx; t: PType; body, x: PNode): bool =
  var op = t.destructor
  if op == nil and useNoGc(c, t):
    op = liftBody(c.c, t, attachedDestructor, c.info)
    doAssert op != nil
    doAssert op == t.destructor

  if op != nil:
    markUsed(c.graph.config, c.info, op, c.graph.usageSym)
    onUse(c.info, op)
    body.add destructorCall(c.graph, op, x)
    result = true
  elif useNoGc(c, t):
    internalError(c.graph.config, c.info,
      "type-bound operator could not be resolved")

proc considerUserDefinedOp(c: var TLiftCtx; t: PType; body, x, y: PNode): bool =
  case c.kind
  of attachedDestructor:
    var op = t.destructor
    if op != nil and sfOverriden in op.flags:

      if op.ast[genericParamsPos].kind != nkEmpty:
        assert t.typeInst != nil
        # patch generic destructor:
        op = c.c.instTypeBoundOp(c.c, op, t.typeInst, c.info, attachedAsgn, 1)
        t.destructor = op

      markUsed(c.graph.config, c.info, op, c.graph.usageSym)
      onUse(c.info, op)
      body.add destructorCall(c.graph, op, x)
      result = true
    #result = addDestructorCall(c, t, body, x)
  of attachedAsgn:
    result = considerAsgnOrSink(c, t, body, x, y, t.assignment)
  of attachedSink:
    result = considerAsgnOrSink(c, t, body, x, y, t.sink)
  of attachedDeepCopy:
    let op = t.deepCopy
    if op != nil:
      markUsed(c.graph.config, c.info, op, c.graph.usageSym)
      onUse(c.info, op)
      body.add newDeepCopyCall(op, x, y)
      result = true

proc defaultOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  if c.kind != attachedDestructor:
    body.add newAsgnStmt(x, y)

proc addVar(father, v, value: PNode) =
  var vpart = newNodeI(nkIdentDefs, v.info, 3)
  vpart.sons[0] = v
  vpart.sons[1] = newNodeI(nkEmpty, v.info)
  vpart.sons[2] = value
  addSon(father, vpart)

proc declareCounter(c: var TLiftCtx; body: PNode; first: BiggestInt): PNode =
  var temp = newSym(skTemp, getIdent(c.graph.cache, lowerings.genPrefix), c.fn, c.info)
  temp.typ = getSysType(c.graph, body.info, tyInt)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, c.info)
  result = newSymNode(temp)
  v.addVar(result, lowerings.newIntLit(c.graph, body.info, first))
  body.add v

proc genBuiltin(g: ModuleGraph; magic: TMagic; name: string; i: PNode): PNode =
  result = newNodeI(nkCall, i.info)
  result.add createMagic(g, name, magic).newSymNode
  result.add i

proc genWhileLoop(c: var TLiftCtx; i, dest: PNode): PNode =
  result = newNodeI(nkWhileStmt, c.info, 2)
  let cmp = genBuiltin(c.graph, mLtI, "<", i)
  cmp.add genLen(c.graph, dest)
  cmp.typ = getSysType(c.graph, c.info, tyBool)
  result.sons[0] = cmp
  result.sons[1] = newNodeI(nkStmtList, c.info)

proc genIf(c: var TLiftCtx; cond, action: PNode): PNode =
  result = newTree(nkIfStmt, newTree(nkElifBranch, cond, action))

proc addIncStmt(c: var TLiftCtx; body, i: PNode) =
  let incCall = genBuiltin(c.graph, mInc, "inc", i)
  incCall.add lowerings.newIntLit(c.graph, c.info, 1)
  body.add incCall

proc newSeqCall(g: ModuleGraph; x, y: PNode): PNode =
  # don't call genAddr(c, x) here:
  result = genBuiltin(g, mNewSeq, "newSeq", x)
  let lenCall = genBuiltin(g, mLengthSeq, "len", y)
  lenCall.typ = getSysType(g, x.info, tyInt)
  result.add lenCall

proc setLenStrCall(g: ModuleGraph; x, y: PNode): PNode =
  let lenCall = genBuiltin(g, mLengthStr, "len", y)
  lenCall.typ = getSysType(g, x.info, tyInt)
  result = genBuiltin(g, mSetLengthStr, "setLen", genAddr(g, x))
  result.add lenCall

proc setLenSeqCall(c: var TLiftCtx; t: PType; x, y: PNode): PNode =
  let lenCall = genBuiltin(c.graph, mLengthSeq, "len", y)
  lenCall.typ = getSysType(c.graph, x.info, tyInt)
  var op = getSysMagic(c.graph, x.info, "setLen", mSetLengthSeq)
  op = c.c.instTypeBoundOp(c.c, op, t, c.info, attachedAsgn, 1)
  result = newTree(nkCall, newSymNode(op, x.info), genAddr(c.graph, x), lenCall)

proc forallElements(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  let i = declareCounter(c, body, firstOrd(c.graph.config, t))
  let whileLoop = genWhileLoop(c, i, x)
  let elemType = t.lastSon
  liftBodyAux(c, elemType, whileLoop.sons[1], x.at(i, elemType),
                                              y.at(i, elemType))
  addIncStmt(c, whileLoop.sons[1], i)
  body.add whileLoop

proc seqOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  case c.kind
  of attachedAsgn, attachedDeepCopy:
    # we generate:
    # setLen(dest, y.len)
    # var i = 0
    # while i < y.len: dest[i] = y[i]; inc(i)
    # This is usually more efficient than a destroy/create pair.
    body.add setLenSeqCall(c, t, x, y)
    forallElements(c, t, body, x, y)
  of attachedSink:
    let moveCall = genBuiltin(c.graph, mMove, "move", x)
    moveCall.add y
    doAssert t.destructor != nil
    moveCall.add destructorCall(c.graph, t.destructor, x)
    body.add moveCall
  of attachedDestructor:
    # destroy all elements:
    forallElements(c, t, body, x, y)
    body.add genBuiltin(c.graph, mDestroy, "destroy", x)

proc strOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  case c.kind
  of attachedAsgn, attachedDeepCopy:
    # we generate:
    # setLen(dest, y.len)
    # var i = 0
    # while i < y.len: dest[i] = y[i]; inc(i)
    # This is usually more efficient than a destroy/create pair.
    body.add setLenStrCall(c.graph, x, y)
    forallElements(c, t, body, x, y)
  of attachedSink:
    let moveCall = genBuiltin(c.graph, mMove, "move", x)
    moveCall.add y
    doAssert t.destructor != nil
    moveCall.add destructorCall(c.graph, t.destructor, x)
    body.add moveCall
  of attachedDestructor:
    body.add genBuiltin(c.graph, mDestroy, "destroy", x)

proc weakrefOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  case c.kind
  of attachedSink:
    # we 'nil' y out afterwards so we *need* to take over its reference
    # count value:
    body.add genIf(c, x, callCodegenProc(c.graph, "nimDecWeakRef", c.info, x))
    body.add newAsgnStmt(x, y)
  of attachedAsgn:
    body.add callCodegenProc(c.graph, "nimIncWeakRef", c.info, y)
    body.add genIf(c, x, callCodegenProc(c.graph, "nimDecWeakRef", c.info, x))
    body.add newAsgnStmt(x, y)
  of attachedDestructor:
    body.add genIf(c, x, callCodegenProc(c.graph, "nimDecWeakRef", c.info, x))
  of attachedDeepCopy: assert(false, "cannot happen")

proc ownedRefOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  var actions = newNodeI(nkStmtList, c.info)

  let elemType = t.lastSon
  #liftBodyAux(c, elemType, actions, genDeref(x), genDeref(y))
  #var disposeCall = genBuiltin(c.graph, mDispose, "dispose", x)

  if isFinal(elemType):
    discard addDestructorCall(c, elemType, actions, genDeref(x))
    actions.add callCodegenProc(c.graph, "nimRawDispose", c.info, x)
  else:
    discard addDestructorCall(c, elemType, newNodeI(nkStmtList, c.info), genDeref(x))
    actions.add callCodegenProc(c.graph, "nimDestroyAndDispose", c.info, x)

  case c.kind
  of attachedSink, attachedAsgn:
    body.add genIf(c, x, actions)
    body.add newAsgnStmt(x, y)
  of attachedDestructor:
    body.add genIf(c, x, actions)
  of attachedDeepCopy: assert(false, "cannot happen")

proc closureOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  if c.kind == attachedDeepCopy:
    # a big problem is that we don't know the enviroment's type here, so we
    # have to go through some indirection; we delegate this to the codegen:
    let call = newNodeI(nkCall, c.info, 2)
    call.typ = t
    call.sons[0] = newSymNode(createMagic(c.graph, "deepCopy", mDeepCopy))
    call.sons[1] = y
    body.add newAsgnStmt(x, call)
  elif optNimV2 in c.graph.config.globalOptions:
    let xx = genBuiltin(c.graph, mAccessEnv, "accessEnv", x)
    case c.kind
    of attachedSink:
      # we 'nil' y out afterwards so we *need* to take over its reference
      # count value:
      body.add genIf(c, xx, callCodegenProc(c.graph, "nimDecWeakRef", c.info, xx))
      body.add newAsgnStmt(x, y)
    of attachedAsgn:
      body.add callCodegenProc(c.graph, "nimIncWeakRef", c.info, y)
      body.add genIf(c, xx, callCodegenProc(c.graph, "nimDecWeakRef", c.info, xx))
      body.add newAsgnStmt(x, y)
    of attachedDestructor:
      body.add genIf(c, xx, callCodegenProc(c.graph, "nimDecWeakRef", c.info, xx))
    of attachedDeepCopy: assert(false, "cannot happen")

proc ownedClosureOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  let xx = genBuiltin(c.graph, mAccessEnv, "accessEnv", x)
  var actions = newNodeI(nkStmtList, c.info)
  let elemType = t.lastSon
  discard addDestructorCall(c, elemType, newNodeI(nkStmtList, c.info), genDeref(xx))
  actions.add callCodegenProc(c.graph, "nimDestroyAndDispose", c.info, xx)
  case c.kind
  of attachedSink, attachedAsgn:
    body.add genIf(c, xx, actions)
    body.add newAsgnStmt(x, y)
  of attachedDestructor:
    body.add genIf(c, xx, actions)
  of attachedDeepCopy: assert(false, "cannot happen")

proc liftBodyAux(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  case t.kind
  of tyNone, tyEmpty, tyVoid: discard
  of tyPointer, tySet, tyBool, tyChar, tyEnum, tyInt..tyUInt64, tyCString,
      tyPtr, tyOpt, tyUncheckedArray:
    defaultOp(c, t, body, x, y)
  of tyRef:
    if optNimV2 in c.graph.config.globalOptions:
      weakrefOp(c, t, body, x, y)
    else:
      defaultOp(c, t, body, x, y)
  of tyProc:
    if t.callConv == ccClosure:
      closureOp(c, t, body, x, y)
    else:
      defaultOp(c, t, body, x, y)
  of tyOwned:
    let base = t.skipTypes(abstractInstOwned)
    if optNimV2 in c.graph.config.globalOptions:
      case base.kind
      of tyRef:
        ownedRefOp(c, base, body, x, y)
        return
      of tyProc:
        if base.callConv == ccClosure:
          ownedClosureOp(c, base, body, x, y)
          return
      else: discard
    defaultOp(c, base, body, x, y)
  of tyArray:
    if tfHasAsgn in t.flags or useNoGc(c, t):
      forallElements(c, t, body, x, y)
    else:
      defaultOp(c, t, body, x, y)
  of tySequence:
    if useNoGc(c, t):
      seqOp(c, t, body, x, y)
    elif c.graph.config.selectedGC == gcDestructors:
      # note that tfHasAsgn is propagated so we need the check on
      # 'selectedGC' here to determine if we have the new runtime.
      discard considerUserDefinedOp(c, t, body, x, y)
    elif tfHasAsgn in t.flags:
      if c.kind != attachedDestructor:
        body.add newSeqCall(c.graph, x, y)
      forallElements(c, t, body, x, y)
    else:
      defaultOp(c, t, body, x, y)
  of tyString:
    if useNoGc(c, t):
      strOp(c, t, body, x, y)
    elif tfHasAsgn in t.flags:
      discard considerUserDefinedOp(c, t, body, x, y)
    else:
      defaultOp(c, t, body, x, y)
  of tyObject:
    if not considerUserDefinedOp(c, t, body, x, y):
      liftBodyObj(c, t.n, body, x, y)
  of tyDistinct:
    if not considerUserDefinedOp(c, t, body, x, y):
      liftBodyAux(c, t.sons[0].skipTypes(skipPtrs), body, x, y)
  of tyTuple:
    liftBodyTup(c, t, body, x, y)
  of tyVarargs, tyOpenArray:
    localError(c.graph.config, c.info, "cannot copy openArray")
  of tyFromExpr, tyProxy, tyBuiltInTypeClass, tyUserTypeClass,
     tyUserTypeClassInst, tyCompositeTypeClass, tyAnd, tyOr, tyNot, tyAnything,
     tyGenericParam, tyGenericBody, tyNil, tyExpr, tyStmt,
     tyTypeDesc, tyGenericInvocation, tyForward:
    #internalError(c.graph.config, c.info, "assignment requested for type: " & typeToString(t))
    discard
  of tyOrdinal, tyRange, tyInferred,
     tyGenericInst, tyStatic, tyVar, tyLent, tyAlias, tySink:
    liftBodyAux(c, lastSon(t), body, x, y)

proc newProcType(info: TLineInfo; owner: PSym): PType =
  result = newType(tyProc, owner)
  result.n = newNodeI(nkFormalParams, info)
  rawAddSon(result, nil) # return type
  # result.n[0] used to be `nkType`, but now it's `nkEffectList` because
  # the effects are now stored in there too ... this is a bit hacky, but as
  # usual we desperately try to save memory:
  addSon(result.n, newNodeI(nkEffectList, info))

proc addParam(procType: PType; param: PSym) =
  param.position = procType.len-1
  addSon(procType.n, newSymNode(param))
  rawAddSon(procType, param.typ)

proc liftBodyDistinctType(c: PContext; typ: PType; kind: TTypeAttachedOp; info: TLineInfo): PSym =
  assert typ.kind == tyDistinct
  let baseType = typ[0]
  case kind
  of attachedAsgn:
    if baseType.assignment == nil:
      discard liftBody(c, baseType, kind, info)
    typ.assignment = baseType.assignment
    result = typ.assignment
  of attachedSink:
    if baseType.sink == nil:
      discard liftBody(c, baseType, kind, info)
    typ.sink = baseType.sink
    result = typ.sink
  of attachedDeepCopy:
    if baseType.deepCopy == nil:
      discard liftBody(c, baseType, kind, info)
    typ.deepCopy = baseType.deepCopy
    result = typ.deepCopy
  of attachedDestructor:
    if baseType.destructor == nil:
      discard liftBody(c, baseType, kind, info)
    typ.destructor = baseType.destructor
    result = typ.destructor

proc liftBody(c: PContext; typ: PType; kind: TTypeAttachedOp;
              info: TLineInfo): PSym =
  if typ.kind == tyDistinct:
    return liftBodyDistinctType(c, typ, kind, info)
  when false:
    var typ = typ
    if c.config.selectedGC == gcDestructors and typ.kind == tySequence:
      # use the canonical type to access the =sink and =destroy etc.
      typ = c.graph.sysTypes[tySequence]

  var a: TLiftCtx
  a.info = info
  a.graph = c.graph
  a.kind = kind
  a.c = c
  let g = c.graph
  let body = newNodeI(nkStmtList, info)
  let procname = case kind
                 of attachedAsgn: getIdent(g.cache, "=")
                 of attachedSink: getIdent(g.cache, "=sink")
                 of attachedDeepCopy: getIdent(g.cache, "=deepcopy")
                 of attachedDestructor: getIdent(g.cache, "=destroy")

  result = newSym(skProc, procname, typ.owner, info)
  a.fn = result
  a.asgnForType = typ

  let dest = newSym(skParam, getIdent(g.cache, "dest"), result, info)
  let src = newSym(skParam, getIdent(g.cache, "src"), result, info)
  dest.typ = makeVarType(typ.owner, typ)
  src.typ = typ

  result.typ = newProcType(info, typ.owner)
  result.typ.addParam dest
  if kind != attachedDestructor:
    result.typ.addParam src

  # register this operation already:
  case kind
  of attachedAsgn: typ.assignment = result
  of attachedSink: typ.sink = result
  of attachedDeepCopy: typ.deepCopy = result
  of attachedDestructor: typ.destructor = result

  liftBodyAux(a, typ, body, newSymNode(dest).newDeref, newSymNode(src))

  var n = newNodeI(nkProcDef, info, bodyPos+1)
  for i in 0 ..< n.len: n.sons[i] = newNodeI(nkEmpty, info)
  n.sons[namePos] = newSymNode(result)
  n.sons[paramsPos] = result.typ.n
  n.sons[bodyPos] = body
  result.ast = n
  incl result.flags, sfFromGeneric
  incl result.flags, sfGeneratedOp

proc getAsgnOrLiftBody(c: PContext; typ: PType; info: TLineInfo): PSym =
  let t = typ.skipTypes({tyGenericInst, tyVar, tyLent, tyAlias, tySink})
  result = t.assignment
  if result.isNil:
    result = liftBody(c, t, attachedAsgn, info)

proc overloadedAsgn(c: PContext; dest, src: PNode): PNode =
  let a = getAsgnOrLiftBody(c, dest.typ, dest.info)
  result = newAsgnCall(c.graph, a, dest, src)

template liftTypeBoundOps*(c: PContext; typ: PType; info: TLineInfo) =
  discard "now a nop"

proc patchBody(c: PContext; n: PNode; info: TLineInfo) =
  if n.kind in nkCallKinds:
    if n[0].kind == nkSym and n[0].sym.magic == mDestroy:
      let t = n[1].typ.skipTypes(abstractVar)
      if t.destructor == nil:
        liftBody(c, t, attachedDestructor, info)

      if t.destructor != nil:
        if t.destructor.ast[genericParamsPos].kind != nkEmpty:
          internalError(c.graph.config, info, "resolved destructor is generic")
        if t.destructor.magic == mDestroy:
          internalError(c.graph.config, info, "patching mDestroy with mDestroy?")
        n.sons[0] = newSymNode(t.destructor)
  for x in n: patchBody(c, x, info)

template inst(field, t) =
  if field.ast != nil and field.ast[genericParamsPos].kind != nkEmpty:
    assert t.typeInst != nil
    field = c.instTypeBoundOp(c, field, t.typeInst, info, attachedAsgn, 1)
    if field.ast != nil:
      patchBody(c, field.ast, info)

proc createTypeBoundOps*(c: PContext; orig: PType; info: TLineInfo) =
  ## In the semantic pass this is called in strategic places
  ## to ensure we lift assignment, destructors and moves properly.
  ## The later 'injectdestructors' pass depends on it.
  if orig == nil or {tfCheckedForDestructor, tfHasMeta} * orig.flags != {}: return
  incl orig.flags, tfCheckedForDestructor

  let h = sighashes.hashType(orig, {CoType, CoConsiderOwned})
  var canon = c.graph.canonTypes.getOrDefault(h)
  var overwrite = false
  if canon == nil:
    c.graph.canonTypes[h] = orig
    canon = orig
  elif canon != orig:
    overwrite = true

  # multiple cases are to distinguish here:
  # 1. we don't know yet if 'typ' has a nontrival destructor.
  # 2. we have a nop destructor. --> mDestroy
  # 3. we have a lifted destructor.
  # 4. We have a custom destructor.
  # 5. We have a (custom) generic destructor.
  let typ = canon.skipTypes({tyGenericInst, tyAlias})
  # we generate the destructor first so that other operators can depend on it:
  if typ.destructor == nil:
    liftBody(c, typ, attachedDestructor, info)
  else:
    inst(typ.destructor, typ)
  if typ.assignment == nil:
    liftBody(c, typ, attachedAsgn, info)
  else:
    inst(typ.assignment, typ)
  if typ.sink == nil:
    liftBody(c, typ, attachedSink, info)
  else:
    inst(typ.sink, typ)

  if overwrite:
    orig.destructor = canon.destructor
    orig.assignment = canon.assignment
    orig.sink = canon.sink
