#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking of type declarations

proc newOrPrevType(kind: TTypeKind, prev: PType, c: PContext): PType = 
  if prev == nil: 
    result = newTypeS(kind, c)
  else: 
    result = prev
    if result.kind == tyForward: result.kind = kind
  
proc semEnum(c: PContext, n: PNode, prev: PType): PType = 
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
  addSon(result, base)
  for i in countup(1, sonsLen(n) - 1): 
    case n.sons[i].kind
    of nkEnumFieldDef: 
      e = newSymS(skEnumField, n.sons[i].sons[0], c)
      var v = semConstExpr(c, n.sons[i].sons[1])
      var strVal: PNode = nil
      case skipTypes(v.typ, abstractInst).kind 
      of tyTuple: 
        if sonsLen(v) != 2: GlobalError(v.info, errWrongNumberOfVariables)
        strVal = v.sons[1] # second tuple part is the string value
        if skipTypes(strVal.typ, abstractInst).kind notin {tyString, tyCstring}:
          GlobalError(strVal.info, errStringLiteralExpected)
        x = getOrdValue(v.sons[0]) # first tuple part is the ordinal
      of tyString, tyCstring:
        strVal = v
        x = counter
      else:
        x = getOrdValue(v)
      if i != 1:
        if x != counter: incl(result.flags, tfEnumHasHoles)
        if x < counter: 
          GlobalError(n.sons[i].info, errInvalidOrderInEnumX, e.name.s)
      e.ast = strVal # might be nil
      counter = x
    of nkSym: 
      e = n.sons[i].sym
    of nkIdent: 
      e = newSymS(skEnumField, n.sons[i], c)
    else: illFormedAst(n)
    e.typ = result
    e.position = int(counter)
    if result.sym != nil and sfExported in result.sym.flags: 
      incl(e.flags, sfUsed)   # BUGFIX
      incl(e.flags, sfExported) # BUGFIX
      StrTableAdd(c.module.tab, e) # BUGFIX
    addSon(result.n, newSymNode(e))
    addDeclAt(c, e, c.tab.tos - 1)
    inc(counter)

proc semSet(c: PContext, n: PNode, prev: PType): PType = 
  result = newOrPrevType(tySet, prev, c)
  if sonsLen(n) == 2: 
    var base = semTypeNode(c, n.sons[1], nil)
    addSon(result, base)
    if base.kind == tyGenericInst: base = lastSon(base)
    if base.kind != tyGenericParam: 
      if not isOrdinalType(base): GlobalError(n.info, errOrdinalTypeExpected)
      if lengthOrd(base) > MaxSetElements: GlobalError(n.info, errSetTooBig)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, "set")
  
proc semContainer(c: PContext, n: PNode, kind: TTypeKind, kindStr: string, 
                  prev: PType): PType = 
  result = newOrPrevType(kind, prev, c)
  if sonsLen(n) == 2: 
    var base = semTypeNode(c, n.sons[1], nil)
    addSon(result, base)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, kindStr)
  
proc semAnyRef(c: PContext, n: PNode, kind: TTypeKind, kindStr: string, 
               prev: PType): PType = 
  result = newOrPrevType(kind, prev, c)
  if sonsLen(n) == 1: 
    var base = semTypeNode(c, n.sons[0], nil)
    addSon(result, base)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, kindStr)
  
proc semVarType(c: PContext, n: PNode, prev: PType): PType = 
  result = newOrPrevType(tyVar, prev, c)
  if sonsLen(n) == 1: 
    var base = semTypeNode(c, n.sons[0], nil)
    if base.kind == tyVar: GlobalError(n.info, errVarVarTypeNotAllowed)
    addSon(result, base)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, "var")
  
proc semDistinct(c: PContext, n: PNode, prev: PType): PType = 
  result = newOrPrevType(tyDistinct, prev, c)
  if sonsLen(n) == 1: addSon(result, semTypeNode(c, n.sons[0], nil))
  else: GlobalError(n.info, errXExpectsOneTypeParam, "distinct")
  
proc semRangeAux(c: PContext, n: PNode, prev: PType): PType = 
  assert IsRange(n)
  checkSonsLen(n, 3)
  result = newOrPrevType(tyRange, prev, c)
  result.n = newNodeI(nkRange, n.info)
  if (n[1].kind == nkEmpty) or (n[2].kind == nkEmpty): 
    GlobalError(n.Info, errRangeIsEmpty)
  var a = semConstExpr(c, n[1])
  var b = semConstExpr(c, n[2])
  if not sameType(a.typ, b.typ): GlobalError(n.info, errPureTypeMismatch)
  if not (a.typ.kind in
      {tyInt..tyInt64, tyEnum, tyBool, tyChar, tyFloat..tyFloat128}): 
    GlobalError(n.info, errOrdinalTypeExpected)
  if enumHasHoles(a.typ): 
    GlobalError(n.info, errEnumXHasHoles, a.typ.sym.name.s)
  if not leValue(a, b): GlobalError(n.Info, errRangeIsEmpty)
  addSon(result.n, a)
  addSon(result.n, b)
  addSon(result, b.typ)

proc semRange(c: PContext, n: PNode, prev: PType): PType = 
  result = nil
  if sonsLen(n) == 2: 
    if isRange(n[1]): result = semRangeAux(c, n[1], prev)
    else: GlobalError(n.sons[0].info, errRangeExpected)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, "range")
  
proc semArray(c: PContext, n: PNode, prev: PType): PType = 
  var indx, base: PType
  result = newOrPrevType(tyArray, prev, c)
  if sonsLen(n) == 3: 
    # 3 = length(array indx base)
    if isRange(n[1]): indx = semRangeAux(c, n[1], nil)
    else: indx = semTypeNode(c, n.sons[1], nil)
    addSon(result, indx)
    if indx.kind == tyGenericInst: indx = lastSon(indx)
    if indx.kind != tyGenericParam: 
      if not isOrdinalType(indx): 
        GlobalError(n.sons[1].info, errOrdinalTypeExpected)
      if enumHasHoles(indx): 
        GlobalError(n.sons[1].info, errEnumXHasHoles, indx.sym.name.s)
    base = semTypeNode(c, n.sons[2], nil)
    addSon(result, base)
  else: 
    GlobalError(n.info, errArrayExpectsTwoTypeParams)
  
proc semOrdinal(c: PContext, n: PNode, prev: PType): PType = 
  result = newOrPrevType(tyOrdinal, prev, c)
  if sonsLen(n) == 2: 
    var base = semTypeNode(c, n.sons[1], nil)
    if base.kind != tyGenericParam: 
      if not isOrdinalType(base): 
        GlobalError(n.sons[1].info, errOrdinalTypeExpected)
    addSon(result, base)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, "ordinal")
  
proc semTypeIdent(c: PContext, n: PNode): PSym =
  if n.kind == nkSym: 
    result = n.sym
  else:
    result = qualifiedLookup(c, n, {checkAmbiguity, checkUndeclared})
    if result != nil:
      markUsed(n, result)
      if result.kind != skType: GlobalError(n.info, errTypeExpected)
      if result.typ.kind != tyGenericParam:
        # XXX get rid of this hack!
        reset(n[])
        n.kind = nkSym
        n.sym = result
    else:
      GlobalError(n.info, errIdentifierExpected)
  
proc semTuple(c: PContext, n: PNode, prev: PType): PType = 
  var 
    typ: PType
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
    else: GlobalError(a.info, errTypeExpected)
    if a.sons[length - 1].kind != nkEmpty: 
      GlobalError(a.sons[length - 1].info, errInitHereNotAllowed)
    for j in countup(0, length - 3): 
      var field = newSymS(skField, a.sons[j], c)
      field.typ = typ
      field.position = counter
      inc(counter)
      if ContainsOrIncl(check, field.name.id): 
        GlobalError(a.sons[j].info, errAttemptToRedefine, field.name.s)
      addSon(result.n, newSymNode(field))
      addSon(result, typ)

proc semIdentVis(c: PContext, kind: TSymKind, n: PNode, 
                 allowed: TSymFlags): PSym = 
  # identifier with visibility
  if n.kind == nkPostfix: 
    if sonsLen(n) == 2 and n.sons[0].kind == nkIdent: 
      result = newSymS(kind, n.sons[1], c)
      var v = n.sons[0].ident
      if sfExported in allowed and v.id == ord(wStar): 
        incl(result.flags, sfExported)
      else:
        LocalError(n.sons[0].info, errInvalidVisibilityX, v.s)
    else:
      illFormedAst(n)
  else:
    result = newSymS(kind, n, c)
  
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
  
proc checkForOverlap(c: PContext, t, ex: PNode, branchIndex: int) = 
  for i in countup(1, branchIndex - 1): 
    for j in countup(0, sonsLen(t.sons[i]) - 2): 
      if overlap(t.sons[i].sons[j], ex): 
        LocalError(ex.info, errDuplicateCaseLabel)
  
proc semBranchExpr(c: PContext, t, e: PNode): PNode =
  result = semConstExpr(c, e)
  checkMinSonsLen(t, 1)
  result = fitNode(c, t.sons[0].typ, result)
  #if cmpTypes(t.sons[0].typ, result.typ) <= isConvertible: 
  #  typeMismatch(result, t.sons[0].typ, result.typ)

proc SemCaseBranchRange(c: PContext, t, b: PNode, 
                        covered: var biggestInt): PNode = 
  checkSonsLen(b, 3)
  result = newNodeI(nkRange, b.info)
  result.add(semBranchExpr(c, t, b.sons[1]))
  result.add(semBranchExpr(c, t, b.sons[2]))
  if emptyRange(result[0], result[1]): GlobalError(b.info, errRangeIsEmpty)
  covered = covered + getOrdValue(result[1]) - getOrdValue(result[0]) + 1

proc semCaseBranchSetElem(c: PContext, t, b: PNode, 
                          covered: var biggestInt): PNode = 
  if isRange(b):
    checkSonsLen(b, 3)
    result = newNodeI(nkRange, b.info)
    result.add(semBranchExpr(c, t, b.sons[1]))
    result.add(semBranchExpr(c, t, b.sons[2]))
    if emptyRange(result[0], result[1]): GlobalError(b.info, errRangeIsEmpty)
    covered = covered + getOrdValue(result[1]) - getOrdValue(result[0]) + 1
  elif b.kind == nkRange:
    checkSonsLen(b, 2)
    result = newNodeI(nkRange, b.info)
    result.add(semBranchExpr(c, t, b.sons[0]))
    result.add(semBranchExpr(c, t, b.sons[1]))
    if emptyRange(result[0], result[1]): GlobalError(b.info, errRangeIsEmpty)
    covered = covered + getOrdValue(result[1]) - getOrdValue(result[0]) + 1
  else:
    result = fitNode(c, t.sons[0].typ, b)
    inc(covered)

proc semCaseBranch(c: PContext, t, branch: PNode, branchIndex: int, 
                   covered: var biggestInt) = 
  for i in countup(0, sonsLen(branch) - 2): 
    var b = branch.sons[i]
    if isRange(b):
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
    checkForOverlap(c, t, branch.sons[i], branchIndex)
     
proc semRecordNodeAux(c: PContext, n: PNode, check: var TIntSet, pos: var int, 
                      father: PNode, rectype: PSym)
proc semRecordCase(c: PContext, n: PNode, check: var TIntSet, pos: var int, 
                   father: PNode, rectype: PSym) = 
  var a = copyNode(n)
  checkMinSonsLen(n, 2)
  semRecordNodeAux(c, n.sons[0], check, pos, a, rectype)
  if a.sons[0].kind != nkSym: 
    internalError("semRecordCase: dicriminant is no symbol")
  incl(a.sons[0].sym.flags, sfDiscriminant)
  var covered: biggestInt = 0
  var typ = skipTypes(a.sons[0].Typ, abstractVar)
  if not isOrdinalType(typ): GlobalError(n.info, errSelectorMustBeOrdinal)
  if firstOrd(typ) < 0: 
    GlobalError(n.info, errOrdXMustNotBeNegative, a.sons[0].sym.name.s)
  if lengthOrd(typ) > 0x00007FFF: 
    GlobalError(n.info, errLenXinvalid, a.sons[0].sym.name.s)
  var chckCovered = true
  for i in countup(1, sonsLen(n) - 1): 
    var b = copyTree(n.sons[i])
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
    addSon(a, b)
  if chckCovered and (covered != lengthOrd(a.sons[0].typ)): 
    localError(a.info, errNotAllCasesCovered)
  addSon(father, a)

proc semRecordNodeAux(c: PContext, n: PNode, check: var TIntSet, pos: var int, 
                      father: PNode, rectype: PSym) = 
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
          if e.intVal != 0 and branch == nil: branch = it.sons[1]
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
    if father.kind != nkRecList and length >= 4: a = newNodeI(nkRecList, n.info)
    else: a = ast.emptyNode
    if n.sons[length-1].kind != nkEmpty: 
      localError(n.sons[length-1].info, errInitHereNotAllowed)
    if n.sons[length-2].kind == nkEmpty: 
      GlobalError(n.info, errTypeExpected)
    var typ = semTypeNode(c, n.sons[length-2], nil)
    for i in countup(0, sonsLen(n)-3): 
      var f = semIdentWithPragma(c, skField, n.sons[i], {sfExported})
      f.typ = typ
      f.position = pos
      if (rectype != nil) and ({sfImportc, sfExportc} * rectype.flags != {}) and
          (f.loc.r == nil): 
        f.loc.r = toRope(f.name.s)
        f.flags = f.flags + ({sfImportc, sfExportc} * rectype.flags)
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
      localError(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects)
  if n.kind != nkObjectTy: InternalError(n.info, "semObjectNode")
  result = newOrPrevType(tyObject, prev, c)
  addSon(result, base)
  result.n = newNodeI(nkRecList, n.info)
  semRecordNodeAux(c, n.sons[2], check, pos, result.n, result.sym)
  
proc addTypeVarsOfGenericBody(c: PContext, t: PType, genericParams: PNode, 
                              cl: var TIntSet): PType = 
  result = t
  if t == nil: return 
  if ContainsOrIncl(cl, t.id): return 
  case t.kind
  of tyGenericBody: 
    result = newTypeS(tyGenericInvokation, c)
    addSon(result, t)
    for i in countup(0, sonsLen(t) - 2): 
      if t.sons[i].kind != tyGenericParam: 
        InternalError("addTypeVarsOfGenericBody")
      # do not declare ``TKey`` twice:
      #if not ContainsOrIncl(cl, t.sons[i].sym.ident.id):
      var s = copySym(t.sons[i].sym)
      s.position = sonsLen(genericParams)
      if s.typ == nil or s.typ.kind != tyGenericParam: 
        InternalError("addTypeVarsOfGenericBody 2")
      addDecl(c, s)
      addSon(genericParams, newSymNode(s))
      addSon(result, t.sons[i])
  of tyGenericInst: 
    var L = sonsLen(t) - 1
    t.sons[L] = addTypeVarsOfGenericBody(c, t.sons[L], genericParams, cl)
  of tyGenericInvokation: 
    for i in countup(1, sonsLen(t) - 1): 
      t.sons[i] = addTypeVarsOfGenericBody(c, t.sons[i], genericParams, cl)
  else: 
    for i in countup(0, sonsLen(t) - 1): 
      t.sons[i] = addTypeVarsOfGenericBody(c, t.sons[i], genericParams, cl)
  
proc paramType(c: PContext, n, genericParams: PNode, cl: var TIntSet): PType = 
  result = semTypeNode(c, n, nil)
  if genericParams != nil and sonsLen(genericParams) == 0: 
    result = addTypeVarsOfGenericBody(c, result, genericParams, cl)

proc semProcTypeNode(c: PContext, n, genericParams: PNode, 
                     prev: PType): PType = 
  var 
    def, res: PNode
    typ: PType
    cl: TIntSet
  checkMinSonsLen(n, 1)
  result = newOrPrevType(tyProc, prev, c)
  result.callConv = lastOptionEntry(c).defaultCC
  result.n = newNodeI(nkFormalParams, n.info)
  if genericParams != nil and sonsLen(genericParams) == 0:
    cl = initIntSet()
  addSon(result, nil) # return type
  res = newNodeI(nkType, n.info)
  addSon(result.n, res)
  var check = initIntSet()
  var counter = 0
  for i in countup(1, sonsLen(n)-1): 
    var a = n.sons[i]
    if a.kind != nkIdentDefs: IllFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    if a.sons[length-2].kind != nkEmpty: 
      typ = paramType(c, a.sons[length-2], genericParams, cl)
      #if matchType(typ, [(tyVar, 0)], tyGenericInvokation):
      #  debug a.sons[length-2][0][1]
    else:
      typ = nil
      # consider: 
      # template T(x)
      # it's wrong, but the parser might not generate a fatal error (when in
      # 'check' mode for example), so we need to check again here:
      if unlikely(a.sons[length-1].kind == nkEmpty): continue
      
    if a.sons[length-1].kind != nkEmpty:
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
    else:
      def = ast.emptyNode
    if skipTypes(typ, {tyGenericInst}).kind == tyEmpty: continue
    for j in countup(0, length-3): 
      var arg = newSymS(skParam, a.sons[j], c)
      arg.typ = typ
      arg.position = counter
      inc(counter)
      if def.kind != nkEmpty: arg.ast = copyTree(def)
      if ContainsOrIncl(check, arg.name.id): 
        LocalError(a.sons[j].info, errAttemptToRedefine, arg.name.s)
      addSon(result.n, newSymNode(arg))
      addSon(result, typ)
      addDecl(c, arg)

  if n.sons[0].kind != nkEmpty: 
    var r = paramType(c, n.sons[0], genericParams, cl)
    # turn explicit 'void' return type into 'nil' because the rest of the 
    # compiler only checks for 'nil':
    if skipTypes(r, {tyGenericInst}).kind != tyEmpty:
      result.sons[0] = r
      res.typ = result.sons[0]
  #if matchType(result, [(tyProc, 1), (tyVar, 0)], tyGenericInvokation):
  #  debug result

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
  openScope(c.tab)
  if n.sons[0].kind != nkEmpty: 
    addDecl(c, newSymS(skLabel, n.sons[0], c))
  result = semStmtListType(c, n.sons[1], prev)
  n.sons[1].typ = result
  n.typ = result
  closeScope(c.tab)
  Dec(c.p.nestedBlockCounter)

proc semGenericParamInInvokation(c: PContext, n: PNode): PType =
  # XXX hack 1022 for generics ... would have been nice if the compiler had
  # been designed with them in mind from start ...
  when false:
    if n.kind == nkSym:
      # for generics we need to lookup the type var again:
      var s = SymtabGet(c.Tab, n.sym.name)
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
  if s.typ == nil or s.typ.kind != tyGenericBody: 
    GlobalError(n.info, errCannotInstantiateX, s.name.s)
  result = newOrPrevType(tyGenericInvokation, prev, c)
  if s.typ.containerID == 0: InternalError(n.info, "semtypes.semGeneric")
  if sonsLen(n) != sonsLen(s.typ): 
    GlobalError(n.info, errWrongNumberOfArguments)
  addSon(result, s.typ)
  var isConcrete = true # iterate over arguments:
  for i in countup(1, sonsLen(n)-1):
    var elem = semGenericParamInInvokation(c, n.sons[i])
    if containsGenericType(elem): isConcrete = false
    #if elem.kind in {tyGenericParam, tyGenericInvokation}: isConcrete = false
    addSon(result, elem)
  if isConcrete:
    if s.ast == nil: GlobalError(n.info, errCannotInstantiateX, s.name.s)
    result = instGenericContainer(c, n, result)

proc semExpandToType(c: PContext, n: PNode, sym: PSym): PType =
  # Expands a macro or template until a type is returned
  # results in GlobalError if the macro expands to something different
  markUsed(n, sym)
  case sym.kind
  of skMacro:
    result = semTypeNode(c, semMacroExpr(c, n, sym), nil)
  of skTemplate:
    result = semTypeNode(c, semTemplateExpr(c, n, sym), nil)
  else:
    GlobalError(n.info, errXisNoMacroOrTemplate, n.renderTree)

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
    else: GlobalError(n.info, errTypeExpected)
  of nkCallKinds:
    # expand macros and templates
    var expandedSym = expectMacroOrTemplateCall(c, n)
    result = semExpandToType(c, n, expandedSym)
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
    else: result = semGeneric(c, n, s, prev)
  of nkIdent, nkDotExpr, nkAccQuoted: 
    var s = semTypeIdent(c, n)
    if s.typ == nil: GlobalError(n.info, errTypeExpected)
    if prev == nil: 
      result = s.typ
    else: 
      assignType(prev, s.typ)
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
      GlobalError(n.info, errTypeExpected)
  of nkObjectTy: result = semObjectNode(c, n, prev)
  of nkTupleTy: result = semTuple(c, n, prev)
  of nkRefTy: result = semAnyRef(c, n, tyRef, "ref", prev)
  of nkPtrTy: result = semAnyRef(c, n, tyPtr, "ptr", prev)
  of nkVarTy: result = semVarType(c, n, prev)
  of nkDistinctTy: result = semDistinct(c, n, prev)
  of nkProcTy: 
    checkSonsLen(n, 2)
    openScope(c.tab)
    result = semProcTypeNode(c, n.sons[0], nil, prev)
    # dummy symbol for `pragma`:
    var s = newSymS(skProc, newIdentNode(getIdent("dummy"), n.info), c)
    s.typ = result
    pragma(c, s, n.sons[1], procTypePragmas)
    closeScope(c.tab)    
  of nkEnumTy: result = semEnum(c, n, prev)
  of nkType: result = n.typ
  of nkStmtListType: result = semStmtListType(c, n, prev)
  of nkBlockType: result = semBlockType(c, n, prev)
  else: GlobalError(n.info, errTypeExpected) 
  #internalError(n.info, 'semTypeNode(' +{&} nodeKindToStr[n.kind] +{&} ')');
  
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
  of mFloat: setMagicType(m, tyFloat, floatSize)
  of mFloat32: setMagicType(m, tyFloat32, 4)
  of mFloat64: setMagicType(m, tyFloat64, 8)
  of mBool: setMagicType(m, tyBool, 1)
  of mChar: setMagicType(m, tyChar, 1)
  of mString: 
    setMagicType(m, tyString, ptrSize)
    addSon(m.typ, getSysType(tyChar))
  of mCstring: 
    setMagicType(m, tyCString, ptrSize)
    addSon(m.typ, getSysType(tyChar))
  of mPointer: setMagicType(m, tyPointer, ptrSize)
  of mEmptySet: 
    setMagicType(m, tySet, 1)
    addSon(m.typ, newTypeS(tyEmpty, c))
  of mIntSetBaseType: setMagicType(m, tyRange, intSize)
  of mNil: setMagicType(m, tyNil, ptrSize)
  of mExpr: setMagicType(m, tyExpr, 0)
  of mStmt: setMagicType(m, tyStmt, 0)
  of mTypeDesc: setMagicType(m, tyTypeDesc, 0)
  of mVoidType: setMagicType(m, tyEmpty, 0)
  of mArray, mOpenArray, mRange, mSet, mSeq, mOrdinal: nil 
  else: GlobalError(m.info, errTypeExpected)
  
proc newConstraint(c: PContext, k: TTypeKind): PType = 
  result = newTypeS(tyOrdinal, c)
  result.addSon(newTypeS(k, c))
  
proc semGenericConstraints(c: PContext, n: PNode, result: PType) = 
  case n.kind
  of nkProcTy: result.addSon(newConstraint(c, tyProc))
  of nkEnumTy: result.addSon(newConstraint(c, tyEnum))
  of nkObjectTy: result.addSon(newConstraint(c, tyObject))
  of nkTupleTy: result.addSon(newConstraint(c, tyTuple))
  of nkDistinctTy: result.addSon(newConstraint(c, tyDistinct))
  of nkVarTy: result.addSon(newConstraint(c, tyVar))
  of nkPtrTy: result.addSon(newConstraint(c, tyPtr))
  of nkRefTy: result.addSon(newConstraint(c, tyRef))
  of nkInfix: 
    semGenericConstraints(c, n.sons[1], result)
    semGenericConstraints(c, n.sons[2], result)
  else:
    result.addSon(semTypeNode(c, n, nil))

proc semGenericParamList(c: PContext, n: PNode, father: PType = nil): PNode = 
  result = copyNode(n)
  if n.kind != nkGenericParams: InternalError(n.info, "semGenericParamList")
  for i in countup(0, sonsLen(n)-1): 
    var a = n.sons[i]
    if a.kind != nkIdentDefs: illFormedAst(n)
    var L = sonsLen(a)
    var def = a.sons[L-1]
    var typ: PType
    if a.sons[L-2].kind != nkEmpty: 
      typ = newTypeS(tyGenericParam, c)
      semGenericConstraints(c, a.sons[L-2], typ)
      if sonsLen(typ) == 1 and typ.sons[0].kind == tyTypeDesc:
        typ = typ.sons[0]
    elif def.kind != nkEmpty: typ = newTypeS(tyExpr, c)
    else: typ = nil
    for j in countup(0, L-3): 
      var s: PSym
      if typ == nil:
        s = newSymS(skType, a.sons[j], c)
        s.typ = newTypeS(tyGenericParam, c)
      else:
        case typ.kind
        of tyTypeDesc: 
          s = newSymS(skType, a.sons[j], c)
          s.typ = newTypeS(tyGenericParam, c)
        of tyExpr:
          # not a type param, but an expression
          s = newSymS(skGenericParam, a.sons[j], c)
          s.typ = typ
        else:
          s = newSymS(skType, a.sons[j], c)
          s.typ = typ
      if def.kind != nkEmpty: s.ast = def
      s.typ.sym = s
      if father != nil: addSon(father, s.typ)
      s.position = i
      addSon(result, newSymNode(s))
      addDecl(c, s)

  
