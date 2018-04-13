#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module does the semantic transformation of the fields* iterators.
#  included from semstmts.nim

type
  TFieldInstCtx = object  # either 'tup[i]' or 'field' is valid
    tupleType: PType      # if != nil we're traversing a tuple
    tupleIndex: int
    field: PSym
    m: TMagic

proc instFieldLoopBody(c: TFieldInstCtx, n: PNode, forLoop: PNode): PNode =
  let replaceByFieldName = c.m == mFieldPairs
  case n.kind
  of nkEmpty..pred(nkIdent), succ(nkSym)..nkNilLit: result = n
  of nkIdent, nkSym:
    result = n
    let ident = considerQuotedIdent(n)
    var L = sonsLen(forLoop)

    #TODO: different order for mFieldsIndexed
    #TODO: allow passing in just type for mFieldsIndexed
    if c.m == mFieldPairs or c.m == mFieldsIndexed:
      let indexField =
        if c.m == mFieldPairs: 0
        else: 1

      if ident.id == considerQuotedIdent(forLoop[indexField]).id:
        let fieldName = if c.tupleType.isNil: c.field.name.s
                        elif c.tupleType.n.isNil: "Field" & $c.tupleIndex
                        else: c.tupleType.n.sons[c.tupleIndex].sym.name.s
        result = newStrNode(nkStrLit, fieldName)
        return

    if c.m == mFieldsIndexed:
      if ident.id == considerQuotedIdent(forLoop[0]).id:
        var call = forLoop.sons[L-2]
        var tupl = call.sons[1]
        result = newIntNode(nkIntLit, c.tupleIndex)

    else:
     # value fields:
     for i in ord(replaceByFieldName)..L-3:
      if ident.id == considerQuotedIdent(forLoop[i]).id:
        var call = forLoop.sons[L-2]
        var tupl = call.sons[i+1-ord(replaceByFieldName)]
        if c.field.isNil:
          result = newNodeI(nkBracketExpr, n.info)
          result.add(tupl)
          result.add(newIntNode(nkIntLit, c.tupleIndex))
        else:
          result = newNodeI(nkDotExpr, n.info)
          result.add(tupl)
          result.add(newSymNode(c.field, n.info))
        # TODO: does it check for repeated names, eg: for k,v,v in ...
        break
  else:
    if n.kind == nkContinueStmt:
      localError(n.info, errGenerated,
                 "'continue' not supported in a 'fields' loop")
    result = copyNode(n)
    newSons(result, sonsLen(n))
    for i in countup(0, sonsLen(n)-1):
      result.sons[i] = instFieldLoopBody(c, n.sons[i], forLoop)

type
  TFieldsCtx = object
    c: PContext
    m: TMagic

proc semForObjectFields(c: TFieldsCtx, typ, forLoop, father: PNode) =
  case typ.kind
  of nkSym:
    var fc: TFieldInstCtx  # either 'tup[i]' or 'field' is valid
    fc.field = typ.sym
    fc.m = c.m
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
    semForObjectFields(c, typ[0], forLoop, father)
    # we need to generate a case statement:
    var caseStmt = newNodeI(nkCaseStmt, forLoop.info)
    # generate selector:
    var access = newNodeI(nkDotExpr, forLoop.info, 2)
    access.sons[0] = call.sons[1]
    access.sons[1] = newSymNode(typ.sons[0].sym, forLoop.info)
    caseStmt.add(semExprWithType(c.c, access))
    # copy the branches over, but replace the fields with the for loop body:
    for i in 1 ..< typ.len:
      var branch = copyTree(typ[i])
      let L = branch.len
      branch.sons[L-1] = newNodeI(nkStmtList, forLoop.info)
      semForObjectFields(c, typ[i].lastSon, forLoop, branch[L-1])
      caseStmt.add(branch)
    father.add(caseStmt)
  of nkRecList:
    for t in items(typ): semForObjectFields(c, t, forLoop, father)
  else:
    illFormedAstLocal(typ)

proc semForFields(c: PContext, n: PNode, m: TMagic): PNode =
  # so that 'break' etc. work as expected, we produce
  # a 'while true: stmt; break' loop ...
  result = newNodeI(nkWhileStmt, n.info, 2)
  var trueSymbol = strTableGet(magicsys.systemModule.tab, getIdent"true")
  if trueSymbol == nil:
    localError(n.info, errSystemNeeds, "true")
    trueSymbol = newSym(skUnknown, getIdent"true", getCurrOwner(c), n.info)
    trueSymbol.typ = getSysType(tyBool)

  result.sons[0] = newSymNode(trueSymbol, n.info)
  var stmts = newNodeI(nkStmtList, n.info)
  result.sons[1] = stmts

  var length = sonsLen(n)
  var call = n.sons[length-2]
  if m==mFieldsIndexed:
    if length-2 != 2:
      localError(n.info, errWrongNumberOfVariables)
      return result
  elif length-2 != sonsLen(call)-1 + ord(m==mFieldPairs):
    localError(n.info, errWrongNumberOfVariables)
    return result

  const skippedTypesForFields = abstractVar - {tyTypeDesc} + tyUserTypeClasses
  var tupleTypeA = skipTypes(call.sons[1].typ, skippedTypesForFields)
  if tupleTypeA.kind notin {tyTuple, tyObject}:
    localError(n.info, errGenerated, "no object or tuple type")
    return result
  for i in 1..call.len-1:
    var tupleTypeB = skipTypes(call.sons[i].typ, skippedTypesForFields)
    if not sameType(tupleTypeA, tupleTypeB):
      typeMismatch(call.sons[i].info, tupleTypeA, tupleTypeB)

  inc(c.p.nestedLoopCounter)
  if tupleTypeA.kind == tyTuple:
    var loopBody = n.sons[length-1]
    for i in 0..sonsLen(tupleTypeA)-1:
      openScope(c)
      var fc: TFieldInstCtx
      fc.tupleType = tupleTypeA
      fc.tupleIndex = i
      fc.m = m
      var body = instFieldLoopBody(fc, loopBody, n)
      inc c.inUnrolledContext
      stmts.add(semStmt(c, body))
      dec c.inUnrolledContext
      closeScope(c)
  else:
    var fc: TFieldsCtx
    fc.m = m
    fc.c = c
    var t = tupleTypeA
    while t.kind == tyObject:
      semForObjectFields(fc, t.n, n, stmts)
      if t.sons[0] == nil: break
      t = skipTypes(t.sons[0], skipPtrs)
  dec(c.p.nestedLoopCounter)
  # for TR macros this 'while true: ...; break' loop is pretty bad, so
  # we avoid it now if we can:
  if containsNode(stmts, {nkBreakStmt}):
    var b = newNodeI(nkBreakStmt, n.info)
    b.add(ast.emptyNode)
    stmts.add(b)
  else:
    result = stmts
