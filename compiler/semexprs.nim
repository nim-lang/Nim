#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking for expressions
# included from sem.nim

proc restoreOldStyleType(n: PNode) =
  # XXX: semExprWithType used to return the same type
  # for nodes such as (100) or (int). 
  # This is inappropriate. The type of the first expression
  # should be "int", while the type of the second one should 
  # be typedesc(int).
  #
  # This is strictly for backward compatibility until 
  # the transition to types as first-class values is complete.
  n.typ = n.typ.skipTypes({tyTypeDesc})

proc semTemplateExpr(c: PContext, n: PNode, s: PSym, semCheck = true): PNode = 
  markUsed(n, s)
  pushInfoContext(n.info)
  result = evalTemplate(n, s)
  if semCheck: result = semAfterMacroCall(c, result, s)
  popInfoContext()

proc semFieldAccess(c: PContext, n: PNode, flags: TExprFlags = {}): PNode

proc newDeref(n: PNode): PNode {.inline.} =  
  result = newNodeIT(nkHiddenDeref, n.info, n.typ.sons[0])
  addSon(result, n)

proc semExprWithType(c: PContext, n: PNode, flags: TExprFlags = {}): PNode = 
  result = semExpr(c, n, flags)
  if result.kind == nkEmpty: 
    # do not produce another redundant error message:
    raiseRecoverableError("")
  if result.typ != nil: 
    if result.typ.kind == tyVar: result = newDeref(result)
  else:
    GlobalError(n.info, errExprXHasNoType, 
                renderTree(result, {renderNoComments}))

proc semExprNoDeref(c: PContext, n: PNode, flags: TExprFlags = {}): PNode = 
  result = semExpr(c, n, flags)
  if result.kind == nkEmpty: 
    # do not produce another redundant error message:
    raiseRecoverableError("")
  if result.typ == nil:
    GlobalError(n.info, errExprXHasNoType, 
                renderTree(result, {renderNoComments}))

proc semSymGenericInstantiation(c: PContext, n: PNode, s: PSym): PNode =
  result = symChoice(c, n, s)
  
proc inlineConst(n: PNode, s: PSym): PNode {.inline.} =
  result = copyTree(s.ast)
  result.typ = s.typ
  result.info = n.info

proc illegalCapture(s: PSym): bool {.inline.} =
  result = skipTypes(s.typ, abstractInst).kind in {tyVar, tyOpenArray} or
      s.kind == skResult

proc semSym(c: PContext, n: PNode, s: PSym, flags: TExprFlags): PNode = 
  case s.kind
  of skProc, skMethod, skIterator, skConverter: 
    var smoduleId = getModule(s).id
    if sfProcVar notin s.flags and s.typ.callConv == ccDefault and
        smoduleId != c.module.id and smoduleId != c.friendModule.id: 
      LocalError(n.info, errXCannotBePassedToProcVar, s.name.s)
    result = symChoice(c, n, s)
    if result.kind == nkSym:
      markIndirect(c, result.sym)
      if isGenericRoutine(result.sym):
        LocalError(n.info, errInstantiateXExplicitely, s.name.s)
  of skConst:
    markUsed(n, s)
    case skipTypes(s.typ, abstractInst).kind
    of  tyNil, tyChar, tyInt..tyInt64, tyFloat..tyFloat128, 
        tyTuple, tySet, tyUInt..tyUInt64:
      result = inlineConst(n, s)
    of tyArrayConstr, tySequence:
      # Consider::
      #     const x = []
      #     proc p(a: openarray[int])
      #     proc q(a: openarray[char])
      #     p(x)
      #     q(x)
      #
      # It is clear that ``[]`` means two totally different things. Thus, we
      # copy `x`'s AST into each context, so that the type fixup phase can
      # deal with two different ``[]``.
      if s.ast.len == 0: result = inlineConst(n, s)
      else: result = newSymNode(s, n.info)
    else:
      result = newSymNode(s, n.info)
  of skMacro: result = semMacroExpr(c, n, s)
  of skTemplate: result = semTemplateExpr(c, n, s)
  of skVar, skLet, skResult, skParam, skForVar:
    markUsed(n, s)
    # if a proc accesses a global variable, it is not side effect free:
    if sfGlobal in s.flags:
      incl(c.p.owner.flags, sfSideEffect)
    elif s.kind == skParam and s.typ.kind == tyExpr:
      return s.typ.n
    elif s.owner != c.p.owner and s.owner.kind != skModule and 
        c.p.owner.typ != nil and not IsGenericRoutine(s.owner):
      c.p.owner.typ.callConv = ccClosure
      if illegalCapture(s) or c.p.next.owner != s.owner:
        # Currently captures are restricted to a single level of nesting:
        GlobalError(n.info, errIllegalCaptureX, s.name.s)
    result = newSymNode(s, n.info)
  of skGenericParam:
    if s.ast == nil: InternalError(n.info, "no default for")
    result = semExpr(c, s.ast)
  of skType:
    markUsed(n, s)
    result = newSymNode(s, n.info)
    result.typ = makeTypeDesc(c, s.typ)
  else:
    markUsed(n, s)
    result = newSymNode(s, n.info)
  
proc checkConversionBetweenObjects(info: TLineInfo, castDest, src: PType) =
  var diff = inheritanceDiff(castDest, src)
  if diff == high(int):
    GlobalError(info, errGenerated, MsgKindToString(errIllegalConvFromXtoY) % [
        src.typeToString, castDest.typeToString])

const 
  IntegralTypes = {tyBool, tyEnum, tyChar, tyInt..tyUInt64}

proc checkConvertible(info: TLineInfo, castDest, src: PType) = 
  if sameType(castDest, src) and castDest.sym == src.sym: 
    # don't annoy conversions that may be needed on another processor:
    if castDest.kind notin IntegralTypes+{tyRange}:
      Message(info, hintConvFromXtoItselfNotNeeded, typeToString(castDest))
    return
  var d = skipTypes(castDest, abstractVar)
  var s = skipTypes(src, abstractVar)
  while (d != nil) and (d.Kind in {tyPtr, tyRef}) and (d.Kind == s.Kind): 
    d = base(d)
    s = base(s)
  if d == nil:
    GlobalError(info, errGenerated, msgKindToString(errIllegalConvFromXtoY) % [
        src.typeToString, castDest.typeToString])
  elif d.Kind == tyObject and s.Kind == tyObject: 
    checkConversionBetweenObjects(info, d, s)
  elif (skipTypes(castDest, abstractVarRange).Kind in IntegralTypes) and
      (skipTypes(src, abstractVarRange).Kind in IntegralTypes): 
    # accept conversion between integral types
  else: 
    # we use d, s here to speed up that operation a bit:
    case cmpTypes(d, s)
    of isNone, isGeneric: 
      if not compareTypes(castDest, src, dcEqIgnoreDistinct):
        GlobalError(info, errGenerated, `%`(
            MsgKindToString(errIllegalConvFromXtoY), 
            [typeToString(src), typeToString(castDest)]))
    else: 
      nil

proc isCastable(dst, src: PType): bool = 
  #const
  #  castableTypeKinds = {tyInt, tyPtr, tyRef, tyCstring, tyString, 
  #                       tySequence, tyPointer, tyNil, tyOpenArray,
  #                       tyProc, tySet, tyEnum, tyBool, tyChar}
  var ds, ss: biggestInt
  # this is very unrestrictive; cast is allowed if castDest.size >= src.size
  ds = computeSize(dst)
  ss = computeSize(src)
  if ds < 0: 
    result = false
  elif ss < 0: 
    result = false
  else: 
    result = (ds >= ss) or
        (skipTypes(dst, abstractInst).kind in IntegralTypes) or
        (skipTypes(src, abstractInst).kind in IntegralTypes)
  
proc semConv(c: PContext, n: PNode, s: PSym): PNode = 
  if sonsLen(n) != 2: GlobalError(n.info, errConvNeedsOneArg)
  result = newNodeI(nkConv, n.info)
  result.typ = semTypeNode(c, n.sons[0], nil)
  addSon(result, copyTree(n.sons[0]))
  addSon(result, semExprWithType(c, n.sons[1]))
  var op = result.sons[1]
  if op.kind != nkSymChoice: 
    checkConvertible(result.info, result.typ, op.typ)
  else: 
    for i in countup(0, sonsLen(op) - 1):
      let it = op.sons[i]
      if sameType(result.typ, it.typ): 
        markUsed(n, it.sym)
        markIndirect(c, it.sym)
        return it
    localError(n.info, errUseQualifier, op.sons[0].sym.name.s)

proc semCast(c: PContext, n: PNode): PNode = 
  if optSafeCode in gGlobalOptions: localError(n.info, errCastNotInSafeMode)
  #incl(c.p.owner.flags, sfSideEffect)
  checkSonsLen(n, 2)
  result = newNodeI(nkCast, n.info)
  result.typ = semTypeNode(c, n.sons[0], nil)
  addSon(result, copyTree(n.sons[0]))
  addSon(result, semExprWithType(c, n.sons[1]))
  if not isCastable(result.typ, result.sons[1].Typ): 
    GlobalError(result.info, errExprCannotBeCastedToX, 
                typeToString(result.Typ))
  
proc semLowHigh(c: PContext, n: PNode, m: TMagic): PNode = 
  const 
    opToStr: array[mLow..mHigh, string] = ["low", "high"]
  if sonsLen(n) != 2: 
    GlobalError(n.info, errXExpectsTypeOrValue, opToStr[m])
  else: 
    n.sons[1] = semExprWithType(c, n.sons[1])
    restoreOldStyleType(n.sons[1])
    var typ = skipTypes(n.sons[1].typ, abstractVarRange)
    case typ.Kind
    of tySequence, tyString, tyOpenArray: 
      n.typ = getSysType(tyInt)
    of tyArrayConstr, tyArray: 
      n.typ = n.sons[1].typ.sons[0] # indextype
    of tyInt..tyInt64, tyChar, tyBool, tyEnum, tyUInt8, tyUInt16, tyUInt32: 
      n.typ = n.sons[1].typ
    else: GlobalError(n.info, errInvalidArgForX, opToStr[m])
  result = n

proc semSizeof(c: PContext, n: PNode): PNode = 
  if sonsLen(n) != 2:
    GlobalError(n.info, errXExpectsTypeOrValue, "sizeof")
  else: 
    n.sons[1] = semExprWithType(c, n.sons[1])
    restoreOldStyleType(n.sons[1])

  n.typ = getSysType(tyInt)
  result = n

proc semOf(c: PContext, n: PNode): PNode = 
  if sonsLen(n) == 3: 
    n.sons[1] = semExprWithType(c, n.sons[1])
    n.sons[2] = semExprWithType(c, n.sons[2])
    restoreOldStyleType(n.sons[1])
    restoreOldStyleType(n.sons[2])
    var a = skipTypes(n.sons[1].typ, abstractPtrs)
    var b = skipTypes(n.sons[2].typ, abstractPtrs)
    if b.kind != tyObject or a.kind != tyObject: 
      GlobalError(n.info, errXExpectsObjectTypes, "of")
    while b != nil and b.id != a.id: b = b.sons[0]
    if b == nil:
      GlobalError(n.info, errXcanNeverBeOfThisSubtype, typeToString(a))
    n.typ = getSysType(tyBool)
  else: 
    GlobalError(n.info, errXExpectsTwoArguments, "of")
  result = n

proc semIs(c: PContext, n: PNode): PNode = 
  if sonsLen(n) == 3:
    var a = semTypeNode(c, n[1], nil)
    var b = semTypeNode(c, n[2], nil)
    n.typ = getSysType(tyBool)
    n.sons[1] = newNodeIT(nkType, n[1].info, a)
    n.sons[2] = newNodeIT(nkType, n[2].info, b)
    result = n
  else:
    GlobalError(n.info, errXExpectsTwoArguments, "is")

proc semOpAux(c: PContext, n: PNode) =
  for i in countup(1, sonsLen(n) - 1):
    var a = n.sons[i]
    if a.kind == nkExprEqExpr and sonsLen(a) == 2: 
      var info = a.sons[0].info
      a.sons[0] = newIdentNode(considerAcc(a.sons[0]), info)
      a.sons[1] = semExprWithType(c, a.sons[1])
      a.typ = a.sons[1].typ
    else:
      n.sons[i] = semExprWithType(c, a)
    
proc overloadedCallOpr(c: PContext, n: PNode): PNode = 
  # quick check if there is *any* () operator overloaded:
  var par = getIdent("()")
  if SymtabGet(c.Tab, par) == nil: 
    result = nil
  else: 
    result = newNodeI(nkCall, n.info)
    addSon(result, newIdentNode(par, n.info))
    for i in countup(0, sonsLen(n) - 1): addSon(result, n.sons[i])
    result = semExpr(c, result)

proc changeType(n: PNode, newType: PType) = 
  case n.kind
  of nkCurly, nkBracket: 
    for i in countup(0, sonsLen(n) - 1): 
      changeType(n.sons[i], elemType(newType))
  of nkPar: 
    if newType.kind != tyTuple: 
      InternalError(n.info, "changeType: no tuple type for constructor")
    if newType.n == nil: nil
    elif sonsLen(n) > 0 and n.sons[0].kind == nkExprColonExpr: 
      for i in countup(0, sonsLen(n) - 1): 
        var m = n.sons[i].sons[0]
        if m.kind != nkSym: 
          internalError(m.info, "changeType(): invalid tuple constr")
        var f = getSymFromList(newType.n, m.sym.name)
        if f == nil: internalError(m.info, "changeType(): invalid identifier")
        changeType(n.sons[i].sons[1], f.typ)
    else:
      for i in countup(0, sonsLen(n) - 1):
        var m = n.sons[i]
        var a = newNodeIT(nkExprColonExpr, m.info, newType.sons[i])
        addSon(a, newSymNode(newType.n.sons[i].sym))
        addSon(a, m)
        changeType(m, newType.sons[i])
        n.sons[i] = a
  else: nil
  n.typ = newType

proc semArrayConstr(c: PContext, n: PNode): PNode = 
  result = newNodeI(nkBracket, n.info)
  result.typ = newTypeS(tyArrayConstr, c)
  rawAddSon(result.typ, nil)     # index type
  if sonsLen(n) == 0: 
    rawAddSon(result.typ, newTypeS(tyEmpty, c)) # needs an empty basetype!
  else: 
    var x = n.sons[0]
    var lastIndex: biggestInt = 0
    var indexType = getSysType(tyInt)
    if x.kind == nkExprColonExpr and sonsLen(x) == 2: 
      var idx = semConstExpr(c, x.sons[0])
      lastIndex = getOrdValue(idx)
      indexType = idx.typ
      x = x.sons[1]
    
    addSon(result, semExprWithType(c, x))
    var typ = skipTypes(result.sons[0].typ, {tyGenericInst, tyVar, tyOrdinal})
    for i in countup(1, sonsLen(n) - 1): 
      x = n.sons[i]
      if x.kind == nkExprColonExpr and sonsLen(x) == 2: 
        var idx = semConstExpr(c, x.sons[0])
        idx = fitNode(c, indexType, idx)
        if lastIndex+1 != getOrdValue(idx):
          localError(x.info, errInvalidOrderInArrayConstructor)
        x = x.sons[1]
      
      n.sons[i] = semExprWithType(c, x)
      addSon(result, fitNode(c, typ, n.sons[i]))
      inc(lastIndex)
    addSonSkipIntLit(result.typ, typ)
  result.typ.sons[0] = makeRangeType(c, 0, sonsLen(result) - 1, n.info)

proc fixAbstractType(c: PContext, n: PNode) = 
  # XXX finally rewrite that crap!
  for i in countup(1, sonsLen(n) - 1): 
    var it = n.sons[i]
    case it.kind
    of nkHiddenStdConv, nkHiddenSubConv:
      if it.sons[1].kind == nkBracket:
        it.sons[1] = semArrayConstr(c, it.sons[1])
      if skipTypes(it.typ, abstractVar).kind == tyOpenArray: 
        #if n.sons[0].kind == nkSym and IdentEq(n.sons[0].sym.name, "[]="):
        #  debug(n)
        
        var s = skipTypes(it.sons[1].typ, abstractVar)
        if s.kind == tyArrayConstr and s.sons[1].kind == tyEmpty: 
          s = copyType(s, getCurrOwner(), false)
          skipTypes(s, abstractVar).sons[1] = elemType(
              skipTypes(it.typ, abstractVar))
          it.sons[1].typ = s
        elif s.kind == tySequence and s.sons[0].kind == tyEmpty:
          s = copyType(s, getCurrOwner(), false)
          skipTypes(s, abstractVar).sons[0] = elemType(
              skipTypes(it.typ, abstractVar))
          it.sons[1].typ = s
          
      elif skipTypes(it.sons[1].typ, abstractVar).kind in
          {tyNil, tyArrayConstr, tyTuple, tySet}: 
        var s = skipTypes(it.typ, abstractVar)
        changeType(it.sons[1], s)
        n.sons[i] = it.sons[1]
    of nkBracket: 
      # an implicitely constructed array (passed to an open array):
      n.sons[i] = semArrayConstr(c, it)
    else: 
      nil
      #if (it.typ == nil): 
      #  InternalError(it.info, "fixAbstractType: " & renderTree(it))  
  
proc skipObjConv(n: PNode): PNode = 
  case n.kind
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    if skipTypes(n.sons[1].typ, abstractPtrs).kind in {tyTuple, tyObject}: 
      result = n.sons[1]
    else: 
      result = n
  of nkObjUpConv, nkObjDownConv: result = n.sons[0]
  else: result = n
  
type 
  TAssignableResult = enum 
    arNone,                   # no l-value and no discriminant
    arLValue,                 # is an l-value
    arLocalLValue,            # is an l-value, but local var; must not escape
                              # its stack frame!
    arDiscriminant            # is a discriminant

proc isAssignable(c: PContext, n: PNode): TAssignableResult = 
  result = arNone
  case n.kind
  of nkSym:
    # don't list 'skLet' here:
    if n.sym.kind in {skVar, skResult, skTemp}:
      if c.p.owner.id == n.sym.owner.id and sfGlobal notin n.sym.flags:
        result = arLocalLValue
      else:
        result = arLValue
  of nkDotExpr: 
    if skipTypes(n.sons[0].typ, abstractInst).kind in {tyVar, tyPtr, tyRef}: 
      result = arLValue
    else: 
      result = isAssignable(c, n.sons[0])
    if result != arNone and sfDiscriminant in n.sons[1].sym.flags: 
      result = arDiscriminant
  of nkBracketExpr: 
    if skipTypes(n.sons[0].typ, abstractInst).kind in {tyVar, tyPtr, tyRef}: 
      result = arLValue
    else:
      result = isAssignable(c, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    # Object and tuple conversions are still addressable, so we skip them
    if skipTypes(n.typ, abstractPtrs).kind in {tyOpenArray, tyTuple, tyObject}: 
      result = isAssignable(c, n.sons[1])
    elif compareTypes(n.typ, n.sons[1].typ, dcEqIgnoreDistinct):
      # types that are equal modulo distinction preserve l-value:
      result = isAssignable(c, n.sons[1])
  of nkHiddenDeref, nkDerefExpr: 
    result = arLValue
  of nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr: 
    result = isAssignable(c, n.sons[0])
  else: 
    nil

proc newHiddenAddrTaken(c: PContext, n: PNode): PNode = 
  if n.kind == nkHiddenDeref: 
    checkSonsLen(n, 1)
    result = n.sons[0]
  else: 
    result = newNodeIT(nkHiddenAddr, n.info, makeVarType(c, n.typ))
    addSon(result, n)
    if isAssignable(c, n) notin {arLValue, arLocalLValue}:
      localError(n.info, errVarForOutParamNeeded)

proc analyseIfAddressTaken(c: PContext, n: PNode): PNode = 
  result = n
  case n.kind
  of nkSym: 
    if skipTypes(n.sym.typ, abstractInst).kind != tyVar: 
      incl(n.sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  of nkDotExpr: 
    checkSonsLen(n, 2)
    if n.sons[1].kind != nkSym: internalError(n.info, "analyseIfAddressTaken")
    if skipTypes(n.sons[1].sym.typ, abstractInst).kind != tyVar: 
      incl(n.sons[1].sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  of nkBracketExpr: 
    checkMinSonsLen(n, 1)
    if skipTypes(n.sons[0].typ, abstractInst).kind != tyVar: 
      if n.sons[0].kind == nkSym: incl(n.sons[0].sym.flags, sfAddrTaken)
      result = newHiddenAddrTaken(c, n)
  else: 
    result = newHiddenAddrTaken(c, n) # BUGFIX!
  
proc analyseIfAddressTakenInCall(c: PContext, n: PNode) = 
  const 
    FakeVarParams = {mNew, mNewFinalize, mInc, ast.mDec, mIncl, mExcl, 
      mSetLengthStr, mSetLengthSeq, mAppendStrCh, mAppendStrStr, mSwap, 
      mAppendSeqElem, mNewSeq, mReset, mShallowCopy}
  checkMinSonsLen(n, 1)
  var t = n.sons[0].typ
  if n.sons[0].kind == nkSym and n.sons[0].sym.magic in FakeVarParams: 
    # BUGFIX: check for L-Value still needs to be done for the arguments!
    for i in countup(1, sonsLen(n) - 1): 
      if i < sonsLen(t) and t.sons[i] != nil and
          skipTypes(t.sons[i], abstractInst).kind == tyVar: 
        if isAssignable(c, n.sons[i]) notin {arLValue, arLocalLValue}: 
          LocalError(n.sons[i].info, errVarForOutParamNeeded)
    return
  for i in countup(1, sonsLen(n) - 1): 
    if i < sonsLen(t) and
        skipTypes(t.sons[i], abstractInst).kind == tyVar:
      n.sons[i] = analyseIfAddressTaken(c, n.sons[i])
  
include semmagic

proc evalAtCompileTime(c: PContext, n: PNode): PNode =
  result = n
  if n.kind notin nkCallKinds or n.sons[0].kind != nkSym: return
  var callee = n.sons[0].sym
  
  # constant folding that is necessary for correctness of semantic pass:
  if callee.magic != mNone and callee.magic in ctfeWhitelist and n.typ != nil:
    var call = newNodeIT(nkCall, n.info, n.typ)
    call.add(n.sons[0])
    var allConst = true
    for i in 1 .. < n.len:
      let a = getConstExpr(c.module, n.sons[i])
      if a != nil: call.add(a)
      else:
        allConst = false
        call.add(n.sons[i])
    if allConst:
      result = semfold.getConstExpr(c.module, call)
      if result.isNil: result = n
      else: return result
    result.typ = semfold.getIntervalType(callee.magic, call)
    
  # optimization pass: not necessary for correctness of the semantic pass
  if {sfNoSideEffect, sfCompileTime} * callee.flags != {} and
     {sfForward, sfImportc} * callee.flags == {}:
    if sfCompileTime notin callee.flags and 
        optImplicitStatic notin gOptions: return

    if callee.magic notin ctfeWhitelist: return
    if callee.kind notin {skProc, skConverter} or callee.isGenericRoutine:
      return
    
    if n.typ != nil and not typeAllowed(n.typ, skConst): return
    
    var call = newNodeIT(nkCall, n.info, n.typ)
    call.add(n.sons[0])
    for i in 1 .. < n.len:
      let a = getConstExpr(c.module, n.sons[i])
      if a == nil: return n
      call.add(a)
    #echo "NOW evaluating at compile time: ", call.renderTree
    if sfCompileTime in callee.flags:
      result = evalStaticExpr(c.module, call)
      if result.isNil: 
        LocalError(n.info, errCannotInterpretNodeX, renderTree(call))
    else:
      result = evalConstExpr(c.module, call)
      if result.isNil: result = n
    #if result != n:
    #  echo "SUCCESS evaluated at compile time: ", call.renderTree

proc semStaticExpr(c: PContext, n: PNode): PNode =
  let a = semExpr(c, n.sons[0])
  result = evalStaticExpr(c.module, a)
  if result.isNil:
    LocalError(n.info, errCannotInterpretNodeX, renderTree(n))

proc semOverloadedCallAnalyseEffects(c: PContext, n: PNode, nOrig: PNode,
                                     flags: TExprFlags): PNode =
  if efWantIterator in flags:
    result = semOverloadedCall(c, n, nOrig, {skIterator})
  elif efInTypeOf in flags:
    # for ``type(countup(1,3))``, see ``tests/ttoseq``.
    result = semOverloadedCall(c, n, nOrig, 
      {skProc, skMethod, skConverter, skMacro, skTemplate, skIterator})
  else:
    result = semOverloadedCall(c, n, nOrig, 
      {skProc, skMethod, skConverter, skMacro, skTemplate})
  if result != nil:
    if result.sons[0].kind != nkSym: 
      InternalError("semDirectCallAnalyseEffects")
    let callee = result.sons[0].sym
    case callee.kind
    of skMacro, skTemplate: nil
    else:
      if (callee.kind == skIterator) and (callee.id == c.p.owner.id): 
        GlobalError(n.info, errRecursiveDependencyX, callee.name.s)
      if sfNoSideEffect notin callee.flags: 
        if {sfImportc, sfSideEffect} * callee.flags != {}:
          incl(c.p.owner.flags, sfSideEffect)

proc semDirectCallAnalyseEffects(c: PContext, n: PNode, nOrig: PNode,
                                 flags: TExprFlags): PNode =
  result = semOverloadedCallAnalyseEffects(c, n, nOrig, flags)

proc semIndirectOp(c: PContext, n: PNode, flags: TExprFlags): PNode = 
  result = nil
  var prc = n.sons[0]
  checkMinSonsLen(n, 1)
  if n.sons[0].kind == nkDotExpr: 
    checkSonsLen(n.sons[0], 2)
    n.sons[0] = semFieldAccess(c, n.sons[0])
    if n.sons[0].kind == nkDotCall: 
      # it is a static call!
      result = n.sons[0]
      result.kind = nkCall
      for i in countup(1, sonsLen(n) - 1): addSon(result, n.sons[i])
      return semExpr(c, result, flags)
  else: 
    n.sons[0] = semExpr(c, n.sons[0])
  let nOrig = n.copyTree
  semOpAux(c, n)
  var t: PType = nil
  if (n.sons[0].typ != nil): t = skipTypes(n.sons[0].typ, abstractInst)
  if (t != nil) and (t.kind == tyProc): 
    var m: TCandidate
    initCandidate(m, t)
    matches(c, n, nOrig, m)
    if m.state != csMatch: 
      var msg = msgKindToString(errTypeMismatch)
      for i in countup(1, sonsLen(n) - 1): 
        if i > 1: add(msg, ", ")
        add(msg, typeToString(n.sons[i].typ))
      add(msg, ")\n" & msgKindToString(errButExpected) & "\n" &
          typeToString(n.sons[0].typ))
      GlobalError(n.Info, errGenerated, msg)
      result = nil
    else: 
      result = m.call
    # we assume that a procedure that calls something indirectly 
    # has side-effects:
    if tfNoSideEffect notin t.flags: incl(c.p.owner.flags, sfSideEffect)
  else:
    result = overloadedCallOpr(c, n)
    # Now that nkSym does not imply an iteration over the proc/iterator space,
    # the old ``prc`` (which is likely an nkIdent) has to be restored:
    if result == nil: 
      n.sons[0] = prc
      nOrig.sons[0] = prc
      result = semOverloadedCallAnalyseEffects(c, n, nOrig, flags)
    if result == nil: 
      GlobalError(n.info, errExprXCannotBeCalled, 
                  renderTree(n, {renderNoComments}))
  fixAbstractType(c, result)
  analyseIfAddressTakenInCall(c, result)
  if result.sons[0].kind == nkSym and result.sons[0].sym.magic != mNone:
    result = magicsAfterOverloadResolution(c, result, flags)
  result = evalAtCompileTime(c, result)

proc semDirectOp(c: PContext, n: PNode, flags: TExprFlags): PNode = 
  # this seems to be a hotspot in the compiler!
  let nOrig = n.copyTree
  semOpAux(c, n)
  result = semOverloadedCallAnalyseEffects(c, n, nOrig, flags)
  if result == nil:
    result = overloadedCallOpr(c, n)
    if result == nil: GlobalError(n.Info, errGenerated, getNotFoundError(c, n))
  let callee = result.sons[0].sym
  case callee.kind
  of skMacro: result = semMacroExpr(c, nOrig, callee)
  of skTemplate: result = semTemplateExpr(c, nOrig, callee)
  else:
    fixAbstractType(c, result)
    analyseIfAddressTakenInCall(c, result)
    if callee.magic != mNone:
      result = magicsAfterOverloadResolution(c, result, flags)
  result = evalAtCompileTime(c, result)

proc buildStringify(c: PContext, arg: PNode): PNode = 
  if arg.typ != nil and skipTypes(arg.typ, abstractInst).kind == tyString:
    result = arg
  else:
    result = newNodeI(nkCall, arg.info)
    addSon(result, newIdentNode(getIdent"$", arg.info))
    addSon(result, arg)

proc semEcho(c: PContext, n: PNode): PNode = 
  # this really is a macro
  checkMinSonsLen(n, 1)
  for i in countup(1, sonsLen(n) - 1): 
    var arg = semExprWithType(c, n.sons[i])
    n.sons[i] = semExpr(c, buildStringify(c, arg))
  result = n
  
proc buildEchoStmt(c: PContext, n: PNode): PNode = 
  # we MUST not check 'n' for semantics again here!
  result = newNodeI(nkCall, n.info)
  var e = StrTableGet(magicsys.systemModule.Tab, getIdent"echo")
  if e == nil: GlobalError(n.info, errSystemNeeds, "echo")
  addSon(result, newSymNode(e))
  var arg = buildStringify(c, n)
  # problem is: implicit '$' is not checked for semantics yet. So we give up
  # and check 'arg' for semantics again:
  addSon(result, semExpr(c, arg))

proc semExprNoType(c: PContext, n: PNode): PNode =
  proc ImplicitelyDiscardable(n: PNode): bool {.inline.} =
    result = isCallExpr(n) and n.sons[0].kind == nkSym and 
             sfDiscardable in n.sons[0].sym.flags
  result = semExpr(c, n)
  if result.typ != nil and result.typ.kind != tyStmt:
    if gCmd == cmdInteractive:
      result = buildEchoStmt(c, result)
    elif not ImplicitelyDiscardable(result):
      localError(n.info, errDiscardValue)
  
proc isTypeExpr(n: PNode): bool = 
  case n.kind
  of nkType, nkTypeOfExpr: result = true
  of nkSym: result = n.sym.kind == skType
  else: result = false
  
proc lookupInRecordAndBuildCheck(c: PContext, n, r: PNode, field: PIdent, 
                                 check: var PNode): PSym = 
  # transform in a node that contains the runtime check for the
  # field, if it is in a case-part...
  result = nil
  case r.kind
  of nkRecList: 
    for i in countup(0, sonsLen(r) - 1): 
      result = lookupInRecordAndBuildCheck(c, n, r.sons[i], field, check)
      if result != nil: return 
  of nkRecCase: 
    checkMinSonsLen(r, 2)
    if (r.sons[0].kind != nkSym): IllFormedAst(r)
    result = lookupInRecordAndBuildCheck(c, n, r.sons[0], field, check)
    if result != nil: return 
    var s = newNodeI(nkCurly, r.info)
    for i in countup(1, sonsLen(r) - 1): 
      var it = r.sons[i]
      case it.kind
      of nkOfBranch: 
        result = lookupInRecordAndBuildCheck(c, n, lastSon(it), field, check)
        if result == nil: 
          for j in 0..sonsLen(it)-2: addSon(s, copyTree(it.sons[j]))
        else: 
          if check == nil: 
            check = newNodeI(nkCheckedFieldExpr, n.info)
            addSon(check, ast.emptyNode) # make space for access node
          s = newNodeI(nkCurly, n.info)
          for j in countup(0, sonsLen(it) - 2): addSon(s, copyTree(it.sons[j]))
          var inExpr = newNodeI(nkCall, n.info)
          addSon(inExpr, newIdentNode(getIdent("in"), n.info))
          addSon(inExpr, copyTree(r.sons[0]))
          addSon(inExpr, s)   #writeln(output, renderTree(inExpr));
          addSon(check, semExpr(c, inExpr))
          return 
      of nkElse: 
        result = lookupInRecordAndBuildCheck(c, n, lastSon(it), field, check)
        if result != nil: 
          if check == nil: 
            check = newNodeI(nkCheckedFieldExpr, n.info)
            addSon(check, ast.emptyNode) # make space for access node
          var inExpr = newNodeI(nkCall, n.info)
          addSon(inExpr, newIdentNode(getIdent("in"), n.info))
          addSon(inExpr, copyTree(r.sons[0]))
          addSon(inExpr, s)
          var notExpr = newNodeI(nkCall, n.info)
          addSon(notExpr, newIdentNode(getIdent("not"), n.info))
          addSon(notExpr, inExpr)
          addSon(check, semExpr(c, notExpr))
          return 
      else: illFormedAst(it)
  of nkSym: 
    if r.sym.name.id == field.id: result = r.sym
  else: illFormedAst(n)
  
proc makeDeref(n: PNode): PNode = 
  var t = skipTypes(n.typ, {tyGenericInst})
  result = n
  if t.kind == tyVar: 
    result = newNodeIT(nkHiddenDeref, n.info, t.sons[0])
    addSon(result, n)
    t = skipTypes(t.sons[0], {tyGenericInst})
  while t.kind in {tyPtr, tyRef}:
    var a = result
    result = newNodeIT(nkHiddenDeref, n.info, t.sons[0])
    addSon(result, a)
    t = skipTypes(t.sons[0], {tyGenericInst})

proc builtinFieldAccess(c: PContext, n: PNode, flags: TExprFlags): PNode =
  ## returns nil if it's not a built-in field access
  checkSonsLen(n, 2)
  # early exit for this; see tests/compile/tbindoverload.nim:
  if n.sons[1].kind == nkSymChoice: return

  var s = qualifiedLookup(c, n, {checkAmbiguity, checkUndeclared})
  if s != nil:
    return semSym(c, n, s, flags)

  n.sons[0] = semExprWithType(c, n.sons[0], flags)
  restoreOldStyleType(n.sons[0])
  var i = considerAcc(n.sons[1])
  var ty = n.sons[0].typ
  var f: PSym = nil
  result = nil
  if isTypeExpr(n.sons[0]):
    case ty.kind
    of tyEnum: 
      # look up if the identifier belongs to the enum:
      while ty != nil: 
        f = getSymFromList(ty.n, i)
        if f != nil: break 
        ty = ty.sons[0]         # enum inheritance
      if f != nil: 
        result = newSymNode(f)
        result.info = n.info
        result.typ = ty
        markUsed(n, f)
        return
    of tyGenericInst:
      assert ty.sons[0].kind == tyGenericBody
      let tbody = ty.sons[0]
      for s in countup(0, tbody.len-2):
        let tParam = tbody.sons[s]
        assert tParam.kind == tyGenericParam
        if tParam.sym.name == i:
          let foundTyp = makeTypeDesc(c, ty.sons[s + 1])
          return newSymNode(copySym(tParam.sym).linkTo(foundTyp), n.info)
      return
    else:
      # echo "TYPE FIELD ACCESS"
      # debug ty
      return
    # XXX: This is probably not relevant any more
    # reset to prevent 'nil' bug: see "tests/reject/tenumitems.nim":
    ty = n.sons[0].Typ
      
  ty = skipTypes(ty, {tyGenericInst, tyVar, tyPtr, tyRef})
  var check: PNode = nil
  if ty.kind == tyObject: 
    while true: 
      check = nil
      f = lookupInRecordAndBuildCheck(c, n, ty.n, i, check)
      if f != nil: break 
      if ty.sons[0] == nil: break 
      ty = skipTypes(ty.sons[0], {tyGenericInst})
    if f != nil: 
      var fmoduleId = getModule(f).id
      if sfExported in f.flags or fmoduleId == c.module.id or
          fmoduleId == c.friendModule.id: 
        # is the access to a public field or in the same module or in a friend?
        n.sons[0] = makeDeref(n.sons[0])
        n.sons[1] = newSymNode(f) # we now have the correct field
        n.typ = f.typ
        markUsed(n, f)
        if check == nil: 
          result = n
        else: 
          check.sons[0] = n
          check.typ = n.typ
          result = check
  elif ty.kind == tyTuple and ty.n != nil: 
    f = getSymFromList(ty.n, i)
    if f != nil: 
      n.sons[0] = makeDeref(n.sons[0])
      n.sons[1] = newSymNode(f)
      n.typ = f.typ
      result = n
      markUsed(n, f)

proc semFieldAccess(c: PContext, n: PNode, flags: TExprFlags): PNode = 
  # this is difficult, because the '.' is used in many different contexts
  # in Nimrod. We first allow types in the semantic checking.
  result = builtinFieldAccess(c, n, flags)
  if result == nil:
    if n.sons[1].kind == nkSymChoice: 
      result = newNodeI(nkDotCall, n.info)
      addSon(result, n.sons[1])
      addSon(result, copyTree(n[0]))
    else:
      var i = considerAcc(n.sons[1])
      var f = SymTabGet(c.tab, i)
      # if f != nil and f.kind == skStub: loadStub(f)
      # ``loadStub`` is not correct here as we don't care for ``f`` really
      if f != nil: 
        # BUGFIX: do not check for (f.kind in {skProc, skMethod, skIterator}) here
        # This special node kind is to merge with the call handler in `semExpr`.
        result = newNodeI(nkDotCall, n.info)
        addSon(result, newIdentNode(i, n.info))
        addSon(result, copyTree(n[0]))
      else: 
        GlobalError(n.Info, errUndeclaredFieldX, i.s)

proc buildOverloadedSubscripts(n: PNode, ident: PIdent): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newIdentNode(ident, n.info))
  for i in 0 .. n.len-1: result.add(n[i])
  
proc semDeref(c: PContext, n: PNode): PNode =
  checkSonsLen(n, 1)
  n.sons[0] = semExprWithType(c, n.sons[0])
  result = n
  var t = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar})
  case t.kind
  of tyRef, tyPtr: n.typ = t.sons[0]
  else: result = nil
  #GlobalError(n.sons[0].info, errCircumNeedsPointer) 

proc semSubscript(c: PContext, n: PNode, flags: TExprFlags): PNode =
  ## returns nil if not a built-in subscript operator; also called for the
  ## checking of assignments
  if sonsLen(n) == 1: 
    var x = semDeref(c, n)
    if x == nil: return nil
    result = newNodeIT(nkDerefExpr, x.info, x.typ)
    result.add(x[0])
    return
  checkMinSonsLen(n, 2)
  n.sons[0] = semExprWithType(c, n.sons[0])
  var arr = skipTypes(n.sons[0].typ, {tyGenericInst, tyVar, tyPtr, tyRef})
  case arr.kind
  of tyArray, tyOpenArray, tyArrayConstr, tySequence, tyString, tyCString: 
    checkSonsLen(n, 2)
    n.sons[0] = makeDeref(n.sons[0])
    for i in countup(1, sonsLen(n) - 1): 
      n.sons[i] = semExprWithType(c, n.sons[i], flags)
    var indexType = if arr.kind == tyArray: arr.sons[0] else: getSysType(tyInt)
    var arg = IndexTypesMatch(c, indexType, n.sons[1].typ, n.sons[1])
    if arg != nil:
      n.sons[1] = arg
      result = n
      result.typ = elemType(arr)
    #GlobalError(n.info, errIndexTypesDoNotMatch)
  of tyTypeDesc:
    result = n.sons[0] # The result so far is a tyTypeDesc bound to
                       # a tyGenericBody. The line below will substitute
                       # it with the instantiated type.
    result.typ.sons[0] = semTypeNode(c, n, nil).linkTo(result.sym)
  of tyTuple: 
    checkSonsLen(n, 2)
    n.sons[0] = makeDeref(n.sons[0])
    # [] operator for tuples requires constant expression:
    n.sons[1] = semConstExpr(c, n.sons[1])
    if skipTypes(n.sons[1].typ, {tyGenericInst, tyRange, tyOrdinal}).kind in
        {tyInt..tyInt64}: 
      var idx = getOrdValue(n.sons[1])
      if idx >= 0 and idx < sonsLen(arr): n.typ = arr.sons[int(idx)]
      else: GlobalError(n.info, errInvalidIndexValueForTuple)
    else: 
      GlobalError(n.info, errIndexTypesDoNotMatch)
    result = n
  else: nil
  
proc semArrayAccess(c: PContext, n: PNode, flags: TExprFlags): PNode = 
  result = semSubscript(c, n, flags)
  if result == nil:
    # overloaded [] operator:
    result = semExpr(c, buildOverloadedSubscripts(n, getIdent"[]"))

proc propertyWriteAccess(c: PContext, n, nOrig, a: PNode): PNode =
  var id = considerAcc(a[1])
  let setterId = newIdentNode(getIdent(id.s & '='), n.info)
  # a[0] is already checked for semantics, that does ``builtinFieldAccess``
  # this is ugly. XXX Semantic checking should use the ``nfSem`` flag for
  # nodes?
  let aOrig = nOrig[0]
  result = newNode(nkCall, n.info, sons = @[setterId, a[0], semExpr(c, n[1])])
  let orig = newNode(nkCall, n.info, sons = @[setterId, aOrig[0], nOrig[1]])
  result = semDirectCallAnalyseEffects(c, result, orig, {})
  if result != nil:
    fixAbstractType(c, result)
    analyseIfAddressTakenInCall(c, result)
  else:
    globalError(n.Info, errUndeclaredFieldX, id.s)

proc takeImplicitAddr(c: PContext, n: PNode): PNode =
  case n.kind
  of nkHiddenAddr, nkAddr: return n
  of nkHiddenDeref, nkDerefExpr: return n.sons[0]
  of nkBracketExpr:
    if len(n) == 1: return n.sons[0]
  else: nil
  var valid = isAssignable(c, n)
  if valid != arLValue:
    if valid == arLocalLValue:
      GlobalError(n.info, errXStackEscape, renderTree(n, {renderNoComments}))
    else:
      GlobalError(n.info, errExprHasNoAddress)
  result = newNodeIT(nkHiddenAddr, n.info, makePtrType(c, n.typ))
  result.add(n)
  
proc asgnToResultVar(c: PContext, n, le, ri: PNode) {.inline.} =
  if le.kind == nkHiddenDeref:
    var x = le.sons[0]
    if x.typ.kind == tyVar and x.kind == nkSym and x.sym.kind == skResult:
      n.sons[0] = x # 'result[]' --> 'result'
      n.sons[1] = takeImplicitAddr(c, ri)

proc semAsgn(c: PContext, n: PNode): PNode =
  checkSonsLen(n, 2)
  var a = n.sons[0]
  case a.kind
  of nkDotExpr: 
    # r.f = x
    # --> `f=` (r, x)
    let nOrig = n.copyTree
    a = builtinFieldAccess(c, a, {efLValue})
    if a == nil: 
      return propertyWriteAccess(c, n, nOrig, n[0])
  of nkBracketExpr: 
    # a[i] = x
    # --> `[]=`(a, i, x)
    a = semSubscript(c, a, {efLValue})
    if a == nil:
      result = buildOverloadedSubscripts(n.sons[0], getIdent"[]=")
      add(result, n[1])
      return semExprNoType(c, result)
  of nkCurlyExpr:
    # a{i} = x -->  `{}=`(a, i, x)
    result = buildOverloadedSubscripts(n.sons[0], getIdent"{}=")
    add(result, n[1])
    return semExprNoType(c, result)
  else:
    a = semExprWithType(c, a, {efLValue})
  n.sons[0] = a
  # a = b # both are vars, means: a[] = b[]
  # a = b # b no 'var T' means: a = addr(b)
  var le = a.typ
  if skipTypes(le, {tyGenericInst}).kind != tyVar and 
      IsAssignable(c, a) == arNone: 
    # Direct assignment to a discriminant is allowed!
    localError(a.info, errXCannotBeAssignedTo, 
               renderTree(a, {renderNoComments}))
  else:
    n.sons[1] = semExprWithType(c, n.sons[1])
    n.sons[1] = fitNode(c, le, n.sons[1])
    fixAbstractType(c, n)
    asgnToResultVar(c, n, n.sons[0], n.sons[1])
  result = n

proc lookUpForDefined(c: PContext, i: PIdent, onlyCurrentScope: bool): PSym =
  if onlyCurrentScope: 
    result = SymtabLocalGet(c.tab, i)
  else: 
    result = SymtabGet(c.Tab, i) # no need for stub loading

proc LookUpForDefined(c: PContext, n: PNode, onlyCurrentScope: bool): PSym = 
  case n.kind
  of nkIdent: 
    result = LookupForDefined(c, n.ident, onlyCurrentScope)
  of nkDotExpr:
    result = nil
    if onlyCurrentScope: return 
    checkSonsLen(n, 2)
    var m = LookupForDefined(c, n.sons[0], onlyCurrentScope)
    if (m != nil) and (m.kind == skModule): 
      if (n.sons[1].kind == nkIdent): 
        var ident = n.sons[1].ident
        if m == c.module: 
          result = StrTableGet(c.tab.stack[ModuleTablePos], ident)
        else: 
          result = StrTableGet(m.tab, ident)
      else: 
        GlobalError(n.sons[1].info, errIdentifierExpected, "")
  of nkAccQuoted:
    result = lookupForDefined(c, considerAcc(n), onlyCurrentScope)
  of nkSym:
    result = n.sym
  else: 
    GlobalError(n.info, errIdentifierExpected, renderTree(n))
    result = nil

proc semDefined(c: PContext, n: PNode, onlyCurrentScope: bool): PNode = 
  checkSonsLen(n, 2)
  # we replace this node by a 'true' or 'false' node:
  result = newIntNode(nkIntLit, 0)
  if LookUpForDefined(c, n.sons[1], onlyCurrentScope) != nil: 
    result.intVal = 1
  elif not onlyCurrentScope and (n.sons[1].kind == nkIdent) and
      condsyms.isDefined(n.sons[1].ident): 
    result.intVal = 1
  result.info = n.info
  result.typ = getSysType(tyBool)

proc setMs(n: PNode, s: PSym): PNode = 
  result = n
  n.sons[0] = newSymNode(s)
  n.sons[0].info = n.info

proc expectMacroOrTemplateCall(c: PContext, n: PNode): PSym =
  ## The argument to the proc should be nkCall(...) or similar
  ## Returns the macro/template symbol
  if not isCallExpr(n):
    GlobalError(n.info, errXisNoMacroOrTemplate, n.renderTree)

  var expandedSym = qualifiedLookup(c, n[0], {checkUndeclared})
  if expandedSym == nil:
    GlobalError(n.info, errUndeclaredIdentifier, n[0].renderTree)

  if expandedSym.kind notin {skMacro, skTemplate}:
    GlobalError(n.info, errXisNoMacroOrTemplate, expandedSym.name.s)

  result = expandedSym

proc semExpandToAst(c: PContext, n: PNode, magicSym: PSym,
                    flags: TExprFlags): PNode =
  if sonsLen(n) == 2:
    var macroCall = n[1]
    var expandedSym = expectMacroOrTemplateCall(c, macroCall)

    macroCall.sons[0] = newSymNode(expandedSym, macroCall.info)
    markUsed(n, expandedSym)

    for i in countup(1, macroCall.len-1):
      macroCall.sons[i] = semExprWithType(c, macroCall[i], {})

    # Preserve the magic symbol in order to be handled in evals.nim
    n.sons[0] = newSymNode(magicSym, n.info)
    n.typ = getSysSym("PNimrodNode").typ # expandedSym.getReturnType
    result = n
  else:
    result = semDirectOp(c, n, flags)

proc semMagic(c: PContext, n: PNode, s: PSym, flags: TExprFlags): PNode = 
  # this is a hotspot in the compiler!
  result = n
  case s.magic # magics that need special treatment
  of mDefined: result = semDefined(c, setMs(n, s), false)
  of mDefinedInScope: result = semDefined(c, setMs(n, s), true)
  of mLow: result = semLowHigh(c, setMs(n, s), mLow)
  of mHigh: result = semLowHigh(c, setMs(n, s), mHigh)
  of mSizeOf: result = semSizeof(c, setMs(n, s))
  of mIs: result = semIs(c, setMs(n, s))
  of mOf: result = semOf(c, setMs(n, s))
  of mEcho: result = semEcho(c, setMs(n, s))
  of mShallowCopy:
    if sonsLen(n) == 3:
      # XXX ugh this is really a hack: shallowCopy() can be overloaded only
      # with procs that take not 2 parameters:
      result = newNodeI(nkFastAsgn, n.info)
      result.add(n[1])
      result.add(n[2])
      result = semAsgn(c, result)
    else:
      result = semDirectOp(c, n, flags)
  of mExpandToAst: result = semExpandToAst(c, n, s, flags)
  else: result = semDirectOp(c, n, flags)

proc semIfExpr(c: PContext, n: PNode): PNode = 
  result = n
  checkMinSonsLen(n, 2)
  var typ: PType = nil
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    case it.kind
    of nkElifExpr: 
      checkSonsLen(it, 2)
      it.sons[0] = forceBool(c, semExprWithType(c, it.sons[0]))
      it.sons[1] = semExprWithType(c, it.sons[1])
      if typ == nil: typ = it.sons[1].typ
      else: it.sons[1] = fitNode(c, typ, it.sons[1])
    of nkElseExpr: 
      checkSonsLen(it, 1)
      it.sons[0] = semExprWithType(c, it.sons[0])
      if typ == nil: InternalError(it.info, "semIfExpr")
      it.sons[0] = fitNode(c, typ, it.sons[0])
    else: illFormedAst(n)
  result.typ = typ

proc semSetConstr(c: PContext, n: PNode): PNode = 
  result = newNodeI(nkCurly, n.info)
  result.typ = newTypeS(tySet, c)
  if sonsLen(n) == 0: 
    rawAddSon(result.typ, newTypeS(tyEmpty, c))
  else: 
    # only semantic checking for all elements, later type checking:
    var typ: PType = nil
    for i in countup(0, sonsLen(n) - 1): 
      if isRange(n.sons[i]): 
        checkSonsLen(n.sons[i], 3)
        n.sons[i].sons[1] = semExprWithType(c, n.sons[i].sons[1])
        n.sons[i].sons[2] = semExprWithType(c, n.sons[i].sons[2])
        if typ == nil: 
          typ = skipTypes(n.sons[i].sons[1].typ, 
                          {tyGenericInst, tyVar, tyOrdinal})
        n.sons[i].typ = n.sons[i].sons[2].typ # range node needs type too
      elif n.sons[i].kind == nkRange:
        # already semchecked
        if typ == nil:
          typ = skipTypes(n.sons[i].sons[0].typ, 
                          {tyGenericInst, tyVar, tyOrdinal})
      else:
        n.sons[i] = semExprWithType(c, n.sons[i])
        if typ == nil: 
          typ = skipTypes(n.sons[i].typ, {tyGenericInst, tyVar, tyOrdinal})
    if not isOrdinalType(typ): 
      GlobalError(n.info, errOrdinalTypeExpected)
      return 
    if lengthOrd(typ) > MaxSetElements: 
      typ = makeRangeType(c, 0, MaxSetElements - 1, n.info)
    addSonSkipIntLit(result.typ, typ)
    for i in countup(0, sonsLen(n) - 1): 
      var m: PNode
      if isRange(n.sons[i]):
        m = newNodeI(nkRange, n.sons[i].info)
        addSon(m, fitNode(c, typ, n.sons[i].sons[1]))
        addSon(m, fitNode(c, typ, n.sons[i].sons[2]))
      elif n.sons[i].kind == nkRange: m = n.sons[i] # already semchecked
      else:
        m = fitNode(c, typ, n.sons[i])
      addSon(result, m)

proc semTableConstr(c: PContext, n: PNode): PNode = 
  # we simply transform ``{key: value, key2: value}`` to 
  # ``[(key, value), (key2, value2)]``
  result = newNodeI(nkBracket, n.info)
  for i in 0..n.len-1:
    var x = n.sons[i]
    if x.kind == nkExprColonExpr and sonsLen(x) == 2:
      var pair = newNodeI(nkPar, x.info)
      pair.add(x[0])
      pair.add(x[1])
      result.add(pair)
    else:
      illFormedAst(x)
  result = semExpr(c, result)

type 
  TParKind = enum 
    paNone, paSingle, paTupleFields, paTuplePositions

proc checkPar(n: PNode): TParKind = 
  var length = sonsLen(n)
  if length == 0: 
    result = paTuplePositions # ()
  elif length == 1: 
    result = paSingle         # (expr)
  else: 
    if n.sons[0].kind == nkExprColonExpr: result = paTupleFields
    else: result = paTuplePositions
    for i in countup(0, length - 1): 
      if result == paTupleFields: 
        if (n.sons[i].kind != nkExprColonExpr) or
            not (n.sons[i].sons[0].kind in {nkSym, nkIdent}): 
          GlobalError(n.sons[i].info, errNamedExprExpected)
          return paNone
      else: 
        if n.sons[i].kind == nkExprColonExpr: 
          GlobalError(n.sons[i].info, errNamedExprNotAllowed)
          return paNone

proc semTupleFieldsConstr(c: PContext, n: PNode): PNode = 
  result = newNodeI(nkPar, n.info)
  var typ = newTypeS(tyTuple, c)
  typ.n = newNodeI(nkRecList, n.info) # nkIdentDefs
  var ids = initIntSet()
  for i in countup(0, sonsLen(n) - 1): 
    if (n.sons[i].kind != nkExprColonExpr) or
        not (n.sons[i].sons[0].kind in {nkSym, nkIdent}): 
      illFormedAst(n.sons[i])
    var id: PIdent
    if n.sons[i].sons[0].kind == nkIdent: id = n.sons[i].sons[0].ident
    else: id = n.sons[i].sons[0].sym.name
    if ContainsOrIncl(ids, id.id): 
      localError(n.sons[i].info, errFieldInitTwice, id.s)
    n.sons[i].sons[1] = semExprWithType(c, n.sons[i].sons[1])
    var f = newSymS(skField, n.sons[i].sons[0], c)
    f.typ = skipIntLit(n.sons[i].sons[1].typ)
    rawAddSon(typ, f.typ)
    addSon(typ.n, newSymNode(f))
    n.sons[i].sons[0] = newSymNode(f)
    addSon(result, n.sons[i])
  result.typ = typ

proc semTuplePositionsConstr(c: PContext, n: PNode): PNode = 
  result = n                  # we don't modify n, but compute the type:
  var typ = newTypeS(tyTuple, c)  # leave typ.n nil!
  for i in countup(0, sonsLen(n) - 1): 
    n.sons[i] = semExprWithType(c, n.sons[i])
    addSonSkipIntLit(typ, n.sons[i].typ)
  result.typ = typ

proc semStmtListExpr(c: PContext, n: PNode): PNode = 
  result = n
  checkMinSonsLen(n, 1)
  var length = sonsLen(n)
  for i in countup(0, length - 2): 
    n.sons[i] = semStmt(c, n.sons[i])
  if length > 0: 
    n.sons[length - 1] = semExprWithType(c, n.sons[length - 1])
    n.typ = n.sons[length - 1].typ

proc semBlockExpr(c: PContext, n: PNode): PNode = 
  result = n
  Inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2)
  openScope(c.tab)            # BUGFIX: label is in the scope of block!
  if n.sons[0].kind != nkEmpty: addDecl(c, newSymS(skLabel, n.sons[0], c))
  n.sons[1] = semStmtListExpr(c, n.sons[1])
  n.typ = n.sons[1].typ
  closeScope(c.tab)
  Dec(c.p.nestedBlockCounter)

proc semMacroStmt(c: PContext, n: PNode, semCheck = true): PNode = 
  checkMinSonsLen(n, 2)
  var a: PNode
  if isCallExpr(n.sons[0]): a = n.sons[0].sons[0]
  else: a = n.sons[0]
  var s = qualifiedLookup(c, a, {checkUndeclared})
  if s != nil: 
    case s.kind
    of skMacro: 
      result = semMacroExpr(c, n, s, semCheck)
    of skTemplate: 
      # transform
      # nkMacroStmt(nkCall(a...), stmt, b...)
      # to
      # nkCall(a..., stmt, b...)
      result = newNodeI(nkCall, n.info)
      addSon(result, a)
      if isCallExpr(n.sons[0]): 
        for i in countup(1, sonsLen(n.sons[0]) - 1): 
          addSon(result, n.sons[0].sons[i])
      for i in countup(1, sonsLen(n) - 1): addSon(result, n.sons[i])
      result = semTemplateExpr(c, result, s, semCheck)
    else: GlobalError(n.info, errXisNoMacroOrTemplate, s.name.s)
  else: 
    GlobalError(n.info, errInvalidExpressionX, 
                renderTree(a, {renderNoComments}))

proc semExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode = 
  result = n
  if gCmd == cmdIdeTools: suggestExpr(c, n)
  if nfSem in n.flags: return 
  case n.kind
  of nkIdent, nkAccQuoted:
    var s = lookUp(c, n)
    result = semSym(c, n, s, flags)
  of nkSym:
    # because of the changed symbol binding, this does not mean that we
    # don't have to check the symbol for semantics here again!
    result = semSym(c, n, n.sym, flags)
  of nkEmpty, nkNone: 
    nil
  of nkNilLit: 
    result.typ = getSysType(tyNil)
  of nkIntLit:
    if result.typ == nil: setIntLitType(result)
  of nkInt8Lit:
    if result.typ == nil: result.typ = getSysType(tyInt8)
  of nkInt16Lit: 
    if result.typ == nil: result.typ = getSysType(tyInt16)
  of nkInt32Lit: 
    if result.typ == nil: result.typ = getSysType(tyInt32)
  of nkInt64Lit: 
    if result.typ == nil: result.typ = getSysType(tyInt64)
  of nkUIntLit:
    if result.typ == nil: result.typ = getSysType(tyUInt)
  of nkUInt8Lit: 
    if result.typ == nil: result.typ = getSysType(tyUInt8)
  of nkUInt16Lit: 
    if result.typ == nil: result.typ = getSysType(tyUInt16)
  of nkUInt32Lit: 
    if result.typ == nil: result.typ = getSysType(tyUInt32)
  of nkUInt64Lit: 
    if result.typ == nil: result.typ = getSysType(tyUInt64)
  of nkFloatLit: 
    if result.typ == nil: result.typ = getSysType(tyFloat)
  of nkFloat32Lit: 
    if result.typ == nil: result.typ = getSysType(tyFloat32)
  of nkFloat64Lit: 
    if result.typ == nil: result.typ = getSysType(tyFloat64)
  of nkFloat128Lit: 
    if result.typ == nil: result.typ = getSysType(tyFloat128)
  of nkStrLit..nkTripleStrLit: 
    if result.typ == nil: result.typ = getSysType(tyString)
  of nkCharLit: 
    if result.typ == nil: result.typ = getSysType(tyChar)
  of nkDotExpr: 
    result = semFieldAccess(c, n, flags)
    if result.kind == nkDotCall: 
      result.kind = nkCall
      result = semExpr(c, result, flags)
  of nkBind:
    Message(n.info, warnDeprecated, "bind")
    result = semExpr(c, n.sons[0], flags)
  of nkTypeOfExpr:
    var typ = semTypeNode(c, n, nil).skipTypes({tyTypeDesc})
    typ = makeTypedesc(c, typ)
    var sym = newSym(skType, getIdent"TypeOfExpr", typ.owner).linkTo(typ)
    sym.flags.incl(sfAnon)
    result = newSymNode(sym, n.info)
  of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit: 
    # check if it is an expression macro:
    checkMinSonsLen(n, 1)
    var s = qualifiedLookup(c, n.sons[0], {checkUndeclared})
    if s != nil: 
      case s.kind
      of skMacro:
        if false and sfImmediate notin s.flags: # XXX not yet enabled
          result = semDirectOp(c, n, flags)
        else:
          result = semMacroExpr(c, n, s)
      of skTemplate:
        if sfImmediate notin s.flags:
          result = semDirectOp(c, n, flags)
        else:
          result = semTemplateExpr(c, n, s)
      of skType: 
        # XXX think about this more (``set`` procs)
        if n.len == 2:
          result = semConv(c, n, s)
        elif Contains(c.AmbiguousSymbols, s.id): 
          LocalError(n.info, errUseQualifier, s.name.s)
        elif s.magic == mNone: result = semDirectOp(c, n, flags)
        else: result = semMagic(c, n, s, flags)
      of skProc, skMethod, skConverter, skIterator: 
        if s.magic == mNone: result = semDirectOp(c, n, flags)
        else: result = semMagic(c, n, s, flags)
      else:
        #liMessage(n.info, warnUser, renderTree(n));
        result = semIndirectOp(c, n, flags)
    elif n.sons[0].kind == nkSymChoice or n[0].kind == nkBracketExpr and 
        n[0][0].kind == nkSymChoice:
      result = semDirectOp(c, n, flags)
    else:
      result = semIndirectOp(c, n, flags)
  of nkMacroStmt: 
    result = semMacroStmt(c, n)
  of nkWhenExpr:
    result = semWhen(c, n, false)
    result = semExpr(c, result)
  of nkBracketExpr: 
    checkMinSonsLen(n, 1)
    var s = qualifiedLookup(c, n.sons[0], {checkUndeclared})
    if s != nil and s.kind in {skProc, skMethod, skConverter, skIterator}: 
      # type parameters: partial generic specialization
      n.sons[0] = semSymGenericInstantiation(c, n.sons[0], s)
      result = explicitGenericInstantiation(c, n, s)
    else: 
      result = semArrayAccess(c, n, flags)
  of nkCurlyExpr:
    result = semExpr(c, buildOverloadedSubscripts(n, getIdent"{}"), flags)
  of nkPragmaExpr: 
    # which pragmas are allowed for expressions? `likely`, `unlikely`
    internalError(n.info, "semExpr() to implement") # XXX: to implement
  of nkPar: 
    case checkPar(n)
    of paNone: result = nil
    of paTuplePositions: result = semTuplePositionsConstr(c, n)
    of paTupleFields: result = semTupleFieldsConstr(c, n)
    of paSingle: result = semExpr(c, n.sons[0], flags)
  of nkCurly: result = semSetConstr(c, n)
  of nkBracket: result = semArrayConstr(c, n)
  of nkLambdaKinds: result = semLambda(c, n)
  of nkDerefExpr: result = semDeref(c, n)
  of nkAddr: 
    result = n
    checkSonsLen(n, 1)
    n.sons[0] = semExprWithType(c, n.sons[0])
    if isAssignable(c, n.sons[0]) notin {arLValue, arLocalLValue}: 
      GlobalError(n.info, errExprHasNoAddress)
    n.typ = makePtrType(c, n.sons[0].typ)
  of nkHiddenAddr, nkHiddenDeref:
    checkSonsLen(n, 1)
    n.sons[0] = semExpr(c, n.sons[0], flags)
  of nkCast: result = semCast(c, n)
  of nkIfExpr: result = semIfExpr(c, n)
  of nkStmtListExpr: result = semStmtListExpr(c, n)
  of nkBlockExpr: result = semBlockExpr(c, n)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkHiddenCallConv: 
    checkSonsLen(n, 2)
  of nkStringToCString, nkCStringToString, nkObjDownConv, nkObjUpConv: 
    checkSonsLen(n, 1)
  of nkChckRangeF, nkChckRange64, nkChckRange: 
    checkSonsLen(n, 3)
  of nkCheckedFieldExpr: 
    checkMinSonsLen(n, 2)
  of nkTableConstr:
    result = semTableConstr(c, n)
  of nkSymChoice:
    GlobalError(n.info, errExprXAmbiguous, renderTree(n, {renderNoComments}))
  of nkStaticExpr:
    result = semStaticExpr(c, n)
  else:
    GlobalError(n.info, errInvalidExpressionX, 
                renderTree(n, {renderNoComments}))
  incl(result.flags, nfSem)
