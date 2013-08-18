#
#
#           The Nimrod Compiler
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
  result = newTypeS(tyTypeClass, c)
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
          if skipTypes(strVal.typ, abstractInst).kind in {tyString, tyCstring}:
            x = getOrdValue(v.sons[0]) # first tuple part is the ordinal
          else:
            LocalError(strVal.info, errStringLiteralExpected)
        else:
          LocalError(v.info, errWrongNumberOfVariables)
      of tyString, tyCstring:
        strVal = v
        x = counter
      else:
        x = getOrdValue(v)
      if i != 1:
        if x != counter: incl(result.flags, tfEnumHasHoles)
        if x < counter: 
          LocalError(n.sons[i].info, errInvalidOrderInEnumX, e.name.s)
          x = counter
      e.ast = strVal # might be nil
      counter = x
    of nkSym: 
      e = n.sons[i].sym
    of nkIdent: 
      e = newSymS(skEnumField, n.sons[i], c)
    else: illFormedAst(n)
    e.typ = result
    e.position = int(counter)
    if e.position == 0: hasNull = true
    if result.sym != nil and sfExported in result.sym.flags:
      incl(e.flags, sfUsed)
      incl(e.flags, sfExported)
      if not isPure: StrTableAdd(c.module.tab, e)
    addSon(result.n, newSymNode(e))
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
        LocalError(n.info, errOrdinalTypeExpected)
      elif lengthOrd(base) > MaxSetElements: 
        LocalError(n.info, errSetTooBig)
  else:
    LocalError(n.info, errXExpectsOneTypeParam, "set")
    addSonSkipIntLit(result, errorType(c))
  
proc semContainer(c: PContext, n: PNode, kind: TTypeKind, kindStr: string, 
                  prev: PType): PType = 
  result = newOrPrevType(kind, prev, c)
  if sonsLen(n) == 2: 
    var base = semTypeNode(c, n.sons[1], nil)
    addSonSkipIntLit(result, base)
  else: 
    LocalError(n.info, errXExpectsOneTypeParam, kindStr)
    addSonSkipIntLit(result, errorType(c))

proc semVarargs(c: PContext, n: PNode, prev: PType): PType =
  result = newOrPrevType(tyVarargs, prev, c)
  if sonsLen(n) == 2 or sonsLen(n) == 3:
    var base = semTypeNode(c, n.sons[1], nil)
    addSonSkipIntLit(result, base)
    if sonsLen(n) == 3:
      result.n = newIdentNode(considerAcc(n.sons[2]), n.sons[2].info)
  else:
    LocalError(n.info, errXExpectsOneTypeParam, "varargs")
    addSonSkipIntLit(result, errorType(c))
  
proc semAnyRef(c: PContext, n: PNode, kind: TTypeKind, prev: PType): PType = 
  if sonsLen(n) == 1:
    result = newOrPrevType(kind, prev, c)
    var base = semTypeNode(c, n.sons[0], nil)
    addSonSkipIntLit(result, base)
  else:
    result = newConstraint(c, kind)
  
proc semVarType(c: PContext, n: PNode, prev: PType): PType = 
  if sonsLen(n) == 1: 
    result = newOrPrevType(tyVar, prev, c)
    var base = semTypeNode(c, n.sons[0], nil)
    if base.kind == tyVar: 
      LocalError(n.info, errVarVarTypeNotAllowed)
      base = base.sons[0]
    addSonSkipIntLit(result, base)
  else:
    result = newConstraint(c, tyVar)
  
proc semDistinct(c: PContext, n: PNode, prev: PType): PType = 
  if sonsLen(n) == 1:
    result = newOrPrevType(tyDistinct, prev, c)
    addSonSkipIntLit(result, semTypeNode(c, n.sons[0], nil))
  else:
    result = newConstraint(c, tyDistinct)
  
proc semRangeAux(c: PContext, n: PNode, prev: PType): PType = 
  assert IsRange(n)
  checkSonsLen(n, 3)
  result = newOrPrevType(tyRange, prev, c)
  result.n = newNodeI(nkRange, n.info)
  if (n[1].kind == nkEmpty) or (n[2].kind == nkEmpty): 
    LocalError(n.Info, errRangeIsEmpty)
  var a = semConstExpr(c, n[1])
  var b = semConstExpr(c, n[2])
  if not sameType(a.typ, b.typ): 
    LocalError(n.info, errPureTypeMismatch)
  elif a.typ.kind notin {tyInt..tyInt64,tyEnum,tyBool,tyChar,
                         tyFloat..tyFloat128,tyUInt8..tyUInt32}:
    LocalError(n.info, errOrdinalTypeExpected)
  elif enumHasHoles(a.typ): 
    LocalError(n.info, errEnumXHasHoles, a.typ.sym.name.s)
  elif not leValue(a, b): LocalError(n.Info, errRangeIsEmpty)
  addSon(result.n, a)
  addSon(result.n, b)
  addSonSkipIntLit(result, b.typ)

proc semRange(c: PContext, n: PNode, prev: PType): PType =
  result = nil
  if sonsLen(n) == 2:
    if isRange(n[1]):
      result = semRangeAux(c, n[1], prev)
      let n = result.n
      if n.sons[0].kind in {nkCharLit..nkUInt64Lit}:
        if n.sons[0].intVal > 0 or n.sons[1].intVal < 0:
          incl(result.flags, tfNeedsInit)
      elif n.sons[0].floatVal > 0.0 or n.sons[1].floatVal < 0.0:
        incl(result.flags, tfNeedsInit)
    else:
      LocalError(n.sons[0].info, errRangeExpected)
      result = newOrPrevType(tyError, prev, c)
  else:
    LocalError(n.info, errXExpectsOneTypeParam, "range")
    result = newOrPrevType(tyError, prev, c)

proc semArray(c: PContext, n: PNode, prev: PType): PType = 
  var indx, base: PType
  result = newOrPrevType(tyArray, prev, c)
  if sonsLen(n) == 3: 
    # 3 = length(array indx base)
    if isRange(n[1]): indx = semRangeAux(c, n[1], nil)
    else:
      let e = semExprWithType(c, n.sons[1], {efDetermineType})
      if e.kind in {nkIntLit..nkUInt64Lit}:
        indx = newTypeS(tyRange, c)
        indx.n = newNodeI(nkRange, n.info)
        addSon(indx.n, newIntTypeNode(e.kind, 0, e.typ))
        addSon(indx.n, newIntTypeNode(e.kind, e.intVal-1, e.typ))
        addSonSkipIntLit(indx, e.typ)
      else:
        indx = e.typ.skipTypes({tyTypeDesc})
    addSonSkipIntLit(result, indx)
    if indx.kind == tyGenericInst: indx = lastSon(indx)
    if indx.kind != tyGenericParam: 
      if not isOrdinalType(indx): 
        LocalError(n.sons[1].info, errOrdinalTypeExpected)
      elif enumHasHoles(indx): 
        LocalError(n.sons[1].info, errEnumXHasHoles, indx.sym.name.s)
    base = semTypeNode(c, n.sons[2], nil)
    addSonSkipIntLit(result, base)
  else: 
    LocalError(n.info, errArrayExpectsTwoTypeParams)
    result = newOrPrevType(tyError, prev, c)
  
proc semOrdinal(c: PContext, n: PNode, prev: PType): PType = 
  result = newOrPrevType(tyOrdinal, prev, c)
  if sonsLen(n) == 2: 
    var base = semTypeNode(c, n.sons[1], nil)
    if base.kind != tyGenericParam: 
      if not isOrdinalType(base): 
        LocalError(n.sons[1].info, errOrdinalTypeExpected)
    addSonSkipIntLit(result, base)
  else:
    LocalError(n.info, errXExpectsOneTypeParam, "ordinal")
    result = newOrPrevType(tyError, prev, c)

proc semTypeIdent(c: PContext, n: PNode): PSym =
  if n.kind == nkSym: 
    result = n.sym
  else:
    result = qualifiedLookup(c, n, {checkAmbiguity, checkUndeclared})
    if result != nil:
      markUsed(n, result)
      if result.kind == skParam and result.typ.kind == tyTypeDesc:
        # This is a typedesc param. is it already bound?
        # it's not bound when it's also used as return type for example
        if result.typ.sonsLen > 0:
          let bound = result.typ.sons[0].sym
          if bound != nil:
            return bound
          return result
        if result.typ.sym == nil:
          LocalError(n.info, errTypeExpected)
          return errorSym(c, n)
        result = result.typ.sym.copySym
        result.typ = copyType(result.typ, result.typ.owner, true)
        result.typ.flags.incl tfUnresolved
      if result.kind != skType: 
        # this implements the wanted ``var v: V, x: V`` feature ...
        var ov: TOverloadIter
        var amb = InitOverloadIter(ov, c, n)
        while amb != nil and amb.kind != skType:
          amb = nextOverloadIter(ov, c, n)
        if amb != nil: result = amb
        else:
          if result.kind != skError: LocalError(n.info, errTypeExpected)
          return errorSym(c, n)
      if result.typ.kind != tyGenericParam:
        # XXX get rid of this hack!
        var oldInfo = n.info
        reset(n[])
        n.kind = nkSym
        n.sym = result
        n.info = oldInfo
    else:
      LocalError(n.info, errIdentifierExpected)
      result = errorSym(c, n)
  
proc semTuple(c: PContext, n: PNode, prev: PType): PType = 
  if n.sonsLen == 0: return newConstraint(c, tyTuple)
  var typ: PType
  result = newOrPrevType(tyTuple, prev, c)
  result.n = newNodeI(nkRecList, n.info)
  var check = initIntSet()
  var counter = 0
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if (a.kind != nkIdentDefs): IllFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    if a.sons[length - 2].kind != nkEmpty: 
      typ = semTypeNode(c, a.sons[length - 2], nil)
    else:
      LocalError(a.info, errTypeExpected)
      typ = errorType(c)
    if a.sons[length - 1].kind != nkEmpty: 
      LocalError(a.sons[length - 1].info, errInitHereNotAllowed)
    for j in countup(0, length - 3): 
      var field = newSymG(skField, a.sons[j], c)
      field.typ = typ
      field.position = counter
      inc(counter)
      if ContainsOrIncl(check, field.name.id): 
        LocalError(a.sons[j].info, errAttemptToRedefine, field.name.s)
      else:
        addSon(result.n, newSymNode(field))
        addSonSkipIntLit(result, typ)

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
        LocalError(n.sons[0].info, errInvalidVisibilityX, v.s)
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
    of skField: pragma(c, result, n.sons[1], fieldPragmas)
    of skVar:   pragma(c, result, n.sons[1], varPragmas)
    of skLet:   pragma(c, result, n.sons[1], letPragmas)
    of skConst: pragma(c, result, n.sons[1], constPragmas)
    else: nil
  else:
    result = semIdentVis(c, kind, n, allowed)
  
proc checkForOverlap(c: PContext, t: PNode, currentEx, branchIndex: int) =
  let ex = t[branchIndex][currentEx].skipConv
  for i in countup(1, branchIndex):
    for j in countup(0, sonsLen(t.sons[i]) - 2): 
      if i == branchIndex and j == currentEx: break
      if overlap(t.sons[i].sons[j].skipConv, ex):
        LocalError(ex.info, errDuplicateCaseLabel)
  
proc semBranchRange(c: PContext, t, a, b: PNode, covered: var biggestInt): PNode =
  checkMinSonsLen(t, 1)
  let ac = semConstExpr(c, a)
  let bc = semConstExpr(c, b)
  let at = fitNode(c, t.sons[0].typ, ac).skipConvTakeType
  let bt = fitNode(c, t.sons[0].typ, bc).skipConvTakeType
  
  result = newNodeI(nkRange, a.info)
  result.add(at)
  result.add(bt)
  if emptyRange(ac, bc): LocalError(b.info, errRangeIsEmpty)
  else: covered = covered + getOrdValue(bc) - getOrdValue(ac) + 1

proc SemCaseBranchRange(c: PContext, t, b: PNode, 
                        covered: var biggestInt): PNode = 
  checkSonsLen(b, 3)
  result = semBranchRange(c, t, b.sons[1], b.sons[2], covered)

proc semCaseBranchSetElem(c: PContext, t, b: PNode, 
                          covered: var biggestInt): PNode = 
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
                   covered: var biggestInt) = 
  for i in countup(0, sonsLen(branch) - 2): 
    var b = branch.sons[i]
    if b.kind == nkRange:
      branch.sons[i] = b
    elif isRange(b):
      branch.sons[i] = semCaseBranchRange(c, t, b, covered)
    else:
      var r = semConstExpr(c, b)
      # for ``{}`` we want to trigger the type mismatch in ``fitNode``:
      if r.kind != nkCurly or len(r) == 0:
        checkMinSonsLen(t, 1)
        branch.sons[i] = fitNode(c, t.sons[0].typ, r)
        inc(covered)
      else:
        # constant sets have special rules
        # first element is special and will overwrite: branch.sons[i]:
        branch.sons[i] = semCaseBranchSetElem(c, t, r[0], covered)
        # other elements have to be added to ``branch``
        for j in 1 .. <r.len:
          branch.add(semCaseBranchSetElem(c, t, r[j], covered))
          # caution! last son of branch must be the actions to execute:
          var L = branch.len
          swap(branch.sons[L-2], branch.sons[L-1])
    checkForOverlap(c, t, i, branchIndex)
    
proc semRecordNodeAux(c: PContext, n: PNode, check: var TIntSet, pos: var int,
                      father: PNode, rectype: PType)
proc semRecordCase(c: PContext, n: PNode, check: var TIntSet, pos: var int,
                   father: PNode, rectype: PType) =
  var a = copyNode(n)
  checkMinSonsLen(n, 2)
  semRecordNodeAux(c, n.sons[0], check, pos, a, rectype)
  if a.sons[0].kind != nkSym:
    internalError("semRecordCase: discriminant is no symbol")
    return
  incl(a.sons[0].sym.flags, sfDiscriminant)
  var covered: biggestInt = 0
  var typ = skipTypes(a.sons[0].Typ, abstractVar-{tyTypeDesc})
  if not isOrdinalType(typ):
    LocalError(n.info, errSelectorMustBeOrdinal)
  elif firstOrd(typ) < 0:
    LocalError(n.info, errOrdXMustNotBeNegative, a.sons[0].sym.name.s)
  elif lengthOrd(typ) > 0x00007FFF:
    LocalError(n.info, errLenXinvalid, a.sons[0].sym.name.s)
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

proc semRecordNodeAux(c: PContext, n: PNode, check: var TIntSet, pos: var int, 
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
        if c.InGenericContext == 0:
          var e = semConstBoolExpr(c, it.sons[0])
          if e.kind != nkIntLit: InternalError(e.info, "semRecordNodeAux")
          elif e.intVal != 0 and branch == nil: branch = it.sons[1]
        else:
          it.sons[0] = forceBool(c, semExprWithType(c, it.sons[0]))
      of nkElse:
        checkSonsLen(it, 1)
        if branch == nil: branch = it.sons[0]
        idx = 0
      else: illFormedAst(n)
      if c.InGenericContext > 0:
        # use a new check intset here for each branch:
        var newCheck: TIntSet
        assign(newCheck, check)
        var newPos = pos
        var newf = newNodeI(nkRecList, n.info)
        semRecordNodeAux(c, it.sons[idx], newcheck, newpos, newf, rectype)
        it.sons[idx] = if newf.len == 1: newf[0] else: newf
    if c.InGenericContext > 0:
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
      LocalError(n.info, errTypeExpected)
      typ = errorType(c)
    else:
      typ = semTypeNode(c, n.sons[length-2], nil)
      propagateToOwner(rectype, typ)
    let rec = rectype.sym
    for i in countup(0, sonsLen(n)-3):
      var f = semIdentWithPragma(c, skField, n.sons[i], {sfExported})
      suggestSym(n.sons[i], f)
      f.typ = typ
      f.position = pos
      if (rec != nil) and ({sfImportc, sfExportc} * rec.flags != {}) and
          (f.loc.r == nil): 
        f.loc.r = toRope(f.name.s)
        f.flags = f.flags + ({sfImportc, sfExportc} * rec.flags)
      inc(pos)
      if ContainsOrIncl(check, f.name.id):
        localError(n.sons[i].info, errAttemptToRedefine, f.name.s)
      if a.kind == nkEmpty: addSon(father, newSymNode(f))
      else: addSon(a, newSymNode(f))
    if a.kind != nkEmpty: addSon(father, a)
  of nkEmpty: nil
  else: illFormedAst(n)
  
proc addInheritedFieldsAux(c: PContext, check: var TIntSet, pos: var int, 
                           n: PNode) =
  case n.kind
  of nkRecCase:
    if (n.sons[0].kind != nkSym): InternalError(n.info, "addInheritedFieldsAux")
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
    Incl(check, n.sym.name.id)
    inc(pos)
  else: InternalError(n.info, "addInheritedFieldsAux()")
  
proc addInheritedFields(c: PContext, check: var TIntSet, pos: var int, 
                        obj: PType) = 
  if (sonsLen(obj) > 0) and (obj.sons[0] != nil): 
    addInheritedFields(c, check, pos, obj.sons[0])
  addInheritedFieldsAux(c, check, pos, obj.n)

proc skipGenericInvokation(t: PType): PType {.inline.} = 
  result = t
  if result.kind == tyGenericInvokation:
    result = result.sons[0]
  if result.kind == tyGenericBody:
    result = lastSon(result)

proc semObjectNode(c: PContext, n: PNode, prev: PType): PType =
  if n.sonsLen == 0: return newConstraint(c, tyObject)
  var check = initIntSet()
  var pos = 0 
  var base: PType = nil
  # n.sons[0] contains the pragmas (if any). We process these later...
  checkSonsLen(n, 3)
  if n.sons[1].kind != nkEmpty: 
    base = skipTypes(semTypeNode(c, n.sons[1].sons[0], nil), skipPtrs)
    var concreteBase = skipGenericInvokation(base)
    if concreteBase.kind == tyObject and tfFinal notin concreteBase.flags: 
      addInheritedFields(c, check, pos, concreteBase)
    else:
      if concreteBase.kind != tyError:
        localError(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects)
      base = nil
  if n.kind != nkObjectTy: InternalError(n.info, "semObjectNode")
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
  
proc addParamOrResult(c: PContext, param: PSym, kind: TSymKind) =
  if kind == skMacro and param.typ.kind != tyTypeDesc:
    # within a macro, every param has the type PNimrodNode!
    # and param.typ.kind in {tyTypeDesc, tyExpr, tyStmt}:
    let nn = getSysSym"PNimrodNode"
    var a = copySym(param)
    a.typ = nn.typ
    if sfGenSym notin a.flags: addDecl(c, a)
  else:
    if sfGenSym notin param.flags: addDecl(c, param)

proc liftParamType(c: PContext, procKind: TSymKind, genericParams: PNode,
                   paramType: PType, paramName: string,
                   info: TLineInfo, anon = false): PType =
  if procKind in {skMacro, skTemplate}:
    # generic param types in macros and templates affect overload
    # resolution, but don't work as generic params when it comes
    # to proc instantiation. We don't need to lift such params here.  
    return

  proc addImplicitGenericImpl(typeClass: PType, typId: PIdent): PType =
    let finalTypId = if typId != nil: typId
                     else: getIdent(paramName & ":type")
    # is this a bindOnce type class already present in the param list?
    for i in countup(0, genericParams.len - 1):
      if genericParams.sons[i].sym.name.id == finalTypId.id:
        return genericParams.sons[i].typ

    var s = newSym(skType, finalTypId, getCurrOwner(), info)
    if typId == nil: s.flags.incl(sfAnon)
    s.linkTo(typeClass)
    s.position = genericParams.len
    genericParams.addSon(newSymNode(s))
    result = typeClass

  # XXX: There are codegen errors if this is turned into a nested proc
  template liftingWalk(typ: PType, anonFlag = false): expr =
    liftParamType(c, procKind, genericParams, typ, paramName, info, anonFlag)
  #proc liftingWalk(paramType: PType, anon = false): PType =

  var paramTypId = if not anon and paramType.sym != nil: paramType.sym.name
                   else: nil

  template addImplicitGeneric(e: expr): expr =
    addImplicitGenericImpl(e, paramTypId)

  case paramType.kind:
  of tyExpr:
    if paramType.sonsLen == 0:
      # proc(a, b: expr)
      # no constraints, treat like generic param
      result = addImplicitGeneric(newTypeS(tyGenericParam, c))
    else:
      # proc(a: expr{string}, b: expr{nkLambda})
      # overload on compile time values and AST trees
      result = addImplicitGeneric(c.newTypeWithSons(tyExpr, paramType.sons))
  of tyTypeDesc:
    if tfUnresolved notin paramType.flags:
      result = addImplicitGeneric(c.newTypeWithSons(tyTypeDesc, paramType.sons))
  of tyDistinct:
    if paramType.sonsLen == 1:
      # disable the bindOnce behavior for the type class
      result = liftingWalk(paramType.sons[0], true)
  of tySequence, tySet, tyArray, tyOpenArray:
    # XXX: this is a bit strange, but proc(s: seq)
    # produces tySequence(tyGenericParam, null).
    # This also seems to be true when creating aliases
    # like: type myseq = distinct seq.
    # Maybe there is another better place to associate
    # the seq type class with the seq identifier.
    if paramType.lastSon == nil:
      let typ = c.newTypeWithSons(tyTypeClass, @[newTypeS(paramType.kind, c)])
      result = addImplicitGeneric(typ)
    else:
      for i in 0 .. <paramType.sons.len:
        var lifted = liftingWalk(paramType.sons[i])
        if lifted != nil:
          paramType.sons[i] = lifted
          result = paramType
  of tyGenericBody:
    # type Foo[T] = object
    # proc x(a: Foo, b: Foo) 
    var typ = newTypeS(tyTypeClass, c)
    typ.addSonSkipIntLit(paramType)
    result = addImplicitGeneric(typ)
  of tyGenericInst:
    for i in 1 .. (paramType.sons.len - 2):
      var lifted = liftingWalk(paramType.sons[i])
      if lifted != nil:
        paramType.sons[i] = lifted
        result = paramType
    
    if result != nil:
      result.kind = tyGenericInvokation
      result.sons.setLen(result.sons.len - 1)
  of tyTypeClass:
    result = addImplicitGeneric(copyType(paramType, getCurrOwner(), false))
  else: nil

  # result = liftingWalk(paramType)

proc semParamType(c: PContext, n: PNode, constraint: var PNode): PType =
  if n.kind == nkCurlyExpr:
    result = semTypeNode(c, n.sons[0], nil)
    constraint = semNodeKindConstraints(n)
  else:
    result = semTypeNode(c, n, nil)

proc semProcTypeNode(c: PContext, n, genericParams: PNode, 
                     prev: PType, kind: TSymKind): PType = 
  var
    res: PNode
    cl: TIntSet
  checkMinSonsLen(n, 1)
  result = newOrPrevType(tyProc, prev, c)
  result.callConv = lastOptionEntry(c).defaultCC
  result.n = newNodeI(nkFormalParams, n.info)
  if genericParams != nil and sonsLen(genericParams) == 0:
    cl = initIntSet()
  rawAddSon(result, nil) # return type
  # result.n[0] used to be `nkType`, but now it's `nkEffectList` because 
  # the effects are now stored in there too ... this is a bit hacky, but as
  # usual we desperately try to save memory:
  res = newNodeI(nkEffectList, n.info)
  addSon(result.n, res)
  var check = initIntSet()
  var counter = 0
  for i in countup(1, n.len - 1):
    var a = n.sons[i]
    if a.kind != nkIdentDefs: IllFormedAst(a)
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
      # check type compability between def.typ and typ:
      if typ == nil:
        typ = def.typ
      elif def != nil:
        # and def.typ != nil and def.typ.kind != tyNone:
        # example code that triggers it:
        # proc sort[T](cmp: proc(a, b: T): int = cmp)
        if not containsGenericType(typ):
          def = fitNode(c, typ, def)
    if not (hasType or hasDefault):
      typ = newTypeS(tyExpr, c)
      
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
      if ContainsOrIncl(check, arg.name.id): 
        LocalError(a.sons[j].info, errAttemptToRedefine, arg.name.s)
      addSon(result.n, newSymNode(arg))
      rawAddSon(result, finalType)
      addParamOrResult(c, arg, kind)

  if n.sons[0].kind != nkEmpty:
    var r = semTypeNode(c, n.sons[0], nil)
    # turn explicit 'void' return type into 'nil' because the rest of the 
    # compiler only checks for 'nil':
    if skipTypes(r, {tyGenericInst}).kind != tyEmpty:
      if r.sym == nil or sfAnon notin r.sym.flags:
        let lifted = liftParamType(c, kind, genericParams, r, "result",
                                   n.sons[0].info)
        if lifted != nil: r = lifted
        r.flags.incl tfRetType
      result.sons[0] = skipIntLit(r)
      res.typ = result.sons[0]
 
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
  Inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2)
  openScope(c)
  if n.sons[0].kind notin {nkEmpty, nkSym}:
    addDecl(c, newSymS(skLabel, n.sons[0], c))
  result = semStmtListType(c, n.sons[1], prev)
  n.sons[1].typ = result
  n.typ = result
  closeScope(c)
  Dec(c.p.nestedBlockCounter)

proc semGenericParamInInvokation(c: PContext, n: PNode): PType =
  # XXX hack 1022 for generics ... would have been nice if the compiler had
  # been designed with them in mind from start ...
  when false:
    if n.kind == nkSym:
      # for generics we need to lookup the type var again:
      var s = searchInScopes(c, n.sym.name)
      if s != nil:
        if s.kind == skType and s.typ != nil:
          var t = n.sym.typ
          echo "came here"
          return t
        else:
          echo "s is crap:"
          debug(s)
      else:
        echo "s is nil!!!!"
  result = semTypeNode(c, n, nil)

proc semGeneric(c: PContext, n: PNode, s: PSym, prev: PType): PType = 
  result = newOrPrevType(tyGenericInvokation, prev, c)
  addSonSkipIntLit(result, s.typ)
  
  template addToResult(typ) =
    if typ.isNil:
      InternalAssert false
      rawAddSon(result, typ)
    else: addSonSkipIntLit(result, typ)

  if s.typ == nil:
    LocalError(n.info, errCannotInstantiateX, s.name.s)
    return newOrPrevType(tyError, prev, c)
  elif s.typ.kind == tyForward:
    for i in countup(1, sonsLen(n)-1):
      var elem = semGenericParamInInvokation(c, n.sons[i])
      addToResult(elem)
  else:
    internalAssert s.typ.kind == tyGenericBody

    var m = newCandidate(s, n)
    matches(c, n, copyTree(n), m)
    
    if m.state != csMatch:
      LocalError(n.info, errWrongNumberOfArguments)
      return newOrPrevType(tyError, prev, c)

    var isConcrete = true
  
    for i in 1 .. <m.call.len:
      let typ = m.call[i].typ.skipTypes({tyTypeDesc})
      if containsGenericType(typ): isConcrete = false
      addToResult(typ)
    
    if isConcrete:
      if s.ast == nil:
        LocalError(n.info, errCannotInstantiateX, s.name.s)
        result = newOrPrevType(tyError, prev, c)
      else:
        result = instGenericContainer(c, n, result)

proc semTypeExpr(c: PContext, n: PNode): PType =
  var n = semExprWithType(c, n, {efDetermineType})
  if n.kind == nkSym and n.sym.kind == skType:
    result = n.sym.typ
  else:
    LocalError(n.info, errTypeExpected, n.renderTree)

proc freshType(res, prev: PType): PType {.inline.} =
  if prev.isNil:
    result = copyType(res, res.owner, keepId=false)
  else:
    result = res

proc semTypeNode(c: PContext, n: PNode, prev: PType): PType =
  result = nil
  if gCmd == cmdIdeTools: suggestExpr(c, n)
  case n.kind
  of nkEmpty: nil
  of nkTypeOfExpr:
    # for ``type(countup(1,3))``, see ``tests/ttoseq``.
    checkSonsLen(n, 1)
    result = semExprWithType(c, n.sons[0], {efInTypeof}).typ
  of nkPar: 
    if sonsLen(n) == 1: result = semTypeNode(c, n.sons[0], prev)
    else:
      # XXX support anon tuple here
      LocalError(n.info, errTypeExpected)
      result = newOrPrevType(tyError, prev, c)
  of nkCallKinds:
    if isRange(n):
      result = semRangeAux(c, n, prev)
    elif n[0].kind == nkIdent:
      let op = n.sons[0].ident
      if op.id in {ord(wAnd), ord(wOr)} or op.s == "|":
        checkSonsLen(n, 3)
        var
          t1 = semTypeNode(c, n.sons[1], nil)
          t2 = semTypeNode(c, n.sons[2], nil)
        if t1 == nil: 
          LocalError(n.sons[1].info, errTypeExpected)
          result = newOrPrevType(tyError, prev, c)
        elif t2 == nil: 
          LocalError(n.sons[2].info, errTypeExpected)
          result = newOrPrevType(tyError, prev, c)
        else:
          result = newTypeS(tyTypeClass, c)
          result.addSonSkipIntLit(t1)
          result.addSonSkipIntLit(t2)
          result.flags.incl(if op.id == ord(wAnd): tfAll else: tfAny)
      elif op.id == ord(wNot):
        checkSonsLen(n, 3)
        result = semTypeNode(c, n.sons[1], prev)
        if result.kind in NilableTypes and n.sons[2].kind == nkNilLit:
          result = freshType(result, prev)
          result.flags.incl(tfNotNil)
        else:
          LocalError(n.info, errGenerated, "invalid type")
      else:
        result = semTypeExpr(c, n)
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
    of mExpr, mTypeDesc:
      result = semTypeNode(c, n.sons[0], nil)
      if result != nil:
        result = copyType(result, getCurrOwner(), false)
        for i in countup(1, n.len - 1):
          result.rawAddSon(semTypeNode(c, n.sons[i], nil))
    else: result = semGeneric(c, n, s, prev)
  of nkIdent, nkDotExpr, nkAccQuoted: 
    var s = semTypeIdent(c, n)
    if s.typ == nil: 
      if s.kind != skError: LocalError(n.info, errTypeExpected)
      result = newOrPrevType(tyError, prev, c)
    elif s.kind == skParam and s.typ.kind == tyTypeDesc:
      assert s.typ.len > 0
      InternalAssert prev == nil
      result = s.typ.sons[0]
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
      markUsed(n, n.sym)
    else:
      if n.sym.kind != skError: LocalError(n.info, errTypeExpected)
      result = newOrPrevType(tyError, prev, c)
  of nkObjectTy: result = semObjectNode(c, n, prev)
  of nkTupleTy: result = semTuple(c, n, prev)
  of nkRefTy: result = semAnyRef(c, n, tyRef, prev)
  of nkPtrTy: result = semAnyRef(c, n, tyPtr, prev)
  of nkVarTy: result = semVarType(c, n, prev)
  of nkDistinctTy: result = semDistinct(c, n, prev)
  of nkProcTy, nkIteratorTy:
    if n.sonsLen == 0:
      result = newConstraint(c, tyProc)
    else:
      checkSonsLen(n, 2)
      openScope(c)
      result = semProcTypeNode(c, n.sons[0], nil, prev, skProc)
      # dummy symbol for `pragma`:
      var s = newSymS(skProc, newIdentNode(getIdent("dummy"), n.info), c)
      s.typ = result
      if n.sons[1].kind == nkEmpty or n.sons[1].len == 0:
        if result.callConv == ccDefault:
          result.callConv = ccClosure
          #Message(n.info, warnImplicitClosure, renderTree(n))
      else:
        pragma(c, s, n.sons[1], procTypePragmas)
        when useEffectSystem: SetEffectsForProcType(result, n.sons[1])
      closeScope(c)
    if n.kind == nkIteratorTy:
      result.flags.incl(tfIterator)
      result.callConv = ccClosure
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
    LocalError(n.info, errTypeExpected)
    result = newOrPrevType(tyError, prev, c)
  
proc setMagicType(m: PSym, kind: TTypeKind, size: int) = 
  m.typ.kind = kind
  m.typ.align = size
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
  of mTypeDesc: setMagicType(m, tyTypeDesc, 0)
  of mVoidType: setMagicType(m, tyEmpty, 0)
  of mArray: setMagicType(m, tyArray, 0)
  of mOpenArray: setMagicType(m, tyOpenArray, 0)
  of mVarargs: setMagicType(m, tyVarargs, 0)
  of mRange: setMagicType(m, tyRange, 0)
  of mSet: setMagicType(m, tySet, 0) 
  of mSeq: setMagicType(m, tySequence, 0)
  of mOrdinal: setMagicType(m, tyOrdinal, 0)
  of mPNimrodNode: nil
  else: LocalError(m.info, errTypeExpected)
  
proc semGenericConstraints(c: PContext, x: PType): PType =
  if x.kind in StructuralEquivTypes and (
      sonsLen(x) == 0 or x.sons[0].kind in {tyGenericParam, tyEmpty}):
    result = newConstraint(c, x.kind)
  else:
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
      if typ.kind != tyExpr or typ.len == 0:
        if typ.len == 0 and typ.kind == tyTypeDesc:
          typ = newTypeS(tyGenericParam, c)
        else:
          typ = semGenericConstraints(c, typ)
    
    if def.kind != nkEmpty:
      def = semConstExpr(c, def)
      if typ == nil:
        if def.typ.kind != tyTypeDesc:
          typ = newTypeWithSons(c, tyExpr, @[def.typ])
      else:
        if not containsGenericType(def.typ):
          def = fitNode(c, typ, def)
    
    if typ == nil:
      typ = newTypeS(tyGenericParam, c)
    
    for j in countup(0, L-3):
      let finalType = if j == 0: typ
                      else: copyType(typ, typ.owner, false)
                      # it's important the we create an unique
                      # type for each generic param. the index
                      # of the parameter will be stored in the
                      # attached symbol.
      var s = case finalType.kind
        of tyExpr:
          newSymG(skGenericParam, a.sons[j], c).linkTo(finalType)
        else:
          newSymG(skType, a.sons[j], c).linkTo(finalType)
      if def.kind != nkEmpty: s.ast = def
      if father != nil: addSonSkipIntLit(father, s.typ)
      s.position = result.len
      addSon(result, newSymNode(s))
      if sfGenSym notin s.flags: addDecl(c, s)

