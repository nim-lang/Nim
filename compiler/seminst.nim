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

proc addObjFieldsToLocalScope(c: PContext; n: PNode) =
  template rec(n) = addObjFieldsToLocalScope(c, n)
  case n.kind
  of nkRecList:
    for i in countup(0, len(n)-1):
      rec n[i]
  of nkRecCase:
    if n.len > 0: rec n.sons[0]
    for i in countup(1, len(n)-1):
      if n[i].kind in {nkOfBranch, nkElse}: rec lastSon(n[i])
  of nkSym:
    let f = n.sym
    if f.kind == skField and fieldVisible(c, f):
      c.currentScope.symbols.strTableIncl(f, onConflictKeepOld=true)
      incl(f.flags, sfUsed)
      # it is not an error to shadow fields via parameters
  else: discard

proc rawPushProcCon(c: PContext, owner: PSym) =
  var x: PProcCon
  new(x)
  x.owner = owner
  x.next = c.p
  c.p = x

proc rawHandleSelf(c: PContext; owner: PSym) =
  if c.selfName != nil and owner.kind in {skProc, skMethod, skConverter, skIterator, skMacro} and owner.typ != nil:
    let params = owner.typ.n
    if params.len > 1:
      let arg = params[1].sym
      if arg.name.id == c.selfName.id:
        c.p.selfSym = arg
        arg.flags.incl sfIsSelf
        var t = c.p.selfSym.typ.skipTypes(abstractPtrs)
        while t.kind == tyObject:
          addObjFieldsToLocalScope(c, t.n)
          if t.sons[0] == nil: break
          t = t.sons[0].skipTypes(skipPtrs)

proc pushProcCon*(c: PContext; owner: PSym) =
  rawPushProcCon(c, owner)
  rawHandleSelf(c, owner)

iterator instantiateGenericParamList(c: PContext, n: PNode, pt: TIdTable): PSym =
  internalAssert n.kind == nkGenericParams
  for i, a in n.pairs:
    internalAssert a.kind == nkSym
    var q = a.sym
    if q.typ.kind notin {tyTypeDesc, tyGenericParam, tyStatic}+tyTypeClasses:
      continue
    let symKind = if q.typ.kind == tyStatic: skConst else: skType
    var s = newSym(symKind, q.name, getCurrOwner(c), q.info)
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
    yield s

proc sameInstantiation(a, b: TInstantiation): bool =
  if a.concreteTypes.len == b.concreteTypes.len:
    for i in 0..a.concreteTypes.high:
      if not compareTypes(a.concreteTypes[i], b.concreteTypes[i],
                          flags = {ExactTypeDescValues}): return
    result = true

proc genericCacheGet(genericSym: PSym, entry: TInstantiation;
                     id: CompilesId): PSym =
  if genericSym.procInstCache != nil:
    for inst in genericSym.procInstCache:
      if inst.compilesId == id and sameInstantiation(entry, inst[]):
        return inst.sym

when false:
  proc `$`(x: PSym): string =
    result = x.name.s & " " & " id " & $x.id

proc freshGenSyms(n: PNode, owner, orig: PSym, symMap: var TIdTable) =
  # we need to create a fresh set of gensym'ed symbols:
  #if n.kind == nkSym and sfGenSym in n.sym.flags:
  #  if n.sym.owner != orig:
  #    echo "symbol ", n.sym.name.s, " orig ", orig, " owner ", n.sym.owner
  if n.kind == nkSym and sfGenSym in n.sym.flags: # and
    #  (n.sym.owner == orig or n.sym.owner.kind in {skPackage}):
    let s = n.sym
    var x = PSym(idTableGet(symMap, s))
    if x != nil:
      n.sym = x
    elif s.owner.kind == skPackage:
      #echo "copied this ", s.name.s
      x = copySym(s, false)
      x.owner = owner
      idTablePut(symMap, s, x)
      n.sym = x
  else:
    for i in 0 .. <safeLen(n): freshGenSyms(n.sons[i], owner, orig, symMap)

proc addParamOrResult(c: PContext, param: PSym, kind: TSymKind)

proc instantiateBody(c: PContext, n, params: PNode, result, orig: PSym) =
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
    freshGenSyms(b, result, orig, symMap)
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
      instantiateBody(c, n, nil, oldPrc, s)
      closeScope(c)
      popInfoContext()

proc sideEffectsCheck(c: PContext, s: PSym) =
  when false:
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
  #addDecl(c, prc)

  pushInfoContext(info)
  var cl = initTypeVars(c, pt, info, nil)
  var result = instCopyType(cl, prc.typ)
  let originalParams = result.n
  result.n = originalParams.shallowCopy

  for i in 1 .. <result.len:
    # twrong_field_caching requires these 'resetIdTable' calls:
    if i > 1:
      resetIdTable(cl.symMap)
      resetIdTable(cl.localCache)
    result.sons[i] = replaceTypeVarsT(cl, result.sons[i])
    propagateToOwner(result, result.sons[i])
    internalAssert originalParams[i].kind == nkSym
    when true:
      let oldParam = originalParams[i].sym
      let param = copySym(oldParam)
      param.owner = prc
      param.typ = result.sons[i]
      if oldParam.ast != nil:
        param.ast = fitNode(c, param.typ, oldParam.ast, oldParam.ast.info)

      # don't be lazy here and call replaceTypeVarsN(cl, originalParams[i])!
      result.n.sons[i] = newSymNode(param)
      addDecl(c, param)
    else:
      let param = replaceTypeVarsN(cl, originalParams[i])
      result.n.sons[i] = param
      param.sym.owner = prc
      addDecl(c, result.n.sons[i].sym)

  resetIdTable(cl.symMap)
  resetIdTable(cl.localCache)
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
  internalAssert fn.kind notin {skMacro, skTemplate}
  # generates an instantiated proc
  if c.instCounter > 1000: internalError(fn.ast.info, "nesting too deep")
  inc(c.instCounter)
  # careful! we copy the whole AST including the possibly nil body!
  var n = copyTree(fn.ast)
  # NOTE: for access of private fields within generics from a different module
  # we set the friend module:
  c.friendModules.add(getModule(fn))
  let oldInTypeClass = c.inTypeClass
  c.inTypeClass = 0
  let oldScope = c.currentScope
  while not isTopLevel(c): c.currentScope = c.currentScope.parent
  result = copySym(fn, false)
  incl(result.flags, sfFromGeneric)
  result.owner = fn
  result.ast = n
  pushOwner(c, result)

  openScope(c)
  let gp = n.sons[genericParamsPos]
  internalAssert gp.kind != nkEmpty
  n.sons[namePos] = newSymNode(result)
  pushInfoContext(info)
  var entry = TInstantiation.new
  entry.sym = result
  # we need to compare both the generic types and the concrete types:
  # generic[void](), generic[int]()
  # see ttypeor.nim test.
  var i = 0
  newSeq(entry.concreteTypes, fn.typ.len+gp.len-1)
  for s in instantiateGenericParamList(c, gp, pt):
    addDecl(c, s)
    entry.concreteTypes[i] = s.typ
    inc i
  rawPushProcCon(c, result)
  instantiateProcType(c, pt, result, info)
  for j in 1 .. result.typ.len-1:
    entry.concreteTypes[i] = result.typ.sons[j]
    inc i
  if tfTriggersCompileTime in result.typ.flags:
    incl(result.flags, sfCompileTime)
  n.sons[genericParamsPos] = ast.emptyNode
  var oldPrc = genericCacheGet(fn, entry[], c.compilesContextId)
  if oldPrc == nil:
    # we MUST not add potentially wrong instantiations to the caching mechanism.
    # This means recursive instantiations behave differently when in
    # a ``compiles`` context but this is the lesser evil. See
    # bug #1055 (tevilcompiles).
    #if c.compilesContextId == 0:
    rawHandleSelf(c, result)
    entry.compilesId = c.compilesContextId
    fn.procInstCache.safeAdd(entry)
    c.generics.add(makeInstPair(fn, entry))
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, result, n.sons[pragmasPos], allRoutinePragmas)
    if isNil(n.sons[bodyPos]):
      n.sons[bodyPos] = copyTree(fn.getBody)
    instantiateBody(c, n, fn.typ.n, result, fn)
    sideEffectsCheck(c, result)
    paramsTypeCheck(c, result.typ)
  else:
    result = oldPrc
  popProcCon(c)
  popInfoContext()
  closeScope(c)           # close scope for parameters
  popOwner(c)
  c.currentScope = oldScope
  discard c.friendModules.pop()
  dec(c.instCounter)
  c.inTypeClass = oldInTypeClass
  if result.kind == skMethod: finishMethod(c, result)
