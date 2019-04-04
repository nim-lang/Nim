#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the transformator. It transforms the syntax tree
# to ease the work of the code generators. Does some transformations:
#
# * inlines iterators
# * inlines constants
# * performs constant folding
# * converts "continue" to "break"; disambiguates "break"
# * introduces method dispatchers
# * performs lambda lifting for closure support
# * transforms 'defer' into a 'try finally' statement

import
  intsets, strutils, options, ast, astalgo, trees, treetab, msgs, lookups,
  idents, renderer, types, passes, semfold, magicsys, cgmeth,
  sempass2, lowerings, injectdestructors, liftlocals,
  modulegraphs, lineinfos

proc transformBody*(g: ModuleGraph, prc: PSym, cache = true;
                    noDestructors = false): PNode

import closureiters, lambdalifting

type
  PTransNode* = distinct PNode

  PTransCon = ref TTransCon
  TTransCon{.final.} = object # part of TContext; stackable
    mapping: TIdNodeTable     # mapping from symbols to nodes
    owner: PSym               # current owner
    forStmt: PNode            # current for stmt
    forLoopBody: PTransNode   # transformed for loop body
    yieldStmts: int           # we count the number of yield statements,
                              # because we need to introduce new variables
                              # if we encounter the 2nd yield statement
    next: PTransCon           # for stacking

  TTransfContext = object of TPassContext
    module: PSym
    transCon: PTransCon      # top of a TransCon stack
    inlining: int            # > 0 if we are in inlining context (copy vars)
    nestedProcs: int         # > 0 if we are in a nested proc
    contSyms, breakSyms: seq[PSym]  # to transform 'continue' and 'break'
    deferDetected, tooEarly, needsDestroyPass, noDestructors: bool
    graph: ModuleGraph
  PTransf = ref TTransfContext

proc newTransNode(a: PNode): PTransNode {.inline.} =
  result = PTransNode(shallowCopy(a))

proc newTransNode(kind: TNodeKind, info: TLineInfo,
                  sons: int): PTransNode {.inline.} =
  var x = newNodeI(kind, info)
  newSeq(x.sons, sons)
  result = x.PTransNode

proc newTransNode(kind: TNodeKind, n: PNode,
                  sons: int): PTransNode {.inline.} =
  var x = newNodeIT(kind, n.info, n.typ)
  newSeq(x.sons, sons)
  x.typ = n.typ
#  x.flags = n.flags
  result = x.PTransNode

proc add(a, b: PTransNode) {.inline.} = addSon(PNode(a), PNode(b))
proc len(a: PTransNode): int {.inline.} = sonsLen(a.PNode)

proc `[]=`(a: PTransNode, i: int, x: PTransNode) {.inline.} =
  var n = PNode(a)
  n.sons[i] = PNode(x)

proc `[]=`(a: PTransNode, i: BackwardsIndex, x: PTransNode) {.inline.} =
  `[]=`(a, a.len - i.int, x)

proc `[]`(a: PTransNode, i: int): PTransNode {.inline.} =
  var n = PNode(a)
  result = n.sons[i].PTransNode

proc `[]`(a: PTransNode, i: BackwardsIndex): PTransNode {.inline.} =
  `[]`(a, a.len - i.int)

proc newTransCon(owner: PSym): PTransCon =
  assert owner != nil
  new(result)
  initIdNodeTable(result.mapping)
  result.owner = owner

proc pushTransCon(c: PTransf, t: PTransCon) =
  t.next = c.transCon
  c.transCon = t

proc popTransCon(c: PTransf) =
  if (c.transCon == nil): internalError(c.graph.config, "popTransCon")
  c.transCon = c.transCon.next

proc getCurrOwner(c: PTransf): PSym =
  if c.transCon != nil: result = c.transCon.owner
  else: result = c.module

proc newTemp(c: PTransf, typ: PType, info: TLineInfo): PNode =
  let r = newSym(skTemp, getIdent(c.graph.cache, genPrefix), getCurrOwner(c), info)
  r.typ = typ #skipTypes(typ, {tyGenericInst, tyAlias, tySink})
  incl(r.flags, sfFromGeneric)
  let owner = getCurrOwner(c)
  if owner.isIterator and not c.tooEarly:
    result = freshVarForClosureIter(c.graph, r, owner)
  else:
    result = newSymNode(r)

proc transform(c: PTransf, n: PNode): PTransNode

proc transformSons(c: PTransf, n: PNode): PTransNode =
  result = newTransNode(n)
  for i in countup(0, sonsLen(n)-1):
    result[i] = transform(c, n.sons[i])

proc newAsgnStmt(c: PTransf, kind: TNodeKind, le: PNode, ri: PTransNode): PTransNode =
  result = newTransNode(kind, PNode(ri).info, 2)
  result[0] = PTransNode(le)
  result[1] = ri

proc transformSymAux(c: PTransf, n: PNode): PNode =
  let s = n.sym
  if s.typ != nil and s.typ.callConv == ccClosure:
    if s.kind in routineKinds:
      discard transformBody(c.graph, s, true, c.noDestructors)
    if s.kind == skIterator:
      if c.tooEarly: return n
      else: return liftIterSym(c.graph, n, getCurrOwner(c))
    elif s.kind in {skProc, skFunc, skConverter, skMethod} and not c.tooEarly:
      # top level .closure procs are still somewhat supported for 'Nake':
      return makeClosure(c.graph, s, nil, n.info)
  #elif n.sym.kind in {skVar, skLet} and n.sym.typ.callConv == ccClosure:
  #  echo n.info, " come heer for ", c.tooEarly
  #  if not c.tooEarly:
  var b: PNode
  var tc = c.transCon
  if sfBorrow in s.flags and s.kind in routineKinds:
    # simply exchange the symbol:
    b = s.getBody
    if b.kind != nkSym: internalError(c.graph.config, n.info, "wrong AST for borrowed symbol")
    b = newSymNode(b.sym, n.info)
  else:
    b = n
  while tc != nil:
    result = idNodeTableGet(tc.mapping, b.sym)
    if result != nil:
      # this slightly convoluted way ensures the line info stays correct:
      if result.kind == nkSym:
        result = copyNode(result)
        result.info = n.info
      return
    tc = tc.next
  result = b

proc transformSym(c: PTransf, n: PNode): PTransNode =
  result = PTransNode(transformSymAux(c, n))

proc freshVar(c: PTransf; v: PSym): PNode =
  let owner = getCurrOwner(c)
  if owner.isIterator and not c.tooEarly:
    result = freshVarForClosureIter(c.graph, v, owner)
  else:
    var newVar = copySym(v)
    incl(newVar.flags, sfFromGeneric)
    newVar.owner = owner
    result = newSymNode(newVar)

proc transformVarSection(c: PTransf, v: PNode): PTransNode =
  result = newTransNode(v)
  for i in countup(0, sonsLen(v)-1):
    var it = v.sons[i]
    if it.kind == nkCommentStmt:
      result[i] = PTransNode(it)
    elif it.kind == nkIdentDefs:
      if it.sons[0].kind == nkSym:
        internalAssert(c.graph.config, it.len == 3)
        let x = freshVar(c, it.sons[0].sym)
        idNodeTablePut(c.transCon.mapping, it.sons[0].sym, x)
        var defs = newTransNode(nkIdentDefs, it.info, 3)
        if importantComments(c.graph.config):
          # keep documentation information:
          PNode(defs).comment = it.comment
        defs[0] = x.PTransNode
        defs[1] = it.sons[1].PTransNode
        defs[2] = transform(c, it.sons[2])
        if x.kind == nkSym: x.sym.ast = defs[2].PNode
        result[i] = defs
      else:
        # has been transformed into 'param.x' for closure iterators, so just
        # transform it:
        result[i] = transform(c, it)
    else:
      if it.kind != nkVarTuple:
        internalError(c.graph.config, it.info, "transformVarSection: not nkVarTuple")
      var L = sonsLen(it)
      var defs = newTransNode(it.kind, it.info, L)
      for j in countup(0, L-3):
        if it[j].kind == nkSym:
          let x = freshVar(c, it.sons[j].sym)
          idNodeTablePut(c.transCon.mapping, it.sons[j].sym, x)
          defs[j] = x.PTransNode
        else:
          defs[j] = transform(c, it[j])
      assert(it.sons[L-2].kind == nkEmpty)
      defs[L-2] = newNodeI(nkEmpty, it.info).PTransNode
      defs[L-1] = transform(c, it.sons[L-1])
      result[i] = defs

proc transformConstSection(c: PTransf, v: PNode): PTransNode =
  result = PTransNode(v)
  when false:
    result = newTransNode(v)
    for i in countup(0, sonsLen(v)-1):
      var it = v.sons[i]
      if it.kind == nkCommentStmt:
        result[i] = PTransNode(it)
      else:
        if it.kind != nkConstDef: internalError(c.graph.config, it.info, "transformConstSection")
        if it.sons[0].kind != nkSym:
          debug it.sons[0]
          internalError(c.graph.config, it.info, "transformConstSection")

        result[i] = PTransNode(it)

proc hasContinue(n: PNode): bool =
  case n.kind
  of nkEmpty..nkNilLit, nkForStmt, nkParForStmt, nkWhileStmt: discard
  of nkContinueStmt: result = true
  else:
    for i in countup(0, sonsLen(n) - 1):
      if hasContinue(n.sons[i]): return true

proc newLabel(c: PTransf, n: PNode): PSym =
  result = newSym(skLabel, nil, getCurrOwner(c), n.info)
  result.name = getIdent(c.graph.cache, genPrefix & $result.id)

proc transformBlock(c: PTransf, n: PNode): PTransNode =
  var labl: PSym
  if c.inlining > 0:
    labl = newLabel(c, n[0])
    idNodeTablePut(c.transCon.mapping, n[0].sym, newSymNode(labl))
  else:
    labl =
      if n.sons[0].kind != nkEmpty:
        n.sons[0].sym  # already named block? -> Push symbol on the stack
      else:
        newLabel(c, n)
  c.breakSyms.add(labl)
  result = transformSons(c, n)
  discard c.breakSyms.pop
  result[0] = newSymNode(labl).PTransNode

proc transformLoopBody(c: PTransf, n: PNode): PTransNode =
  # What if it contains "continue" and "break"? "break" needs
  # an explicit label too, but not the same!

  # We fix this here by making every 'break' belong to its enclosing loop
  # and changing all breaks that belong to a 'block' by annotating it with
  # a label (if it hasn't one already).
  if hasContinue(n):
    let labl = newLabel(c, n)
    c.contSyms.add(labl)

    result = newTransNode(nkBlockStmt, n.info, 2)
    result[0] = newSymNode(labl).PTransNode
    result[1] = transform(c, n)
    discard c.contSyms.pop()
  else:
    result = transform(c, n)

proc transformWhile(c: PTransf; n: PNode): PTransNode =
  if c.inlining > 0:
    result = transformSons(c, n)
  else:
    let labl = newLabel(c, n)
    c.breakSyms.add(labl)
    result = newTransNode(nkBlockStmt, n.info, 2)
    result[0] = newSymNode(labl).PTransNode

    var body = newTransNode(n)
    for i in 0..n.len-2:
      body[i] = transform(c, n.sons[i])
    body[n.len-1] = transformLoopBody(c, n.sons[n.len-1])
    result[1] = body
    discard c.breakSyms.pop

proc transformBreak(c: PTransf, n: PNode): PTransNode =
  result = transformSons(c, n)
  if n.sons[0].kind == nkEmpty and c.breakSyms.len > 0:
    let labl = c.breakSyms[c.breakSyms.high]
    result[0] = newSymNode(labl).PTransNode

proc introduceNewLocalVars(c: PTransf, n: PNode): PTransNode =
  case n.kind
  of nkSym:
    result = transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    # nothing to be done for leaves:
    result = PTransNode(n)
  of nkVarSection, nkLetSection:
    result = transformVarSection(c, n)
  of nkClosure:
    # it can happen that for-loop-inlining produced a fresh
    # set of variables, including some computed environment
    # (bug #2604). We need to patch this environment here too:
    let a = n[1]
    if a.kind == nkSym:
      n.sons[1] = transformSymAux(c, a)
    return PTransNode(n)
  else:
    result = newTransNode(n)
    for i in countup(0, sonsLen(n)-1):
      result[i] = introduceNewLocalVars(c, n.sons[i])

proc transformAsgn(c: PTransf, n: PNode): PTransNode =
  let rhs = n[1]

  if rhs.kind != nkTupleConstr:
    return transformSons(c, n)

  # Unpack the tuple assignment into N temporary variables and then pack them
  # into a tuple: this allows us to get the correct results even when the rhs
  # depends on the value of the lhs
  let letSection = newTransNode(nkLetSection, n.info, rhs.len)
  let newTupleConstr = newTransNode(nkTupleConstr, n.info, rhs.len)
  for i, field in rhs:
    let val = if field.kind == nkExprColonExpr: field[1] else: field
    let def = newTransNode(nkIdentDefs, field.info, 3)
    def[0] = PTransNode(newTemp(c, val.typ, field.info))
    def[1] = PTransNode(newNodeI(nkEmpty, field.info))
    def[2] = transform(c, val)
    letSection[i] = def
    # NOTE: We assume the constructor fields are in the correct order for the
    # given tuple type
    newTupleConstr[i] = def[0]

  PNode(newTupleConstr).typ = rhs.typ

  let asgnNode = newTransNode(nkAsgn, n.info, 2)
  asgnNode[0] = transform(c, n[0])
  asgnNode[1] = newTupleConstr

  result = newTransNode(nkStmtList, n.info, 2)
  result[0] = letSection
  result[1] = asgnNode

proc transformYield(c: PTransf, n: PNode): PTransNode =
  proc asgnTo(lhs: PNode, rhs: PTransNode): PTransNode =
    # Choose the right assignment instruction according to the given ``lhs``
    # node since it may not be a nkSym (a stack-allocated skForVar) but a
    # nkDotExpr (a heap-allocated slot into the envP block)
    case lhs.kind:
    of nkSym:
      internalAssert c.graph.config, lhs.sym.kind == skForVar
      result = newAsgnStmt(c, nkFastAsgn, lhs, rhs)
    of nkDotExpr:
      result = newAsgnStmt(c, nkAsgn, lhs, rhs)
    else:
      internalAssert c.graph.config, false
  result = newTransNode(nkStmtList, n.info, 0)
  var e = n.sons[0]
  # c.transCon.forStmt.len == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if e.typ.isNil: return result # can happen in nimsuggest for unknown reasons
  if skipTypes(e.typ, {tyGenericInst, tyAlias, tySink}).kind == tyTuple and
      c.transCon.forStmt.len != 3:
    e = skipConv(e)
    if e.kind in {nkPar, nkTupleConstr}:
      for i in countup(0, sonsLen(e) - 1):
        var v = e.sons[i]
        if v.kind == nkExprColonExpr: v = v.sons[1]
        if c.transCon.forStmt[i].kind == nkVarTuple:
          for j in 0 ..< sonsLen(c.transCon.forStmt[i])-1:
            let lhs = c.transCon.forStmt[i][j]
            let rhs = transform(c, newTupleAccess(c.graph, v, j))
            add(result, asgnTo(lhs, rhs))
        else:
          let lhs = c.transCon.forStmt.sons[i]
          let rhs = transform(c, v)
          add(result, asgnTo(lhs, rhs))
    else:
      # Unpack the tuple into the loop variables
      # XXX: BUG: what if `n` is an expression with side-effects?
      for i in countup(0, sonsLen(c.transCon.forStmt) - 3):
        let lhs = c.transCon.forStmt.sons[i]
        let rhs = transform(c, newTupleAccess(c.graph, e, i))
        add(result, asgnTo(lhs, rhs))
  else:
    if c.transCon.forStmt.sons[0].kind == nkVarTuple:
      for i in 0 ..< sonsLen(c.transCon.forStmt[0])-1:
        let lhs = c.transCon.forStmt[0][i]
        let rhs = transform(c, newTupleAccess(c.graph, e, i))
        add(result, asgnTo(lhs, rhs))
    else:
      let lhs = c.transCon.forStmt.sons[0]
      let rhs = transform(c, e)
      add(result, asgnTo(lhs, rhs))

  inc(c.transCon.yieldStmts)
  if c.transCon.yieldStmts <= 1:
    # common case
    add(result, c.transCon.forLoopBody)
  else:
    # we need to introduce new local variables:
    add(result, introduceNewLocalVars(c, c.transCon.forLoopBody.PNode))
  if result.len > 0:
    var changeNode = PNode(result[0])
    changeNode.info = c.transCon.forStmt.info
    for i, child in changeNode:
      child.info = changeNode.info

proc transformAddrDeref(c: PTransf, n: PNode, a, b: TNodeKind): PTransNode =
  result = transformSons(c, n)
  if c.graph.config.cmd == cmdCompileToCpp or sfCompileToCpp in c.module.flags: return
  var n = result.PNode
  case n.sons[0].kind
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    var m = n.sons[0].sons[0]
    if m.kind == a or m.kind == b:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      n.sons[0].sons[0] = m.sons[0]
      result = PTransNode(n.sons[0])
      if n.typ.skipTypes(abstractVar).kind != tyOpenArray:
        PNode(result).typ = n.typ
      elif n.typ.skipTypes(abstractInst).kind in {tyVar}:
        PNode(result).typ = toVar(PNode(result).typ)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    var m = n.sons[0].sons[1]
    if m.kind == a or m.kind == b:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      n.sons[0].sons[1] = m.sons[0]
      result = PTransNode(n.sons[0])
      if n.typ.skipTypes(abstractVar).kind != tyOpenArray:
        PNode(result).typ = n.typ
      elif n.typ.skipTypes(abstractInst).kind in {tyVar}:
        PNode(result).typ = toVar(PNode(result).typ)
  else:
    if n.sons[0].kind == a or n.sons[0].kind == b:
      # addr ( deref ( x )) --> x
      result = PTransNode(n.sons[0].sons[0])
      if n.typ.skipTypes(abstractVar).kind != tyOpenArray:
        PNode(result).typ = n.typ

proc generateThunk(c: PTransf; prc: PNode, dest: PType): PNode =
  ## Converts 'prc' into '(thunk, nil)' so that it's compatible with
  ## a closure.

  # we cannot generate a proper thunk here for GC-safety reasons
  # (see internal documentation):
  if c.graph.config.cmd == cmdCompileToJS: return prc
  result = newNodeIT(nkClosure, prc.info, dest)
  var conv = newNodeIT(nkHiddenSubConv, prc.info, dest)
  conv.add(newNodeI(nkEmpty, prc.info))
  conv.add(prc)
  if prc.kind == nkClosure:
    internalError(c.graph.config, prc.info, "closure to closure created")
  result.add(conv)
  result.add(newNodeIT(nkNilLit, prc.info, getSysType(c.graph, prc.info, tyNil)))

proc transformConv(c: PTransf, n: PNode): PTransNode =
  # numeric types need range checks:
  var dest = skipTypes(n.typ, abstractVarRange)
  var source = skipTypes(n.sons[1].typ, abstractVarRange)
  case dest.kind
  of tyInt..tyInt64, tyEnum, tyChar, tyBool, tyUInt8..tyUInt32:
    # we don't include uint and uint64 here as these are no ordinal types ;-)
    if not isOrdinalType(source):
      # float -> int conversions. ugh.
      result = transformSons(c, n)
    elif firstOrd(c.graph.config, n.typ) <= firstOrd(c.graph.config, n.sons[1].typ) and
        lastOrd(c.graph.config, n.sons[1].typ) <= lastOrd(c.graph.config, n.typ):
      # BUGFIX: simply leave n as it is; we need a nkConv node,
      # but no range check:
      result = transformSons(c, n)
    else:
      # generate a range check:
      if dest.kind == tyInt64 or source.kind == tyInt64:
        result = newTransNode(nkChckRange64, n, 3)
      else:
        result = newTransNode(nkChckRange, n, 3)
      dest = skipTypes(n.typ, abstractVar)
      result[0] = transform(c, n.sons[1])
      result[1] = newIntTypeNode(nkIntLit, firstOrd(c.graph.config, dest), dest).PTransNode
      result[2] = newIntTypeNode(nkIntLit, lastOrd(c.graph.config, dest), dest).PTransNode
  of tyFloat..tyFloat128:
    # XXX int64 -> float conversion?
    if skipTypes(n.typ, abstractVar).kind == tyRange:
      result = newTransNode(nkChckRangeF, n, 3)
      dest = skipTypes(n.typ, abstractVar)
      result[0] = transform(c, n.sons[1])
      result[1] = copyTree(dest.n.sons[0]).PTransNode
      result[2] = copyTree(dest.n.sons[1]).PTransNode
    else:
      result = transformSons(c, n)
  of tyOpenArray, tyVarargs:
    result = transform(c, n.sons[1])
    PNode(result).typ = takeType(n.typ, n.sons[1].typ)
    #echo n.info, " came here and produced ", typeToString(PNode(result).typ),
    #   " from ", typeToString(n.typ), " and ", typeToString(n.sons[1].typ)
  of tyCString:
    if source.kind == tyString:
      result = newTransNode(nkStringToCString, n, 1)
      result[0] = transform(c, n.sons[1])
    else:
      result = transformSons(c, n)
  of tyString:
    if source.kind == tyCString:
      result = newTransNode(nkCStringToString, n, 1)
      result[0] = transform(c, n.sons[1])
    else:
      result = transformSons(c, n)
  of tyRef, tyPtr:
    dest = skipTypes(dest, abstractPtrs)
    source = skipTypes(source, abstractPtrs)
    if source.kind == tyObject:
      var diff = inheritanceDiff(dest, source)
      if diff < 0:
        result = newTransNode(nkObjUpConv, n, 1)
        result[0] = transform(c, n.sons[1])
      elif diff > 0 and diff != high(int):
        result = newTransNode(nkObjDownConv, n, 1)
        result[0] = transform(c, n.sons[1])
      else:
        result = transform(c, n.sons[1])
    else:
      result = transformSons(c, n)
  of tyObject:
    var diff = inheritanceDiff(dest, source)
    if diff < 0:
      result = newTransNode(nkObjUpConv, n, 1)
      result[0] = transform(c, n.sons[1])
    elif diff > 0 and diff != high(int):
      result = newTransNode(nkObjDownConv, n, 1)
      result[0] = transform(c, n.sons[1])
    else:
      result = transform(c, n.sons[1])
  of tyGenericParam, tyOrdinal:
    result = transform(c, n.sons[1])
    # happens sometimes for generated assignments, etc.
  of tyProc:
    result = transformSons(c, n)
    if dest.callConv == ccClosure and source.callConv == ccDefault:
      result = generateThunk(c, result[1].PNode, dest).PTransNode
  else:
    result = transformSons(c, n)

type
  TPutArgInto = enum
    paDirectMapping, paFastAsgn, paVarAsgn, paComplexOpenarray

proc putArgInto(arg: PNode, formal: PType): TPutArgInto =
  # This analyses how to treat the mapping "formal <-> arg" in an
  # inline context.
  if skipTypes(formal, abstractInst).kind in {tyOpenArray, tyVarargs}:
    if arg.kind == nkStmtListExpr:
      return paComplexOpenarray
    return paDirectMapping    # XXX really correct?
                              # what if ``arg`` has side-effects?
  case arg.kind
  of nkEmpty..nkNilLit:
    result = paDirectMapping
  of nkPar, nkTupleConstr, nkCurly, nkBracket:
    result = paFastAsgn
    for i in countup(0, sonsLen(arg) - 1):
      if putArgInto(arg.sons[i], formal) != paDirectMapping: return
    result = paDirectMapping
  else:
    if skipTypes(formal, abstractInst).kind in {tyVar, tyLent}: result = paVarAsgn
    else: result = paFastAsgn

proc findWrongOwners(c: PTransf, n: PNode) =
  if n.kind == nkVarSection:
    let x = n.sons[0].sons[0]
    if x.kind == nkSym and x.sym.owner != getCurrOwner(c):
      internalError(c.graph.config, x.info, "bah " & x.sym.name.s & " " &
        x.sym.owner.name.s & " " & getCurrOwner(c).name.s)
  else:
    for i in 0 ..< safeLen(n): findWrongOwners(c, n.sons[i])

proc transformFor(c: PTransf, n: PNode): PTransNode =
  # generate access statements for the parameters (unless they are constant)
  # put mapping from formal parameters to actual parameters
  if n.kind != nkForStmt: internalError(c.graph.config, n.info, "transformFor")

  var length = sonsLen(n)
  var call = n.sons[length - 2]

  let labl = newLabel(c, n)
  result = newTransNode(nkBlockStmt, n.info, 2)
  result[0] = newSymNode(labl).PTransNode
  if call.typ.isNil:
    # see bug #3051
    result[1] = newNode(nkEmpty).PTransNode
    return result
  c.breakSyms.add(labl)
  if call.kind notin nkCallKinds or call.sons[0].kind != nkSym or
      call.sons[0].typ.callConv == ccClosure:
    result[1] = n.PTransNode
    result[1][^1] = transformLoopBody(c, n[^1])
    result[1][^2] = transform(c, n[^2])
    result[1] = lambdalifting.liftForLoop(c.graph, result[1].PNode, getCurrOwner(c)).PTransNode
    discard c.breakSyms.pop
    return result

  #echo "transforming: ", renderTree(n)
  var stmtList = newTransNode(nkStmtList, n.info, 0)
  result[1] = stmtList

  var loopBody = transformLoopBody(c, n.sons[length-1])

  discard c.breakSyms.pop

  var v = newNodeI(nkVarSection, n.info)
  for i in countup(0, length - 3):
    if n[i].kind == nkVarTuple:
      for j in 0 ..< sonsLen(n[i])-1:
        addVar(v, copyTree(n[i][j])) # declare new vars
    else:
      addVar(v, copyTree(n.sons[i])) # declare new vars
  add(stmtList, v.PTransNode)

  # Bugfix: inlined locals belong to the invoking routine, not to the invoked
  # iterator!
  let iter = call.sons[0].sym
  var newC = newTransCon(getCurrOwner(c))
  newC.forStmt = n
  newC.forLoopBody = loopBody
  # this can fail for 'nimsuggest' and 'check':
  if iter.kind != skIterator: return result
  # generate access statements for the parameters (unless they are constant)
  pushTransCon(c, newC)
  for i in countup(1, sonsLen(call) - 1):
    var arg = transform(c, call.sons[i]).PNode
    let ff = skipTypes(iter.typ, abstractInst)
    # can happen for 'nim check':
    if i >= ff.n.len: return result
    var formal = ff.n.sons[i].sym
    case putArgInto(arg, formal.typ)
    of paDirectMapping:
      idNodeTablePut(newC.mapping, formal, arg)
    of paFastAsgn:
      # generate a temporary and produce an assignment statement:
      var temp = newTemp(c, formal.typ, formal.info)
      addVar(v, temp)
      add(stmtList, newAsgnStmt(c, nkFastAsgn, temp, arg.PTransNode))
      idNodeTablePut(newC.mapping, formal, temp)
    of paVarAsgn:
      assert(skipTypes(formal.typ, abstractInst).kind == tyVar)
      idNodeTablePut(newC.mapping, formal, arg)
      # XXX BUG still not correct if the arg has a side effect!
    of paComplexOpenarray:
      let typ = newType(tySequence, formal.owner)
      addSonSkipIntLit(typ, formal.typ.sons[0])
      var temp = newTemp(c, typ, formal.info)
      addVar(v, temp)
      add(stmtList, newAsgnStmt(c, nkFastAsgn, temp, arg.PTransNode))
      idNodeTablePut(newC.mapping, formal, temp)

  let body = transformBody(c.graph, iter, true, c.noDestructors)
  pushInfoContext(c.graph.config, n.info)
  inc(c.inlining)
  add(stmtList, transform(c, body))
  #findWrongOwners(c, stmtList.pnode)
  dec(c.inlining)
  popInfoContext(c.graph.config)
  popTransCon(c)
  # echo "transformed: ", stmtList.PNode.renderTree

proc transformCase(c: PTransf, n: PNode): PTransNode =
  # removes `elif` branches of a case stmt
  # adds ``else: nil`` if needed for the code generator
  result = newTransNode(nkCaseStmt, n, 0)
  var ifs = PTransNode(nil)
  for i in 0 .. sonsLen(n)-1:
    var it = n.sons[i]
    var e = transform(c, it)
    case it.kind
    of nkElifBranch:
      if ifs.PNode == nil:
        # Generate the right node depending on whether `n` is used as a stmt or
        # as an expr
        let kind = if n.typ != nil: nkIfExpr else: nkIfStmt
        ifs = newTransNode(kind, it.info, 0)
        ifs.PNode.typ = n.typ
      ifs.add(e)
    of nkElse:
      if ifs.PNode == nil: result.add(e)
      else: ifs.add(e)
    else:
      result.add(e)
  if ifs.PNode != nil:
    var elseBranch = newTransNode(nkElse, n.info, 1)
    elseBranch[0] = ifs
    result.add(elseBranch)
  elif result.PNode.lastSon.kind != nkElse and not (
      skipTypes(n.sons[0].typ, abstractVarRange).kind in
        {tyInt..tyInt64, tyChar, tyEnum, tyUInt..tyUInt32}):
    # fix a stupid code gen bug by normalizing:
    var elseBranch = newTransNode(nkElse, n.info, 1)
    elseBranch[0] = newTransNode(nkNilLit, n.info, 0)
    add(result, elseBranch)

proc transformArrayAccess(c: PTransf, n: PNode): PTransNode =
  # XXX this is really bad; transf should use a proper AST visitor
  if n.sons[0].kind == nkSym and n.sons[0].sym.kind == skType:
    result = n.PTransNode
  else:
    result = newTransNode(n)
    for i in 0 ..< n.len:
      result[i] = transform(c, skipConv(n.sons[i]))

proc getMergeOp(n: PNode): PSym =
  case n.kind
  of nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix,
     nkCallStrLit:
    if n.sons[0].kind == nkSym and n.sons[0].sym.magic == mConStrStr:
      result = n.sons[0].sym
  else: discard

proc flattenTreeAux(d, a: PNode, op: PSym) =
  let op2 = getMergeOp(a)
  if op2 != nil and
      (op2.id == op.id or op.magic != mNone and op2.magic == op.magic):
    for i in countup(1, sonsLen(a)-1): flattenTreeAux(d, a.sons[i], op)
  else:
    addSon(d, copyTree(a))

proc flattenTree(root: PNode): PNode =
  let op = getMergeOp(root)
  if op != nil:
    result = copyNode(root)
    addSon(result, copyTree(root.sons[0]))
    flattenTreeAux(result, root, op)
  else:
    result = root

proc transformCall(c: PTransf, n: PNode): PTransNode =
  var n = flattenTree(n)
  let op = getMergeOp(n)
  let magic = getMagic(n)
  if op != nil and op.magic != mNone and n.len >= 3:
    result = newTransNode(nkCall, n, 0)
    add(result, transform(c, n.sons[0]))
    var j = 1
    while j < sonsLen(n):
      var a = transform(c, n.sons[j]).PNode
      inc(j)
      if isConstExpr(a):
        while (j < sonsLen(n)):
          let b = transform(c, n.sons[j]).PNode
          if not isConstExpr(b): break
          a = evalOp(op.magic, n, a, b, nil, c.graph)
          inc(j)
      add(result, a.PTransNode)
    if len(result) == 2: result = result[1]
  elif magic == mAddr:
    result = newTransNode(nkAddr, n, 1)
    result[0] = n[1].PTransNode
    result = transformAddrDeref(c, result.PNode, nkDerefExpr, nkHiddenDeref)
  elif magic in {mNBindSym, mTypeOf, mRunnableExamples}:
    # for bindSym(myconst) we MUST NOT perform constant folding:
    result = n.PTransNode
  elif magic == mProcCall:
    # but do not change to its dispatcher:
    result = transformSons(c, n[1])
  else:
    let s = transformSons(c, n).PNode
    # bugfix: check after 'transformSons' if it's still a method call:
    # use the dispatcher for the call:
    if s.sons[0].kind == nkSym and s.sons[0].sym.kind == skMethod:
      when false:
        let t = lastSon(s.sons[0].sym.ast)
        if t.kind != nkSym or sfDispatcher notin t.sym.flags:
          methodDef(s.sons[0].sym, false)
      result = methodCall(s, c.graph.config).PTransNode
    else:
      result = s.PTransNode

proc transformExceptBranch(c: PTransf, n: PNode): PTransNode =
  result = transformSons(c, n)
  if n[0].isInfixAs() and not isImportedException(n[0][1].typ, c.graph.config):
    let excTypeNode = n[0][1]
    let actions = newTransNode(nkStmtListExpr, n[1], 2)
    # Generating `let exc = (excType)(getCurrentException())`
    # -> getCurrentException()
    let excCall = PTransNode(callCodegenProc(c.graph, "getCurrentException"))
    # -> (excType)
    let convNode = newTransNode(nkHiddenSubConv, n[1].info, 2)
    convNode[0] = PTransNode(newNodeI(nkEmpty, n.info))
    convNode[1] = excCall
    PNode(convNode).typ = excTypeNode.typ.toRef()
    # -> let exc = ...
    let identDefs = newTransNode(nkIdentDefs, n[1].info, 3)
    identDefs[0] = PTransNode(n[0][2])
    identDefs[1] = PTransNode(newNodeI(nkEmpty, n.info))
    identDefs[2] = convNode

    let letSection = newTransNode(nkLetSection, n[1].info, 1)
    letSection[0] = identDefs
    # Place the let statement and body of the 'except' branch into new stmtList.
    actions[0] = letSection
    actions[1] = transformSons(c, n[1])
    # Overwrite 'except' branch body with our stmtList.
    result[1] = actions

    # Replace the `Exception as foobar` with just `Exception`.
    result[0] = result[0][1]

proc dontInlineConstant(orig, cnst: PNode): bool {.inline.} =
  # symbols that expand to a complex constant (array, etc.) should not be
  # inlined, unless it's the empty array:
  result = orig.kind == nkSym and
           cnst.kind in {nkCurly, nkPar, nkTupleConstr, nkBracket} and
           cnst.len != 0

proc commonOptimizations*(g: ModuleGraph; c: PSym, n: PNode): PNode =
  result = n
  for i in 0 ..< n.safeLen:
    result.sons[i] = commonOptimizations(g, c, n.sons[i])
  var op = getMergeOp(n)
  if (op != nil) and (op.magic != mNone) and (sonsLen(n) >= 3):
    result = newNodeIT(nkCall, n.info, n.typ)
    add(result, n.sons[0])
    var args = newNode(nkArgList)
    flattenTreeAux(args, n, op)
    var j = 0
    while j < sonsLen(args):
      var a = args.sons[j]
      inc(j)
      if isConstExpr(a):
        while j < sonsLen(args):
          let b = args.sons[j]
          if not isConstExpr(b): break
          a = evalOp(op.magic, result, a, b, nil, g)
          inc(j)
      add(result, a)
    if len(result) == 2: result = result[1]
  else:
    var cnst = getConstExpr(c, n, g)
    # we inline constants if they are not complex constants:
    if cnst != nil and not dontInlineConstant(n, cnst):
      result = cnst
    else:
      result = n

proc hoistParamsUsedInDefault(c: PTransf, call, letSection, defExpr: PNode): PNode =
  # This takes care of complicated signatures such as:
  # proc foo(a: int, b = a)
  # proc bar(a: int, b: int, c = a + b)
  #
  # The recursion may confuse you. It performs two duties:
  #
  # 1) extracting all referenced params from default expressions
  #    into a let section preceeding the call
  #
  # 2) replacing the "references" within the default expression
  #    with these extracted skLet symbols.
  #
  # The first duty is carried out directly in the code here, while the second
  # duty is activated by returning a non-nil value. The caller is responsible
  # for replacing the input to the function with the returned non-nil value.
  # (which is the hoisted symbol)
  if defExpr.kind == nkSym:
    if defExpr.sym.kind == skParam and defExpr.sym.owner == call[0].sym:
      let paramPos = defExpr.sym.position + 1

      if call[paramPos].kind == nkSym and sfHoisted in call[paramPos].sym.flags:
        # Already hoisted, we still need to return it in order to replace the
        # placeholder expression in the default value.
        return call[paramPos]

      let hoistedVarSym = hoistExpr(letSection,
                                    call[paramPos],
                                    getIdent(c.graph.cache, genPrefix),
                                    c.transCon.owner).newSymNode
      call[paramPos] = hoistedVarSym
      return hoistedVarSym
  else:
    for i in 0..<defExpr.safeLen:
      let hoisted = hoistParamsUsedInDefault(c, call, letSection, defExpr[i])
      if hoisted != nil: defExpr[i] = hoisted

proc transform(c: PTransf, n: PNode): PTransNode =
  when false:
    var oldDeferAnchor: PNode
    if n.kind in {nkElifBranch, nkOfBranch, nkExceptBranch, nkElifExpr,
                  nkElseExpr, nkElse, nkForStmt, nkWhileStmt, nkFinally,
                  nkBlockStmt, nkBlockExpr}:
      oldDeferAnchor = c.deferAnchor
      c.deferAnchor = n
  if (n.typ != nil and tfHasAsgn in n.typ.flags) or
      optNimV2 in c.graph.config.globalOptions:
    c.needsDestroyPass = true
  case n.kind
  of nkSym:
    result = transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit, nkComesFrom:
    # nothing to be done for leaves:
    result = PTransNode(n)
  of nkBracketExpr: result = transformArrayAccess(c, n)
  of procDefs:
    var s = n.sons[namePos].sym
    if n.typ != nil and s.typ.callConv == ccClosure:
      result = transformSym(c, n.sons[namePos])
      # use the same node as before if still a symbol:
      if result.PNode.kind == nkSym: result = PTransNode(n)
    else:
      result = PTransNode(n)
  of nkMacroDef:
    # XXX no proper closure support yet:
    when false:
      if n.sons[genericParamsPos].kind == nkEmpty:
        var s = n.sons[namePos].sym
        n.sons[bodyPos] = PNode(transform(c, s.getBody))
        if n.kind == nkMethodDef: methodDef(s, false)
    result = PTransNode(n)
  of nkForStmt:
    result = transformFor(c, n)
  of nkParForStmt:
    result = transformSons(c, n)
  of nkCaseStmt:
    result = transformCase(c, n)
  of nkWhileStmt: result = transformWhile(c, n)
  of nkBlockStmt, nkBlockExpr:
    result = transformBlock(c, n)
  of nkDefer:
    c.deferDetected = true
    result = transformSons(c, n)
    when false:
      let deferPart = newNodeI(nkFinally, n.info)
      deferPart.add n.sons[0]
      let tryStmt = newNodeI(nkTryStmt, n.info)
      if c.deferAnchor.isNil:
        tryStmt.add c.root
        c.root = tryStmt
        result = PTransNode(tryStmt)
      else:
        # modify the corresponding *action*, don't rely on nkStmtList:
        let L = c.deferAnchor.len-1
        tryStmt.add c.deferAnchor.sons[L]
        c.deferAnchor.sons[L] = tryStmt
        result = newTransNode(nkCommentStmt, n.info, 0)
      tryStmt.addSon(deferPart)
      # disable the original 'defer' statement:
      n.kind = nkEmpty
  of nkContinueStmt:
    result = PTransNode(newNodeI(nkBreakStmt, n.info))
    var labl = c.contSyms[c.contSyms.high]
    add(result, PTransNode(newSymNode(labl)))
  of nkBreakStmt: result = transformBreak(c, n)
  of nkCallKinds:
    result = transformCall(c, n)
    var call = result.PNode
    if nfDefaultRefsParam in call.flags:
      # We've found a default value that references another param.
      # See the notes in `hoistParamsUsedInDefault` for more details.
      var hoistedParams = newNodeI(nkLetSection, call.info, 0)
      for i in 1 ..< call.len:
        let hoisted = hoistParamsUsedInDefault(c, call, hoistedParams, call[i])
        if hoisted != nil: call[i] = hoisted
      result = newTree(nkStmtListExpr, hoistedParams, call).PTransNode
      PNode(result).typ = call.typ
  of nkAddr, nkHiddenAddr:
    result = transformAddrDeref(c, n, nkDerefExpr, nkHiddenDeref)
  of nkDerefExpr, nkHiddenDeref:
    result = transformAddrDeref(c, n, nkAddr, nkHiddenAddr)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    result = transformConv(c, n)
  of nkDiscardStmt:
    result = PTransNode(n)
    if n.sons[0].kind != nkEmpty:
      result = transformSons(c, n)
      if isConstExpr(PNode(result).sons[0]):
        # ensure that e.g. discard "some comment" gets optimized away
        # completely:
        result = PTransNode(newNode(nkCommentStmt))
  of nkCommentStmt, nkTemplateDef, nkImportStmt, nkStaticStmt,
      nkExportStmt, nkExportExceptStmt:
    return n.PTransNode
  of nkConstSection:
    # do not replace ``const c = 3`` with ``const 3 = 3``
    return transformConstSection(c, n)
  of nkTypeSection, nkTypeOfExpr:
    # no need to transform type sections:
    return PTransNode(n)
  of nkVarSection, nkLetSection:
    if c.inlining > 0:
      # we need to copy the variables for multiple yield statements:
      result = transformVarSection(c, n)
    else:
      result = transformSons(c, n)
  of nkYieldStmt:
    if c.inlining > 0:
      result = transformYield(c, n)
    else:
      result = transformSons(c, n)
  #of nkAsgn:
  #  result = transformAsgn(c, n)
  of nkIdentDefs, nkConstDef:
    result = PTransNode(n)
    result[0] = transform(c, n[0])
    # Skip the second son since it only contains an unsemanticized copy of the
    # variable type used by docgen
    result[2] = transform(c, n[2])
    # XXX comment handling really sucks:
    if importantComments(c.graph.config):
      PNode(result).comment = n.comment
  of nkClosure:
    # it can happen that for-loop-inlining produced a fresh
    # set of variables, including some computed environment
    # (bug #2604). We need to patch this environment here too:
    let a = n[1]
    if a.kind == nkSym:
      n.sons[1] = transformSymAux(c, a)
    return PTransNode(n)
  of nkExceptBranch:
    result = transformExceptBranch(c, n)
  else:
    result = transformSons(c, n)
  when false:
    if oldDeferAnchor != nil: c.deferAnchor = oldDeferAnchor

  # Constants can be inlined here, but only if they cannot result in a cast
  # in the back-end (e.g. var p: pointer = someProc)
  let exprIsPointerCast = n.kind in {nkCast, nkConv, nkHiddenStdConv} and
                          n.typ.kind == tyPointer
  if not exprIsPointerCast:
    var cnst = getConstExpr(c.module, PNode(result), c.graph)
    # we inline constants if they are not complex constants:
    if cnst != nil and not dontInlineConstant(n, cnst):
      result = PTransNode(cnst) # do not miss an optimization

proc processTransf(c: PTransf, n: PNode, owner: PSym): PNode =
  # Note: For interactive mode we cannot call 'passes.skipCodegen' and skip
  # this step! We have to rely that the semantic pass transforms too errornous
  # nodes into an empty node.
  if nfTransf in n.flags: return n
  pushTransCon(c, newTransCon(owner))
  result = PNode(transform(c, n))
  popTransCon(c)
  incl(result.flags, nfTransf)

proc openTransf(g: ModuleGraph; module: PSym, filename: string): PTransf =
  new(result)
  result.contSyms = @[]
  result.breakSyms = @[]
  result.module = module
  result.graph = g

proc flattenStmts(n: PNode) =
  var goOn = true
  while goOn:
    goOn = false
    var i = 0
    while i < n.len:
      let it = n[i]
      if it.kind in {nkStmtList, nkStmtListExpr}:
        n.sons[i..i] = it.sons[0..<it.len]
        goOn = true
      inc i

proc liftDeferAux(n: PNode) =
  if n.kind in {nkStmtList, nkStmtListExpr}:
    flattenStmts(n)
    var goOn = true
    while goOn:
      goOn = false
      let last = n.len-1
      for i in 0..last:
        if n.sons[i].kind == nkDefer:
          let deferPart = newNodeI(nkFinally, n.sons[i].info)
          deferPart.add n.sons[i].sons[0]
          var tryStmt = newNodeI(nkTryStmt, n.sons[i].info)
          var body = newNodeI(n.kind, n.sons[i].info)
          if i < last:
            body.sons = n.sons[(i+1)..last]
          tryStmt.addSon(body)
          tryStmt.addSon(deferPart)
          n.sons[i] = tryStmt
          n.sons.setLen(i+1)
          n.typ = n.sons[i].typ
          goOn = true
          break
  for i in 0..n.safeLen-1:
    liftDeferAux(n.sons[i])

template liftDefer(c, root) =
  if c.deferDetected:
    liftDeferAux(root)

proc transformBody*(g: ModuleGraph, prc: PSym, cache = true;
                    noDestructors = false): PNode =
  assert prc.kind in routineKinds

  if prc.transformedBody != nil:
    result = prc.transformedBody
  elif nfTransf in prc.ast[bodyPos].flags or prc.kind in {skTemplate}:
    result = prc.ast[bodyPos]
  else:
    prc.transformedBody = newNode(nkEmpty) # protects from recursion
    var c = openTransf(g, prc.getModule, "")
    c.noDestructors = noDestructors
    result = liftLambdas(g, prc, prc.ast[bodyPos], c.tooEarly)
    result = processTransf(c, result, prc)
    liftDefer(c, result)
    result = liftLocalsIfRequested(prc, result, g.cache, g.config)
    if c.needsDestroyPass and not noDestructors:
      result = injectDestructorCalls(g, prc, result)

    if prc.isIterator:
      result = g.transformClosureIterator(prc, result)

    incl(result.flags, nfTransf)

    let cache = cache or prc.typ.callConv == ccInline
    if cache:
      # genProc for inline procs will be called multiple times from diffrent modules,
      # it is important to transform exactly once to get sym ids and locations right
      prc.transformedBody = result
    else:
      prc.transformedBody = nil

proc transformStmt*(g: ModuleGraph; module: PSym, n: PNode): PNode =
  if nfTransf in n.flags:
    result = n
  else:
    var c = openTransf(g, module, "")
    result = processTransf(c, n, module)
    liftDefer(c, result)
    #result = liftLambdasForTopLevel(module, result)
    if c.needsDestroyPass:
      result = injectDestructorCalls(g, module, result)
    incl(result.flags, nfTransf)

proc transformExpr*(g: ModuleGraph; module: PSym, n: PNode;
                    noDestructors = false): PNode =
  if nfTransf in n.flags:
    result = n
  else:
    var c = openTransf(g, module, "")
    result = processTransf(c, n, module)
    liftDefer(c, result)
    # expressions are not to be injected with destructor calls as that
    # the list of top level statements needs to be collected before.
    if c.needsDestroyPass and not noDestructors:
      result = injectDestructorCalls(g, module, result)
    incl(result.flags, nfTransf)
