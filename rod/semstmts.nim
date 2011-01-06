#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking of statements

proc semExprNoType(c: PContext, n: PNode): PNode =
  result = semExpr(c, n)
  if result.typ != nil and result.typ.kind != tyStmt:
    liMessage(n.info, errDiscardValue)

proc semWhen(c: PContext, n: PNode): PNode = 
  result = nil
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if it == nil: illFormedAst(n)
    case it.kind
    of nkElifBranch: 
      checkSonsLen(it, 2)
      var e = semConstExpr(c, it.sons[0])
      checkBool(e)
      if (e.kind != nkIntLit): InternalError(n.info, "semWhen")
      if (e.intVal != 0) and (result == nil): 
        result = semStmt(c, it.sons[1]) # do not open a new scope!
    of nkElse: 
      checkSonsLen(it, 1)
      if result == nil: 
        result = semStmt(c, it.sons[0]) # do not open a new scope!
    else: illFormedAst(n)
  if result == nil: 
    result = newNodeI(nkNilLit, n.info) 
  # The ``when`` statement implements the mechanism for platform dependant
  # code. Thus we try to ensure here consistent ID allocation after the
  # ``when`` statement.
  IDsynchronizationPoint(200)

proc semIf(c: PContext, n: PNode): PNode = 
  result = n
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if it == nil: illFormedAst(n)
    case it.kind
    of nkElifBranch: 
      checkSonsLen(it, 2)
      openScope(c.tab)
      it.sons[0] = semExprWithType(c, it.sons[0])
      checkBool(it.sons[0])
      it.sons[1] = semStmt(c, it.sons[1])
      closeScope(c.tab)
    of nkElse: 
      if sonsLen(it) == 1: it.sons[0] = semStmtScope(c, it.sons[0])
      else: illFormedAst(it)
    else: illFormedAst(n)
  
proc semDiscard(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  n.sons[0] = semExprWithType(c, n.sons[0])
  if n.sons[0].typ == nil: liMessage(n.info, errInvalidDiscard)
  
proc semBreakOrContinue(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if n.sons[0] != nil: 
    var s: PSym
    case n.sons[0].kind
    of nkIdent: s = lookUp(c, n.sons[0])
    of nkSym: s = n.sons[0].sym
    else: illFormedAst(n)
    if (s.kind == skLabel) and (s.owner.id == c.p.owner.id): 
      var x = newSymNode(s)
      x.info = n.info
      incl(s.flags, sfUsed)
      n.sons[0] = x
    else: 
      liMessage(n.info, errInvalidControlFlowX, s.name.s)
  elif (c.p.nestedLoopCounter <= 0) and (c.p.nestedBlockCounter <= 0): 
    liMessage(n.info, errInvalidControlFlowX, renderTree(n, {renderNoComments}))
  
proc semBlock(c: PContext, n: PNode): PNode = 
  result = n
  Inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2)
  openScope(c.tab)            # BUGFIX: label is in the scope of block!
  if n.sons[0] != nil: 
    var labl = newSymS(skLabel, n.sons[0], c)
    addDecl(c, labl)
    n.sons[0] = newSymNode(labl) # BUGFIX
  n.sons[1] = semStmt(c, n.sons[1])
  closeScope(c.tab)
  Dec(c.p.nestedBlockCounter)

proc semAsm(con: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 2)
  var marker = pragmaAsm(con, n.sons[0])
  if marker == '\0': marker = '`' # default marker
  case n.sons[1].kind
  of nkStrLit, nkRStrLit, nkTripleStrLit: 
    result = copyNode(n)
    var str = n.sons[1].strVal
    if str == "": liMessage(n.info, errEmptyAsm) 
    # now parse the string literal and substitute symbols:
    var a = 0
    while true: 
      var b = strutils.find(str, marker, a)
      var sub = if b < 0: copy(str, a) else: copy(str, a, b - 1)
      if sub != "": addSon(result, newStrNode(nkStrLit, sub))
      if b < 0: break 
      var c = strutils.find(str, marker, b + 1)
      if c < 0: sub = copy(str, b + 1)
      else: sub = copy(str, b + 1, c - 1)
      if sub != "": 
        var e = SymtabGet(con.tab, getIdent(sub))
        if e != nil: 
          if e.kind == skStub: loadStub(e)
          addSon(result, newSymNode(e))
        else: 
          addSon(result, newStrNode(nkStrLit, sub))
      if c < 0: break 
      a = c + 1
  else: illFormedAst(n)
  
proc semWhile(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 2)
  openScope(c.tab)
  n.sons[0] = semExprWithType(c, n.sons[0])
  CheckBool(n.sons[0])
  inc(c.p.nestedLoopCounter)
  n.sons[1] = semStmt(c, n.sons[1])
  dec(c.p.nestedLoopCounter)
  closeScope(c.tab)

proc toCover(t: PType): biggestInt = 
  var t2 = skipTypes(t, abstractVarRange)
  if t2.kind == tyEnum and enumHasWholes(t2): 
    result = sonsLen(t2.n)
  else:
    result = lengthOrd(skipTypes(t, abstractVar))

proc semCase(c: PContext, n: PNode): PNode = 
  # check selector:
  result = n
  checkMinSonsLen(n, 2)
  openScope(c.tab)
  n.sons[0] = semExprWithType(c, n.sons[0])
  var chckCovered = false
  var covered: biggestint = 0
  case skipTypes(n.sons[0].Typ, abstractVarRange).Kind
  of tyInt..tyInt64, tyChar, tyEnum: 
    chckCovered = true
  of tyFloat..tyFloat128, tyString: 
    nil
  else: liMessage(n.info, errSelectorMustBeOfCertainTypes)
  for i in countup(1, sonsLen(n) - 1): 
    var x = n.sons[i]
    case x.kind
    of nkOfBranch: 
      checkMinSonsLen(x, 2)
      semCaseBranch(c, n, x, i, covered)
      var length = sonsLen(x)
      x.sons[length - 1] = semStmtScope(c, x.sons[length - 1])
    of nkElifBranch: 
      chckCovered = false
      checkSonsLen(x, 2)
      x.sons[0] = semExprWithType(c, x.sons[0])
      checkBool(x.sons[0])
      x.sons[1] = semStmtScope(c, x.sons[1])
    of nkElse: 
      chckCovered = false
      checkSonsLen(x, 1)
      x.sons[0] = semStmtScope(c, x.sons[0])
    else: illFormedAst(x)
  if chckCovered and (covered != toCover(n.sons[0].typ)): 
    liMessage(n.info, errNotAllCasesCovered)
  closeScope(c.tab)

proc propertyWriteAccess(c: PContext, n, a: PNode): PNode = 
  var id = considerAcc(a[1])
  result = newNodeI(nkCall, n.info)
  addSon(result, newIdentNode(getIdent(id.s & '='), n.info))
  # a[0] is already checked for semantics, that does ``builtinFieldAccess``
  # this is ugly. XXX Semantic checking should use the ``nfSem`` flag for
  # nodes!
  addSon(result, a[0])
  addSon(result, semExpr(c, n[1]))
  result = semDirectCallAnalyseEffects(c, result, {})
  if result != nil:
    fixAbstractType(c, result)
    analyseIfAddressTakenInCall(c, result)
  else:
    liMessage(n.Info, errUndeclaredFieldX, id.s)

proc semAsgn(c: PContext, n: PNode): PNode = 
  checkSonsLen(n, 2)
  var a = n.sons[0]
  case a.kind
  of nkDotExpr: 
    # r.f = x
    # --> `f=` (r, x)
    a = builtinFieldAccess(c, a, {efLValue})
    if a == nil: 
      return propertyWriteAccess(c, n, n[0])
    when false:
      checkSonsLen(a, 2)
      var id = considerAcc(a.sons[1])
      result = newNodeI(nkCall, n.info)
      addSon(result, newIdentNode(getIdent(id.s & '='), n.info))
      addSon(result, semExpr(c, a.sons[0]))
      addSon(result, semExpr(c, n.sons[1]))
      result = semDirectCallAnalyseEffects(c, result, {})
      if result != nil: 
        fixAbstractType(c, result)
        analyseIfAddressTakenInCall(c, result)
        return 
  of nkBracketExpr: 
    # a[i..j] = x
    # --> `[..]=`(a, i, j, x)
    a = semSubscript(c, a, {efLValue})
    if a == nil:
      result = buildOverloadedSubscripts(n.sons[0], inAsgn=true)
      add(result, n[1])
      return semExprNoType(c, result)
  else: 
    a = semExprWithType(c, a, {efLValue})
  #n.sons[0] = semExprWithType(c, n.sons[0], {efLValue})
  n.sons[0] = a
  n.sons[1] = semExprWithType(c, n.sons[1])
  var le = a.typ
  if skipTypes(le, {tyGenericInst}).kind != tyVar and IsAssignable(a) == arNone: 
    # Direct assignment to a discriminant is allowed!
    liMessage(a.info, errXCannotBeAssignedTo, renderTree(a, {renderNoComments}))
  else: 
    n.sons[1] = fitNode(c, le, n.sons[1])
    fixAbstractType(c, n)
  result = n

proc SemReturn(c: PContext, n: PNode): PNode = 
  var 
    restype: PType
    a: PNode                  # temporary assignment for code generator
  result = n
  checkSonsLen(n, 1)
  if not (c.p.owner.kind in {skConverter, skMethod, skProc, skMacro}): 
    liMessage(n.info, errXNotAllowedHere, "\'return\'")
  if (n.sons[0] != nil): 
    n.sons[0] = SemExprWithType(c, n.sons[0]) # check for type compatibility:
    restype = c.p.owner.typ.sons[0]
    if (restype != nil): 
      a = newNodeI(nkAsgn, n.sons[0].info)
      n.sons[0] = fitNode(c, restype, n.sons[0])
      # optimize away ``return result``, because it would be transformed
      # to ``result = result; return``:
      if (n.sons[0].kind == nkSym) and (sfResult in n.sons[0].sym.flags): 
        n.sons[0] = nil
      else: 
        if (c.p.resultSym == nil): InternalError(n.info, "semReturn")
        addSon(a, semExprWithType(c, newSymNode(c.p.resultSym)))
        addSon(a, n.sons[0])
        n.sons[0] = a
    else: 
      liMessage(n.info, errCannotReturnExpr)
  
proc SemYield(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if (c.p.owner == nil) or (c.p.owner.kind != skIterator): 
    liMessage(n.info, errYieldNotAllowedHere)
  if (n.sons[0] != nil): 
    n.sons[0] = SemExprWithType(c, n.sons[0]) # check for type compatibility:
    var restype = c.p.owner.typ.sons[0]
    if (restype != nil): 
      n.sons[0] = fitNode(c, restype, n.sons[0])
      if (n.sons[0].typ == nil): InternalError(n.info, "semYield")
    else: 
      liMessage(n.info, errCannotReturnExpr)
  
proc fitRemoveHiddenConv(c: PContext, typ: Ptype, n: PNode): PNode = 
  result = fitNode(c, typ, n)
  if (result.kind in {nkHiddenStdConv, nkHiddenSubConv}): 
    changeType(result.sons[1], typ)
    result = result.sons[1]
  elif not sameType(result.typ, typ): 
    changeType(result, typ)
  
proc semVar(c: PContext, n: PNode): PNode = 
  var 
    length: int
    a, b, def: PNode
    typ, tup: PType
    v: PSym
  result = copyNode(n)
  for i in countup(0, sonsLen(n) - 1): 
    a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkIdentDefs) and (a.kind != nkVarTuple): IllFormedAst(a)
    checkMinSonsLen(a, 3)
    length = sonsLen(a)
    if a.sons[length - 2] != nil: typ = semTypeNode(c, a.sons[length - 2], nil)
    else: typ = nil
    if a.sons[length - 1] != nil: 
      def = semExprWithType(c, a.sons[length - 1]) 
      # BUGFIX: ``fitNode`` is needed here!
      # check type compability between def.typ and typ:
      if (typ != nil): def = fitNode(c, typ, def)
      else: typ = def.typ
    else: 
      def = nil
    if not typeAllowed(typ, skVar): 
      #debug(typ);
      liMessage(a.info, errXisNoType, typeToString(typ))
    tup = skipTypes(typ, {tyGenericInst})
    if a.kind == nkVarTuple: 
      if tup.kind != tyTuple: liMessage(a.info, errXExpected, "tuple")
      if length - 2 != sonsLen(tup): 
        liMessage(a.info, errWrongNumberOfVariables)
      b = newNodeI(nkVarTuple, a.info)
      newSons(b, length)
      b.sons[length - 2] = nil # no type desc
      b.sons[length - 1] = def
      addSon(result, b)
    for j in countup(0, length - 3): 
      if (c.p.owner.kind == skModule): 
        v = semIdentWithPragma(c, skVar, a.sons[j], {sfStar, sfMinus})
        incl(v.flags, sfGlobal)
      else: 
        v = semIdentWithPragma(c, skVar, a.sons[j], {})
      if v.flags * {sfStar, sfMinus} != {}: incl(v.flags, sfInInterface)
      addInterfaceDecl(c, v)
      if a.kind != nkVarTuple: 
        v.typ = typ
        b = newNodeI(nkIdentDefs, a.info)
        addSon(b, newSymNode(v))
        addSon(b, nil)        # no type description
        addSon(b, copyTree(def))
        addSon(result, b)
      else: 
        v.typ = tup.sons[j]
        b.sons[j] = newSymNode(v)

proc semConst(c: PContext, n: PNode): PNode = 
  var 
    a, def, b: PNode
    v: PSym
    typ: PType
  result = copyNode(n)
  for i in countup(0, sonsLen(n) - 1): 
    a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkConstDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    if (c.p.owner.kind == skModule): 
      v = semIdentWithPragma(c, skConst, a.sons[0], {sfStar, sfMinus})
      incl(v.flags, sfGlobal)
    else: 
      v = semIdentWithPragma(c, skConst, a.sons[0], {})
    if a.sons[1] != nil: typ = semTypeNode(c, a.sons[1], nil)
    else: typ = nil
    def = semAndEvalConstExpr(c, a.sons[2]) 
    # check type compability between def.typ and typ:
    if (typ != nil): 
      def = fitRemoveHiddenConv(c, typ, def)
    else: 
      typ = def.typ
    if not typeAllowed(typ, skConst): 
      liMessage(a.info, errXisNoType, typeToString(typ))
    v.typ = typ
    v.ast = def               # no need to copy
    if v.flags * {sfStar, sfMinus} != {}: incl(v.flags, sfInInterface)
    addInterfaceDecl(c, v)
    b = newNodeI(nkConstDef, a.info)
    addSon(b, newSymNode(v))
    addSon(b, nil)            # no type description
    addSon(b, copyTree(def))
    addSon(result, b)

proc semFor(c: PContext, n: PNode): PNode = 
  var 
    length: int
    v, countup: PSym
    iter: PType
    countupNode, call: PNode
  result = n
  checkMinSonsLen(n, 3)
  length = sonsLen(n)
  openScope(c.tab)
  if n.sons[length - 2].kind == nkRange: 
    checkSonsLen(n.sons[length - 2], 2) 
    # convert ``in 3..5`` to ``in countup(3, 5)``
    countupNode = newNodeI(nkCall, n.sons[length - 2].info)
    countUp = StrTableGet(magicsys.systemModule.Tab, getIdent("countup"))
    if (countUp == nil): liMessage(countupNode.info, errSystemNeeds, "countup")
    newSons(countupNode, 3)
    countupnode.sons[0] = newSymNode(countup)
    countupNode.sons[1] = n.sons[length - 2].sons[0]
    countupNode.sons[2] = n.sons[length - 2].sons[1]
    n.sons[length - 2] = countupNode
  n.sons[length - 2] = semExprWithType(c, n.sons[length - 2], {efWantIterator})
  call = n.sons[length - 2]
  if (call.kind != nkCall) or (call.sons[0].kind != nkSym) or
      (call.sons[0].sym.kind != skIterator): 
    liMessage(n.sons[length - 2].info, errIteratorExpected)
  iter = skipTypes(n.sons[length - 2].typ, {tyGenericInst})
  if iter.kind != tyTuple: 
    if length != 3: liMessage(n.info, errWrongNumberOfVariables)
    v = newSymS(skForVar, n.sons[0], c)
    v.typ = iter
    n.sons[0] = newSymNode(v)
    addDecl(c, v)
  else: 
    if length - 2 != sonsLen(iter): liMessage(n.info, errWrongNumberOfVariables)
    for i in countup(0, length - 3): 
      v = newSymS(skForVar, n.sons[i], c)
      v.typ = iter.sons[i]
      n.sons[i] = newSymNode(v)
      addDecl(c, v)
  Inc(c.p.nestedLoopCounter)
  n.sons[length - 1] = SemStmt(c, n.sons[length - 1])
  closeScope(c.tab)
  Dec(c.p.nestedLoopCounter)

proc semRaise(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if n.sons[0] != nil: 
    n.sons[0] = semExprWithType(c, n.sons[0])
    var typ = n.sons[0].typ
    if (typ.kind != tyRef) or (typ.sons[0].kind != tyObject): 
      liMessage(n.info, errExprCannotBeRaised)
  
proc semTry(c: PContext, n: PNode): PNode = 
  var check: TIntSet
  result = n
  checkMinSonsLen(n, 2)
  n.sons[0] = semStmtScope(c, n.sons[0])
  IntSetInit(check)
  for i in countup(1, sonsLen(n) - 1): 
    var a = n.sons[i]
    checkMinSonsLen(a, 1)
    var length = sonsLen(a)
    if a.kind == nkExceptBranch: 
      for j in countup(0, length - 2): 
        var typ = semTypeNode(c, a.sons[j], nil)
        if typ.kind == tyRef: typ = typ.sons[0]
        if (typ.kind != tyObject): 
          liMessage(a.sons[j].info, errExprCannotBeRaised)
        a.sons[j] = newNodeI(nkType, a.sons[j].info)
        a.sons[j].typ = typ
        if IntSetContainsOrIncl(check, typ.id): 
          liMessage(a.sons[j].info, errExceptionAlreadyHandled)
    elif a.kind != nkFinally: 
      illFormedAst(n) 
    # last child of an nkExcept/nkFinally branch is a statement:
    a.sons[length - 1] = semStmtScope(c, a.sons[length - 1])

proc semGenericParamList(c: PContext, n: PNode, father: PType = nil): PNode = 
  result = copyNode(n)
  if n.kind != nkGenericParams: InternalError(n.info, "semGenericParamList")
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind != nkIdentDefs: illFormedAst(n)
    var L = sonsLen(a)
    var def = a.sons[L - 1]
    var typ: PType
    if a.sons[L - 2] != nil: typ = semTypeNode(c, a.sons[L - 2], nil)
    elif def != nil: typ = newTypeS(tyExpr, c)
    else: typ = nil
    for j in countup(0, L - 3): 
      var s: PSym
      if (typ == nil) or (typ.kind == tyTypeDesc): 
        s = newSymS(skType, a.sons[j], c)
        s.typ = newTypeS(tyGenericParam, c)
      else: 
        # not a type param, but an expression
        s = newSymS(skGenericParam, a.sons[j], c)
        s.typ = typ
      s.ast = def
      s.typ.sym = s
      if father != nil: addSon(father, s.typ)
      s.position = i
      addSon(result, newSymNode(s))
      addDecl(c, s)

proc addGenericParamListToScope(c: PContext, n: PNode) = 
  if n.kind != nkGenericParams: 
    InternalError(n.info, "addGenericParamListToScope")
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind != nkSym: internalError(a.info, "addGenericParamListToScope")
    addDecl(c, a.sym)

proc SemTypeSection(c: PContext, n: PNode): PNode = 
  var 
    s: PSym
    t, body: PType
  result = n 
  # process the symbols on the left side for the whole type section, before
  # we even look at the type definitions on the right
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkTypeDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    if (c.p.owner.kind == skModule): 
      s = semIdentWithPragma(c, skType, a.sons[0], {sfStar, sfMinus})
      incl(s.flags, sfGlobal)
    else: 
      s = semIdentWithPragma(c, skType, a.sons[0], {})
    if s.flags * {sfStar, sfMinus} != {}: incl(s.flags, sfInInterface)
    s.typ = newTypeS(tyForward, c)
    s.typ.sym = s             # process pragmas:
    if a.sons[0].kind == nkPragmaExpr: 
      pragma(c, s, a.sons[0].sons[1], typePragmas) 
    # add it here, so that recursive types are possible:
    addInterfaceDecl(c, s)
    a.sons[0] = newSymNode(s)
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkTypeDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    if (a.sons[0].kind != nkSym): IllFormedAst(a)
    s = a.sons[0].sym
    if (s.magic == mNone) and (a.sons[2] == nil): 
      liMessage(a.info, errImplOfXexpected, s.name.s)
    if s.magic != mNone: processMagicType(c, s)
    if a.sons[1] != nil: 
      # We have a generic type declaration here. In generic types,
      # symbol lookup needs to be done here.
      openScope(c.tab)
      pushOwner(s)
      s.typ.kind = tyGenericBody
      if s.typ.containerID != 0: 
        InternalError(a.info, "semTypeSection: containerID")
      s.typ.containerID = getID()
      a.sons[1] = semGenericParamList(c, a.sons[1], s.typ)
      addSon(s.typ, nil)      # to be filled out later
      s.ast = a
      body = semTypeNode(c, a.sons[2], nil)
      if body != nil: body.sym = s
      s.typ.sons[sonsLen(s.typ) - 1] = body #debug(s.typ);
      popOwner()
      closeScope(c.tab)
    elif a.sons[2] != nil: 
      # process the type's body:
      pushOwner(s)
      t = semTypeNode(c, a.sons[2], s.typ)
      if (t != s.typ) and (s.typ != nil): 
        internalError(a.info, "semTypeSection()")
      s.typ = t
      s.ast = a
      popOwner()
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.sons[0].kind != nkSym): IllFormedAst(a)
    s = a.sons[0].sym         
    # compute the type's size and check for illegal recursions:
    if a.sons[1] == nil: 
      if (a.sons[2] != nil) and
          (a.sons[2].kind in {nkSym, nkIdent, nkAccQuoted}): 
        # type aliases are hard:
        #MessageOut('for type ' + typeToString(s.typ));
        t = semTypeNode(c, a.sons[2], nil)
        if t.kind in {tyObject, tyEnum}: 
          assignType(s.typ, t)
          s.typ.id = t.id     # same id
      checkConstructedType(s.info, s.typ)

proc semParamList(c: PContext, n, genericParams: PNode, s: PSym) = 
  s.typ = semProcTypeNode(c, n, genericParams, nil)

proc addParams(c: PContext, n: PNode) = 
  for i in countup(1, sonsLen(n) - 1): 
    if (n.sons[i].kind != nkSym): InternalError(n.info, "addParams")
    addDecl(c, n.sons[i].sym)

proc semBorrow(c: PContext, n: PNode, s: PSym) = 
  # search for the correct alias:
  var b = SearchForBorrowProc(c, s, c.tab.tos - 2)
  if b == nil: 
    liMessage(n.info, errNoSymbolToBorrowFromFound) # store the alias:
  n.sons[codePos] = newSymNode(b)

proc sideEffectsCheck(c: PContext, s: PSym) = 
  if {sfNoSideEffect, sfSideEffect} * s.flags ==
      {sfNoSideEffect, sfSideEffect}: 
    liMessage(s.info, errXhasSideEffects, s.name.s)
  
proc addResult(c: PContext, t: PType, info: TLineInfo) = 
  if t != nil: 
    var s = newSym(skVar, getIdent("result"), getCurrOwner())
    s.info = info
    s.typ = t
    incl(s.flags, sfResult)
    incl(s.flags, sfUsed)
    addDecl(c, s)
    c.p.resultSym = s

proc addResultNode(c: PContext, n: PNode) = 
  if c.p.resultSym != nil: addSon(n, newSymNode(c.p.resultSym))
  
proc semLambda(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, codePos + 1)
  var s = newSym(skProc, getIdent(":anonymous"), getCurrOwner())
  s.info = n.info
  var oldP = c.p                  # restore later
  s.ast = n
  n.sons[namePos] = newSymNode(s)
  pushOwner(s)
  openScope(c.tab)
  if (n.sons[genericParamsPos] != nil): 
    illFormedAst(n)           # process parameters:
  if n.sons[paramsPos] != nil: 
    semParamList(c, n.sons[ParamsPos], nil, s)
    addParams(c, s.typ.n)
  else: 
    s.typ = newTypeS(tyProc, c)
    addSon(s.typ, nil)
  s.typ.callConv = ccClosure
  if n.sons[pragmasPos] != nil: pragma(c, s, n.sons[pragmasPos], lambdaPragmas)
  s.options = gOptions
  if n.sons[codePos] != nil: 
    if sfImportc in s.flags: 
      liMessage(n.sons[codePos].info, errImplOfXNotAllowed, s.name.s)
    c.p = newProcCon(s)
    addResult(c, s.typ.sons[0], n.info)
    n.sons[codePos] = semStmtScope(c, n.sons[codePos])
    addResultNode(c, n)
  else: 
    liMessage(n.info, errImplOfXexpected, s.name.s)
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  c.p = oldP                  # restore
  result.typ = s.typ

proc semProcAux(c: PContext, n: PNode, kind: TSymKind, 
                validPragmas: TSpecialWords): PNode = 
  var 
    s, proto: PSym
    gp: PNode
  result = n
  checkSonsLen(n, codePos + 1)
  if c.p.owner.kind == skModule: 
    s = semIdentVis(c, kind, n.sons[0], {sfStar})
    incl(s.flags, sfGlobal)
  else: 
    s = semIdentVis(c, kind, n.sons[0], {})
  n.sons[namePos] = newSymNode(s)
  var oldP = c.p                  # restore later
  if sfStar in s.flags: incl(s.flags, sfInInterface)
  s.ast = n
  pushOwner(s)
  openScope(c.tab)
  if n.sons[genericParamsPos] != nil: 
    n.sons[genericParamsPos] = semGenericParamList(c, n.sons[genericParamsPos])
    gp = n.sons[genericParamsPos]
  else: 
    gp = newNodeI(nkGenericParams, n.info)
  # process parameters:
  if n.sons[paramsPos] != nil: 
    semParamList(c, n.sons[ParamsPos], gp, s)
    if sonsLen(gp) > 0: 
      if n.sons[genericParamsPos] == nil:
        # we have a list of implicit type parameters:
        n.sons[genericParamsPos] = gp
        # check for semantics again:
        semParamList(c, n.sons[ParamsPos], nil, s)
    addParams(c, s.typ.n)
  else: 
    s.typ = newTypeS(tyProc, c)
    addSon(s.typ, nil)
  proto = SearchForProc(c, s, c.tab.tos - 2) # -2 because we have a scope open
                                             # for parameters
  if proto == nil: 
    if oldP.owner.kind != skModule: 
      s.typ.callConv = ccClosure
    else: 
      s.typ.callConv = lastOptionEntry(c).defaultCC 
    # add it here, so that recursive procs are possible:
    # -2 because we have a scope open for parameters
    if kind in OverloadableSyms: 
      addInterfaceOverloadableSymAt(c, s, c.tab.tos - 2)
    else: 
      addInterfaceDeclAt(c, s, c.tab.tos - 2)
    if n.sons[pragmasPos] != nil: pragma(c, s, n.sons[pragmasPos], validPragmas)
  else: 
    if n.sons[pragmasPos] != nil: 
      liMessage(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProc)
    if sfForward notin proto.flags: 
      liMessage(n.info, errAttemptToRedefineX, proto.name.s)
    excl(proto.flags, sfForward)
    closeScope(c.tab)         # close scope with wrong parameter symbols
    openScope(c.tab)          # open scope for old (correct) parameter symbols
    if proto.ast.sons[genericParamsPos] != nil: 
      addGenericParamListToScope(c, proto.ast.sons[genericParamsPos])
    addParams(c, proto.typ.n)
    proto.info = s.info       # more accurate line information
    s.typ = proto.typ
    s = proto
    n.sons[genericParamsPos] = proto.ast.sons[genericParamsPos]
    n.sons[paramsPos] = proto.ast.sons[paramsPos]
    if (n.sons[namePos].kind != nkSym): InternalError(n.info, "semProcAux")
    n.sons[namePos].sym = proto
    proto.ast = n             # needed for code generation
    popOwner()
    pushOwner(s)
  s.options = gOptions
  if n.sons[codePos] != nil: 
    # for DLL generation, it is annoying to check for sfImportc!
    if sfBorrow in s.flags: 
      liMessage(n.sons[codePos].info, errImplOfXNotAllowed, s.name.s)
    if (n.sons[genericParamsPos] == nil): 
      c.p = newProcCon(s)
      if (s.typ.sons[0] != nil) and (kind != skIterator): 
        addResult(c, s.typ.sons[0], n.info)
      if sfImportc notin s.flags: 
        # no semantic checking for importc:
        n.sons[codePos] = semStmtScope(c, n.sons[codePos])
      if (s.typ.sons[0] != nil) and (kind != skIterator): addResultNode(c, n)
    else: 
      if (s.typ.sons[0] != nil) and (kind != skIterator): 
        addDecl(c, newSym(skUnknown, getIdent("result"), nil))
      n.sons[codePos] = semGenericStmtScope(c, n.sons[codePos])
    if sfImportc in s.flags: 
      # so we just ignore the body after semantic checking for importc:
      n.sons[codePos] = nil
  else: 
    if proto != nil: liMessage(n.info, errImplOfXexpected, proto.name.s)
    if {sfImportc, sfBorrow} * s.flags == {}: incl(s.flags, sfForward)
    elif sfBorrow in s.flags: semBorrow(c, n, s)
  sideEffectsCheck(c, s)
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  c.p = oldP                  # restore
  
proc semIterator(c: PContext, n: PNode): PNode = 
  result = semProcAux(c, n, skIterator, iteratorPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: liMessage(n.info, errXNeedsReturnType, "iterator")
  if n.sons[codePos] == nil: liMessage(n.info, errImplOfXexpected, s.name.s)
  
proc semProc(c: PContext, n: PNode): PNode = 
  result = semProcAux(c, n, skProc, procPragmas)

proc semMethod(c: PContext, n: PNode): PNode = 
  if not isTopLevel(c): liMessage(n.info, errXOnlyAtModuleScope, "method")
  result = semProcAux(c, n, skMethod, methodPragmas)
  
  var s = result.sons[namePos].sym
  var t = s.typ
  var hasObjParam = false
  
  for col in countup(1, sonsLen(t)-1): 
    if skipTypes(t.sons[col], skipPtrs).kind == tyObject: 
      hasObjParam = true
      break
  
  # XXX this not really correct way to do it: Perhaps it should be done after
  # generic instantiation. Well it's good enough for now: 
  if not hasObjParam:
    liMessage(n.info, errXNeedsParamObjectType, "method")

proc semConverterDef(c: PContext, n: PNode): PNode = 
  if not isTopLevel(c): liMessage(n.info, errXOnlyAtModuleScope, "converter")
  checkSonsLen(n, codePos + 1)
  if n.sons[genericParamsPos] != nil: 
    liMessage(n.info, errNoGenericParamsAllowedForX, "converter")
  result = semProcAux(c, n, skConverter, converterPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: liMessage(n.info, errXNeedsReturnType, "converter")
  if sonsLen(t) != 2: liMessage(n.info, errXRequiresOneArgument, "converter")
  addConverter(c, s)

proc semMacroDef(c: PContext, n: PNode): PNode = 
  checkSonsLen(n, codePos + 1)
  if n.sons[genericParamsPos] != nil: 
    liMessage(n.info, errNoGenericParamsAllowedForX, "macro")
  result = semProcAux(c, n, skMacro, macroPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: liMessage(n.info, errXNeedsReturnType, "macro")
  if sonsLen(t) != 2: liMessage(n.info, errXRequiresOneArgument, "macro")
  if n.sons[codePos] == nil: liMessage(n.info, errImplOfXexpected, s.name.s)
  
proc evalInclude(c: PContext, n: PNode): PNode = 
  result = newNodeI(nkStmtList, n.info)
  addSon(result, n)           # the rodwriter needs include information!
  for i in countup(0, sonsLen(n) - 1): 
    var f = getModuleFile(n.sons[i])
    var fileIndex = includeFilename(f)
    if IntSetContainsOrIncl(c.includedFiles, fileIndex): 
      liMessage(n.info, errRecursiveDependencyX, f)
    addSon(result, semStmt(c, gIncludeFile(f)))
    IntSetExcl(c.includedFiles, fileIndex)

proc semCommand(c: PContext, n: PNode): PNode =
  result = semExprNoType(c, n)
  
proc SemStmt(c: PContext, n: PNode): PNode = 
  const                       # must be last statements in a block:
    LastBlockStmts = {nkRaiseStmt, nkReturnStmt, nkBreakStmt, nkContinueStmt}
  result = n
  if n == nil: return 
  if nfSem in n.flags: return 
  case n.kind
  of nkAsgn: result = semAsgn(c, n)
  of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkMacroStmt, nkCallStrLit: 
    result = semCommand(c, n)
  of nkEmpty, nkCommentStmt, nkNilLit: nil
  of nkBlockStmt: result = semBlock(c, n)
  of nkStmtList: 
    var length = sonsLen(n)
    for i in countup(0, length - 1): 
      n.sons[i] = semStmt(c, n.sons[i])
      if (n.sons[i].kind in LastBlockStmts): 
        for j in countup(i + 1, length - 1): 
          case n.sons[j].kind
          of nkPragma, nkCommentStmt, nkNilLit, nkEmpty: 
            nil
          else: liMessage(n.sons[j].info, errStmtInvalidAfterReturn)
  of nkRaiseStmt: result = semRaise(c, n)
  of nkVarSection: result = semVar(c, n)
  of nkConstSection: result = semConst(c, n)
  of nkTypeSection: result = SemTypeSection(c, n)
  of nkIfStmt: result = SemIf(c, n)
  of nkWhenStmt: result = semWhen(c, n)
  of nkDiscardStmt: result = semDiscard(c, n)
  of nkWhileStmt: result = semWhile(c, n)
  of nkTryStmt: result = semTry(c, n)
  of nkBreakStmt, nkContinueStmt: result = semBreakOrContinue(c, n)
  of nkForStmt: result = semFor(c, n)
  of nkCaseStmt: result = semCase(c, n)
  of nkReturnStmt: result = semReturn(c, n)
  of nkAsmStmt: result = semAsm(c, n)
  of nkYieldStmt: result = semYield(c, n)
  of nkPragma: pragma(c, c.p.owner, n, stmtPragmas)
  of nkIteratorDef: result = semIterator(c, n)
  of nkProcDef: result = semProc(c, n)
  of nkMethodDef: result = semMethod(c, n)
  of nkConverterDef: result = semConverterDef(c, n)
  of nkMacroDef: result = semMacroDef(c, n)
  of nkTemplateDef: result = semTemplateDef(c, n)
  of nkImportStmt: 
    if not isTopLevel(c): liMessage(n.info, errXOnlyAtModuleScope, "import")
    result = evalImport(c, n)
  of nkFromStmt: 
    if not isTopLevel(c): liMessage(n.info, errXOnlyAtModuleScope, "from")
    result = evalFrom(c, n)
  of nkIncludeStmt: 
    if not isTopLevel(c): liMessage(n.info, errXOnlyAtModuleScope, "include")
    result = evalInclude(c, n)
  else: liMessage(n.info, errStmtExpected)
  if result == nil: InternalError(n.info, "SemStmt: result = nil")
  incl(result.flags, nfSem)

proc semStmtScope(c: PContext, n: PNode): PNode = 
  openScope(c.tab)
  result = semStmt(c, n)
  closeScope(c.tab)
