#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## this module does the semantic checking of statements
#  included from sem.nim

var enforceVoidContext = PType(kind: tyStmt)

proc semDiscard(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty:
    n.sons[0] = semExprWithType(c, n.sons[0])
    if isEmptyType(n.sons[0].typ): localError(n.info, errInvalidDiscard)

proc semBreakOrContinue(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty:
    if n.kind != nkContinueStmt:
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
        suggestSym(x.info, s)
        styleCheckUse(x.info, s)
      else:
        localError(n.info, errInvalidControlFlowX, s.name.s)
    else:
      localError(n.info, errGenerated, "'continue' cannot have a label")
  elif (c.p.nestedLoopCounter <= 0) and (c.p.nestedBlockCounter <= 0):
    localError(n.info, errInvalidControlFlowX,
               renderTree(n, {renderNoComments}))

proc semAsm(con: PContext, n: PNode): PNode =
  checkSonsLen(n, 2)
  var marker = pragmaAsm(con, n.sons[0])
  if marker == '\0': marker = '`' # default marker
  result = semAsmOrEmit(con, n, marker)

proc semWhile(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 2)
  openScope(c)
  n.sons[0] = forceBool(c, semExprWithType(c, n.sons[0]))
  inc(c.p.nestedLoopCounter)
  n.sons[1] = semStmt(c, n.sons[1])
  dec(c.p.nestedLoopCounter)
  closeScope(c)
  if n.sons[1].typ == enforceVoidContext:
    result.typ = enforceVoidContext

proc toCover(t: PType): BiggestInt =
  var t2 = skipTypes(t, abstractVarRange-{tyTypeDesc})
  if t2.kind == tyEnum and enumHasHoles(t2):
    result = sonsLen(t2.n)
  else:
    result = lengthOrd(skipTypes(t, abstractVar-{tyTypeDesc}))

proc performProcvarCheck(c: PContext, n: PNode, s: PSym) =
  ## Checks that the given symbol is a proper procedure variable, meaning
  ## that it
  var smoduleId = getModule(s).id
  if sfProcvar notin s.flags and s.typ.callConv == ccDefault and
      smoduleId != c.module.id:
    block outer:
      for module in c.friendModules:
        if smoduleId == module.id:
          break outer
      localError(n.info, errXCannotBePassedToProcVar, s.name.s)

proc semProcvarCheck(c: PContext, n: PNode) =
  let n = n.skipConv
  if n.kind == nkSym and n.sym.kind in {skProc, skMethod, skConverter,
                                        skIterator, skClosureIterator}:
    performProcvarCheck(c, n, n.sym)

proc semProc(c: PContext, n: PNode): PNode

include semdestruct

proc semDestructorCheck(c: PContext, n: PNode, flags: TExprFlags) {.inline.} =
  if efAllowDestructor notin flags and
      n.kind in nkCallKinds+{nkObjConstr,nkBracket}:
    if instantiateDestructor(c, n.typ) != nil:
      localError(n.info, warnDestructor)
  # This still breaks too many things:
  when false:
    if efDetermineType notin flags and n.typ.kind == tyTypeDesc and
        c.p.owner.kind notin {skTemplate, skMacro}:
      localError(n.info, errGenerated, "value expected, but got a type")

proc newDeref(n: PNode): PNode {.inline.} =
  result = newNodeIT(nkHiddenDeref, n.info, n.typ.sons[0])
  addSon(result, n)

proc semExprBranch(c: PContext, n: PNode): PNode =
  result = semExpr(c, n)
  if result.typ != nil:
    # XXX tyGenericInst here?
    semProcvarCheck(c, result)
    if result.typ.kind == tyVar: result = newDeref(result)
    semDestructorCheck(c, result, {})

proc semExprBranchScope(c: PContext, n: PNode): PNode =
  openScope(c)
  result = semExprBranch(c, n)
  closeScope(c)

const
  skipForDiscardable = {nkIfStmt, nkIfExpr, nkCaseStmt, nkOfBranch,
    nkElse, nkStmtListExpr, nkTryStmt, nkFinally, nkExceptBranch,
    nkElifBranch, nkElifExpr, nkElseExpr, nkBlockStmt, nkBlockExpr}

proc implicitlyDiscardable(n: PNode): bool =
  var n = n
  while n.kind in skipForDiscardable: n = n.lastSon
  result = isCallExpr(n) and n.sons[0].kind == nkSym and
           sfDiscardable in n.sons[0].sym.flags

proc fixNilType(n: PNode) =
  if isAtom(n):
    if n.kind != nkNilLit and n.typ != nil:
      localError(n.info, errDiscardValueX, n.typ.typeToString)
  elif n.kind in {nkStmtList, nkStmtListExpr}:
    n.kind = nkStmtList
    for it in n: fixNilType(it)
  n.typ = nil

proc discardCheck(c: PContext, result: PNode) =
  if c.inTypeClass > 0: return
  if result.typ != nil and result.typ.kind notin {tyStmt, tyEmpty}:
    if result.kind == nkNilLit:
      result.typ = nil
      message(result.info, warnNilStatement)
    elif implicitlyDiscardable(result):
      var n = result
      result.typ = nil
      while n.kind in skipForDiscardable:
        n = n.lastSon
        n.typ = nil
    elif result.typ.kind != tyError and gCmd != cmdInteractive:
      if result.typ.kind == tyNil:
        fixNilType(result)
        message(result.info, warnNilStatement)
      else:
        var n = result
        while n.kind in skipForDiscardable: n = n.lastSon
        localError(n.info, errDiscardValueX, result.typ.typeToString)

proc semIf(c: PContext, n: PNode): PNode =
  result = n
  var typ = commonTypeBegin
  var hasElse = false
  for i in countup(0, sonsLen(n) - 1):
    var it = n.sons[i]
    if it.len == 2:
      when newScopeForIf: openScope(c)
      it.sons[0] = forceBool(c, semExprWithType(c, it.sons[0]))
      when not newScopeForIf: openScope(c)
      it.sons[1] = semExprBranch(c, it.sons[1])
      typ = commonType(typ, it.sons[1].typ)
      closeScope(c)
    elif it.len == 1:
      hasElse = true
      it.sons[0] = semExprBranchScope(c, it.sons[0])
      typ = commonType(typ, it.sons[0].typ)
    else: illFormedAst(it)
  if isEmptyType(typ) or typ.kind == tyNil or not hasElse:
    for it in n: discardCheck(c, it.lastSon)
    result.kind = nkIfStmt
    # propagate any enforced VoidContext:
    if typ == enforceVoidContext: result.typ = enforceVoidContext
  else:
    for it in n:
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j])
    result.kind = nkIfExpr
    result.typ = typ

proc semCase(c: PContext, n: PNode): PNode =
  result = n
  checkMinSonsLen(n, 2)
  openScope(c)
  n.sons[0] = semExprWithType(c, n.sons[0])
  var chckCovered = false
  var covered: BiggestInt = 0
  var typ = commonTypeBegin
  var hasElse = false
  var notOrdinal = false
  case skipTypes(n.sons[0].typ, abstractVarRange-{tyTypeDesc}).kind
  of tyInt..tyInt64, tyChar, tyEnum, tyUInt..tyUInt32, tyBool:
    chckCovered = true
  of tyFloat..tyFloat128, tyString, tyError:
    notOrdinal = true
  else:
    localError(n.info, errSelectorMustBeOfCertainTypes)
    return
  for i in countup(1, sonsLen(n) - 1):
    var x = n.sons[i]
    case x.kind
    of nkOfBranch:
      checkMinSonsLen(x, 2)
      semCaseBranch(c, n, x, i, covered)
      var last = sonsLen(x)-1
      x.sons[last] = semExprBranchScope(c, x.sons[last])
      typ = commonType(typ, x.sons[last].typ)
    of nkElifBranch:
      chckCovered = false
      checkSonsLen(x, 2)
      when newScopeForIf: openScope(c)
      x.sons[0] = forceBool(c, semExprWithType(c, x.sons[0]))
      when not newScopeForIf: openScope(c)
      x.sons[1] = semExprBranch(c, x.sons[1])
      typ = commonType(typ, x.sons[1].typ)
      closeScope(c)
    of nkElse:
      chckCovered = false
      checkSonsLen(x, 1)
      x.sons[0] = semExprBranchScope(c, x.sons[0])
      typ = commonType(typ, x.sons[0].typ)
      hasElse = true
    else:
      illFormedAst(x)
  if notOrdinal and not hasElse:
    message(n.info, warnDeprecated,
            "use 'else: discard'; non-ordinal case without 'else'")
  if chckCovered:
    if covered == toCover(n.sons[0].typ):
      hasElse = true
    else:
      localError(n.info, errNotAllCasesCovered)
  closeScope(c)
  if isEmptyType(typ) or typ.kind == tyNil or not hasElse:
    for i in 1..n.len-1: discardCheck(c, n.sons[i].lastSon)
    # propagate any enforced VoidContext:
    if typ == enforceVoidContext:
      result.typ = enforceVoidContext
  else:
    for i in 1..n.len-1:
      var it = n.sons[i]
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j])
    result.typ = typ

proc semTry(c: PContext, n: PNode): PNode =
  result = n
  inc c.p.inTryStmt
  checkMinSonsLen(n, 2)
  var typ = commonTypeBegin
  n.sons[0] = semExprBranchScope(c, n.sons[0])
  typ = commonType(typ, n.sons[0].typ)
  var check = initIntSet()
  var last = sonsLen(n) - 1
  for i in countup(1, last):
    var a = n.sons[i]
    checkMinSonsLen(a, 1)
    var length = sonsLen(a)
    if a.kind == nkExceptBranch:
      # so that ``except [a, b, c]`` is supported:
      if length == 2 and a.sons[0].kind == nkBracket:
        a.sons[0..0] = a.sons[0].sons
        length = a.sonsLen

      for j in countup(0, length-2):
        var typ = semTypeNode(c, a.sons[j], nil)
        if typ.kind == tyRef: typ = typ.sons[0]
        if typ.kind != tyObject:
          localError(a.sons[j].info, errExprCannotBeRaised)
        a.sons[j] = newNodeI(nkType, a.sons[j].info)
        a.sons[j].typ = typ
        if containsOrIncl(check, typ.id):
          localError(a.sons[j].info, errExceptionAlreadyHandled)
    elif a.kind != nkFinally:
      illFormedAst(n)
    # last child of an nkExcept/nkFinally branch is a statement:
    a.sons[length-1] = semExprBranchScope(c, a.sons[length-1])
    if a.kind != nkFinally: typ = commonType(typ, a.sons[length-1].typ)
    else: dec last
  dec c.p.inTryStmt
  if isEmptyType(typ) or typ.kind == tyNil:
    discardCheck(c, n.sons[0])
    for i in 1..n.len-1: discardCheck(c, n.sons[i].lastSon)
    if typ == enforceVoidContext:
      result.typ = enforceVoidContext
  else:
    if n.lastSon.kind == nkFinally: discardCheck(c, n.lastSon.lastSon)
    n.sons[0] = fitNode(c, typ, n.sons[0])
    for i in 1..last:
      var it = n.sons[i]
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j])
    result.typ = typ

proc fitRemoveHiddenConv(c: PContext, typ: PType, n: PNode): PNode =
  result = fitNode(c, typ, n)
  if result.kind in {nkHiddenStdConv, nkHiddenSubConv}:
    changeType(result.sons[1], typ, check=true)
    result = result.sons[1]
  elif not sameType(result.typ, typ):
    changeType(result, typ, check=false)

proc findShadowedVar(c: PContext, v: PSym): PSym =
  for scope in walkScopes(c.currentScope.parent):
    if scope == c.topLevelScope: break
    let shadowed = strTableGet(scope.symbols, v.name)
    if shadowed != nil and shadowed.kind in skLocalVars:
      return shadowed

proc identWithin(n: PNode, s: PIdent): bool =
  for i in 0 .. n.safeLen-1:
    if identWithin(n.sons[i], s): return true
  result = n.kind == nkSym and n.sym.name.id == s.id

proc semIdentDef(c: PContext, n: PNode, kind: TSymKind): PSym =
  if isTopLevel(c):
    result = semIdentWithPragma(c, kind, n, {sfExported})
    incl(result.flags, sfGlobal)
  else:
    result = semIdentWithPragma(c, kind, n, {})
  suggestSym(n.info, result)
  styleCheckDef(result)

proc checkNilable(v: PSym) =
  if sfGlobal in v.flags and {tfNotNil, tfNeedsInit} * v.typ.flags != {}:
    if v.ast.isNil:
      message(v.info, warnProveInit, v.name.s)
    elif tfNotNil in v.typ.flags and tfNotNil notin v.ast.typ.flags:
      message(v.info, warnProveInit, v.name.s)

proc semVarOrLet(c: PContext, n: PNode, symkind: TSymKind): PNode =
  var b: PNode
  result = copyNode(n)
  var hasCompileTime = false
  for i in countup(0, sonsLen(n)-1):
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if a.kind notin {nkIdentDefs, nkVarTuple, nkConstDef}: illFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    var typ: PType
    if a.sons[length-2].kind != nkEmpty:
      typ = semTypeNode(c, a.sons[length-2], nil)
    else:
      typ = nil
    var def: PNode
    if a.sons[length-1].kind != nkEmpty:
      def = semExprWithType(c, a.sons[length-1], {efAllowDestructor})
      if def.typ.kind == tyTypeDesc and c.p.owner.kind != skMacro:
        # prevent the all too common 'var x = int' bug:
        localError(def.info, "'typedesc' metatype is not valid here; typed '=' instead of ':'?")
        def.typ = errorType(c)
      if typ != nil:
        if typ.isMetaType:
          def = inferWithMetatype(c, typ, def)
          typ = def.typ
        else:
          # BUGFIX: ``fitNode`` is needed here!
          # check type compatibility between def.typ and typ
          def = fitNode(c, typ, def)
          #changeType(def.skipConv, typ, check=true)
      else:
        typ = skipIntLit(def.typ)
        if typ.kind in {tySequence, tyArray, tySet} and
           typ.lastSon.kind == tyEmpty:
          localError(def.info, errCannotInferTypeOfTheLiteral,
                     ($typ.kind).substr(2).toLower)
    else:
      def = ast.emptyNode
      if symkind == skLet: localError(a.info, errLetNeedsInit)

    # this can only happen for errornous var statements:
    if typ == nil: continue
    typeAllowedCheck(a.info, typ, symkind)
    var tup = skipTypes(typ, {tyGenericInst})
    if a.kind == nkVarTuple:
      if tup.kind != tyTuple:
        localError(a.info, errXExpected, "tuple")
      elif length-2 != sonsLen(tup):
        localError(a.info, errWrongNumberOfVariables)
      else:
        b = newNodeI(nkVarTuple, a.info)
        newSons(b, length)
        b.sons[length-2] = a.sons[length-2] # keep type desc for doc generator
        b.sons[length-1] = def
        addSon(result, b)
    elif tup.kind == tyTuple and def.kind == nkPar and
        a.kind == nkIdentDefs and a.len > 3:
      message(a.info, warnEachIdentIsTuple)

    for j in countup(0, length-3):
      var v = semIdentDef(c, a.sons[j], symkind)
      if sfGenSym notin v.flags: addInterfaceDecl(c, v)
      when oKeepVariableNames:
        if c.inUnrolledContext > 0: v.flags.incl(sfShadowed)
        else:
          let shadowed = findShadowedVar(c, v)
          if shadowed != nil:
            shadowed.flags.incl(sfShadowed)
            if shadowed.kind == skResult and sfGenSym notin v.flags:
              message(a.info, warnResultShadowed)
            # a shadowed variable is an error unless it appears on the right
            # side of the '=':
            if warnShadowIdent in gNotes and not identWithin(def, v.name):
              message(a.info, warnShadowIdent, v.name.s)
      if a.kind != nkVarTuple:
        if def != nil and def.kind != nkEmpty:
          # this is needed for the evaluation pass and for the guard checking:
          v.ast = def
          if sfThread in v.flags: localError(def.info, errThreadvarCannotInit)
        v.typ = typ
        b = newNodeI(nkIdentDefs, a.info)
        if importantComments():
          # keep documentation information:
          b.comment = a.comment
        addSon(b, newSymNode(v))
        addSon(b, a.sons[length-2])      # keep type desc for doc generator
        addSon(b, copyTree(def))
        addSon(result, b)
      else:
        if def.kind == nkPar: v.ast = def[j]
        v.typ = tup.sons[j]
        b.sons[j] = newSymNode(v)
      checkNilable(v)
      if sfCompileTime in v.flags: hasCompileTime = true
  if hasCompileTime: vm.setupCompileTimeVar(c.module, result)

proc semConst(c: PContext, n: PNode): PNode =
  result = copyNode(n)
  for i in countup(0, sonsLen(n) - 1):
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if (a.kind != nkConstDef): illFormedAst(a)
    checkSonsLen(a, 3)
    var v = semIdentDef(c, a.sons[0], skConst)
    var typ: PType = nil
    if a.sons[1].kind != nkEmpty: typ = semTypeNode(c, a.sons[1], nil)

    var def = semConstExpr(c, a.sons[2])
    if def == nil:
      localError(a.sons[2].info, errConstExprExpected)
      continue
    # check type compatibility between def.typ and typ:
    if typ != nil:
      def = fitRemoveHiddenConv(c, typ, def)
    else:
      typ = def.typ
    if typ == nil:
      localError(a.sons[2].info, errConstExprExpected)
      continue
    if typeAllowed(typ, skConst) != nil and def.kind != nkNilLit:
      localError(a.info, errXisNoType, typeToString(typ))
      continue
    v.typ = typ
    v.ast = def               # no need to copy
    if sfGenSym notin v.flags: addInterfaceDecl(c, v)
    var b = newNodeI(nkConstDef, a.info)
    if importantComments(): b.comment = a.comment
    addSon(b, newSymNode(v))
    addSon(b, a.sons[1])
    addSon(b, copyTree(def))
    addSon(result, b)

include semfields

proc addForVarDecl(c: PContext, v: PSym) =
  if warnShadowIdent in gNotes:
    let shadowed = findShadowedVar(c, v)
    if shadowed != nil:
      # XXX should we do this here?
      #shadowed.flags.incl(sfShadowed)
      message(v.info, warnShadowIdent, v.name.s)
  addDecl(c, v)

proc symForVar(c: PContext, n: PNode): PSym =
  let m = if n.kind == nkPragmaExpr: n.sons[0] else: n
  result = newSymG(skForVar, m, c)
  styleCheckDef(result)

proc semForVars(c: PContext, n: PNode): PNode =
  result = n
  var length = sonsLen(n)
  let iterBase = n.sons[length-2].typ.skipTypes({tyIter})
  var iter = skipTypes(iterBase, {tyGenericInst})
  # length == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if iter.kind != tyTuple or length == 3:
    if length == 3:
      var v = symForVar(c, n.sons[0])
      if getCurrOwner().kind == skModule: incl(v.flags, sfGlobal)
      # BUGFIX: don't use `iter` here as that would strip away
      # the ``tyGenericInst``! See ``tests/compile/tgeneric.nim``
      # for an example:
      v.typ = iterBase
      n.sons[0] = newSymNode(v)
      if sfGenSym notin v.flags: addForVarDecl(c, v)
    else:
      localError(n.info, errWrongNumberOfVariables)
  elif length-2 != sonsLen(iter):
    localError(n.info, errWrongNumberOfVariables)
  else:
    for i in countup(0, length - 3):
      var v = symForVar(c, n.sons[i])
      if getCurrOwner().kind == skModule: incl(v.flags, sfGlobal)
      v.typ = iter.sons[i]
      n.sons[i] = newSymNode(v)
      if sfGenSym notin v.flags: addForVarDecl(c, v)
  inc(c.p.nestedLoopCounter)
  n.sons[length-1] = semStmt(c, n.sons[length-1])
  dec(c.p.nestedLoopCounter)

proc implicitIterator(c: PContext, it: string, arg: PNode): PNode =
  result = newNodeI(nkCall, arg.info)
  result.add(newIdentNode(it.getIdent, arg.info))
  if arg.typ != nil and arg.typ.kind == tyVar:
    result.add newDeref(arg)
  else:
    result.add arg
  result = semExprNoDeref(c, result, {efWantIterator})

proc semFor(c: PContext, n: PNode): PNode =
  result = n
  checkMinSonsLen(n, 3)
  var length = sonsLen(n)
  openScope(c)
  n.sons[length-2] = semExprNoDeref(c, n.sons[length-2], {efWantIterator})
  var call = n.sons[length-2]
  let isCallExpr = call.kind in nkCallKinds
  if isCallExpr and call[0].kind == nkSym and
      call[0].sym.magic in {mFields, mFieldPairs, mOmpParFor}:
    if call.sons[0].sym.magic == mOmpParFor:
      result = semForVars(c, n)
      result.kind = nkParForStmt
    else:
      result = semForFields(c, n, call.sons[0].sym.magic)
  elif (isCallExpr and call.sons[0].typ.callConv == ccClosure) or
      call.typ.kind == tyIter:
    # first class iterator:
    result = semForVars(c, n)
  elif not isCallExpr or call.sons[0].kind != nkSym or
      call.sons[0].sym.kind notin skIterators:
    if length == 3:
      n.sons[length-2] = implicitIterator(c, "items", n.sons[length-2])
    elif length == 4:
      n.sons[length-2] = implicitIterator(c, "pairs", n.sons[length-2])
    else:
      localError(n.sons[length-2].info, errIteratorExpected)
    result = semForVars(c, n)
  else:
    result = semForVars(c, n)
  # propagate any enforced VoidContext:
  if n.sons[length-1].typ == enforceVoidContext:
    result.typ = enforceVoidContext
  closeScope(c)

proc semRaise(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty:
    n.sons[0] = semExprWithType(c, n.sons[0])
    var typ = n.sons[0].typ
    if typ.kind != tyRef or typ.sons[0].kind != tyObject:
      localError(n.info, errExprCannotBeRaised)

proc addGenericParamListToScope(c: PContext, n: PNode) =
  if n.kind != nkGenericParams: illFormedAst(n)
  for i in countup(0, sonsLen(n)-1):
    var a = n.sons[i]
    if a.kind == nkSym: addDecl(c, a.sym)
    else: illFormedAst(a)

proc typeSectionLeftSidePass(c: PContext, n: PNode) =
  # process the symbols on the left side for the whole type section, before
  # we even look at the type definitions on the right
  for i in countup(0, sonsLen(n) - 1):
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if a.kind != nkTypeDef: illFormedAst(a)
    checkSonsLen(a, 3)
    var s = semIdentDef(c, a.sons[0], skType)
    s.typ = newTypeS(tyForward, c)
    s.typ.sym = s             # process pragmas:
    if a.sons[0].kind == nkPragmaExpr:
      pragma(c, s, a.sons[0].sons[1], typePragmas)
    # add it here, so that recursive types are possible:
    if sfGenSym notin s.flags: addInterfaceDecl(c, s)
    a.sons[0] = newSymNode(s)

proc typeSectionRightSidePass(c: PContext, n: PNode) =
  for i in countup(0, sonsLen(n) - 1):
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue
    if (a.kind != nkTypeDef): illFormedAst(a)
    checkSonsLen(a, 3)
    if (a.sons[0].kind != nkSym): illFormedAst(a)
    var s = a.sons[0].sym
    if s.magic == mNone and a.sons[2].kind == nkEmpty:
      localError(a.info, errImplOfXexpected, s.name.s)
    if s.magic != mNone: processMagicType(c, s)
    if a.sons[1].kind != nkEmpty:
      # We have a generic type declaration here. In generic types,
      # symbol lookup needs to be done here.
      openScope(c)
      pushOwner(s)
      if s.magic == mNone: s.typ.kind = tyGenericBody
      # XXX for generic type aliases this is not correct! We need the
      # underlying Id really:
      #
      # type
      #   TGObj[T] = object
      #   TAlias[T] = TGObj[T]
      #
      s.typ.n = semGenericParamList(c, a.sons[1], s.typ)
      a.sons[1] = s.typ.n
      s.typ.size = -1 # could not be computed properly
      # we fill it out later. For magic generics like 'seq', it won't be filled
      # so we use tyEmpty instead of nil to not crash for strange conversions
      # like: mydata.seq
      rawAddSon(s.typ, newTypeS(tyNone, c))
      s.ast = a
      inc c.inGenericContext
      var body = semTypeNode(c, a.sons[2], nil)
      dec c.inGenericContext
      if body != nil:
        body.sym = s
        body.size = -1 # could not be computed properly
        s.typ.sons[sonsLen(s.typ) - 1] = body
      popOwner()
      closeScope(c)
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

proc checkForMetaFields(n: PNode) =
  template checkMeta(t) =
    if t != nil and t.isMetaType and tfGenericTypeParam notin t.flags:
      localError(n.info, errTIsNotAConcreteType, t.typeToString)

  if n.isNil: return
  case n.kind
  of nkRecList, nkRecCase:
    for s in n: checkForMetaFields(s)
  of nkOfBranch, nkElse:
    checkForMetaFields(n.lastSon)
  of nkSym:
    let t = n.sym.typ
    case t.kind
    of tySequence, tySet, tyArray, tyOpenArray, tyVar, tyPtr, tyRef,
       tyProc, tyGenericInvocation, tyGenericInst:
      let start = ord(t.kind in {tyGenericInvocation, tyGenericInst})
      for i in start .. <t.sons.len:
        checkMeta(t.sons[i])
    else:
      checkMeta(t)
  else:
    internalAssert false

proc typeSectionFinalPass(c: PContext, n: PNode) =
  for i in countup(0, sonsLen(n) - 1):
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue
    if a.sons[0].kind != nkSym: illFormedAst(a)
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
      if s.typ.kind in {tyObject, tyTuple} and not s.typ.n.isNil:
        checkForMetaFields(s.typ.n)
    let aa = a.sons[2]
    if aa.kind in {nkRefTy, nkPtrTy} and aa.len == 1 and
       aa.sons[0].kind == nkObjectTy:
      # give anonymous object a dummy symbol:
      var st = s.typ
      if st.kind == tyGenericBody: st = st.lastSon
      internalAssert st.kind in {tyPtr, tyRef}
      internalAssert st.lastSon.sym == nil
      st.lastSon.sym = newSym(skType, getIdent(s.name.s & ":ObjectType"),
                              getCurrOwner(), s.info)

proc semTypeSection(c: PContext, n: PNode): PNode =
  ## Processes a type section. This must be done in separate passes, in order
  ## to allow the type definitions in the section to reference each other
  ## without regard for the order of their definitions.
  typeSectionLeftSidePass(c, n)
  typeSectionRightSidePass(c, n)
  typeSectionFinalPass(c, n)
  result = n

proc semParamList(c: PContext, n, genericParams: PNode, s: PSym) =
  s.typ = semProcTypeNode(c, n, genericParams, nil, s.kind)
  if s.kind notin {skMacro, skTemplate}:
    if s.typ.sons[0] != nil and s.typ.sons[0].kind == tyStmt:
      localError(n.info, errGenerated, "invalid return type: 'stmt'")

proc addParams(c: PContext, n: PNode, kind: TSymKind) =
  for i in countup(1, sonsLen(n)-1):
    if n.sons[i].kind == nkSym: addParamOrResult(c, n.sons[i].sym, kind)
    else: illFormedAst(n)

proc semBorrow(c: PContext, n: PNode, s: PSym) =
  # search for the correct alias:
  var b = searchForBorrowProc(c, c.currentScope.parent, s)
  if b != nil:
    # store the alias:
    n.sons[bodyPos] = newSymNode(b)
  else:
    localError(n.info, errNoSymbolToBorrowFromFound)

proc addResult(c: PContext, t: PType, info: TLineInfo, owner: TSymKind) =
  if t != nil:
    var s = newSym(skResult, getIdent"result", getCurrOwner(), info)
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
    result = searchInScopes(c, considerQuotedIdent(n), {skMacro, skTemplate})

proc semProcAnnotation(c: PContext, prc: PNode;
                       validPragmas: TSpecialWords): PNode =
  var n = prc.sons[pragmasPos]
  if n == nil or n.kind == nkEmpty: return
  for i in countup(0, <n.len):
    var it = n.sons[i]
    var key = if it.kind == nkExprColonExpr: it.sons[0] else: it
    let m = lookupMacro(c, key)
    if m == nil:
      if key.kind == nkIdent and key.ident.id == ord(wDelegator):
        if considerQuotedIdent(prc.sons[namePos]).s == "()":
          prc.sons[namePos] = newIdentNode(idDelegator, prc.info)
          prc.sons[pragmasPos] = copyExcept(n, i)
        else:
          localError(prc.info, errOnlyACallOpCanBeDelegator)
      continue
    # we transform ``proc p {.m, rest.}`` into ``m(do: proc p {.rest.})`` and
    # let the semantic checker deal with it:
    var x = newNodeI(nkCall, n.info)
    x.add(newSymNode(m))
    prc.sons[pragmasPos] = copyExcept(n, i)
    if it.kind == nkExprColonExpr:
      # pass pragma argument to the macro too:
      x.add(it.sons[1])
    x.add(prc)
    # recursion assures that this works for multiple macro annotations too:
    result = semStmt(c, x)
    # since a proc annotation can set pragmas, we process these here again.
    # This is required for SqueakNim-like export pragmas.
    if result.kind in procDefs and result[namePos].kind == nkSym and
        result[pragmasPos].kind != nkEmpty:
      pragma(c, result[namePos].sym, result[pragmasPos], validPragmas)
    return

proc semLambda(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # XXX semProcAux should be good enough for this now, we will eventually
  # remove semLambda
  result = semProcAnnotation(c, n, lambdaPragmas)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s: PSym
  if n[namePos].kind != nkSym:
    s = newSym(skProc, idAnon, getCurrOwner(), n.info)
    s.ast = n
    n.sons[namePos] = newSymNode(s)
  else:
    s = n[namePos].sym
  pushOwner(s)
  openScope(c)
  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty:
    n.sons[genericParamsPos] = semGenericParamList(c, n.sons[genericParamsPos])
    gp = n.sons[genericParamsPos]
  else:
    gp = newNodeI(nkGenericParams, n.info)

  if n.sons[paramsPos].kind != nkEmpty:
    #if n.kind == nkDo and not experimentalMode(c):
    #  localError(n.sons[paramsPos].info,
    #      "use the {.experimental.} pragma to enable 'do' with parameters")
    semParamList(c, n.sons[paramsPos], gp, s)
    # paramsTypeCheck(c, s.typ)
    if sonsLen(gp) > 0 and n.sons[genericParamsPos].kind == nkEmpty:
      # we have a list of implicit type parameters:
      n.sons[genericParamsPos] = gp
  else:
    s.typ = newProcType(c, n.info)
  if n.sons[pragmasPos].kind != nkEmpty:
    pragma(c, s, n.sons[pragmasPos], lambdaPragmas)
  s.options = gOptions
  if n.sons[bodyPos].kind != nkEmpty:
    if sfImportc in s.flags:
      localError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    #if efDetermineType notin flags:
    # XXX not good enough; see tnamedparamanonproc.nim
    if gp.len == 0 or (gp.len == 1 and tfRetType in gp[0].typ.flags):
      pushProcCon(c, s)
      addResult(c, s.typ.sons[0], n.info, skProc)
      addResultNode(c, n)
      let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
      n.sons[bodyPos] = transformBody(c.module, semBody, s)
      popProcCon(c)
    elif efOperand notin flags:
      localError(n.info, errGenericLambdaNotAllowed)
    sideEffectsCheck(c, s)
  else:
    localError(n.info, errImplOfXexpected, s.name.s)
  closeScope(c)           # close scope for parameters
  popOwner()
  result.typ = s.typ

proc semDo(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # 'do' without params produces a stmt:
  if n[genericParamsPos].kind == nkEmpty and n[paramsPos].kind == nkEmpty:
    result = semStmt(c, n[bodyPos])
  else:
    result = semLambda(c, n, flags)

proc semInferredLambda(c: PContext, pt: TIdTable, n: PNode): PNode =
  var n = n

  n = replaceTypesInBody(c, pt, n)
  result = n

  n.sons[genericParamsPos] = emptyNode
  n.sons[paramsPos] = n.typ.n

  openScope(c)
  var s = n.sons[namePos].sym
  pushOwner(s)
  addParams(c, n.typ.n, skProc)
  pushProcCon(c, s)
  addResult(c, n.typ.sons[0], n.info, skProc)
  addResultNode(c, n)
  let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
  n.sons[bodyPos] = transformBody(c.module, semBody, n.sons[namePos].sym)
  popProcCon(c)
  popOwner()
  closeScope(c)

  s.ast = result

  # alternative variant (not quite working):
  # var prc = arg[0].sym
  # let inferred = c.semGenerateInstance(c, prc, m.bindings, arg.info)
  # result = inferred.ast
  # result.kind = arg.kind

proc activate(c: PContext, n: PNode) =
  # XXX: This proc is part of my plan for getting rid of
  # forward declarations. stay tuned.
  when false:
    # well for now it breaks code ...
    case n.kind
    of nkLambdaKinds:
      discard semLambda(c, n, {})
    of nkCallKinds:
      for i in 1 .. <n.len: activate(c, n[i])
    else:
      discard

proc maybeAddResult(c: PContext, s: PSym, n: PNode) =
  if s.typ.sons[0] != nil and s.kind != skIterator:
    addResult(c, s.typ.sons[0], n.info, s.kind)
    addResultNode(c, n)

proc semOverride(c: PContext, s: PSym, n: PNode) =
  case s.name.s.normalize
  of "destroy":
    doDestructorStuff(c, s, n)
    if not experimentalMode(c):
      localError n.info, "use the {.experimental.} pragma to enable destructors"
  of "deepcopy":
    if s.typ.len == 2 and
        s.typ.sons[1].skipTypes(abstractInst).kind in {tyRef, tyPtr} and
        sameType(s.typ.sons[1], s.typ.sons[0]):
      # Note: we store the deepCopy in the base of the pointer to mitigate
      # the problem that pointers are structural types:
      var t = s.typ.sons[1].skipTypes(abstractInst).lastSon.skipTypes(abstractInst)
      while true:
        if t.kind == tyGenericBody: t = t.lastSon
        elif t.kind == tyGenericInvocation: t = t.sons[0]
        else: break
      if t.kind in {tyObject, tyDistinct, tyEnum}:
        if t.deepCopy.isNil: t.deepCopy = s
        else:
          localError(n.info, errGenerated,
                     "cannot bind another 'deepCopy' to: " & typeToString(t))
      else:
        localError(n.info, errGenerated,
                   "cannot bind 'deepCopy' to: " & typeToString(t))
    else:
      localError(n.info, errGenerated,
                 "signature for 'deepCopy' must be proc[T: ptr|ref](x: T): T")
  of "=": discard
  else: localError(n.info, errGenerated,
                   "'destroy' or 'deepCopy' expected for 'override'")
  incl(s.flags, sfUsed)

type
  TProcCompilationSteps = enum
    stepRegisterSymbol,
    stepDetermineType,
    stepCompileBody

proc isForwardDecl(s: PSym): bool =
  internalAssert s.kind == skProc
  result = s.ast[bodyPos].kind != nkEmpty

proc semProcAux(c: PContext, n: PNode, kind: TSymKind,
                validPragmas: TSpecialWords,
                phase = stepRegisterSymbol): PNode =
  result = semProcAnnotation(c, n, validPragmas)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s: PSym
  var typeIsDetermined = false
  var isAnon = false
  if n[namePos].kind != nkSym:
    assert phase == stepRegisterSymbol

    if n[namePos].kind == nkEmpty:
      s = newSym(kind, idAnon, getCurrOwner(), n.info)
      isAnon = true
    else:
      s = semIdentDef(c, n.sons[0], kind)
    n.sons[namePos] = newSymNode(s)
    s.ast = n
    s.scope = c.currentScope

    if sfNoForward in c.module.flags and
       sfSystemModule notin c.module.flags:
      addInterfaceOverloadableSymAt(c, c.currentScope, s)
      s.flags.incl sfForward
      return
  else:
    s = n[namePos].sym
    s.owner = getCurrOwner()
    typeIsDetermined = s.typ == nil
    s.ast = n
    s.scope = c.currentScope

    # if typeIsDetermined: assert phase == stepCompileBody
    # else: assert phase == stepDetermineType
  # before compiling the proc body, set as current the scope
  # where the proc was declared
  let oldScope = c.currentScope
  c.currentScope = s.scope
  pushOwner(s)
  openScope(c)
  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty:
    n.sons[genericParamsPos] = semGenericParamList(c, n.sons[genericParamsPos])
    gp = n.sons[genericParamsPos]
  else:
    gp = newNodeI(nkGenericParams, n.info)
  # process parameters:
  if n.sons[paramsPos].kind != nkEmpty:
    semParamList(c, n.sons[paramsPos], gp, s)
    if sonsLen(gp) > 0:
      if n.sons[genericParamsPos].kind == nkEmpty:
        # we have a list of implicit type parameters:
        n.sons[genericParamsPos] = gp
        # check for semantics again:
        # semParamList(c, n.sons[ParamsPos], nil, s)
  else:
    s.typ = newProcType(c, n.info)
  if n.sons[patternPos].kind != nkEmpty:
    n.sons[patternPos] = semPattern(c, n.sons[patternPos])
  if s.kind in skIterators:
    s.typ.flags.incl(tfIterator)

  var proto = searchForProc(c, s.scope, s)
  if proto == nil:
    if s.kind == skClosureIterator: s.typ.callConv = ccClosure
    else: s.typ.callConv = lastOptionEntry(c).defaultCC
    # add it here, so that recursive procs are possible:
    if sfGenSym in s.flags: discard
    elif kind in OverloadableSyms:
      if not typeIsDetermined:
        addInterfaceOverloadableSymAt(c, s.scope, s)
    else:
      if not typeIsDetermined:
        addInterfaceDeclAt(c, s.scope, s)
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, s, n.sons[pragmasPos], validPragmas)
    else:
      implicitPragmas(c, s, n, validPragmas)
  else:
    if n.sons[pragmasPos].kind != nkEmpty:
      localError(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProc)
    if sfForward notin proto.flags:
      wrongRedefinition(n.info, proto.name.s)
    excl(proto.flags, sfForward)
    closeScope(c)         # close scope with wrong parameter symbols
    openScope(c)          # open scope for old (correct) parameter symbols
    if proto.ast.sons[genericParamsPos].kind != nkEmpty:
      addGenericParamListToScope(c, proto.ast.sons[genericParamsPos])
    addParams(c, proto.typ.n, proto.kind)
    proto.info = s.info       # more accurate line information
    s.typ = proto.typ
    s = proto
    n.sons[genericParamsPos] = proto.ast.sons[genericParamsPos]
    n.sons[paramsPos] = proto.ast.sons[paramsPos]
    n.sons[pragmasPos] = proto.ast.sons[pragmasPos]
    if n.sons[namePos].kind != nkSym: internalError(n.info, "semProcAux")
    n.sons[namePos].sym = proto
    if importantComments() and not isNil(proto.ast.comment):
      n.comment = proto.ast.comment
    proto.ast = n             # needed for code generation
    popOwner()
    pushOwner(s)
  s.options = gOptions
  if sfOverriden in s.flags: semOverride(c, s, n)
  if n.sons[bodyPos].kind != nkEmpty:
    # for DLL generation it is annoying to check for sfImportc!
    if sfBorrow in s.flags:
      localError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    let usePseudoGenerics = kind in {skMacro, skTemplate}
    # Macros and Templates can have generic parameters, but they are
    # only used for overload resolution (there is no instantiation of
    # the symbol, so we must process the body now)
    if n.sons[genericParamsPos].kind == nkEmpty or usePseudoGenerics:
      if not usePseudoGenerics: paramsTypeCheck(c, s.typ)
      pushProcCon(c, s)
      c.p.wasForwarded = proto != nil
      maybeAddResult(c, s, n)
      if sfImportc notin s.flags:
        # no semantic checking for importc:
        let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
        # unfortunately we cannot skip this step when in 'system.compiles'
        # context as it may even be evaluated in 'system.compiles':
        n.sons[bodyPos] = transformBody(c.module, semBody, s)
      popProcCon(c)
    else:
      if s.typ.sons[0] != nil and kind notin skIterators:
        addDecl(c, newSym(skUnknown, getIdent"result", nil, n.info))
      openScope(c)
      n.sons[bodyPos] = semGenericStmt(c, n.sons[bodyPos])
      closeScope(c)
      fixupInstantiatedSymbols(c, s)
    if sfImportc in s.flags:
      # so we just ignore the body after semantic checking for importc:
      n.sons[bodyPos] = ast.emptyNode
  else:
    if proto != nil: localError(n.info, errImplOfXexpected, proto.name.s)
    if {sfImportc, sfBorrow} * s.flags == {} and s.magic == mNone:
      incl(s.flags, sfForward)
    elif sfBorrow in s.flags: semBorrow(c, n, s)
  sideEffectsCheck(c, s)
  closeScope(c)           # close scope for parameters
  c.currentScope = oldScope
  popOwner()
  if n.sons[patternPos].kind != nkEmpty:
    c.patterns.add(s)
  if isAnon: result.typ = s.typ

proc determineType(c: PContext, s: PSym) =
  if s.typ != nil: return
  #if s.magic != mNone: return
  discard semProcAux(c, s.ast, s.kind, {}, stepDetermineType)

proc semIterator(c: PContext, n: PNode): PNode =
  let kind = if hasPragma(n[pragmasPos], wClosure) or
                n[namePos].kind == nkEmpty: skClosureIterator
             else: skIterator
  # gensym'ed iterator?
  if n[namePos].kind == nkSym:
    # gensym'ed iterators might need to become closure iterators:
    n[namePos].sym.owner = getCurrOwner()
    n[namePos].sym.kind = kind
  result = semProcAux(c, n, kind, iteratorPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil and s.typ.callConv != ccClosure:
    localError(n.info, errXNeedsReturnType, "iterator")
  # iterators are either 'inline' or 'closure'; for backwards compatibility,
  # we require first class iterators to be marked with 'closure' explicitly
  # -- at least for 0.9.2.
  if s.typ.callConv == ccClosure:
    incl(s.typ.flags, tfCapturesEnv)
  else:
    s.typ.callConv = ccInline
  when false:
    if s.typ.callConv != ccInline:
      s.typ.callConv = ccClosure
      # and they always at least use the 'env' for the state field:
      incl(s.typ.flags, tfCapturesEnv)
  if n.sons[bodyPos].kind == nkEmpty and s.magic == mNone:
    localError(n.info, errImplOfXexpected, s.name.s)

proc semProc(c: PContext, n: PNode): PNode =
  result = semProcAux(c, n, skProc, procPragmas)

proc hasObjParam(s: PSym): bool =
  var t = s.typ
  for col in countup(1, sonsLen(t)-1):
    if skipTypes(t.sons[col], skipPtrs).kind == tyObject:
      return true

proc finishMethod(c: PContext, s: PSym) =
  if hasObjParam(s):
    methodDef(s, false)

proc semMethod(c: PContext, n: PNode): PNode =
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "method")
  result = semProcAux(c, n, skMethod, methodPragmas)

  var s = result.sons[namePos].sym
  if not isGenericRoutine(s):
    # why check for the body? bug #2400 has none. Checking for sfForward makes
    # no sense either.
    # and result.sons[bodyPos].kind != nkEmpty:
    if hasObjParam(s):
      methodDef(s, fromCache=false)
    else:
      localError(n.info, errXNeedsParamObjectType, "method")

proc semConverterDef(c: PContext, n: PNode): PNode =
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "converter")
  checkSonsLen(n, bodyPos + 1)
  result = semProcAux(c, n, skConverter, converterPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: localError(n.info, errXNeedsReturnType, "converter")
  if sonsLen(t) != 2: localError(n.info, errXRequiresOneArgument, "converter")
  addConverter(c, s)

proc semMacroDef(c: PContext, n: PNode): PNode =
  checkSonsLen(n, bodyPos + 1)
  result = semProcAux(c, n, skMacro, macroPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: localError(n.info, errXNeedsReturnType, "macro")
  if n.sons[bodyPos].kind == nkEmpty:
    localError(n.info, errImplOfXexpected, s.name.s)

proc evalInclude(c: PContext, n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  addSon(result, n)
  for i in countup(0, sonsLen(n) - 1):
    var f = checkModuleName(n.sons[i])
    if f != InvalidFileIDX:
      if containsOrIncl(c.includedFiles, f):
        localError(n.info, errRecursiveDependencyX, f.toFilename)
      else:
        addSon(result, semStmt(c, gIncludeFile(c.module, f)))
        excl(c.includedFiles, f)

proc setLine(n: PNode, info: TLineInfo) =
  for i in 0 .. <safeLen(n): setLine(n.sons[i], info)
  n.info = info

proc semPragmaBlock(c: PContext, n: PNode): PNode =
  let pragmaList = n.sons[0]
  pragma(c, nil, pragmaList, exprPragmas)
  result = semExpr(c, n.sons[1])
  n.sons[1] = result
  for i in 0 .. <pragmaList.len:
    case whichPragma(pragmaList.sons[i])
    of wLine: setLine(result, pragmaList.sons[i].info)
    of wLocks:
      result = n
      result.typ = n.sons[1].typ
    else: discard

proc semStaticStmt(c: PContext, n: PNode): PNode =
  #echo "semStaticStmt"
  #writeStackTrace()
  let a = semStmt(c, n.sons[0])
  n.sons[0] = a
  evalStaticStmt(c.module, a, c.p.owner)
  result = newNodeI(nkDiscardStmt, n.info, 1)
  result.sons[0] = emptyNode
  when false:
    result = evalStaticStmt(c.module, a, c.p.owner)
    if result.isNil:
      LocalError(n.info, errCannotInterpretNodeX, renderTree(n))
      result = emptyNode
    elif result.kind == nkEmpty:
      result = newNodeI(nkDiscardStmt, n.info, 1)
      result.sons[0] = emptyNode

proc usesResult(n: PNode): bool =
  # nkStmtList(expr) properly propagates the void context,
  # so we don't need to process that all over again:
  if n.kind notin {nkStmtList, nkStmtListExpr,
                   nkMacroDef, nkTemplateDef} + procDefs:
    if isAtom(n):
      result = n.kind == nkSym and n.sym.kind == skResult
    elif n.kind == nkReturnStmt:
      result = true
    else:
      for c in n:
        if usesResult(c): return true

proc semStmtList(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # these must be last statements in a block:
  const
    LastBlockStmts = {nkRaiseStmt, nkReturnStmt, nkBreakStmt, nkContinueStmt}
  result = n
  result.kind = nkStmtList
  var length = sonsLen(n)
  var voidContext = false
  var last = length-1
  # by not allowing for nkCommentStmt etc. we ensure nkStmtListExpr actually
  # really *ends* in the expression that produces the type: The compiler now
  # relies on this fact and it's too much effort to change that. And arguably
  #  'R(); #comment' shouldn't produce R's type anyway.
  #while last > 0 and n.sons[last].kind in {nkPragma, nkCommentStmt,
  #                                         nkNilLit, nkEmpty}:
  #  dec last
  for i in countup(0, length - 1):
    let k = n.sons[i].kind
    case k
    of nkFinally, nkExceptBranch, nkDefer:
      # stand-alone finally and except blocks are
      # transformed into regular try blocks:
      #
      # var f = fopen("somefile") | var f = fopen("somefile")
      # finally: fclose(f)        | try:
      # ...                       |   ...
      #                           | finally:
      #                           |   fclose(f)
      var deferPart: PNode
      if k == nkDefer:
        deferPart = newNodeI(nkFinally, n.sons[i].info)
        deferPart.add n.sons[i].sons[0]
      elif k == nkFinally:
        message(n.info, warnDeprecated,
                "use 'defer'; standalone 'finally'")
        deferPart = n.sons[i]
      else:
        message(n.info, warnDeprecated,
                "use an explicit 'try'; standalone 'except'")
        deferPart = n.sons[i]
      var tryStmt = newNodeI(nkTryStmt, n.sons[i].info)
      var body = newNodeI(nkStmtList, n.sons[i].info)
      if i < n.sonsLen - 1:
        body.sons = n.sons[(i+1)..(-1)]
      tryStmt.addSon(body)
      tryStmt.addSon(deferPart)
      n.sons[i] = semTry(c, tryStmt)
      n.sons.setLen(i+1)
      n.typ = n.sons[i].typ
      return
    else:
      n.sons[i] = semExpr(c, n.sons[i])
      if c.inTypeClass > 0 and n[i].typ != nil:
        case n[i].typ.kind
        of tyBool:
          let verdict = semConstExpr(c, n[i])
          if verdict.intVal == 0:
            localError(result.info, "type class predicate failed")
        of tyUnknown: continue
        else: discard
      if n.sons[i].typ == enforceVoidContext or usesResult(n.sons[i]):
        voidContext = true
        n.typ = enforceVoidContext
      if i == last and (length == 1 or efWantValue in flags):
        n.typ = n.sons[i].typ
        if not isEmptyType(n.typ): n.kind = nkStmtListExpr
      elif i != last or voidContext:
        discardCheck(c, n.sons[i])
      else:
        n.typ = n.sons[i].typ
        if not isEmptyType(n.typ): n.kind = nkStmtListExpr
      case n.sons[i].kind
      of nkVarSection, nkLetSection:
        let (outer, inner) = insertDestructors(c, n.sons[i])
        if outer != nil:
          n.sons[i] = outer
          var rest = newNode(nkStmtList, n.info, n.sons[i+1 .. length-1])
          inner.addSon(semStmtList(c, rest, flags))
          n.sons.setLen(i+1)
          return
      of LastBlockStmts:
        for j in countup(i + 1, length - 1):
          case n.sons[j].kind
          of nkPragma, nkCommentStmt, nkNilLit, nkEmpty: discard
          else: localError(n.sons[j].info, errStmtInvalidAfterReturn)
      else: discard
  if result.len == 1:
    result = result.sons[0]
  when defined(nimfix):
    if result.kind == nkCommentStmt and not result.comment.isNil and
        not (result.comment[0] == '#' and result.comment[1] == '#'):
      # it is an old-style comment statement: we replace it with 'discard ""':
      prettybase.replaceComment(result.info)
  when false:
    # a statement list (s; e) has the type 'e':
    if result.kind == nkStmtList and result.len > 0:
      var lastStmt = lastSon(result)
      if lastStmt.kind != nkNilLit and not implicitlyDiscardable(lastStmt):
        result.typ = lastStmt.typ
        #localError(lastStmt.info, errGenerated,
        #  "Last expression must be explicitly returned if it " &
        #  "is discardable or discarded")

proc semStmt(c: PContext, n: PNode): PNode =
  # now: simply an alias:
  result = semExprNoType(c, n)

proc semStmtScope(c: PContext, n: PNode): PNode =
  openScope(c)
  result = semStmt(c, n)
  closeScope(c)
