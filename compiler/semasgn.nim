#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements lifting for assignments. Later versions of this code
## will be able to also lift ``=deepCopy`` and ``=destroy``.

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
proc liftBody(c: PContext; typ: PType; info: TLineInfo): PSym

proc at(a, i: PNode, elemType: PType): PNode =
  result = newNodeI(nkBracketExpr, a.info, 2)
  result.sons[0] = a
  result.sons[1] = i
  result.typ = elemType

proc liftBodyTup(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  for i in 0 .. <t.len:
    let lit = lowerings.newIntLit(i)
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
    for i in 1 .. <n.len:
      var branch = copyTree(n[i])
      let L = branch.len
      branch.sons[L-1] = newNodeI(nkStmtList, c.info)

      liftBodyObj(c, n[i].lastSon, branch.sons[L-1], x, y)
      caseStmt.add(branch)
    body.add(caseStmt)
    localError(c.info, "cannot lift assignment operator to 'case' object")
  of nkRecList:
    for t in items(n): liftBodyObj(c, t, body, x, y)
  else:
    illFormedAstLocal(n)

proc genAddr(c: PContext; x: PNode): PNode =
  if x.kind == nkHiddenDeref:
    checkSonsLen(x, 1)
    result = x.sons[0]
  else:
    result = newNodeIT(nkHiddenAddr, x.info, makeVarType(c, x.typ))
    addSon(result, x)

proc newAsgnCall(c: PContext; op: PSym; x, y: PNode): PNode =
  if sfError in op.flags:
    localError(x.info, errWrongSymbolX, op.name.s)
  result = newNodeI(nkCall, x.info)
  result.add newSymNode(op)
  result.add genAddr(c, x)
  result.add y

proc newAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc newDestructorCall(op: PSym; x: PNode): PNode =
  result = newNodeIT(nkCall, x.info, op.typ.sons[0])
  result.add(newSymNode(op))
  result.add x

proc newDeepCopyCall(op: PSym; x, y: PNode): PNode =
  result = newAsgnStmt(x, newDestructorCall(op, y))

proc considerOverloadedOp(c: var TLiftCtx; t: PType; body, x, y: PNode): bool =
  case c.kind
  of attachedDestructor:
    let op = t.destructor
    if op != nil:
      markUsed(c.info, op)
      styleCheckUse(c.info, op)
      body.add newDestructorCall(op, x)
      result = true
  of attachedAsgn:
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
        op = t.assignment
        if op == nil:
          op = liftBody(c.c, t, c.info)
      markUsed(c.info, op)
      styleCheckUse(c.info, op)
      body.add newAsgnCall(c.c, op, x, y)
      result = true
  of attachedDeepCopy:
    let op = t.deepCopy
    if op != nil:
      markUsed(c.info, op)
      styleCheckUse(c.info, op)
      body.add newDeepCopyCall(op, x, y)
      result = true

proc defaultOp(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  if c.kind != attachedDestructor:
    body.add newAsgnStmt(x, y)

proc addVar(father, v, value: PNode) =
  var vpart = newNodeI(nkIdentDefs, v.info, 3)
  vpart.sons[0] = v
  vpart.sons[1] = ast.emptyNode
  vpart.sons[2] = value
  addSon(father, vpart)

proc declareCounter(c: var TLiftCtx; body: PNode; first: BiggestInt): PNode =
  var temp = newSym(skTemp, getIdent(lowerings.genPrefix), c.fn, c.info)
  temp.typ = getSysType(tyInt)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, c.info)
  result = newSymNode(temp)
  v.addVar(result, lowerings.newIntLit(first))
  body.add v

proc genBuiltin(magic: TMagic; name: string; i: PNode): PNode =
  result = newNodeI(nkCall, i.info)
  result.add createMagic(name, magic).newSymNode
  result.add i

proc genWhileLoop(c: var TLiftCtx; i, dest: PNode): PNode =
  result = newNodeI(nkWhileStmt, c.info, 2)
  let cmp = genBuiltin(mLeI, "<=", i)
  cmp.add genHigh(dest)
  cmp.typ = getSysType(tyBool)
  result.sons[0] = cmp
  result.sons[1] = newNodeI(nkStmtList, c.info)

proc addIncStmt(body, i: PNode) =
  let incCall = genBuiltin(mInc, "inc", i)
  incCall.add lowerings.newIntLit(1)
  body.add incCall

proc newSeqCall(c: PContext; x, y: PNode): PNode =
  # don't call genAddr(c, x) here:
  result = genBuiltin(mNewSeq, "newSeq", x)
  let lenCall = genBuiltin(mLengthSeq, "len", y)
  lenCall.typ = getSysType(tyInt)
  result.add lenCall

proc liftBodyAux(c: var TLiftCtx; t: PType; body, x, y: PNode) =
  case t.kind
  of tyNone, tyEmpty, tyVoid: discard
  of tyPointer, tySet, tyBool, tyChar, tyEnum, tyInt..tyUInt64, tyCString,
      tyPtr, tyString, tyRef:
    defaultOp(c, t, body, x, y)
  of tyArray, tySequence:
    if tfHasAsgn in t.flags:
      if t.kind == tySequence:
        # XXX add 'nil' handling here
        body.add newSeqCall(c.c, x, y)
      let i = declareCounter(c, body, firstOrd(t))
      let whileLoop = genWhileLoop(c, i, x)
      let elemType = t.lastSon
      liftBodyAux(c, elemType, whileLoop.sons[1], x.at(i, elemType),
                                                  y.at(i, elemType))
      addIncStmt(whileLoop.sons[1], i)
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
      call.sons[0] = newSymNode(createMagic("deepCopy", mDeepCopy))
      call.sons[1] = y
      body.add newAsgnStmt(x, call)
  of tyVarargs, tyOpenArray:
    localError(c.info, errGenerated, "cannot copy openArray")
  of tyFromExpr, tyProxy, tyBuiltInTypeClass, tyUserTypeClass,
     tyUserTypeClassInst, tyCompositeTypeClass, tyAnd, tyOr, tyNot, tyAnything,
     tyGenericParam, tyGenericBody, tyNil, tyExpr, tyStmt,
     tyTypeDesc, tyGenericInvocation, tyForward:
    internalError(c.info, "assignment requested for type: " & typeToString(t))
  of tyOrdinal, tyRange,
     tyGenericInst, tyFieldAccessor, tyStatic, tyVar, tyAlias:
    liftBodyAux(c, lastSon(t), body, x, y)
  of tyUnused, tyUnused0, tyUnused1, tyUnused2: internalError("liftBodyAux")

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

proc liftBody(c: PContext; typ: PType; info: TLineInfo): PSym =
  var a: TLiftCtx
  a.info = info
  let body = newNodeI(nkStmtList, info)
  result = newSym(skProc, getIdent":lifted=", typ.owner, info)
  a.fn = result
  a.asgnForType = typ

  let dest = newSym(skParam, getIdent"dest", result, info)
  let src = newSym(skParam, getIdent"src", result, info)
  dest.typ = makeVarType(c, typ)
  src.typ = typ

  result.typ = newProcType(info, typ.owner)
  result.typ.addParam dest
  result.typ.addParam src

  liftBodyAux(a, typ, body, newSymNode(dest).newDeref, newSymNode(src))

  var n = newNodeI(nkProcDef, info, bodyPos+1)
  for i in 0 .. < n.len: n.sons[i] = emptyNode
  n.sons[namePos] = newSymNode(result)
  n.sons[paramsPos] = result.typ.n
  n.sons[bodyPos] = body
  result.ast = n

  # register late as recursion is handled differently
  typ.assignment = result
  #echo "Produced this ", n

proc getAsgnOrLiftBody(c: PContext; typ: PType; info: TLineInfo): PSym =
  let t = typ.skipTypes({tyGenericInst, tyVar, tyAlias})
  result = t.assignment
  if result.isNil:
    result = liftBody(c, t, info)

proc overloadedAsgn(c: PContext; dest, src: PNode): PNode =
  let a = getAsgnOrLiftBody(c, dest.typ, dest.info)
  result = newAsgnCall(c, a, dest, src)
