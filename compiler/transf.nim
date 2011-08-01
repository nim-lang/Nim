#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the transformator. It transforms the syntax tree
# to ease the work of the code generators. Does some transformations:
#
# * inlines iterators
# * inlines constants
# * performes contant folding
# * converts "continue" to "break"
# * introduces method dispatchers

import 
  intsets, strutils, lists, options, ast, astalgo, trees, treetab, msgs, os, 
  idents, renderer, types, passes, semfold, magicsys, cgmeth

const 
  genPrefix* = ":tmp"         # prefix for generated names

proc transfPass*(): TPass
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
    blocksyms: seq[PSym]
  
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
  if (c.transCon == nil): InternalError("popTransCon")
  c.transCon = c.transCon.next

proc getCurrOwner(c: PTransf): PSym = 
  if c.transCon != nil: result = c.transCon.owner
  else: result = c.module
  
proc newTemp(c: PTransf, typ: PType, info: TLineInfo): PSym = 
  result = newSym(skTemp, getIdent(genPrefix), getCurrOwner(c))
  result.info = info
  result.typ = skipTypes(typ, {tyGenericInst})
  incl(result.flags, sfFromGeneric)

proc transform(c: PTransf, n: PNode): PTransNode

proc transformSons(c: PTransf, n: PNode): PTransNode =
  result = newTransNode(n)
  for i in countup(0, sonsLen(n)-1): 
    result[i] = transform(c, n.sons[i])

# Transforming iterators into non-inlined versions is pretty hard, but
# unavoidable for not bloating the code too much. If we had direct access to
# the program counter, things'd be much easier.
# ::
#
#  iterator items(a: string): char =
#    var i = 0
#    while i < length(a):
#      yield a[i]
#      inc(i)
#
#  for ch in items("hello world"): # `ch` is an iteration variable
#    echo(ch)
#
# Should be transformed into::
#
#  type
#    TItemsClosure = record
#      i: int
#      state: int
#  proc items(a: string, c: var TItemsClosure): char =
#    case c.state
#    of 0: goto L0 # very difficult without goto!
#    of 1: goto L1 # can be implemented by GCC's computed gotos
#
#    block L0:
#      c.i = 0
#      while c.i < length(a):
#        c.state = 1
#        return a[i]
#        block L1: inc(c.i)
#
# More efficient, but not implementable::
#
#  type
#    TItemsClosure = record
#      i: int
#      pc: pointer
#
#  proc items(a: string, c: var TItemsClosure): char =
#    goto c.pc
#    c.i = 0
#    while c.i < length(a):
#      c.pc = label1
#      return a[i]
#      label1: inc(c.i)
#

proc newAsgnStmt(c: PTransf, le: PNode, ri: PTransNode): PTransNode = 
  result = newTransNode(nkFastAsgn, PNode(ri).info, 2)
  result[0] = PTransNode(le)
  result[1] = ri

proc transformSymAux(c: PTransf, n: PNode): PNode = 
  var b: PNode
  if (n.kind != nkSym): internalError(n.info, "transformSym")
  var tc = c.transCon
  if sfBorrow in n.sym.flags: 
    # simply exchange the symbol:
    b = n.sym.ast.sons[codePos]
    if b.kind != nkSym: internalError(n.info, "wrong AST for borrowed symbol")
    b = newSymNode(b.sym)
    b.info = n.info
  else: 
    b = n
  while tc != nil: 
    result = IdNodeTableGet(tc.mapping, b.sym)
    if result != nil: return
    tc = tc.next
  result = b
  case b.sym.kind
  of skConst, skEnumField: 
    if sfFakeConst notin b.sym.flags:
      if skipTypes(b.sym.typ, abstractInst).kind notin ConstantDataTypes: 
        result = getConstExpr(c.module, b)
        if result == nil: InternalError(b.info, "transformSym: const")
  else: 
    nil

proc transformSym(c: PTransf, n: PNode): PTransNode = 
  result = PTransNode(transformSymAux(c, n))

proc transformVarSection(c: PTransf, v: PNode): PTransNode =
  result = newTransNode(v)
  for i in countup(0, sonsLen(v)-1): 
    var it = v.sons[i]
    if it.kind == nkCommentStmt: 
      result[i] = PTransNode(it)
    elif it.kind == nkIdentDefs: 
      if it.sons[0].kind != nkSym: InternalError(it.info, "transformVarSection")
      var newVar = copySym(it.sons[0].sym)
      incl(newVar.flags, sfFromGeneric) 
      # fixes a strange bug for rodgen:
      #include(it.sons[0].sym.flags, sfFromGeneric);
      newVar.owner = getCurrOwner(c)
      IdNodeTablePut(c.transCon.mapping, it.sons[0].sym, newSymNode(newVar))
      var defs = newTransNode(nkIdentDefs, it.info, 3)
      defs[0] = newSymNode(newVar).PTransNode
      defs[1] = it.sons[1].PTransNode
      defs[2] = transform(c, it.sons[2])
      result[i] = defs
    else: 
      if it.kind != nkVarTuple: 
        InternalError(it.info, "transformVarSection: not nkVarTuple")
      var L = sonsLen(it)
      var defs = newTransNode(it.kind, it.info, L)
      for j in countup(0, L-3): 
        var newVar = copySym(it.sons[j].sym)
        incl(newVar.flags, sfFromGeneric)
        newVar.owner = getCurrOwner(c)
        IdNodeTablePut(c.transCon.mapping, it.sons[j].sym, newSymNode(newVar))
        defs[j] = newSymNode(newVar).PTransNode
      assert(it.sons[L-2].kind == nkEmpty)
      defs[L-1] = transform(c, it.sons[L-1])
      result[i] = defs

proc transformConstSection(c: PTransf, v: PNode): PTransNode =
  result = newTransNode(v)
  for i in countup(0, sonsLen(v)-1):
    var it = v.sons[i]
    if it.kind == nkCommentStmt:
      result[i] = PTransNode(it)
    else:
      if it.kind != nkConstDef: InternalError(it.info, "transformConstSection")
      if it.sons[0].kind != nkSym:
        InternalError(it.info, "transformConstSection")
      if sfFakeConst in it[0].sym.flags:
        var b = newNodeI(nkConstDef, it.info)
        addSon(b, it[0])
        addSon(b, ast.emptyNode)            # no type description
        addSon(b, transform(c, it[2]).pnode)
        result[i] = PTransNode(b)
      else:
        result[i] = PTransNode(it)
  

proc hasContinue(n: PNode): bool = 
  case n.kind
  of nkEmpty..nkNilLit, nkForStmt, nkWhileStmt: nil
  of nkContinueStmt: result = true
  else: 
    for i in countup(0, sonsLen(n) - 1): 
      if hasContinue(n.sons[i]): return true

proc transformLoopBody(c: PTransf, n: PNode): PTransNode =  
  # XXX BUG: What if it contains "continue" and "break"? "break" needs 
  # an explicit label too, but not the same!
  if hasContinue(n):
    var labl = newSym(skLabel, nil, getCurrOwner(c))
    labl.name = getIdent(genPrefix & $labl.id)
    labl.info = n.info
    c.blockSyms.add(labl)

    result = newTransNode(nkBlockStmt, n.info, 2)
    result[0] = newSymNode(labl).PTransNode
    result[1] = transform(c, n)
    discard c.blockSyms.pop()
  else: 
    result = transform(c, n)

proc skipConv(n: PNode): PNode = 
  case n.kind
  of nkObjUpConv, nkObjDownConv, nkPassAsOpenArray, nkChckRange, nkChckRangeF, 
     nkChckRange64: 
    result = n.sons[0]
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    result = n.sons[1]
  else: result = n
  
proc newTupleAccess(tup: PNode, i: int): PNode = 
  result = newNodeIT(nkBracketExpr, tup.info, tup.typ.sons[i])
  addSon(result, copyTree(tup))
  var lit = newNodeIT(nkIntLit, tup.info, getSysType(tyInt))
  lit.intVal = i
  addSon(result, lit)

proc unpackTuple(c: PTransf, n: PNode, father: PTransNode) = 
  # XXX: BUG: what if `n` is an expression with side-effects?
  for i in countup(0, sonsLen(c.transCon.forStmt) - 3): 
    add(father, newAsgnStmt(c, c.transCon.forStmt.sons[i], 
        transform(c, newTupleAccess(n, i))))

proc introduceNewLocalVars(c: PTransf, n: PNode): PTransNode = 
  case n.kind
  of nkSym: 
    return transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: 
    # nothing to be done for leaves:
    result = PTransNode(n)
  of nkVarSection:
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
    add(result, introduceNewLocalVars(c, c.transCon.forLoopBody.pnode))

proc addVar(father, v: PNode) = 
  var vpart = newNodeI(nkIdentDefs, v.info)
  addSon(vpart, v)
  addSon(vpart, ast.emptyNode)
  addSon(vpart, ast.emptyNode)
  addSon(father, vpart)

proc transformAddrDeref(c: PTransf, n: PNode, a, b: TNodeKind): PTransNode = 
  case n.sons[0].kind
  of nkObjUpConv, nkObjDownConv, nkPassAsOpenArray, nkChckRange, nkChckRangeF, 
     nkChckRange64: 
    var m = n.sons[0].sons[0]
    if (m.kind == a) or (m.kind == b): 
      # addr ( nkPassAsOpenArray ( deref ( x ) ) ) --> nkPassAsOpenArray(x)
      var x = copyTree(n)
      x.sons[0].sons[0] = m.sons[0]
      result = transform(c, x.sons[0])
    else: 
      result = transformSons(c, n)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    var m = n.sons[0].sons[1]
    if (m.kind == a) or (m.kind == b): 
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      var x = copyTree(n)
      x.sons[0].sons[1] = m.sons[0]
      result = transform(c, x.sons[0])
    else:
      result = transformSons(c, n)
  else: 
    if (n.sons[0].kind == a) or (n.sons[0].kind == b): 
      # addr ( deref ( x )) --> x
      result = transform(c, n.sons[0].sons[0])
    else:
      result = transformSons(c, n)

proc transformConv(c: PTransf, n: PNode): PTransNode = 
  # numeric types need range checks:
  var dest = skipTypes(n.typ, abstractVarRange)
  var source = skipTypes(n.sons[1].typ, abstractVarRange)
  case dest.kind
  of tyInt..tyInt64, tyEnum, tyChar, tyBool: 
    if not isOrdinalType(source):
      # XXX int64 -> float conversion?
      result = transformSons(c, n)
    elif firstOrd(dest) <= firstOrd(source) and
        lastOrd(source) <= lastOrd(dest): 
      # BUGFIX: simply leave n as it is; we need a nkConv node,
      # but no range check:
      result = transformSons(c, n)
    else: 
      # generate a range check:
      if (dest.kind == tyInt64) or (source.kind == tyInt64): 
        result = newTransNode(nkChckRange64, n, 3)
      else: 
        result = newTransNode(nkChckRange, n, 3)
      dest = skipTypes(n.typ, abstractVar)
      result[0] = transform(c, n.sons[1])
      result[1] = newIntTypeNode(nkIntLit, firstOrd(dest), source).PTransNode
      result[2] = newIntTypeNode(nkIntLit, lastOrd(dest), source).PTransNode
  of tyFloat..tyFloat128: 
    if skipTypes(n.typ, abstractVar).kind == tyRange: 
      result = newTransNode(nkChckRangeF, n, 3)
      dest = skipTypes(n.typ, abstractVar)
      result[0] = transform(c, n.sons[1])
      result[1] = copyTree(dest.n.sons[0]).PTransNode
      result[2] = copyTree(dest.n.sons[1]).PTransNode
    else:
      result = transformSons(c, n)
  of tyOpenArray: 
    result = newTransNode(nkPassAsOpenArray, n, 1)
    result[0] = transform(c, n.sons[1])
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
      elif diff > 0: 
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
    elif diff > 0: 
      result = newTransNode(nkObjDownConv, n, 1)
      result[0] = transform(c, n.sons[1])
    else: 
      result = transform(c, n.sons[1])
  of tyGenericParam, tyOrdinal: 
    result = transform(c, n.sons[1])
    # happens sometimes for generated assignments, etc.
  else: 
    result = transformSons(c, n)

proc skipPassAsOpenArray(n: PNode): PNode = 
  result = n
  while result.kind == nkPassAsOpenArray: result = result.sons[0]
  
type 
  TPutArgInto = enum 
    paDirectMapping, paFastAsgn, paVarAsgn

proc putArgInto(arg: PNode, formal: PType): TPutArgInto = 
  # This analyses how to treat the mapping "formal <-> arg" in an
  # inline context.
  if skipTypes(formal, abstractInst).kind == tyOpenArray: 
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
  
proc transformFor(c: PTransf, n: PNode): PTransNode = 
  # generate access statements for the parameters (unless they are constant)
  # put mapping from formal parameters to actual parameters
  if n.kind != nkForStmt: InternalError(n.info, "transformFor")
  #echo "transforming: ", renderTree(n)
  result = newTransNode(nkStmtList, n.info, 0)
  var length = sonsLen(n)
  var loopBody = transformLoopBody(c, n.sons[length-1])
  var v = newNodeI(nkVarSection, n.info)
  for i in countup(0, length - 3): 
    addVar(v, copyTree(n.sons[i])) # declare new vars
  add(result, v.ptransNode)
  var call = n.sons[length - 2]
  if call.kind != nkCall or call.sons[0].kind != nkSym:
    InternalError(call.info, "transformFor")
  
  var newC = newTransCon(call.sons[0].sym)
  newC.forStmt = n
  newC.forLoopBody = loopBody
  if newC.owner.kind != skIterator: InternalError(call.info, "transformFor") 
  # generate access statements for the parameters (unless they are constant)
  pushTransCon(c, newC)
  for i in countup(1, sonsLen(call) - 1): 
    var arg = skipPassAsOpenArray(transform(c, call.sons[i]).pnode)
    var formal = skipTypes(newC.owner.typ, abstractInst).n.sons[i].sym 
    case putArgInto(arg, formal.typ)
    of paDirectMapping: 
      IdNodeTablePut(newC.mapping, formal, arg)
    of paFastAsgn: 
      # generate a temporary and produce an assignment statement:
      var temp = newTemp(c, formal.typ, formal.info)
      addVar(v, newSymNode(temp))
      add(result, newAsgnStmt(c, newSymNode(temp), arg.ptransNode))
      IdNodeTablePut(newC.mapping, formal, newSymNode(temp))
    of paVarAsgn:
      assert(skipTypes(formal.typ, abstractInst).kind == tyVar)
      # XXX why is this even necessary?
      var b = newNodeIT(nkHiddenAddr, arg.info, formal.typ)
      b.add(arg)
      arg = b
      IdNodeTablePut(newC.mapping, formal, arg)
      # XXX BUG still not correct if the arg has a side effect!
      #InternalError(arg.info, "not implemented: pass to var parameter")
  var body = newC.owner.ast.sons[codePos]
  pushInfoContext(n.info)
  inc(c.inlining)
  add(result, transform(c, body))
  dec(c.inlining)
  popInfoContext()
  popTransCon(c)
  #echo "transformed: ", renderTree(n)
  

proc getMagicOp(call: PNode): TMagic = 
  if call.sons[0].kind == nkSym and
      call.sons[0].sym.kind in {skProc, skMethod, skConverter}: 
    result = call.sons[0].sym.magic
  else:
    result = mNone
  
proc gatherVars(c: PTransf, n: PNode, marked: var TIntSet, owner: PSym, 
                container: PNode) = 
  # gather used vars for closure generation
  case n.kind
  of nkSym:
    var s = n.sym
    var found = false
    case s.kind
    of skVar: found = sfGlobal notin s.flags
    of skTemp, skForVar, skParam, skResult: found = true
    else: nil
    if found and owner.id != s.owner.id and not ContainsOrIncl(marked, s.id): 
      incl(s.flags, sfInClosure)
      addSon(container, copyNode(n)) # DON'T make a copy of the symbol!
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: 
    nil
  else: 
    for i in countup(0, sonsLen(n) - 1): 
      gatherVars(c, n.sons[i], marked, owner, container)
  
proc addFormalParam(routine: PSym, param: PSym) = 
  addSon(routine.typ, param.typ)
  addSon(routine.ast.sons[paramsPos], newSymNode(param))

proc indirectAccess(a, b: PSym): PNode = 
  # returns a[].b as a node
  var x = newSymNode(a)
  var y = newSymNode(b)
  var deref = newNodeI(nkHiddenDeref, x.info)
  deref.typ = x.typ.sons[0]
  addSon(deref, x)
  result = newNodeI(nkDotExpr, x.info)
  addSon(result, deref)
  addSon(result, y)
  result.typ = y.typ

proc transformLambda(c: PTransf, n: PNode): PNode = 
  var marked = initIntSet()
  result = n
  if n.sons[namePos].kind != nkSym: InternalError(n.info, "transformLambda")
  var s = n.sons[namePos].sym
  var closure = newNodeI(nkRecList, n.sons[codePos].info)
  gatherVars(c, n.sons[codePos], marked, s, closure) 
  # add closure type to the param list (even if closure is empty!):
  var cl = newType(tyObject, s)
  cl.n = closure
  addSon(cl, nil)             # no super class
  var p = newType(tyRef, s)
  addSon(p, cl)
  var param = newSym(skParam, getIdent(genPrefix & "Cl"), s)
  param.typ = p
  addFormalParam(s, param) 
  # all variables that are accessed should be accessed by the new closure
  # parameter:
  if sonsLen(closure) > 0: 
    var newC = newTransCon(c.transCon.owner)
    for i in countup(0, sonsLen(closure) - 1): 
      IdNodeTablePut(newC.mapping, closure.sons[i].sym, 
                     indirectAccess(param, closure.sons[i].sym))
    pushTransCon(c, newC)
    n.sons[codePos] = transform(c, n.sons[codePos]).pnode
    popTransCon(c)

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
      if ifs.pnode == nil:
        ifs = newTransNode(nkIfStmt, it.info, 0)
      ifs.add(e)
    of nkElse:
      if ifs.pnode == nil: result.add(e)
      else: ifs.add(e)
    else:
      result.add(e)
  if ifs.pnode != nil:
    var elseBranch = newTransNode(nkElse, n.info, 1)
    elseBranch[0] = ifs
    result.add(elseBranch)
  elif result.Pnode.lastSon.kind != nkElse and not (
      skipTypes(n.sons[0].Typ, abstractVarRange).Kind in
        {tyInt..tyInt64, tyChar, tyEnum}):
    # fix a stupid code gen bug by normalizing: 
    var elseBranch = newTransNode(nkElse, n.info, 1)
    elseBranch[0] = newTransNode(nkNilLit, n.info, 0)
    add(result, elseBranch)
  
proc transformArrayAccess(c: PTransf, n: PNode): PTransNode = 
  result = newTransNode(n)
  result[0] = transform(c, skipConv(n.sons[0]))
  result[1] = transform(c, skipConv(n.sons[1]))
  
proc getMergeOp(n: PNode): PSym = 
  case n.kind
  of nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix, 
     nkCallStrLit: 
    if (n.sons[0].Kind == nkSym) and (n.sons[0].sym.kind == skProc) and
        (sfMerge in n.sons[0].sym.flags): 
      result = n.sons[0].sym
  else: nil

proc flattenTreeAux(d, a: PNode, op: PSym) = 
  var op2 = getMergeOp(a)
  if op2 != nil and
      (op2.id == op.id or op.magic != mNone and op2.magic == op.magic): 
    for i in countup(1, sonsLen(a)-1): flattenTreeAux(d, a.sons[i], op)
  else: 
    addSon(d, copyTree(a))
  
proc flattenTree(root: PNode): PNode = 
  var op = getMergeOp(root)
  if op != nil: 
    result = copyNode(root)
    addSon(result, copyTree(root.sons[0]))
    flattenTreeAux(result, root, op)
  else: 
    result = root
  
proc transformCall(c: PTransf, n: PNode): PTransNode = 
  var n = flattenTree(n)
  var op = getMergeOp(n)
  if (op != nil) and (op.magic != mNone) and (sonsLen(n) >= 3): 
    result = newTransNode(nkCall, n, 0)
    add(result, transform(c, n.sons[0]))
    var j = 1
    while j < sonsLen(n): 
      var a = n.sons[j]
      inc(j)
      if isConstExpr(a): 
        while (j < sonsLen(n)) and isConstExpr(n.sons[j]): 
          a = evalOp(op.magic, n, a, n.sons[j], nil)
          inc(j)
      add(result, transform(c, a))
    if len(result) == 2: result = result[1]
  elif n.sons[0].kind == nkSym and n.sons[0].sym.kind == skMethod: 
    # use the dispatcher for the call:
    result = methodCall(transformSons(c, n).pnode).ptransNode
  else:
    result = transformSons(c, n)

proc transform(c: PTransf, n: PNode): PTransNode = 
  case n.kind
  of nkSym: 
    return transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: 
    # nothing to be done for leaves:
    result = PTransNode(n)
  of nkBracketExpr: 
    result = transformArrayAccess(c, n)
  of nkLambda: 
    n.sons[codePos] = PNode(transform(c, n.sons[codePos]))
    result = PTransNode(n)
    when false: result = transformLambda(c, n)
  of nkForStmt: 
    result = transformFor(c, n)
  of nkCaseStmt: 
    result = transformCase(c, n)
  of nkProcDef, nkMethodDef, nkIteratorDef, nkMacroDef, nkConverterDef: 
    if n.sons[genericParamsPos].kind == nkEmpty: 
      n.sons[codePos] = PNode(transform(c, n.sons[codePos]))
      if n.kind == nkMethodDef: methodDef(n.sons[namePos].sym)
    result = PTransNode(n)
  of nkContinueStmt:
    result = PTransNode(newNode(nkBreakStmt))
    var labl = c.blockSyms[c.blockSyms.high]
    add(result, PTransNode(newSymNode(labl)))
  of nkWhileStmt: 
    result = newTransNode(n)
    result[0] = transform(c, n.sons[0])
    result[1] = transformLoopBody(c, n.sons[1])
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
    result = transformSons(c, n)
    if isConstExpr(PNode(result).sons[0]): 
      # ensure that e.g. discard "some comment" gets optimized away completely:
      result = PTransNode(newNode(nkCommentStmt))
  of nkCommentStmt, nkTemplateDef: 
    return n.ptransNode
  of nkConstSection:
    # do not replace ``const c = 3`` with ``const 3 = 3``
    return transformConstSection(c, n)
  of nkVarSection: 
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
  else:
    result = transformSons(c, n)
  var cnst = getConstExpr(c.module, PNode(result))
  if cnst != nil: 
    result = PTransNode(cnst) # do not miss an optimization  
 
proc processTransf(context: PPassContext, n: PNode): PNode = 
  # Note: For interactive mode we cannot call 'passes.skipCodegen' and skip
  # this step! We have to rely that the semantic pass transforms too errornous
  # nodes into an empty node.
  if passes.skipCodegen(n): return n
  var c = PTransf(context)
  pushTransCon(c, newTransCon(getCurrOwner(c)))
  result = PNode(transform(c, n))
  popTransCon(c)

proc openTransf(module: PSym, filename: string): PPassContext = 
  var n: PTransf
  new(n)
  n.blocksyms = @[]
  n.module = module
  result = n

proc transfPass(): TPass = 
  initPass(result)
  result.open = openTransf
  result.process = processTransf
  result.close = processTransf # we need to process generics too!
  
proc transform*(module: PSym, n: PNode): PNode =
  var c = openTransf(module, "")
  result = processTransf(c, n)

