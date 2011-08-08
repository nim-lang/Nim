#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the instantiation of generic procs.

proc instantiateGenericParamList(c: PContext, n: PNode, pt: TIdTable,
                                 entry: var TInstantiatedSymbol) = 
  if n.kind != nkGenericParams: 
    InternalError(n.info, "instantiateGenericParamList; no generic params")
  newSeq(entry.concreteTypes, n.len)
  for i in countup(0, n.len - 1):
    var a = n.sons[i]
    if a.kind != nkSym: 
      InternalError(a.info, "instantiateGenericParamList; no symbol")
    var q = a.sym
    if q.typ.kind notin {tyTypeDesc, tyGenericParam}: continue 
    var s = newSym(skType, q.name, getCurrOwner())
    s.info = q.info
    incl(s.flags, sfUsed)
    var t = PType(IdTableGet(pt, q.typ))
    if t == nil: 
      LocalError(a.info, errCannotInstantiateX, s.name.s)
      break
    if t.kind == tyGenericParam: 
      InternalError(a.info, "instantiateGenericParamList: " & q.name.s)
    s.typ = t
    addDecl(c, s)
    entry.concreteTypes[i] = t

proc sameInstantiation(a, b: TInstantiatedSymbol): bool =
  if a.genericSym.id == b.genericSym.id and 
      a.concreteTypes.len == b.concreteTypes.len:
    for i in 0 .. < a.concreteTypes.len:
      if not sameType(a.concreteTypes[i], b.concreteTypes[i]): return
    result = true

proc GenericCacheGet(c: PContext, entry: var TInstantiatedSymbol): PSym = 
  for i in countup(0, Len(generics) - 1):
    if sameInstantiation(entry, generics[i]):
      result = generics[i].instSym
      # checking for the concrete parameter list is wrong and unnecessary!
      #if equalParams(b.typ.n, instSym.typ.n) == paramsEqual:
      #echo "found in cache: ", getProcHeader(result)
      return

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

proc instantiateBody(c: PContext, n: PNode, result: PSym) =
  if n.sons[codePos].kind != nkEmpty:
    # add it here, so that recursive generic procs are possible:
    addDecl(c, result)
    pushProcCon(c, result)
    if result.kind in {skProc, skMethod, skConverter}: 
      addResult(c, result.typ.sons[0], n.info)
      addResultNode(c, n)
    n.sons[codePos] = semStmtScope(c, n.sons[codePos])
    if result.kind == skIterator:
      # XXX Bad hack for tests/titer2:
      n.sons[codePos] = transform(c.module, n.sons[codePos])
    #echo "code instantiated ", result.name.s
    excl(result.flags, sfForward)
    popProcCon(c)

proc fixupInstantiatedSymbols(c: PContext, s: PSym) =
  for i in countup(0, Len(generics) - 1):
    if generics[i].genericSym.id == s.id:
      var oldPrc = generics[i].instSym
      pushInfoContext(oldPrc.info)
      openScope(c.tab)
      var n = oldPrc.ast
      n.sons[codePos] = copyTree(s.ast.sons[codePos])
      if n.sons[paramsPos].kind != nkEmpty: addParams(c, oldPrc.typ.n)
      instantiateBody(c, n, oldPrc)
      closeScope(c.tab)
      popInfoContext()

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable, 
                      info: TLineInfo): PSym = 
  # generates an instantiated proc
  if c.InstCounter > 1000: InternalError(fn.ast.info, "nesting too deep")
  inc(c.InstCounter)
  # NOTE: for access of private fields within generics from a different module
  # and other identifiers we fake the current module temporarily!
  # XXX bad hack!
  var oldMod = c.module
  c.module = getModule(fn)
  result = copySym(fn, false)
  incl(result.flags, sfFromGeneric)
  result.owner = getCurrOwner().owner
  var n = copyTree(fn.ast)
  result.ast = n
  pushOwner(result)
  openScope(c.tab)
  if n.sons[genericParamsPos].kind == nkEmpty: 
    InternalError(n.info, "generateInstance")
  n.sons[namePos] = newSymNode(result)
  pushInfoContext(info)
  var entry: TInstantiatedSymbol
  entry.instSym = result
  entry.genericSym = fn
  instantiateGenericParamList(c, n.sons[genericParamsPos], pt, entry)
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
  ParamsTypeCheck(c, result.typ)
  var oldPrc = GenericCacheGet(c, entry)
  if oldPrc == nil:
    generics.add(entry)
    instantiateBody(c, n, result)
  else:
    result = oldPrc
  popInfoContext()
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  c.module = oldMod
  dec(c.InstCounter)
  
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType = 
  var cl: TReplTypeVars
  InitIdTable(cl.symMap)
  InitIdTable(cl.typeMap)
  cl.info = n.info
  cl.c = c
  result = ReplaceTypeVarsT(cl, header)

