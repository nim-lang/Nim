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
from trees import getMagic, whichPragma
from wordrecg import wNoSideEffect
from isolation_check import canAlias
<<<<<<< HEAD
<<<<<<< HEAD
import tables, treetab, strutils, sequtils

type
  TrackedNode* = (int, PNode)
  # PNode and calculating 

  # Indirection = 1 <=> normal case
  # (deref level)

  SubgraphFlag* = enum
    isMutated, # graph might be mutated
    connectsConstParam, # graph is connected to a non-var parameter.

  VarFlag* = enum
    ownsData,
    preventCursor

  VarId* = int
  
  GraphId* = int

  VarIndexKind* = enum
=======
import tables, treetab
=======
import tables, treetab, strutils, sequtils
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug

type
  TrackedNode* = (int, PNode)
  # PNode and calculating 

  # Indirection = 1 <=> normal case
  # (deref level)

  SubgraphFlag* = enum
    isMutated, # graph might be mutated
    connectsConstParam, # graph is connected to a non-var parameter.

  VarFlag* = enum
    ownsData,
    preventCursor

<<<<<<< HEAD
  VarIndexKind = enum
>>>>>>> Work on mutation and aliasing: not finished
=======
  VarId* = int
  
  GraphId* = int

  VarIndexKind* = enum
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
    isEmptyRoot,
    dependsOn,
    isRootOf

<<<<<<< HEAD
<<<<<<< HEAD
  VarIndex* = object
    flags*: set[VarFlag]
    case kind*: VarIndexKind
    of isEmptyRoot: discard
    of dependsOn: parent*: VarId
    of isRootOf: graphIndex*: GraphId
    # sym: PSym
    sym: TrackedNode


  MutationInfo* = object
    param*: TrackedNode
    mutatedHere*, connectedVia*: TLineInfo
    flags*: set[SubgraphFlag]

  Partitions* = object
    s*: seq[VarIndex]
    graphs*: seq[MutationInfo]
    unanalysableMutation, performCursorInference: bool
    inAsgnSource, inConstructor, inNoSideEffectSection: int

#type
  #DistinctSeq[T, U] = seq[U]
#proc `[]`*[T, U](a: distinctSeq[T, U], b: T): U =
 # return cast[seq[U]](a)[b.int]
=======
  VarIndex = object
    flags: set[VarFlag]
    case kind: VarIndexKind
=======
  VarIndex* = object
    flags*: set[VarFlag]
    case kind*: VarIndexKind
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
    of isEmptyRoot: discard
    of dependsOn: parent*: VarId
    of isRootOf: graphIndex*: GraphId
    # sym: PSym
    sym: TrackedNode


  MutationInfo* = object
    param*: TrackedNode
    mutatedHere*, connectedVia*: TLineInfo
    flags*: set[SubgraphFlag]

  Partitions* = object
    s*: seq[VarIndex]
    graphs*: seq[MutationInfo]
    unanalysableMutation, performCursorInference: bool
    inAsgnSource, inConstructor, inNoSideEffectSection: int
<<<<<<< HEAD
    symbols: Table[Symbol, PSym]
>>>>>>> Work on mutation and aliasing: not finished
=======

#type
  #DistinctSeq[T, U] = seq[U]
#proc `[]`*[T, U](a: distinctSeq[T, U], b: T): U =
 # return cast[seq[U]](a)[b.int]
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug

proc `$`*(config: ConfigRef; g: MutationInfo): string =
  result = ""
  if g.flags == {isMutated, connectsConstParam}:
    result.add "\nan object reachable from '"
    result.add $g.param[1]
    result.add "' is potentially mutated"
    if g.mutatedHere != unknownLineInfo:
      result.add "\n"
      result.add config $ g.mutatedHere
      result.add " the mutation is here"
    if g.connectedVia != unknownLineInfo:
      result.add "\n"
      result.add config $ g.connectedVia
      result.add " is the statement that connected the mutation to the parameter"

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
proc toTextGraph(config: ConfigRef, par: Partitions): string =
  # {a} ---18:9---> {b}
  # 
  result = ""
  var setTable: Table[int, seq[PNode]]

  # TODO detect nodes repetition

  var emptyRootIndex = par.graphs.len
  for i, variable in par.s:
    case variable.kind:
      of isEmptyRoot:
        # {a}
        result.add("{" & $variable.sym[1] & "}\n")
        setTable[emptyRootIndex] = @[variable.sym[1]]
        emptyRootIndex += 1
      of isRootOf:
        #  a ---line:column--> b
        # echo "graph index ", variable.sym[1], " ", variable.graphIndex
        var graph = par.graphs[variable.graphIndex]
        result.add(
          $variable.sym[1] & 
          " ---" & $graph.mutatedHere.line & ":" & $graph.mutatedHere.col & "-->" & 
          $graph.param[1] & "\n")
        if not setTable.hasKey(variable.graphIndex):
          setTable[variable.graphIndex] = @[variable.sym[1]]
      of dependsOn:
        # b -> a
        let parent = par.s[variable.parent]
        result.add($parent.sym[1] & " -> " & $variable.sym[1] & "\n")
        let index = parent.graphIndex
        if not setTable.hasKey(index):
          setTable[index] = @[parent.sym[1]]
        setTable[index].add(variable.sym[1])
 
  result.add("\n")

  for index, nodeSet in setTable:
    # index : {a, b}
    result.add($index & " : {" & nodeSet.mapIt($it).join(", ") & "}\n")

<<<<<<< HEAD
=======
>>>>>>> Work on mutation and aliasing: not finished
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
proc hasSideEffect(c: var Partitions; info: var MutationInfo): bool =
  for g in mitems c.graphs:
    if g.flags == {isMutated, connectsConstParam}:
      info = g
      return true
  return false

template isConstParam(a): bool = a[1].kind == nkSym and a[1].sym.kind == skParam and a[1].sym.typ.kind != tyVar

<<<<<<< HEAD
<<<<<<< HEAD
proc tracked(n: PNode): TrackedNode
  ## tracked : id and node for a node

proc eq(a: TrackedNode, b: TrackedNode): bool =
  ## tracked nodes are equal when their id-s are equal
  a[0] == b[0]

const resultId = -1
let noTrackedNode: TrackedNode = (-2, nil)

proc registerVariable(c: var Partitions; n: PNode) =
  #if n.kind == nkSym:
  if isConstParam(tracked(n)):
    c.s.add VarIndex(kind: isRootOf, graphIndex: c.graphs.len.GraphId, sym: tracked(n))
    c.graphs.add MutationInfo(param: tracked(n), mutatedHere: unknownLineInfo,
                          connectedVia: unknownLineInfo, flags: {connectsConstParam})
  else:
    c.s.add VarIndex(kind: isEmptyRoot, sym: tracked(n))

proc variableId(c: Partitions; x: TrackedNode): VarId {.inline.} =
  for i in 0 ..< c.s.len:
    if eq(c.s[i].sym, x): return i.VarId
  return (-1).VarId

proc root(v: var Partitions; start: int): VarId =
=======
proc symbol(n: PNode): Symbol
  ## symbol : id and node for a node
=======
proc tracked(n: PNode): TrackedNode
  ## tracked : id and node for a node
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug

proc eq(a: TrackedNode, b: TrackedNode): bool =
  ## tracked nodes are equal when their id-s are equal
  a[0] == b[0]

const resultId = -1
let noTrackedNode: TrackedNode = (-2, nil)

proc registerVariable(c: var Partitions; n: PNode) =
  #if n.kind == nkSym:
  if isConstParam(tracked(n)):
    c.s.add VarIndex(kind: isRootOf, graphIndex: c.graphs.len.GraphId, sym: tracked(n))
    c.graphs.add MutationInfo(param: tracked(n), mutatedHere: unknownLineInfo,
                          connectedVia: unknownLineInfo, flags: {connectsConstParam})
  else:
    c.s.add VarIndex(kind: isEmptyRoot, sym: tracked(n))

proc variableId(c: Partitions; x: TrackedNode): VarId {.inline.} =
  for i in 0 ..< c.s.len:
    if eq(c.s[i].sym, x): return i.VarId
  return (-1).VarId

<<<<<<< HEAD
proc root(v: var Partitions; start: int): int =
>>>>>>> Work on mutation and aliasing: not finished
=======
proc root(v: var Partitions; start: int): VarId =
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
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

<<<<<<< HEAD
<<<<<<< HEAD
proc potentialMutation(v: var Partitions; s: TrackedNode; info: TLineInfo) =
=======
proc potentialMutation(v: var Partitions; s: Symbol; info: TLineInfo) =
>>>>>>> Work on mutation and aliasing: not finished
=======
proc potentialMutation(v: var Partitions; s: TrackedNode; info: TLineInfo) =
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  let id = variableId(v, s)
  if id >= 0:
    let r = root(v, id)
    case v.s[r].kind
    of isEmptyRoot:
<<<<<<< HEAD
<<<<<<< HEAD
      v.s[r] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len.GraphId,
                        sym: v.s[r].sym, flags: v.s[r].flags)
      # echo "potential"
      v.graphs.add MutationInfo(param: if isConstParam(s): s else: noTrackedNode, mutatedHere: info,
                            connectedVia: unknownLineInfo, flags: {isMutated})
    of isRootOf:
      let g = addr v.graphs[v.s[r].graphIndex]
      if eq(g.param, noTrackedNode) and isConstParam(s):
=======
      v.s[r] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len,
=======
      v.s[r] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len.GraphId,
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
                        sym: v.s[r].sym, flags: v.s[r].flags)
      echo "potential"
      v.graphs.add MutationInfo(param: if isConstParam(s): s else: noTrackedNode, mutatedHere: info,
                            connectedVia: unknownLineInfo, flags: {isMutated})
    of isRootOf:
      let g = addr v.graphs[v.s[r].graphIndex]
<<<<<<< HEAD
      if eq(g.param, noSymbol) and isConstParam(s):
>>>>>>> Work on mutation and aliasing: not finished
=======
      if eq(g.param, noTrackedNode) and isConstParam(s):
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
        g.param = s
      if g.mutatedHere == unknownLineInfo:
        g.mutatedHere = info
      g.flags.incl isMutated
    else:
      assert false, "cannot happen"
  else:
    v.unanalysableMutation = true


<<<<<<< HEAD
<<<<<<< HEAD
proc tracked(n: PNode): TrackedNode =
  ## returns a TrackedNode for each expression
=======
proc symbol(n: PNode): Symbol =
  ## returns a Symbol for each expression
>>>>>>> Work on mutation and aliasing: not finished
=======
proc tracked(n: PNode): TrackedNode =
  ## returns a TrackedNode for each expression
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  ## the goal is to get an unique Symbol
  ## but we have to ensure hashTree does it as we expect
  case n.kind:
  of nkIdent:
    # echo "ident?", $n
<<<<<<< HEAD
<<<<<<< HEAD
    result = noTrackedNode
=======
    result = noSymbol
>>>>>>> Work on mutation and aliasing: not finished
=======
    result = noTrackedNode
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  of nkSym:
    if n.sym.kind == skResult: # credit to disruptek for showing me that
      result = (resultId, n)
    else:
      result = (n.sym.id, n)
  of nkHiddenAddr, nkAddr:
<<<<<<< HEAD
<<<<<<< HEAD
    result = tracked(n[0])
=======
    result = symbol(n[0])
>>>>>>> Work on mutation and aliasing: not finished
=======
    result = tracked(n[0])
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  else:
    result = (hashTree(n), n)
  # echo result



<<<<<<< HEAD
<<<<<<< HEAD
proc connect(v: var Partitions; a, b: TrackedNode; info: TLineInfo) =
  let aid = variableId(v, a)
  if aid < 0:
    return
  let bid = variableId(v, b)
=======
proc connect(v: var Partitions; a, b: Symbol; info: TLineInfo) =
  echo "a ", a, "b ", b
=======
proc connect(v: var Partitions; a, b: TrackedNode; info: TLineInfo) =
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  let aid = variableId(v, a)
  if aid < 0:
    return
  let bid = variableId(v, b)
<<<<<<< HEAD
  echo bid
>>>>>>> Work on mutation and aliasing: not finished
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  if bid < 0:
    return

  let ra = root(v, aid)
  let rb = root(v, bid)
<<<<<<< HEAD
<<<<<<< HEAD
  if ra != rb:
    var param: TrackedNode = noTrackedNode
    if isConstParam(a): param = a
    elif isConstParam(b): param = b
    let paramFlags =
      if not eq(param, noTrackedNode):
=======
  echo ra
  echo rb
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  if ra != rb:
    var param: TrackedNode = noTrackedNode
    if isConstParam(a): param = a
    elif isConstParam(b): param = b
    let paramFlags =
<<<<<<< HEAD
      if not eq(param, noSymbol):
>>>>>>> Work on mutation and aliasing: not finished
=======
      if not eq(param, noTrackedNode):
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
        {connectsConstParam}
      else:
        {}

    # for now we always make 'rb' the slave and 'ra' the master:
    var rbFlags: set[SubgraphFlag] = {}
    var mutatedHere = unknownLineInfo
    if v.s[rb].kind == isRootOf:
      var gb = addr v.graphs[v.s[rb].graphIndex]
<<<<<<< HEAD
<<<<<<< HEAD
      if eq(param, noTrackedNode): param = gb.param
=======
      if eq(param, noSymbol): param = gb.param
>>>>>>> Work on mutation and aliasing: not finished
=======
      if eq(param, noTrackedNode): param = gb.param
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
      mutatedHere = gb.mutatedHere
      rbFlags = gb.flags

    v.s[rb] = VarIndex(kind: dependsOn, parent: ra, sym: v.s[rb].sym, flags: v.s[rb].flags)
    case v.s[ra].kind
    of isEmptyRoot:
<<<<<<< HEAD
<<<<<<< HEAD
      v.s[ra] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len.GraphId, sym: v.s[ra].sym, flags: v.s[ra].flags)
=======
      v.s[ra] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len, sym: v.s[ra].sym, flags: v.s[ra].flags)
>>>>>>> Work on mutation and aliasing: not finished
=======
      v.s[ra] = VarIndex(kind: isRootOf, graphIndex: v.graphs.len.GraphId, sym: v.s[ra].sym, flags: v.s[ra].flags)
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
      v.graphs.add MutationInfo(param: param, mutatedHere: mutatedHere,
                            connectedVia: info, flags: paramFlags + rbFlags)
    of isRootOf:
      var g = addr v.graphs[v.s[ra].graphIndex]
<<<<<<< HEAD
<<<<<<< HEAD
      if eq(g.param, noTrackedNode): g.param = param
=======
      if eq(g.param, noSymbol): g.param = param
>>>>>>> Work on mutation and aliasing: not finished
=======
      if eq(g.param, noTrackedNode): g.param = param
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
      if g.mutatedHere == unknownLineInfo: g.mutatedHere = mutatedHere
      g.connectedVia = info
      g.flags.incl paramFlags + rbFlags
    else:
      assert false, "cannot happen"

<<<<<<< HEAD
<<<<<<< HEAD
proc allRoots(n: PNode; result: var seq[TrackedNode]; followDotExpr = true) =
  case n.kind
  of nkSym:
    if n.sym.kind in {skParam, skVar, skTemp, skLet, skResult, skForVar}:
      result.add(tracked(n))

  of nkDotExpr:
   result.add(tracked(n))
  of nkDerefExpr, nkBracketExpr, nkHiddenDeref,
      nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
=======
proc allRoots(n: PNode; result: var seq[Symbol]; followDotExpr = true) =
=======
proc allRoots(n: PNode; result: var seq[TrackedNode]; followDotExpr = true) =
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  case n.kind
  of nkSym:
    if n.sym.kind in {skParam, skVar, skTemp, skLet, skResult, skForVar}:
      result.add(tracked(n))

  of nkDotExpr:
   result.add(tracked(n))
  of nkDerefExpr, nkBracketExpr, nkHiddenDeref,
      nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
<<<<<<< HEAD
    # result.add(symbol(n))
>>>>>>> Work on mutation and aliasing: not finished
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
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

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  # a, b
  # call(a) # call(a: var int) Mutation

  # a.b
  # call(a) # call(a: ref A) Mutation 

  # {a} {b} {c}
  # {a, b} {c}
  
  # (tyVar, addrOf?) -> 

  # call(a.b) -> if a.b. is tyRef 2

  # var -> 0 / ByAddr  (a)
  # ref -> 1 / ByField (a.field) (a[0])
  # 

  # 0 / 1+ most important
  # 
  # local: 0 graph: 1
  # a 1 

<<<<<<< HEAD
=======
>>>>>>> Work on mutation and aliasing: not finished
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
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
<<<<<<< HEAD
<<<<<<< HEAD
        connect(c, dest.sym, tracked(n), n.info)
=======
        connect(c, dest.sym, symbol(n), n.info)
>>>>>>> Work on mutation and aliasing: not finished
=======
        connect(c, dest.sym, tracked(n), n.info)
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
        # but a construct like ``[symbol]`` is dangerous:
        if c.inConstructor > 0: dest.flags.incl ownsData

  of nkDotExpr:
<<<<<<< HEAD
<<<<<<< HEAD
    connect(c, dest.sym, tracked(n), n.info)
=======
    connect(c, dest.sym, symbol(n), n.info)
>>>>>>> Work on mutation and aliasing: not finished
=======
    connect(c, dest.sym, tracked(n), n.info)
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  of nkBracketExpr, nkHiddenDeref, nkDerefExpr,
      nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
    analyseAsgn(c, dest, n)

  of nkCallKinds:
    if hasDestructor(n.typ):
      # calls do construct, what we construct must be destroyed,
      # so dest cannot be a cursor:
      dest.flags.incl ownsData
    elif n.typ.kind in {tyLent, tyVar}:
      # we know the result is derived from the first argument:
<<<<<<< HEAD
<<<<<<< HEAD
      var roots: seq[TrackedNode]
=======
      var roots: seq[Symbol]
>>>>>>> Work on mutation and aliasing: not finished
=======
      var roots: seq[TrackedNode]
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
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

<<<<<<< HEAD
<<<<<<< HEAD
proc noCursor(c: var Partitions, s: TrackedNode) =
=======
proc noCursor(c: var Partitions, s: Symbol) =
>>>>>>> Work on mutation and aliasing: not finished
=======
proc noCursor(c: var Partitions, s: TrackedNode) =
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  let vid = variableId(c, s)
  if vid >= 0:
    c.s[vid].flags.incl preventCursor

proc rhsIsSink(c: var Partitions, n: PNode) =
  if n.kind == nkSym and n.typ.skipTypes(abstractInst-{tyOwned}).kind == tyRef:
    discard "do no pessimize simple refs further, injectdestructors.nim will prevent moving from it"
  else:
<<<<<<< HEAD
<<<<<<< HEAD
    var roots: seq[TrackedNode]
=======
    var roots: seq[Symbol]
>>>>>>> Work on mutation and aliasing: not finished
=======
    var roots: seq[TrackedNode]
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
    allRoots(n, roots, followDotExpr = false)
    # let x = cursor? --> treat it like a sink parameter
    for r in roots:
      noCursor(c, r)

proc deps(c: var Partitions; dest, src: PNode) =
<<<<<<< HEAD
<<<<<<< HEAD
  var targets, sources: seq[TrackedNode]
=======
  var targets, sources: seq[Symbol]
>>>>>>> Work on mutation and aliasing: not finished
=======
  var targets, sources: seq[TrackedNode]
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  allRoots(dest, targets)
  allRoots(src, sources)

  proc wrap(t: PType): bool {.nimcall.} = t.kind in {tyRef, tyPtr}
  let destIsComplex = types.searchTypeFor(dest.typ, wrap)

  for t in targets:
    if dest.kind != nkSym and c.inNoSideEffectSection == 0:
      potentialMutation(c, t, dest.info)

    if destIsComplex:
      for s in sources:
        connect(c, t, s, dest.info)

  if c.performCursorInference and src.kind != nkEmpty:
    if dest.kind == nkSym:
<<<<<<< HEAD
<<<<<<< HEAD
      let vid = variableId(c, tracked(dest))
=======
      let vid = variableId(c, symbol(dest))
>>>>>>> Work on mutation and aliasing: not finished
=======
      let vid = variableId(c, tracked(dest))
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
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
    if n[0].kind == nkDotExpr:
      registerVariable(c, n[0])
      deps(c, n[0], n[1])
    if n[1].kind == nkDotExpr:
      registerVariable(c, n[1])
      deps(c, n[0], n[1])
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
<<<<<<< HEAD
<<<<<<< HEAD
          var roots: seq[TrackedNode]
=======
          var roots: seq[Symbol]
>>>>>>> Work on mutation and aliasing: not finished
=======
          var roots: seq[TrackedNode]
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
          allRoots(it, roots)
          if paramType.kind == tyVar:
            if c.inNoSideEffectSection == 0:
              for r in roots: potentialMutation(c, r, it.info)
          else:
            for r in roots: noCursor(c, r)

  of nkAddr, nkHiddenAddr:
    traverse(c, n[0])
    when false:
      # XXX investigate if this is required, it doesn't look
      # like it is!
<<<<<<< HEAD
<<<<<<< HEAD
      var roots: seq[TrackedNode]
=======
      var roots: seq[Symbol]
>>>>>>> Work on mutation and aliasing: not finished
=======
      var roots: seq[TrackedNode]
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
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
<<<<<<< HEAD
<<<<<<< HEAD
          noCursor(c, tracked(n[i]))
=======
          noCursor(c, symbol(n[i]))
>>>>>>> Work on mutation and aliasing: not finished
=======
          noCursor(c, tracked(n[i]))
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug

  of nkObjConstr:
    for child in n: traverse(c, child)
    if c.inAsgnSource > 0:
      for i in 1..<n.len:
        let it = n[i].skipColon
        if it.kind == nkSym:
          # we assume constructions with cursors are better without
          # the cursors because it's likely we can move then, see
          # test arc/topt_no_cursor.nim
<<<<<<< HEAD
<<<<<<< HEAD
          noCursor(c, tracked(it))
=======
          noCursor(c, symbol(it))
>>>>>>> Work on mutation and aliasing: not finished
=======
          noCursor(c, tracked(it))
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug

  of nkPragmaBlock:
    let pragmaList = n[0]
    var enforceNoSideEffects = 0
    for i in 0..<pragmaList.len:
      if whichPragma(pragmaList[i]) == wNoSideEffect:
        enforceNoSideEffects = 1
        break

    inc c.inNoSideEffectSection, enforceNoSideEffects
    traverse(c, n.lastSon)
    dec c.inNoSideEffectSection, enforceNoSideEffects
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
    if v.flags == {} and not v.sym[1].isNil and v.sym[1].kind == nkSym and v.sym[1].sym.kind notin {skParam, skResult} and
        v.sym[1].sym.flags * {sfThread, sfGlobal} == {} and hasDestructor(v.sym[1].sym.typ) and
        v.sym[1].sym.typ.skipTypes({tyGenericInst, tyAlias}).kind != tyOwned:
      let rid = root(par, i)
      if par.s[rid].kind == isRootOf and isMutated in par.graphs[par.s[rid].graphIndex].flags:
        discard "cannot cursor into a graph that is mutated"
      else:
        v.sym[1].sym.flags.incl sfCursor
        #echo "this is now a cursor ", v.sym, " ", par.s[rid].flags
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  
proc loadPartitions*(s: PSym, n: PNode, config: ConfigRef): Partitions =
  result = Partitions(performCursorInference: true)
  if s.kind notin {skMacro, skModule}:
    let params = s.typ.n
    for i in 1..<params.len:
      registerVariable(result, params[i])
    if resultPos < s.ast.safeLen:
      registerVariable(result, s.ast[resultPos])

  traverse(result, n)
  echo toTextGraph(config, result)
  
  # 
  # c -> b 
  #   -> d 
  #   -> e
  # g -> f

  # c -> b
  # e -> d
  # g -> f

  # c
  # b -> e
  #   -> d
  # g -> f
<<<<<<< HEAD
=======
>>>>>>> Work on mutation and aliasing: not finished
=======
>>>>>>> Render var parititions graph, try to understand it, fix a nilcheck if bug
  # for i, v in par.s:
  #   echo v
  #   if par.graphs.len - 1 >= i:
  #     echo par.graphs[i].mutatedHere.line
  #     echo par.graphs[i].flags
  #     echo par.graphs[i].param
  #   else:
  #     echo "no graph"
