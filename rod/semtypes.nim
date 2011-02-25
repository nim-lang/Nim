#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking of type declarations

proc fitNode(c: PContext, formal: PType, arg: PNode): PNode = 
  result = IndexTypesMatch(c, formal, arg.typ, arg)
  if result == nil: typeMismatch(arg, formal, arg.typ)
  
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
        if (x != counter): incl(result.flags, tfEnumHasWholes)
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
    if (result.sym != nil) and (sfInInterface in result.sym.flags): 
      incl(e.flags, sfUsed)   # BUGFIX
      incl(e.flags, sfInInterface) # BUGFIX
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
  if (n.kind != nkRange): InternalError(n.info, "semRangeAux")
  checkSonsLen(n, 2)
  result = newOrPrevType(tyRange, prev, c)
  result.n = newNodeI(nkRange, n.info)
  if (n.sons[0].kind == nkEmpty) or (n.sons[1].kind == nkEmpty): 
    GlobalError(n.Info, errRangeIsEmpty)
  var a = semConstExpr(c, n.sons[0])
  var b = semConstExpr(c, n.sons[1])
  if not sameType(a.typ, b.typ): GlobalError(n.info, errPureTypeMismatch)
  if not (a.typ.kind in
      {tyInt..tyInt64, tyEnum, tyBool, tyChar, tyFloat..tyFloat128}): 
    GlobalError(n.info, errOrdinalTypeExpected)
  if enumHasWholes(a.typ): 
    GlobalError(n.info, errEnumXHasHoles, a.typ.sym.name.s)
  if not leValue(a, b): GlobalError(n.Info, errRangeIsEmpty)
  addSon(result.n, a)
  addSon(result.n, b)
  addSon(result, b.typ)

proc semRange(c: PContext, n: PNode, prev: PType): PType = 
  result = nil
  if sonsLen(n) == 2: 
    if n.sons[1].kind == nkRange: result = semRangeAux(c, n.sons[1], prev)
    else: GlobalError(n.sons[0].info, errRangeExpected)
  else: 
    GlobalError(n.info, errXExpectsOneTypeParam, "range")
  
proc semArray(c: PContext, n: PNode, prev: PType): PType = 
  var indx, base: PType
  result = newOrPrevType(tyArray, prev, c)
  if sonsLen(n) == 3: 
    # 3 = length(array indx base)
    if n.sons[1].kind == nkRange: indx = semRangeAux(c, n.sons[1], nil)
    else: indx = semTypeNode(c, n.sons[1], nil)
    addSon(result, indx)
    if indx.kind == tyGenericInst: indx = lastSon(indx)
    if indx.kind != tyGenericParam: 
      if not isOrdinalType(indx): 
        GlobalError(n.sons[1].info, errOrdinalTypeExpected)
      if enumHasWholes(indx): 
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
  result = qualifiedLookup(c, n, {checkAmbiguity, checkUndeclared})
  if (result != nil): 
    markUsed(n, result)
    if result.kind != skType: GlobalError(n.info, errTypeExpected)
  else: 
    GlobalError(n.info, errIdentifierExpected)
  
proc semTuple(c: PContext, n: PNode, prev: PType): PType = 
  var 
    typ: PType
    check: TIntSet
  result = newOrPrevType(tyTuple, prev, c)
  result.n = newNodeI(nkRecList, n.info)
  IntSetInit(check)
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
      if IntSetContainsOrIncl(check, field.name.id): 
        GlobalError(a.sons[j].info, errAttemptToRedefine, field.name.s)
      addSon(result.n, newSymNode(field))
      addSon(result, typ)

proc semGeneric(c: PContext, n: PNode, s: PSym, prev: PType): PType = 
  var 
    elem: PType
    isConcrete: bool
  if (s.typ == nil) or (s.typ.kind != tyGenericBody): 
    GlobalError(n.info, errCannotInstantiateX, s.name.s)
  result = newOrPrevType(tyGenericInvokation, prev, c)
  if (s.typ.containerID == 0): InternalError(n.info, "semtypes.semGeneric")
  if sonsLen(n) != sonsLen(s.typ): 
    GlobalError(n.info, errWrongNumberOfArguments)
  addSon(result, s.typ)
  isConcrete = true           # iterate over arguments:
  for i in countup(1, sonsLen(n) - 1): 
    elem = semTypeNode(c, n.sons[i], nil)
    if elem.kind == tyGenericParam: isConcrete = false
    addSon(result, elem)
  if isConcrete: 
    if s.ast == nil: GlobalError(n.info, errCannotInstantiateX, s.name.s)
    result = instGenericContainer(c, n, result)

proc semIdentVis(c: PContext, kind: TSymKind, n: PNode, 
                 allowed: TSymFlags): PSym = 
  # identifier with visibility
  if n.kind == nkPostfix: 
    if sonsLen(n) == 2 and n.sons[0].kind == nkIdent: 
      result = newSymS(kind, n.sons[1], c)
      var v = n.sons[0].ident
      if (sfStar in allowed) and (v.id == ord(wStar)): 
        incl(result.flags, sfStar)
      elif (sfMinus in allowed) and (v.id == ord(wMinus)): 
        incl(result.flags, sfMinus)
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
    of skConst: pragma(c, result, n.sons[1], constPragmas)
    else: nil
  else: 
    result = semIdentVis(c, kind, n, allowed)
  
proc checkForOverlap(c: PContext, t, ex: PNode, branchIndex: int) = 
  for i in countup(1, branchIndex - 1): 
    for j in countup(0, sonsLen(t.sons[i]) - 2): 
      if overlap(t.sons[i].sons[j], ex): 
        LocalError(ex.info, errDuplicateCaseLabel)
  
proc semBranchExpr(c: PContext, t: PNode, ex: var PNode) = 
  ex = semConstExpr(c, ex)
  checkMinSonsLen(t, 1)
  if (cmpTypes(t.sons[0].typ, ex.typ) <= isConvertible): 
    typeMismatch(ex, t.sons[0].typ, ex.typ)

proc SemCaseBranch(c: PContext, t, branch: PNode, branchIndex: int, 
                   covered: var biggestInt) = 
  for i in countup(0, sonsLen(branch) - 2): 
    var b = branch.sons[i]
    if b.kind == nkRange: 
      checkSonsLen(b, 2)
      semBranchExpr(c, t, b.sons[0])
      semBranchExpr(c, t, b.sons[1])
      if emptyRange(b.sons[0], b.sons[1]): 
        #MessageOut(renderTree(t));
        GlobalError(b.info, errRangeIsEmpty)
      covered = covered + getOrdValue(b.sons[1]) - getOrdValue(b.sons[0]) + 1
    else: 
      semBranchExpr(c, t, branch.sons[i]) # NOT: `b`, because of var-param!
      inc(covered)
    checkForOverlap(c, t, branch.sons[i], branchIndex)

proc semRecordNodeAux(c: PContext, n: PNode, check: var TIntSet, pos: var int, 
                      father: PNode, rectype: PSym)
proc semRecordCase(c: PContext, n: PNode, check: var TIntSet, pos: var int, 
                   father: PNode, rectype: PSym) = 
  var 
    covered: biggestint
    chckCovered: bool
    a, b: PNode
    typ: PType
  a = copyNode(n)
  checkMinSonsLen(n, 2)
  semRecordNodeAux(c, n.sons[0], check, pos, a, rectype)
  if a.sons[0].kind != nkSym: 
    internalError("semRecordCase: dicriminant is no symbol")
  incl(a.sons[0].sym.flags, sfDiscriminant)
  covered = 0
  typ = skipTypes(a.sons[0].Typ, abstractVar)
  if not isOrdinalType(typ): GlobalError(n.info, errSelectorMustBeOrdinal)
  if firstOrd(typ) < 0: 
    GlobalError(n.info, errOrdXMustNotBeNegative, a.sons[0].sym.name.s)
  if lengthOrd(typ) > 0x00007FFF: 
    GlobalError(n.info, errLenXinvalid, a.sons[0].sym.name.s)
  chckCovered = true
  for i in countup(1, sonsLen(n) - 1): 
    b = copyTree(n.sons[i])
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
  var 
    length: int
    f: PSym                   # new field
    a, it, e, branch: PNode
    typ: PType
  if n == nil: 
    return                    # BUGFIX: nil is possible
  case n.kind
  of nkRecWhen: 
    branch = nil              # the branch to take
    for i in countup(0, sonsLen(n) - 1): 
      it = n.sons[i]
      if it == nil: illFormedAst(n)
      case it.kind
      of nkElifBranch: 
        checkSonsLen(it, 2)
        e = semConstExpr(c, it.sons[0])
        checkBool(e)
        if (e.kind != nkIntLit): InternalError(e.info, "semRecordNodeAux")
        if (e.intVal != 0) and (branch == nil): branch = it.sons[1]
      of nkElse: 
        checkSonsLen(it, 1)
        if branch == nil: branch = it.sons[0]
      else: illFormedAst(n)
    if branch != nil: semRecordNodeAux(c, branch, check, pos, father, rectype)
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
    length = sonsLen(n)
    if (father.kind != nkRecList) and (length >= 4): 
      a = newNodeI(nkRecList, n.info)
    else: 
      a = ast.emptyNode
    if n.sons[length - 1].kind != nkEmpty: 
      localError(n.sons[length - 1].info, errInitHereNotAllowed)
    if n.sons[length - 2].kind == nkEmpty: 
      GlobalError(n.info, errTypeExpected)
    typ = semTypeNode(c, n.sons[length-2], nil)
    for i in countup(0, sonsLen(n) - 3): 
      f = semIdentWithPragma(c, skField, n.sons[i], {sfStar, sfMinus})
      f.typ = typ
      f.position = pos
      if (rectype != nil) and ({sfImportc, sfExportc} * rectype.flags != {}) and
          (f.loc.r == nil): 
        f.loc.r = toRope(f.name.s)
        f.flags = f.flags + ({sfImportc, sfExportc} * rectype.flags)
      inc(pos)
      if IntSetContainsOrIncl(check, f.name.id): 
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
    IntSetIncl(check, n.sym.name.id)
    inc(pos)
  else: InternalError(n.info, "addInheritedFieldsAux()")
  
proc addInheritedFields(c: PContext, check: var TIntSet, pos: var int, 
                        obj: PType) = 
  if (sonsLen(obj) > 0) and (obj.sons[0] != nil): 
    addInheritedFields(c, check, pos, obj.sons[0])
  addInheritedFieldsAux(c, check, pos, obj.n)

proc semObjectNode(c: PContext, n: PNode, prev: PType): PType = 
  var 
    check: TIntSet
    base: PType
    pos: int
  IntSetInit(check)
  pos = 0 # n.sons[0] contains the pragmas (if any). We process these later...
  checkSonsLen(n, 3)
  if n.sons[1].kind != nkEmpty: 
    base = semTypeNode(c, n.sons[1].sons[0], nil)
    if base.kind == tyObject: addInheritedFields(c, check, pos, base)
    else: localError(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects)
  else:
    base = nil
  if n.kind != nkObjectTy: InternalError(n.info, "semObjectNode")
  result = newOrPrevType(tyObject, prev, c)
  addSon(result, base)
  result.n = newNodeI(nkRecList, n.info)
  semRecordNodeAux(c, n.sons[2], check, pos, result.n, result.sym)
  if (base != nil) and (tfFinal in base.flags): 
    localError(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects)
  
proc addTypeVarsOfGenericBody(c: PContext, t: PType, genericParams: PNode, 
                              cl: var TIntSet): PType = 
  result = t
  if t == nil: return 
  if IntSetContainsOrIncl(cl, t.id): return 
  case t.kind
  of tyGenericBody: 
    #debug(t)
    result = newTypeS(tyGenericInvokation, c)
    addSon(result, t)
    for i in countup(0, sonsLen(t) - 2): 
      if t.sons[i].kind != tyGenericParam: 
        InternalError("addTypeVarsOfGenericBody")
      # do not declare ``TKey`` twice:
      #if not IntSetContainsOrIncl(cl, t.sons[i].sym.ident.id):
      var s = copySym(t.sons[i].sym)
      s.position = sonsLen(genericParams)
      if s.typ == nil or s.typ.kind != tyGenericParam: 
        InternalError("addTypeVarsOfGenericBody 2")
      addDecl(c, s)
      addSon(genericParams, newSymNode(s))
      addSon(result, t.sons[i])
  of tyGenericInst: 
    #debug(t)
    var L = sonsLen(t) - 1
    t.sons[L] = addTypeVarsOfGenericBody(c, t.sons[L], genericParams, cl)
  of tyGenericInvokation: 
    #debug(t)
    for i in countup(1, sonsLen(t) - 1): 
      t.sons[i] = addTypeVarsOfGenericBody(c, t.sons[i], genericParams, cl)
  else: 
    for i in countup(0, sonsLen(t) - 1): 
      t.sons[i] = addTypeVarsOfGenericBody(c, t.sons[i], genericParams, cl)
  
proc paramType(c: PContext, n, genericParams: PNode, cl: var TIntSet): PType = 
  result = semTypeNode(c, n, nil)
  if (genericParams != nil) and (sonsLen(genericParams) == 0): 
    result = addTypeVarsOfGenericBody(c, result, genericParams, cl)
    #if result.kind == tyGenericInvokation: debug(result)
  
proc semProcTypeNode(c: PContext, n, genericParams: PNode, prev: PType): PType = 
  var 
    def, res: PNode
    typ: PType
    check, cl: TIntSet
  checkMinSonsLen(n, 1)
  result = newOrPrevType(tyProc, prev, c)
  result.callConv = lastOptionEntry(c).defaultCC
  result.n = newNodeI(nkFormalParams, n.info)
  if (genericParams != nil) and (sonsLen(genericParams) == 0): IntSetInit(cl)
  addSon(result, nil) # return type
  res = newNodeI(nkType, n.info)
  addSon(result.n, res)
  IntSetInit(check)
  var counter = 0
  for i in countup(1, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind != nkIdentDefs: IllFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    if a.sons[length - 2].kind != nkEmpty: 
      typ = paramType(c, a.sons[length - 2], genericParams, cl)
    else: 
      typ = nil
    if a.sons[length - 1].kind != nkEmpty: 
      def = semExprWithType(c, a.sons[length - 1]) 
      # check type compability between def.typ and typ:
      if typ != nil: 
        if cmpTypes(typ, def.typ) < isConvertible: 
          typeMismatch(a.sons[length - 1], typ, def.typ)
        def = fitNode(c, typ, def)
      else: 
        typ = def.typ
    else: 
      def = ast.emptyNode
    for j in countup(0, length - 3): 
      var arg = newSymS(skParam, a.sons[j], c)
      arg.typ = typ
      arg.position = counter
      inc(counter)
      if def.kind != nkEmpty: arg.ast = copyTree(def)
      if IntSetContainsOrIncl(check, arg.name.id): 
        LocalError(a.sons[j].info, errAttemptToRedefine, arg.name.s)
      addSon(result.n, newSymNode(arg))
      addSon(result, typ)
  if n.sons[0].kind != nkEmpty: 
    result.sons[0] = paramType(c, n.sons[0], genericParams, cl)
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
  openScope(c.tab)
  if n.sons[0].kind != nkEmpty: 
    addDecl(c, newSymS(skLabel, n.sons[0], c))
  result = semStmtListType(c, n.sons[1], prev)
  n.sons[1].typ = result
  n.typ = result
  closeScope(c.tab)
  Dec(c.p.nestedBlockCounter)

proc semTypeNode(c: PContext, n: PNode, prev: PType): PType = 
  var 
    s: PSym
    t: PType
  result = nil
  if gCmd == cmdIdeTools: suggestExpr(c, n)
  case n.kind
  of nkEmpty: nil
  of nkTypeOfExpr: 
    result = semExprWithType(c, n, {efAllowType}).typ
  of nkPar: 
    if sonsLen(n) == 1: result = semTypeNode(c, n.sons[0], prev)
    else: GlobalError(n.info, errTypeExpected)
  of nkBracketExpr: 
    checkMinSonsLen(n, 2)
    s = semTypeIdent(c, n.sons[0])
    case s.magic
    of mArray: result = semArray(c, n, prev)
    of mOpenArray: result = semContainer(c, n, tyOpenArray, "openarray", prev)
    of mRange: result = semRange(c, n, prev)
    of mSet: result = semSet(c, n, prev)
    of mOrdinal: result = semOrdinal(c, n, prev)
    of mSeq: result = semContainer(c, n, tySequence, "seq", prev)
    else: result = semGeneric(c, n, s, prev)
  of nkIdent, nkDotExpr, nkAccQuoted: 
    s = semTypeIdent(c, n)
    if s.typ == nil: GlobalError(n.info, errTypeExpected)
    if prev == nil: 
      result = s.typ
    else: 
      assignType(prev, s.typ)
      prev.id = s.typ.id
      result = prev
  of nkSym: 
    if (n.sym.kind == skType) and (n.sym.typ != nil): 
      t = n.sym.typ
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
    result = semProcTypeNode(c, n.sons[0], nil, prev) 
    # dummy symbol for `pragma`:
    s = newSymS(skProc, newIdentNode(getIdent("dummy"), n.info), c)
    s.typ = result
    pragma(c, s, n.sons[1], procTypePragmas)
  of nkEnumTy: 
    result = semEnum(c, n, prev)
  of nkType: 
    result = n.typ
  of nkStmtListType: 
    result = semStmtListType(c, n, prev)
  of nkBlockType: 
    result = semBlockType(c, n, prev)
  else: 
    GlobalError(n.info, errTypeExpected) 
    #internalError(n.info, 'semTypeNode(' +{&} nodeKindToStr[n.kind] +{&} ')');
  
proc setMagicType(m: PSym, kind: TTypeKind, size: int) = 
  m.typ.kind = kind
  m.typ.align = size
  m.typ.size = size           #m.typ.sym := nil;
  
proc processMagicType(c: PContext, m: PSym) = 
  case m.magic                #registerSysType(m.typ);
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
  of mIntSetBaseType: 
    setMagicType(m, tyRange, intSize) #intSetBaseType := m.typ;
    return 
  of mNil: setMagicType(m, tyNil, ptrSize)
  of mExpr: setMagicType(m, tyExpr, 0)
  of mStmt: setMagicType(m, tyStmt, 0)
  of mTypeDesc: setMagicType(m, tyTypeDesc, 0)
  of mArray, mOpenArray, mRange, mSet, mSeq, mOrdinal: return 
  else: GlobalError(m.info, errTypeExpected)
  
