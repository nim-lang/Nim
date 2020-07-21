#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Partition variables into different graphs. Used for
## Nim's write tracking. The used algorithm is "union find"
## with path compression.

import ast, types
from trees import getMagic

type
  SubgraphFlag = enum
    isMutated, # graph might be mutated
    connectsConstParam, # graph is connected to a non-var parameter.

  VarIndexKind = enum
    isEmptyRoot,
    dependsOn,
    isRootOf

  VarIndex = object
    case kind: VarIndexKind
    of isEmptyRoot: discard
    of dependsOn: parent: int
    of isRootOf: graphIndex: int

  Partitions = object
    symToId: seq[PSym]
    s: seq[VarIndex]
    graphs: seq[set[SubgraphFlag]]

proc hasSideEffect(p: Partitions): bool =
  for g in p.graphs:
    if g == {isMutated, connectsConstParam}: return true
  return false

proc registerVariable(p: var Partitions; n: PNode) =
  if n.kind == nkSym:
    p.symToId.add n.sym
    p.s.add VarIndex(kind: isEmptyRoot)

proc variableId(p: Partitions; x: PSym): int {.inline.} = system.find(p.symToId, x)

proc root(v: var Partitions; start: int): int =
  result = start
  while v.s[result].kind == dependsOn:
    result = v.s[result].parent
  # path compression:
  var it = start
  while v.s[it].kind == dependsOn:
    let next = v.s[it].parent
    v.s[it] = VarIndex(kind: dependsOn, parent: result)
    it = next

proc potentialMutation(v: var Partitions; s: PSym) =
  let id = variableId(v, s)
  if id >= 0:
    let r = root(v, id)
    case v.s[r].kind
    of isEmptyRoot:
      v.s[r] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len)
      v.graphs.add({isMutated})
    of isRootOf:
      v.graphs[v.s[r].graphIndex].incl isMutated
    else:
      assert false, "cannot happen"
  else:
    discard "we are not interested in the mutation"

proc connect(v: var Partitions; a, b: PSym) =
  template isConstParam(a): bool = a.kind == skParam and a.typ.kind != tyVar

  let aid = variableId(v, a)
  if aid < 0:
    return
  let bid = variableId(v, b)
  if bid < 0:
    return

  let ra = root(v, aid)
  let rb = root(v, bid)
  if ra != rb:
    let paramFlags =
      if isConstParam(a) or isConstParam(b):
        {connectsConstParam}
      else:
        {}

    # for now we always make 'rb' the slave and 'ra' the master:
    let rbFlags =
      if v.s[rb].kind == isRootOf:
        v.graphs[v.s[rb].graphIndex]
      else:
        {}

    v.s[rb] = VarIndex(kind: dependsOn, parent: ra)
    case v.s[ra].kind
    of isEmptyRoot:
      v.s[ra] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len)
      v.graphs.add(paramFlags + rbFlags)
    of isRootOf:
      v.graphs[v.s[ra].graphIndex].incl paramFlags + rbFlags
    else:
      assert false, "cannot happen"

proc allRoots(n: PNode; result: var seq[PSym]) =
  case n.kind
  of nkSym:
    if n.sym.kind in {skParam, skVar, skTemp, skLet, skResult, skForVar}:
      result.add(n.sym)
  of nkHiddenDeref, nkDerefExpr, nkAddr, nkDotExpr, nkBracketExpr,
      nkCheckedFieldExpr, nkHiddenAddr, nkObjUpConv, nkObjDownConv:
    allRoots(n[0], result)
  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv, nkConv,
      nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkCast:
    if n.len > 0:
      allRoots(n.lastSon, result)
  of nkCaseStmt, nkObjConstr:
    for i in 1..<n.len:
      allRoots(n[i].lastSon, result)
  of nkIfStmt, nkIfExpr:
    for i in 0..<n.len:
      allRoots(n[i].lastSon, result)
  of nkBracket, nkTupleConstr, nkPar:
    for i in 0..<n.len:
      allRoots(n[i], result)

  of nkCallKinds:
    if n.typ != nil and n.typ.kind in {tyVar, tyLent}:
      if n.len > 1:
        allRoots(n[1], result)
    else:
      let m = getMagic(n)
      case m
      of mNone:
        # we do significantly better here by using the available escape
        # information:
        if n[0].typ.isNil: return
        var typ = n[0].typ
        if typ != nil:
          typ = skipTypes(typ, abstractInst)
          if typ.kind != tyProc: typ = nil
          else: assert(typ.len == typ.n.len)

        for i in 1 ..< n.len:
          let it = n[i]
          if typ != nil and i < typ.len:
            assert(typ.n[i].kind == nkSym)
            let paramType = typ.n[i]
            if not paramType.typ.isCompileTimeOnly:
              allRoots(it, result)
          else:
            allRoots(it, result)

      of mSlice:
        allRoots(n[1], result)
      else:
        discard "harmless operation"
  else:
    discard "nothing to do"

proc deps(p: var Partitions; dest, src: PNode) =
  var targets, sources: seq[PSym]
  allRoots(dest, targets)
  allRoots(src, sources)
  for t in targets:
    if dest.kind != nkSym:
      potentialMutation(p, t)

    proc wrap(t: PType): bool {.nimcall.} = t.kind in {tyRef, tyPtr}
    if types.searchTypeFor(t.typ, wrap):
      for s in sources:
        connect(p, t, s)

proc traverse(p: var Partitions; n: PNode) =
  case n.kind
  of nkLetSection, nkVarSection:
    for child in n:
      let last = lastSon(child)
      traverse(p, last)
      if child.kind == nkVarTuple and last.kind in {nkPar, nkTupleConstr}:
        if child.len-2 != last.len: return
        for i in 0..<child.len-2:
          registerVariable(p, child[i])
          deps(p, child[i], last[i])
      else:
        for i in 0..<child.len-2:
          registerVariable(p, child[i])
          deps(p, child[i], last)
  of nkAsgn, nkFastAsgn:
    traverse(p, n[0])
    traverse(p, n[1])
    deps(p, n[0], n[1])
  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
    discard "do not follow the construct"
  of nkCallKinds:
    for child in n: traverse(p, child)

    if n[0].typ.isNil: return
    var typ = skipTypes(n[0].typ, abstractInst)
    if typ.kind != tyProc: return
    assert(typ.len == typ.n.len)
    for i in 1..<n.len:
      let it = n[i]
      if i < typ.len:
        assert(typ.n[i].kind == nkSym)
        let paramType = typ.n[i]
        if paramType.typ.isCompileTimeOnly: continue
        if paramType.typ.kind == tyVar:
          var roots: seq[PSym]
          allRoots(n, roots)
          for r in roots: potentialMutation(p, r)

  else:
    for child in n: traverse(p, child)


proc mutatesNonVarParameters*(s: PSym; n: PNode): bool =
  var par = Partitions()
  if s.kind != skMacro:
    let params = s.typ.n
    for i in 1..<params.len:
      registerVariable(par, params[i])
    if resultPos < s.ast.safeLen:
      registerVariable(par, s.ast[resultPos])

  traverse(par, n)
  result = hasSideEffect(par)
