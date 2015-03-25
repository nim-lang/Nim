#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking of type declarations
# included from sem.nim

proc newOrPrevType(kind: TTypeKind, prev: PType, c: PContext): PType =
  if prev == nil:
    result = newTypeS(kind, c)
  else:
    result = prev
    if result.kind == tyForward: result.kind = kind

proc newConstraint(c: PContext, k: TTypeKind): PType =
  result = newTypeS(tyBuiltInTypeClass, c)
  result.addSonSkipIntLit(newTypeS(k, c))

proc semEnum(c: PContext, n: PNode, prev: PType): PType =
  if n.sonsLen == 0: return newConstraint(c, tyEnum)
  var
    counter, x: BiggestInt
    e: PSym
    base: PType
  counter = 0
  base = nil
  result = newOrPrevType(tyEnum, prev, c)
  result.n = newNodeI(nkEnumTy, n.info)
  checkMinSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty:
    base = semTypeNode(c, n.sons[0].sons[0], nil)
    if base.kind != tyEnum:
      localError(n.sons[0].info, errInheritanceOnlyWithEnums)
    counter = lastOrd(base) + 1
  rawAddSon(result, base)
  let isPure = result.sym != nil and sfPure in result.sym.flags
  var hasNull = false
  for i in countup(1, sonsLen(n) - 1):
    case n.sons[i].kind
    of nkEnumFieldDef:
      e = newSymS(skEnumField, n.sons[i].sons[0], c)
      var v = semConstExpr(c, n.sons[i].sons[1])
      var strVal: PNode = nil
      case skipTypes(v.typ, abstractInst-{tyTypeDesc}).kind
      of tyTuple:
        if sonsLen(v) == 2:
          strVal = v.sons[1] # second tuple part is the string value
          if skipTypes(strVal.typ, abstractInst).kind in {tyString, tyCString}:
            x = getOrdValue(v.sons[0]) # first tuple part is the ordinal
          else:
            localError(strVal.info, errStringLiteralExpected)
        else:
          localError(v.info, errWrongNumberOfVariables)
      of tyString, tyCString:
        strVal = v
        x = counter
      else:
        x = getOrdValue(v)
      if i != 1:
        if x != counter: incl(result.flags, tfEnumHasHoles)
        if x < counter:
          localError(n.sons[i].info, errInvalidOrderInEnumX, e.name.s)
          x = counter
      e.ast = strVal # might be nil
      counter = x
    of nkSym:
      e = n.sons[i].sym
    of nkIdent, nkAccQuoted:
      e = newSymS(skEnumField, n.sons[i], c)
    else:
      illFormedAst(n[i])
    e.typ = result
    e.position = int(counter)
    if e.position == 0: hasNull = true
    if result.sym != nil and sfExported in result.sym.flags:
      incl(e.flags, sfUsed)
      incl(e.flags, sfExported)
      if not isPure: strTableAdd(c.module.tab, e)
    addSon(result.n, newSymNode(e))
    styleCheckDef(e)
    if sfGenSym notin e.flags and not isPure: addDecl(c, e)
    inc(counter)
  if not hasNull: incl(result.flags, tfNeedsInit)

proc semSet(c: PContext, n: PNode, prev: PType): PType =
  result = newOrPrevType(tySet, prev, c)
  if sonsLen(n) == 2:
    var base = semTypeNode(c, n.sons[1], nil)
    addSonSkipIntLit(result, base)
    if base.kind == tyGenericInst: base = lastSon(base)
    if base.kind != tyGenericParam:
      if not isOrdinalType(base):
        localError(n.info, errOrdinalTypeExpected)
      elif lengthOrd(base) > MaxSetElements:
        localError(n.info, errSetTooBig)
  else:
    localError(n.info, errXExpectsOneTypeParam, "set")
    addSonSkipIntLit(result, errorType(c))

proc semContainer(c: PContext, n: PNode, kind: TTypeKind, kindStr: string,
                  prev: PType): PType =
  result = newOrPrevType(kind, prev, c)
  if sonsLen(n) == 2:
    var base = semTypeNode(c, n.sons[1], nil)
    addSonSkipIntLit(result, base)
  else:
    localError(n.info, errXExpectsOneTypeParam, kindStr)
    addSonSkipIntLit(result, errorType(c))

proc semVarargs(c: PContext, n: PNode, prev: PType): PType =
  result = newOrPrevType(tyVarargs, prev, c)
  if sonsLen(n) == 2 or sonsLen(n) == 3:
    var base = semTypeNode(c, n.sons[1], nil)
    addSonSkipIntLit(result, base)
    if sonsLen(n) == 3:
      result.n = newIdentNode(considerQuotedIdent(n.sons[2]), n.sons[2].info)
  else:
    localError(n.info, errXExpectsOneTypeParam, "varargs")
    addSonSkipIntLit(result, errorType(c))

proc semAnyRef(c: PContext; n: PNode; kind: TTypeKind; prev: PType): PType =
  if n.len < 1:
    result = newConstraint(c, kind)
  else:
    let isCall = ord(n.kind in nkCallKinds)
    let n = if n[0].kind == nkBracket: n[0] else: n
    checkMinSonsLen(n, 1)
    result = newOrPrevType(kind, prev, c)
    # check every except the last is an object:
    for i in isCall .. n.len-2:
      let region = semTypeNode(c, n[i], nil)
      if region.skipTypes({tyGenericInst}).kind notin {tyError, tyObject}:
        message n[i].info, errGenerated, "region needs to be an object type"
      addSonSkipIntLit(result, region)
    var base = semTypeNode(c, n.lastSon, nil)
    addSonSkipIntLit(result, base)

proc semVarType(c: PContext, n: PNode, prev: PType): PType =
  if sonsLen(n) == 1:
    result = newOrPrevType(tyVar, prev, c)
    var base = semTypeNode(c, n.sons[0], nil)
    if base.kind == tyVar:
      localError(n.info, errVarVarTypeNotAllowed)
      base = base.sons[0]
    addSonSkipIntLit(result, base)
  else:
    result = newConstraint(c, tyVar)

proc semDistinct(c: PContext, n: PNode, prev: PType): PType =
  if n.len == 0: return newConstraint(c, tyDistinct)
  result = newOrPrevType(tyDistinct, prev, c)
  addSonSkipIntLit(result, semTypeNode(c, n.sons[0], nil))
  if n.len > 1: result.n = n[1]

proc semRangeAux(c: PContext, n: PNode, prev: PType): PType =
  assert isRange(n)
  checkSonsLen(n, 3)
  result = newOrPrevType(tyRange, prev, c)
  result.n = newNodeI(nkRange, n.info)
  if (n[1].kind == nkEmpty) or (n[2].kind == nkEmpty):
    localError(n.info, errRangeIsEmpty)

  var range: array[2, PNode]
  range[0] = semExprWithType(c, n[1], {efDetermineType})
  range[1] = semExprWithType(c, n[2], {efDetermineType})

  var rangeT: array[2, PType]
  for i in 0..1:
    rangeT[i] = range[i].typ.skipTypes({tyStatic}).skipIntLit

  if not sameType(rangeT[0].skipTypes({tyRange}), rangeT[1].skipTypes({tyRange})):
    localError(n.info, errPureTypeMismatch)
  elif not rangeT[0].isOrdinalType:
    localError(n.info, errOrdinalTypeExpected)
  elif enumHasHoles(rangeT[0]):
    localError(n.info, errEnumXHasHoles, rangeT[0].sym.name.s)

  for i in 0..1:
    if hasGenericArguments(range[i]):
      result.n.addSon makeStaticExpr(c, range[i])
    else:
      result.n.addSon semConstExpr(c, range[i])

  if weakLeValue(result.n[0], result.n[1]) == impNo:
    localError(n.info, errRangeIsEmpty)

  addSonSkipIntLit(result, rangeT[0])

proc semRange(c: PContext, n: PNode, prev: PType): PType =
  result = nil
  if sonsLen(n) == 2:
    if isRange(n[1]):
      result = semRangeAux(c, n[1], prev)
      let n = result.n
      if n.sons[0].kind in {nkCharLit..nkUInt64Lit} and n.sons[0].intVal > 0:
        incl(result.flags, tfNeedsInit)
      elif n.sons[1].kind in {nkCharLit..nkUInt64Lit} and n.sons[1].intVal < 0:
        incl(result.flags, tfNeedsInit)
      elif n.sons[0].kind in {nkFloatLit..nkFloat64Lit} and
          n.sons[0].floatVal > 0.0:
        incl(result.flags, tfNeedsInit)
      elif n.sons[1].kind in {nkFloatLit..nkFloat64Lit} and
          n.sons[1].floatVal < 0.0:
        incl(result.flags, tfNeedsInit)
    else:
      localError(n.sons[0].info, errRangeExpected)
      result = newOrPrevType(tyError, prev, c)
  else:
    localError(n.info, errXExpectsOneTypeParam, "range")
    result = newOrPrevType(tyError, prev, c)

proc semArrayIndex(c: PContext, n: PNode): PType =
  if isRange(n): result = semRangeAux(c, n, nil)
  else:
    let e = semExprWithType(c, n, {efDetermineType})
    if e.typ.kind == tyFromExpr:
      result = makeRangeWithStaticExpr(c, e.typ.n)
    elif e.kind in {nkIntLit..nkUInt64Lit}:
      result = makeRangeType(c, 0, e.intVal-1, n.info, e.typ)
    elif e.kind == nkSym and e.typ.kind == tyStatic:
      if e.sym.ast != nil:
        return semArrayIndex(c, e.sym.ast)
      if not isOrdinalType(e.typ.lastSon):
        localError(n[1].info, errOrdinalTypeExpected)
      result = makeRangeWithStaticExpr(c, e)
      if c.inGenericContext > 0: result.flags.incl tfUnresolved
    elif e.kind in nkCallKinds and hasGenericArguments(e):
      if not isOrdinalType(e.typ):
        localError(n[1].info, errOrdinalTypeExpected)
      # This is an int returning call, depending on an
      # yet unknown generic param (see tgenericshardcases).
      # We are going to construct a range type that will be
      # properly filled-out in semtypinst (see how tyStaticExpr
      # is handled there).
      result = makeRangeWithStaticExpr(c, e)
    elif e.kind == nkIdent:
      result = e.typ.skipTypes({tyTypeDesc})
    else:
      let x = semConstExpr(c, e)
      if x.kind in {nkIntLit..nkUInt64Lit}:
        result = makeRangeType(c, 0, x.intVal-1, n.info,
                             x.typ.skipTypes({tyTypeDesc}))
      else:
        result = x.typ.skipTypes({tyTypeDesc})
        #localError(n[1].info, errConstExprExpected)

proc semArray(c: PContext, n: PNode, prev: PType): PType =
  var base: PType
  result = newOrPrevType(tyArray, prev, c)
  if sonsLen(n) == 3:
    # 3 = length(array indx base)
    var indx = semArrayIndex(c, n[1])
    addSonSkipIntLit(result, indx)
    if indx.kind == tyGenericInst: indx = lastSon(indx)
    if indx.kind notin {tyGenericParam, tyStatic, tyFromExpr}:
      if not isOrdinalType(indx):
        localError(n.sons[1].info, errOrdinalTypeExpected)
      elif enumHasHoles(indx):
        localError(n.sons[1].info, errEnumXHasHoles, indx.sym.name.s)
    base = semTypeNode(c, n.sons[2], nil)
    addSonSkipIntLit(result, base)
  else:
    localError(n.info, errArrayExpectsTwoTypeParams)
    result = newOrPrevType(tyError, prev, c)

proc semOrdinal(c: PContext, n: PNode, prev: PType): PType =
  result = newOrPrevType(tyOrdinal, prev, c)
  if sonsLen(n) == 2:
    var base = semTypeNode(c, n.sons[1], nil)
    if base.kind != tyGenericParam:
      if not isOrdinalType(base):
        localError(n.sons[1].info, errOrdinalTypeExpected)
    addSonSkipIntLit(result, base)
  else:
    localError(n.info, errXExpectsOneTypeParam, "ordinal")
    result = newOrPrevType(tyError, prev, c)

proc semTypeIdent(c: PContext, n: PNode): PSym =
  if n.kind == nkSym:
    result = n.sym
  else:
    when defined(nimfix):
      result = pickSym(c, n, skType)
      if result.isNil:
        result = qualifiedLookUp(c, n, {checkAmbiguity, checkUndeclared})
    else:
      result = qualifiedLookUp(c, n, {checkAmbiguity, checkUndeclared})
    if result != nil:
      markUsed(n.info, result)
      styleCheckUse(n.info, result)
      if result.kind == skParam and result.typ.kind == tyTypeDesc:
        # This is a typedesc param. is it already bound?
        # it's not bound when it's used multiple times in the
        # proc signature for example
        if c.inGenericInst > 0:
          let bound = result.typ.sons[0].sym
          if bound != nil: return bound
          return result
        if result.typ.sym == nil:
          localError(n.info, errTypeExpected)
          return errorSym(c, n)
        result = result.typ.sym.copySym
        result.typ = copyType(result.typ, result.typ.owner, true)
        result.typ.flags.incl tfUnresolved

      if result.kind == skGenericParam:
        if result.typ.kind == tyGenericParam and result.typ.len == 0 and
           tfWildcard in result.typ.flags:
          # collapse the wild-card param to a type
          result.kind = skType
          result.typ.flags.excl tfWildcard
          return
        else:
          localError(n.info, errTypeExpected)
          return errorSym(c, n)

      if result.kind != skType:
        # this implements the wanted ``var v: V, x: V`` feature ...
        var ov: TOverloadIter
        var amb = initOverloadIter(ov, c, n)
        while amb != nil and amb.kind != skType:
          amb = nextOverloadIter(ov, c, n)
        if amb != nil: result = amb
        else:
          if result.kind != skError: localError(n.info, errTypeExpected)
          return errorSym(c, n)
      if result.typ.kind != tyGenericParam:
        # XXX get rid of this hack!
        var oldInfo = n.info
        when defined(useNodeIds):
          let oldId = n.id
        reset(n[])
        when defined(useNodeIds):
          n.id = oldId
        n.kind = nkSym
        n.sym = result
        n.info = oldInfo
        n.typ = result.typ
    else:
      localError(n.info, errIdentifierExpected)
      result = errorSym(c, n)

proc semAnonTuple(c: PContext, n: PNode, prev: PType): PType =
  if sonsLen(n) == 0:
    localError(n.info, errTypeExpected)
  result = newOrPrevType(tyTuple, prev, c)
  for i in countup(0, sonsLen(n) - 1):
    addSonSkipIntLit(result, semTypeNode(c, n.sons[i], nil))

proc semTuple(c: PContext, n: PNode, prev: PType): PType =
  var typ: PType
  result = newOrPrevType(tyTuple, prev, c)
  result.n = newNodeI(nkRecList, n.info)
  var check = initIntSet()
  var counter = 0
  for i in countup(0, sonsLen(n) - 1):
    var a = n.sons[i]
    if (a.kind != nkIdentDefs): illFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    if a.sons[length - 2].kind != nkEmpty:
      typ = semTypeNode(c, a.sons[length - 2], nil)
    else:
      localError(a.info, errTypeExpected)
      typ = errorType(c)
    if a.sons[length - 1].kind != nkEmpty:
      localError(a.sons[length - 1].info, errInitHereNotAllowed)
    for j in countup(0, length - 3):
      var field = newSymG(skField, a.sons[j], c)
      field.typ = typ
      field.position = counter
      inc(counter)
      if containsOrIncl(check, field.name.id):
        localError(a.sons[j].info, errAttemptToRedefine, field.name.s)
      else:
        addSon(result.n, newSymNode(field))
        addSonSkipIntLit(result, typ)
      if gCmd == cmdPretty: styleCheckDef(a.sons[j].info, field)

proc semIdentVis(c: PContext, kind: TSymKind, n: PNode,
                 allowed: TSymFlags): PSym =
  # identifier with visibility
  if n.kind == nkPostfix:
    if sonsLen(n) == 2 and n.sons[0].kind == nkIdent:
      # for gensym'ed identifiers the identifier may already have been
      # transformed to a symbol and we need to use that here:
      result = newSymG(kind, n.sons[1], c)
      var v = n.sons[0].ident
      if sfExported in allowed and v.id == ord(wStar):
        incl(result.flags, sfExported)
      else:
        localError(n.sons[0].info, errInvalidVisibilityX, v.s)
    else:
      illFormedAst(n)
  else:
    result = newSymG(kind, n, c)

proc semIdentWithPragma(c: PContext, kind: TSymKind, n: PNode,
                        allowed: TSymFlags): PSym =
  if n.kind == nkPragmaExpr:
    checkSonsLen(n, 2)
    result = semIdentVis(c, kind, n.sons[0], allowed)
    case kind
    of skType:
      # process pragmas later, because result.typ has not been set yet
      discard
    of skField: pragma(c, result, n.sons[1], fieldPragmas)
    of skVar:   pragma(c, result, n.sons[1], varPragmas)
    of skLet:   pragma(c, result, n.sons[1], letPragmas)
    of skConst: pragma(c, result, n.sons[1], constPragmas)
    else: discard
  else:
    result = semIdentVis(c, kind, n, allowed)
  if gCmd == cmdPretty: styleCheckDef(n.info, result)

proc checkForOverlap(c: PContext, t: PNode, currentEx, branchIndex: int) =
  let ex = t[branchIndex][currentEx].skipConv
  for i in countup(1, branchIndex):
    for j in countup(0, sonsLen(t.sons[i]) - 2):
      if i == branchIndex and j == currentEx: break
      if overlap(t.sons[i].sons[j].skipConv, ex):
        localError(ex.info, errDuplicateCaseLabel)

proc semBranchRange(c: PContext, t, a, b: PNode, covered: var BiggestInt): PNode =
  checkMinSonsLen(t, 1)
  let ac = semConstExpr(c, a)
  let bc = semConstExpr(c, b)
  let at = fitNode(c, t.sons[0].typ, ac).skipConvTakeType
  let bt = fitNode(c, t.sons[0].typ, bc).skipConvTakeType

  result = newNodeI(nkRange, a.info)
  result.add(at)
  result.add(bt)
  if emptyRange(ac, bc): localError(b.info, errRangeIsEmpty)
  else: covered = covered + getOrdValue(bc) - getOrdValue(ac) + 1

proc semCaseBranchRange(c: PContext, t, b: PNode,
                        covered: var BiggestInt): PNode =
  checkSonsLen(b, 3)
  result = semBranchRange(c, t, b.sons[1], b.sons[2], covered)

proc semCaseBranchSetElem(c: PContext, t, b: PNode,
                          covered: var BiggestInt): PNode =
  if isRange(b):
    checkSonsLen(b, 3)
    result = semBranchRange(c, t, b.sons[1], b.sons[2], covered)
  elif b.kind == nkRange:
    checkSonsLen(b, 2)
    result = semBranchRange(c, t, b.sons[0], b.sons[1], covered)
  else:
    result = fitNode(c, t.sons[0].typ, b)
    inc(covered)

proc semCaseBranch(c: PContext, t, branch: PNode, branchIndex: int,
                   covered: var BiggestInt) =

  for i in countup(0, sonsLen(branch) - 2):
    var b = branch.sons[i]
    if b.kind == nkRange:
      branch.sons[i] = b
    elif isRange(b):
      branch.sons[i] = semCaseBranchRange(c, t, b, covered)
    else:
      # constant sets and arrays are allowed:
      var r = semConstExpr(c, b)
      if r.kind in {nkCurly, nkBracket} and len(r) == 0  and sonsLen(branch)==2:
        # discarding ``{}`` and ``[]`` branches silently
        delSon(branch, 0)
        return
      elif r.kind notin {nkCurly, nkBracket} or len(r) == 0:
        checkMinSonsLen(t, 1)
        branch.sons[i] = skipConv(fitNode(c, t.sons[0].typ, r))
        inc(covered)
      else:
        # first element is special and will overwrite: branch.sons[i]:
        branch.sons[i] = semCaseBranchSetElem(c, t, r[0], covered)
        # other elements have to be added to ``branch``
        for j in 1 .. <r.len:
          branch.add(semCaseBranchSetElem(c, t, r[j], covered))
          # caution! last son of branch must be the actions to execute:
          var L = branch.len
          swap(branch.sons[L-2], branch.sons[L-1])
    checkForOverlap(c, t, i, branchIndex)

proc semRecordNodeAux(c: PContext, n: PNode, check: var IntSet, pos: var int,
                      father: PNode, rectype: PType)
proc semRecordCase(c: PContext, n: PNode, check: var IntSet, pos: var int,
                   father: PNode, rectype: PType) =
  var a = copyNode(n)
  checkMinSonsLen(n, 2)
  semRecordNodeAux(c, n.sons[0], check, pos, a, rectype)
  if a.sons[0].kind != nkSym:
    internalError("semRecordCase: discriminant is no symbol")
    return
  incl(a.sons[0].sym.flags, sfDiscriminant)
  var covered: BiggestInt = 0
  var typ = skipTypes(a.sons[0].typ, abstractVar-{tyTypeDesc})
  if not isOrdinalType(typ):
    localError(n.info, errSelectorMustBeOrdinal)
  elif firstOrd(typ) < 0:
    localError(n.info, errOrdXMustNotBeNegative, a.sons[0].sym.name.s)
  elif lengthOrd(typ) > 0x00007FFF:
    localError(n.info, errLenXinvalid, a.sons[0].sym.name.s)
  var chckCovered = true
  for i in countup(1, sonsLen(n) - 1):
    var b = copyTree(n.sons[i])
    addSon(a, b)
    case n.sons[i].kind
    of nkOfBranch:
      checkMinSonsLen(b, 2)
      semCaseBranch(c, a, b, i, covered)
    of nkElse:
      chckCovered = false
      checkSonsLen(b, 1)
    else: illFormedAst(n)
    delSon(b, sonsLen(b) - 1)
    semRecordNodeAux(c, lastSon(n.sons[i]), check, pos, b, rectype)
  if chckCovered and (covered != lengthOrd(a.sons[0].typ)):
    localError(a.info, errNotAllCasesCovered)
  addSon(father, a)

proc semRecordNodeAux(c: PContext, n: PNode, check: var IntSet, pos: var int,
                      father: PNode, rectype: PType) =
  if n == nil: return
  case n.kind
  of nkRecWhen:
    var branch: PNode = nil   # the branch to take
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it == nil: illFormedAst(n)
      var idx = 1
      case it.kind
      of nkElifBranch:
        checkSonsLen(it, 2)
        if c.inGenericContext == 0:
          var e = semConstBoolExpr(c, it.sons[0])
          if e.kind != nkIntLit: internalError(e.info, "semRecordNodeAux")
          elif e.intVal != 0 and branch == nil: branch = it.sons[1]
        else:
          it.sons[0] = forceBool(c, semExprWithType(c, it.sons[0]))
      of nkElse:
        checkSonsLen(it, 1)
        if branch == nil: branch = it.sons[0]
        idx = 0
      else: illFormedAst(n)
      if c.inGenericContext > 0:
        # use a new check intset here for each branch:
        var newCheck: IntSet
        assign(newCheck, check)
        var newPos = pos
        var newf = newNodeI(nkRecList, n.info)
        semRecordNodeAux(c, it.sons[idx], newCheck, newPos, newf, rectype)
        it.sons[idx] = if newf.len == 1: newf[0] else: newf
    if c.inGenericContext > 0:
      addSon(father, n)
    elif branch != nil:
      semRecordNodeAux(c, branch, check, pos, father, rectype)
  of nkRecCase:
    semRecordCase(c, n, check, pos, father, rectype)
  of nkNilLit:
    if father.kind != nkRecList: addSon(father, newNodeI(nkRecList, n.info))
  of nkRecList:
    # attempt to keep the nesting at a sane level:
    var a = if father.kind == nkRecList: father else: copyNode(n)
    for i in countup(0, sonsLen(n) - 1):
      semRecordNodeAux(c, n.sons[i], check, pos, a, rectype)
    if a != father: addSon(father, a)
  of nkIdentDefs:
    checkMinSonsLen(n, 3)
    var length = sonsLen(n)
    var a: PNode
    if father.kind != nkRecList and length>=4: a = newNodeI(nkRecList, n.info)
    else: a = ast.emptyNode
    if n.sons[length-1].kind != nkEmpty:
      localError(n.sons[length-1].info, errInitHereNotAllowed)
    var typ: PType
    if n.sons[length-2].kind == nkEmpty:
      localError(n.info, errTypeExpected)
      typ = errorType(c)
    else:
      typ = semTypeNode(c, n.sons[length-2], nil)
      propagateToOwner(rectype, typ)
    let rec = rectype.sym
    for i in countup(0, sonsLen(n)-3):
      var f = semIdentWithPragma(c, skField, n.sons[i], {sfExported})
      suggestSym(n.sons[i].info, f)
      f.typ = typ
      f.position = pos
      if (rec != nil) and ({sfImportc, sfExportc} * rec.flags != {}) and
          (f.loc.r == nil):
        f.loc.r = toRope(f.name.s)
        f.flags = f.flags + ({sfImportc, sfExportc} * rec.flags)
      inc(pos)
      if containsOrIncl(check, f.name.id):
        localError(n.sons[i].info, errAttemptToRedefine, f.name.s)
      if a.kind == nkEmpty: addSon(father, newSymNode(f))
      else: addSon(a, newSymNode(f))
      styleCheckDef(f)
    if a.kind != nkEmpty: addSon(father, a)
  of nkEmpty: discard
  else: illFormedAst(n)

proc addInheritedFieldsAux(c: PContext, check: var IntSet, pos: var int,
                           n: PNode) =
  case n.kind
  of nkRecCase:
    if (n.sons[0].kind != nkSym): internalError(n.info, "addInheritedFieldsAux")
    addInheritedFieldsAux(c, check, pos, n.sons[0])
    for i in countup(1, sonsLen(n) - 1):
      case n.sons[i].kind
      of nkOfBranch, nkElse:
        addInheritedFieldsAux(c, check, pos, lastSon(n.sons[i]))
      else: internalError(n.info, "addInheritedFieldsAux(record case branch)")
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      addInheritedFieldsAux(c, check, pos, n.sons[i])
  of nkSym:
    incl(check, n.sym.name.id)
    inc(pos)
  else: internalError(n.info, "addInheritedFieldsAux()")

proc skipGenericInvocation(t: PType): PType {.inline.} =
  result = t
  if result.kind == tyGenericInvocation:
    result = result.sons[0]
  if result.kind == tyGenericBody:
    result = lastSon(result)

proc addInheritedFields(c: PContext, check: var IntSet, pos: var int,
                        obj: PType) =
  assert obj.kind == tyObject
  if (sonsLen(obj) > 0) and (obj.sons[0] != nil):
    addInheritedFields(c, check, pos, obj.sons[0].skipGenericInvocation)
  addInheritedFieldsAux(c, check, pos, obj.n)

proc semObjectNode(c: PContext, n: PNode, prev: PType): PType =
  if n.sonsLen == 0: return newConstraint(c, tyObject)
  var check = initIntSet()
  var pos = 0
  var base: PType = nil
  # n.sons[0] contains the pragmas (if any). We process these later...
  checkSonsLen(n, 3)
  if n.sons[1].kind != nkEmpty:
    base = skipTypes(semTypeNode(c, n.sons[1].sons[0], nil), skipPtrs)
    var concreteBase = skipGenericInvocation(base).skipTypes(skipPtrs)
    if concreteBase.kind == tyObject and tfFinal notin concreteBase.flags:
      addInheritedFields(c, check, pos, concreteBase)
    else:
      if concreteBase.kind != tyError:
        localError(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects)
      base = nil
  if n.kind != nkObjectTy: internalError(n.info, "semObjectNode")
  result = newOrPrevType(tyObject, prev, c)
  rawAddSon(result, base)
  result.n = newNodeI(nkRecList, n.info)
  semRecordNodeAux(c, n.sons[2], check, pos, result.n, result)
  if n.sons[0].kind != nkEmpty:
    # dummy symbol for `pragma`:
    var s = newSymS(skType, newIdentNode(getIdent("dummy"), n.info), c)
    s.typ = result
    pragma(c, s, n.sons[0], typePragmas)
  if base == nil and tfInheritable notin result.flags:
    incl(result.flags, tfFinal)

proc findEnforcedStaticType(t: PType): PType =
  # This handles types such as `static[T] and Foo`,
  # which are subset of `static[T]`, hence they could
  # be treated in the same way
  if t.kind == tyStatic: return t
  if t.kind == tyAnd:
    for s in t.sons:
      let t = findEnforcedStaticType(s)
      if t != nil: return t

proc addParamOrResult(c: PContext, param: PSym, kind: TSymKind) =
  if kind == skMacro:
    let staticType = findEnforcedStaticType(param.typ)
    if staticType != nil:
      var a = copySym(param)
      a.typ = staticType.base
      addDecl(c, a)
    elif param.typ.kind == tyTypeDesc:
      addDecl(c, param)
    else:
      # within a macro, every param has the type NimNode!
      let nn = if getCompilerProc("NimNode") != nil: getSysSym"NimNode"
               else: getSysSym"PNimrodNode"
      var a = copySym(param)
      a.typ = nn.typ
      addDecl(c, a)
  else:
    if sfGenSym notin param.flags: addDecl(c, param)

let typedescId = getIdent"typedesc"

template shouldHaveMeta(t) =
  internalAssert tfHasMeta in t.flags
  # result.lastSon.flags.incl tfHasMeta

proc liftParamType(c: PContext, procKind: TSymKind, genericParams: PNode,
                   paramType: PType, paramName: string,
                   info: TLineInfo, anon = false): PType =
  if paramType == nil: return # (e.g. proc return type)

  proc addImplicitGenericImpl(typeClass: PType, typId: PIdent): PType =
    let finalTypId = if typId != nil: typId
                     else: getIdent(paramName & ":type")
    if genericParams == nil:
      # This happens with anonymous proc types appearing in signatures
      # XXX: we need to lift these earlier
      return
    # is this a bindOnce type class already present in the param list?
    for i in countup(0, genericParams.len - 1):
      if genericParams.sons[i].sym.name.id == finalTypId.id:
        return genericParams.sons[i].typ

    let owner = if typeClass.sym != nil: typeClass.sym
                else: getCurrOwner()
    var s = newSym(skType, finalTypId, owner, info)
    if typId == nil: s.flags.incl(sfAnon)
    s.linkTo(typeClass)
    typeClass.flags.incl tfImplicitTypeParam
    s.position = genericParams.len
    genericParams.addSon(newSymNode(s))
    result = typeClass
    addDecl(c, s)

  # XXX: There are codegen errors if this is turned into a nested proc
  template liftingWalk(typ: PType, anonFlag = false): expr =
    liftParamType(c, procKind, genericParams, typ, paramName, info, anonFlag)
  #proc liftingWalk(paramType: PType, anon = false): PType =

  var paramTypId = if not anon and paramType.sym != nil: paramType.sym.name
                   else: nil

  template maybeLift(typ: PType): expr =
    let lifted = liftingWalk(typ)
    (if lifted != nil: lifted else: typ)

  template addImplicitGeneric(e: expr): expr =
    addImplicitGenericImpl(e, paramTypId)

  case paramType.kind:
  of tyAnything:
    result = addImplicitGeneric(newTypeS(tyGenericParam, c))

  of tyStatic:
    # proc(a: expr{string}, b: expr{nkLambda})
    # overload on compile time values and AST trees
    if paramType.n != nil: return # this is a concrete type
    if tfUnresolved in paramType.flags: return # already lifted
    let base = paramType.base.maybeLift
    if base.isMetaType and procKind == skMacro:
      localError(info, errMacroBodyDependsOnGenericTypes, paramName)
    result = addImplicitGeneric(c.newTypeWithSons(tyStatic, @[base]))
    result.flags.incl({tfHasStatic, tfUnresolved})

  of tyTypeDesc:
    if tfUnresolved notin paramType.flags:
      # naked typedescs are not bindOnce types
      if paramType.base.kind == tyNone and paramTypId != nil and
         paramTypId.id == typedescId.id: paramTypId = nil
      result = addImplicitGeneric(
        c.newTypeWithSons(tyTypeDesc, @[paramType.base]))

  of tyDistinct:
    if paramType.sonsLen == 1:
      # disable the bindOnce behavior for the type class
      result = liftingWalk(paramType.sons[0], true)

  of tySequence, tySet, tyArray, tyOpenArray,
     tyVar, tyPtr, tyRef, tyProc:
    # XXX: this is a bit strange, but proc(s: seq)
    # produces tySequence(tyGenericParam, tyNone).
    # This also seems to be true when creating aliases
    # like: type myseq = distinct seq.
    # Maybe there is another better place to associate
    # the seq type class with the seq identifier.
    if paramType.kind == tySequence and paramType.lastSon.kind == tyNone:
      let typ = c.newTypeWithSons(tyBuiltInTypeClass,
                                  @[newTypeS(paramType.kind, c)])
      result = addImplicitGeneric(typ)
    else:
      for i in 0 .. <paramType.sons.len:
        if paramType.sons[i] == paramType:
          globalError(info, errIllegalRecursionInTypeX, typeToString(paramType))
        var lifted = liftingWalk(paramType.sons[i])
        if lifted != nil:
          paramType.sons[i] = lifted
          result = paramType

  of tyGenericBody:
    result = newTypeS(tyGenericInvocation, c)
    result.rawAddSon(paramType)

    for i in 0 .. paramType.sonsLen - 2:
      if paramType.sons[i].kind == tyStatic:
        var x = copyNode(ast.emptyNode)
        x.typ = paramType.sons[i]
        result.rawAddSon makeTypeFromExpr(c, x) # aka 'tyUnknown'
      else:
        result.rawAddSon newTypeS(tyAnything, c)

    if paramType.lastSon.kind == tyUserTypeClass:
      result.kind = tyUserTypeClassInst
      result.rawAddSon paramType.lastSon
      return addImplicitGeneric(result)

    result = instGenericContainer(c, paramType.sym.info, result,
                                  allowMetaTypes = true)
    result = newTypeWithSons(c, tyCompositeTypeClass, @[paramType, result])
    result = addImplicitGeneric(result)

  of tyIter:
    if paramType.callConv == ccInline:
      if procKind notin {skTemplate, skMacro, skIterator}:
        localError(info, errInlineIteratorsAsProcParams)
      if paramType.len == 1:
        let lifted = liftingWalk(paramType.base)
        if lifted != nil: paramType.sons[0] = lifted
      result = addImplicitGeneric(paramType)

  of tyGenericInst:
    if paramType.lastSon.kind == tyUserTypeClass:
      var cp = copyType(paramType, getCurrOwner(), false)
      cp.kind = tyUserTypeClassInst
      return addImplicitGeneric(cp)

    for i in 1 .. (paramType.sons.len - 2):
      var lifted = liftingWalk(paramType.sons[i])
      if lifted != nil:
        paramType.sons[i] = lifted
        result = paramType
        result.lastSon.shouldHaveMeta

    let liftBody = liftingWalk(paramType.lastSon, true)
    if liftBody != nil:
      result = liftBody
      result.shouldHaveMeta

  of tyGenericInvocation:
    for i in 1 .. <paramType.sonsLen:
      let lifted = liftingWalk(paramType.sons[i])
      if lifted != nil: paramType.sons[i] = lifted
    when false:
      let expanded = instGenericContainer(c, info, paramType,
                                          allowMetaTypes = true)
      result = liftingWalk(expanded, true)

  of tyUserTypeClass, tyBuiltInTypeClass, tyAnd, tyOr, tyNot:
    result = addImplicitGeneric(copyType(paramType, getCurrOwner(), true))

  of tyExpr:
    if procKind notin {skMacro, skTemplate}:
      result = addImplicitGeneric(newTypeS(tyAnything, c))

  of tyGenericParam:
    markUsed(info, paramType.sym)
    styleCheckUse(info, paramType.sym)
    if tfWildcard in paramType.flags:
      paramType.flags.excl tfWildcard
      paramType.sym.kind = skType

  else: discard

  # result = liftingWalk(paramType)

proc semParamType(c: PContext, n: PNode, constraint: var PNode): PType =
  if n.kind == nkCurlyExpr:
    result = semTypeNode(c, n.sons[0], nil)
    constraint = semNodeKindConstraints(n)
  else:
    result = semTypeNode(c, n, nil)

proc newProcType(c: PContext; info: TLineInfo; prev: PType = nil): PType =
  result = newOrPrevType(tyProc, prev, c)
  result.callConv = lastOptionEntry(c).defaultCC
  result.n = newNodeI(nkFormalParams, info)
  rawAddSon(result, nil) # return type
  # result.n[0] used to be `nkType`, but now it's `nkEffectList` because
  # the effects are now stored in there too ... this is a bit hacky, but as
  # usual we desperately try to save memory:
  addSon(result.n, newNodeI(nkEffectList, info))

proc semProcTypeNode(c: PContext, n, genericParams: PNode,
                     prev: PType, kind: TSymKind; isType=false): PType =
  # for historical reasons (code grows) this is invoked for parameter
  # lists too and then 'isType' is false.
  var cl: IntSet
  checkMinSonsLen(n, 1)
  result = newProcType(c, n.info, prev)
  if genericParams != nil and sonsLen(genericParams) == 0:
    cl = initIntSet()
  var check = initIntSet()
  var counter = 0
  for i in countup(1, n.len - 1):
    var a = n.sons[i]
    if a.kind != nkIdentDefs:
      # for some generic instantiations the passed ':env' parameter
      # for closures has already been produced (see bug #898). We simply
      # skip this parameter here. It'll then be re-generated in another LL
      # pass over this instantiation:
      if a.kind == nkSym and sfFromGeneric in a.sym.flags: continue
      illFormedAst(a)
    checkMinSonsLen(a, 3)
    var
      typ: PType = nil
      def: PNode = nil
      constraint: PNode = nil
      length = sonsLen(a)
      hasType = a.sons[length-2].kind != nkEmpty
      hasDefault = a.sons[length-1].kind != nkEmpty
    if hasType:
      typ = semParamType(c, a.sons[length-2], constraint)

    if hasDefault:
      def = semExprWithType(c, a.sons[length-1])
      # check type compatibility between def.typ and typ:
      if typ == nil:
        typ = def.typ
      elif def != nil:
        # and def.typ != nil and def.typ.kind != tyNone:
        # example code that triggers it:
        # proc sort[T](cmp: proc(a, b: T): int = cmp)
        if not containsGenericType(typ):
          def = fitNode(c, typ, def)
    if not hasType and not hasDefault:
      if isType: localError(a.info, "':' expected")
      let tdef = if kind in {skTemplate, skMacro}: tyExpr else: tyAnything
      if tdef == tyAnything:
        message(a.info, warnTypelessParam, renderTree(n))
      typ = newTypeS(tdef, c)

    if skipTypes(typ, {tyGenericInst}).kind == tyEmpty: continue
    for j in countup(0, length-3):
      var arg = newSymG(skParam, a.sons[j], c)
      let lifted = liftParamType(c, kind, genericParams, typ,
                                 arg.name.s, arg.info)
      let finalType = if lifted != nil: lifted else: typ.skipIntLit
      arg.typ = finalType
      arg.position = counter
      arg.constraint = constraint
      inc(counter)
      if def != nil and def.kind != nkEmpty: arg.ast = copyTree(def)
      if containsOrIncl(check, arg.name.id):
        localError(a.sons[j].info, errAttemptToRedefine, arg.name.s)
      addSon(result.n, newSymNode(arg))
      rawAddSon(result, finalType)
      addParamOrResult(c, arg, kind)
      if gCmd == cmdPretty: styleCheckDef(a.sons[j].info, arg)

  var r: PType
  if n.sons[0].kind != nkEmpty:
    r = semTypeNode(c, n.sons[0], nil)
  elif kind == skIterator:
    # XXX This is special magic we should likely get rid of
    r = newTypeS(tyExpr, c)

  if r != nil:
    # turn explicit 'void' return type into 'nil' because the rest of the
    # compiler only checks for 'nil':
    if skipTypes(r, {tyGenericInst}).kind != tyEmpty:
      # 'auto' as a return type does not imply a generic:
      if r.kind != tyExpr:
        if r.sym == nil or sfAnon notin r.sym.flags:
          let lifted = liftParamType(c, kind, genericParams, r, "result",
                                     n.sons[0].info)
          if lifted != nil: r = lifted
          r.flags.incl tfRetType
        r = skipIntLit(r)
        if kind == skIterator:
          # see tchainediterators
          # in cases like iterator foo(it: iterator): type(it)
          # we don't need to change the return type to iter[T]
          if not r.isInlineIterator: r = newTypeWithSons(c, tyIter, @[r])
      result.sons[0] = r
      result.n.typ = r

  if genericParams != nil:
    for n in genericParams:
      if tfWildcard in n.sym.typ.flags:
        n.sym.kind = skType
        n.sym.typ.flags.excl tfWildcard

proc semStmtListType(c: PContext, n: PNode, prev: PType): PType =
  checkMinSonsLen(n, 1)
  var length = sonsLen(n)
  for i in countup(0, length - 2):
    n.sons[i] = semStmt(c, n.sons[i])
  if length > 0:
    result = semTypeNode(c, n.sons[length - 1], prev)
    n.typ = result
    n.sons[length - 1].typ = result
  else:
    result = nil

proc semBlockType(c: PContext, n: PNode, prev: PType): PType =
  inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2)
  openScope(c)
  if n.sons[0].kind notin {nkEmpty, nkSym}:
    addDecl(c, newSymS(skLabel, n.sons[0], c))
  result = semStmtListType(c, n.sons[1], prev)
  n.sons[1].typ = result
  n.typ = result
  closeScope(c)
  dec(c.p.nestedBlockCounter)

proc semGenericParamInInvocation(c: PContext, n: PNode): PType =
  result = semTypeNode(c, n, nil)

proc semGeneric(c: PContext, n: PNode, s: PSym, prev: PType): PType =
  if s.typ == nil:
    localError(n.info, "cannot instantiate the '$1' $2" %
                       [s.name.s, ($s.kind).substr(2).toLower])
    return newOrPrevType(tyError, prev, c)

  var t = s.typ
  if t.kind == tyCompositeTypeClass and t.base.kind == tyGenericBody:
    t = t.base

  result = newOrPrevType(tyGenericInvocation, prev, c)
  addSonSkipIntLit(result, t)

  template addToResult(typ) =
    if typ.isNil:
      internalAssert false
      rawAddSon(result, typ)
    else: addSonSkipIntLit(result, typ)

  if t.kind == tyForward:
    for i in countup(1, sonsLen(n)-1):
      var elem = semGenericParamInInvocation(c, n.sons[i])
      addToResult(elem)
    return
  elif t.kind != tyGenericBody:
    # we likely got code of the form TypeA[TypeB] where TypeA is
    # not generic.
    localError(n.info, errNoGenericParamsAllowedForX, s.name.s)
    return newOrPrevType(tyError, prev, c)
  else:
    var m = newCandidate(c, t)
    matches(c, n, copyTree(n), m)

    if m.state != csMatch and not m.typedescMatched:
      let err = "cannot instantiate " & typeToString(t) & "\n" &
                "got: (" & describeArgs(c, n) & ")\n" &
                "but expected: (" & describeArgs(c, t.n, 0) & ")"
      localError(n.info, errGenerated, err)
      return newOrPrevType(tyError, prev, c)

    var isConcrete = true

    for i in 1 .. <m.call.len:
      var typ = m.call[i].typ
      if typ.kind == tyTypeDesc and typ.sons[0].kind == tyNone:
        isConcrete = false
        addToResult(typ)
      else:
        typ = typ.skipTypes({tyTypeDesc})
        if containsGenericType(typ): isConcrete = false
        addToResult(typ)

    if isConcrete:
      if s.ast == nil and s.typ.kind != tyCompositeTypeClass:
        # XXX: What kind of error is this? is it still relevant?
        localError(n.info, errCannotInstantiateX, s.name.s)
        result = newOrPrevType(tyError, prev, c)
      else:
        result = instGenericContainer(c, n.info, result,
                                      allowMetaTypes = false)

proc semTypeExpr(c: PContext, n: PNode): PType =
  var n = semExprWithType(c, n, {efDetermineType})
  if n.typ.kind == tyTypeDesc:
    result = n.typ.base
  else:
    localError(n.info, errTypeExpected, n.renderTree)

proc freshType(res, prev: PType): PType {.inline.} =
  if prev.isNil:
    result = copyType(res, res.owner, keepId=false)
  else:
    result = res

proc semTypeClass(c: PContext, n: PNode, prev: PType): PType =
  # if n.sonsLen == 0: return newConstraint(c, tyTypeClass)
  if nfBase2 in n.flags:
    message(n.info, warnDeprecated, "use 'concept' instead; 'generic'")
  result = newOrPrevType(tyUserTypeClass, prev, c)
  result.n = n

  let
    pragmas = n[1]
    inherited = n[2]

  if inherited.kind != nkEmpty:
    for n in inherited.sons:
      let typ = semTypeNode(c, n, nil)
      result.sons.safeAdd(typ)

proc semProcTypeWithScope(c: PContext, n: PNode,
                        prev: PType, kind: TSymKind): PType =
  checkSonsLen(n, 2)
  openScope(c)
  result = semProcTypeNode(c, n.sons[0], nil, prev, kind, isType=true)
  # dummy symbol for `pragma`:
  var s = newSymS(kind, newIdentNode(getIdent("dummy"), n.info), c)
  s.typ = result
  if n.sons[1].kind == nkEmpty or n.sons[1].len == 0:
    if result.callConv == ccDefault:
      result.callConv = ccClosure
      #Message(n.info, warnImplicitClosure, renderTree(n))
  else:
    pragma(c, s, n.sons[1], procTypePragmas)
    when useEffectSystem: setEffectsForProcType(result, n.sons[1])
  closeScope(c)

proc semTypeNode(c: PContext, n: PNode, prev: PType): PType =
  result = nil
  if gCmd == cmdIdeTools: suggestExpr(c, n)
  case n.kind
  of nkEmpty: discard
  of nkTypeOfExpr:
    # for ``type(countup(1,3))``, see ``tests/ttoseq``.
    checkSonsLen(n, 1)
    let typExpr = semExprWithType(c, n.sons[0], {efInTypeof})
    result = typExpr.typ.skipTypes({tyIter})
  of nkPar:
    if sonsLen(n) == 1: result = semTypeNode(c, n.sons[0], prev)
    else:
      result = semAnonTuple(c, n, prev)
  of nkCallKinds:
    if isRange(n):
      result = semRangeAux(c, n, prev)
    elif n[0].kind notin nkIdentKinds:
      result = semTypeExpr(c, n)
    else:
      let op = considerQuotedIdent(n.sons[0])
      if op.id in {ord(wAnd), ord(wOr)} or op.s == "|":
        checkSonsLen(n, 3)
        var
          t1 = semTypeNode(c, n.sons[1], nil)
          t2 = semTypeNode(c, n.sons[2], nil)
        if t1 == nil:
          localError(n.sons[1].info, errTypeExpected)
          result = newOrPrevType(tyError, prev, c)
        elif t2 == nil:
          localError(n.sons[2].info, errTypeExpected)
          result = newOrPrevType(tyError, prev, c)
        else:
          result = if op.id == ord(wAnd): makeAndType(c, t1, t2)
                   else: makeOrType(c, t1, t2)
      elif op.id == ord(wNot):
        case n.len
        of 3:
          result = semTypeNode(c, n.sons[1], prev)
          if result.skipTypes({tyGenericInst}).kind in NilableTypes+GenericTypes and
              n.sons[2].kind == nkNilLit:
            result = freshType(result, prev)
            result.flags.incl(tfNotNil)
          else:
            localError(n.info, errGenerated, "invalid type")
        of 2:
          let negated = semTypeNode(c, n.sons[1], prev)
          result = makeNotType(c, negated)
        else:
          localError(n.info, errGenerated, "invalid type")
      elif op.id == ord(wPtr):
        result = semAnyRef(c, n, tyPtr, prev)
      elif op.id == ord(wRef):
        result = semAnyRef(c, n, tyRef, prev)
      else:
        result = semTypeExpr(c, n)
  of nkWhenStmt:
    var whenResult = semWhen(c, n, false)
    if whenResult.kind == nkStmtList: whenResult.kind = nkStmtListType
    result = semTypeNode(c, whenResult, prev)
  of nkBracketExpr:
    checkMinSonsLen(n, 2)
    var s = semTypeIdent(c, n.sons[0])
    case s.magic
    of mArray: result = semArray(c, n, prev)
    of mOpenArray: result = semContainer(c, n, tyOpenArray, "openarray", prev)
    of mRange: result = semRange(c, n, prev)
    of mSet: result = semSet(c, n, prev)
    of mOrdinal: result = semOrdinal(c, n, prev)
    of mSeq: result = semContainer(c, n, tySequence, "seq", prev)
    of mVarargs: result = semVarargs(c, n, prev)
    of mTypeDesc: result = makeTypeDesc(c, semTypeNode(c, n[1], nil))
    of mExpr:
      result = semTypeNode(c, n.sons[0], nil)
      if result != nil:
        result = copyType(result, getCurrOwner(), false)
        for i in countup(1, n.len - 1):
          result.rawAddSon(semTypeNode(c, n.sons[i], nil))
    else: result = semGeneric(c, n, s, prev)
  of nkDotExpr:
    var typeExpr = semExpr(c, n)
    if typeExpr.typ.kind != tyTypeDesc:
      localError(n.info, errTypeExpected)
      result = errorType(c)
    else:
      result = typeExpr.typ.base
      if result.isMetaType:
        var preprocessed = semGenericStmt(c, n)
        result = makeTypeFromExpr(c, preprocessed.copyTree)
  of nkIdent, nkAccQuoted:
    var s = semTypeIdent(c, n)
    if s.typ == nil:
      if s.kind != skError: localError(n.info, errTypeExpected)
      result = newOrPrevType(tyError, prev, c)
    elif s.kind == skParam and s.typ.kind == tyTypeDesc:
      internalAssert s.typ.base.kind != tyNone and prev == nil
      result = s.typ.base
    elif prev == nil:
      result = s.typ
    else:
      assignType(prev, s.typ)
      # bugfix: keep the fresh id for aliases to integral types:
      if s.typ.kind notin {tyBool, tyChar, tyInt..tyInt64, tyFloat..tyFloat128,
                           tyUInt..tyUInt64}:
        prev.id = s.typ.id
      result = prev
  of nkSym:
    if n.sym.kind == skType and n.sym.typ != nil:
      var t = n.sym.typ
      if prev == nil:
        result = t
      else:
        assignType(prev, t)
        result = prev
      markUsed(n.info, n.sym)
      styleCheckUse(n.info, n.sym)
    else:
      if n.sym.kind != skError: localError(n.info, errTypeExpected)
      result = newOrPrevType(tyError, prev, c)
  of nkObjectTy: result = semObjectNode(c, n, prev)
  of nkTupleTy: result = semTuple(c, n, prev)
  of nkTupleClassTy: result = newConstraint(c, tyTuple)
  of nkTypeClassTy: result = semTypeClass(c, n, prev)
  of nkRefTy: result = semAnyRef(c, n, tyRef, prev)
  of nkPtrTy: result = semAnyRef(c, n, tyPtr, prev)
  of nkVarTy: result = semVarType(c, n, prev)
  of nkDistinctTy: result = semDistinct(c, n, prev)
  of nkStaticTy:
    result = newOrPrevType(tyStatic, prev, c)
    var base = semTypeNode(c, n.sons[0], nil)
    result.rawAddSon(base)
    result.flags.incl tfHasStatic
  of nkIteratorTy:
    if n.sonsLen == 0:
      result = newConstraint(c, tyIter)
    else:
      result = semProcTypeWithScope(c, n, prev, skClosureIterator)
      if n.lastSon.kind == nkPragma and hasPragma(n.lastSon, wInline):
        result.kind = tyIter
        result.callConv = ccInline
      else:
        result.flags.incl(tfIterator)
        result.callConv = ccClosure
  of nkProcTy:
    if n.sonsLen == 0:
      result = newConstraint(c, tyProc)
    else:
      result = semProcTypeWithScope(c, n, prev, skProc)
  of nkEnumTy: result = semEnum(c, n, prev)
  of nkType: result = n.typ
  of nkStmtListType: result = semStmtListType(c, n, prev)
  of nkBlockType: result = semBlockType(c, n, prev)
  of nkSharedTy:
    checkSonsLen(n, 1)
    result = semTypeNode(c, n.sons[0], prev)
    result = freshType(result, prev)
    result.flags.incl(tfShared)
  else:
    localError(n.info, errTypeExpected)
    result = newOrPrevType(tyError, prev, c)
  n.typ = result

proc setMagicType(m: PSym, kind: TTypeKind, size: int) =
  m.typ.kind = kind
  m.typ.align = size.int16
  m.typ.size = size

proc processMagicType(c: PContext, m: PSym) =
  case m.magic
  of mInt: setMagicType(m, tyInt, intSize)
  of mInt8: setMagicType(m, tyInt8, 1)
  of mInt16: setMagicType(m, tyInt16, 2)
  of mInt32: setMagicType(m, tyInt32, 4)
  of mInt64: setMagicType(m, tyInt64, 8)
  of mUInt: setMagicType(m, tyUInt, intSize)
  of mUInt8: setMagicType(m, tyUInt8, 1)
  of mUInt16: setMagicType(m, tyUInt16, 2)
  of mUInt32: setMagicType(m, tyUInt32, 4)
  of mUInt64: setMagicType(m, tyUInt64, 8)
  of mFloat: setMagicType(m, tyFloat, floatSize)
  of mFloat32: setMagicType(m, tyFloat32, 4)
  of mFloat64: setMagicType(m, tyFloat64, 8)
  of mFloat128: setMagicType(m, tyFloat128, 16)
  of mBool: setMagicType(m, tyBool, 1)
  of mChar: setMagicType(m, tyChar, 1)
  of mString:
    setMagicType(m, tyString, ptrSize)
    rawAddSon(m.typ, getSysType(tyChar))
  of mCstring:
    setMagicType(m, tyCString, ptrSize)
    rawAddSon(m.typ, getSysType(tyChar))
  of mPointer: setMagicType(m, tyPointer, ptrSize)
  of mEmptySet:
    setMagicType(m, tySet, 1)
    rawAddSon(m.typ, newTypeS(tyEmpty, c))
  of mIntSetBaseType: setMagicType(m, tyRange, intSize)
  of mNil: setMagicType(m, tyNil, ptrSize)
  of mExpr: setMagicType(m, tyExpr, 0)
  of mStmt: setMagicType(m, tyStmt, 0)
  of mTypeDesc:
    setMagicType(m, tyTypeDesc, 0)
    rawAddSon(m.typ, newTypeS(tyNone, c))
  of mVoidType: setMagicType(m, tyEmpty, 0)
  of mArray:
    setMagicType(m, tyArray, 0)
  of mOpenArray:
    setMagicType(m, tyOpenArray, 0)
  of mVarargs:
    setMagicType(m, tyVarargs, 0)
  of mRange:
    setMagicType(m, tyRange, 0)
    rawAddSon(m.typ, newTypeS(tyNone, c))
  of mSet:
    setMagicType(m, tySet, 0)
  of mSeq:
    setMagicType(m, tySequence, 0)
  of mOrdinal:
    setMagicType(m, tyOrdinal, 0)
    rawAddSon(m.typ, newTypeS(tyNone, c))
  of mPNimrodNode: discard
  of mShared:
    setMagicType(m, tyObject, 0)
    m.typ.n = newNodeI(nkRecList, m.info)
    incl m.typ.flags, tfShared
  of mGuarded:
    setMagicType(m, tyObject, 0)
    m.typ.n = newNodeI(nkRecList, m.info)
    incl m.typ.flags, tfShared
    rawAddSon(m.typ, sysTypeFromName"shared")
  else: localError(m.info, errTypeExpected)

proc semGenericConstraints(c: PContext, x: PType): PType =
  result = newTypeWithSons(c, tyGenericParam, @[x])

proc semGenericParamList(c: PContext, n: PNode, father: PType = nil): PNode =
  result = copyNode(n)
  if n.kind != nkGenericParams:
    illFormedAst(n)
    return
  for i in countup(0, sonsLen(n)-1):
    var a = n.sons[i]
    if a.kind != nkIdentDefs: illFormedAst(n)
    let L = a.len
    var def = a{-1}
    let constraint = a{-2}
    var typ: PType

    if constraint.kind != nkEmpty:
      typ = semTypeNode(c, constraint, nil)
      if typ.kind != tyStatic or typ.len == 0:
        if typ.kind == tyTypeDesc:
          if typ.sons[0].kind == tyNone:
            typ = newTypeWithSons(c, tyTypeDesc, @[newTypeS(tyNone, c)])
        else:
          typ = semGenericConstraints(c, typ)

    if def.kind != nkEmpty:
      def = semConstExpr(c, def)
      if typ == nil:
        if def.typ.kind != tyTypeDesc:
          typ = newTypeWithSons(c, tyStatic, @[def.typ])
      else:
        # the following line fixes ``TV2*[T:SomeNumber=TR] = array[0..1, T]``
        # from manyloc/named_argument_bug/triengine:
        def.typ = def.typ.skipTypes({tyTypeDesc})
        if not containsGenericType(def.typ):
          def = fitNode(c, typ, def)

    if typ == nil:
      typ = newTypeS(tyGenericParam, c)
      if father == nil: typ.flags.incl tfWildcard

    typ.flags.incl tfGenericTypeParam

    for j in countup(0, L-3):
      let finalType = if j == 0: typ
                      else: copyType(typ, typ.owner, false)
                      # it's important the we create an unique
                      # type for each generic param. the index
                      # of the parameter will be stored in the
                      # attached symbol.
      var s = if finalType.kind == tyStatic or tfWildcard in typ.flags:
          newSymG(skGenericParam, a.sons[j], c).linkTo(finalType)
        else:
          newSymG(skType, a.sons[j], c).linkTo(finalType)
      if def.kind != nkEmpty: s.ast = def
      if father != nil: addSonSkipIntLit(father, s.typ)
      s.position = result.len
      addSon(result, newSymNode(s))
      if sfGenSym notin s.flags: addDecl(c, s)

