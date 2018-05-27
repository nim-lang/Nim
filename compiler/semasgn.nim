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

# included from sem.nim

type
  TLiftCtx = object
    c: PContext
    info: TLineInfo # for construction
    kind: TTypeAttachedOp
    fn: PSym
    asgnForType: PType
    recurse: bool

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
    let lit = lowerings.newIntLit(c.c.graph, x.info, i)
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
    localError(c.c.config, c.info, "cannot lift assignment operator to 'case' object")
  of nkRecList:
    for t in items(n): liftBodyObj(c, t, body, x, y)
  else:
    illFormedAstLocal(n, c.c.config)

proc genAddr(c: PContext; x: PNode): PNode =
  if x.kind == nkHiddenDeref:
    checkSonsLen(x, 1, c.config)
    result = x.sons[0]
  else:
    result = newNodeIT(nkHiddenAddr, x.info, makeVarType(c, x.typ))
    addSon(result, x)

proc newAsgnCall(c: PContext; op: PSym; x, y: PNode): PNode =
  if sfError in op.flags:
    localError(c.config, x.info, "usage of '$1' is a user-defined error" % op.name.s)
  result = newNodeI(nkCall, x.info)
  result.add newSymNode(op)
  result.add genAddr(c, x)
  result.add y

proc newAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc newOpCall(op: PSym; x: PNode): PNode =
  result = newNodeIT(nkCall, x.info, op.typ.sons[0])
  result.add(newSymNode(op))
  result.add x

proc destructorCall(c: PContext; op: PSym; x: PNode): PNode =
  result = newNodeIT(nkCall, x.info, op.typ.sons[0])
  result.add(newSymNode(op))
  if destructor in c.features:
    result.add genAddr(c, x)
  else:
    result.add x

proc newDeepCopyCall(op: PSym; x, y: PNode): PNode =
  result = newAsgnStmt(x, newOpCall(op, y))

proc considerAsgnOrSink(c: var TLiftCtx; t: PType; body, x, y: PNode;
                        field: PSym): bool =
  if tfHasAsgn in t.flags:
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
    markUsed(c.c.config, c.info, op, c.c.graph.usageSym)
    styleCheckUse(c.info, op)
    body.add newAsgnCall(c.c, op, x, y)
    result = true

proc considerOverloadedOp(c: var TLiftCtx; t: PType; body, x, y: PNode): bool =
  case c.kind
  of attachedDestructor:
    let op = t.destructor
    if op != nil:
      markUsed(c.c.config, c.info, op, c.c.graph.usageSym)
      styleCheckUse(c.info, op)
      body.add destructorCall(c.c, op, x)
      result = true
  of attachedAsgn:
    result = considerAsgnOrSink(c, t, body, x, y, t.assignment)
  of attachedSink:
    result = considerAsgnOrSink(c, t, body, x, y, t.sink)
  of attachedDeepCopy:
    let op = t.deepCopy
    if op != nil:
      markUsed(c.c.config, c.info, op, c.c.graph.usageSym)
      styleCheckUse(c.info, op)
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
  var temp = newSym(skTemp, getIdent(c.c.cache, lowerings.genPrefix), c.fn, c.info)
  temp.typ = getSysType(c.c.graph, body.info, tyInt)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, c.info)
  result = newSymNode(temp)
  v.addVar(result, lowerings.newIntLit(c.c.graph, body.info, first))
  body.add v

proc genBuiltin(g: ModuleGraph; magic: TMagic; name: string; i: PNode): PNode =
  result = newNodeI(nkCall, i.info)
  result.add createMagic(g, name, magic).newSymNode
  result.add i

proc genWhileLoop(c: var TLiftCtx; i, dest: PNode): PNode =
  result = newNodeI(nkWhileStmt, c.info, 2)
  let cmp = genBuiltin(c.c.graph, mLeI, "<=", i)
  cmp.add genHigh(c.c.graph, dest)
  cmp.typ = getSysType(c.c.graph, c.info, tyBool)
  result.sons[0] = cmp
  result.sons[1] = newNodeI(nkStmtList, c.info)

proc addIncStmt(c: var TLiftCtx; body, i: PNode) =
  let incCall = genBuiltin(c.c.graph, mInc, "inc", i)
  incCall.add lowerings.newIntLit(c.c.graph, c.info, 1)
  body.add incCall

proc newSeqCall(c: PContext; x, y: PNode): PNode =
  # don't call genAddr(c, x) here:
  result = genBuiltin(c.graph, mNewSeq, "newSeq", x)
  let lenCall = genBuiltin(c.graph, mLengthSeq, "len", y)
  lenCall.typ = getSysType(c.graph, x.info, tyInt)
  result.add lenCall

proc liftBodyAux(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  case t.kind
  of tyNone, tyEmpty, tyVoid: discard
  of tyPointer, tySet, tyBool, tyChar, tyEnum, tyInt..tyUInt64, tyCString,
      tyPtr, tyString, tyRef, tyOpt:
    defaultOp(c, t, body, x, y)
  of tyArray, tySequence:
    if {tfHasAsgn, tfUncheckedArray} * t.flags == {tfHasAsgn}:
      if t.kind == tySequence:
        # XXX add 'nil' handling here
        body.add newSeqCall(c.c, x, y)
      let i = declareCounter(c, body, firstOrd(c.c.config, t))
      let whileLoop = genWhileLoop(c, i, x)
      let elemType = t.lastSon
      liftBodyAux(c, elemType, whileLoop.sons[1], x.at(i, elemType),
                                                  y.at(i, elemType))
      addIncStmt(c, whileLoop.sons[1], i)
      body.add whileLoop
    else:
      defaultOp(c, t, body, x, y)
  of tyObject, tyDistinct:
    if not considerOverloadedOp(c, t, body, x, y):
      if t.sons[0] != nil:
        liftBodyAux(c, t.sons[0].skipTypes(skipPtrs), body, x, y)
      if t.kind == tyObject: liftBodyObj(c, t.n, body, x, y)
  of tyTuple:
    liftBodyTup(c, t, body, x, y)
  of tyProc:
    if t.callConv != ccClosure or c.kind != attachedDeepCopy:
      defaultOp(c, t, body, x, y)
    else:
      # a big problem is that we don't know the enviroment's type here, so we
      # have to go through some indirection; we delegate this to the codegen:
      let call = newNodeI(nkCall, c.info, 2)
      call.typ = t
      call.sons[0] = newSymNode(createMagic(c.c.graph, "deepCopy", mDeepCopy))
      call.sons[1] = y
      body.add newAsgnStmt(x, call)
  of tyVarargs, tyOpenArray:
    localError(c.c.config, c.info, "cannot copy openArray")
  of tyFromExpr, tyProxy, tyBuiltInTypeClass, tyUserTypeClass,
     tyUserTypeClassInst, tyCompositeTypeClass, tyAnd, tyOr, tyNot, tyAnything,
     tyGenericParam, tyGenericBody, tyNil, tyExpr, tyStmt,
     tyTypeDesc, tyGenericInvocation, tyForward:
    internalError(c.c.config, c.info, "assignment requested for type: " & typeToString(t))
  of tyOrdinal, tyRange, tyInferred,
     tyGenericInst, tyStatic, tyVar, tyLent, tyAlias, tySink:
    liftBodyAux(c, lastSon(t), body, x, y)
  of tyUnused, tyOptAsRef: internalError(c.c.config, "liftBodyAux")

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

proc liftBody(c: PContext; typ: PType; kind: TTypeAttachedOp;
              info: TLineInfo): PSym =
  var a: TLiftCtx
  a.info = info
  a.c = c
  a.kind = kind
  let body = newNodeI(nkStmtList, info)
  let procname = case kind
                 of attachedAsgn: getIdent(c.cache, "=")
                 of attachedSink: getIdent(c.cache, "=sink")
                 of attachedDeepCopy: getIdent(c.cache, "=deepcopy")
                 of attachedDestructor: getIdent(c.cache, "=destroy")

  result = newSym(skProc, procname, typ.owner, info)
  a.fn = result
  a.asgnForType = typ

  let dest = newSym(skParam, getIdent(c.cache, "dest"), result, info)
  let src = newSym(skParam, getIdent(c.cache, "src"), result, info)
  dest.typ = makeVarType(c, typ)
  src.typ = typ

  result.typ = newProcType(info, typ.owner)
  result.typ.addParam dest
  if kind != attachedDestructor:
    result.typ.addParam src

  liftBodyAux(a, typ, body, newSymNode(dest).newDeref, newSymNode(src))
  # recursion is handled explicitly, do not register the type based operation
  # before 'liftBodyAux':
  case kind
  of attachedAsgn: typ.assignment = result
  of attachedSink: typ.sink = result
  of attachedDeepCopy: typ.deepCopy = result
  of attachedDestructor: typ.destructor = result

  var n = newNodeI(nkProcDef, info, bodyPos+1)
  for i in 0 ..< n.len: n.sons[i] = newNodeI(nkEmpty, info)
  n.sons[namePos] = newSymNode(result)
  n.sons[paramsPos] = result.typ.n
  n.sons[bodyPos] = body
  result.ast = n
  incl result.flags, sfFromGeneric


proc getAsgnOrLiftBody(c: PContext; typ: PType; info: TLineInfo): PSym =
  let t = typ.skipTypes({tyGenericInst, tyVar, tyLent, tyAlias, tySink})
  result = t.assignment
  if result.isNil:
    result = liftBody(c, t, attachedAsgn, info)

proc overloadedAsgn(c: PContext; dest, src: PNode): PNode =
  let a = getAsgnOrLiftBody(c, dest.typ, dest.info)
  result = newAsgnCall(c, a, dest, src)

proc liftTypeBoundOps*(c: PContext; typ: PType; info: TLineInfo) =
  ## In the semantic pass this is called in strategic places
  ## to ensure we lift assignment, destructors and moves properly.
  ## The later 'destroyer' pass depends on it.
  if destructor notin c.features or not hasDestructor(typ): return
  when false:
    # do not produce wrong liftings while we're still instantiating generics:
    # now disabled; breaks topttree.nim!
    if c.typesWithOps.len > 0: return
  let typ = typ.skipTypes({tyGenericInst, tyAlias})
  # we generate the destructor first so that other operators can depend on it:
  if typ.destructor == nil:
    liftBody(c, typ, attachedDestructor, info)
  if typ.assignment == nil:
    liftBody(c, typ, attachedAsgn, info)
  if typ.sink == nil:
    liftBody(c, typ, attachedSink, info)

#proc patchResolvedTypeBoundOp*(c: PContext; n: PNode): PNode =
#  if n.kind == nkCall and
