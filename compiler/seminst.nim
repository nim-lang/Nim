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
                                 entry: var TInstantiation) = 
  if n.kind != nkGenericParams: 
    internalError(n.info, "instantiateGenericParamList; no generic params")
  newSeq(entry.concreteTypes, n.len)
  for i in countup(0, n.len - 1):
    var a = n.sons[i]
    if a.kind != nkSym: 
      internalError(a.info, "instantiateGenericParamList; no symbol")
    var q = a.sym
    if q.typ.kind notin {tyTypeDesc, tyGenericParam, tyStatic}+tyTypeClasses:
      continue
    var s = newSym(skType, q.name, getCurrOwner(), q.info)
    s.flags = s.flags + {sfUsed, sfFromGeneric}
    var t = PType(idTableGet(pt, q.typ))
    if t == nil:
      if tfRetType in q.typ.flags:
        # keep the generic type and allow the return type to be bound 
        # later by semAsgn in return type inference scenario
        t = q.typ
      else:
        localError(a.info, errCannotInstantiateX, s.name.s)
        t = errorType(c)
    elif t.kind == tyGenericParam: 
      internalError(a.info, "instantiateGenericParamList: " & q.name.s)
    elif t.kind == tyGenericInvokation:
      #t = instGenericContainer(c, a, t)
      t = generateTypeInstance(c, pt, a, t)
      #t = ReplaceTypeVarsT(cl, t)
    s.typ = t
    addDecl(c, s)
    entry.concreteTypes[i] = t

proc sameInstantiation(a, b: TInstantiation): bool =
  if a.concreteTypes.len == b.concreteTypes.len:
    for i in 0..a.concreteTypes.high:
      if not compareTypes(a.concreteTypes[i], b.concreteTypes[i],
                          flags = {ExactTypeDescValues}): return
    result = true

proc genericCacheGet(genericSym: PSym, entry: TInstantiation): PSym =
  if genericSym.procInstCache != nil:
    for inst in genericSym.procInstCache:
      if sameInstantiation(entry, inst[]):
        return inst.sym

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

proc freshGenSyms(n: PNode, owner: PSym, symMap: var TIdTable) =
  # we need to create a fresh set of gensym'ed symbols:
  if n.kind == nkSym and sfGenSym in n.sym.flags:
    var x = PSym(idTableGet(symMap, n.sym))
    if x == nil:
      x = copySym(n.sym, false)
      x.owner = owner
      idTablePut(symMap, n.sym, x)
    n.sym = x
  else:
    for i in 0 .. <safeLen(n): freshGenSyms(n.sons[i], owner, symMap)

proc addParamOrResult(c: PContext, param: PSym, kind: TSymKind)

proc instantiateBody(c: PContext, n: PNode, result: PSym) =
  if n.sons[bodyPos].kind != nkEmpty:
    inc c.inGenericInst
    # add it here, so that recursive generic procs are possible:
    addDecl(c, result)
    pushProcCon(c, result)
    # add params to scope
    for i in 1 .. <result.typ.n.len:
      var param = result.typ.n.sons[i].sym
      param.owner = result
      addParamOrResult(c, param, result.kind)
    # debug result.typ.n
    maybeAddResult(c, result, n)
    var b = n.sons[bodyPos]
    var symMap: TIdTable
    initIdTable symMap
    freshGenSyms(b, result, symMap)
    b = semProcBody(c, b)
    b = hloBody(c, b)
    n.sons[bodyPos] = transformBody(c.module, b, result)
    #echo "code instantiated ", result.name.s
    excl(result.flags, sfForward)
    popProcCon(c)
    dec c.inGenericInst

proc fixupInstantiatedSymbols(c: PContext, s: PSym) =
  for i in countup(0, c.generics.len - 1):
    if c.generics[i].genericSym.id == s.id:
      var oldPrc = c.generics[i].inst.sym
      pushInfoContext(oldPrc.info)
      openScope(c)
      var n = oldPrc.ast
      n.sons[bodyPos] = copyTree(s.getBody)
      instantiateBody(c, n, oldPrc)
      closeScope(c)
      popInfoContext()

proc sideEffectsCheck(c: PContext, s: PSym) = 
  if {sfNoSideEffect, sfSideEffect} * s.flags ==
      {sfNoSideEffect, sfSideEffect}: 
    localError(s.info, errXhasSideEffects, s.name.s)
  elif sfThread in s.flags and semthreads.needsGlobalAnalysis() and 
      s.ast.sons[genericParamsPos].kind == nkEmpty:
    c.threadEntries.add(s)

proc instGenericContainer(c: PContext, info: TLineInfo, header: PType,
                          allowMetaTypes = false): PType =
  var cl: TReplTypeVars
  initIdTable(cl.symMap)
  initIdTable(cl.typeMap)
  initIdTable(cl.localCache)
  cl.info = info
  cl.c = c
  cl.allowMetaTypes = allowMetaTypes
  result = replaceTypeVarsT(cl, header)

proc instGenericContainer(c: PContext, n: PNode, header: PType): PType =
  result = instGenericContainer(c, n.info, header)

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable,
                      info: TLineInfo): PSym =
  # no need to instantiate generic templates/macros:
  if fn.kind in {skTemplate, skMacro}: return fn
 
  # generates an instantiated proc
  if c.instCounter > 1000: internalError(fn.ast.info, "nesting too deep")
  inc(c.instCounter)
  # careful! we copy the whole AST including the possibly nil body!
  var n = copyTree(fn.ast)
  # NOTE: for access of private fields within generics from a different module
  # we set the friend module:
  var oldFriend = c.friendModule
  c.friendModule = getModule(fn)
  #let oldScope = c.currentScope
  #c.currentScope = fn.scope
  result = copySym(fn, false)
  incl(result.flags, sfFromGeneric)
  result.owner = fn
  result.ast = n
  pushOwner(result)
  openScope(c)
  internalAssert n.sons[genericParamsPos].kind != nkEmpty
  n.sons[namePos] = newSymNode(result)
  pushInfoContext(info)
  var entry = TInstantiation.new
  entry.sym = result
  instantiateGenericParamList(c, n.sons[genericParamsPos], pt, entry[])
  result.typ = generateTypeInstance(c, pt, info, fn.typ)
  n.sons[genericParamsPos] = ast.emptyNode
  var oldPrc = genericCacheGet(fn, entry[])
  if oldPrc == nil:
    fn.procInstCache.safeAdd(entry)
    c.generics.add(makeInstPair(fn, entry))
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, result, n.sons[pragmasPos], allRoutinePragmas)
    if isNil(n.sons[bodyPos]):
      n.sons[bodyPos] = copyTree(fn.getBody)
    if fn.kind != skTemplate:
      instantiateBody(c, n, result)
      sideEffectsCheck(c, result)
    paramsTypeCheck(c, result.typ)
  else:
    result = oldPrc
  popInfoContext()
  closeScope(c)           # close scope for parameters
  popOwner()
  #c.currentScope = oldScope
  c.friendModule = oldFriend
  dec(c.instCounter)
  if result.kind == skMethod: finishMethod(c, result)
