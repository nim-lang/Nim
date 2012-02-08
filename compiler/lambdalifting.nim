#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements lambda lifting for the transformator.

const
  declarativeDefs = {nkProcDef, nkMethodDef, nkIteratorDef,
     nkConverterDef}
  procDefs = {nkLambda} + declarativeDefs

proc indirectAccess(a, b: PSym, info: TLineInfo): PNode = 
  # returns a[].b as a node
  let x = newSymNode(a)
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = x.typ.sons[0]
  
  let field = getSymFromList(deref.typ.n, b.name)
  addSon(deref, x)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

type
  TCapture = seq[PSym]

proc Capture(cap: var TCapture, s: PSym) = 
  for x in cap:
    if x.name.id == s.name.id: return
  cap.add(s)

proc captureToTuple(cap: TCapture, owner: PSym): PType =
  result = newType(tyTuple, owner)
  result.n = newNodeI(nkRecList, owner.info)
  for s in cap:
    var field = newSym(skField, s.name, s.owner)
    
    let typ = s.typ
    field.typ = typ
    field.position = sonsLen(result)
    
    addSon(result.n, newSymNode(field))
    addSon(result, typ)

proc interestingVar(s: PSym): bool {.inline.} =
  result = s.kind in {skVar, skLet, skTemp, skForVar, skParam, skResult} and
    sfGlobal notin s.flags

proc gatherVars(c: PTransf, n: PNode, outerProc: PSym, cap: var TCapture) = 
  # gather used vars for closure generation into 'cap'
  case n.kind
  of nkSym:
    var s = n.sym
    if interestingVar(s) and outerProc.id == s.owner.id:
      #echo "captured: ", s.name.s
      Capture(cap, s)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in countup(0, sonsLen(n) - 1): 
      gatherVars(c, n.sons[i], outerProc, cap)

proc replaceVars(c: PTransf, n: PNode, outerProc, env: PSym) = 
  for i in countup(0, safeLen(n) - 1):
    let a = n.sons[i]
    if a.kind == nkSym:
      let s = a.sym
      if interestingVar(s) and outerProc == s.owner:
        # access through the closure param:
        n.sons[i] = indirectAccess(env, s, n.info)
    else:
      replaceVars(c, a, outerProc, env)

proc addHiddenParam(routine: PSym, param: PSym) =
  var params = routine.ast.sons[paramsPos]
  let L = params.len-1
  param.position = L
  if L >= 0:
    # update if we already added a hidden parameter:
    if params.sons[L].kind == nkSym and params.sons[L].sym.kind == skParam: 
      params.sons[L].sym = param
      return
  addSon(params, newSymNode(param))
  #echo "produced environment: ", param.id, " for ", routine.name.s

proc isInnerProc(s, outerProc: PSym): bool {.inline.} =
  result = s.kind in {skProc, skMacro, skIterator, skMethod, skConverter} and
    s.owner == outerProc and not isGenericRoutine(s)
  #s.typ.callConv == ccClosure

proc searchForInnerProcs(c: PTransf, n: PNode, outerProc: PSym,
                         cap: var TCapture) =
  case n.kind
  of nkSym:
    if isInnerProc(n.sym, outerProc):
      gatherVars(c, n.sym.getBody, outerProc, cap)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in 0.. <len(n):
      searchForInnerProcs(c, n.sons[i], outerProc, cap)
  
proc makeClosure(c: PTransf, prc, env: PSym, info: TLineInfo): PNode =
  result = newNodeIT(nkClosure, info, prc.typ)
  result.add(newSymNode(prc))
  if env == nil:
    result.add(newNodeIT(nkNilLit, info, getSysType(tyNil)))
  else:
    result.add(newSymNode(env))
  
proc transformInnerProcs(c: PTransf, n: PNode, outerProc, env: PSym) =
  case n.kind
  of nkSym:
    let innerProc = n.sym
    if isInnerProc(innerProc, outerProc) and not 
        containsOrIncl(c.transformedInnerProcs, innerProc.id):
      if env == nil:
        innerProc.ast.sons[bodyPos] = transform(c, innerProc.getBody).pnode
      else:
        # inner proc could capture outer vars:
        var param = newTemp(c, env.typ, n.info)
        param.kind = skParam
        
        # recursive calls go through (f, hiddenParam):
        IdNodeTablePut(c.transCon.mapping, innerProc, 
                       makeClosure(c, innerProc, param, n.info))
        # access all non-local vars through the 'env' param:
        replaceVars(c, innerProc.getBody, outerProc, param)

        innerProc.ast.sons[bodyPos] = transform(c, innerProc.getBody).pnode
        addHiddenParam(innerProc, param)
        
        # 'anon' should be replaced by '(anon, env)' in the outer proc:
        IdNodeTablePut(c.transCon.mapping, innerProc, 
                       makeClosure(c, innerProc, env, n.info))
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in 0.. <len(n):
      transformInnerProcs(c, n.sons[i], outerProc, env)
  
template checkInvariant(n: PNode, s: PSym) =
  when false:
    if s.ast != n:
      echo renderTree(s.ast)
      echo " -------------- "
      echo n.renderTree
    assert s.ast == n

proc newCall(a, b: PSym): PNode =
  result = newNodeI(nkCall, a.info)
  result.add newSymNode(a)
  result.add newSymNode(b)

proc createEnvStmt(c: PTransf, varList: TCapture, env: PSym): PTransNode =
  # 'varlist' can contain parameters or variables. We don't eliminate yet
  # local vars that end up in an environment. This could even be a for loop
  # var!
  result = newTransNode(nkStmtList, env.info, 0)
  var v = newNodeI(nkVarSection, env.info)
  addVar(v, newSymNode(env))
  result.add(v.ptransNode)
  # add 'new' statement:
  result.add(newCall(getSysSym"internalNew", env).ptransnode)
  
  # add assignment statements:
  for v in varList:
    let fieldAccess = indirectAccess(env, v, env.info)
    if v.kind == skParam:
      # add ``env.param = param``
      result.add(newAsgnStmt(c, fieldAccess, newSymNode(v).ptransNode))
    IdNodeTablePut(c.transCon.mapping, v, fieldAccess)
  
proc transformProcFin(c: PTransf, n: PNode, s: PSym): PTransNode =
  if n.kind == nkLambda:
    # for lambdas we transformed 'n.sons[bodyPos]', but not 'ast.n[bodyPos]'!
    s.ast.sons[bodyPos] = n.sons[bodyPos]
  else:
    assert s.ast == n
  
  if n.kind == nkMethodDef: methodDef(s, false)
  # should 's' be replaced by a tuple ('s', env)?
  var tc = c.transCon
  var repl: PNode = nil
  while tc != nil:
    repl = IdNodeTableGet(tc.mapping, s)
    if repl != nil: break
    tc = tc.next
  if repl != nil:
    result = PTransNode(repl)
  else:
    result = PTransNode(n)

proc transformProc(c: PTransf, n: PNode): PTransNode =
  # don't process generics:
  if n.sons[genericParamsPos].kind != nkEmpty:
    return PTransNode(n)
  
  var s = n.sons[namePos].sym
  var body = s.getBody
  if body.kind == nkEmpty or n.sons[bodyPos].kind == nkEmpty or
     containsOrIncl(c.transformedInnerProcs, s.id):
    return PTransNode(n)
    
  checkInvariant(n, s)
  
  if not containsNode(body, procDefs) and s.typ.callConv != ccClosure:
    # fast path: no inner procs, so no closure needed:
    n.sons[bodyPos] = PNode(transform(c, body))
    checkInvariant(n, s)
    return transformProcFin(c, n, s)

  # create environment:
  var cap: TCapture = @[]
  searchForInnerProcs(c, body, s, cap)

  var envType = newType(tyRef, s)
  addSon(envType, captureToTuple(cap, s))
  if s.typ.callConv == ccClosure:
    addHiddenParam(s, newTemp(c, envType, n.info))
    IdNodeTablePut(c.transCon.mapping, s, 
                   makeClosure(c, s, nil, n.info))
  
  if cap.len == 0:
    # fast path: no captured variables, so no closure needed:
    transformInnerProcs(c, body, s, nil)
    n.sons[bodyPos] = PNode(transform(c, body))
    return transformProcFin(c, n, s)
  
  # Currently we always do a heap allocation. A simple escape analysis
  # could turn the closure into a stack allocation. Later versions might 
  # implement that. This would require backend changes too though.
  var envSym = newTemp(c, envType, s.info)
  
  var newBody = createEnvStmt(c, cap, envSym)
  # modify any local proc to gain a new parameter; this also creates the
  # mapping entries that turn (localProc) into (localProc, env):
  transformInnerProcs(c, body, s, envSym)

  # now we can transform 'body' as all rewriting entries have been created:
  newBody.add(transform(c, body))
  n.sons[bodyPos] = newBody.pnode
  result = transformProcFin(c, n, s)
  checkInvariant(n, s)

proc generateThunk(c: PTransf, prc: PNode, dest: PType): PNode =
  ## Converts 'prc' into '(thunk, nil)' so that it's compatible with
  ## a closure.
  
  # we cannot generate a proper thunk here for GC-safety reasons (see internal
  # documentation):
  result = newNodeIT(nkClosure, prc.info, dest)
  var conv = newNodeIT(nkHiddenStdConv, prc.info, dest)
  conv.add(emptyNode)
  conv.add(prc)
  result.add(conv)
  result.add(newNodeIT(nkNilLit, prc.info, getSysType(tyNil)))
  

