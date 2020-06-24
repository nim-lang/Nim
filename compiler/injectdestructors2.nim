#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Injects destructor calls into Nim code as well as
## an optimizer that optimizes copies to moves. This is implemented as an
## AST to AST transformation so that every backend benefits from it.

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents,
  strutils, options, dfa, lowerings, tables, modulegraphs, msgs,
  lineinfos, parampatterns, sighashes, liftdestructors

from trees import exprStructuralEquivalent, getRoot
from algorithm import reverse

type
  Con = object
    owner: PSym
    g: ControlFlowGraph
    jumpTargets: IntSet
    graph: ModuleGraph
    otherRead: PNode
    inSpawn: int

  Scope = object  # well we do scope-based memory management. \
    # a scope is comparable to an nkStmtListExpr like
    # (try: statements; dest = y(); finally: destructors(); dest)
    temps: seq[PSym]
    body: PNode   # statements that can fail
    final: seq[PNode] # finally section
    needsTry: bool

  SinkFlag = enum
    isDefinition,
    willBeConsumedAnyway
  SinkFlags = set[SinkFlag]

proc toTree(s: Scope; ret: PNode): PNode =
  if s.body == nil:
    assert s.temps.len == 0
    assert s.final.len == 0
    result = ret
  else:
    if ret == nil and s.temps.len == 0 and s.final.len == 0:
      # trivial, nothing was done:
      result = s.body
    else:
      if ret != nil:
        result = newNodeIT(nkStmtListExpr, ret.info, ret.typ)
      else:
        assert s.body != nil
        result = newNodeI(nkStmtList, s.body.info)
      if s.temps.len > 0:
        let varSection = newNodeI(nkVarSection, ret.info)
        for tmp in s.temps:
          varSection.add newTree(nkIdentDefs, newSymNode(tmp), newNodeI(nkEmpty, s.body.info),
                                                               newNodeI(nkEmpty, s.body.info))
        result.add varSection
      if s.needsTry:
        var finSection = newNodeI(nkStmtList, ret.info)
        for f in s.final: finSection.add f
        result.add newTryFinally(s.body, finSection)
      else:
        result.add s.body
        for f in s.final: result.add f
      if ret != nil:
        result.add ret

const toDebug {.strdefine.} = ""

template dbg(body) =
  when toDebug.len > 0:
    if c.owner.name.s == toDebug or toDebug == "always":
      body

include dataflow_analysis

proc checkForErrorPragma(c: Con; t: PType; ri: PNode; opname: string) =
  var m = "'" & opname & "' is not available for type <" & typeToString(t) & ">"
  if opname == "=" and ri != nil:
    m.add "; requires a copy because it's not the last read of '"
    m.add renderTree(ri)
    m.add '\''
    if c.otherRead != nil:
      m.add "; another read is done here: "
      m.add c.graph.config $ c.otherRead.info
    elif ri.kind == nkSym and ri.sym.kind == skParam and not isSinkType(ri.sym.typ):
      m.add "; try to make "
      m.add renderTree(ri)
      m.add " a 'sink' parameter"
  m.add "; routine: "
  m.add c.owner.name.s
  localError(c.graph.config, ri.info, errGenerated, m)

proc makePtrType(c: Con, baseType: PType): PType =
  result = newType(tyPtr, c.owner)
  addSonSkipIntLit(result, baseType)

proc genOp(c: Con; op: PSym; dest: PNode): PNode =
  let addrExp = newNodeIT(nkHiddenAddr, dest.info, makePtrType(c, dest.typ))
  addrExp.add(dest)
  result = newTree(nkCall, newSymNode(op), addrExp)

proc genOp(c: Con; t: PType; kind: TTypeAttachedOp; dest, ri: PNode): PNode =
  var op = t.attachedOps[kind]
  if op == nil or op.ast[genericParamsPos].kind != nkEmpty:
    # give up and find the canonical type instead:
    let h = sighashes.hashType(t, {CoType, CoConsiderOwned, CoDistinct})
    let canon = c.graph.canonTypes.getOrDefault(h)
    if canon != nil:
      op = canon.attachedOps[kind]
  if op == nil:
    #echo dest.typ.id
    globalError(c.graph.config, dest.info, "internal error: '" & AttachedOpToStr[kind] &
      "' operator not found for type " & typeToString(t))
  elif op.ast[genericParamsPos].kind != nkEmpty:
    globalError(c.graph.config, dest.info, "internal error: '" & AttachedOpToStr[kind] &
      "' operator is generic")
  dbg:
    if kind == attachedDestructor:
      echo "destructor is ", op.id, " ", op.ast
  if sfError in op.flags: checkForErrorPragma(c, t, ri, AttachedOpToStr[kind])
  genOp(c, op, dest)

proc genDestroy(c: Con; dest: PNode): PNode =
  let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedDestructor, dest, nil)

proc canBeMoved(c: Con; t: PType): bool {.inline.} =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  if optOwnedRefs in c.graph.config.globalOptions:
    result = t.kind != tyRef and t.attachedOps[attachedSink] != nil
  else:
    result = t.attachedOps[attachedSink] != nil

proc isNoInit(dest: PNode): bool {.inline.} =
  result = dest.kind == nkSym and sfNoInit in dest.sym.flags

proc isCursor(n: PNode): bool =
  case n.kind
  of nkSym:
    result = sfCursor in n.sym.flags
  of nkDotExpr:
    result = sfCursor in n[1].sym.flags
  of nkCheckedFieldExpr:
    result = isCursor(n[0])
  else:
    result = false

proc cycleCheck(n: PNode; c: var Con) =
  if c.graph.config.selectedGC != gcArc: return
  var value = n[1]
  if value.kind == nkClosure:
    value = value[1]
  if value.kind == nkNilLit: return
  let destTyp = n[0].typ.skipTypes(abstractInst)
  if destTyp.kind != tyRef and not (destTyp.kind == tyProc and destTyp.callConv == ccClosure):
    return

  var x = n[0]
  var field: PNode = nil
  while true:
    if x.kind == nkDotExpr:
      field = x[1]
      if field.kind == nkSym and sfCursor in field.sym.flags: return
      x = x[0]
    elif x.kind in {nkBracketExpr, nkCheckedFieldExpr, nkDerefExpr, nkHiddenDeref}:
      x = x[0]
    else:
      break
    if exprStructuralEquivalent(x, value, strictSymEquality = true):
      let msg =
        if field != nil:
          "'$#' creates an uncollectable ref cycle; annotate '$#' with .cursor" % [$n, $field]
        else:
          "'$#' creates an uncollectable ref cycle" % [$n]
      message(c.graph.config, n.info, warnCycleCreated, msg)
      break

proc getTemp(c: var Con; s: var Scope; typ: PType; info: TLineInfo): PNode =
  let sym = newSym(skTemp, getIdent(c.graph.cache, ":tmpD"), c.owner, info)
  sym.typ = typ
  s.temps.add(sym)
  result = newSymNode(sym)

proc st(n: PNode; c: var Con; s: var Scope; flags: SinkFlags): PNode

proc genDiscriminantAsgn(c: var Con; s: var Scope; n: PNode): PNode =
  # discriminator is ordinal value that doesn't need sink destroy
  # but fields within active case branch might need destruction

  # tmp to support self assignments
  let tmp = getTemp(c, n[1].typ, n.info)

  result = newTree(nkStmtList)
  result.add newTree(nkFastAsgn, tmp, st(n[1], c, s, {willBeConsumedAnyway}))

  let le = st(n[0], c, s, {})

  let leDotExpr = if le.kind == nkCheckedFieldExpr: le[0] else: le
  let objType = leDotExpr[0].typ

  if hasDestructor(objType):
    if objType.attachedOps[attachedDestructor] != nil and
        sfOverriden in objType.attachedOps[attachedDestructor].flags:
      localError(c.graph.config, n.info, errGenerated, """Assignment to discriminant for objects with user defined destructor is not supported, object must have default destructor.
It is best to factor out piece of object that needs custom destructor into separate object or not use discriminator assignment""")
    else:
      # generate: if le != tmp: `=destroy`(le)
      let branchDestructor = produceDestructorForDiscriminator(c.graph, objType, leDotExpr[1].sym, n.info)
      let cond = newNodeIT(nkInfix, n.info, getSysType(c.graph, unknownLineInfo, tyBool))
      cond.add newSymNode(getMagicEqSymForType(c.graph, le.typ, n.info))
      cond.add le
      cond.add tmp
      let notExpr = newNodeIT(nkPrefix, n.info, getSysType(c.graph, unknownLineInfo, tyBool))
      notExpr.add newSymNode(createMagic(c.graph, "not", mNot))
      notExpr.add cond
      result.add newTree(nkIfStmt, newTree(nkElifBranch, notExpr, genOp(c, branchDestructor, le)))
  result.add newTree(nkFastAsgn, le, tmp)

template isUnpackedTuple(n: PNode): bool =
  ## we move out all elements of unpacked tuples,
  ## hence unpacked tuples themselves don't need to be destroyed
  (n.kind == nkSym and n.sym.kind == skTemp and n.sym.typ.kind == tyTuple)

proc genSink(c: var Con; dest, ri: PNode, flags: SinkFlags): PNode =
  if isUnpackedTuple(dest) or isDefinition in flags or
      (isAnalysableFieldAccess(dest, c.owner) and isFirstWrite(dest, c)) or
      isNoInit(dest):
    # optimize sink call into a bitwise memcopy
    result = newTree(nkFastAsgn, dest, ri)
  else:
    let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
    if t.attachedOps[attachedSink] != nil:
      result = genOp(c, t, attachedSink, dest, ri)
      result.add ri
    else:
      # the default is to use combination of `=destroy(dest)` and
      # and copyMem(dest, source). This is efficient.
      let snk = newTree(nkFastAsgn, dest, ri)
      result = newTree(nkStmtList, genDestroy(c, dest), snk)

proc genCopyNoCheck(c: Con; dest, ri: PNode): PNode =
  let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedAsgn, dest, ri)

proc genCopy(c: var Con; dest, ri: PNode): PNode =
  let t = dest.typ
  if tfHasOwned in t.flags and ri.kind != nkNilLit:
    # try to improve the error message here:
    if c.otherRead == nil: discard isLastRead(ri, c)
    checkForErrorPragma(c, t, ri, "=")
  result = genCopyNoCheck(c, dest, ri)

proc genWasMoved(n: PNode; c: var Con): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newSymNode(createMagic(c.graph, "wasMoved", mWasMoved)))
  result.add copyTree(n) #mWasMoved does not take the address
  #if n.kind != nkSym:
  #  message(c.graph.config, n.info, warnUser, "wasMoved(" & $n & ")")

proc genDefaultCall(t: PType; c: Con; info: TLineInfo): PNode =
  result = newNodeI(nkCall, info)
  result.add(newSymNode(createMagic(c.graph, "default", mDefault)))
  result.typ = t

proc ensureDestruction(arg: PNode; c: var Con; s: var Scope): PNode =
  result = newNodeIT(nkStmtListExpr, arg.info, arg.typ)
  let tmp = getTemp(c, s, arg.typ, arg.info)
  result.add newTree(nkFastAsgn, tmp, arg)
  s.final.add genDestroy(c, tmp)

proc storeInto(dest, n: PNode; c: var Con; s: var Scope; flags: SinkFlags): PNode =
  if dest.kind == nkSym and dest.sym.kind == skTemp:
    result = newTree(nkFastAsgn, dest, n)
  elif willBeConsumedAnyway in flags:
    result = n
  else:
    result = genSink(c, dest, n, flags)

proc st(n: PNode; c: var Con; s: var Scope; flags: SinkFlags): PNode =
  # It handles a statement and can create a new scope.
  case n.kind
  of nkCast:
    # dest = cast[T](x)
    result = shallowCopy(n)
    result[0] = n[0]
    result[1] = st(n[1], nil, c, s, {})
  of nkCheckedFieldExpr, nkDotExpr:
    result = shallowCopy(n)
    result[0] = st(n[0], nil, c, s, {})
    result[1] = n[1]
  of nkCaseStmt:
    result = copyNode(n)
    result.add st(n[0], c, s)
    for i in 1..<n.len:
      let it = n[i]
      assert it.kind in {nkOfBranch, nkElse}

      var branch = shallowCopy(it)
      for j in 0 ..< it.len-1:
        branch[j] = copyTree(it[j])
      var ofScope: Scope
      let ofResult = st(it[^1], c, ofScope, flags)
      branch[^1] = toTree(ofScope, ofResult)
      result.add branch

  of nkWhileStmt:
    result = copyNode(n)
    result.add st(n[0], c, s, {})
    var bodyScope: Scope
    let bodyResult = st(n[1], c, bodyScope, {})
    result.add toTree(bodyScope, bodyResult)

  of nkBlockStmt, nkBlockExpr:
    result = copyNode(n)
    result.add n[0]
    var bodyScope: Scope
    let bodyResult = st(n[1], c, bodyScope, flags)
    result.add toTree(bodyScope, bodyResult)

  of nkIfStmt, nkIfExpr:
    result = copyNode(n)
    for i in 0..<n.len:
      let it = n[i]
      var branch = shallowCopy(it)
      if it.kind in {nkElifBranch, nkElifExpr}:
        var condScope: Scope
        var condResult = st(it[0], c, condScope, {})
        branch[0] = toTree(condScope, condResult)

      var branchScope: Scope
      var branchResult = st(it[0], c, branchScope, flags)
      branch[^1] = toTree(branchScope, branchResult)

  of nkWhen:
    # This should be a "when nimvm" node.
    result = copyTree(n)
    result[1][0] = st(n[1][0], c, s, flags)
  of nkStmtList, nkStmtListExpr:
    # a statement list does not introduce a new scope:
    if not isEmptyType(n.typ) and n.len > 0:
      result = newNodeI(nkStmtList, n.info)
      for i in 0 ..< n.len-1:
        result.add st(n[i], nil, c, s)
      if dest != nil:
        result.add st(n[^1], dest, c, s)
      else:
        # move into a temp:
        let tmp = getTemp(c, s, n.typ, n.info)
        result.add st(n[^1], tmp, c, s, flags)
        # XXX Is this really correct? Who is responsible for cleanups?
        if hasDestructor(n.typ):
          s.final.add genDestroy(c, tmp)
    else:
      result = shallowCopy(n)
      for i in 0 ..< n.len:
        result[i] = st(n[i], nil, c, s, {})
      assert dest == nil

  of nkDiscardStmt:
    result = shallowCopy(n)
    if n[0].kind != nkEmpty:
      result[0] = st(n[0], c, s, {})
    else:
      result[0] = copyNode(n[0])

  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState:
    # nothing to do
    result = n
  of nkBreakStmt:
    s.needsTry = true
    result = n
  of nkReturnStmt:
    result = shallowCopy(n)
    for i in 0 ..< n.len:
      result[i] = st(n[i], c, s, {})
    s.needsTry = true

  of nkAsgn, nkFastAsgn:
    if hasDestructor(n[0].typ) and not isCursor(n[0]):
      # rule (self-assignment-removal):
      if n[1].kind == nkSym and n[0].kind == nkSym and n[0].sym == n[1].sym:
        result = newNodeI(nkEmpty, n.info)
      else:
        if n[0].kind in {nkDotExpr, nkCheckedFieldExpr}:
          cycleCheck(n, c)
        assert n[1].kind notin {nkAsgn, nkFastAsgn}
        result = st(n[0], nil, c, s)
        result = st(n[1], result, c, s)
    elif isDiscriminantField(n[0]):
      result = genDiscriminantAsgn(c, s, n)
    else:
      result = shallowCopy(n)
      for i in 0 ..< n.len:
        result[i] = st(n[i], nil, c, s)

  of nkCallKinds:
    let inSpawn = c.inSpawn
    if n[0].kind == nkSym and n[0].sym.magic == mSpawn:
      c.inSpawn.inc
    elif c.inSpawn > 0:
      c.inSpawn.dec

    let parameters = n[0].typ
    let L = if parameters != nil: parameters.len else: 0

    result = shallowCopy(n)
    for i in 1..<n.len:
      let argflags =
        if i < L and (isSinkTypeForParam(parameters[i]) or inSpawn > 0):
          {willBeConsumedAnyway}
        else:
          {}
      result[i] = st(n[i], nil, c, s, argflags)

    if canRaise(n[0]): s.needsTry = true
    if hasDestructor(n.typ):
      if willBeConsumedAnyway in flags:
        discard "construction passed to a sink parameter: nothing to do"
      else:
        result = ensureDestruction(result, c, s)

  of nkVarSection, nkLetSection:
    # we destroy every 'v' at scope exit. So we know that 'v = value' is the first
    # write to 'v' no matter what. We can always transform it into bitcopy(v, value).
    result = newNodeI(nkStmtList, n.info)
    for it in n:
      var ri = it[^1]
      if it.kind == nkVarTuple and hasDestructor(ri.typ):
        let x = lowerTupleUnpacking(c.graph, it, c.owner)
        result.add st(x, nil, c, s)
      else:
        for j in 0..<it.len-2:
          var varSection = copyNode(n)
          var identDefs = copyNode(it)

          let v = it[j]
          if v.kind == nkSym and sfCompileTime notin v.sym.flags and
              hasDestructor(v.typ) and not isCursor(it[j]):
            s.final.add genDestroy(c, v)
          identDefs.add it[j]
          identDefs.add it[it.len-2] # type

          let initExpr = st(it[^1], c, s)
          identDefs.add initExpr
          varSection.add identDefs
          result.add varSection

  of nkRaiseStmt:
    if optOwnedRefs in c.graph.config.globalOptions and n[0].kind != nkEmpty:
      if n[0].kind in nkCallKinds:
        let call = st(n[0], c, s, {})
        result = copyNode(n)
        result.add call
      else:
        let tmp = getTemp(c, s, n[0].typ, n.info)
        var m = genCopyNoCheck(c, tmp, n[0])
        m.add st(n[0], c, s, {})
        result = newTree(nkStmtList, genWasMoved(tmp, c), m)
        var toDisarm = n[0]
        if toDisarm.kind == nkStmtListExpr: toDisarm = toDisarm.lastSon
        if toDisarm.kind == nkSym and toDisarm.sym.owner == c.owner:
          result.add genWasMoved(toDisarm, c)
        result.add newTree(nkRaiseStmt, tmp)
    else:
      result = copyNode(n)
      if n[0].kind != nkEmpty:
        result.add st(n[0], c, s, {willBeConsumedAnyway})
      else:
        result.add copyNode(n[0])
    s.needsTry = true
  else:
    internalError(c.graph.config, n.info, "cannot inject destructors to node kind: " & $n.kind)

proc injectDestructorCalls*(g: ModuleGraph; owner: PSym; n: PNode): PNode =
  if sfGeneratedOp in owner.flags or (owner.kind == skIterator and isInlineIterator(owner.typ)):
    return n
  var c: Con
  c.owner = owner
  c.graph = g
  let cfg = constructCfg(owner, n)
  shallowCopy(c.g, cfg)
  c.jumpTargets = initIntSet()
  for i in 0..<c.g.len:
    if c.g[i].kind in {goto, fork}:
      c.jumpTargets.incl(i+c.g[i].dest)
  dbg:
    echo "\n### ", owner.name.s, ":\nCFG:"
    echoCfg(c.g)
    echo n

  var scope: Scope
  let res = st(n, nil, c, scope)

  if owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter}:
    let params = owner.typ.n
    for i in 1..<params.len:
      let t = params[i].sym.typ
      if isSinkTypeForParam(t) and hasDestructor(t.skipTypes({tySink})):
        scope.final.add genDestroy(c, params[i])

  result = toTree(scope, res)
  if result == nil:
    # there was nothing to transform:
    result = n
  dbg:
    echo ">---------transformed-to--------->"
    echo renderTree(result, {renderIds})
