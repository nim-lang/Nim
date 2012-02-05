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
  procDefs = {nkLambda, nkProcDef, nkMethodDef, nkIteratorDef, nkMacroDef,
     nkConverterDef}

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

proc gatherVars(c: PTransf, n: PNode, outerProc: PSym, cap: var TCapture) = 
  # gather used vars for closure generation into 'cap'
  case n.kind
  of nkSym:
    var s = n.sym
    var found = false
    case s.kind
    of skVar, skLet: found = sfGlobal notin s.flags
    of skTemp, skForVar, skParam, skResult: found = true
    else: nil
    if found and outerProc.id == s.owner.id:
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
      var found = false
      case s.kind
      of skVar, skLet: found = sfGlobal notin s.flags
      of skTemp, skForVar, skParam, skResult: found = true
      else: nil
      if found and outerProc.id == s.owner.id:
        # access through the closure param:
        n.sons[i] = indirectAccess(env, s, n.info)
    else:
      replaceVars(c, a, outerProc, env)

proc addFormalParam(routine: PType, param: PSym) =
  addSon(routine, param.typ)
  addSon(routine.n, newSymNode(param))

proc addFormalParam(routine: PSym, param: PSym) = 
  #addFormalParam(routine.typ, param)
  addSon(routine.ast.sons[paramsPos], newSymNode(param))

proc isInnerProc(s, outerProc: PSym): bool {.inline.} =
  result = s.kind in {skProc, skMacro, skIterator, skMethod, skConverter} and
    s.owner.id == outerProc.id and not isGenericRoutine(s) and
    s.typ.callConv == ccClosure

proc searchForInnerProcs(c: PTransf, n: PNode, outerProc: PSym,
                         cap: var TCapture) =
  case n.kind
  of nkSym:
    let s = n.sym
    if isInnerProc(s, outerProc):
      gatherVars(c, s.getBody, outerProc, cap)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in 0.. <len(n):
      searchForInnerProcs(c, n.sons[i], outerProc, cap)
  
proc makeClosure(c: PTransf, prc, env: PSym, info: TLineInfo): PNode =
  result = newNodeIT(nkClosure, info, prc.typ)
  result.add(newSymNode(prc))
  result.add(newSymNode(env))
  
proc transformInnerProcs(c: PTransf, n: PNode, outerProc, env: PSym) =
  case n.kind
  of nkSym:
    let innerProc = n.sym
    if isInnerProc(innerProc, outerProc):
      # inner proc could capture outer vars:
      var param = newTemp(c, env.typ, n.info)
      param.kind = skParam
      addFormalParam(innerProc, param)
      # 'anon' should be replaced by '(anon, env)':
      IdNodeTablePut(c.transCon.mapping, innerProc, 
                     makeClosure(c, innerProc, env, n.info))
      # access all non-local vars through the 'env' param:
      var body = innerProc.getBody
      # XXX does not work with recursion!
      replaceVars(c, body, outerProc, param)
      innerProc.ast.sons[bodyPos] = body
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in 0.. <len(n):
      transformInnerProcs(c, n.sons[i], outerProc, env)

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
  # to be safe: XXX this a mystery how it could ever happen that: s.ast != n.
  s.ast.sons[bodyPos] = n.sons[bodyPos]
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
  if body.kind == nkEmpty:
    return PTransNode(n)    
  
  if not containsNode(body, procDefs):
    # fast path: no inner procs, so no closure needed:
    n.sons[bodyPos] = PNode(transform(c, body))
    return transformProcFin(c, n, s)

  # create environment:
  var cap: TCapture = @[]
  searchForInnerProcs(c, body, s, cap)
  
  if cap.len == 0:
    # fast path: no captured variables, so no closure needed:
    n.sons[bodyPos] = PNode(transform(c, body))
    return transformProcFin(c, n, s)
  
  var envType = newType(tyRef, s)
  addSon(envType, captureToTuple(cap, s))
  
  # Currently we always do a heap allocation. A simple escape analysis
  # could turn the closure into a stack allocation. Later versions might 
  # implement that. This would require backend changes too though.
  var envSym = newTemp(c, envType, s.info)
  
  var newBody = createEnvStmt(c, cap, envSym)
  # modify any local proc to gain a new parameter; this also creates the
  # mapping entries that turn (localProc) into (localProc, env):
  transformInnerProcs(c, body, s, envSym)

  # now we can transform 'body' as all rewriting entries have been created.
  # Careful this transforms the inner procs too!
  newBody.add(transform(c, body))
  n.sons[bodyPos] = newBody.pnode
  result = transformProcFin(c, n, s)

proc generateThunk(c: PTransf, prc: PNode, dest: PType): PNode =
  ## Converts 'prc' into '(thunk, nil)' so that it's compatible with
  ## a closure.
  
  # XXX we hack around here by generating a 'cast' instead of a proper thunk.
  result = newNodeIT(nkClosure, prc.info, dest)
  var conv = newNodeIT(nkHiddenStdConv, prc.info, dest)
  conv.add(emptyNode)
  conv.add(prc)
  result.add(conv)
  result.add(newNodeIT(nkNilLit, prc.info, getSysType(tyNil)))
  

