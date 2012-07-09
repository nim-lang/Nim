#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the instantiation of generic procs.
# included from sem.nim

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
    if q.typ.kind notin {tyTypeDesc, tyGenericParam, tyTypeClass, tyExpr}: continue
    var s = newSym(skType, q.name, getCurrOwner())
    s.info = q.info
    s.flags = s.flags + {sfUsed, sfFromGeneric}
    var t = PType(IdTableGet(pt, q.typ))
    if t == nil:
      LocalError(a.info, errCannotInstantiateX, s.name.s)
      break
    if t.kind == tyGenericParam: 
      InternalError(a.info, "instantiateGenericParamList: " & q.name.s)
    elif t.kind == tyGenericInvokation:
      #t = instGenericContainer(c, a, t)
      t = generateTypeInstance(c, pt, a, t)
      #t = ReplaceTypeVarsT(cl, t)
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
  for i in countup(0, Len(c.generics.generics) - 1):
    if sameInstantiation(entry, c.generics.generics[i]):
      result = c.generics.generics[i].instSym
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
  if n.sons[bodyPos].kind != nkEmpty:
    # add it here, so that recursive generic procs are possible:
    addDecl(c, result)
    pushProcCon(c, result)
    if result.kind in {skProc, skMethod, skConverter}: 
      addResult(c, result.typ.sons[0], n.info, result.kind)
      addResultNode(c, n)
    var b = semStmtScope(c, n.sons[bodyPos])
    # XXX Bad hack for tests/titer2 and tests/tactiontable
    n.sons[bodyPos] = transform(c.module, b)
    #echo "code instantiated ", result.name.s
    excl(result.flags, sfForward)
    popProcCon(c)

proc fixupInstantiatedSymbols(c: PContext, s: PSym) =
  for i in countup(0, Len(c.generics.generics) - 1):
    if c.generics.generics[i].genericSym.id == s.id:
      var oldPrc = c.generics.generics[i].instSym
      pushInfoContext(oldPrc.info)
      openScope(c.tab)
      var n = oldPrc.ast
      n.sons[bodyPos] = copyTree(s.getBody)
      if n.sons[paramsPos].kind != nkEmpty: 
        addParams(c, oldPrc.typ.n, oldPrc.kind)
      instantiateBody(c, n, oldPrc)
      closeScope(c.tab)
      popInfoContext()

proc sideEffectsCheck(c: PContext, s: PSym) = 
  if {sfNoSideEffect, sfSideEffect} * s.flags ==
      {sfNoSideEffect, sfSideEffect}: 
    LocalError(s.info, errXhasSideEffects, s.name.s)
  elif sfThread in s.flags and semthreads.needsGlobalAnalysis() and 
      s.ast.sons[genericParamsPos].kind == nkEmpty:
    c.threadEntries.add(s)

proc applyConcreteTypesToSig(genericProc: PSym, concTypes: seq[PType]): PType =
  # XXX: This is intended to replace the use of semParamList in generateInstance.
  # The results of semParamList's analysis are already encoded in the original
  # proc type and any concrete types may be aplied directly over it.
  # Besides being more efficient, it will remove the awkward case of
  # genericParams == nil in semParamList.
  # Currenly, it fails in some cases such as:
  # proc inc2*[T](x: var ordinal[T], y = 1) {.magic: "Inc", noSideEffect.}
  let sig = genericProc.typ
  result = copyType(sig, getCurrOwner(), false)
  result.n = sig.n.shallowCopy
  
  for i in countup(0, sig.len - 1):
    let tOrig = sig.sons[i]
    if tOrig == nil: continue        
    let oGenParams = genericProc.ast.sons[genericParamsPos]
    if skipTypes(tOrig, skipPtrs).kind in {tyGenericParam}:
      var tConcrete = concTypes[tOrig.sym.position]
      if i > 0:
        let param = sig.n.sons[i].sym.copySym
        param.typ = tConcrete
        result.n.sons[i] = newSymNode(param)
      result.sons[i] = tConcrete
    else:
      result.sons[i] = tOrig
      if i > 0: result.n.sons[i] = sig.n.sons[i]

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable, 
                      info: TLineInfo): PSym = 
  # generates an instantiated proc
  if c.InstCounter > 1000: InternalError(fn.ast.info, "nesting too deep")
  inc(c.InstCounter)
  # careful! we copy the whole AST including the possibly nil body!
  var n = copyTree(fn.ast)
  # NOTE: for access of private fields within generics from a different module
  # we set the friend module:
  var oldFriend = c.friendModule
  c.friendModule = getModule(fn)
  result = copySym(fn, false)
  incl(result.flags, sfFromGeneric)
  # keep the owner if it's an inner proc (for proper closure transformations):
  if fn.owner.kind == skModule:
    result.owner = getCurrOwner().owner
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
    if false and nimdbg:
      result.typ = applyConcreteTypesToSig(fn, entry.concreteTypes)
      addParams(c, result.typ.n, fn.kind)
    else:
      removeDefaultParamValues(n.sons[ParamsPos])
      semParamList(c, n.sons[ParamsPos], nil, result)
  else:
    result.typ = newTypeS(tyProc, c)
    rawAddSon(result.typ, nil)
  result.typ.callConv = fn.typ.callConv
  ParamsTypeCheck(c, result.typ)
  var oldPrc = GenericCacheGet(c, entry)
  if oldPrc == nil:
    c.generics.generics.add(entry)
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, result, n.sons[pragmasPos], allRoutinePragmas)
    if isNil(n.sons[bodyPos]):
      n.sons[bodyPos] = copyTree(fn.getBody)
    instantiateBody(c, n, result)
    sideEffectsCheck(c, result)
  else:
    result = oldPrc
  popInfoContext()
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  c.friendModule = oldFriend
  dec(c.InstCounter)
  
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType = 
  var cl: TReplTypeVars
  InitIdTable(cl.symMap)
  InitIdTable(cl.typeMap)
  cl.info = n.info
  cl.c = c
  result = ReplaceTypeVarsT(cl, header)

