
import ast, idents, lineinfos, modulegraphs, magicsys

proc genEnumToStrProc*(t: PType; info: TLineInfo; g: ModuleGraph): PSym =
  result = newSym(skProc, getIdent(g.cache, "$"), t.owner, info)

  let dest = newSym(skParam, getIdent(g.cache, "e"), result, info)
  dest.typ = t

  let res = newSym(skResult, getIdent(g.cache, "result"), result, info)
  res.typ = getSysType(g, info, tyString)

  result.typ = newType(tyProc, t.owner)
  result.typ.n = newNodeI(nkFormalParams, info)
  rawAddSon(result.typ, res.typ)
  addSon(result.typ.n, newNodeI(nkEffectList, info))

  result.typ.addParam dest

  var body = newNodeI(nkStmtList, info)
  var caseStmt = newNodeI(nkCaseStmt, info)
  caseStmt.add(newSymNode dest)

  # copy the branches over, but replace the fields with the for loop body:
  for i in 0 ..< t.n.len:
    assert(t.n[i].kind == nkSym)
    var field = t.n[i].sym
    let val = if field.ast == nil: field.name.s else: field.ast.strVal
    caseStmt.add newTree(nkOfBranch, newSymNode(field),
      newTree(nkStmtList, newTree(nkFastAsgn, newSymNode(res), newStrNode(val, info))))
    #newIntTypeNode(nkIntLit, field.position, t)

  body.add(caseStmt)

  var n = newNodeI(nkProcDef, info, bodyPos+2)
  for i in 0 ..< n.len: n.sons[i] = newNodeI(nkEmpty, info)
  n.sons[namePos] = newSymNode(result)
  n.sons[paramsPos] = result.typ.n
  n.sons[bodyPos] = body
  n.sons[resultPos] = newSymNode(res)
  result.ast = n
  incl result.flags, sfFromGeneric

proc searchObjCase(obj: PNode; field: PSym): PNode =
  case obj.kind
  of nkSym:
    result = nil
  of nkElse, nkOfBranch:
    result = searchObjCase(obj.lastSon, field)
  else:
    if obj.kind == nkRecCase and obj[0].kind == nkSym and obj[0].sym == field:
      result = obj
    else:
      for x in obj:
        result = searchObjCase(x, field)
        if result != nil: break

proc genCaseObjDiscMapping*(t: PType; field: PSym; info: TLineInfo; g: ModuleGraph): PSym =
  result = newSym(skProc, getIdent(g.cache, "objDiscMapping"), t.owner, info)

  let dest = newSym(skParam, getIdent(g.cache, "e"), result, info)
  dest.typ = field.typ

  let res = newSym(skResult, getIdent(g.cache, "result"), result, info)
  res.typ = getSysType(g, info, tyUInt8)

  result.typ = newType(tyProc, t.owner)
  result.typ.n = newNodeI(nkFormalParams, info)
  rawAddSon(result.typ, res.typ)
  addSon(result.typ.n, newNodeI(nkEffectList, info))

  result.typ.addParam dest

  var body = newNodeI(nkStmtList, info)
  var caseStmt = newNodeI(nkCaseStmt, info)
  caseStmt.add(newSymNode dest)

  let subObj = searchObjCase(t.n, field)
  doAssert subObj != nil
  for i in 1 ..< subObj.len:
    let ofBranch = subObj[i]
    var newBranch = newNodeI(ofBranch.kind, ofBranch.info)
    for j in 0..ofBranch.len-2:
      newBranch.add ofBranch[j]

    newBranch.add newTree(nkStmtList, newTree(nkFastAsgn, newSymNode(res), newIntNode(nkInt8Lit, i)))
    caseStmt.add newBranch

  body.add(caseStmt)

  var n = newNodeI(nkProcDef, info, bodyPos+2)
  for i in 0 ..< n.len: n.sons[i] = newNodeI(nkEmpty, info)
  n.sons[namePos] = newSymNode(result)
  n.sons[paramsPos] = result.typ.n
  n.sons[bodyPos] = body
  n.sons[resultPos] = newSymNode(res)
  result.ast = n
  incl result.flags, sfFromGeneric
