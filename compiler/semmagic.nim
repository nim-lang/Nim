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

proc skipAddr(n: PNode): PNode {.inline.} =
  (if n.kind == nkHiddenAddr: n.sons[0] else: n)

proc semArrGet(c: PContext; n: PNode; flags: TExprFlags): PNode =
  result = newNodeI(nkBracketExpr, n.info)
  for i in 1..<n.len: result.add(n[i])
  result = semSubscript(c, result, flags)
  if result.isNil:
    let x = copyTree(n)
    x.sons[0] = newIdentNode(getIdent(c.cache, "[]"), n.info)
    bracketNotFoundError(c, x)
    #localError(c.config, n.info, "could not resolve: " & $n)
    result = n

proc semArrPut(c: PContext; n: PNode; flags: TExprFlags): PNode =
  # rewrite `[]=`(a, i, x)  back to ``a[i] = x``.
  let b = newNodeI(nkBracketExpr, n.info)
  b.add(n[1].skipAddr)
  for i in 2..n.len-2: b.add(n[i])
  result = newNodeI(nkAsgn, n.info, 2)
  result.sons[0] = b
  result.sons[1] = n.lastSon
  result = semAsgn(c, result, noOverloadedSubscript)

proc semAsgnOpr(c: PContext; n: PNode): PNode =
  result = newNodeI(nkAsgn, n.info, 2)
  result.sons[0] = n[1]
  result.sons[1] = n[2]
  result = semAsgn(c, result, noOverloadedAsgn)

proc semIsPartOf(c: PContext, n: PNode, flags: TExprFlags): PNode =
  var r = isPartOf(n[1], n[2])
  result = newIntNodeT(ord(r), n, c.graph)

proc expectIntLit(c: PContext, n: PNode): int =
  let x = c.semConstExpr(c, n)
  case x.kind
  of nkIntLit..nkInt64Lit: result = int(x.intVal)
  else: localError(c.config, n.info, errIntLiteralExpected)

proc semInstantiationInfo(c: PContext, n: PNode): PNode =
  result = newNodeIT(nkTupleConstr, n.info, n.typ)
  let idx = expectIntLit(c, n.sons[1])
  let useFullPaths = expectIntLit(c, n.sons[2])
  let info = getInfoContext(c.config, idx)
  var filename = newNodeIT(nkStrLit, n.info, getSysType(c.graph, n.info, tyString))
  filename.strVal = if useFullPaths != 0: toFullPath(c.config, info) else: toFilename(c.config, info)
  var line = newNodeIT(nkIntLit, n.info, getSysType(c.graph, n.info, tyInt))
  line.intVal = toLinenumber(info)
  var column = newNodeIT(nkIntLit, n.info, getSysType(c.graph, n.info, tyInt))
  column.intVal = toColumn(info)
  result.add(filename)
  result.add(line)
  result.add(column)

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
    of tyCompositeTypeClass: uninstantiate t.sons[1]
    else: t

proc evalTypeTrait(c: PContext; traitCall: PNode, operand: PType, context: PSym): PNode =
  const skippedTypes = {tyTypeDesc, tyAlias, tySink}
  let trait = traitCall[0]
  internalAssert c.config, trait.kind == nkSym
  var operand = operand.skipTypes(skippedTypes)

  template operand2: PType =
    traitCall.sons[2].typ.skipTypes({tyTypeDesc})

  template typeWithSonsResult(kind, sons): PNode =
    newTypeWithSons(context, kind, sons).toNode(traitCall.info)

  let s = trait.sym.name.s
  case s
  of "or", "|":
    return typeWithSonsResult(tyOr, @[operand, operand2])
  of "and":
    return typeWithSonsResult(tyAnd, @[operand, operand2])
  of "not":
    return typeWithSonsResult(tyNot, @[operand])
  of "name", "$":
    result = newStrNode(nkStrLit, operand.typeToString(preferTypeName))
    result.typ = newType(tyString, context)
    result.info = traitCall.info
  of "arity":
    result = newIntNode(nkIntLit, operand.len - ord(operand.kind==tyProc))
    result.typ = newType(tyInt, context)
    result.info = traitCall.info
  of "genericHead":
    var res = uninstantiate(operand)
    if res == operand and res.kind notin tyMagicGenerics:
      localError(c.config, traitCall.info,
        "genericHead expects a generic type. The given type was " &
        typeToString(operand))
      return newType(tyError, context).toNode(traitCall.info)
    result = res.base.toNode(traitCall.info)
  of "stripGenericParams":
    result = uninstantiate(operand).toNode(traitCall.info)
  of "supportsCopyMem":
    let t = operand.skipTypes({tyVar, tyLent, tyGenericInst, tyAlias, tySink, tyInferred})
    let complexObj = containsGarbageCollectedRef(t) or
                     hasDestructor(t)
    result = newIntNodeT(ord(not complexObj), traitCall, c.graph)
  else:
    localError(c.config, traitCall.info, "unknown trait: " & s)
    result = newNodeI(nkEmpty, traitCall.info)

proc semTypeTraits(c: PContext, n: PNode): PNode =
  checkMinSonsLen(n, 2, c.config)
  let t = n.sons[1].typ
  internalAssert c.config, t != nil and t.kind == tyTypeDesc
  if t.sonsLen > 0:
    # This is either a type known to sem or a typedesc
    # param to a regular proc (again, known at instantiation)
    result = evalTypeTrait(c, n, t, getCurrOwner(c))
  else:
    # a typedesc variable, pass unmodified to evals
    result = n

proc semOrd(c: PContext, n: PNode): PNode =
  result = n
  let parType = n.sons[1].typ
  if isOrdinalType(parType, allowEnumWithHoles=true):
    discard
  elif parType.kind == tySet:
    result.typ = makeRangeType(c, firstOrd(c.config, parType), lastOrd(c.config, parType), n.info)
  else:
    localError(c.config, n.info, errOrdinalTypeExpected)
    result.typ = errorType(c)

proc semBindSym(c: PContext, n: PNode): PNode =
  result = copyNode(n)
  result.add(n.sons[0])

  let sl = semConstExpr(c, n.sons[1])
  if sl.kind notin {nkStrLit, nkRStrLit, nkTripleStrLit}:
    localError(c.config, n.sons[1].info, errStringLiteralExpected)
    return errorNode(c, n)

  let isMixin = semConstExpr(c, n.sons[2])
  if isMixin.kind != nkIntLit or isMixin.intVal < 0 or
      isMixin.intVal > high(TSymChoiceRule).int:
    localError(c.config, n.sons[2].info, errConstExprExpected)
    return errorNode(c, n)

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
    errorUndeclaredIdentifier(c, n.sons[1].info, sl.strVal)

proc opBindSym(c: PContext, scope: PScope, n: PNode, isMixin: int, info: PNode): PNode =
  if n.kind notin {nkStrLit, nkRStrLit, nkTripleStrLit, nkIdent}:
    localError(c.config, info.info, errStringOrIdentNodeExpected)
    return errorNode(c, n)

  if isMixin < 0 or isMixin > high(TSymChoiceRule).int:
    localError(c.config, info.info, errConstExprExpected)
    return errorNode(c, n)

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
    setupGlobalCtx(c.module, c.graph)

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
    # altough we use VM callback here, it is not
    # executed like 'normal' VM callback
    idx = vm.registerCallback("bindSymImpl", bindSymWrapper)
    # dummy node to carry idx information to VM
    idxNode = newIntTypeNode(nkIntLit, idx, c.graph.getSysType(TLineInfo(), tyInt))

  result = copyNode(n)
  for x in n: result.add x
  result.add n # info node
  result.add idxNode

proc semShallowCopy(c: PContext, n: PNode, flags: TExprFlags): PNode

proc semOf(c: PContext, n: PNode): PNode =
  if sonsLen(n) == 3:
    n.sons[1] = semExprWithType(c, n.sons[1])
    n.sons[2] = semExprWithType(c, n.sons[2], {efDetermineType})
    #restoreOldStyleType(n.sons[1])
    #restoreOldStyleType(n.sons[2])
    let a = skipTypes(n.sons[1].typ, abstractPtrs)
    let b = skipTypes(n.sons[2].typ, abstractPtrs)
    let x = skipTypes(n.sons[1].typ, abstractPtrs-{tyTypeDesc})
    let y = skipTypes(n.sons[2].typ, abstractPtrs-{tyTypeDesc})

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

proc magicsAfterOverloadResolution(c: PContext, n: PNode,
                                   flags: TExprFlags): PNode =
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
    # TODO there is no proper way to find out if a type cannot be queried for the size.
    let size = getSize(c.config, n[1].typ)
    # We just assume here that the type might come from the c backend
    if size == szUnknownSize:
      # Forward to the c code generation to emit a `sizeof` in the C code.
      result = n
    elif size >= 0:
      result = newIntNode(nkIntLit, size)
      result.info = n.info
      result.typ = n.typ
    else:
      localError(c.config, n.info, "cannot evaluate 'sizeof' because its type is not defined completely, type: " & n[1].typ.typeToString)
      result = n
  of mAlignOf:
    # this is 100% analog to mSizeOf, could be made more dry.
    let align = getAlign(c.config, n[1].typ)
    if align == szUnknownSize:
      result = n
    elif align >= 0:
      result = newIntNode(nkIntLit, align)
      result.info = n.info
      result.typ = n.typ
    else:
      localError(c.config, n.info, "cannot evaluate 'alignof' because its type is not defined completely, type: " & n[1].typ.typeToString)
      result = n
  of mOffsetOf:
    var dotExpr: PNode

    block findDotExpr:
      if n[1].kind == nkDotExpr:
        dotExpr = n[1]
      elif n[1].kind == nkCheckedFieldExpr:
        dotExpr = n[1][0]
      else:
        illFormedAst(n, c.config)

    assert dotExpr != nil

    let value = dotExpr[0]
    let member = dotExpr[1]

    discard computeSize(c.config, value.typ)

    result = newIntNode(nkIntLit, member.sym.offset)
    result.info = n.info
    result.typ = n.typ
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
  of mRoof:
    localError(c.config, n.info, "builtin roof operator is not supported anymore")
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
      localError(c.config, n.info, "finalizer must be a direct reference to a procedure")
    result = n
  of mDestroy:
    result = n
    let t = n[1].typ.skipTypes(abstractVar)
    if t.destructor != nil:
      result.sons[0] = newSymNode(t.destructor)
  else: result = n
