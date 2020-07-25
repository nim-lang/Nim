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

import ast, types, lineinfos, options, msgs
from trees import getMagic
from isolation_check import canAlias

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

  MutationInfo* = object
    param: PSym
    mutatedHere, connectedVia: TLineInfo
    flags: set[SubgraphFlag]

  Partitions = object
    symToId: seq[PSym]
    s: seq[VarIndex]
    graphs: seq[MutationInfo]

proc `$`*(config: ConfigRef; g: MutationInfo): string =
  result = ""
  if g.flags == {isMutated, connectsConstParam}:
    result.add "\nan object reachable from "
    result.add g.param.name.s
    result.add " is potentially mutated"
    if g.mutatedHere != unknownLineInfo:
      result.add "\n"
      result.add config $ g.mutatedHere
      result.add " the mutation is here"
    if g.connectedVia != unknownLineInfo:
      result.add "\n"
      result.add config $ g.connectedVia
      result.add " is the statement that connected the mutation to the parameter"

proc hasSideEffect(p: var Partitions; info: var MutationInfo): bool =
  for g in mitems p.graphs:
    if g.flags == {isMutated, connectsConstParam}:
      info = g
      return true
  return false

template isConstParam(a): bool = a.kind == skParam and a.typ.kind != tyVar

proc registerVariable(p: var Partitions; n: PNode) =
  if n.kind == nkSym:
    p.symToId.add n.sym
    if isConstParam(n.sym):
      p.s.add VarIndex(kind: isRootOf, graphIndex: p.graphs.len)
      p.graphs.add MutationInfo(param: n.sym, mutatedHere: unknownLineInfo,
                            connectedVia: unknownLineInfo, flags: {connectsConstParam})
    else:
      p.s.add VarIndex(kind: isEmptyRoot)

proc variableId(p: Partitions; x: PSym): int {.inline.} = system.find(p.symToId, x)

proc root(v: var Partitions; start: int): int =
  result = start
  var depth = 0
  while v.s[result].kind == dependsOn:
    result = v.s[result].parent
    inc depth
  if depth > 0:
    # path compression:
    var it = start
    while v.s[it].kind == dependsOn:
      let next = v.s[it].parent
      v.s[it] = VarIndex(kind: dependsOn, parent: result)
      it = next

proc potentialMutation(v: var Partitions; s: PSym; info: TLineInfo) =
  let id = variableId(v, s)
  if id >= 0:
    let r = root(v, id)
    case v.s[r].kind
    of isEmptyRoot:
      v.s[r] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len)
      v.graphs.add MutationInfo(param: if isConstParam(s): s else: nil, mutatedHere: info,
                            connectedVia: unknownLineInfo, flags: {isMutated})
    of isRootOf:
      let g = addr v.graphs[v.s[r].graphIndex]
      if g.param == nil and isConstParam(s):
        g.param = s
      if g.mutatedHere == unknownLineInfo:
        g.mutatedHere = info
      g.flags.incl isMutated
    else:
      assert false, "cannot happen"
  else:
    discard "we are not interested in the mutation"

proc connect(v: var Partitions; a, b: PSym; info: TLineInfo) =
  let aid = variableId(v, a)
  if aid < 0:
    return
  let bid = variableId(v, b)
  if bid < 0:
    return

  let ra = root(v, aid)
  let rb = root(v, bid)
  if ra != rb:
    var param = PSym(nil)
    if isConstParam(a): param = a
    elif isConstParam(b): param = b

    let paramFlags =
      if param != nil:
        {connectsConstParam}
      else:
        {}

    # for now we always make 'rb' the slave and 'ra' the master:
    var rbFlags: set[SubgraphFlag] = {}
    var mutatedHere = unknownLineInfo
    if v.s[rb].kind == isRootOf:
      var gb = addr v.graphs[v.s[rb].graphIndex]
      if param == nil: param = gb.param
      mutatedHere = gb.mutatedHere
      rbFlags = gb.flags

    v.s[rb] = VarIndex(kind: dependsOn, parent: ra)
    case v.s[ra].kind
    of isEmptyRoot:
      v.s[ra] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len)
      v.graphs.add MutationInfo(param: param, mutatedHere: mutatedHere,
                            connectedVia: info, flags: paramFlags + rbFlags)
    of isRootOf:
      var g = addr v.graphs[v.s[ra].graphIndex]
      if g.param == nil: g.param = param
      if g.mutatedHere == unknownLineInfo: g.mutatedHere = mutatedHere
      g.connectedVia = info
      g.flags.incl paramFlags + rbFlags
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
            let paramType = typ.n[i].typ
            if not paramType.isCompileTimeOnly and not typ.sons[0].isEmptyType and
                canAlias(paramType, typ.sons[0]):
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
      potentialMutation(p, t, dest.info)

    proc wrap(t: PType): bool {.nimcall.} = t.kind in {tyRef, tyPtr}
    if types.searchTypeFor(t.typ, wrap):
      for s in sources:
        connect(p, t, s, dest.info)

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
          for r in roots: potentialMutation(p, r, n.info)

  else:
    for child in n: traverse(p, child)

proc mutatesNonVarParameters*(s: PSym; n: PNode; info: var MutationInfo): bool =
  var par = Partitions()
  if s.kind != skMacro:
    let params = s.typ.n
    for i in 1..<params.len:
      registerVariable(par, params[i])
    if resultPos < s.ast.safeLen:
      registerVariable(par, s.ast[resultPos])

  traverse(par, n)
  result = hasSideEffect(par, info)
