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
# * performes constant folding
# * converts "continue" to "break"; disambiguates "break"
# * introduces method dispatchers
# * performs lambda lifting for closure support

import
  intsets, strutils, lists, options, ast, astalgo, trees, treetab, msgs, os,
  idents, renderer, types, passes, semfold, magicsys, cgmeth, rodread,
  lambdalifting, sempass2, lowerings

# implementation

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

  TTransfContext = object of passes.TPassContext
    module: PSym
    transCon: PTransCon      # top of a TransCon stack
    inlining: int            # > 0 if we are in inlining context (copy vars)
    nestedProcs: int         # > 0 if we are in a nested proc
    contSyms, breakSyms: seq[PSym]  # to transform 'continue' and 'break'
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
  result = x.PTransNode

proc `[]=`(a: PTransNode, i: int, x: PTransNode) {.inline.} =
  var n = PNode(a)
  n.sons[i] = PNode(x)

proc `[]`(a: PTransNode, i: int): PTransNode {.inline.} =
  var n = PNode(a)
  result = n.sons[i].PTransNode

proc add(a, b: PTransNode) {.inline.} = addSon(PNode(a), PNode(b))
proc len(a: PTransNode): int {.inline.} = result = sonsLen(a.PNode)

proc newTransCon(owner: PSym): PTransCon =
  assert owner != nil
  new(result)
  initIdNodeTable(result.mapping)
  result.owner = owner

proc pushTransCon(c: PTransf, t: PTransCon) =
  t.next = c.transCon
  c.transCon = t

proc popTransCon(c: PTransf) =
  if (c.transCon == nil): internalError("popTransCon")
  c.transCon = c.transCon.next

proc getCurrOwner(c: PTransf): PSym =
  if c.transCon != nil: result = c.transCon.owner
  else: result = c.module

proc newTemp(c: PTransf, typ: PType, info: TLineInfo): PSym =
  result = newSym(skTemp, getIdent(genPrefix), getCurrOwner(c), info)
  result.typ = skipTypes(typ, {tyGenericInst})
  incl(result.flags, sfFromGeneric)

proc transform(c: PTransf, n: PNode): PTransNode

proc transformSons(c: PTransf, n: PNode): PTransNode =
  result = newTransNode(n)
  for i in countup(0, sonsLen(n)-1):
    result[i] = transform(c, n.sons[i])

proc newAsgnStmt(c: PTransf, le: PNode, ri: PTransNode): PTransNode =
  result = newTransNode(nkFastAsgn, PNode(ri).info, 2)
  result[0] = PTransNode(le)
  result[1] = ri

proc transformSymAux(c: PTransf, n: PNode): PNode =
  #if n.sym.kind == skClosureIterator:
  #  return liftIterSym(n)
  var b: PNode
  var tc = c.transCon
  if sfBorrow in n.sym.flags:
    # simply exchange the symbol:
    b = n.sym.getBody
    if b.kind != nkSym: internalError(n.info, "wrong AST for borrowed symbol")
    b = newSymNode(b.sym)
    b.info = n.info
  else:
    b = n
  while tc != nil:
    result = idNodeTableGet(tc.mapping, b.sym)
    if result != nil: return
    tc = tc.next
  result = b

proc transformSym(c: PTransf, n: PNode): PTransNode =
  result = PTransNode(transformSymAux(c, n))

proc transformVarSection(c: PTransf, v: PNode): PTransNode =
  result = newTransNode(v)
  for i in countup(0, sonsLen(v)-1):
    var it = v.sons[i]
    if it.kind == nkCommentStmt:
      result[i] = PTransNode(it)
    elif it.kind == nkIdentDefs:
      if it.sons[0].kind != nkSym: internalError(it.info, "transformVarSection")
      internalAssert(it.len == 3)
      var newVar = copySym(it.sons[0].sym)
      incl(newVar.flags, sfFromGeneric)
      # fixes a strange bug for rodgen:
      #include(it.sons[0].sym.flags, sfFromGeneric);
      newVar.owner = getCurrOwner(c)
      idNodeTablePut(c.transCon.mapping, it.sons[0].sym, newSymNode(newVar))
      var defs = newTransNode(nkIdentDefs, it.info, 3)
      if importantComments():
        # keep documentation information:
        PNode(defs).comment = it.comment
      defs[0] = newSymNode(newVar).PTransNode
      defs[1] = it.sons[1].PTransNode
      defs[2] = transform(c, it.sons[2])
      newVar.ast = defs[2].PNode
      result[i] = defs
    else:
      if it.kind != nkVarTuple:
        internalError(it.info, "transformVarSection: not nkVarTuple")
      var L = sonsLen(it)
      var defs = newTransNode(it.kind, it.info, L)
      for j in countup(0, L-3):
        var newVar = copySym(it.sons[j].sym)
        incl(newVar.flags, sfFromGeneric)
        newVar.owner = getCurrOwner(c)
        idNodeTablePut(c.transCon.mapping, it.sons[j].sym, newSymNode(newVar))
        defs[j] = newSymNode(newVar).PTransNode
      assert(it.sons[L-2].kind == nkEmpty)
      defs[L-2] = ast.emptyNode.PTransNode
      defs[L-1] = transform(c, it.sons[L-1])
      result[i] = defs

proc transformConstSection(c: PTransf, v: PNode): PTransNode =
  result = newTransNode(v)
  for i in countup(0, sonsLen(v)-1):
    var it = v.sons[i]
    if it.kind == nkCommentStmt:
      result[i] = PTransNode(it)
    else:
      if it.kind != nkConstDef: internalError(it.info, "transformConstSection")
      if it.sons[0].kind != nkSym:
        internalError(it.info, "transformConstSection")
      if sfFakeConst in it[0].sym.flags:
        var b = newNodeI(nkConstDef, it.info)
        addSon(b, it[0])
        addSon(b, ast.emptyNode)            # no type description
        addSon(b, transform(c, it[2]).PNode)
        result[i] = PTransNode(b)
      else:
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
  result.name = getIdent(genPrefix & $result.id)

proc freshLabels(c: PTransf, n: PNode; symMap: var TIdTable) =
  if n.kind in {nkBlockStmt, nkBlockExpr}:
    if n.sons[0].kind == nkSym:
      let x = newLabel(c, n[0])
      idTablePut(symMap, n[0].sym, x)
      n.sons[0].sym = x
  if n.kind == nkSym and n.sym.kind == skLabel:
    let x = PSym(idTableGet(symMap, n.sym))
    if x != nil: n.sym = x
  else:
    for i in 0 .. <safeLen(n): freshLabels(c, n.sons[i], symMap)

proc transformBlock(c: PTransf, n: PNode): PTransNode =
  var labl: PSym
  if n.sons[0].kind != nkEmpty:
    # already named block? -> Push symbol on the stack:
    labl = n.sons[0].sym
  else:
    labl = newLabel(c, n)
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
    body[<n.len] = transformLoopBody(c, n.sons[<n.len])
    result[1] = body
    discard c.breakSyms.pop

proc transformBreak(c: PTransf, n: PNode): PTransNode =
  if n.sons[0].kind != nkEmpty or c.inlining > 0:
    result = n.PTransNode
    when false:
      let lablCopy = idNodeTableGet(c.transCon.mapping, n.sons[0].sym)
      if lablCopy.isNil:
        result = n.PTransNode
      else:
        result = newTransNode(n.kind, n.info, 1)
        result[0] = lablCopy.PTransNode
  else:
    let labl = c.breakSyms[c.breakSyms.high]
    result = transformSons(c, n)
    result[0] = newSymNode(labl).PTransNode

proc unpackTuple(c: PTransf, n: PNode, father: PTransNode) =
  # XXX: BUG: what if `n` is an expression with side-effects?
  for i in countup(0, sonsLen(c.transCon.forStmt) - 3):
    add(father, newAsgnStmt(c, c.transCon.forStmt.sons[i],
        transform(c, newTupleAccess(n, i))))

proc introduceNewLocalVars(c: PTransf, n: PNode): PTransNode =
  case n.kind
  of nkSym:
    result = transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    # nothing to be done for leaves:
    result = PTransNode(n)
  of nkVarSection, nkLetSection:
    result = transformVarSection(c, n)
  else:
    result = newTransNode(n)
    for i in countup(0, sonsLen(n)-1):
      result[i] =  introduceNewLocalVars(c, n.sons[i])

proc transformYield(c: PTransf, n: PNode): PTransNode =
  result = newTransNode(nkStmtList, n.info, 0)
  var e = n.sons[0]
  # c.transCon.forStmt.len == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if skipTypes(e.typ, {tyGenericInst}).kind == tyTuple and
      c.transCon.forStmt.len != 3:
    e = skipConv(e)
    if e.kind == nkPar:
      for i in countup(0, sonsLen(e) - 1):
        add(result, newAsgnStmt(c, c.transCon.forStmt.sons[i],
                                transform(c, e.sons[i])))
    else:
      unpackTuple(c, e, result)
  else:
    var x = transform(c, e)
    add(result, newAsgnStmt(c, c.transCon.forStmt.sons[0], x))

  inc(c.transCon.yieldStmts)
  if c.transCon.yieldStmts <= 1:
    # common case
    add(result, c.transCon.forLoopBody)
  else:
    # we need to introduce new local variables:
    add(result, introduceNewLocalVars(c, c.transCon.forLoopBody.PNode))

proc transformAddrDeref(c: PTransf, n: PNode, a, b: TNodeKind): PTransNode =
  result = transformSons(c, n)
  if gCmd == cmdCompileToCpp or sfCompileToCpp in c.module.flags: return
  var n = result.PNode
  case n.sons[0].kind
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    var m = n.sons[0].sons[0]
    if m.kind == a or m.kind == b:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      n.sons[0].sons[0] = m.sons[0]
      result = PTransNode(n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    var m = n.sons[0].sons[1]
    if m.kind == a or m.kind == b:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      n.sons[0].sons[1] = m.sons[0]
      result = PTransNode(n.sons[0])
  else:
    if n.sons[0].kind == a or n.sons[0].kind == b:
      # addr ( deref ( x )) --> x
      result = PTransNode(n.sons[0].sons[0])

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
    elif firstOrd(n.typ) <= firstOrd(n.sons[1].typ) and
        lastOrd(n.sons[1].typ) <= lastOrd(n.typ):
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
      result[1] = newIntTypeNode(nkIntLit, firstOrd(dest), source).PTransNode
      result[2] = newIntTypeNode(nkIntLit, lastOrd(dest), source).PTransNode
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
  else:
    result = transformSons(c, n)

type
  TPutArgInto = enum
    paDirectMapping, paFastAsgn, paVarAsgn

proc putArgInto(arg: PNode, formal: PType): TPutArgInto =
  # This analyses how to treat the mapping "formal <-> arg" in an
  # inline context.
  if skipTypes(formal, abstractInst).kind in {tyOpenArray, tyVarargs}:
    return paDirectMapping    # XXX really correct?
                              # what if ``arg`` has side-effects?
  case arg.kind
  of nkEmpty..nkNilLit:
    result = paDirectMapping
  of nkPar, nkCurly, nkBracket:
    result = paFastAsgn
    for i in countup(0, sonsLen(arg) - 1):
      if putArgInto(arg.sons[i], formal) != paDirectMapping: return
    result = paDirectMapping
  else:
    if skipTypes(formal, abstractInst).kind == tyVar: result = paVarAsgn
    else: result = paFastAsgn

proc findWrongOwners(c: PTransf, n: PNode) =
  if n.kind == nkVarSection:
    let x = n.sons[0].sons[0]
    if x.kind == nkSym and x.sym.owner != getCurrOwner(c):
      internalError(x.info, "bah " & x.sym.name.s & " " &
        x.sym.owner.name.s & " " & getCurrOwner(c).name.s)
  else:
    for i in 0 .. <safeLen(n): findWrongOwners(c, n.sons[i])

proc transformFor(c: PTransf, n: PNode): PTransNode =
  # generate access statements for the parameters (unless they are constant)
  # put mapping from formal parameters to actual parameters
  if n.kind != nkForStmt: internalError(n.info, "transformFor")

  var length = sonsLen(n)
  var call = n.sons[length - 2]

  let labl = newLabel(c, n)
  c.breakSyms.add(labl)
  result = newTransNode(nkBlockStmt, n.info, 2)
  result[0] = newSymNode(labl).PTransNode

  if call.typ.kind != tyIter and
    (call.kind notin nkCallKinds or call.sons[0].kind != nkSym or
      call.sons[0].sym.kind != skIterator):
    n.sons[length-1] = transformLoopBody(c, n.sons[length-1]).PNode
    result[1] = lambdalifting.liftForLoop(n).PTransNode
    discard c.breakSyms.pop
    return result

  #echo "transforming: ", renderTree(n)
  var stmtList = newTransNode(nkStmtList, n.info, 0)

  var loopBody = transformLoopBody(c, n.sons[length-1])

  result[1] = stmtList
  discard c.breakSyms.pop

  var v = newNodeI(nkVarSection, n.info)
  for i in countup(0, length - 3):
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
    var formal = skipTypes(iter.typ, abstractInst).n.sons[i].sym
    if arg.typ.kind == tyIter: continue
    case putArgInto(arg, formal.typ)
    of paDirectMapping:
      idNodeTablePut(newC.mapping, formal, arg)
    of paFastAsgn:
      # generate a temporary and produce an assignment statement:
      var temp = newTemp(c, formal.typ, formal.info)
      addVar(v, newSymNode(temp))
      add(stmtList, newAsgnStmt(c, newSymNode(temp), arg.PTransNode))
      idNodeTablePut(newC.mapping, formal, newSymNode(temp))
    of paVarAsgn:
      assert(skipTypes(formal.typ, abstractInst).kind == tyVar)
      idNodeTablePut(newC.mapping, formal, arg)
      # XXX BUG still not correct if the arg has a side effect!
  var body = iter.getBody.copyTree
  pushInfoContext(n.info)
  # XXX optimize this somehow. But the check "c.inlining" is not correct:
  var symMap: TIdTable
  initIdTable symMap
  freshLabels(c, body, symMap)

  inc(c.inlining)
  add(stmtList, transform(c, body))
  #findWrongOwners(c, stmtList.pnode)
  dec(c.inlining)
  popInfoContext()
  popTransCon(c)
  # echo "transformed: ", stmtList.PNode.renderTree

proc getMagicOp(call: PNode): TMagic =
  if call.sons[0].kind == nkSym and
      call.sons[0].sym.kind in {skProc, skMethod, skConverter}:
    result = call.sons[0].sym.magic
  else:
    result = mNone

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
        ifs = newTransNode(nkIfStmt, it.info, 0)
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
    for i in 0 .. < n.len:
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
          a = evalOp(op.magic, n, a, b, nil)
          inc(j)
      add(result, a.PTransNode)
    if len(result) == 2: result = result[1]
  elif magic == mNBindSym:
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
      let t = lastSon(s.sons[0].sym.ast)
      if t.kind != nkSym or sfDispatcher notin t.sym.flags:
        methodDef(s.sons[0].sym, false)
      result = methodCall(s).PTransNode
    else:
      result = s.PTransNode

proc dontInlineConstant(orig, cnst: PNode): bool {.inline.} =
  # symbols that expand to a complex constant (array, etc.) should not be
  # inlined, unless it's the empty array:
  result = orig.kind == nkSym and cnst.kind in {nkCurly, nkPar, nkBracket} and
      cnst.len != 0

proc commonOptimizations*(c: PSym, n: PNode): PNode =
  result = n
  for i in 0 .. < n.safeLen:
    result.sons[i] = commonOptimizations(c, n.sons[i])
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
          a = evalOp(op.magic, result, a, b, nil)
          inc(j)
      add(result, a)
    if len(result) == 2: result = result[1]
  else:
    var cnst = getConstExpr(c, n)
    # we inline constants if they are not complex constants:
    if cnst != nil and not dontInlineConstant(n, cnst):
      result = cnst
    else:
      result = n

proc transform(c: PTransf, n: PNode): PTransNode =
  case n.kind
  of nkSym:
    result = transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    # nothing to be done for leaves:
    result = PTransNode(n)
  of nkBracketExpr: result = transformArrayAccess(c, n)
  of procDefs:
    when false:
      if n.sons[genericParamsPos].kind == nkEmpty:
        var s = n.sons[namePos].sym
        n.sons[bodyPos] = PNode(transform(c, s.getBody))
        if s.ast.sons[bodyPos] != n.sons[bodyPos]:
          # somehow this can happen ... :-/
          s.ast.sons[bodyPos] = n.sons[bodyPos]
        #n.sons[bodyPos] = liftLambdas(s, n)
        #if n.kind == nkMethodDef: methodDef(s, false)
    #if n.kind == nkIteratorDef and n.typ != nil:
    #  return liftIterSym(n.sons[namePos]).PTransNode
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
  of nkCaseStmt: result = transformCase(c, n)
  of nkContinueStmt:
    result = PTransNode(newNodeI(nkBreakStmt, n.info))
    var labl = c.contSyms[c.contSyms.high]
    add(result, PTransNode(newSymNode(labl)))
  of nkBreakStmt: result = transformBreak(c, n)
  of nkWhileStmt: result = transformWhile(c, n)
  of nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix,
     nkCallStrLit:
    result = transformCall(c, n)
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
  of nkCommentStmt, nkTemplateDef:
    return n.PTransNode
  of nkConstSection:
    # do not replace ``const c = 3`` with ``const 3 = 3``
    return transformConstSection(c, n)
  of nkTypeSection:
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
  of nkBlockStmt, nkBlockExpr:
    result = transformBlock(c, n)
  of nkIdentDefs, nkConstDef:
    result = transformSons(c, n)
    # XXX comment handling really sucks:
    if importantComments():
      PNode(result).comment = n.comment
  of nkClosure: return PTransNode(n)
  else:
    result = transformSons(c, n)
  var cnst = getConstExpr(c.module, PNode(result))
  # we inline constants if they are not complex constants:
  if cnst != nil and not dontInlineConstant(n, cnst):
    result = PTransNode(cnst) # do not miss an optimization

proc processTransf(c: PTransf, n: PNode, owner: PSym): PNode =
  # Note: For interactive mode we cannot call 'passes.skipCodegen' and skip
  # this step! We have to rely that the semantic pass transforms too errornous
  # nodes into an empty node.
  if c.fromCache or nfTransf in n.flags: return n
  pushTransCon(c, newTransCon(owner))
  result = PNode(transform(c, n))
  popTransCon(c)
  incl(result.flags, nfTransf)

proc openTransf(module: PSym, filename: string): PTransf =
  new(result)
  result.contSyms = @[]
  result.breakSyms = @[]
  result.module = module

proc transformBody*(module: PSym, n: PNode, prc: PSym): PNode =
  if nfTransf in n.flags or prc.kind in {skTemplate}:
    result = n
  else:
    var c = openTransf(module, "")
    result = processTransf(c, n, prc)
    result = liftLambdas(prc, result)
    #if prc.kind == skClosureIterator:
    #  result = lambdalifting.liftIterator(prc, result)
    incl(result.flags, nfTransf)
    when useEffectSystem: trackProc(prc, result)
    #if prc.name.s == "testbody":
    #  echo renderTree(result)

proc transformStmt*(module: PSym, n: PNode): PNode =
  if nfTransf in n.flags:
    result = n
  else:
    var c = openTransf(module, "")
    result = processTransf(c, n, module)
    result = liftLambdasForTopLevel(module, result)
    incl(result.flags, nfTransf)
    when useEffectSystem: trackTopLevelStmt(module, result)

proc transformExpr*(module: PSym, n: PNode): PNode =
  if nfTransf in n.flags:
    result = n
  else:
    var c = openTransf(module, "")
    result = processTransf(c, n, module)
    incl(result.flags, nfTransf)
