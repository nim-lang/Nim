#
#
#           The Nim Compiler
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
  for i, a in n.pairs:
    if a.kind != nkSym:
      internalError(a.info, "instantiateGenericParamList; no symbol")
    var q = a.sym
    if q.typ.kind notin {tyTypeDesc, tyGenericParam, tyStatic, tyIter}+tyTypeClasses:
      continue
    let symKind = if q.typ.kind == tyStatic: skConst else: skType
    var s = newSym(symKind, q.name, getCurrOwner(), q.info)
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
      localError(a.info, errCannotInstantiateX, q.name.s)
      t = errorType(c)
    elif t.kind == tyGenericInvocation:
      #t = instGenericContainer(c, a, t)
      t = generateTypeInstance(c, pt, a, t)
      #t = ReplaceTypeVarsT(cl, t)
    s.typ = t
    if t.kind == tyStatic: s.ast = t.n
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
    let s = n.sym
    var x = PSym(idTableGet(symMap, s))
    if x == nil:
      x = copySym(s, false)
      x.owner = owner
      idTablePut(symMap, s, x)
    n.sym = x
  else:
    for i in 0 .. <safeLen(n): freshGenSyms(n.sons[i], owner, symMap)

proc addParamOrResult(c: PContext, param: PSym, kind: TSymKind)

proc addProcDecls(c: PContext, fn: PSym) =
  # get the proc itself in scope (e.g. for recursion)
  addDecl(c, fn)

  for i in 1 .. <fn.typ.n.len:
    var param = fn.typ.n.sons[i].sym
    param.owner = fn
    addParamOrResult(c, param, fn.kind)

  maybeAddResult(c, fn, fn.ast)

proc instantiateBody(c: PContext, n, params: PNode, result: PSym) =
  if n.sons[bodyPos].kind != nkEmpty:
    inc c.inGenericInst
    # add it here, so that recursive generic procs are possible:
    var b = n.sons[bodyPos]
    var symMap: TIdTable
    initIdTable symMap
    if params != nil:
      for i in 1 .. <params.len:
        let param = params[i].sym
        if sfGenSym in param.flags:
          idTablePut(symMap, params[i].sym, result.typ.n[param.position+1].sym)
    freshGenSyms(b, result, symMap)
    b = semProcBody(c, b)
    b = hloBody(c, b)
    n.sons[bodyPos] = transformBody(c.module, b, result)
    #echo "code instantiated ", result.name.s
    excl(result.flags, sfForward)
    dec c.inGenericInst

proc fixupInstantiatedSymbols(c: PContext, s: PSym) =
  for i in countup(0, c.generics.len - 1):
    if c.generics[i].genericSym.id == s.id:
      var oldPrc = c.generics[i].inst.sym
      pushInfoContext(oldPrc.info)
      openScope(c)
      var n = oldPrc.ast
      n.sons[bodyPos] = copyTree(s.getBody)
      instantiateBody(c, n, nil, oldPrc)
      closeScope(c)
      popInfoContext()

proc sideEffectsCheck(c: PContext, s: PSym) =
  if {sfNoSideEffect, sfSideEffect} * s.flags ==
      {sfNoSideEffect, sfSideEffect}:
    localError(s.info, errXhasSideEffects, s.name.s)

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

proc instantiateProcType(c: PContext, pt: TIdTable,
                          prc: PSym, info: TLineInfo) =
  # XXX: Instantiates a generic proc signature, while at the same
  # time adding the instantiated proc params into the current scope.
  # This is necessary, because the instantiation process may refer to
  # these params in situations like this:
  # proc foo[Container](a: Container, b: a.type.Item): type(b.x)
  #
  # Alas, doing this here is probably not enough, because another
  # proc signature could appear in the params:
  # proc foo[T](a: proc (x: T, b: type(x.y))
  #
  # The solution would be to move this logic into semtypinst, but
  # at this point semtypinst have to become part of sem, because it
  # will need to use openScope, addDecl, etc.
  addDecl(c, prc)

  pushInfoContext(info)
  var cl = initTypeVars(c, pt, info)
  var result = instCopyType(cl, prc.typ)
  let originalParams = result.n
  result.n = originalParams.shallowCopy

  for i in 1 .. <result.len:
    # twrong_field_caching requires these 'resetIdTable' calls:
    if i > 1: resetIdTable(cl.symMap)
    result.sons[i] = replaceTypeVarsT(cl, result.sons[i])
    propagateToOwner(result, result.sons[i])
    internalAssert originalParams[i].kind == nkSym
    when true:
      let oldParam = originalParams[i].sym
      let param = copySym(oldParam)
      param.owner = prc
      param.typ = result.sons[i]
      param.ast = oldParam.ast.copyTree
      # don't be lazy here and call replaceTypeVarsN(cl, originalParams[i])!
      result.n.sons[i] = newSymNode(param)
      addDecl(c, param)
    else:
      let param = replaceTypeVarsN(cl, originalParams[i])
      result.n.sons[i] = param
      param.sym.owner = prc
      addDecl(c, result.n.sons[i].sym)

  resetIdTable(cl.symMap)
  result.sons[0] = replaceTypeVarsT(cl, result.sons[0])
  result.n.sons[0] = originalParams[0].copyTree

  eraseVoidParams(result)
  skipIntLiteralParams(result)

  prc.typ = result
  maybeAddResult(c, prc, prc.ast)
  popInfoContext()

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable,
                      info: TLineInfo): PSym =
  ## Generates a new instance of a generic procedure.
  ## The `pt` parameter is a type-unsafe mapping table used to link generic
  ## parameters to their concrete types within the generic instance.
  # no need to instantiate generic templates/macros:
  if fn.kind in {skTemplate, skMacro}: return fn
  # generates an instantiated proc
  if c.instCounter > 1000: internalError(fn.ast.info, "nesting too deep")
  inc(c.instCounter)
  # careful! we copy the whole AST including the possibly nil body!
  var n = copyTree(fn.ast)
  # NOTE: for access of private fields within generics from a different module
  # we set the friend module:
  c.friendModules.add(getModule(fn))
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
  pushProcCon(c, result)
  instantiateProcType(c, pt, result, info)
  n.sons[genericParamsPos] = ast.emptyNode
  var oldPrc = genericCacheGet(fn, entry[])
  if oldPrc == nil:
    # we MUST not add potentially wrong instantiations to the caching mechanism.
    # This means recursive instantiations behave differently when in
    # a ``compiles`` context but this is the lesser evil. See
    # bug #1055 (tevilcompiles).
    if c.inCompilesContext == 0: fn.procInstCache.safeAdd(entry)
    c.generics.add(makeInstPair(fn, entry))
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, result, n.sons[pragmasPos], allRoutinePragmas)
    if isNil(n.sons[bodyPos]):
      n.sons[bodyPos] = copyTree(fn.getBody)
    instantiateBody(c, n, fn.typ.n, result)
    sideEffectsCheck(c, result)
    paramsTypeCheck(c, result.typ)
  else:
    result = oldPrc
  popProcCon(c)
  popInfoContext()
  closeScope(c)           # close scope for parameters
  popOwner()
  #c.currentScope = oldScope
  discard c.friendModules.pop()
  dec(c.instCounter)
  if result.kind == skMethod: finishMethod(c, result)
