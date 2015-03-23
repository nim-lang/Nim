#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements lifting for assignments and ``deepCopy``.

# included from sem.nim

type
  TTypeAttachedOp = enum
    attachedDestructor,
    attachedAsgn,
    attachedDeepCopy

  TLiftCtx = object
    c: PContext
    info: TLineInfo # for construction
    result: PNode
    kind: TTypeAttachedOp

type
  TFieldInstCtx = object  # either 'tup[i]' or 'field' is valid
    tupleType: PType      # if != nil we're traversing a tuple
    tupleIndex: int
    field: PSym
    replaceByFieldName: bool

proc instFieldLoopBody(c: TFieldInstCtx, n: PNode, forLoop: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkIdent), succ(nkIdent)..nkNilLit: result = n
  of nkIdent:
    result = n
    var L = sonsLen(forLoop)
    if c.replaceByFieldName:
      if n.ident.id == forLoop[0].ident.id:
        let fieldName = if c.tupleType.isNil: c.field.name.s
                        elif c.tupleType.n.isNil: "Field" & $c.tupleIndex
                        else: c.tupleType.n.sons[c.tupleIndex].sym.name.s
        result = newStrNode(nkStrLit, fieldName)
        return
    # other fields:
    for i in ord(c.replaceByFieldName)..L-3:
      if n.ident.id == forLoop[i].ident.id:
        var call = forLoop.sons[L-2]
        var tupl = call.sons[i+1-ord(c.replaceByFieldName)]
        if c.field.isNil:
          result = newNodeI(nkBracketExpr, n.info)
          result.add(tupl)
          result.add(newIntNode(nkIntLit, c.tupleIndex))
        else:
          result = newNodeI(nkDotExpr, n.info)
          result.add(tupl)
          result.add(newSymNode(c.field, n.info))
        break
  else:
    if n.kind == nkContinueStmt:
      localError(n.info, errGenerated,
                 "'continue' not supported in a 'fields' loop")
    result = copyNode(n)
    newSons(result, sonsLen(n))
    for i in countup(0, sonsLen(n)-1):
      result.sons[i] = instFieldLoopBody(c, n.sons[i], forLoop)

proc liftBodyObj(c: TLiftCtx; typ, x, y: PNode) =
  case typ.kind
  of nkSym:
    var fc: TFieldInstCtx  # either 'tup[i]' or 'field' is valid
    fc.field = typ.sym
    fc.replaceByFieldName = c.m == mFieldPairs
    openScope(c.c)
    inc c.c.inUnrolledContext
    let body = instFieldLoopBody(fc, lastSon(forLoop), forLoop)
    father.add(semStmt(c.c, body))
    dec c.c.inUnrolledContext
    closeScope(c.c)
  of nkNilLit: discard
  of nkRecCase:
    let L = forLoop.len
    let call = forLoop.sons[L-2]
    if call.len > 2:
      localError(forLoop.info, errGenerated,
                 "parallel 'fields' iterator does not work for 'case' objects")
      return
    # iterate over the selector:
    asgnForObjectFields(c, typ[0], forLoop, father)
    # we need to generate a case statement:
    var caseStmt = newNodeI(nkCaseStmt, c.info)
    # generate selector:
    var access = newNodeI(nkDotExpr, forLoop.info, 2)
    access.sons[0] = call.sons[1]
    access.sons[1] = newSymNode(typ.sons[0].sym, forLoop.info)
    caseStmt.add(semExprWithType(c.c, access))
    # copy the branches over, but replace the fields with the for loop body:
    for i in 1 .. <typ.len:
      var branch = copyTree(typ[i])
      let L = branch.len
      branch.sons[L-1] = newNodeI(nkStmtList, forLoop.info)
      semForObjectFields(c, typ[i].lastSon, forLoop, branch[L-1])
      caseStmt.add(branch)
    father.add(caseStmt)
  of nkRecList:
    for t in items(typ): liftBodyObj(c, t, x, y)
  else:
    illFormedAstLocal(typ)

proc newAsgnCall(op: PSym; x, y: PNode): PNode =
  result = newNodeI(nkCall, x.info)
  result.add(newSymNode(op))
  result.add x
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

proc considerOverloadedOp(c: TLiftCtx; t: PType; x, y: PNode): bool =
  let op = t.attachedOps[c.kind]
  if op != nil:
    markUsed(c.info, op)
    styleCheckUse(c.info, op)
    case c.kind
    of attachedDestructor:
      c.result.add newDestructorCall(op, x)
    of attachedAsgn:
      c.result.add newAsgnCall(op, x, y)
    of attachedDeepCopy:
      c.result.add newDeepCopyCall(op, x, y)
    result = true

proc defaultOp(c: TLiftCtx; t: PType; x, y: PNode) =
  if c.kind != attachedDestructor:
    c.result.add newAsgnStmt(x, y)

proc liftBodyAux(c: TLiftCtx; t: PType; x, y: PNode) =
  const hasAttachedOp: array[TTypeAttachedOp, TTypeIter] = [
    (proc (t: PType, closure: PObject): bool =
       t.attachedOp[attachedDestructor] != nil),
    (proc (t: PType, closure: PObject): bool =
       t.attachedOp[attachedAsgn] != nil),
    (proc (t: PType, closure: PObject): bool =
       t.attachedOp[attachedDeepCopy] != nil)]
  case t.kind
  of tyNone, tyEmpty: discard
  of tyPointer, tySet, tyBool, tyChar, tyEnum, tyInt..tyUInt64, tyCString:
    defaultOp(c, t, x, y)
  of tyPtr, tyString:
    if not considerOverloadedOp(c, t, x, y):
      defaultOp(c, t, x, y)
  of tyArrayConstr, tyArray, tySequence:
    if iterOverType(lastSon(t), hasAttachedOp[c.kind], nil):
      # generate loop and call the attached Op:

    else:
      defaultOp(c, t, x, y)
  of tyObject:
    liftBodyObj(c, t.n, x, y)
  of tyTuple:
    liftBodyTup(c, t, x, y)
  of tyRef:
    # we MUST NOT check for acyclic here as a DAG might still share nodes:

  of tyProc:
    if t.callConv != ccClosure or c.kind != attachedDeepCopy:
      defaultOp(c, t, x, y)
    else:
      # a big problem is that we don't know the enviroment's type here, so we
      # have to go through some indirection; we delegate this to the codegen:
      call = newNodeI(nkCall, n.info, 2)
      call.typ = t
      call.sons[0] = newSymNode(createMagic("deepCopy", mDeepCopy))
      call.sons[1] = y
      c.result.add newAsgnStmt(x, call)
  of tyVarargs, tyOpenArray:
    localError(c.info, errGenerated, "cannot copy openArray")
  of tyFromExpr, tyIter, tyProxy, tyBuiltInTypeClass, tyUserTypeClass,
     tyUserTypeClassInst, tyCompositeTypeClass, tyAnd, tyOr, tyNot, tyAnything,
     tyMutable, tyGenericParam, tyGenericBody, tyNil, tyExpr, tyStmt,
     tyTypeDesc, tyGenericInvocation, tyBigNum, tyConst, tyForward:
    internalError(c.info, "assignment requested for type: " & typeToString(t))
  of tyDistinct, tyOrdinal, tyRange,
     tyGenericInst, tyFieldAccessor, tyStatic, tyVar:
    liftBodyAux(c, lastSon(t))

proc liftBody(c: PContext; typ: PType; info: TLineInfo): PNode =
  var a: TLiftCtx
  a.info = info
  a.result = newNodeI(nkStmtList, info)
  liftBodyAux(a, typ)
  result = a.result
