discard """
  joinable: false
"""

import compiler/[ast, idents, injectdestructors, modulegraphs, msgs,
                 options, pathutils]

# bug #26218: after `result = if ... else ...` has its assignment distributed
# into the branches, the (former) `nkIfExpr` node kept a nil `typ` while still
# being an expression node. Consumers of the compiler AST (external backends,
# AST analyzers) expect an expression node to always carry a type.

proc main =
  let conf = newConfigRef()
  conf.cmd = cmdM
  conf.backend = backendC
  conf.options.excl optCursorInference
  conf.projectFull = AbsoluteFile("t26218_sample.nim")
  let cache = newIdentCache()
  let graph = newModuleGraph(cache, conf)
  let file = fileInfoIdx(conf, conf.projectFull)
  let info = newLineInfo(file, 1, 1)
  let module = PSym(kind: skModule, name: getIdent(cache, "t26218_sample"),
    itemId: ItemId(module: file.int32, item: 0), position: file.int, info: info)
  let idgen = idGeneratorFromModule(module)

  let intType = newType(tyInt, idgen, module)
  let boolType = newType(tyBool, idgen, module)

  # owner: a proc returning int, no parameters
  let owner = newSym(skProc, getIdent(cache, "fff"), idgen, module, info)
  let procTyp = newType(tyProc, idgen, module)
  procTyp.add(intType)
  procTyp.n = newNodeI(nkFormalParams, info)
  procTyp.n.add newNodeI(nkType, info)
  owner.typ = procTyp

  let resultSym = newSym(skResult, getIdent(cache, "result"), idgen, owner, info)
  resultSym.typ = intType

  let condSym = newSym(skParam, getIdent(cache, "v"), idgen, owner, info)
  condSym.typ = boolType

  let ifNode = newNodeIT(nkIfExpr, info, intType)
  let branch = newNodeI(nkElifBranch, info)
  branch.add newSymNode(condSym)
  let lit42 = newIntNode(nkIntLit, 42)
  lit42.typ = intType
  branch.add lit42
  ifNode.add branch
  let elseBranch = newNodeI(nkElse, info)
  let lit43 = newIntNode(nkIntLit, 43)
  lit43.typ = intType
  elseBranch.add lit43
  ifNode.add elseBranch

  let asgn = newNodeI(nkAsgn, info)
  asgn.add newSymNode(resultSym)
  asgn.add ifNode

  let body = newNodeI(nkStmtList, info)
  body.add asgn

  let lowered = injectDestructorCalls(graph, idgen, owner, body)
  doAssert lowered.kind == nkStmtList

  # the if must still be there, with the assignment distributed into the
  # branches, and the node must now be a statement node (nkIfStmt), because
  # the branches produce the value themselves:
  var found = false
  proc walk(n: PNode) =
    if n.kind in {nkIfStmt, nkIfExpr}:
      found = true
      doAssert n.kind == nkIfStmt
      for i in 0..<n.len:
        let leaf = n[i].lastSon
        doAssert leaf.kind == nkStmtList and leaf.lastSon.kind == nkAsgn
    for i in 0..<n.safeLen:
      walk(n[i])
  walk(lowered)
  doAssert found, "if node lost by lowering"

  # no expression-kind if node without a type may remain:
  proc check(n: PNode) =
    doAssert not (n.kind == nkIfExpr and n.typ == nil)
    for i in 0..<n.safeLen:
      check(n[i])
  check(lowered)

main()
echo "ok"
