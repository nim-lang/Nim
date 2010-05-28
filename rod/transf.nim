#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
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
# * introduces nkHiddenDeref, nkHiddenSubConv, etc.
# * introduces method dispatchers

import 
  strutils, lists, options, ast, astalgo, trees, treetab, evals, msgs, os, 
  idents, rnimsyn, types, passes, semfold, magicsys, cgmeth

const 
  genPrefix* = ":tmp"         # prefix for generated names

proc transfPass*(): TPass
# implementation

type 
  PTransCon = ref TTransCon
  TTransCon{.final.} = object # part of TContext; stackable
    mapping*: TIdNodeTable    # mapping from symbols to nodes
    owner*: PSym              # current owner
    forStmt*: PNode           # current for stmt
    next*: PTransCon          # for stacking
  
  TTransfContext = object of passes.TPassContext
    module*: PSym
    transCon*: PTransCon      # top of a TransCon stack
  
  PTransf = ref TTransfContext

proc newTransCon(): PTransCon = 
  new(result)
  initIdNodeTable(result.mapping)

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

proc transform(c: PTransf, n: PNode): PNode

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

proc newAsgnStmt(c: PTransf, le, ri: PNode): PNode = 
  result = newNodeI(nkFastAsgn, ri.info)
  addSon(result, le)
  addSon(result, ri)

proc transformSym(c: PTransf, n: PNode): PNode = 
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
    b = n                     #writeln('transformSym', n.sym.id : 5);
  while tc != nil: 
    result = IdNodeTableGet(tc.mapping, b.sym)
    if result != nil: 
      return                  #write('not found in: ');
                              #writeIdNodeTable(tc.mapping);
    tc = tc.next
  result = b
  case b.sym.kind
  of skConst, skEnumField: 
    # BUGFIX: skEnumField was missing
    if not (skipTypes(b.sym.typ, abstractInst).kind in ConstantDataTypes): 
      result = getConstExpr(c.module, b)
      if result == nil: InternalError(b.info, "transformSym: const")
  else: 
    nil

proc transformContinueAux(c: PTransf, n: PNode, labl: PSym, counter: var int) = 
  if n == nil: return 
  case n.kind
  of nkEmpty..nkNilLit, nkForStmt, nkWhileStmt: 
    nil
  of nkContinueStmt: 
    n.kind = nkBreakStmt
    addSon(n, newSymNode(labl))
    inc(counter)
  else: 
    for i in countup(0, sonsLen(n) - 1): 
      transformContinueAux(c, n.sons[i], labl, counter)
  
proc transformContinue(c: PTransf, n: PNode): PNode = 
  # we transform the continue statement into a block statement
  result = n
  for i in countup(0, sonsLen(n) - 1): result.sons[i] = transform(c, n.sons[i])
  var counter = 0
  var labl = newSym(skLabel, nil, getCurrOwner(c))
  labl.name = getIdent(genPrefix & $(labl.id))
  labl.info = result.info
  transformContinueAux(c, result, labl, counter)
  if counter > 0: 
    var x = newNodeI(nkBlockStmt, result.info)
    addSon(x, newSymNode(labl))
    addSon(x, result)
    result = x

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

proc unpackTuple(c: PTransf, n, father: PNode) = 
  # XXX: BUG: what if `n` is an expression with side-effects?
  for i in countup(0, sonsLen(c.transCon.forStmt) - 3): 
    addSon(father, newAsgnStmt(c, c.transCon.forStmt.sons[i], 
                               transform(c, newTupleAccess(n, i))))

proc transformYield(c: PTransf, n: PNode): PNode = 
  result = newNodeI(nkStmtList, n.info)
  var e = n.sons[0]
  if skipTypes(e.typ, {tyGenericInst}).kind == tyTuple: 
    e = skipConv(e)
    if e.kind == nkPar: 
      for i in countup(0, sonsLen(e) - 1): 
        addSon(result, newAsgnStmt(c, c.transCon.forStmt.sons[i], 
                                   transform(c, copyTree(e.sons[i]))))
    else: 
      unpackTuple(c, e, result)
  else: 
    e = transform(c, copyTree(e))
    addSon(result, newAsgnStmt(c, c.transCon.forStmt.sons[0], e))
  addSon(result, transform(c, lastSon(c.transCon.forStmt)))

proc inlineIter(c: PTransf, n: PNode): PNode = 
  result = n
  if n == nil: return 
  case n.kind
  of nkEmpty..nkNilLit: 
    result = transform(c, copyTree(n))
  of nkYieldStmt: 
    result = transformYield(c, n)
  of nkVarSection: 
    result = copyTree(n)
    for i in countup(0, sonsLen(result) - 1): 
      var it = result.sons[i]
      if it.kind == nkCommentStmt: continue 
      if it.kind == nkIdentDefs: 
        if (it.sons[0].kind != nkSym): InternalError(it.info, "inlineIter")
        var newVar = copySym(it.sons[0].sym)
        incl(newVar.flags, sfFromGeneric) 
        # fixes a strange bug for rodgen:
        #include(it.sons[0].sym.flags, sfFromGeneric);
        newVar.owner = getCurrOwner(c)
        IdNodeTablePut(c.transCon.mapping, it.sons[0].sym, newSymNode(newVar))
        it.sons[0] = newSymNode(newVar)
        it.sons[2] = transform(c, it.sons[2])
      else: 
        if it.kind != nkVarTuple: 
          InternalError(it.info, "inlineIter: not nkVarTuple")
        var L = sonsLen(it)
        for j in countup(0, L - 3): 
          var newVar = copySym(it.sons[j].sym)
          incl(newVar.flags, sfFromGeneric)
          newVar.owner = getCurrOwner(c)
          IdNodeTablePut(c.transCon.mapping, it.sons[j].sym, newSymNode(newVar))
          it.sons[j] = newSymNode(newVar)
        assert(it.sons[L - 2] == nil)
        it.sons[L - 1] = transform(c, it.sons[L - 1])
  else: 
    result = copyNode(n)
    for i in countup(0, sonsLen(n) - 1): addSon(result, inlineIter(c, n.sons[i]))
    result = transform(c, result)

proc addVar(father, v: PNode) = 
  var vpart = newNodeI(nkIdentDefs, v.info)
  addSon(vpart, v)
  addSon(vpart, nil)
  addSon(vpart, nil)
  addSon(father, vpart)

proc transformAddrDeref(c: PTransf, n: PNode, a, b: TNodeKind): PNode = 
  case n.sons[0].kind
  of nkObjUpConv, nkObjDownConv, nkPassAsOpenArray, nkChckRange, nkChckRangeF, 
     nkChckRange64: 
    var m = n.sons[0].sons[0]
    if (m.kind == a) or (m.kind == b): 
      # addr ( nkPassAsOpenArray ( deref ( x ) ) ) --> nkPassAsOpenArray(x)
      n.sons[0].sons[0] = m.sons[0]
      return transform(c, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    var m = n.sons[0].sons[1]
    if (m.kind == a) or (m.kind == b): 
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      n.sons[0].sons[1] = m.sons[0]
      return transform(c, n.sons[0])
  else: 
    if (n.sons[0].kind == a) or (n.sons[0].kind == b): 
      # addr ( deref ( x )) --> x
      return transform(c, n.sons[0].sons[0])
  n.sons[0] = transform(c, n.sons[0])
  result = n

proc transformConv(c: PTransf, n: PNode): PNode = 
  n.sons[1] = transform(c, n.sons[1])
  result = n                  # numeric types need range checks:
  var dest = skipTypes(n.typ, abstractVarRange)
  var source = skipTypes(n.sons[1].typ, abstractVarRange)
  case dest.kind
  of tyInt..tyInt64, tyEnum, tyChar, tyBool: 
    if not isOrdinalType(source):
      # XXX int64 -> float conversion?
      result = n
    elif firstOrd(dest) <= firstOrd(source) and
        lastOrd(source) <= lastOrd(dest): 
      # BUGFIX: simply leave n as it is; we need a nkConv node,
      # but no range check:
      result = n
    else: 
      # generate a range check:
      if (dest.kind == tyInt64) or (source.kind == tyInt64): 
        result = newNodeIT(nkChckRange64, n.info, n.typ)
      else: 
        result = newNodeIT(nkChckRange, n.info, n.typ)
      dest = skipTypes(n.typ, abstractVar)
      addSon(result, n.sons[1])
      addSon(result, newIntTypeNode(nkIntLit, firstOrd(dest), source))
      addSon(result, newIntTypeNode(nkIntLit, lastOrd(dest), source))
  of tyFloat..tyFloat128: 
    if skipTypes(n.typ, abstractVar).kind == tyRange: 
      result = newNodeIT(nkChckRangeF, n.info, n.typ)
      dest = skipTypes(n.typ, abstractVar)
      addSon(result, n.sons[1])
      addSon(result, copyTree(dest.n.sons[0]))
      addSon(result, copyTree(dest.n.sons[1]))
  of tyOpenArray: 
    result = newNodeIT(nkPassAsOpenArray, n.info, n.typ)
    addSon(result, n.sons[1])
  of tyCString: 
    if source.kind == tyString: 
      result = newNodeIT(nkStringToCString, n.info, n.typ)
      addSon(result, n.sons[1])
  of tyString: 
    if source.kind == tyCString: 
      result = newNodeIT(nkCStringToString, n.info, n.typ)
      addSon(result, n.sons[1])
  of tyRef, tyPtr: 
    dest = skipTypes(dest, abstractPtrs)
    source = skipTypes(source, abstractPtrs)
    if source.kind == tyObject: 
      var diff = inheritanceDiff(dest, source)
      if diff < 0: 
        result = newNodeIT(nkObjUpConv, n.info, n.typ)
        addSon(result, n.sons[1])
      elif diff > 0: 
        result = newNodeIT(nkObjDownConv, n.info, n.typ)
        addSon(result, n.sons[1])
      else: 
        result = n.sons[1]
  of tyObject: 
    var diff = inheritanceDiff(dest, source)
    if diff < 0: 
      result = newNodeIT(nkObjUpConv, n.info, n.typ)
      addSon(result, n.sons[1])
    elif diff > 0: 
      result = newNodeIT(nkObjDownConv, n.info, n.typ)
      addSon(result, n.sons[1])
    else: 
      result = n.sons[1]
  of tyGenericParam, tyOrdinal: 
    result = n.sons[1] # happens sometimes for generated assignments, etc.
  else: 
    nil

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
  
proc transformFor(c: PTransf, n: PNode): PNode = 
  # generate access statements for the parameters (unless they are constant)
  # put mapping from formal parameters to actual parameters
  if (n.kind != nkForStmt): InternalError(n.info, "transformFor")
  result = newNodeI(nkStmtList, n.info)
  var length = sonsLen(n)
  n.sons[length - 1] = transformContinue(c, n.sons[length - 1])
  var v = newNodeI(nkVarSection, n.info)
  for i in countup(0, length - 3): 
    addVar(v, copyTree(n.sons[i])) # declare new vars
  addSon(result, v)
  var newC = newTransCon()
  var call = n.sons[length - 2]
  if (call.kind != nkCall) or (call.sons[0].kind != nkSym): 
    InternalError(call.info, "transformFor")
  newC.owner = call.sons[0].sym
  newC.forStmt = n
  if (newC.owner.kind != skIterator): 
    InternalError(call.info, "transformFor") 
  # generate access statements for the parameters (unless they are constant)
  pushTransCon(c, newC)
  for i in countup(1, sonsLen(call) - 1): 
    var arg = skipPassAsOpenArray(transform(c, call.sons[i]))
    var formal = skipTypes(newC.owner.typ, abstractInst).n.sons[i].sym 
    #if IdentEq(newc.Owner.name, 'items') then 
    #  liMessage(arg.info, warnUser, 'items: ' + nodeKindToStr[arg.kind]);
    case putArgInto(arg, formal.typ)
    of paDirectMapping: 
      IdNodeTablePut(newC.mapping, formal, arg)
    of paFastAsgn: 
      # generate a temporary and produce an assignment statement:
      var temp = newTemp(c, formal.typ, formal.info)
      addVar(v, newSymNode(temp))
      addSon(result, newAsgnStmt(c, newSymNode(temp), arg))
      IdNodeTablePut(newC.mapping, formal, newSymNode(temp))
    of paVarAsgn: 
      assert(skipTypes(formal.typ, abstractInst).kind == tyVar)
      InternalError(arg.info, "not implemented: pass to var parameter")
  var body = newC.owner.ast.sons[codePos]
  pushInfoContext(n.info)
  addSon(result, inlineIter(c, body))
  popInfoContext()
  popTransCon(c)

proc getMagicOp(call: PNode): TMagic = 
  if (call.sons[0].kind == nkSym) and
      (call.sons[0].sym.kind in {skProc, skMethod, skConverter}): 
    result = call.sons[0].sym.magic
  else: 
    result = mNone
  
proc gatherVars(c: PTransf, n: PNode, marked: var TIntSet, owner: PSym, 
                container: PNode) = 
  # gather used vars for closure generation
  if n == nil: return 
  case n.kind
  of nkSym: 
    var s = n.sym
    var found = false
    case s.kind
    of skVar: found = not (sfGlobal in s.flags)
    of skTemp, skForVar, skParam: found = true
    else: nil
    if found and (owner.id != s.owner.id) and
        not IntSetContainsOrIncl(marked, s.id): 
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
  # returns a^ .b as a node
  var x = newSymNode(a)
  var y = newSymNode(b)
  var deref = newNodeI(nkDerefExpr, x.info)
  deref.typ = x.typ.sons[0]
  addSon(deref, x)
  result = newNodeI(nkDotExpr, x.info)
  addSon(result, deref)
  addSon(result, y)
  result.typ = y.typ

proc transformLambda(c: PTransf, n: PNode): PNode = 
  var marked: TIntSet
  result = n
  IntSetInit(marked)
  if (n.sons[namePos].kind != nkSym): InternalError(n.info, "transformLambda")
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
    var newC = newTransCon()
    for i in countup(0, sonsLen(closure) - 1): 
      IdNodeTablePut(newC.mapping, closure.sons[i].sym, 
                     indirectAccess(param, closure.sons[i].sym))
    pushTransCon(c, newC)
    n.sons[codePos] = transform(c, n.sons[codePos])
    popTransCon(c)

proc transformCase(c: PTransf, n: PNode): PNode = 
  # removes `elif` branches of a case stmt
  # adds ``else: nil`` if needed for the code generator
  var length = sonsLen(n)
  var i = length - 1
  if n.sons[i].kind == nkElse: dec(i)
  if n.sons[i].kind == nkElifBranch: 
    while n.sons[i].kind == nkElifBranch: dec(i)
    if (n.sons[i].kind != nkOfBranch): 
      InternalError(n.sons[i].info, "transformCase")
    var ifs = newNodeI(nkIfStmt, n.sons[i + 1].info)
    var elsen = newNodeI(nkElse, ifs.info)
    for j in countup(i + 1, length - 1): addSon(ifs, n.sons[j])
    setlen(n.sons, i + 2)
    addSon(elsen, ifs)
    n.sons[i + 1] = elsen
  elif (n.sons[length - 1].kind != nkElse) and
      not (skipTypes(n.sons[0].Typ, abstractVarRange).Kind in
      {tyInt..tyInt64, tyChar, tyEnum}): 
    #MessageOut(renderTree(n));
    var elsen = newNodeI(nkElse, n.info)
    addSon(elsen, newNodeI(nkNilLit, n.info))
    addSon(n, elsen)
  result = n
  for j in countup(0, sonsLen(n) - 1): result.sons[j] = transform(c, n.sons[j])
  
proc transformArrayAccess(c: PTransf, n: PNode): PNode = 
  result = copyTree(n)
  result.sons[0] = skipConv(result.sons[0])
  result.sons[1] = skipConv(result.sons[1])
  for i in countup(0, sonsLen(result) - 1): 
    result.sons[i] = transform(c, result.sons[i])
  
proc getMergeOp(n: PNode): PSym = 
  result = nil
  case n.kind
  of nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix, 
     nkCallStrLit: 
    if (n.sons[0].Kind == nkSym) and (n.sons[0].sym.kind == skProc) and
        (sfMerge in n.sons[0].sym.flags): 
      result = n.sons[0].sym
  else: 
    nil

proc flattenTreeAux(d, a: PNode, op: PSym) = 
  var op2 = getMergeOp(a)
  if op2 != nil and
      (op2.id == op.id or op.magic != mNone and op2.magic == op.magic): 
    for i in countup(1, sonsLen(a) - 1): flattenTreeAux(d, a.sons[i], op)
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
  
proc transformCall(c: PTransf, n: PNode): PNode = 
  result = flattenTree(n)
  for i in countup(0, sonsLen(result) - 1): 
    result.sons[i] = transform(c, result.sons[i])
  var op = getMergeOp(result)
  if (op != nil) and (op.magic != mNone) and (sonsLen(result) >= 3): 
    var m = result
    result = newNodeIT(nkCall, m.info, m.typ)
    addSon(result, copyTree(m.sons[0]))
    var j = 1
    while j < sonsLen(m): 
      var a = m.sons[j]
      inc(j)
      if isConstExpr(a): 
        while (j < sonsLen(m)) and isConstExpr(m.sons[j]): 
          a = evalOp(op.magic, m, a, m.sons[j], nil)
          inc(j)
      addSon(result, a)
    if sonsLen(result) == 2: result = result.sons[1]
  elif (result.sons[0].kind == nkSym) and
      (result.sons[0].sym.kind == skMethod): 
    # use the dispatcher for the call:
    result = methodCall(result)

proc transform(c: PTransf, n: PNode): PNode = 
  result = n
  if n == nil: return
  case n.kind
  of nkSym: 
    return transformSym(c, n)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: 
    # nothing to be done for leaves
  of nkBracketExpr: 
    result = transformArrayAccess(c, n)
  of nkLambda: 
    result = transformLambda(c, n)
  of nkForStmt: 
    result = transformFor(c, n)
  of nkCaseStmt: 
    result = transformCase(c, n)
  of nkProcDef, nkMethodDef, nkIteratorDef, nkMacroDef: 
    if n.sons[genericParamsPos] == nil: 
      n.sons[codePos] = transform(c, n.sons[codePos])
      if n.kind == nkMethodDef: methodDef(n.sons[namePos].sym)
  of nkWhileStmt: 
    if (sonsLen(n) != 2): InternalError(n.info, "transform")
    n.sons[0] = transform(c, n.sons[0])
    n.sons[1] = transformContinue(c, n.sons[1])
  of nkCall, nkHiddenCallConv, nkCommand, nkInfix, nkPrefix, nkPostfix, 
     nkCallStrLit: 
    result = transformCall(c, result)
  of nkAddr, nkHiddenAddr: 
    result = transformAddrDeref(c, n, nkDerefExpr, nkHiddenDeref)
  of nkDerefExpr, nkHiddenDeref: 
    result = transformAddrDeref(c, n, nkAddr, nkHiddenAddr)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    result = transformConv(c, n)
  of nkDiscardStmt: 
    for i in countup(0, sonsLen(n) - 1): result.sons[i] = transform(c, n.sons[i])
    if isConstExpr(result.sons[0]): result = newNode(nkCommentStmt)
  of nkCommentStmt, nkTemplateDef: 
    return 
  of nkConstSection: 
    # do not replace ``const c = 3`` with ``const 3 = 3``
    return                    
  else: 
    for i in countup(0, sonsLen(n) - 1): result.sons[i] = transform(c, n.sons[i])
  var cnst = getConstExpr(c.module, result)
  if cnst != nil: 
    result = cnst             # do not miss an optimization  
  
proc processTransf(context: PPassContext, n: PNode): PNode = 
  var c = PTransf(context)
  result = transform(c, n)

proc openTransf(module: PSym, filename: string): PPassContext = 
  var n: PTransf
  new(n)
  n.module = module
  result = n

proc transfPass(): TPass = 
  initPass(result)
  result.open = openTransf
  result.process = processTransf
  result.close = processTransf # we need to process generics too!
  
