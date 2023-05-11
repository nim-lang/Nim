#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements the semantic checking for magics.
# included from sem.nim

proc semAddrArg(c: PContext; n: PNode; isUnsafeAddr = false): PNode =
  let x = semExprWithType(c, n)
  if x.kind == nkSym:
    x.sym.flags.incl(sfAddrTaken)
  if isAssignable(c, x, isUnsafeAddr) notin {arLValue, arLocalLValue}:
    # Do not suggest the use of unsafeAddr if this expression already is a
    # unsafeAddr
    if isUnsafeAddr:
      localError(c.config, n.info, errExprHasNoAddress)
    else:
      localError(c.config, n.info, errExprHasNoAddress & "; maybe use 'unsafeAddr'")
  result = x

proc semTypeOf(c: PContext; n: PNode): PNode =
  var m = BiggestInt 1 # typeOfIter
  if n.len == 3:
    let mode = semConstExpr(c, n[2])
    if mode.kind != nkIntLit:
      localError(c.config, n.info, "typeof: cannot evaluate 'mode' parameter at compile-time")
    else:
      m = mode.intVal
  result = newNodeI(nkTypeOfExpr, n.info)
  let typExpr = semExprWithType(c, n[1], if m == 1: {efInTypeof} else: {})
  result.add typExpr
  result.typ = makeTypeDesc(c, typExpr.typ)

type
  SemAsgnMode = enum asgnNormal, noOverloadedSubscript, noOverloadedAsgn

proc semAsgn(c: PContext, n: PNode; mode=asgnNormal): PNode
proc semSubscript(c: PContext, n: PNode, flags: TExprFlags): PNode

proc semArrGet(c: PContext; n: PNode; flags: TExprFlags): PNode =
  result = newNodeI(nkBracketExpr, n.info)
  for i in 1..<n.len: result.add(n[i])
  result = semSubscript(c, result, flags)
  if result.isNil:
    let x = copyTree(n)
    x[0] = newIdentNode(getIdent(c.cache, "[]"), n.info)
    bracketNotFoundError(c, x)
    #localError(c.config, n.info, "could not resolve: " & $n)
    result = n

proc semArrPut(c: PContext; n: PNode; flags: TExprFlags): PNode =
  # rewrite `[]=`(a, i, x)  back to ``a[i] = x``.
  let b = newNodeI(nkBracketExpr, n.info)
  b.add(n[1].skipAddr)
  for i in 2..<n.len-1: b.add(n[i])
  result = newNodeI(nkAsgn, n.info, 2)
  result[0] = b
  result[1] = n.lastSon
  result = semAsgn(c, result, noOverloadedSubscript)

proc semAsgnOpr(c: PContext; n: PNode): PNode =
  result = newNodeI(nkAsgn, n.info, 2)
  result[0] = n[1]
  result[1] = n[2]
  result = semAsgn(c, result, noOverloadedAsgn)

proc semIsPartOf(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var r = isPartOf(n[1], n[2])
  result = newIntNodeT(toInt128(ord(r)), n, c.idgen, c.graph)

proc expectIntLit(c: PContext, n: PNode): int =
  let x = c.semConstExpr(c, n)
  case x.kind
  of nkIntLit..nkInt64Lit: result = int(x.intVal)
  else: localError(c.config, n.info, errIntLiteralExpected)

proc semInstantiationInfo(c: PContext, n: PNode): PNode =
  result = newNodeIT(nkTupleConstr, n.info, n.typ)
  let idx = expectIntLit(c, n[1])
  let useFullPaths = expectIntLit(c, n[2])
  let info = getInfoContext(c.config, idx)
  var filename = newNodeIT(nkStrLit, n.info, getSysType(c.graph, n.info, tyString))
  filename.strVal = if useFullPaths != 0: toFullPath(c.config, info) else: toFilename(c.config, info)
  var line = newNodeIT(nkIntLit, n.info, getSysType(c.graph, n.info, tyInt))
  line.intVal = toLinenumber(info)
  var column = newNodeIT(nkIntLit, n.info, getSysType(c.graph, n.info, tyInt))
  column.intVal = toColumn(info)
  # filename: string, line: int, column: int
  result.add(newTree(nkExprColonExpr, n.typ.n[0], filename))
  result.add(newTree(nkExprColonExpr, n.typ.n[1], line))
  result.add(newTree(nkExprColonExpr, n.typ.n[2], column))

proc toNode(t: PType, i: TLineInfo): PNode =
  result = newNodeIT(nkType, i, t)

const
  # these are types that use the bracket syntax for instantiation
  # they can be subjected to the type traits `genericHead` and
  # `Uninstantiated`
  tyUserDefinedGenerics* = {tyGenericInst, tyGenericInvocation,
                            tyUserTypeClassInst}

  tyMagicGenerics* = {tySet, tySequence, tyArray, tyOpenArray}

  tyGenericLike* = tyUserDefinedGenerics +
                   tyMagicGenerics +
                   {tyCompositeTypeClass}

proc uninstantiate(t: PType): PType =
  result = case t.kind
    of tyMagicGenerics: t
    of tyUserDefinedGenerics: t.base
    of tyCompositeTypeClass: uninstantiate t[1]
    else: t

proc getTypeDescNode(c: PContext; typ: PType, sym: PSym, info: TLineInfo): PNode =
  var resType = newType(tyTypeDesc, nextTypeId c.idgen, sym)
  rawAddSon(resType, typ)
  result = toNode(resType, info)

proc evalTypeTrait(c: PContext; traitCall: PNode, operand: PType, context: PSym): PNode =
  const skippedTypes = {tyTypeDesc, tyAlias, tySink}
  let trait = traitCall[0]
  internalAssert c.config, trait.kind == nkSym
  var operand = operand.skipTypes(skippedTypes)

  template operand2: PType =
    traitCall[2].typ.skipTypes({tyTypeDesc})

  template typeWithSonsResult(kind, sons): PNode =
    newTypeWithSons(context, kind, sons, c.idgen).toNode(traitCall.info)

  if operand.kind == tyGenericParam or (traitCall.len > 2 and operand2.kind == tyGenericParam):
    return traitCall  ## too early to evaluate

  let s = trait.sym.name.s
  case s
  of "or", "|":
    return typeWithSonsResult(tyOr, @[operand, operand2])
  of "and":
    return typeWithSonsResult(tyAnd, @[operand, operand2])
  of "not":
    return typeWithSonsResult(tyNot, @[operand])
  of "typeToString":
    var prefer = preferTypeName
    if traitCall.len >= 2:
      let preferStr = traitCall[2].strVal
      prefer = parseEnum[TPreferedDesc](preferStr)
    result = newStrNode(nkStrLit, operand.typeToString(prefer))
    result.typ = getSysType(c.graph, traitCall[1].info, tyString)
    result.info = traitCall.info
  of "name", "$":
    result = newStrNode(nkStrLit, operand.typeToString(preferTypeName))
    result.typ = getSysType(c.graph, traitCall[1].info, tyString)
    result.info = traitCall.info
  of "arity":
    result = newIntNode(nkIntLit, operand.len - ord(operand.kind==tyProc))
    result.typ = newType(tyInt, nextTypeId c.idgen, context)
    result.info = traitCall.info
  of "genericHead":
    var arg = operand
    case arg.kind
    of tyGenericInst:
      result = getTypeDescNode(c, arg.base, operand.owner, traitCall.info)
    # of tySequence: # this doesn't work
    #   var resType = newType(tySequence, operand.owner)
    #   result = toNode(resType, traitCall.info) # doesn't work yet
    else:
      localError(c.config, traitCall.info, "expected generic type, got: type $2 of kind $1" % [arg.kind.toHumanStr, typeToString(operand)])
      result = newType(tyError, nextTypeId c.idgen, context).toNode(traitCall.info)
  of "stripGenericParams":
    result = uninstantiate(operand).toNode(traitCall.info)
  of "supportsCopyMem":
    let t = operand.skipTypes({tyVar, tyLent, tyGenericInst, tyAlias, tySink, tyInferred})
    let complexObj = containsGarbageCollectedRef(t) or
                     hasDestructor(t)
    result = newIntNodeT(toInt128(ord(not complexObj)), traitCall, c.idgen, c.graph)
  of "isNamedTuple":
    var operand = operand.skipTypes({tyGenericInst})
    let cond = operand.kind == tyTuple and operand.n != nil
    result = newIntNodeT(toInt128(ord(cond)), traitCall, c.idgen, c.graph)
  of "tupleLen":
    var operand = operand.skipTypes({tyGenericInst})
    assert operand.kind == tyTuple, $operand.kind
    result = newIntNodeT(toInt128(operand.len), traitCall, c.idgen, c.graph)
  of "distinctBase":
    var arg = operand.skipTypes({tyGenericInst})
    let rec = semConstExpr(c, traitCall[2]).intVal != 0
    while arg.kind == tyDistinct:
      arg = arg.base.skipTypes(skippedTypes + {tyGenericInst})
      if not rec: break
    result = getTypeDescNode(c, arg, operand.owner, traitCall.info)
  of "isCyclic":
    var operand = operand.skipTypes({tyGenericInst})
    let isCyclic = canFormAcycle(c.graph, operand)
    result = newIntNodeT(toInt128(ord(isCyclic)), traitCall, c.idgen, c.graph)
  else:
    localError(c.config, traitCall.info, "unknown trait: " & s)
    result = newNodeI(nkEmpty, traitCall.info)

proc semTypeTraits(c: PContext, n: PNode): PNode =
  checkMinSonsLen(n, 2, c.config)
  let t = n[1].typ
  internalAssert c.config, t != nil and t.kind == tyTypeDesc
  if t.len > 0:
    # This is either a type known to sem or a typedesc
    # param to a regular proc (again, known at instantiation)
    result = evalTypeTrait(c, n, t, getCurrOwner(c))
  else:
    # a typedesc variable, pass unmodified to evals
    result = n

proc semOrd(c: PContext, n: PNode): PNode =
  result = n
  let parType = n[1].typ
  if isOrdinalType(parType, allowEnumWithHoles=true):
    discard
  else:
    localError(c.config, n.info, errOrdinalTypeExpected)
    result.typ = errorType(c)

proc semBindSym(c: PContext, n: PNode): PNode =
  result = copyNode(n)
  result.add(n[0])

  let sl = semConstExpr(c, n[1])
  if sl.kind notin {nkStrLit, nkRStrLit, nkTripleStrLit}:
    return localErrorNode(c, n, n[1].info, errStringLiteralExpected)

  let isMixin = semConstExpr(c, n[2])
  if isMixin.kind != nkIntLit or isMixin.intVal < 0 or
      isMixin.intVal > high(TSymChoiceRule).int:
    return localErrorNode(c, n, n[2].info, errConstExprExpected)

  let id = newIdentNode(getIdent(c.cache, sl.strVal), n.info)
  let s = qualifiedLookUp(c, id, {checkUndeclared})
  if s != nil:
    # we need to mark all symbols:
    var sc = symChoice(c, id, s, TSymChoiceRule(isMixin.intVal))
    if not (c.inStaticContext > 0 or getCurrOwner(c).isCompileTimeProc):
      # inside regular code, bindSym resolves to the sym-choice
      # nodes (see tinspectsymbol)
      return sc
    result.add(sc)
  else:
    errorUndeclaredIdentifier(c, n[1].info, sl.strVal)

proc opBindSym(c: PContext, scope: PScope, n: PNode, isMixin: int, info: PNode): PNode =
  if n.kind notin {nkStrLit, nkRStrLit, nkTripleStrLit, nkIdent}:
    return localErrorNode(c, n, info.info, errStringOrIdentNodeExpected)

  if isMixin < 0 or isMixin > high(TSymChoiceRule).int:
    return localErrorNode(c, n, info.info, errConstExprExpected)

  let id = if n.kind == nkIdent: n
    else: newIdentNode(getIdent(c.cache, n.strVal), info.info)

  let tmpScope = c.currentScope
  c.currentScope = scope
  let s = qualifiedLookUp(c, id, {checkUndeclared})
  if s != nil:
    # we need to mark all symbols:
    result = symChoice(c, id, s, TSymChoiceRule(isMixin))
  else:
    errorUndeclaredIdentifier(c, info.info, if n.kind == nkIdent: n.ident.s
      else: n.strVal)
  c.currentScope = tmpScope

proc semDynamicBindSym(c: PContext, n: PNode): PNode =
  # inside regular code, bindSym resolves to the sym-choice
  # nodes (see tinspectsymbol)
  if not (c.inStaticContext > 0 or getCurrOwner(c).isCompileTimeProc):
    return semBindSym(c, n)

  if c.graph.vm.isNil:
    setupGlobalCtx(c.module, c.graph, c.idgen)

  let
    vm = PCtx c.graph.vm
    # cache the current scope to
    # prevent it lost into oblivion
    scope = c.currentScope

  # cannot use this
  # vm.config.features.incl dynamicBindSym

  proc bindSymWrapper(a: VmArgs) =
    # capture PContext and currentScope
    # param description:
    #   0. ident, a string literal / computed string / or ident node
    #   1. bindSym rule
    #   2. info node
    a.setResult opBindSym(c, scope, a.getNode(0), a.getInt(1).int, a.getNode(2))

  let
    # although we use VM callback here, it is not
    # executed like 'normal' VM callback
    idx = vm.registerCallback("bindSymImpl", bindSymWrapper)
    # dummy node to carry idx information to VM
    idxNode = newIntTypeNode(idx, c.graph.getSysType(TLineInfo(), tyInt))

  result = copyNode(n)
  for x in n: result.add x
  result.add n # info node
  result.add idxNode

proc semShallowCopy(c: PContext, n: PNode, flags: TExprFlags): PNode

proc semOf(c: PContext, n: PNode): PNode =
  if n.len == 3:
    n[1] = semExprWithType(c, n[1])
    n[2] = semExprWithType(c, n[2], {efDetermineType})
    #restoreOldStyleType(n[1])
    #restoreOldStyleType(n[2])
    let a = skipTypes(n[1].typ, abstractPtrs)
    let b = skipTypes(n[2].typ, abstractPtrs)
    let x = skipTypes(n[1].typ, abstractPtrs-{tyTypeDesc})
    let y = skipTypes(n[2].typ, abstractPtrs-{tyTypeDesc})

    if x.kind == tyTypeDesc or y.kind != tyTypeDesc:
      localError(c.config, n.info, "'of' takes object types")
    elif b.kind != tyObject or a.kind != tyObject:
      localError(c.config, n.info, "'of' takes object types")
    else:
      let diff = inheritanceDiff(a, b)
      # | returns: 0 iff `a` == `b`
      # | returns: -x iff `a` is the x'th direct superclass of `b`
      # | returns: +x iff `a` is the x'th direct subclass of `b`
      # | returns: `maxint` iff `a` and `b` are not compatible at all
      if diff <= 0:
        # optimize to true:
        message(c.config, n.info, hintConditionAlwaysTrue, renderTree(n))
        result = newIntNode(nkIntLit, 1)
        result.info = n.info
        result.typ = getSysType(c.graph, n.info, tyBool)
        return result
      elif diff == high(int):
        if commonSuperclass(a, b) == nil:
          localError(c.config, n.info, "'$1' cannot be of this subtype" % typeToString(a))
        else:
          message(c.config, n.info, hintConditionAlwaysFalse, renderTree(n))
          result = newIntNode(nkIntLit, 0)
          result.info = n.info
          result.typ = getSysType(c.graph, n.info, tyBool)
  else:
    localError(c.config, n.info, "'of' takes 2 arguments")
  n.typ = getSysType(c.graph, n.info, tyBool)
  result = n

proc semUnown(c: PContext; n: PNode): PNode =
  proc unownedType(c: PContext; t: PType): PType =
    case t.kind
    of tyTuple:
      var elems = newSeq[PType](t.len)
      var someChange = false
      for i in 0..<t.len:
        elems[i] = unownedType(c, t[i])
        if elems[i] != t[i]: someChange = true
      if someChange:
        result = newType(tyTuple, nextTypeId c.idgen, t.owner)
        # we have to use 'rawAddSon' here so that type flags are
        # properly computed:
        for e in elems: result.rawAddSon(e)
      else:
        result = t
    of tyOwned: result = t[0]
    of tySequence, tyOpenArray, tyArray, tyVarargs, tyVar, tyLent,
       tyGenericInst, tyAlias:
      let b = unownedType(c, t[^1])
      if b != t[^1]:
        result = copyType(t, nextTypeId c.idgen, t.owner)
        copyTypeProps(c.graph, c.idgen.module, result, t)

        result[^1] = b
        result.flags.excl tfHasOwned
      else:
        result = t
    else:
      result = t

  result = copyTree(n[1])
  result.typ = unownedType(c, result.typ)
  # little hack for injectdestructors.nim (see bug #11350):
  #result[0].typ = nil

proc turnFinalizerIntoDestructor(c: PContext; orig: PSym; info: TLineInfo): PSym =
  # We need to do 2 things: Replace n.typ which is a 'ref T' by a 'var T' type.
  # Replace nkDerefExpr by nkHiddenDeref
  # nkDeref is for 'ref T':  x[].field
  # nkHiddenDeref is for 'var T': x<hidden deref [] here>.field
  proc transform(c: PContext; procSym: PSym; n: PNode; old, fresh: PType; oldParam, newParam: PSym): PNode =
    result = shallowCopy(n)
    if sameTypeOrNil(n.typ, old):
      result.typ = fresh
    if n.kind == nkSym:
      if n.sym == oldParam:
        result.sym = newParam
      elif n.sym.owner == orig:
        result.sym = copySym(n.sym, nextSymId c.idgen)
        result.sym.owner = procSym
    for i in 0 ..< safeLen(n):
      result[i] = transform(c, procSym, n[i], old, fresh, oldParam, newParam)
    #if n.kind == nkDerefExpr and sameType(n[0].typ, old):
    #  result =

  result = copySym(orig, nextSymId c.idgen)
  result.info = info
  result.flags.incl sfFromGeneric
  result.owner = orig
  let origParamType = orig.typ[1]
  let newParamType = makeVarType(result, origParamType.skipTypes(abstractPtrs), c.idgen)
  let oldParam = orig.typ.n[1].sym
  let newParam = newSym(skParam, oldParam.name, nextSymId c.idgen, result, result.info)
  newParam.typ = newParamType
  # proc body:
  result.ast = transform(c, result, orig.ast, origParamType, newParamType, oldParam, newParam)
  # proc signature:
  result.typ = newProcType(result.info, nextTypeId c.idgen, result)
  result.typ.addParam newParam

proc semQuantifier(c: PContext; n: PNode): PNode =
  checkSonsLen(n, 2, c.config)
  openScope(c)
  result = newNodeIT(n.kind, n.info, n.typ)
  result.add n[0]
  let args = n[1]
  assert args.kind == nkArgList
  for i in 0..args.len-2:
    let it = args[i]
    var valid = false
    if it.kind == nkInfix:
      let op = considerQuotedIdent(c, it[0])
      if op.id == ord(wIn):
        let v = newSymS(skForVar, it[1], c)
        styleCheckDef(c, v)
        onDef(it[1].info, v)
        let domain = semExprWithType(c, it[2], {efWantIterator})
        v.typ = domain.typ
        valid = true
        addDecl(c, v)
        result.add newTree(nkInfix, it[0], newSymNode(v), domain)
    if not valid:
      localError(c.config, n.info, "<quantifier> 'in' <range> expected")
  result.add forceBool(c, semExprWithType(c, args[^1]))
  closeScope(c)

proc semOld(c: PContext; n: PNode): PNode =
  if n[1].kind == nkHiddenDeref:
    n[1] = n[1][0]
  if n[1].kind != nkSym or n[1].sym.kind != skParam:
    localError(c.config, n[1].info, "'old' takes a parameter name")
  elif n[1].sym.owner != getCurrOwner(c):
    localError(c.config, n[1].info, n[1].sym.name.s & " does not belong to " & getCurrOwner(c).name.s)
  result = n

proc semPrivateAccess(c: PContext, n: PNode): PNode =
  let t = n[1].typ[0].toObjectFromRefPtrGeneric
  c.currentScope.allowPrivateAccess.add t.sym
  result = newNodeIT(nkEmpty, n.info, getSysType(c.graph, n.info, tyVoid))

proc magicsAfterOverloadResolution(c: PContext, n: PNode,
                                   flags: TExprFlags; expectedType: PType = nil): PNode =
  ## This is the preferred code point to implement magics.
  ## ``c`` the current module, a symbol table to a very good approximation
  ## ``n`` the ast like it would be passed to a real macro
  ## ``flags`` Some flags for more contextual information on how the
  ## "macro" is calld.

  case n[0].sym.magic
  of mAddr:
    checkSonsLen(n, 2, c.config)
    result = n
    result[1] = semAddrArg(c, n[1], n[0].sym.name.s == "unsafeAddr")
    result.typ = makePtrType(c, result[1].typ)
  of mTypeOf:
    result = semTypeOf(c, n)
  of mSizeOf:
    result = foldSizeOf(c.config, n, n)
  of mAlignOf:
    result = foldAlignOf(c.config, n, n)
  of mOffsetOf:
    result = foldOffsetOf(c.config, n, n)
  of mArrGet:
    result = semArrGet(c, n, flags)
  of mArrPut:
    result = semArrPut(c, n, flags)
  of mAsgn:
    if n[0].sym.name.s == "=":
      result = semAsgnOpr(c, n)
    else:
      result = semShallowCopy(c, n, flags)
  of mIsPartOf: result = semIsPartOf(c, n, flags)
  of mTypeTrait: result = semTypeTraits(c, n)
  of mAstToStr:
    result = newStrNodeT(renderTree(n[1], {renderNoComments}), n, c.graph)
    result.typ = getSysType(c.graph, n.info, tyString)
  of mInstantiationInfo: result = semInstantiationInfo(c, n)
  of mOrd: result = semOrd(c, n)
  of mOf: result = semOf(c, n)
  of mHigh, mLow: result = semLowHigh(c, n, n[0].sym.magic)
  of mShallowCopy: result = semShallowCopy(c, n, flags)
  of mNBindSym:
    if dynamicBindSym notin c.features:
      result = semBindSym(c, n)
    else:
      result = semDynamicBindSym(c, n)
  of mProcCall:
    result = n
    result.typ = n[1].typ
  of mDotDot:
    result = n
  of mPlugin:
    let plugin = getPlugin(c.cache, n[0].sym)
    if plugin.isNil:
      localError(c.config, n.info, "cannot find plugin " & n[0].sym.name.s)
      result = n
    else:
      result = plugin(c, n)
  of mNewFinalize:
    # Make sure the finalizer procedure refers to a procedure
    if n[^1].kind == nkSym and n[^1].sym.kind notin {skProc, skFunc}:
      localError(c.config, n.info, "finalizer must be a direct reference to a proc")
    elif optTinyRtti in c.config.globalOptions:
      let nfin = skipConvCastAndClosure(n[^1])
      let fin = case nfin.kind
        of nkSym: nfin.sym
        of nkLambda, nkDo: nfin[namePos].sym
        else:
          localError(c.config, n.info, "finalizer must be a direct reference to a proc")
          nil
      if fin != nil:
        if fin.kind notin {skProc, skFunc}:
          # calling convention is checked in codegen
          localError(c.config, n.info, "finalizer must be a direct reference to a proc")

        # check if we converted this finalizer into a destructor already:
        let t = whereToBindTypeHook(c, fin.typ[1].skipTypes(abstractInst+{tyRef}))
        if t != nil and getAttachedOp(c.graph, t, attachedDestructor) != nil and
            getAttachedOp(c.graph, t, attachedDestructor).owner == fin:
          discard "already turned this one into a finalizer"
        else:
          bindTypeHook(c, turnFinalizerIntoDestructor(c, fin, n.info), n, attachedDestructor)
    result = n
  of mDestroy:
    result = n
    let t = n[1].typ.skipTypes(abstractVar)
    let op = getAttachedOp(c.graph, t, attachedDestructor)
    if op != nil:
      result[0] = newSymNode(op)
  of mTrace:
    result = n
    let t = n[1].typ.skipTypes(abstractVar)
    let op = getAttachedOp(c.graph, t, attachedTrace)
    if op != nil:
      result[0] = newSymNode(op)
  of mUnown:
    result = semUnown(c, n)
  of mExists, mForall:
    result = semQuantifier(c, n)
  of mOld:
    result = semOld(c, n)
  of mSetLengthSeq:
    result = n
    let seqType = result[1].typ.skipTypes({tyPtr, tyRef, # in case we had auto-dereferencing
                                           tyVar, tyGenericInst, tyOwned, tySink,
                                           tyAlias, tyUserTypeClassInst})
    if seqType.kind == tySequence and seqType.base.requiresInit:
      message(c.config, n.info, warnUnsafeSetLen, typeToString(seqType.base))
  of mDefault:
    result = n
    c.config.internalAssert result[1].typ.kind == tyTypeDesc
    let constructed = result[1].typ.base
    if constructed.requiresInit:
      message(c.config, n.info, warnUnsafeDefault, typeToString(constructed))
  of mIsolate:
    if not checkIsolate(n[1]):
      localError(c.config, n.info, "expression cannot be isolated: " & $n[1])
    result = n
  of mPred:
    if n[1].typ.skipTypes(abstractInst).kind in {tyUInt..tyUInt64}:
      n[0].sym.magic = mSubU
    result = n
  of mPrivateAccess:
    result = semPrivateAccess(c, n)
  of mArrToSeq:
    result = n
    if result.typ != nil and expectedType != nil and result.typ.kind == tySequence and expectedType.kind == tySequence and result.typ[0].kind == tyEmpty:
      result.typ = expectedType # type inference for empty sequence # bug #21377
  else:
    result = n
