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
    wasMoved: seq[PNode]
    final: seq[PNode] # finally section
    needsTry: bool

  SinkFlag = enum
    isDefinition,
    sinkArg
  SinkFlags = set[SinkFlag]

proc rememberParent(parent: var Scope; inner: Scope) {.inline.} =
  parent.needsTry = parent.needsTry or inner.needsTry

proc optimize(s: var Scope) =
  # optimize away simple 'wasMoved(x); destroy(x)' pairs.
  #[ Unfortunately this optimization is only really safe when no exceptions
     are possible, see for example:

  proc main(inp: string; cond: bool) =
    if cond:
      try:
        var s = ["hi", inp & "more"]
        for i in 0..4:
          echo s
        consume(s)
        wasMoved(s)
      finally:
        destroy(x)

    Now assume 'echo' raises, then we shouldn't do the 'wasMoved(s)'
  ]#
  # XXX: Investigate how to really insert 'wasMoved()' calls!
  proc findCorrespondingDestroy(final: seq[PNode]; moved: PNode): int =
    # remember that it's destroy(addr(x))
    for i in 0 ..< final.len:
      if final[i] != nil and exprStructuralEquivalent(final[i][1].skipAddr, moved):
        return i
    return -1

  var removed = 0
  for i in 0 ..< s.wasMoved.len:
    let j = findCorrespondingDestroy(s.final, s.wasMoved[i][1])
    if j >= 0:
      s.wasMoved[i] = nil
      s.final[j] = nil
      inc removed
  if removed > 0:
    template filterNil(field) =
      var m = newSeq[PNode](s.field.len - removed)
      var mi = 0
      for i in 0 ..< s.field.len:
        if s.field[i] != nil:
          m[mi] = s.field[i]
          inc mi
      assert mi == m.len
      s.field = m

    filterNil(wasMoved)
    filterNil(final)

proc toTree(s: var Scope; ret: PNode): PNode =
  if not s.needsTry: optimize(s)
  assert ret != nil
  if s.temps.len == 0 and s.final.len == 0 and s.wasMoved.len == 0:
    # trivial, nothing was done:
    result = ret
  else:
    if isEmptyType(ret.typ):
      result = newNodeI(nkStmtList, ret.info)
    else:
      result = newNodeIT(nkStmtListExpr, ret.info, ret.typ)

    if s.temps.len > 0:
      let varSection = newNodeI(nkVarSection, ret.info)
      for tmp in s.temps:
        varSection.add newTree(nkIdentDefs, newSymNode(tmp), newNodeI(nkEmpty, ret.info),
                                                              newNodeI(nkEmpty, ret.info))
      result.add varSection
    if s.needsTry:
      # XXX wasMoved calls should be outside the 'finally' section!
      var finSection = newNodeI(nkStmtList, ret.info)
      for m in s.wasMoved: finSection.add m
      for f in s.final: finSection.add f
      result.add newTryFinally(ret, finSection)
    else:
      result.add ret
      for m in s.wasMoved: result.add m
      for f in s.final: result.add f

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

proc genUnaryOp(c: Con; op: PSym; dest: PNode): PNode =
  let addrExp = newNodeIT(nkHiddenAddr, dest.info, makePtrType(c, dest.typ))
  addrExp.add(dest)
  result = newTree(nkCall, newSymNode(op), addrExp)

proc genOp(c: Con; t: PType; kind: TTypeAttachedOp; dest, src: PNode): PNode =
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
  if sfError in op.flags: checkForErrorPragma(c, t, src, AttachedOpToStr[kind])
  result = genUnaryOp(c, op, dest)
  if src != nil:
    result.add src

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
  let tmp = getTemp(c, s, n[1].typ, n.info)

  result = newTree(nkStmtList)
  result.add newTree(nkFastAsgn, tmp, st(n[1], c, s, {sinkArg}))

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
      result.add newTree(nkIfStmt, newTree(nkElifBranch, notExpr, genUnaryOp(c, branchDestructor, le)))
  result.add newTree(nkFastAsgn, le, tmp)

template isUnpackedTuple(n: PNode): bool =
  ## we move out all elements of unpacked tuples,
  ## hence unpacked tuples themselves don't need to be destroyed
  (n.kind == nkSym and n.sym.kind == skTemp and n.sym.typ.kind == tyTuple)

proc genSink(c: var Con; dest, src: PNode, flags: SinkFlags): PNode =
  if isUnpackedTuple(dest) or isDefinition in flags or
      (isAnalysableFieldAccess(dest, c.owner) and isFirstWrite(dest, c)) or
      isNoInit(dest):
    # optimize sink call into a bitwise memcopy
    result = newTree(nkFastAsgn, dest, src)
  else:
    let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
    if t.attachedOps[attachedSink] != nil:
      result = genOp(c, t, attachedSink, dest, src)
    else:
      # the default is to use combination of `=destroy(dest)` and
      # and copyMem(dest, source). This is efficient.
      let snk = newTree(nkFastAsgn, dest, src)
      result = newTree(nkStmtList, genDestroy(c, dest), snk)

proc genCopyNoCheck(c: Con; dest, src: PNode): PNode =
  let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedAsgn, dest, src)

proc genCopy(c: var Con; dest, src: PNode): PNode =
  let t = dest.typ
  if tfHasOwned in t.flags and src.kind != nkNilLit:
    # try to improve the error message here:
    if c.otherRead == nil: discard isLastRead(src, c)
    checkForErrorPragma(c, t, src, "=")
  result = genCopyNoCheck(c, dest, src)

proc genWasMoved(n: PNode; c: var Con): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newSymNode(createMagic(c.graph, "wasMoved", mWasMoved)))
  result.add copyTree(n) # mWasMoved does not take the address
  #if n.kind != nkSym:
  #  message(c.graph.config, n.info, warnUser, "wasMoved(" & $n & ")")

proc isCapturedVar(n: PNode): bool =
  let root = getRoot(n)
  if root != nil: result = root.name.s[0] == ':'

proc passCopyToSink(n: PNode; c: var Con; s: var Scope): PNode =
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  let tmp = getTemp(c, s, n.typ, n.info)
  if hasDestructor(n.typ):
    result.add genWasMoved(tmp, c)
    result.add genCopy(c, tmp, n)
    if isLValue(n) and not isCapturedVar(n) and n.typ.skipTypes(abstractInst).kind != tyRef and c.inSpawn == 0:
      message(c.graph.config, n.info, hintPerformance,
        ("passing '$1' to a sink parameter introduces an implicit copy; " &
        "if possible, rearrange your program's control flow to prevent it") % $n)
  else:
    if c.graph.config.selectedGC in {gcArc, gcOrc}:
      assert(not containsGarbageCollectedRef(n.typ))
    result.add newTree(nkFastAsgn, tmp, n)
  # Since we know somebody will take over the produced copy, there is
  # no need to destroy it.
  result.add tmp

proc isDangerousSeq(t: PType): bool {.inline.} =
  let t = t.skipTypes(abstractInst)
  result = t.kind == tySequence and tfHasOwned notin t[0].flags

proc containsConstSeq(n: PNode): bool =
  if n.kind == nkBracket and n.len > 0 and n.typ != nil and isDangerousSeq(n.typ):
    return true
  result = false
  case n.kind
  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv:
    result = containsConstSeq(n[1])
  of nkObjConstr, nkClosure:
    for i in 1..<n.len:
      if containsConstSeq(n[i]): return true
  of nkCurly, nkBracket, nkPar, nkTupleConstr:
    for son in n:
      if containsConstSeq(son): return true
  else: discard

proc genMoveOrCopy(dest, src: PNode; c: var Con, s: var Scope; flags: SinkFlags): PNode =
  case src.kind
  of nkCallKinds:
    result = genSink(c, dest, src, flags)
  of nkBracketExpr:
    if isUnpackedTuple(src[0]):
      # unpacking of tuple: take over the elements
      result = genSink(c, dest, src, flags)
    elif isAnalysableFieldAccess(src, c.owner) and isLastRead(src, c) and
        not aliases(dest, src):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      let snk = genSink(c, dest, src, flags)
      result = newTree(nkStmtList, snk, genWasMoved(src, c))
    else:
      result = genCopy(c, dest, src)
  of nkBracket:
    # array constructor
    if src.len > 0 and isDangerousSeq(src.typ):
      result = genCopy(c, dest, src)
    else:
      result = genSink(c, dest, src, flags)
  of nkObjConstr, nkTupleConstr, nkClosure, nkCharLit..nkNilLit:
    result = genSink(c, dest, src, flags)
  of nkSym:
    if isSinkParam(src.sym) and isLastRead(src, c):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      let snk = genSink(c, dest, src, flags)
      result = newTree(nkStmtList, snk, genWasMoved(src, c))
    elif src.sym.kind != skParam and src.sym.owner == c.owner and
        isLastRead(src, c) and canBeMoved(c, dest.typ):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      let snk = genSink(c, dest, src, flags)
      result = newTree(nkStmtList, snk, genWasMoved(src, c))
    else:
      result = genCopy(c, dest, src)
  of nkHiddenSubConv, nkHiddenStdConv, nkConv, nkObjDownConv, nkObjUpConv:
    result = genSink(c, dest, src, flags)
  of nkStmtListExpr, nkBlockExpr, nkIfExpr, nkCaseStmt:
    result = genSink(c, dest, src, flags)
  else:
    if isAnalysableFieldAccess(src, c.owner) and isLastRead(src, c) and
        canBeMoved(c, dest.typ):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      result = genSink(c, dest, src, flags)
      s.wasMoved.add genWasMoved(src, c)
    else:
      result = genCopy(c, dest, src)

proc genDefaultCall(t: PType; c: Con; info: TLineInfo): PNode =
  result = newNodeI(nkCall, info)
  result.add(newSymNode(createMagic(c.graph, "default", mDefault)))
  result.typ = t

proc ensureDestruction(arg: PNode; c: var Con; s: var Scope): PNode =
  result = newNodeIT(nkStmtListExpr, arg.info, arg.typ)
  let tmp = getTemp(c, s, arg.typ, arg.info)
  result.add newTree(nkFastAsgn, tmp, arg)
  #result.add genWasMoved(tmp, c)
  #result.add genMoveOrCopy(tmp, arg, c, s, {isDefinition})
  result.add tmp
  s.final.add genDestroy(c, tmp)

proc st(n: PNode; c: var Con; s: var Scope; flags: SinkFlags): PNode =
  # It handles a statement and can create a new scope.
  case n.kind
  of nkSym:
    if sinkArg in flags and hasDestructor(n.typ):
      if isSinkParam(n.sym) and isLastRead(n, c):
        # Rule 3: `=sink`(x, z); wasMoved(z)
        result = n
        s.wasMoved.add genWasMoved(result, c)
      elif n.sym.kind != skParam and n.sym.owner == c.owner and
          isLastRead(n, c) and canBeMoved(c, n.typ):
        result = n
        s.wasMoved.add genWasMoved(result, c)
      else:
        result = passCopyToSink(n, c, s)
    else:
      result = n
  of nkBracketExpr, nkAddr, nkHiddenAddr, nkDerefExpr, nkHiddenDeref:
    result = shallowCopy(n)
    for i in 0 ..< n.len:
      result[i] = st(n[i], c, s, {})
    if sinkArg in flags and hasDestructor(n.typ):
      if isAnalysableFieldAccess(n, c.owner) and isLastRead(n, c):
        # consider 'a[(g; destroy(g); 3)]', we want to say 'wasMoved(a[3])'
        # without the junk, hence 'genWasMoved(n, c)'
        # and not 'genWasMoved(result, c)':
        s.wasMoved.add genWasMoved(n, c)
      else:
        result = passCopyToSink(result, c, s)
  of nkCast:
    # dest = cast[T](x)
    result = shallowCopy(n)
    result[0] = n[0]
    result[1] = st(n[1], c, s, flags)

  of nkStringToCString, nkCStringToString, nkChckRangeF, nkChckRange64, nkChckRange, nkPragmaBlock:
    result = shallowCopy(n)
    for i in 0 ..< n.len:
      result[i] = st(n[i], c, s, {})
    if n.typ != nil and hasDestructor(n.typ):
      if sinkArg in flags:
        discard "created string is taken over"
      else:
        result = ensureDestruction(result, c, s)

  of nkCheckedFieldExpr, nkDotExpr:
    result = shallowCopy(n)
    result[0] = st(n[0], c, s, {})
    for i in 1 ..< n.len:
      result[i] = n[i]
    if sinkArg in flags and hasDestructor(n.typ):
      if isAnalysableFieldAccess(n, c.owner) and isLastRead(n, c):
        s.wasMoved.add genWasMoved(n, c)
      else:
        result = passCopyToSink(result, c, s)

  of nkHiddenSubConv, nkHiddenStdConv, nkConv:
    # we have an "ownership invariance" for all constructors C(x).
    # See the comment for nkBracket construction. If the caller wants
    # to own 'C(x)', it really wants to own 'x' too. If it doesn't,
    # we need to destroy 'x' but the function call handling ensures that
    # already.
    result = copyTree(n)
    if n.typ.skipTypes(abstractInst-{tyOwned}).kind != tyOwned and
        n[1].typ.skipTypes(abstractInst-{tyOwned}).kind == tyOwned:
      # allow conversions from owned to unowned via this little hack:
      let nTyp = n[1].typ
      n[1].typ = n.typ
      result[1] = st(n[1], c, s, flags)
      result[1].typ = nTyp
    else:
      result[1] = st(n[1], c, s, flags)

  of nkObjDownConv, nkObjUpConv:
    result = copyTree(n)
    result[0] = st(n[0], c, s, flags)

  of nkCaseStmt:
    result = copyNode(n)
    result.add st(n[0], c, s, {})
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
      rememberParent(s, ofScope)

  of nkWhileStmt:
    result = copyNode(n)
    result.add st(n[0], c, s, {})
    var bodyScope: Scope
    let bodyResult = st(n[1], c, bodyScope, {})
    result.add toTree(bodyScope, bodyResult)
    rememberParent(s, bodyScope)

  of nkBlockStmt, nkBlockExpr:
    result = copyNode(n)
    result.add n[0]
    var bodyScope: Scope
    let bodyResult = st(n[1], c, bodyScope, flags)
    result.add toTree(bodyScope, bodyResult)
    rememberParent(s, bodyScope)

  of nkIfStmt, nkIfExpr:
    result = copyNode(n)
    for i in 0..<n.len:
      let it = n[i]
      var branch = shallowCopy(it)
      var branchScope: Scope
      if it.kind in {nkElifBranch, nkElifExpr}:
        branch[0] = st(it[0], c, branchScope, {})

      var branchResult = st(it[^1], c, branchScope, flags)
      branch[^1] = toTree(branchScope, branchResult)
      result.add branch
      rememberParent(s, branchScope)

  of nkTryStmt:
    result = copyNode(n)
    var tryScope: Scope
    var tryResult = st(n[0], c, tryScope, flags)
    result.add toTree(tryScope, tryResult)
    rememberParent(s, tryScope)

    for i in 1..<n.len:
      let it = n[i]
      var branch = copyTree(it)
      var branchScope: Scope
      var branchResult = st(it[^1], c, branchScope, if it.kind == nkFinally: {} else: flags)
      branch[^1] = toTree(branchScope, branchResult)
      result.add branch
      rememberParent(s, branchScope)

  of nkDefer, nkRange:
    result = shallowCopy(n)
    for i in 0 ..< n.len:
      result[i] = st(n[i], c, s, {})

  of nkWhen:
    # This should be a "when nimvm" node.
    result = copyTree(n)
    result[1][0] = st(n[1][0], c, s, flags)
  of nkStmtList, nkStmtListExpr:
    result = shallowCopy(n)
    for i in 0 ..< n.len:
      let f = if i == n.len-1 and not isEmptyType(n.typ): flags else: {}
      result[i] = st(n[i], c, s, f)

  of nkDiscardStmt:
    result = shallowCopy(n)
    if n[0].kind != nkEmpty:
      result[0] = st(n[0], c, s, {})
    else:
      result[0] = copyNode(n[0])

  of nkNone..pred(nkSym), succ(nkSym)..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
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
        let dest = st(n[0], c, s, {})
        let src = st(n[1], c, s, {sinkArg})
        result = genMoveOrCopy(dest, src, c, s, {})
    elif isDiscriminantField(n[0]):
      result = genDiscriminantAsgn(c, s, n)
    else:
      result = shallowCopy(n)
      for i in 0 ..< n.len:
        result[i] = st(n[i], c, s, {})

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
      if i < L and isCompileTimeOnly(parameters[i]):
        result[i] = n[i]
      else:
        let argflags =
          if i < L and (isSinkTypeForParam(parameters[i]) or inSpawn > 0):
            {sinkArg}
          else:
            {}
        result[i] = st(n[i], c, s, argflags)

    if n[0].kind == nkSym and n[0].sym.magic in {mNew, mNewFinalize}:
      result[0] = copyTree(n[0])
      if c.graph.config.selectedGC in {gcHooks, gcArc, gcOrc}:
        let destroyOld = genDestroy(c, result[1])
        result = newTree(nkStmtList, destroyOld, result)
    else:
      result[0] = st(n[0], c, s, {})

    if canRaise(n[0]): s.needsTry = true
    if n.typ != nil and hasDestructor(n.typ):
      if sinkArg in flags:
        discard "construction passed to a sink parameter: nothing to do"
      else:
        result = ensureDestruction(result, c, s)

  of nkBracket, nkObjConstr, nkTupleConstr, nkClosure, nkCurly:
    # Let C(x) be the construction, 'x' the vector of arguments.
    # C(x) either owns 'x' or it doesn't.
    # If C(x) owns its data, we must consume C(x).
    # If it doesn't own the data, it's harmful to destroy it (double frees etc).
    # We have the freedom to choose whether it owns it or not so we are smart about it
    # and we say, "if passed to a sink we demand C(x) to own its data"
    # otherwise we say "C(x) is just some temporary storage, it doesn't own anything,
    # don't destroy it"
    # but if C(x) is a ref it MUST own its data since we must destroy it
    # so then we have no choice but to use 'sinkArg'.
    let isRefConstr = n.kind == nkObjConstr and n.typ.skipTypes(abstractInst).kind == tyRef
    let argflags = if isRefConstr: {sinkArg}
                   else: flags

    result = copyTree(n)
    for i in ord(n.kind in {nkObjConstr, nkClosure})..<n.len:
      if n[i].kind == nkExprColonExpr:
        result[i][1] = st(n[i][1], c, s, argflags)
      else:
        result[i] = st(n[i], c, s, argflags)

    if sinkArg in flags:
      if containsConstSeq(result):
        # const sequences are not mutable and so we need to pass a copy to the
        # sink parameter (bug #11524). Note that the string implementation is
        # different and can deal with 'const string sunk into var'.
        result = passCopyToSink(result, c, s)
    elif n.typ != nil and hasDestructor(n.typ) and isRefConstr:
      result = ensureDestruction(result, c, s)

  of nkVarSection, nkLetSection:
    # we destroy every 'v' at scope exit. So we know that 'v = value' is the first
    # write to 'v' no matter what. We can always transform it into bitcopy(v, value).
    result = newNodeI(nkStmtList, n.info)
    for it in n:
      var ri = it[^1]
      if it.kind == nkVarTuple and hasDestructor(ri.typ):
        let x = lowerTupleUnpacking(c.graph, it, c.owner)
        result.add st(x, c, s, {})
      else:
        for j in 0..<it.len-2:
          var varSection = copyNode(n)
          var identDefs = copyNode(it)

          let v = it[j]
          if v.kind == nkSym and {sfCompileTime, sfGlobal, sfThread} * v.sym.flags == {} and
              hasDestructor(v.typ) and not isCursor(it[j]):
            s.final.add genDestroy(c, v)
          identDefs.add it[j]
          identDefs.add it[it.len-2] # type

          let initExpr = st(it[^1], c, s, {sinkArg, isDefinition})
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
        result.add st(n[0], c, s, {sinkArg})
      else:
        result.add copyNode(n[0])
    s.needsTry = true
  of nkGotoState, nkState:
    result = n
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
  let res = st(n, c, scope, {})

  if owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter}:
    let params = owner.typ.n
    for i in 1..<params.len:
      let t = params[i].sym.typ
      if isSinkTypeForParam(t) and hasDestructor(t.skipTypes({tySink})):
        scope.final.add genDestroy(c, params[i])

  result = toTree(scope, res)
  dbg:
    echo ">---------transformed-to--------->"
    echo renderTree(result, {renderIds})
