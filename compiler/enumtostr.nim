
import ast, idents, lineinfos, modulegraphs, magicsys

when defined(nimPreviewSlimSystem):
  import std/assertions


proc genEnumToStrProc*(t: PType; info: TLineInfo; g: ModuleGraph; idgen: IdGenerator): PSym =
  result = newSym(skProc, getIdent(g.cache, "$"), idgen, t.owner, info)

  let dest = newSym(skParam, getIdent(g.cache, "e"), idgen, result, info)
  dest.typ = t

  let res = newSym(skResult, getIdent(g.cache, "result"), idgen, result, info)
  res.typ = getSysType(g, info, tyString)

  result.typ = newType(tyProc, idgen, t.owner)
  result.typ.n = newNodeI(nkFormalParams, info)
  rawAddSon(result.typ, res.typ)
  result.typ.n.add newNodeI(nkEffectList, info)

  result.typ.addParam dest

  var body = newNodeI(nkStmtList, info)
  var caseStmt = newNodeI(nkCaseStmt, info)
  caseStmt.add(newSymNode dest)

  # copy the branches over, but replace the fields with the for loop body:
  for i in 0..<t.n.len:
    assert(t.n[i].kind == nkSym)
    var field = t.n[i].sym
    let val = if field.ast == nil: field.name.s else: field.ast.strVal
    caseStmt.add newTree(nkOfBranch, newIntTypeNode(field.position, t),
      newTree(nkStmtList, newTree(nkFastAsgn, newSymNode(res), newStrNode(val, info))))
    #newIntTypeNode(nkIntLit, field.position, t)
  # safety branch for invalid data:
  caseStmt.add newTree(nkElse,
    newTree(nkStmtList, newTree(nkFastAsgn, newSymNode(res),
      newStrNode("", info))))

  body.add(caseStmt)

  var n = newNodeI(nkProcDef, info, bodyPos+2)
  for i in 0..<n.len: n[i] = newNodeI(nkEmpty, info)
  n[namePos] = newSymNode(result)
  n[paramsPos] = result.typ.n
  n[bodyPos] = body
  n[resultPos] = newSymNode(res)
  result.ast = n
  incl result.flagsImpl, {sfFromGeneric, sfNeverRaises}
  setHookDisamb(g, result, "$enumtostr", t)
