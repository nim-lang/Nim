#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements lambda lifting for the transformator.

# - Things to consider: Does capturing of 'result' work? (unknown)
# - Do generic inner procs work? (should)
# - Does nesting of closures work? (not yet)
# - Test that iterators within closures work etc.

const
  procDefs = {nkLambda, nkProcDef, nkMethodDef, nkIteratorDef, nkMacroDef,
     nkConverterDef}

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

proc Incl(container: PNode, s: PSym) =
  for x in container:
    if x.sym.id == s.id: return
  container.add(newSymNode(s))

proc gatherVars(c: PTransf, n: PNode, owner: PSym, container: PNode) = 
  # gather used vars for closure generation
  case n.kind
  of nkSym:
    var s = n.sym
    var found = false
    case s.kind
    of skVar, skLet: found = sfGlobal notin s.flags
    of skTemp, skForVar, skParam, skResult: found = true
    else: nil
    if found and owner.id != s.owner.id:
      incl(container, s)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else: 
    for i in countup(0, sonsLen(n) - 1): 
      gatherVars(c, n.sons[i], owner, container)

proc replaceVars(c: PTransf, n: PNode, owner, env: PSym) = 
  for i in countup(0, safeLen(n) - 1):
    if n.kind == nkSym:
      let s = n.sym
      var found = false
      case s.kind
      of skVar, skLet: found = sfGlobal notin s.flags
      of skTemp, skForVar, skParam, skResult: found = true
      else: nil
      if found and owner.id != s.owner.id:
        # access through the closure param:
        n.sons[i] = indirectAccess(env, s)
    else:
      replaceVars(c, n.sons[i], owner, env)
 
proc addFormalParam(routine: PSym, param: PSym) = 
  addSon(routine.typ, param.typ)
  addSon(routine.ast.sons[paramsPos], newSymNode(param))

proc isInnerProc(s, owner: PSym): bool {.inline.} =
  result = s.kind in {skProc, skMacro, skIterator, skMethod, skConverter} and
    s.owner.id == owner.id and not isGenericRoutine(s)

proc searchForInnerProcs(c: PTransf, n: PNode, owner: PSym, container: PNode) =
  case n.kind
  of nkSym:
    let s = n.sym
    if isInnerProc(s, owner):
      gatherVars(c, s.getBody, owner, container)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in 0.. <len(n):
      searchForInnerProcs(c, n.sons[i], owner, container)
  
proc makeClosure(c: PTransf, prc, env: PSym): PNode =
  var tup = newType(tyTuple, c.module)
  tup.addson(prc.typ)
  tup.addson(env.typ)
  result = newNodeIT(nkPar, prc.info, tup)
  result.add(newSymNode(prc))
  result.add(newSymNode(env))
  
proc transformInnerProcs(c: PTransf, n: PNode, owner, env: PSym) =
  case n.kind
  of nkSym:
    let innerProc = n.sym
    if isInnerProc(innerProc, owner):
      # inner proc could capture outer vars:
      var param = newTemp(c, env.typ, n.info)
      param.kind = skParam
      addFormalParam(innerProc, param)
      # 'anon' should be replaced by '(anon, env)':
      IdNodeTablePut(c.transCon.mapping, innerProc, 
                     makeClosure(c, innerProc, env))
      
      # access all non-local vars through the 'env' param:
      var body = innerProc.getBody
      replaceVars(c, body, innerProc, param)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for i in 0.. <len(n):
      transformInnerProcs(c, n.sons[i], owner, env)

proc newCall(a, b: PSym): PNode =
  result = newNodeI(nkCall, a.info)
  result.add newSymNode(a)
  result.add newSymNode(b)

proc createEnvStmt(c: PTransf, varList: PNode, env: PSym): PTransNode =
  # 'varlist' can contain parameters or variables. We don't eliminate yet
  # local vars that end up in an environment. This could even be a for loop
  # var!
  result = newTransNode(nkStmtList, env.info, 0)
  var v = newNodeI(nkVarSection, env.info)
  addVar(v, newSymNode(env))
  result.add(v.ptransNode)
  # add 'new' statement:
  result.add(newCall(getSysSym"new", env).ptransnode)
  
  # add assignment statements:
  for v in varList:
    assert v.kind == nkSym
    let fieldAccess = indirectAccess(env, v.sym)
    if v.sym.kind == skParam:
      # add ``env.param = param``
      result.add(newAsgnStmt(c, fieldAccess, v.ptransNode))
    IdNodeTablePut(c.transCon.mapping, v.sym, fieldAccess)
  
proc transformProc(c: PTransf, n: PNode): PTransNode =
  # don't process generics:
  if n.sons[genericParamsPos].kind != nkEmpty:
    return PTransNode(n)
  
  var s = n.sons[namePos].sym
  var body = s.getBody
  if not containsNode(body, procDefs):
    # fast path: no inner procs, so no closure needed:
    n.sons[bodyPos] = PNode(transform(c, body))
    if n.kind == nkMethodDef: methodDef(s, false)
    return PTransNode(n)

  var closure = newNodeI(nkRecList, n.info)
  searchForInnerProcs(c, body, s, closure)
  
  if closure.len == 0:
    # fast path: no captured variables, so no closure needed:
    n.sons[bodyPos] = PNode(transform(c, body))
    if n.kind == nkMethodDef: methodDef(s, false)
    return PTransNode(n)
  
  # create environment:
  var envDesc = newType(tyObject, s)
  envDesc.n = closure
  addSon(envDesc, nil) # no super class
  var envType = newType(tyRef, s)
  addSon(envType, envDesc)
  
  # XXX currently we always do a heap allocation. A simple escape analysis
  # could turn the closure into a stack allocation. Later versions will 
  # implement that.
  var envSym = newTemp(c, envType, s.info)
  
  var newBody = createEnvStmt(c, closure, envSym)
  # modify any local proc to gain a new parameter; this also creates the
  # mapping entries that turn (localProc) into (localProc, env):
  transformInnerProcs(c, body, s, envSym)

  # now we can transform 'body' as all rewriting entries have been created.
  # Careful this transforms the inner procs too!
  newBody.add(transform(c, body))
  n.sons[bodyPos] = newBody.pnode
  if n.kind == nkMethodDef: methodDef(s, false)
  result = newBody

proc generateThunk(c: PTransf, prc: PNode, closure: PType): PNode =
  ## Converts 'prc' into '(thunk, nil)' so that it's compatible with
  ## a closure.
  
  # XXX we hack around here by generating a 'cast' instead of a proper thunk.
  result = newNodeIT(nkPar, prc.info, closure)
  var conv = newNodeIT(nkHiddenStdConv, prc.info, closure.sons[0])
  conv.add(emptyNode)
  conv.add(prc)
  result.add(conv)
  result.add(newNodeIT(nkNilLit, prc.info, closure.sons[1]))
  

