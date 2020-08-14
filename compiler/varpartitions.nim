#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Partition variables into different graphs. Used for
## Nim's write tracking and also for the cursor inference.
## The algorithm is a reinvention / variation of Steensgaard's
## algorithm.
## The used data structure is "union find" with path compression.

import ast, types, lineinfos, options, msgs, renderer
from trees import getMagic
from isolation_check import canAlias

type
  SubgraphFlag = enum
    isMutated, # graph might be mutated
    connectsConstParam, # graph is connected to a non-var parameter.

  VarFlag = enum
    ownsData,
    preventCursor

  VarIndexKind = enum
    isEmptyRoot,
    dependsOn,
    isRootOf

  VarIndex = object
    flags: set[VarFlag]
    case kind: VarIndexKind
    of isEmptyRoot: discard
    of dependsOn: parent: int
    of isRootOf: graphIndex: int
    sym: PSym

  MutationInfo* = object
    param: PSym
    mutatedHere, connectedVia: TLineInfo
    flags: set[SubgraphFlag]

  Partitions = object
    s: seq[VarIndex]
    graphs: seq[MutationInfo]
    unanalysableMutation, performCursorInference: bool
    inAsgnSource, inConstructor: int

proc `$`*(config: ConfigRef; g: MutationInfo): string =
  result = ""
  if g.flags == {isMutated, connectsConstParam}:
    result.add "\nan object reachable from '"
    result.add g.param.name.s
    result.add "' is potentially mutated"
    if g.mutatedHere != unknownLineInfo:
      result.add "\n"
      result.add config $ g.mutatedHere
      result.add " the mutation is here"
    if g.connectedVia != unknownLineInfo:
      result.add "\n"
      result.add config $ g.connectedVia
      result.add " is the statement that connected the mutation to the parameter"

proc hasSideEffect(c: var Partitions; info: var MutationInfo): bool =
  for g in mitems c.graphs:
    if g.flags == {isMutated, connectsConstParam}:
      info = g
      return true
  return false

template isConstParam(a): bool = a.kind == skParam and a.typ.kind != tyVar

proc registerVariable(c: var Partitions; n: PNode) =
  if n.kind == nkSym:
    if isConstParam(n.sym):
      c.s.add VarIndex(kind: isRootOf, graphIndex: c.graphs.len, sym: n.sym)
      c.graphs.add MutationInfo(param: n.sym, mutatedHere: unknownLineInfo,
                            connectedVia: unknownLineInfo, flags: {connectsConstParam})
    else:
      c.s.add VarIndex(kind: isEmptyRoot, sym: n.sym)

proc variableId(c: Partitions; x: PSym): int {.inline.} =
  for i in 0 ..< c.s.len:
    if c.s[i].sym == x: return i
  return -1

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
      v.s[it] = VarIndex(kind: dependsOn, parent: result,
                         sym: v.s[it].sym, flags: v.s[it].flags)
      it = next

proc potentialMutation(v: var Partitions; s: PSym; info: TLineInfo) =
  let id = variableId(v, s)
  if id >= 0:
    let r = root(v, id)
    case v.s[r].kind
    of isEmptyRoot:
      v.s[r] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len,
                        sym: v.s[r].sym, flags: v.s[r].flags)
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
    v.unanalysableMutation = true

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

    v.s[rb] = VarIndex(kind: dependsOn, parent: ra, sym: v.s[rb].sym, flags: v.s[rb].flags)
    case v.s[ra].kind
    of isEmptyRoot:
      v.s[ra] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len, sym: v.s[ra].sym, flags: v.s[ra].flags)
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

proc allRoots(n: PNode; result: var seq[PSym]; followDotExpr = true) =
  case n.kind
  of nkSym:
    if n.sym.kind in {skParam, skVar, skTemp, skLet, skResult, skForVar}:
      result.add(n.sym)

  of nkDotExpr, nkDerefExpr, nkBracketExpr, nkHiddenDeref,
      nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
    if followDotExpr:
      allRoots(n[0], result, followDotExpr)

  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv, nkConv,
      nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkCast,
      nkObjUpConv, nkObjDownConv:
    if n.len > 0:
      allRoots(n.lastSon, result, followDotExpr)
  of nkCaseStmt, nkObjConstr:
    for i in 1..<n.len:
      allRoots(n[i].lastSon, result, followDotExpr)
  of nkIfStmt, nkIfExpr:
    for i in 0..<n.len:
      allRoots(n[i].lastSon, result, followDotExpr)
  of nkBracket, nkTupleConstr, nkPar:
    for i in 0..<n.len:
      allRoots(n[i], result, followDotExpr)

  of nkCallKinds:
    if n.typ != nil and n.typ.kind in {tyVar, tyLent}:
      if n.len > 1:
        allRoots(n[1], result, followDotExpr)
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
              allRoots(it, result, followDotExpr)
          else:
            allRoots(it, result, followDotExpr)

      of mSlice:
        allRoots(n[1], result, followDotExpr)
      else:
        discard "harmless operation"
  else:
    discard "nothing to do"

proc analyseAsgn(c: var Partitions; dest: var VarIndex; n: PNode) =
  case n.kind
  of nkEmpty, nkCharLit..nkNilLit:
    # primitive literals including the empty are harmless:
    discard

  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv, nkCast, nkConv:
    analyseAsgn(c, dest, n[1])

  of nkIfStmt, nkIfExpr:
    for i in 0..<n.len:
      analyseAsgn(c, dest, n[i].lastSon)

  of nkCaseStmt:
    for i in 1..<n.len:
      analyseAsgn(c, dest, n[i].lastSon)

  of nkStmtList, nkStmtListExpr:
    if n.len > 0:
      analyseAsgn(c, dest, n[^1])

  of nkClosure:
    for i in 1..<n.len:
      analyseAsgn(c, dest, n[i])
    # you must destroy a closure:
    dest.flags.incl ownsData

  of nkObjConstr:
    for i in 1..<n.len:
      analyseAsgn(c, dest, n[i])
    if hasDestructor(n.typ):
      # you must destroy a ref object:
      dest.flags.incl ownsData

  of nkCurly, nkBracket, nkPar, nkTupleConstr:
    inc c.inConstructor
    for son in n:
      analyseAsgn(c, dest, son)
    dec c.inConstructor
    if n.typ.skipTypes(abstractInst).kind == tySequence:
      # you must destroy a sequence:
      dest.flags.incl ownsData

  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet, skForVar, skParam}:
      if n.sym.flags * {sfThread, sfGlobal} != {}:
        # aliasing a global is inherently dangerous:
        dest.flags.incl ownsData
      else:
        # otherwise it's just a dependency, nothing to worry about:
        connect(c, dest.sym, n.sym, n.info)
        # but a construct like ``[symbol]`` is dangerous:
        if c.inConstructor > 0: dest.flags.incl ownsData

  of nkDotExpr, nkBracketExpr, nkHiddenDeref, nkDerefExpr,
      nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
    analyseAsgn(c, dest, n[0])

  of nkCallKinds:
    if hasDestructor(n.typ):
      # calls do construct, what we construct must be destroyed,
      # so dest cannot be a cursor:
      dest.flags.incl ownsData
    elif n.typ.kind in {tyLent, tyVar}:
      # we know the result is derived from the first argument:
      var roots: seq[PSym]
      allRoots(n[1], roots)
      for r in roots:
        connect(c, dest.sym, r, n[1].info)

    else:
      let magic = if n[0].kind == nkSym: n[0].sym.magic else: mNone
      # this list is subtle, we try to answer the question if after 'dest = f(src)'
      # there is a connection betwen 'src' and 'dest' so that mutations to 'src'
      # also reflect 'dest':
      if magic in {mNone, mMove, mSlice, mAppendStrCh, mAppendStrStr, mAppendSeqElem, mArrToSeq}:
        for i in 1..<n.len:
          # we always have to assume a 'select(...)' like mechanism.
          # But at least we do filter out simple POD types from the
          # list of dependencies via the 'hasDestructor' check for
          # the root's symbol.
          if hasDestructor(n[i].typ.skipTypes({tyVar, tySink, tyLent, tyGenericInst, tyAlias})):
            analyseAsgn(c, dest, n[i])

  else:
    # something we cannot handle:
    dest.flags.incl preventCursor

proc noCursor(c: var Partitions, s: PSym) =
  let vid = variableId(c, s)
  if vid >= 0:
    c.s[vid].flags.incl preventCursor

proc rhsIsSink(c: var Partitions, n: PNode) =
  if n.kind == nkSym and n.typ.skipTypes(abstractInst-{tyOwned}).kind == tyRef:
    discard "do no pessimize simple refs further, injectdestructors.nim will prevent moving from it"
  else:
    var roots: seq[PSym]
    allRoots(n, roots, followDotExpr = false)
    # let x = cursor? --> treat it like a sink parameter
    for r in roots:
      noCursor(c, r)

proc deps(c: var Partitions; dest, src: PNode) =
  var targets, sources: seq[PSym]
  allRoots(dest, targets)
  allRoots(src, sources)
  for t in targets:
    if dest.kind != nkSym:
      potentialMutation(c, t, dest.info)

    proc wrap(t: PType): bool {.nimcall.} = t.kind in {tyRef, tyPtr}
    if types.searchTypeFor(t.typ, wrap):
      for s in sources:
        connect(c, t, s, dest.info)

  if c.performCursorInference and src.kind != nkEmpty:
    if dest.kind == nkSym:
      let vid = variableId(c, dest.sym)
      if vid >= 0:
        analyseAsgn(c, c.s[vid], src)
        # do not borrow from a different local variable, this is easier
        # than tracking reassignments, consider 'var cursor = local; local = newNode()'
        if src.kind == nkSym and (src.sym.kind in {skVar, skResult, skTemp} or
            (src.sym.kind in {skLet, skParam, skForVar} and hasDisabledAsgn(src.sym.typ))):
          c.s[vid].flags.incl preventCursor

    if hasDestructor(src.typ):
      rhsIsSink(c, src)

proc traverse(c: var Partitions; n: PNode) =
  case n.kind
  of nkLetSection, nkVarSection:
    for child in n:
      let last = lastSon(child)
      traverse(c, last)
      if child.kind == nkVarTuple and last.kind in {nkPar, nkTupleConstr}:
        if child.len-2 != last.len: return
        for i in 0..<child.len-2:
          registerVariable(c, child[i])
          deps(c, child[i], last[i])
      else:
        for i in 0..<child.len-2:
          registerVariable(c, child[i])
          deps(c, child[i], last)
  of nkAsgn, nkFastAsgn:
    traverse(c, n[0])
    inc c.inAsgnSource
    traverse(c, n[1])
    dec c.inAsgnSource
    deps(c, n[0], n[1])
  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
    discard "do not follow the construct"
  of nkCallKinds:
    for child in n: traverse(c, child)

    let parameters = n[0].typ
    let L = if parameters != nil: parameters.len else: 0

    for i in 1..<n.len:
      let it = n[i]
      if i < L:
        let paramType = parameters[i].skipTypes({tyGenericInst, tyAlias})
        if not paramType.isCompileTimeOnly and paramType.kind in {tyVar, tySink, tyOwned}:
          var roots: seq[PSym]
          allRoots(it, roots)
          if paramType.kind == tyVar:
            for r in roots: potentialMutation(c, r, it.info)
          else:
            for r in roots: noCursor(c, r)

  of nkAddr, nkHiddenAddr:
    traverse(c, n[0])
    when false:
      # XXX investigate if this is required, it doesn't look
      # like it is!
      var roots: seq[PSym]
      allRoots(n[0], roots)
      for r in roots:
        potentialMutation(c, r, it.info)

  of nkTupleConstr, nkBracket:
    for child in n: traverse(c, child)
    if c.inAsgnSource > 0:
      for i in 0..<n.len:
        if n[i].kind == nkSym:
          # we assume constructions with cursors are better without
          # the cursors because it's likely we can move then, see
          # test arc/topt_no_cursor.nim
          noCursor(c, n[i].sym)

  of nkObjConstr:
    for child in n: traverse(c, child)
    if c.inAsgnSource > 0:
      for i in 1..<n.len:
        let it = n[i].skipColon
        if it.kind == nkSym:
          # we assume constructions with cursors are better without
          # the cursors because it's likely we can move then, see
          # test arc/topt_no_cursor.nim
          noCursor(c, it.sym)

  else:
    for child in n: traverse(c, child)

proc mutatesNonVarParameters*(s: PSym; n: PNode; info: var MutationInfo): bool =
  var par = Partitions(performCursorInference: false)
  if s.kind != skMacro:
    let params = s.typ.n
    for i in 1..<params.len:
      registerVariable(par, params[i])
    if resultPos < s.ast.safeLen:
      registerVariable(par, s.ast[resultPos])

  traverse(par, n)
  result = hasSideEffect(par, info)

proc computeCursors*(s: PSym; n: PNode; config: ConfigRef) =
  var par = Partitions(performCursorInference: true)
  if s.kind notin {skMacro, skModule}:
    let params = s.typ.n
    for i in 1..<params.len:
      registerVariable(par, params[i])
    if resultPos < s.ast.safeLen:
      registerVariable(par, s.ast[resultPos])

  traverse(par, n)
  for i in 0 ..< par.s.len:
    let v = addr(par.s[i])
    if v.flags == {} and v.sym.kind notin {skParam, skResult} and
        v.sym.flags * {sfThread, sfGlobal} == {} and hasDestructor(v.sym.typ) and
        v.sym.typ.skipTypes({tyGenericInst, tyAlias}).kind != tyOwned:
      let rid = root(par, i)
      if par.s[rid].kind == isRootOf and isMutated in par.graphs[par.s[rid].graphIndex].flags:
        discard "cannot cursor into a graph that is mutated"
      else:
        v.sym.flags.incl sfCursor
        #echo "this is now a cursor ", v.sym, " ", par.s[rid].flags
