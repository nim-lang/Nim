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
    for i in 0..<n.len:
      rec n[i]
  of nkRecCase:
    if n.len > 0: rec n[0]
    for i in 1..<n.len:
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
  const callableSymbols = {skProc, skFunc, skMethod, skConverter, skIterator, skMacro}
  if c.selfName != nil and owner.kind in callableSymbols and owner.typ != nil:
    let params = owner.typ.n
    if params.len > 1:
      let arg = params[1].sym
      if arg.name.id == c.selfName.id:
        c.p.selfSym = arg
        arg.flags.incl sfIsSelf
        var t = c.p.selfSym.typ.skipTypes(abstractPtrs)
        while t.kind == tyObject:
          addObjFieldsToLocalScope(c, t.n)
          if t[0] == nil: break
          t = t[0].skipTypes(skipPtrs)

proc pushProcCon*(c: PContext; owner: PSym) =
  rawPushProcCon(c, owner)
  rawHandleSelf(c, owner)

const
  errCannotInstantiateX = "cannot instantiate: '$1'"

iterator instantiateGenericParamList(c: PContext, n: PNode, pt: TIdTable): PSym =
  internalAssert c.config, n.kind == nkGenericParams
  for i, a in n.pairs:
    internalAssert c.config, a.kind == nkSym
    var q = a.sym
    if q.typ.kind in {tyTypeDesc, tyGenericParam, tyStatic, tyConcept}+tyTypeClasses:
      let symKind = if q.typ.kind == tyStatic: skConst else: skType
      var s = newSym(symKind, q.name, nextSymId(c.idgen), getCurrOwner(c), q.info)
      s.flags.incl {sfUsed, sfFromGeneric}
      var t = PType(idTableGet(pt, q.typ))
      if t == nil:
        if tfRetType in q.typ.flags:
          # keep the generic type and allow the return type to be bound
          # later by semAsgn in return type inference scenario
          t = q.typ
        else:
          if q.typ.kind != tyCompositeTypeClass:
            localError(c.config, a.info, errCannotInstantiateX % s.name.s)
          t = errorType(c)
      elif t.kind in {tyGenericParam, tyConcept}:
        localError(c.config, a.info, errCannotInstantiateX % q.name.s)
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
                          flags = {ExactTypeDescValues,
                                   ExactGcSafety,
                                   PickyCAliases}): return
    result = true

proc genericCacheGet(g: ModuleGraph; genericSym: PSym, entry: TInstantiation;
                     id: CompilesId): PSym =
  for inst in procInstCacheItems(g, genericSym):
    if (inst.compilesId == 0 or inst.compilesId == id) and sameInstantiation(entry, inst[]):
      return inst.sym

when false:
  proc `$`(x: PSym): string =
    result = x.name.s & " " & " id " & $x.id

proc freshGenSyms(c: PContext; n: PNode, owner, orig: PSym, symMap: var TIdTable) =
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
    elif s.owner == nil or s.owner.kind == skPackage:
      #echo "copied this ", s.name.s
      x = copySym(s, nextSymId c.idgen)
      x.owner = owner
      idTablePut(symMap, s, x)
      n.sym = x
  else:
    for i in 0..<n.safeLen: freshGenSyms(c, n[i], owner, orig, symMap)

proc addParamOrResult(c: PContext, param: PSym, kind: TSymKind)

proc instantiateBody(c: PContext, n, params: PNode, result, orig: PSym) =
  if n[bodyPos].kind != nkEmpty:
    let procParams = result.typ.n
    for i in 1..<procParams.len:
      addDecl(c, procParams[i].sym)
    maybeAddResult(c, result, result.ast)

    inc c.inGenericInst
    # add it here, so that recursive generic procs are possible:
    var b = n[bodyPos]
    var symMap: TIdTable
    initIdTable symMap
    if params != nil:
      for i in 1..<params.len:
        let param = params[i].sym
        if sfGenSym in param.flags:
          idTablePut(symMap, params[i].sym, result.typ.n[param.position+1].sym)
    freshGenSyms(c, b, result, orig, symMap)

    if sfBorrow notin orig.flags: 
      # We do not want to generate a body for generic borrowed procs.
      # As body is a sym to the borrowed proc.
      let resultType = # todo probably refactor it into a function
        if result.kind == skMacro:
          sysTypeFromName(c.graph, n.info, "NimNode")
        elif not isInlineIterator(result.typ):
          result.typ[0]
        else:
          nil
      b = semProcBody(c, b, resultType)
    result.ast[bodyPos] = hloBody(c, b)
    excl(result.flags, sfForward)
    trackProc(c, result, result.ast[bodyPos])
    dec c.inGenericInst

proc fixupInstantiatedSymbols(c: PContext, s: PSym) =
  for i in 0..<c.generics.len:
    if c.generics[i].genericSym.id == s.id:
      var oldPrc = c.generics[i].inst.sym
      pushProcCon(c, oldPrc)
      pushOwner(c, oldPrc)
      pushInfoContext(c.config, oldPrc.info)
      openScope(c)
      var n = oldPrc.ast
      n[bodyPos] = copyTree(getBody(c.graph, s))
      instantiateBody(c, n, oldPrc.typ.n, oldPrc, s)
      closeScope(c)
      popInfoContext(c.config)
      popOwner(c)
      popProcCon(c)

proc sideEffectsCheck(c: PContext, s: PSym) =
  when false:
    if {sfNoSideEffect, sfSideEffect} * s.flags ==
        {sfNoSideEffect, sfSideEffect}:
      localError(s.info, errXhasSideEffects, s.name.s)

proc instGenericContainer(c: PContext, info: TLineInfo, header: PType,
                          allowMetaTypes = false): PType =
  internalAssert c.config, header.kind == tyGenericInvocation

  var
    cl: TReplTypeVars

  initIdTable(cl.symMap)
  initIdTable(cl.localCache)
  cl.typeMap = LayeredIdTable()
  initIdTable(cl.typeMap.topLayer)

  cl.info = info
  cl.c = c
  cl.allowMetaTypes = allowMetaTypes

  # We must add all generic params in scope, because the generic body
  # may include tyFromExpr nodes depending on these generic params.
  # XXX: This looks quite similar to the code in matchUserTypeClass,
  # perhaps the code can be extracted in a shared function.
  openScope(c)
  let genericTyp = header.base
  for i in 0..<genericTyp.len - 1:
    let genParam = genericTyp[i]
    var param: PSym

    template paramSym(kind): untyped =
      newSym(kind, genParam.sym.name, nextSymId c.idgen, genericTyp.sym, genParam.sym.info)

    if genParam.kind == tyStatic:
      param = paramSym skConst
      param.ast = header[i+1].n
      param.typ = header[i+1]
    else:
      param = paramSym skType
      param.typ = makeTypeDesc(c, header[i+1])

    # this scope was not created by the user,
    # unused params shouldn't be reported.
    param.flags.incl sfUsed
    addDecl(c, param)

  result = replaceTypeVarsT(cl, header)
  closeScope(c)

proc referencesAnotherParam(n: PNode, p: PSym): bool =
  if n.kind == nkSym:
    return n.sym.kind == skParam and n.sym.owner == p
  else:
    for i in 0..<n.safeLen:
      if referencesAnotherParam(n[i], p): return true
    return false

proc instantiateProcType(c: PContext, pt: TIdTable,
                         prc: PSym, info: TLineInfo) =
  # XXX: Instantiates a generic proc signature, while at the same
  # time adding the instantiated proc params into the current scope.
  # This is necessary, because the instantiation process may refer to
  # these params in situations like this:
  # proc foo[Container](a: Container, b: a.type.Item): typeof(b.x)
  #
  # Alas, doing this here is probably not enough, because another
  # proc signature could appear in the params:
  # proc foo[T](a: proc (x: T, b: typeof(x.y))
  #
  # The solution would be to move this logic into semtypinst, but
  # at this point semtypinst have to become part of sem, because it
  # will need to use openScope, addDecl, etc.
  #addDecl(c, prc)
  pushInfoContext(c.config, info)
  var typeMap = initLayeredTypeMap(pt)
  var cl = initTypeVars(c, typeMap, info, nil)
  var result = instCopyType(cl, prc.typ)
  let originalParams = result.n
  result.n = originalParams.shallowCopy
  for i in 1..<result.len:
    # twrong_field_caching requires these 'resetIdTable' calls:
    if i > 1:
      resetIdTable(cl.symMap)
      resetIdTable(cl.localCache)

    # take a note of the original type. If't a free type or static parameter
    # we'll need to keep it unbound for the `fitNode` operation below...
    var typeToFit = result[i]

    let needsStaticSkipping = result[i].kind == tyFromExpr
    result[i] = replaceTypeVarsT(cl, result[i])
    if needsStaticSkipping:
      result[i] = result[i].skipTypes({tyStatic})

    # ...otherwise, we use the instantiated type in `fitNode`
    if (typeToFit.kind != tyTypeDesc or typeToFit.base.kind != tyNone) and
       (typeToFit.kind != tyStatic):
      typeToFit = result[i]

    internalAssert c.config, originalParams[i].kind == nkSym
    let oldParam = originalParams[i].sym
    let param = copySym(oldParam, nextSymId c.idgen)
    param.owner = prc
    param.typ = result[i]

    # The default value is instantiated and fitted against the final
    # concrete param type. We avoid calling `replaceTypeVarsN` on the
    # call head symbol, because this leads to infinite recursion.
    if oldParam.ast != nil:
      var def = oldParam.ast.copyTree
      if def.kind == nkCall:
        for i in 1..<def.len:
          def[i] = replaceTypeVarsN(cl, def[i])

      def = semExprWithType(c, def)
      if def.referencesAnotherParam(getCurrOwner(c)):
        def.flags.incl nfDefaultRefsParam

      var converted = indexTypesMatch(c, typeToFit, def.typ, def)
      if converted == nil:
        # The default value doesn't match the final instantiated type.
        # As an example of this, see:
        # https://github.com/nim-lang/Nim/issues/1201
        # We are replacing the default value with an error node in case
        # the user calls an explicit instantiation of the proc (this is
        # the only way the default value might be inserted).
        param.ast = errorNode(c, def)
      else:
        param.ast = fitNodePostMatch(c, typeToFit, converted)
      param.typ = result[i]

    result.n[i] = newSymNode(param)
    propagateToOwner(result, result[i])
    addDecl(c, param)

  resetIdTable(cl.symMap)
  resetIdTable(cl.localCache)
  cl.isReturnType = true
  result[0] = replaceTypeVarsT(cl, result[0])
  cl.isReturnType = false
  result.n[0] = originalParams[0].copyTree
  if result[0] != nil:
    propagateToOwner(result, result[0])

  eraseVoidParams(result)
  skipIntLiteralParams(result, c.idgen)

  prc.typ = result
  popInfoContext(c.config)

proc fillMixinScope(c: PContext) =
  var p = c.p
  while p != nil:
    for bnd in p.localBindStmts:
      for n in bnd:
        addSym(c.currentScope, n.sym)
    p = p.next

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable,
                      info: TLineInfo): PSym {.nosinks.} =
  ## Generates a new instance of a generic procedure.
  ## The `pt` parameter is a type-unsafe mapping table used to link generic
  ## parameters to their concrete types within the generic instance.
  # no need to instantiate generic templates/macros:
  internalAssert c.config, fn.kind notin {skMacro, skTemplate}
  # generates an instantiated proc
  if c.instCounter > 50:
    globalError(c.config, info, "generic instantiation too nested")
  inc(c.instCounter)
  # careful! we copy the whole AST including the possibly nil body!
  var n = copyTree(fn.ast)
  # NOTE: for access of private fields within generics from a different module
  # we set the friend module:
  c.friendModules.add(getModule(fn))
  let oldMatchedConcept = c.matchedConcept
  c.matchedConcept = nil
  let oldScope = c.currentScope
  while not isTopLevel(c): c.currentScope = c.currentScope.parent
  result = copySym(fn, nextSymId c.idgen)
  incl(result.flags, sfFromGeneric)
  result.owner = fn
  result.ast = n
  pushOwner(c, result)

  # mixin scope:
  openScope(c)
  fillMixinScope(c)

  openScope(c)
  let gp = n[genericParamsPos]
  internalAssert c.config, gp.kind == nkGenericParams
  n[namePos] = newSymNode(result)
  pushInfoContext(c.config, info, fn.detailedInfo)
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
  for j in 1..<result.typ.len:
    entry.concreteTypes[i] = result.typ[j]
    inc i
  if tfTriggersCompileTime in result.typ.flags:
    incl(result.flags, sfCompileTime)
  n[genericParamsPos] = c.graph.emptyNode
  var oldPrc = genericCacheGet(c.graph, fn, entry[], c.compilesContextId)
  if oldPrc == nil:
    # we MUST not add potentially wrong instantiations to the caching mechanism.
    # This means recursive instantiations behave differently when in
    # a ``compiles`` context but this is the lesser evil. See
    # bug #1055 (tevilcompiles).
    #if c.compilesContextId == 0:
    rawHandleSelf(c, result)
    entry.compilesId = c.compilesContextId
    addToGenericProcCache(c, fn, entry)
    c.generics.add(makeInstPair(fn, entry))
    if n[pragmasPos].kind != nkEmpty:
      pragma(c, result, n[pragmasPos], allRoutinePragmas)
    if isNil(n[bodyPos]):
      n[bodyPos] = copyTree(getBody(c.graph, fn))
    if c.inGenericContext == 0:
      instantiateBody(c, n, fn.typ.n, result, fn)
    sideEffectsCheck(c, result)
    if result.magic notin {mSlice, mTypeOf}:
      # 'toOpenArray' is special and it is allowed to return 'openArray':
      paramsTypeCheck(c, result.typ)
  else:
    result = oldPrc
  popProcCon(c)
  popInfoContext(c.config)
  closeScope(c)           # close scope for parameters
  closeScope(c)           # close scope for 'mixin' declarations
  popOwner(c)
  c.currentScope = oldScope
  discard c.friendModules.pop()
  dec(c.instCounter)
  c.matchedConcept = oldMatchedConcept
  if result.kind == skMethod: finishMethod(c, result)

  # inform IC of the generic
  #addGeneric(c.ic, result, entry.concreteTypes)
