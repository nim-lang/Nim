#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the instantiation of generic procs.

proc instantiateGenericParamList(c: PContext, n: PNode, pt: TIdTable) = 
  if (n.kind != nkGenericParams): 
    InternalError(n.info, "instantiateGenericParamList; no generic params")
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind != nkSym: 
      InternalError(a.info, "instantiateGenericParamList; no symbol")
    var q = a.sym
    if not (q.typ.kind in {tyTypeDesc, tyGenericParam}): continue 
    var s = newSym(skType, q.name, getCurrOwner())
    var t = PType(IdTableGet(pt, q.typ))
    if t == nil: 
      LocalError(a.info, errCannotInstantiateX, s.name.s)
      break
    if (t.kind == tyGenericParam): 
      InternalError(a.info, "instantiateGenericParamList: " & q.name.s)
    s.typ = t
    addDecl(c, s)

proc GenericCacheGet(c: PContext, genericSym, instSym: PSym): PSym = 
  result = nil
  for i in countup(0, sonsLen(c.generics) - 1): 
    if c.generics.sons[i].kind != nkExprEqExpr: 
      InternalError(genericSym.info, "GenericCacheGet")
    var a = c.generics.sons[i].sons[0].sym
    if genericSym.id == a.id: 
      var b = c.generics.sons[i].sons[1].sym
      if equalParams(b.typ.n, instSym.typ.n) == paramsEqual: 
        #if gVerbosity > 0 then 
        #  MessageOut('found in cache: ' + getProcHeader(instSym));
        return b

proc GenericCacheAdd(c: PContext, genericSym, instSym: PSym) = 
  var n = newNode(nkExprEqExpr)
  addSon(n, newSymNode(genericSym))
  addSon(n, newSymNode(instSym))
  addSon(c.generics, n)

proc removeDefaultParamValues(n: PNode) = 
  # we remove default params, because they cannot be instantiated properly
  # and they are not needed anyway for instantiation (each param is already
  # provided).
  when false:
    for i in countup(1, sonsLen(n)-1): 
      var a = n.sons[i]
      if a.kind != nkIdentDefs: IllFormedAst(a)
      var L = a.len
      if a.sons[L-1].kind != nkEmpty and a.sons[L-2].kind != nkEmpty:
        # ``param: typ = defaultVal``. 
        # We don't need defaultVal for semantic checking and it's wrong for
        # ``cmp: proc (a, b: T): int = cmp``. Hm, for ``cmp = cmp`` that is
        # not possible... XXX We don't solve this issue here.
        a.sons[L-1] = ast.emptyNode

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable, 
                      info: TLineInfo): PSym = 
  # generates an instantiated proc
  var 
    oldPrc, oldMod: PSym
    oldP: PProcCon
    n: PNode
  if c.InstCounter > 1000: InternalError(fn.ast.info, "nesting too deep")
  inc(c.InstCounter)
  oldP = c.p # restore later
  # NOTE: for access of private fields within generics from a different module
  # and other identifiers we fake the current module temporarily!
  oldMod = c.module
  c.module = getModule(fn)
  result = copySym(fn, false)
  incl(result.flags, sfFromGeneric)
  result.owner = getCurrOwner().owner
  n = copyTree(fn.ast)
  result.ast = n
  pushOwner(result)
  openScope(c.tab)
  if (n.sons[genericParamsPos].kind == nkEmpty): 
    InternalError(n.info, "generateInstance")
  n.sons[namePos] = newSymNode(result)
  pushInfoContext(info)
  instantiateGenericParamList(c, n.sons[genericParamsPos], pt)
  n.sons[genericParamsPos] = ast.emptyNode
  # semantic checking for the parameters:
  if n.sons[paramsPos].kind != nkEmpty: 
    removeDefaultParamValues(n.sons[ParamsPos])
    semParamList(c, n.sons[ParamsPos], nil, result)
    addParams(c, result.typ.n)
  else: 
    result.typ = newTypeS(tyProc, c)
    addSon(result.typ, nil)
  result.typ.callConv = fn.typ.callConv
  oldPrc = GenericCacheGet(c, fn, result)
  if oldPrc == nil: 
    # add it here, so that recursive generic procs are possible:
    GenericCacheAdd(c, fn, result)
    addDecl(c, result)
    if n.sons[codePos].kind != nkEmpty: 
      c.p = newProcCon(result)
      if result.kind in {skProc, skMethod, skConverter}: 
        addResult(c, result.typ.sons[0], n.info)
        addResultNode(c, n)
      n.sons[codePos] = semStmtScope(c, n.sons[codePos])
  else: 
    result = oldPrc
  popInfoContext()
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  c.p = oldP                  # restore
  c.module = oldMod
  dec(c.InstCounter)
    
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType = 
  var cl: TReplTypeVars
  InitIdTable(cl.symMap)
  InitIdTable(cl.typeMap)
  cl.info = n.info
  cl.c = c
  result = ReplaceTypeVarsT(cl, header)

