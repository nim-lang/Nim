#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## this module does the semantic checking of statements
#  included from sem.nim

proc semCommand(c: PContext, n: PNode): PNode =
  result = semExprNoType(c, n)

proc semWhen(c: PContext, n: PNode, semCheck = true): PNode =
  # If semCheck is set to false, ``when`` will return the verbatim AST of
  # the correct branch. Otherwise the AST will be passed through semStmt.
  result = nil
  
  template setResult(e: expr) =
    if semCheck: result = semStmt(c, e) # do not open a new scope!
    else: result = e

  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    case it.kind
    of nkElifBranch, nkElifExpr: 
      checkSonsLen(it, 2)
      var e = semConstExpr(c, it.sons[0])
      if e.kind != nkIntLit: InternalError(n.info, "semWhen")
      if e.intVal != 0 and result == nil:
        setResult(it.sons[1]) 
    of nkElse, nkElseExpr:
      checkSonsLen(it, 1)
      if result == nil: 
        setResult(it.sons[0])
    else: illFormedAst(n)
  if result == nil: 
    result = newNodeI(nkNilLit, n.info) 
  # The ``when`` statement implements the mechanism for platform dependent
  # code. Thus we try to ensure here consistent ID allocation after the
  # ``when`` statement.
  IDsynchronizationPoint(200)

proc semIf(c: PContext, n: PNode): PNode = 
  result = n
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    case it.kind
    of nkElifBranch: 
      checkSonsLen(it, 2)
      it.sons[0] = forceBool(c, semExprWithType(c, it.sons[0]))
      openScope(c.tab)
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
  if n.sons[0].typ == nil: localError(n.info, errInvalidDiscard)
  
proc semBreakOrContinue(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty: 
    var s: PSym
    case n.sons[0].kind
    of nkIdent: s = lookUp(c, n.sons[0])
    of nkSym: s = n.sons[0].sym
    else: illFormedAst(n)
    if s.kind == skLabel and s.owner.id == c.p.owner.id: 
      var x = newSymNode(s)
      x.info = n.info
      incl(s.flags, sfUsed)
      n.sons[0] = x
    else: 
      localError(n.info, errInvalidControlFlowX, s.name.s)
  elif (c.p.nestedLoopCounter <= 0) and (c.p.nestedBlockCounter <= 0): 
    localError(n.info, errInvalidControlFlowX, 
               renderTree(n, {renderNoComments}))
  
proc semBlock(c: PContext, n: PNode): PNode = 
  result = n
  Inc(c.p.nestedBlockCounter)
  checkSonsLen(n, 2)
  openScope(c.tab)            # BUGFIX: label is in the scope of block!
  if n.sons[0].kind != nkEmpty: 
    var labl = newSymS(skLabel, n.sons[0], c)
    addDecl(c, labl)
    n.sons[0] = newSymNode(labl)
  n.sons[1] = semStmt(c, n.sons[1])
  closeScope(c.tab)
  Dec(c.p.nestedBlockCounter)

proc semAsm(con: PContext, n: PNode): PNode = 
  checkSonsLen(n, 2)
  var marker = pragmaAsm(con, n.sons[0])
  if marker == '\0': marker = '`' # default marker
  result = semAsmOrEmit(con, n, marker)
  
proc semWhile(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 2)
  openScope(c.tab)
  n.sons[0] = forceBool(c, semExprWithType(c, n.sons[0]))
  inc(c.p.nestedLoopCounter)
  n.sons[1] = semStmt(c, n.sons[1])
  dec(c.p.nestedLoopCounter)
  closeScope(c.tab)

proc toCover(t: PType): biggestInt = 
  var t2 = skipTypes(t, abstractVarRange)
  if t2.kind == tyEnum and enumHasHoles(t2): 
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
  else: 
    LocalError(n.info, errSelectorMustBeOfCertainTypes)
    return
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
      x.sons[0] = forceBool(c, semExprWithType(c, x.sons[0]))
      x.sons[1] = semStmtScope(c, x.sons[1])
    of nkElse: 
      chckCovered = false
      checkSonsLen(x, 1)
      x.sons[0] = semStmtScope(c, x.sons[0])
    else: illFormedAst(x)
  if chckCovered and (covered != toCover(n.sons[0].typ)): 
    localError(n.info, errNotAllCasesCovered)
  closeScope(c.tab)

proc SemReturn(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if c.p.owner.kind notin {skConverter, skMethod, skProc, skMacro}:
    globalError(n.info, errXNotAllowedHere, "\'return\'")
  if n.sons[0].kind != nkEmpty:
    # transform ``return expr`` to ``result = expr; return``
    if c.p.resultSym == nil: globalError(n.info, errNoReturnTypeDeclared)
    var a = newNodeI(nkAsgn, n.sons[0].info)
    addSon(a, newSymNode(c.p.resultSym))
    addSon(a, n.sons[0])
    n.sons[0] = semAsgn(c, a)
    # optimize away ``result = result``:
    if n[0][1].kind == nkSym and n[0][1].sym.kind == skResult: 
      n.sons[0] = ast.emptyNode
  
proc SemYieldVarResult(c: PContext, n: PNode, restype: PType) =
  var t = skipTypes(restype, {tyGenericInst})
  case t.kind
  of tyVar:
    n.sons[0] = takeImplicitAddr(c, n.sons[0])
  of tyTuple:
    for i in 0.. <t.sonsLen:
      var e = skipTypes(t.sons[i], {tyGenericInst})
      if e.kind == tyVar:
        if n.sons[0].kind == nkPar:
          n.sons[0].sons[i] = takeImplicitAddr(c, n.sons[0].sons[i])
        elif n.sons[0].kind in {nkHiddenStdConv, nkHiddenSubConv} and 
             n.sons[0].sons[1].kind == nkPar:
          var a = n.sons[0].sons[1]
          a.sons[i] = takeImplicitAddr(c, a.sons[i])
        else:
          localError(n.sons[0].info, errXExpected, "tuple constructor")
  else: nil
  
proc SemYield(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if c.p.owner == nil or c.p.owner.kind != skIterator: 
    GlobalError(n.info, errYieldNotAllowedHere)
  if n.sons[0].kind != nkEmpty:
    n.sons[0] = SemExprWithType(c, n.sons[0]) # check for type compatibility:
    var restype = c.p.owner.typ.sons[0]
    if restype != nil: 
      n.sons[0] = fitNode(c, restype, n.sons[0])
      if n.sons[0].typ == nil: InternalError(n.info, "semYield")
      SemYieldVarResult(c, n, restype)
    else:
      localError(n.info, errCannotReturnExpr)
  
proc fitRemoveHiddenConv(c: PContext, typ: Ptype, n: PNode): PNode = 
  result = fitNode(c, typ, n)
  if result.kind in {nkHiddenStdConv, nkHiddenSubConv}: 
    changeType(result.sons[1], typ)
    result = result.sons[1]
  elif not sameType(result.typ, typ): 
    changeType(result, typ)

proc findShadowedVar(c: PContext, v: PSym): PSym =
  for i in countdown(c.tab.tos - 2, 0):
    let shadowed = StrTableGet(c.tab.stack[i], v.name)
    if shadowed != nil and shadowed.kind in skLocalVars:
      return shadowed

proc semIdentDef(c: PContext, n: PNode, kind: TSymKind): PSym =
  if isTopLevel(c): 
    result = semIdentWithPragma(c, kind, n, {sfExported})
    incl(result.flags, sfGlobal)
  else: 
    result = semIdentWithPragma(c, kind, n, {})

proc semVarOrLet(c: PContext, n: PNode, symkind: TSymKind): PNode = 
  var b: PNode
  result = copyNode(n)
  for i in countup(0, sonsLen(n)-1): 
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue 
    if a.kind notin {nkIdentDefs, nkVarTuple, nkConstDef}: IllFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    var typ: PType
    if a.sons[length-2].kind != nkEmpty:
      typ = semTypeNode(c, a.sons[length-2], nil)
    else: 
      typ = nil
    var def: PNode
    if a.sons[length-1].kind != nkEmpty: 
      def = semExprWithType(c, a.sons[length-1])
      # BUGFIX: ``fitNode`` is needed here!
      # check type compability between def.typ and typ:
      if typ != nil: def = fitNode(c, typ, def)
      else: typ = skipIntLit(def.typ)
    else:
      def = ast.emptyNode
      if symkind == skLet: GlobalError(a.info, errLetNeedsInit)
      
    # this can only happen for errornous var statements:
    if typ == nil: continue
    if not typeAllowed(typ, symkind): 
      GlobalError(a.info, errXisNoType, typeToString(typ))
    var tup = skipTypes(typ, {tyGenericInst})
    if a.kind == nkVarTuple: 
      if tup.kind != tyTuple: GlobalError(a.info, errXExpected, "tuple")
      if length-2 != sonsLen(tup): 
        GlobalError(a.info, errWrongNumberOfVariables)
      b = newNodeI(nkVarTuple, a.info)
      newSons(b, length)
      b.sons[length-2] = a.sons[length-2] # keep type desc for doc generator
      b.sons[length-1] = def
      addSon(result, b)
    for j in countup(0, length-3):
      var v = semIdentDef(c, a.sons[j], symkind)
      addInterfaceDecl(c, v)
      when oKeepVariableNames:
        if c.InUnrolledContext > 0: v.flags.incl(sfShadowed)
        else:
          let shadowed = findShadowedVar(c, v)
          if shadowed != nil: shadowed.flags.incl(sfShadowed)
      if def != nil and def.kind != nkEmpty:
        # this is only needed for the evaluation pass:
        v.ast = def
        if sfThread in v.flags: LocalError(def.info, errThreadvarCannotInit)
      if a.kind != nkVarTuple:
        v.typ = typ
        b = newNodeI(nkIdentDefs, a.info)
        addSon(b, newSymNode(v))
        addSon(b, a.sons[length-2])      # keep type desc for doc generator
        addSon(b, copyTree(def))
        addSon(result, b)
      else: 
        v.typ = tup.sons[j]
        b.sons[j] = newSymNode(v)
    
proc semConst(c: PContext, n: PNode): PNode = 
  result = copyNode(n)
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkConstDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    var v = semIdentDef(c, a.sons[0], skConst)
    var typ: PType = nil
    if a.sons[1].kind != nkEmpty: typ = semTypeNode(c, a.sons[1], nil)

    when true:
      var def = semConstExpr(c, a.sons[2])
      if def == nil: GlobalError(a.sons[2].info, errConstExprExpected)
      # check type compatibility between def.typ and typ:
      if typ != nil:
        def = fitRemoveHiddenConv(c, typ, def)
      else:
        typ = def.typ
      if not typeAllowed(typ, skConst):
        GlobalError(a.info, errXisNoType, typeToString(typ))
    else:
      var e = semExprWithType(c, a.sons[2])
      if e == nil: GlobalError(a.sons[2].info, errConstExprExpected)
      var def = getConstExpr(c.module, e)
      if def == nil: 
        v.flags.incl(sfFakeConst)
        def = evalConstExpr(c.module, e)
        if def == nil or def.kind == nkEmpty: def = e
      # check type compatibility between def.typ and typ:
      if typ != nil:
        def = fitRemoveHiddenConv(c, typ, def)
      else:
        typ = def.typ
      if not typeAllowed(typ, skConst):
        v.flags.incl(sfFakeConst)
        if not typeAllowed(typ, skVar):
          GlobalError(a.info, errXisNoType, typeToString(typ))
    v.typ = typ
    v.ast = def               # no need to copy
    addInterfaceDecl(c, v)
    var b = newNodeI(nkConstDef, a.info)
    addSon(b, newSymNode(v))
    addSon(b, ast.emptyNode)            # no type description
    addSon(b, copyTree(def))
    addSon(result, b)

proc transfFieldLoopBody(n: PNode, forLoop: PNode,
                         tupleType: PType,
                         tupleIndex, first: int): PNode = 
  case n.kind
  of nkEmpty..pred(nkIdent), succ(nkIdent)..nkNilLit: result = n
  of nkIdent:
    result = n
    var L = sonsLen(forLoop)
    # field name:
    if first > 0:
      if n.ident.id == forLoop[0].ident.id:
        if tupleType.n == nil: 
          # ugh, there are no field names:
          result = newStrNode(nkStrLit, "")
        else:
          result = newStrNode(nkStrLit, tupleType.n.sons[tupleIndex].sym.name.s)
        return
    # other fields:
    for i in first..L-3:
      if n.ident.id == forLoop[i].ident.id:
        var call = forLoop.sons[L-2]
        var tupl = call.sons[i+1-first]
        result = newNodeI(nkBracketExpr, n.info)
        result.add(tupl)
        result.add(newIntNode(nkIntLit, tupleIndex))
        break
  else:
    result = copyNode(n)
    newSons(result, sonsLen(n))
    for i in countup(0, sonsLen(n)-1):
      result.sons[i] = transfFieldLoopBody(n.sons[i], forLoop,
                                           tupleType, tupleIndex, first)

proc semForFields(c: PContext, n: PNode, m: TMagic): PNode = 
  # so that 'break' etc. work as expected, we produce 
  # a 'while true: stmt; break' loop ...
  result = newNodeI(nkWhileStmt, n.info)
  var trueSymbol = StrTableGet(magicsys.systemModule.Tab, getIdent"true")
  if trueSymbol == nil: GlobalError(n.info, errSystemNeeds, "true")

  result.add(newSymNode(trueSymbol, n.info))
  var stmts = newNodeI(nkStmtList, n.info)
  result.add(stmts)
  
  var length = sonsLen(n)
  var call = n.sons[length-2]
  if length-2 != sonsLen(call)-1 + ord(m==mFieldPairs):
    GlobalError(n.info, errWrongNumberOfVariables)
  
  var tupleTypeA = skipTypes(call.sons[1].typ, abstractVar)
  if tupleTypeA.kind != tyTuple: InternalError(n.info, "no tuple type!")
  for i in 1..call.len-1:
    var tupleTypeB = skipTypes(call.sons[i].typ, abstractVar)
    if not SameType(tupleTypeA, tupleTypeB):
      typeMismatch(call.sons[i], tupleTypeA, tupleTypeB)
  
  Inc(c.p.nestedLoopCounter)
  var loopBody = n.sons[length-1]
  for i in 0..sonsLen(tupleTypeA)-1:
    openScope(c.tab)
    var body = transfFieldLoopBody(loopBody, n, tupleTypeA, i,
                                   ord(m==mFieldPairs))
    inc c.InUnrolledContext
    stmts.add(SemStmt(c, body))
    dec c.InUnrolledContext
    closeScope(c.tab)
  Dec(c.p.nestedLoopCounter)
  var b = newNodeI(nkBreakStmt, n.info)
  b.add(ast.emptyNode)
  stmts.add(b)

proc semForVars(c: PContext, n: PNode): PNode =
  result = n
  var length = sonsLen(n)
  var iter = skipTypes(n.sons[length-2].typ, {tyGenericInst})
  # length == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if iter.kind != tyTuple or length == 3: 
    if length != 3: GlobalError(n.info, errWrongNumberOfVariables)
    var v = newSymS(skForVar, n.sons[0], c)
    if getCurrOwner().kind == skModule: incl(v.flags, sfGlobal)
    # BUGFIX: don't use `iter` here as that would strip away
    # the ``tyGenericInst``! See ``tests/compile/tgeneric.nim``
    # for an example:
    v.typ = n.sons[length-2].typ
    n.sons[0] = newSymNode(v)
    addDecl(c, v)
  else: 
    if length-2 != sonsLen(iter):
      GlobalError(n.info, errWrongNumberOfVariables)
    for i in countup(0, length - 3): 
      var v = newSymS(skForVar, n.sons[i], c)
      if getCurrOwner().kind == skModule: incl(v.flags, sfGlobal)
      v.typ = iter.sons[i]
      n.sons[i] = newSymNode(v)
      addDecl(c, v)
  Inc(c.p.nestedLoopCounter)
  n.sons[length-1] = SemStmt(c, n.sons[length-1])
  Dec(c.p.nestedLoopCounter)

proc implicitIterator(c: PContext, it: string, arg: PNode): PNode =
  result = newNodeI(nkCall, arg.info)
  result.add(newIdentNode(it.getIdent, arg.info))
  result.add(arg)
  result = semExprNoDeref(c, result, {efWantIterator})

proc semFor(c: PContext, n: PNode): PNode = 
  result = n
  checkMinSonsLen(n, 3)
  var length = sonsLen(n)
  openScope(c.tab)
  n.sons[length-2] = semExprNoDeref(c, n.sons[length-2], {efWantIterator})
  var call = n.sons[length-2]
  if call.kind notin nkCallKinds or call.sons[0].kind != nkSym or
      call.sons[0].sym.kind != skIterator: 
    if length == 3:
      n.sons[length-2] = implicitIterator(c, "items", n.sons[length-2])
      result = semForVars(c, n)
    elif length == 4:
      n.sons[length-2] = implicitIterator(c, "pairs", n.sons[length-2])
      result = semForVars(c, n)
    else:
      GlobalError(n.sons[length - 2].info, errIteratorExpected)
  elif call.sons[0].sym.magic != mNone:
    if call.sons[0].sym.magic == mOmpParFor:
      result = semForVars(c, n)
      result.kind = nkParForStmt
    else:
      result = semForFields(c, n, call.sons[0].sym.magic)
  else:
    result = semForVars(c, n)
  closeScope(c.tab)

proc semRaise(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty: 
    n.sons[0] = semExprWithType(c, n.sons[0])
    var typ = n.sons[0].typ
    if typ.kind != tyRef or typ.sons[0].kind != tyObject: 
      localError(n.info, errExprCannotBeRaised)

proc semTry(c: PContext, n: PNode): PNode = 
  result = n
  checkMinSonsLen(n, 2)
  n.sons[0] = semStmtScope(c, n.sons[0])
  var check = initIntSet()
  for i in countup(1, sonsLen(n) - 1): 
    var a = n.sons[i]
    checkMinSonsLen(a, 1)
    var length = sonsLen(a)
    if a.kind == nkExceptBranch:
      if length == 2 and a.sons[0].kind == nkBracket:
        a.sons[0..0] = a.sons[0].sons
        length = a.sonsLen

      for j in countup(0, length - 2):
        var typ = semTypeNode(c, a.sons[j], nil)
        if typ.kind == tyRef: typ = typ.sons[0]
        if typ.kind != tyObject:
          GlobalError(a.sons[j].info, errExprCannotBeRaised)
        a.sons[j] = newNodeI(nkType, a.sons[j].info)
        a.sons[j].typ = typ
        if ContainsOrIncl(check, typ.id):
          localError(a.sons[j].info, errExceptionAlreadyHandled)
    elif a.kind != nkFinally: 
      illFormedAst(n) 
    # last child of an nkExcept/nkFinally branch is a statement:
    a.sons[length - 1] = semStmtScope(c, a.sons[length - 1])

proc addGenericParamListToScope(c: PContext, n: PNode) = 
  if n.kind != nkGenericParams: 
    InternalError(n.info, "addGenericParamListToScope")
  for i in countup(0, sonsLen(n)-1): 
    var a = n.sons[i]
    if a.kind != nkSym: internalError(a.info, "addGenericParamListToScope")
    addDecl(c, a.sym)

proc typeSectionLeftSidePass(c: PContext, n: PNode) = 
  # process the symbols on the left side for the whole type section, before
  # we even look at the type definitions on the right
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue 
    if a.kind != nkTypeDef: IllFormedAst(a)
    checkSonsLen(a, 3)
    var s = semIdentDef(c, a.sons[0], skType)
    s.typ = newTypeS(tyForward, c)
    s.typ.sym = s             # process pragmas:
    if a.sons[0].kind == nkPragmaExpr:
      pragma(c, s, a.sons[0].sons[1], typePragmas)
    # add it here, so that recursive types are possible:
    addInterfaceDecl(c, s)
    a.sons[0] = newSymNode(s)

proc typeSectionRightSidePass(c: PContext, n: PNode) =
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkTypeDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    if (a.sons[0].kind != nkSym): IllFormedAst(a)
    var s = a.sons[0].sym
    if s.magic == mNone and a.sons[2].kind == nkEmpty: 
      GlobalError(a.info, errImplOfXexpected, s.name.s)
    if s.magic != mNone: processMagicType(c, s)
    if a.sons[1].kind != nkEmpty: 
      # We have a generic type declaration here. In generic types,
      # symbol lookup needs to be done here.
      openScope(c.tab)
      pushOwner(s)
      if s.magic == mNone: s.typ.kind = tyGenericBody
      if s.typ.containerID != 0: 
        InternalError(a.info, "semTypeSection: containerID")
      s.typ.containerID = s.typ.id
      # XXX for generic type aliases this is not correct! We need the
      # underlying Id really: 
      #
      # type
      #   TGObj[T] = object
      #   TAlias[T] = TGObj[T]
      # 
      a.sons[1] = semGenericParamList(c, a.sons[1], s.typ)
      s.typ.size = -1 # could not be computed properly
      # we fill it out later. For magic generics like 'seq', it won't be filled
      # so we use tyEmpty instead of nil to not crash for strange conversions
      # like: mydata.seq
      rawAddSon(s.typ, newTypeS(tyEmpty, c))
      s.ast = a
      inc c.InGenericContext
      var body = semTypeNode(c, a.sons[2], nil)
      dec c.InGenericContext
      if body != nil:
        body.sym = s
        body.size = -1 # could not be computed properly
      s.typ.sons[sonsLen(s.typ) - 1] = body
      popOwner()
      closeScope(c.tab)
    elif a.sons[2].kind != nkEmpty: 
      # process the type's body:
      pushOwner(s)
      var t = semTypeNode(c, a.sons[2], s.typ)
      if s.typ == nil: 
        s.typ = t
      elif t != s.typ: 
        # this can happen for e.g. tcan_alias_specialised_generic:
        assignType(s.typ, t)
        #debug s.typ
      s.ast = a
      popOwner()

proc typeSectionFinalPass(c: PContext, n: PNode) = 
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if a.sons[0].kind != nkSym: IllFormedAst(a)
    var s = a.sons[0].sym
    # compute the type's size and check for illegal recursions:
    if a.sons[1].kind == nkEmpty: 
      if a.sons[2].kind in {nkSym, nkIdent, nkAccQuoted}:
        # type aliases are hard:
        #MessageOut('for type ' + typeToString(s.typ));
        var t = semTypeNode(c, a.sons[2], nil)
        if t.kind in {tyObject, tyEnum}: 
          assignType(s.typ, t)
          s.typ.id = t.id     # same id
      checkConstructedType(s.info, s.typ)
    let aa = a.sons[2]
    if aa.kind in {nkRefTy, nkPtrTy} and aa.len == 1 and
       aa.sons[0].kind == nkObjectTy:
      # give anonymous object a dummy symbol:
      assert s.typ.sons[0].sym == nil
      var anonObj = newSym(skType, getIdent(s.name.s & ":ObjectType"), 
                                 getCurrOwner())
      anonObj.info = s.info
      s.typ.sons[0].sym = anonObj

proc SemTypeSection(c: PContext, n: PNode): PNode =
  typeSectionLeftSidePass(c, n)
  typeSectionRightSidePass(c, n)
  typeSectionFinalPass(c, n)
  result = n

proc semParamList(c: PContext, n, genericParams: PNode, s: PSym) =
  s.typ = semProcTypeNode(c, n, genericParams, nil, s.kind)

proc addParams(c: PContext, n: PNode, kind: TSymKind) = 
  for i in countup(1, sonsLen(n)-1): 
    if (n.sons[i].kind != nkSym): InternalError(n.info, "addParams")
    addParamOrResult(c, n.sons[i].sym, kind)

proc semBorrow(c: PContext, n: PNode, s: PSym) = 
  # search for the correct alias:
  var b = SearchForBorrowProc(c, s, c.tab.tos - 2)
  if b != nil: 
    # store the alias:
    n.sons[bodyPos] = newSymNode(b)
  else:
    LocalError(n.info, errNoSymbolToBorrowFromFound) 
  
proc addResult(c: PContext, t: PType, info: TLineInfo, owner: TSymKind) = 
  if t != nil: 
    var s = newSym(skResult, getIdent"result", getCurrOwner())
    s.info = info
    s.typ = t
    incl(s.flags, sfUsed)
    addParamOrResult(c, s, owner)
    c.p.resultSym = s

proc addResultNode(c: PContext, n: PNode) = 
  if c.p.resultSym != nil: addSon(n, newSymNode(c.p.resultSym))

proc copyExcept(n: PNode, i: int): PNode =
  result = copyNode(n)
  for j in 0.. <n.len:
    if j != i: result.add(n.sons[j])

proc lookupMacro(c: PContext, n: PNode): PSym =
  if n.kind == nkSym:
    result = n.sym
    if result.kind notin {skMacro, skTemplate}: result = nil
  else:
    result = SymtabGet(c.Tab, considerAcc(n), {skMacro, skTemplate})

proc semProcAnnotation(c: PContext, prc: PNode): PNode =
  var n = prc.sons[pragmasPos]
  if n == nil or n.kind == nkEmpty: return
  for i in countup(0, <n.len):
    var it = n.sons[i]
    var key = if it.kind == nkExprColonExpr: it.sons[0] else: it
    let m = lookupMacro(c, key)
    if m == nil: continue
    # we transform ``proc p {.m, rest.}`` into ``m: proc p {.rest.}`` and
    # let the semantic checker deal with it:
    var x = newNodeI(nkMacroStmt, n.info)
    x.add(newSymNode(m))
    prc.sons[pragmasPos] = copyExcept(n, i)
    if it.kind == nkExprColonExpr:
      # pass pragma argument to the macro too:
      x.add(it.sons[1])
    x.add(prc)
    # recursion assures that this works for multiple macro annotations too:
    return semStmt(c, x)
  
proc semLambda(c: PContext, n: PNode): PNode = 
  result = semProcAnnotation(c, n)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s = newSym(skProc, getIdent":anonymous", getCurrOwner())
  s.info = n.info
  s.ast = n
  n.sons[namePos] = newSymNode(s)
  pushOwner(s)
  openScope(c.tab)
  if n.sons[genericParamsPos].kind != nkEmpty:
    illFormedAst(n)           # process parameters:
  if n.sons[paramsPos].kind != nkEmpty: 
    semParamList(c, n.sons[ParamsPos], nil, s)
    ParamsTypeCheck(c, s.typ)
  else:
    s.typ = newTypeS(tyProc, c)
    rawAddSon(s.typ, nil)
  if n.sons[pragmasPos].kind != nkEmpty:
    pragma(c, s, n.sons[pragmasPos], lambdaPragmas)
  s.options = gOptions
  if n.sons[bodyPos].kind != nkEmpty: 
    if sfImportc in s.flags: 
      LocalError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    pushProcCon(c, s)
    addResult(c, s.typ.sons[0], n.info, skProc)
    n.sons[bodyPos] = semStmtScope(c, n.sons[bodyPos])
    addResultNode(c, n)
    popProcCon(c)
  else: 
    LocalError(n.info, errImplOfXexpected, s.name.s)
  sideEffectsCheck(c, s)
  if s.typ.callConv == ccClosure and s.owner.kind == skModule:
    localError(s.info, errXCannotBeClosure, s.name.s)
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  result.typ = s.typ
 
proc instantiateDestructor*(c: PContext, typ: PType): bool

proc semProcAux(c: PContext, n: PNode, kind: TSymKind, 
                validPragmas: TSpecialWords): PNode = 
  result = semProcAnnotation(c, n)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s = semIdentDef(c, n.sons[0], kind)
  n.sons[namePos] = newSymNode(s)
  s.ast = n
  pushOwner(s)
  openScope(c.tab)
  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty: 
    n.sons[genericParamsPos] = semGenericParamList(c, n.sons[genericParamsPos])
    gp = n.sons[genericParamsPos]
  else: 
    gp = newNodeI(nkGenericParams, n.info)
  # process parameters:
  if n.sons[paramsPos].kind != nkEmpty:
    semParamList(c, n.sons[ParamsPos], gp, s)
    if sonsLen(gp) > 0: 
      if n.sons[genericParamsPos].kind == nkEmpty:
        # we have a list of implicit type parameters:
        n.sons[genericParamsPos] = gp
        # check for semantics again:
        # semParamList(c, n.sons[ParamsPos], nil, s)
  else: 
    s.typ = newTypeS(tyProc, c)
    rawAddSon(s.typ, nil)
  var proto = SearchForProc(c, s, c.tab.tos-2) # -2 because we have a scope
                                               # open for parameters
  if proto == nil: 
    s.typ.callConv = lastOptionEntry(c).defaultCC 
    # add it here, so that recursive procs are possible:
    # -2 because we have a scope open for parameters
    if kind in OverloadableSyms: 
      addInterfaceOverloadableSymAt(c, s, c.tab.tos - 2)
    else: 
      addInterfaceDeclAt(c, s, c.tab.tos - 2)
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, s, n.sons[pragmasPos], validPragmas)
  else: 
    if n.sons[pragmasPos].kind != nkEmpty: 
      LocalError(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProc)
    if sfForward notin proto.flags: 
      LocalError(n.info, errAttemptToRedefine, proto.name.s)
    excl(proto.flags, sfForward)
    closeScope(c.tab)         # close scope with wrong parameter symbols
    openScope(c.tab)          # open scope for old (correct) parameter symbols
    if proto.ast.sons[genericParamsPos].kind != nkEmpty: 
      addGenericParamListToScope(c, proto.ast.sons[genericParamsPos])
    addParams(c, proto.typ.n, proto.kind)
    proto.info = s.info       # more accurate line information
    s.typ = proto.typ
    s = proto
    n.sons[genericParamsPos] = proto.ast.sons[genericParamsPos]
    n.sons[paramsPos] = proto.ast.sons[paramsPos]
    if n.sons[namePos].kind != nkSym: InternalError(n.info, "semProcAux")
    n.sons[namePos].sym = proto
    proto.ast = n             # needed for code generation
    popOwner()
    pushOwner(s)
  s.options = gOptions
  if sfDestructor in s.flags:
    let t = s.typ.sons[1].skipTypes({tyVar})
    t.destructor = s
    # automatically insert calls to base classes' destructors
    if n.sons[bodyPos].kind != nkEmpty:
      for i in countup(0, t.sonsLen - 1):
        # when inheriting directly from object
        # there will be a single nil son
        if t.sons[i] == nil: continue
        if instantiateDestructor(c, t.sons[i]):
          n.sons[bodyPos].addSon(newNode(nkCall, t.sym.info, @[
              useSym(t.sons[i].destructor),
              n.sons[paramsPos][1][0]]))
  if n.sons[bodyPos].kind != nkEmpty: 
    # for DLL generation it is annoying to check for sfImportc!
    if sfBorrow in s.flags: 
      LocalError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    if n.sons[genericParamsPos].kind == nkEmpty: 
      ParamsTypeCheck(c, s.typ)
      pushProcCon(c, s)
      if s.typ.sons[0] != nil and kind != skIterator: 
        addResult(c, s.typ.sons[0], n.info, kind)
      if sfImportc notin s.flags:
        # no semantic checking for importc:
        n.sons[bodyPos] = semStmtScope(c, n.sons[bodyPos])
      if s.typ.sons[0] != nil and kind != skIterator: addResultNode(c, n)
      popProcCon(c)
    else: 
      if s.typ.sons[0] != nil and kind != skIterator:
        addDecl(c, newSym(skUnknown, getIdent"result", nil))
      var toBind = initIntSet()
      n.sons[bodyPos] = semGenericStmtScope(c, n.sons[bodyPos], {}, toBind)
      fixupInstantiatedSymbols(c, s)
    if sfImportc in s.flags: 
      # so we just ignore the body after semantic checking for importc:
      n.sons[bodyPos] = ast.emptyNode
  else: 
    if proto != nil: LocalError(n.info, errImplOfXexpected, proto.name.s)
    if {sfImportc, sfBorrow} * s.flags == {} and s.magic == mNone: 
      incl(s.flags, sfForward)
    elif sfBorrow in s.flags: semBorrow(c, n, s)
  sideEffectsCheck(c, s)
  if s.typ.callConv == ccClosure and s.owner.kind == skModule:
    localError(s.info, errXCannotBeClosure, s.name.s)
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  
proc semIterator(c: PContext, n: PNode): PNode = 
  result = semProcAux(c, n, skIterator, iteratorPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: 
    LocalError(n.info, errXNeedsReturnType, "iterator")
  if n.sons[bodyPos].kind == nkEmpty and s.magic == mNone: 
    LocalError(n.info, errImplOfXexpected, s.name.s)
  
proc semProc(c: PContext, n: PNode): PNode = 
  result = semProcAux(c, n, skProc, procPragmas)

proc semMethod(c: PContext, n: PNode): PNode = 
  if not isTopLevel(c): LocalError(n.info, errXOnlyAtModuleScope, "method")
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
    LocalError(n.info, errXNeedsParamObjectType, "method")

proc semConverterDef(c: PContext, n: PNode): PNode = 
  if not isTopLevel(c): LocalError(n.info, errXOnlyAtModuleScope, "converter")
  checkSonsLen(n, bodyPos + 1)
  if n.sons[genericParamsPos].kind != nkEmpty: 
    LocalError(n.info, errNoGenericParamsAllowedForX, "converter")
  result = semProcAux(c, n, skConverter, converterPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: LocalError(n.info, errXNeedsReturnType, "converter")
  if sonsLen(t) != 2: LocalError(n.info, errXRequiresOneArgument, "converter")
  addConverter(c, s)

proc semMacroDef(c: PContext, n: PNode): PNode = 
  checkSonsLen(n, bodyPos + 1)
  if n.sons[genericParamsPos].kind != nkEmpty: 
    LocalError(n.info, errNoGenericParamsAllowedForX, "macro")
  result = semProcAux(c, n, skMacro, macroPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: LocalError(n.info, errXNeedsReturnType, "macro")
  if sonsLen(t) != 2: LocalError(n.info, errXRequiresOneArgument, "macro")
  if n.sons[bodyPos].kind == nkEmpty:
    LocalError(n.info, errImplOfXexpected, s.name.s)
  
proc evalInclude(c: PContext, n: PNode): PNode = 
  result = newNodeI(nkStmtList, n.info)
  addSon(result, n)
  for i in countup(0, sonsLen(n) - 1): 
    var f = checkModuleName(n.sons[i])
    var fileIndex = f.fileInfoIdx
    if ContainsOrIncl(c.includedFiles, fileIndex): 
      GlobalError(n.info, errRecursiveDependencyX, f.extractFilename)
    addSon(result, semStmt(c, gIncludeFile(f)))
    Excl(c.includedFiles, fileIndex)
  
proc setLine(n: PNode, info: TLineInfo) =
  for i in 0 .. <safeLen(n): setLine(n.sons[i], info)
  n.info = info
  
proc semPragmaBlock(c: PContext, n: PNode): PNode =
  let pragmaList = n.sons[0]
  pragma(c, nil, pragmaList, exprPragmas)
  result = semStmt(c, n.sons[1])
  for i in 0 .. <pragmaList.len:
    if whichPragma(pragmaList.sons[i]) == wLine:
      setLine(result, pragmaList.sons[i].info)

proc semStaticStmt(c: PContext, n: PNode): PNode =
  let a = semStmt(c, n.sons[0])
  result = evalStaticExpr(c.module, a)
  if result.isNil:
    LocalError(n.info, errCannotInterpretNodeX, renderTree(n))

# special marker values that indicates that we are
# 1) AnalyzingDestructor: currenlty analyzing the type for destructor 
# generation (needed for recursive types)
# 2) DestructorIsTrivial: completed the anlysis before and determined
# that the type has a trivial destructor
var AnalyzingDestructor, DestructorIsTrivial: PSym
new(AnalyzingDestructor)
new(DestructorIsTrivial)

var
  destructorName = getIdent"destroy_"
  destructorParam = getIdent"this_"
  destructorPragma = newIdentNode(getIdent"destructor", UnknownLineInfo())
  rangeDestructorProc: PSym

proc destroyField(c: PContext, field: PSym, holder: PNode): PNode =
  if instantiateDestructor(c, field.typ):
    result = newNode(nkCall, field.info, @[
      useSym(field.typ.destructor),
      newNode(nkDotExpr, field.info, @[holder, useSym(field)])])

proc destroyCase(c: PContext, n: PNode, holder: PNode): PNode =
  var nonTrivialFields = 0
  result = newNode(nkCaseStmt, n.info, @[])
  # case x.kind
  result.addSon(newNode(nkDotExpr, n.info, @[holder, n.sons[0]]))
  for i in countup(1, n.len - 1):
    # of A, B:
    var caseBranch = newNode(n[i].kind, n[i].info, n[i].sons[0 .. -2])
    let recList = n[i].lastSon
    var destroyRecList = newNode(nkStmtList, n[i].info, @[])
    template addField(f: expr): stmt =
      let stmt = destroyField(c, f, holder)
      if stmt != nil:
        destroyRecList.addSon(stmt)
        inc nonTrivialFields
        
    case recList.kind
    of nkSym:
      addField(recList.sym)
    of nkRecList:
      for j in countup(0, recList.len - 1):
        addField(recList[j].sym)
    else:
      internalAssert false
      
    caseBranch.addSon(destroyRecList)
    result.addSon(caseBranch)
  # maybe no fields were destroyed?
  if nonTrivialFields == 0:
    result = nil
 
proc generateDestructor(c: PContext, t: PType): PNode =
  ## generate a destructor for a user-defined object ot tuple type
  ## returns nil if the destructor turns out to be trivial
  
  template addLine(e: expr): stmt =
    if result == nil: result = newNode(nkStmtList)
    result.addSon(e)

  # XXX: This may be true for some C-imported types such as
  # Tposix_spawnattr
  if t.n == nil or t.n.sons == nil: return
  internalAssert t.n.kind == nkRecList
  let destructedObj = newIdentNode(destructorParam, UnknownLineInfo())
  # call the destructods of all fields
  for s in countup(0, t.n.sons.len - 1):
    case t.n.sons[s].kind
    of nkRecCase:
      let stmt = destroyCase(c, t.n.sons[s], destructedObj)
      if stmt != nil: addLine(stmt)
    of nkSym:
      let stmt = destroyField(c, t.n.sons[s].sym, destructedObj)
      if stmt != nil: addLine(stmt)
    else:
      internalAssert false

  # base classes' destructors will be automatically called by
  # semProcAux for both auto-generated and user-defined destructors

proc instantiateDestructor*(c: PContext, typ: PType): bool =
  # returns true if the type already had a user-defined
  # destructor or if the compiler generated a default
  # member-wise one
  var t = skipTypes(typ, {tyConst, tyMutable})
  
  if t.destructor != nil:
    # XXX: This is not entirely correct for recursive types, but we need
    # it temporarily to hide the "destroy is alrady defined" problem
    return t.destructor notin [AnalyzingDestructor, DestructorIsTrivial]
  
  case t.kind
  of tySequence, tyArray, tyArrayConstr, tyOpenArray:
    if instantiateDestructor(c, t.sons[0]):
      if rangeDestructorProc == nil:
        rangeDestructorProc = SymtabGet(c.tab, getIdent"nimDestroyRange")
      t.destructor = rangeDestructorProc
      return true
    else:
      return false
  of tyTuple, tyObject:
    t.destructor = AnalyzingDestructor
    let generated = generateDestructor(c, t)
    if generated != nil:
      internalAssert t.sym != nil
      var i = t.sym.info
      let fullDef = newNode(nkProcDef, i, @[
        newIdentNode(destructorName, i),
        emptyNode,
        newNode(nkFormalParams, i, @[
          emptyNode,
          newNode(nkIdentDefs, i, @[
            newIdentNode(destructorParam, i),
            useSym(t.sym),
            emptyNode]),
          ]),
        newNode(nkPragma, i, @[destructorPragma]),
        generated
        ])
      discard semProc(c, fullDef)
      internalAssert t.destructor != nil
      return true
    else:
      t.destructor = DestructorIsTrivial
      return false
  else:
    return false

proc insertDestructors(c: PContext, varSection: PNode):
  tuple[outer: PNode, inner: PNode] =
  # Accepts a var or let section.
  #
  # When a var section has variables with destructors
  # the var section is split up and finally blocks are inserted
  # immediately after all "destructable" vars
  #
  # In case there were no destrucable variables, the proc returns
  # (nil, nil) and the enclosing stmt-list requires no modifications.
  #
  # Otherwise, after the try blocks are created, the rest of the enclosing
  # stmt-list should be inserted in the most `inner` such block (corresponding
  # to the last variable).
  #
  # `outer` is a statement list that should replace the original var section.
  # It will include the new truncated var section followed by the outermost
  # try block.
  let totalVars = varSection.sonsLen
  for j in countup(0, totalVars - 1):
    let
      varId = varSection[j][0]
      varTyp = varId.sym.typ
      info = varId.info

    if varTyp != nil and instantiateDestructor(c, varTyp):
      var tryStmt = newNodeI(nkTryStmt, info)

      if j < totalVars - 1:
        var remainingVars = newNodeI(varSection.kind, info)
        remainingVars.sons = varSection.sons[(j+1)..(-1)]
        let (outer, inner) = insertDestructors(c, remainingVars)
        if outer != nil:
          tryStmt.addSon(outer)
          result.inner = inner
        else:
          result.inner = newNodeI(nkStmtList, info)
          result.inner.addSon(remainingVars)
          tryStmt.addSon(result.inner)
      else:
        result.inner = newNodeI(nkStmtList, info)
        tryStmt.addSon(result.inner)

      tryStmt.addSon(
        newNode(nkFinally, info, @[
          semStmt(c, newNode(nkCall, info, @[
            useSym(varTyp.destructor),
            useSym(varId.sym)]))]))

      result.outer = newNodeI(nkStmtList, info)
      varSection.sons.setLen(j+1)
      result.outer.addSon(varSection)
      result.outer.addSon(tryStmt)

      return

proc SemStmt(c: PContext, n: PNode): PNode = 
  const                       # must be last statements in a block:
    LastBlockStmts = {nkRaiseStmt, nkReturnStmt, nkBreakStmt, nkContinueStmt}
  result = n
  if gCmd == cmdIdeTools: 
    suggestStmt(c, n)
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
      case n.sons[i].kind
      of nkFinally, nkExceptBranch:
        # stand-alone finally and except blocks are
        # transformed into regular try blocks:
        #
        # var f = fopen("somefile") | var f = fopen("somefile")
        # finally: fclose(f)        | try:
        # ...                       |   ...
        #                           | finally:
        #                           |   fclose(f)
        var tryStmt = newNodeI(nkTryStmt, n.sons[i].info)
        var body = newNodeI(nkStmtList, n.sons[i].info)
        if i < n.sonsLen - 1:
          body.sons = n.sons[(i+1)..(-1)]
        tryStmt.addSon(body)
        tryStmt.addSon(n.sons[i])
        n.sons[i] = semTry(c, tryStmt)
        n.sons.setLen(i+1)
        return
      else:
        n.sons[i] = semStmt(c, n.sons[i])
        case n.sons[i].kind
        of nkVarSection, nkLetSection:
          let (outer, inner) = insertDestructors(c, n.sons[i])
          if outer != nil:
            n.sons[i] = outer
            for j in countup(i+1, length-1):
              inner.addSon(SemStmt(c, n.sons[j]))
            n.sons.setLen(i+1)
            return
        of LastBlockStmts: 
          for j in countup(i + 1, length - 1): 
            case n.sons[j].kind
            of nkPragma, nkCommentStmt, nkNilLit, nkEmpty: nil
            else: localError(n.sons[j].info, errStmtInvalidAfterReturn)
        else: nil
  of nkRaiseStmt: result = semRaise(c, n)
  of nkVarSection: result = semVarOrLet(c, n, skVar)
  of nkLetSection: result = semVarOrLet(c, n, skLet)
  of nkConstSection: result = semConst(c, n)
  of nkTypeSection: result = SemTypeSection(c, n)
  of nkIfStmt: result = SemIf(c, n)
  of nkWhenStmt: result = semWhen(c, n)
  of nkDiscardStmt: result = semDiscard(c, n)
  of nkWhileStmt: result = semWhile(c, n)
  of nkTryStmt: result = semTry(c, n)
  of nkBreakStmt, nkContinueStmt: result = semBreakOrContinue(c, n)
  of nkForStmt, nkParForStmt: result = semFor(c, n)
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
    if not isTopLevel(c): LocalError(n.info, errXOnlyAtModuleScope, "import")
    result = evalImport(c, n)
  of nkFromStmt: 
    if not isTopLevel(c): LocalError(n.info, errXOnlyAtModuleScope, "from")
    result = evalFrom(c, n)
  of nkIncludeStmt: 
    if not isTopLevel(c): LocalError(n.info, errXOnlyAtModuleScope, "include")
    result = evalInclude(c, n)
  of nkPragmaBlock:
    result = semPragmaBlock(c, n)
  of nkStaticStmt:
    result = semStaticStmt(c, n)
  else: 
    # in interactive mode, we embed the expression in an 'echo':
    if gCmd == cmdInteractive:
      result = buildEchoStmt(c, semExpr(c, n))
    else:
      result = semExprNoType(c, n)
      #LocalError(n.info, errStmtExpected)
      #result = ast.emptyNode
  if result == nil: InternalError(n.info, "SemStmt: result = nil")
  incl(result.flags, nfSem)

proc semStmtScope(c: PContext, n: PNode): PNode = 
  openScope(c.tab)
  result = semStmt(c, n)
  closeScope(c.tab)
