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
    if isEmptyType(n.sons[0].typ) or n.sons[0].typ.kind == tyNone or n.sons[0].kind == nkTypeOfExpr:
      localError(n.info, errInvalidDiscard)

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
      s = getGenSym(c, s)
      if s.kind == skLabel and s.owner.id == c.p.owner.id:
        var x = newSymNode(s)
        x.info = n.info
        incl(s.flags, sfUsed)
        n.sons[0] = x
        suggestSym(x.info, s, c.graph.usageSym)
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

when false:
  proc performProcvarCheck(c: PContext, info: TLineInfo, s: PSym) =
    ## Checks that the given symbol is a proper procedure variable, meaning
    ## that it
    var smoduleId = getModule(s).id
    if sfProcvar notin s.flags and s.typ.callConv == ccDefault and
        smoduleId != c.module.id:
      block outer:
        for module in c.friendModules:
          if smoduleId == module.id:
            break outer
        localError(info, errXCannotBePassedToProcVar, s.name.s)

template semProcvarCheck(c: PContext, n: PNode) =
  when false:
    var n = n.skipConv
    if n.kind in nkSymChoices:
      for x in n:
        if x.sym.kind in {skProc, skMethod, skConverter, skIterator}:
          performProcvarCheck(c, n.info, x.sym)
    elif n.kind == nkSym and n.sym.kind in {skProc, skMethod, skConverter,
                                          skIterator}:
      performProcvarCheck(c, n.info, n.sym)

proc semProc(c: PContext, n: PNode): PNode

proc semExprBranch(c: PContext, n: PNode): PNode =
  result = semExpr(c, n)
  if result.typ != nil:
    # XXX tyGenericInst here?
    semProcvarCheck(c, result)
    if result.typ.kind in {tyVar, tyLent}: result = newDeref(result)

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
  if c.matchedConcept != nil: return
  if result.typ != nil and result.typ.kind notin {tyStmt, tyVoid}:
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
        var s = "expression '" & $n & "' is of type '" &
            result.typ.typeToString & "' and has to be discarded"
        if result.info.line != n.info.line or
           result.info.fileIndex != n.info.fileIndex:
          s.add "; start of expression here: " & $result.info
        if result.typ.kind == tyProc:
          s.add "; for a function call use ()"
        localError(n.info, s)

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
      typ = commonType(typ, it.sons[1])
      closeScope(c)
    elif it.len == 1:
      hasElse = true
      it.sons[0] = semExprBranchScope(c, it.sons[0])
      typ = commonType(typ, it.sons[0])
    else: illFormedAst(it)
  if isEmptyType(typ) or typ.kind in {tyNil, tyExpr} or not hasElse:
    for it in n: discardCheck(c, it.lastSon)
    result.kind = nkIfStmt
    # propagate any enforced VoidContext:
    if typ == enforceVoidContext: result.typ = enforceVoidContext
  else:
    for it in n:
      let j = it.len-1
      if not endsInNoReturn(it.sons[j]):
        it.sons[j] = fitNode(c, typ, it.sons[j], it.sons[j].info)
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
  let caseTyp = skipTypes(n.sons[0].typ, abstractVarRange-{tyTypeDesc})
  case caseTyp.kind
  of tyInt..tyInt64, tyChar, tyEnum, tyUInt..tyUInt32, tyBool:
    chckCovered = true
  of tyFloat..tyFloat128, tyString, tyError:
    discard
  else:
    localError(n.info, errSelectorMustBeOfCertainTypes)
    return
  for i in countup(1, sonsLen(n) - 1):
    var x = n.sons[i]
    when defined(nimsuggest):
      if gIdeCmd == ideSug and exactEquals(gTrackPos, x.info) and caseTyp.kind == tyEnum:
        suggestEnum(c, x, caseTyp)
    case x.kind
    of nkOfBranch:
      checkMinSonsLen(x, 2)
      semCaseBranch(c, n, x, i, covered)
      var last = sonsLen(x)-1
      x.sons[last] = semExprBranchScope(c, x.sons[last])
      typ = commonType(typ, x.sons[last])
    of nkElifBranch:
      chckCovered = false
      checkSonsLen(x, 2)
      when newScopeForIf: openScope(c)
      x.sons[0] = forceBool(c, semExprWithType(c, x.sons[0]))
      when not newScopeForIf: openScope(c)
      x.sons[1] = semExprBranch(c, x.sons[1])
      typ = commonType(typ, x.sons[1])
      closeScope(c)
    of nkElse:
      chckCovered = false
      checkSonsLen(x, 1)
      x.sons[0] = semExprBranchScope(c, x.sons[0])
      typ = commonType(typ, x.sons[0])
      hasElse = true
    else:
      illFormedAst(x)
  if chckCovered:
    if covered == toCover(n.sons[0].typ):
      hasElse = true
    else:
      localError(n.info, errNotAllCasesCovered)
  closeScope(c)
  if isEmptyType(typ) or typ.kind in {tyNil, tyExpr} or not hasElse:
    for i in 1..n.len-1: discardCheck(c, n.sons[i].lastSon)
    # propagate any enforced VoidContext:
    if typ == enforceVoidContext:
      result.typ = enforceVoidContext
  else:
    for i in 1..n.len-1:
      var it = n.sons[i]
      let j = it.len-1
      if not endsInNoReturn(it.sons[j]):
        it.sons[j] = fitNode(c, typ, it.sons[j], it.sons[j].info)
    result.typ = typ

proc semTry(c: PContext, n: PNode): PNode =

  var check = initIntSet()
  template semExceptBranchType(typeNode: PNode): PNode =
    let typ = semTypeNode(c, typeNode, nil).toObject()
    if typ.kind != tyObject:
      localError(typeNode.info, errExprCannotBeRaised)
    if containsOrIncl(check, typ.id):
      localError(typeNode.info, errExceptionAlreadyHandled)
    newNodeIT(nkType, typeNode.info, typ)

  result = n
  inc c.p.inTryStmt
  checkMinSonsLen(n, 2)

  var typ = commonTypeBegin
  n[0] = semExprBranchScope(c, n[0])
  typ = commonType(typ, n[0].typ)

  var last = sonsLen(n) - 1
  for i in countup(1, last):
    let a = n.sons[i]
    checkMinSonsLen(a, 1)
    openScope(c)
    if a.kind == nkExceptBranch:

      if a.len == 2 and a[0].kind == nkBracket:
        # rewrite ``except [a, b, c]: body`` -> ```except a, b, c: body```
        a.sons[0..0] = a[0].sons
      
      if a.len == 2 and a[0].isInfixAs():
        # support ``except Exception as ex: body``
        a[0][1] = semExceptBranchType(a[0][1])

        let symbol = newSymG(skLet, a[0][2], c)
        symbol.typ = a[0][1].typ.toRef()
        addDecl(c, symbol)
        # Overwrite symbol in AST with the symbol in the symbol table.
        a[0][2] = newSymNode(symbol, a[0][2].info)

      else:
        # support ``except KeyError, ValueError, ... : body``
        for j in 0..a.len-2:
          a[j] = semExceptBranchType(a[j])
     
    elif a.kind != nkFinally:
      illFormedAst(n)

    # last child of an nkExcept/nkFinally branch is a statement:
    a[^1] = semExprBranchScope(c, a[^1])
    if a.kind != nkFinally: typ = commonType(typ, a[^1])
    else: dec last
    closeScope(c)

  dec c.p.inTryStmt
  if isEmptyType(typ) or typ.kind in {tyNil, tyExpr}:
    discardCheck(c, n.sons[0])
    for i in 1..n.len-1: discardCheck(c, n.sons[i].lastSon)
    if typ == enforceVoidContext:
      result.typ = enforceVoidContext
  else:
    if n.lastSon.kind == nkFinally: discardCheck(c, n.lastSon.lastSon)
    n.sons[0] = fitNode(c, typ, n.sons[0], n.sons[0].info)
    for i in 1..last:
      var it = n.sons[i]
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j], it.sons[j].info)
    result.typ = typ

proc fitRemoveHiddenConv(c: PContext, typ: PType, n: PNode): PNode =
  result = fitNode(c, typ, n, n.info)
  if result.kind in {nkHiddenStdConv, nkHiddenSubConv}:
    let r1 = result.sons[1]
    if r1.kind in {nkCharLit..nkUInt64Lit} and typ.skipTypes(abstractRange).kind in {tyFloat..tyFloat128}:
      result = newFloatNode(nkFloatLit, BiggestFloat r1.intVal)
      result.info = n.info
      result.typ = typ
    else:
      changeType(r1, typ, check=true)
      result = r1
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
    #if kind in {skVar, skLet}:
    #  echo "global variable here ", n.info, " ", result.name.s
  else:
    result = semIdentWithPragma(c, kind, n, {})
    if result.owner.kind == skModule:
      incl(result.flags, sfGlobal)
  suggestSym(n.info, result, c.graph.usageSym)
  styleCheckDef(result)

proc checkNilable(v: PSym) =
  if {sfGlobal, sfImportC} * v.flags == {sfGlobal} and
      {tfNotNil, tfNeedsInit} * v.typ.flags != {}:
    if v.ast.isNil:
      message(v.info, warnProveInit, v.name.s)
    elif tfNotNil in v.typ.flags and tfNotNil notin v.ast.typ.flags:
      message(v.info, warnProveInit, v.name.s)

include semasgn

proc addToVarSection(c: PContext; result: var PNode; orig, identDefs: PNode) =
  # consider this:
  #   var
  #     x = 0
  #     withOverloadedAssignment = foo()
  #     y = use(withOverloadedAssignment)
  # We need to split this into a statement list with multiple 'var' sections
  # in order for this transformation to be correct.
  let L = identDefs.len
  let value = identDefs[L-1]
  if value.typ != nil and tfHasAsgn in value.typ.flags and not newDestructors:
    # the spec says we need to rewrite 'var x = T()' to 'var x: T; x = T()':
    identDefs.sons[L-1] = emptyNode
    if result.kind != nkStmtList:
      let oldResult = result
      oldResult.add identDefs
      result = newNodeI(nkStmtList, result.info)
      result.add oldResult
    else:
      let o = copyNode(orig)
      o.add identDefs
      result.add o
    for i in 0 .. L-3:
      result.add overloadedAsgn(c, identDefs[i], value)
  elif result.kind == nkStmtList:
    let o = copyNode(orig)
    o.add identDefs
    result.add o
  else:
    result.add identDefs

proc isDiscardUnderscore(v: PSym): bool =
  if v.name.s == "_":
    v.flags.incl(sfGenSym)
    result = true

proc semUsing(c: PContext; n: PNode): PNode =
  result = ast.emptyNode
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "using")
  for i in countup(0, sonsLen(n)-1):
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if a.kind notin {nkIdentDefs, nkVarTuple, nkConstDef}: illFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    if a.sons[length-2].kind != nkEmpty:
      let typ = semTypeNode(c, a.sons[length-2], nil)
      for j in countup(0, length-3):
        let v = semIdentDef(c, a.sons[j], skParam)
        v.typ = typ
        strTableIncl(c.signatures, v)
    else:
      localError(a.info, "'using' section must have a type")
    var def: PNode
    if a.sons[length-1].kind != nkEmpty:
      localError(a.info, "'using' sections cannot contain assignments")

proc hasEmpty(typ: PType): bool =
  if typ.kind in {tySequence, tyArray, tySet}:
    result = typ.lastSon.kind == tyEmpty
  elif typ.kind == tyTuple:
    for s in typ.sons:
      result = result or hasEmpty(s)

proc makeDeref(n: PNode): PNode =
  var t = n.typ
  if t.kind in tyUserTypeClasses and t.isResolvedUserTypeClass:
    t = t.lastSon
  t = skipTypes(t, {tyGenericInst, tyAlias, tySink})
  result = n
  if t.kind in {tyVar, tyLent}:
    result = newNodeIT(nkHiddenDeref, n.info, t.sons[0])
    addSon(result, n)
    t = skipTypes(t.sons[0], {tyGenericInst, tyAlias, tySink})
  while t.kind in {tyPtr, tyRef}:
    var a = result
    let baseTyp = t.lastSon
    result = newNodeIT(nkHiddenDeref, n.info, baseTyp)
    addSon(result, a)
    t = skipTypes(baseTyp, {tyGenericInst, tyAlias, tySink})

proc fillPartialObject(c: PContext; n: PNode; typ: PType) =
  if n.len == 2:
    let x = semExprWithType(c, n[0])
    let y = considerQuotedIdent(n[1])
    let obj = x.typ.skipTypes(abstractPtrs)
    if obj.kind == tyObject and tfPartial in obj.flags:
      let field = newSym(skField, getIdent(y.s), obj.sym, n[1].info)
      field.typ = skipIntLit(typ)
      field.position = sonsLen(obj.n)
      addSon(obj.n, newSymNode(field))
      n.sons[0] = makeDeref x
      n.sons[1] = newSymNode(field)
      n.typ = field.typ
    else:
      localError(n.info, "implicit object field construction " &
        "requires a .partial object, but got " & typeToString(obj))
  else:
    localError(n.info, "nkDotNode requires 2 children")

proc setVarType(v: PSym, typ: PType) =
  if v.typ != nil and not sameTypeOrNil(v.typ, typ):
    localError(v.info, "inconsistent typing for reintroduced symbol '" &
        v.name.s & "': previous type was: " & typeToString(v.typ) &
        "; new type is: " & typeToString(typ))
  v.typ = typ

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
    var def: PNode = ast.emptyNode
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
          def = fitNode(c, typ, def, def.info)
          #changeType(def.skipConv, typ, check=true)
      else:
        typ = skipIntLit(def.typ)
        if typ.kind in tyUserTypeClasses and typ.isResolvedUserTypeClass:
          typ = typ.lastSon
        if hasEmpty(typ):
          localError(def.info, errCannotInferTypeOfTheLiteral,
                     ($typ.kind).substr(2).toLowerAscii)
        elif typ.kind == tyProc and tfUnresolved in typ.flags:
          localError(def.info, errProcHasNoConcreteType, def.renderTree)
    else:
      if symkind == skLet: localError(a.info, errLetNeedsInit)

    # this can only happen for errornous var statements:
    if typ == nil: continue
    typeAllowedCheck(a.info, typ, symkind, if c.matchedConcept != nil: {taConcept} else: {})
    liftTypeBoundOps(c, typ, a.info)
    var tup = skipTypes(typ, {tyGenericInst, tyAlias, tySink})
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
        addToVarSection(c, result, n, b)
    elif tup.kind == tyTuple and def.kind == nkPar and
        a.kind == nkIdentDefs and a.len > 3:
      message(a.info, warnEachIdentIsTuple)

    for j in countup(0, length-3):
      if a[j].kind == nkDotExpr:
        fillPartialObject(c, a[j],
          if a.kind != nkVarTuple: typ else: tup.sons[j])
        addToVarSection(c, result, n, a)
        continue
      var v = semIdentDef(c, a.sons[j], symkind)
      if sfGenSym notin v.flags and not isDiscardUnderscore(v):
        addInterfaceDecl(c, v)
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
        if def.kind != nkEmpty:
          # this is needed for the evaluation pass and for the guard checking:
          v.ast = def
          if sfThread in v.flags: localError(def.info, errThreadvarCannotInit)
        setVarType(v, typ)
        b = newNodeI(nkIdentDefs, a.info)
        if importantComments():
          # keep documentation information:
          b.comment = a.comment
        addSon(b, newSymNode(v))
        addSon(b, a.sons[length-2])      # keep type desc for doc generator
        addSon(b, copyTree(def))
        addToVarSection(c, result, n, b)
      else:
        if def.kind == nkPar: v.ast = def[j]
        setVarType(v, tup.sons[j])
        b.sons[j] = newSymNode(v)
      checkNilable(v)
      if sfCompileTime in v.flags: hasCompileTime = true
  if hasCompileTime: vm.setupCompileTimeVar(c.module, c.cache, result)

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
      localError(a.info, "invalid type for const: " & typeToString(typ))
      continue
    setVarType(v, typ)
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
  let iterBase = n.sons[length-2].typ
  var iter = skipTypes(iterBase, {tyGenericInst, tyAlias, tySink})
  # length == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if iter.kind != tyTuple or length == 3:
    if length == 3:
      var v = symForVar(c, n.sons[0])
      if getCurrOwner(c).kind == skModule: incl(v.flags, sfGlobal)
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
      if getCurrOwner(c).kind == skModule: incl(v.flags, sfGlobal)
      v.typ = iter.sons[i]
      n.sons[i] = newSymNode(v)
      if sfGenSym notin v.flags and not isDiscardUnderscore(v):
        addForVarDecl(c, v)
  inc(c.p.nestedLoopCounter)
  openScope(c)
  n.sons[length-1] = semStmt(c, n.sons[length-1])
  closeScope(c)
  dec(c.p.nestedLoopCounter)

proc implicitIterator(c: PContext, it: string, arg: PNode): PNode =
  result = newNodeI(nkCall, arg.info)
  result.add(newIdentNode(it.getIdent, arg.info))
  if arg.typ != nil and arg.typ.kind in {tyVar, tyLent}:
    result.add newDeref(arg)
  else:
    result.add arg
  result = semExprNoDeref(c, result, {efWantIterator})

proc isTrivalStmtExpr(n: PNode): bool =
  for i in 0 .. n.len-2:
    if n[i].kind notin {nkEmpty, nkCommentStmt}:
      return false
  result = true

proc semFor(c: PContext, n: PNode): PNode =
  result = n
  checkMinSonsLen(n, 3)
  var length = sonsLen(n)
  openScope(c)
  n.sons[length-2] = semExprNoDeref(c, n.sons[length-2], {efWantIterator})
  var call = n.sons[length-2]
  if call.kind == nkStmtListExpr and isTrivalStmtExpr(call):
    call = call.lastSon
    n.sons[length-2] = call
  let isCallExpr = call.kind in nkCallKinds
  if isCallExpr and call[0].kind == nkSym and
      call[0].sym.magic in {mFields, mFieldPairs, mOmpParFor}:
    if call.sons[0].sym.magic == mOmpParFor:
      result = semForVars(c, n)
      result.kind = nkParForStmt
    else:
      result = semForFields(c, n, call.sons[0].sym.magic)
  elif isCallExpr and call.sons[0].typ.callConv == ccClosure and
      tfIterator in call.sons[0].typ.flags:
    # first class iterator:
    result = semForVars(c, n)
  elif not isCallExpr or call.sons[0].kind != nkSym or
      call.sons[0].sym.kind != skIterator:
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
    if typ.kind != tyRef or typ.lastSon.kind != tyObject:
      localError(n.info, errExprCannotBeRaised)

    # check if the given object inherits from Exception
    if not typ.lastSon.isException():
        localError(n.info, "raised object of type $1 does not inherit from Exception",
                           [typeToString(typ)])


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
    when defined(nimsuggest):
      if gCmd == cmdIdeTools:
        inc c.inTypeContext
        suggestStmt(c, a)
        dec c.inTypeContext
    if a.kind == nkCommentStmt: continue
    if a.kind != nkTypeDef: illFormedAst(a)
    checkSonsLen(a, 3)
    let name = a.sons[0]
    var s: PSym
    if name.kind == nkDotExpr and a[2].kind == nkObjectTy:
      let pkgName = considerQuotedIdent(name[0])
      let typName = considerQuotedIdent(name[1])
      let pkg = c.graph.packageSyms.strTableGet(pkgName)
      if pkg.isNil or pkg.kind != skPackage:
        localError(name.info, "unknown package name: " & pkgName.s)
      else:
        let typsym = pkg.tab.strTableGet(typName)
        if typsym.isNil:
          s = semIdentDef(c, name[1], skType)
          s.typ = newTypeS(tyObject, c)
          s.typ.sym = s
          s.flags.incl sfForward
          pkg.tab.strTableAdd s
          addInterfaceDecl(c, s)
        elif typsym.kind == skType and sfForward in typsym.flags:
          s = typsym
          addInterfaceDecl(c, s)
        else:
          localError(name.info, typsym.name.s & " is not a type that can be forwarded")
          s = typsym
    else:
      s = semIdentDef(c, name, skType)
      s.typ = newTypeS(tyForward, c)
      s.typ.sym = s             # process pragmas:
      if name.kind == nkPragmaExpr:
        pragma(c, s, name.sons[1], typePragmas)
      if sfForward in s.flags:
        # check if the symbol already exists:
        let pkg = c.module.owner
        if not isTopLevel(c) or pkg.isNil:
          localError(name.info, "only top level types in a package can be 'package'")
        else:
          let typsym = pkg.tab.strTableGet(s.name)
          if typsym != nil:
            if sfForward notin typsym.flags or sfNoForward notin typsym.flags:
              typeCompleted(typsym)
              typsym.info = s.info
            else:
              localError(name.info, "cannot complete type '" & s.name.s & "' twice; " &
                      "previous type completion was here: " & $typsym.info)
            s = typsym
      # add it here, so that recursive types are possible:
      if sfGenSym notin s.flags: addInterfaceDecl(c, s)

    a.sons[0] = newSymNode(s)

proc checkCovariantParamsUsages(genericType: PType) =
  var body = genericType[^1]

  proc traverseSubTypes(t: PType): bool =
    template error(msg) = localError(genericType.sym.info, msg)

    result = false

    template subresult(r) =
      let sub = r
      result = result or sub

    case t.kind
    of tyGenericParam:
      t.flags.incl tfWeakCovariant
      return true

    of tyObject:
      for field in t.n:
        subresult traverseSubTypes(field.typ)

    of tyArray:
      return traverseSubTypes(t[1])

    of tyProc:
      for subType in t.sons:
        if subType != nil:
          subresult traverseSubTypes(subType)
      if result:
        error("non-invariant type param used in a proc type: " &  $t)

    of tySequence:
      return traverseSubTypes(t[0])

    of tyGenericInvocation:
      let targetBody = t[0]
      for i in 1 ..< t.len:
        let param = t[i]
        if param.kind == tyGenericParam:
          if tfCovariant in param.flags:
            let formalFlags = targetBody[i-1].flags
            if tfCovariant notin formalFlags:
              error("covariant param '" & param.sym.name.s &
                    "' used in a non-covariant position")
            elif tfWeakCovariant in formalFlags:
              param.flags.incl tfWeakCovariant
            result = true
          elif tfContravariant in param.flags:
            let formalParam = targetBody[i-1].sym
            if tfContravariant notin formalParam.typ.flags:
              error("contravariant param '" & param.sym.name.s &
                    "' used in a non-contravariant position")
            result = true
        else:
          subresult traverseSubTypes(param)

    of tyAnd, tyOr, tyNot, tyStatic, tyBuiltInTypeClass, tyCompositeTypeClass:
      error("non-invariant type parameters cannot be used with types such '" & $t & "'")

    of tyUserTypeClass, tyUserTypeClassInst:
      error("non-invariant type parameters are not supported in concepts")

    of tyTuple:
      for fieldType in t.sons:
        subresult traverseSubTypes(fieldType)

    of tyPtr, tyRef, tyVar, tyLent:
      if t.base.kind == tyGenericParam: return true
      return traverseSubTypes(t.base)

    of tyDistinct, tyAlias, tySink:
      return traverseSubTypes(t.lastSon)

    of tyGenericInst:
      internalAssert false

    else:
      discard

  discard traverseSubTypes(body)

proc typeSectionRightSidePass(c: PContext, n: PNode) =
  for i in countup(0, sonsLen(n) - 1):
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue
    if (a.kind != nkTypeDef): illFormedAst(a)
    checkSonsLen(a, 3)
    let name = a.sons[0]
    if (name.kind != nkSym): illFormedAst(a)
    var s = name.sym
    if s.magic == mNone and a.sons[2].kind == nkEmpty:
      localError(a.info, errImplOfXexpected, s.name.s)
    if s.magic != mNone: processMagicType(c, s)
    if a.sons[1].kind != nkEmpty:
      # We have a generic type declaration here. In generic types,
      # symbol lookup needs to be done here.
      openScope(c)
      pushOwner(c, s)
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
      # so we use tyNone instead of nil to not crash for strange conversions
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
        if tfCovariant in s.typ.flags:
          checkCovariantParamsUsages(s.typ)
          # XXX: This is a temporary limitation:
          # The codegen currently produces various failures with
          # generic imported types that have fields, but we need
          # the fields specified in order to detect weak covariance.
          # The proper solution is to teach the codegen how to handle
          # such types, because this would offer various interesting
          # possibilities such as instantiating C++ generic types with
          # garbage collected Nim types.
          if sfImportc in s.flags:
            var body = s.typ.lastSon
            if body.kind == tyObject:
              # erases all declared fields
              body.n.sons = nil

      popOwner(c)
      closeScope(c)
    elif a.sons[2].kind != nkEmpty:
      # process the type's body:
      pushOwner(c, s)
      var t = semTypeNode(c, a.sons[2], s.typ)
      if s.typ == nil:
        s.typ = t
      elif t != s.typ and (s.typ == nil or s.typ.kind != tyAlias):
        # this can happen for e.g. tcan_alias_specialised_generic:
        assignType(s.typ, t)
        #debug s.typ
      s.ast = a
      popOwner(c)
    let aa = a.sons[2]
    if aa.kind in {nkRefTy, nkPtrTy} and aa.len == 1 and
       aa.sons[0].kind == nkObjectTy:
      # give anonymous object a dummy symbol:
      var st = s.typ
      if st.kind == tyGenericBody: st = st.lastSon
      internalAssert st.kind in {tyPtr, tyRef}
      internalAssert st.lastSon.sym == nil
      incl st.flags, tfRefsAnonObj
      let obj = newSym(skType, getIdent(s.name.s & ":ObjectType"),
                              getCurrOwner(c), s.info)
      obj.typ = st.lastSon
      st.lastSon.sym = obj


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
    of tySequence, tySet, tyArray, tyOpenArray, tyVar, tyLent, tyPtr, tyRef,
       tyProc, tyGenericInvocation, tyGenericInst, tyAlias, tySink:
      let start = int ord(t.kind in {tyGenericInvocation, tyGenericInst})
      for i in start ..< t.sons.len:
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
      var x = a[2]
      while x.kind in {nkStmtList, nkStmtListExpr} and x.len > 0:
        x = x.lastSon
      if x.kind notin {nkObjectTy, nkDistinctTy, nkEnumTy, nkEmpty} and
          s.typ.kind notin {tyObject, tyEnum}:
        # type aliases are hard:
        var t = semTypeNode(c, x, nil)
        assert t != nil
        if s.typ != nil and s.typ.kind notin {tyAlias, tySink}:
          if t.kind in {tyProc, tyGenericInst} and not t.isMetaType:
            assignType(s.typ, t)
            s.typ.id = t.id
          elif t.kind in {tyObject, tyEnum, tyDistinct}:
            assert s.typ != nil
            assignType(s.typ, t)
            s.typ.id = t.id     # same id
      checkConstructedType(s.info, s.typ)
      if s.typ.kind in {tyObject, tyTuple} and not s.typ.n.isNil:
        checkForMetaFields(s.typ.n)
  instAllTypeBoundOp(c, n.info)


proc semAllTypeSections(c: PContext; n: PNode): PNode =
  proc gatherStmts(c: PContext; n: PNode; result: PNode) {.nimcall.} =
    case n.kind
    of nkIncludeStmt:
      for i in 0..<n.len:
        var f = checkModuleName(n.sons[i])
        if f != InvalidFileIDX:
          if containsOrIncl(c.includedFiles, f):
            localError(n.info, errRecursiveDependencyX, f.toFilename)
          else:
            let code = gIncludeFile(c.graph, c.module, f, c.cache)
            gatherStmts c, code, result
            excl(c.includedFiles, f)
    of nkStmtList:
      for i in 0 ..< n.len:
        gatherStmts(c, n.sons[i], result)
    of nkTypeSection:
      incl n.flags, nfSem
      typeSectionLeftSidePass(c, n)
      result.add n
    else:
      result.add n

  result = newNodeI(nkStmtList, n.info)
  gatherStmts(c, n, result)

  template rec(name) =
    for i in 0 ..< result.len:
      if result[i].kind == nkTypeSection:
        name(c, result[i])

  rec typeSectionRightSidePass
  rec typeSectionFinalPass
  when false:
    # too beautiful to delete:
    template rec(name; setbit=false) =
      proc `name rec`(c: PContext; n: PNode) {.nimcall.} =
        if n.kind == nkTypeSection:
          when setbit: incl n.flags, nfSem
          name(c, n)
        elif n.kind == nkStmtList:
          for i in 0 ..< n.len:
            `name rec`(c, n.sons[i])
      `name rec`(c, n)
    rec typeSectionLeftSidePass, true
    rec typeSectionRightSidePass
    rec typeSectionFinalPass

proc semTypeSection(c: PContext, n: PNode): PNode =
  ## Processes a type section. This must be done in separate passes, in order
  ## to allow the type definitions in the section to reference each other
  ## without regard for the order of their definitions.
  if sfNoForward notin c.module.flags or nfSem notin n.flags:
    inc c.inTypeContext
    typeSectionLeftSidePass(c, n)
    typeSectionRightSidePass(c, n)
    typeSectionFinalPass(c, n)
    dec c.inTypeContext
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
    var s = newSym(skResult, getIdent"result", getCurrOwner(c), info)
    s.typ = t
    incl(s.flags, sfUsed)
    addParamOrResult(c, s, owner)
    c.p.resultSym = s

proc addResultNode(c: PContext, n: PNode) =
  if c.p.resultSym != nil: addSon(n, newSymNode(c.p.resultSym))

proc copyExcept(n: PNode, i: int): PNode =
  result = copyNode(n)
  for j in 0..<n.len:
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
  for i in countup(0, n.len-1):
    var it = n.sons[i]
    var key = if it.kind in nkPragmaCallKinds and it.len >= 1: it.sons[0] else: it
    let m = lookupMacro(c, key)
    if m == nil:
      if key.kind == nkIdent and key.ident.id == ord(wDelegator):
        if considerQuotedIdent(prc.sons[namePos]).s == "()":
          prc.sons[namePos] = newIdentNode(c.cache.idDelegator, prc.info)
          prc.sons[pragmasPos] = copyExcept(n, i)
        else:
          localError(prc.info, errOnlyACallOpCanBeDelegator)
      continue
    elif sfCustomPragma in m.flags:
      continue # semantic check for custom pragma happens later in semProcAux

    # we transform ``proc p {.m, rest.}`` into ``m(do: proc p {.rest.})`` and
    # let the semantic checker deal with it:
    var x = newNodeI(nkCall, n.info)
    x.add(newSymNode(m))
    prc.sons[pragmasPos] = copyExcept(n, i)
    if prc[pragmasPos].kind != nkEmpty and prc[pragmasPos].len == 0:
      prc.sons[pragmasPos] = emptyNode

    if it.kind in nkPragmaCallKinds and it.len > 1:
      # pass pragma arguments to the macro too:
      for i in 1..<it.len:
        x.add(it.sons[i])
    x.add(prc)

    # recursion assures that this works for multiple macro annotations too:
    result = semExpr(c, x)
    # since a proc annotation can set pragmas, we process these here again.
    # This is required for SqueakNim-like export pragmas.
    if result.kind in procDefs and result[namePos].kind == nkSym and
        result[pragmasPos].kind != nkEmpty:
      pragma(c, result[namePos].sym, result[pragmasPos], validPragmas)
    return

proc setGenericParamsMisc(c: PContext; n: PNode): PNode =
  let orig = n.sons[genericParamsPos]
  # we keep the original params around for better error messages, see
  # issue https://github.com/nim-lang/Nim/issues/1713
  result = semGenericParamList(c, orig)
  if n.sons[miscPos].kind == nkEmpty:
    n.sons[miscPos] = newTree(nkBracket, ast.emptyNode, orig)
  else:
    n.sons[miscPos].sons[1] = orig
  n.sons[genericParamsPos] = result

proc semLambda(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # XXX semProcAux should be good enough for this now, we will eventually
  # remove semLambda
  result = semProcAnnotation(c, n, lambdaPragmas)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s: PSym
  if n[namePos].kind != nkSym:
    s = newSym(skProc, c.cache.idAnon, getCurrOwner(c), n.info)
    s.ast = n
    n.sons[namePos] = newSymNode(s)
  else:
    s = n[namePos].sym
  pushOwner(c, s)
  openScope(c)
  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty:
    gp = setGenericParamsMisc(c, n)
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
  popOwner(c)
  result.typ = s.typ

proc semInferredLambda(c: PContext, pt: TIdTable, n: PNode): PNode =
  var n = n

  let original = n.sons[namePos].sym
  let s = original #copySym(original, false)
  #incl(s.flags, sfFromGeneric)
  #s.owner = original

  n = replaceTypesInBody(c, pt, n, original)
  result = n
  s.ast = result
  n.sons[namePos].sym = s
  n.sons[genericParamsPos] = emptyNode
  # for LL we need to avoid wrong aliasing
  let params = copyTree n.typ.n
  n.sons[paramsPos] = params
  s.typ = n.typ
  for i in 1..<params.len:
    if params[i].typ.kind in {tyTypeDesc, tyGenericParam,
                              tyFromExpr}+tyTypeClasses:
      localError(params[i].info, "cannot infer type of parameter: " &
                 params[i].sym.name.s)
    #params[i].sym.owner = s
  openScope(c)
  pushOwner(c, s)
  addParams(c, params, skProc)
  pushProcCon(c, s)
  addResult(c, n.typ.sons[0], n.info, skProc)
  addResultNode(c, n)
  let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
  n.sons[bodyPos] = transformBody(c.module, semBody, s)
  popProcCon(c)
  popOwner(c)
  closeScope(c)

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
      for i in 1 ..< n.len: activate(c, n[i])
    else:
      discard

proc maybeAddResult(c: PContext, s: PSym, n: PNode) =
  if s.typ.sons[0] != nil and not
      (s.kind == skIterator and s.typ.callConv != ccClosure):
    addResult(c, s.typ.sons[0], n.info, s.kind)
    addResultNode(c, n)

proc semOverride(c: PContext, s: PSym, n: PNode) =
  case s.name.s.normalize
  of "destroy", "=destroy":
    if newDestructors:
      let t = s.typ
      var noError = false
      if t.len == 2 and t.sons[0] == nil and t.sons[1].kind == tyVar:
        var obj = t.sons[1].sons[0]
        while true:
          incl(obj.flags, tfHasAsgn)
          if obj.kind in {tyGenericBody, tyGenericInst}: obj = obj.lastSon
          elif obj.kind == tyGenericInvocation: obj = obj.sons[0]
          else: break
        if obj.kind in {tyObject, tyDistinct}:
          if obj.destructor.isNil:
            obj.destructor = s
          else:
            localError(n.info, errGenerated,
              "cannot bind another '" & s.name.s & "' to: " & typeToString(obj))
          noError = true
      if not noError and sfSystemModule notin s.owner.flags:
        localError(n.info, errGenerated,
          "signature for '" & s.name.s & "' must be proc[T: object](x: var T)")
    incl(s.flags, sfUsed)
  of "deepcopy", "=deepcopy":
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
    incl(s.flags, sfUsed)
  of "=", "=sink":
    if s.magic == mAsgn: return
    incl(s.flags, sfUsed)
    let t = s.typ
    if t.len == 3 and t.sons[0] == nil and t.sons[1].kind == tyVar:
      var obj = t.sons[1].sons[0]
      while true:
        incl(obj.flags, tfHasAsgn)
        if obj.kind == tyGenericBody: obj = obj.lastSon
        elif obj.kind == tyGenericInvocation: obj = obj.sons[0]
        else: break
      var objB = t.sons[2]
      while true:
        if objB.kind == tyGenericBody: objB = objB.lastSon
        elif objB.kind in {tyGenericInvocation, tyGenericInst}:
          objB = objB.sons[0]
        else: break
      if obj.kind in {tyObject, tyDistinct} and sameType(obj, objB):
        let opr = if s.name.s == "=": addr(obj.assignment) else: addr(obj.sink)
        if opr[].isNil:
          opr[] = s
        else:
          localError(n.info, errGenerated,
                     "cannot bind another '" & s.name.s & "' to: " & typeToString(obj))
        return
    if sfSystemModule notin s.owner.flags:
      localError(n.info, errGenerated,
                "signature for '" & s.name.s & "' must be proc[T: object](x: var T; y: T)")
  else:
    if sfOverriden in s.flags:
      localError(n.info, errGenerated,
                 "'destroy' or 'deepCopy' expected for 'override'")

proc cursorInProcAux(n: PNode): bool =
  if inCheckpoint(n.info) != cpNone: return true
  for i in 0..<n.safeLen:
    if cursorInProcAux(n[i]): return true

proc cursorInProc(n: PNode): bool =
  if n.info.fileIndex == gTrackPos.fileIndex:
    result = cursorInProcAux(n)

type
  TProcCompilationSteps = enum
    stepRegisterSymbol,
    stepDetermineType,

proc hasObjParam(s: PSym): bool =
  var t = s.typ
  for col in countup(1, sonsLen(t)-1):
    if skipTypes(t.sons[col], skipPtrs).kind == tyObject:
      return true

proc finishMethod(c: PContext, s: PSym) =
  if hasObjParam(s):
    methodDef(c.graph, s, false)

proc semMethodPrototype(c: PContext; s: PSym; n: PNode) =
  if isGenericRoutine(s):
    let tt = s.typ
    var foundObj = false
    # we start at 1 for now so that tparsecombnum continues to compile.
    # XXX Revisit this problem later.
    for col in countup(1, sonsLen(tt)-1):
      let t = tt.sons[col]
      if t != nil and t.kind == tyGenericInvocation:
        var x = skipTypes(t.sons[0], {tyVar, tyLent, tyPtr, tyRef, tyGenericInst,
                                      tyGenericInvocation, tyGenericBody,
                                      tyAlias, tySink})
        if x.kind == tyObject and t.len-1 == n.sons[genericParamsPos].len:
          foundObj = true
          x.methods.safeAdd((col,s))
    if not foundObj:
      message(n.info, warnDeprecated, "generic method not attachable to object type")
  else:
    # why check for the body? bug #2400 has none. Checking for sfForward makes
    # no sense either.
    # and result.sons[bodyPos].kind != nkEmpty:
    if hasObjParam(s):
      methodDef(c.graph, s, fromCache=false)
    else:
      localError(n.info, errXNeedsParamObjectType, "method")

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
      s = newSym(kind, c.cache.idAnon, getCurrOwner(c), n.info)
      incl(s.flags, sfUsed)
      isAnon = true
    else:
      s = semIdentDef(c, n.sons[0], kind)
    n.sons[namePos] = newSymNode(s)
    s.ast = n
    #s.scope = c.currentScope
    when false:
      # disable for now
      if sfNoForward in c.module.flags and
         sfSystemModule notin c.module.flags:
        addInterfaceOverloadableSymAt(c, c.currentScope, s)
        s.flags.incl sfForward
        return
  else:
    s = n[namePos].sym
    s.owner = getCurrOwner(c)
    typeIsDetermined = s.typ == nil
    s.ast = n
    #s.scope = c.currentScope

  # before compiling the proc body, set as current the scope
  # where the proc was declared
  let oldScope = c.currentScope
  #c.currentScope = s.scope
  pushOwner(c, s)
  openScope(c)
  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty:
    gp = setGenericParamsMisc(c, n)
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
  if tfTriggersCompileTime in s.typ.flags: incl(s.flags, sfCompileTime)
  if n.sons[patternPos].kind != nkEmpty:
    n.sons[patternPos] = semPattern(c, n.sons[patternPos])
  if s.kind == skIterator:
    s.typ.flags.incl(tfIterator)

  var proto = searchForProc(c, oldScope, s)
  if proto == nil or isAnon:
    if s.kind == skIterator:
      if s.typ.callConv != ccClosure:
        s.typ.callConv = if isAnon: ccClosure else: ccInline
    else:
      s.typ.callConv = lastOptionEntry(c).defaultCC
    # add it here, so that recursive procs are possible:
    if sfGenSym in s.flags: discard
    elif kind in OverloadableSyms:
      if not typeIsDetermined:
        addInterfaceOverloadableSymAt(c, oldScope, s)
    else:
      if not typeIsDetermined:
        addInterfaceDeclAt(c, oldScope, s)
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, s, n.sons[pragmasPos], validPragmas)
    else:
      implicitPragmas(c, s, n, validPragmas)
  else:
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, s, n.sons[pragmasPos], validPragmas)
      # To ease macro generation that produce forwarded .async procs we now
      # allow a bit redudancy in the pragma declarations. The rule is
      # a prototype's pragma list must be a superset of the current pragma
      # list.
      # XXX This needs more checks eventually, for example that external
      # linking names do agree:
      if proto.typ.callConv != s.typ.callConv or proto.typ.flags < s.typ.flags:
        localError(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProcX,
          "'" & proto.name.s & "' from " & $proto.info)
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
    popOwner(c)
    pushOwner(c, s)
  s.options = gOptions
  if sfOverriden in s.flags or s.name.s[0] == '=': semOverride(c, s, n)
  if s.name.s[0] in {'.', '('}:
    if s.name.s in [".", ".()", ".="] and not experimentalMode(c) and not newDestructors:
      message(n.info, warnDeprecated, "overloaded '.' and '()' operators are now .experimental; " & s.name.s)
    elif s.name.s == "()" and not experimentalMode(c):
      message(n.info, warnDeprecated, "overloaded '()' operators are now .experimental; " & s.name.s)

  if n.sons[bodyPos].kind != nkEmpty:
    # for DLL generation it is annoying to check for sfImportc!
    if sfBorrow in s.flags:
      localError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    let usePseudoGenerics = kind in {skMacro, skTemplate}
    # Macros and Templates can have generic parameters, but they are
    # only used for overload resolution (there is no instantiation of
    # the symbol, so we must process the body now)
    if not usePseudoGenerics and gIdeCmd in {ideSug, ideCon} and not
        cursorInProc(n.sons[bodyPos]):
      discard "speed up nimsuggest"
      if s.kind == skMethod: semMethodPrototype(c, s, n)
    else:
      pushProcCon(c, s)
      if n.sons[genericParamsPos].kind == nkEmpty or usePseudoGenerics:
        if not usePseudoGenerics: paramsTypeCheck(c, s.typ)

        c.p.wasForwarded = proto != nil
        maybeAddResult(c, s, n)
        if s.kind == skMethod: semMethodPrototype(c, s, n)

        if lfDynamicLib notin s.loc.flags:
          # no semantic checking for importc:
          let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
          # unfortunately we cannot skip this step when in 'system.compiles'
          # context as it may even be evaluated in 'system.compiles':
          n.sons[bodyPos] = transformBody(c.module, semBody, s)
      else:
        if s.typ.sons[0] != nil and kind != skIterator:
          addDecl(c, newSym(skUnknown, getIdent"result", nil, n.info))

        openScope(c)
        n.sons[bodyPos] = semGenericStmt(c, n.sons[bodyPos])
        closeScope(c)
        fixupInstantiatedSymbols(c, s)
        if s.kind == skMethod: semMethodPrototype(c, s, n)
      if sfImportc in s.flags:
        # so we just ignore the body after semantic checking for importc:
        n.sons[bodyPos] = ast.emptyNode
      popProcCon(c)
  else:
    if s.kind == skMethod: semMethodPrototype(c, s, n)
    if proto != nil: localError(n.info, errImplOfXexpected, proto.name.s)
    if {sfImportc, sfBorrow} * s.flags == {} and s.magic == mNone:
      incl(s.flags, sfForward)
    elif sfBorrow in s.flags: semBorrow(c, n, s)
  sideEffectsCheck(c, s)
  closeScope(c)           # close scope for parameters
  # c.currentScope = oldScope
  popOwner(c)
  if n.sons[patternPos].kind != nkEmpty:
    c.patterns.add(s)
  if isAnon:
    n.kind = nkLambda
    result.typ = s.typ
  if isTopLevel(c) and s.kind != skIterator and
      s.typ.callConv == ccClosure:
    localError(s.info, "'.closure' calling convention for top level routines is invalid")

proc determineType(c: PContext, s: PSym) =
  if s.typ != nil: return
  #if s.magic != mNone: return
  #if s.ast.isNil: return
  discard semProcAux(c, s.ast, s.kind, {}, stepDetermineType)

proc semIterator(c: PContext, n: PNode): PNode =
  # gensym'ed iterator?
  let isAnon = n[namePos].kind == nkEmpty
  if n[namePos].kind == nkSym:
    # gensym'ed iterators might need to become closure iterators:
    n[namePos].sym.owner = getCurrOwner(c)
    n[namePos].sym.kind = skIterator
  result = semProcAux(c, n, skIterator, iteratorPragmas)
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != n.kind: return
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil and s.typ.callConv != ccClosure:
    localError(n.info, errXNeedsReturnType, "iterator")
  if isAnon and s.typ.callConv == ccInline:
    localError(n.info, "inline iterators are not first-class / cannot be assigned to variables")
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

proc semFunc(c: PContext, n: PNode): PNode =
  result = semProcAux(c, n, skFunc, procPragmas)

proc semMethod(c: PContext, n: PNode): PNode =
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "method")
  result = semProcAux(c, n, skMethod, methodPragmas)
  # macros can transform converters to nothing:
  if namePos >= result.safeLen: return result
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != nkMethodDef: return
  var s = result.sons[namePos].sym
  # we need to fix the 'auto' return type for the dispatcher here (see tautonotgeneric
  # test case):
  let disp = getDispatcher(s)
  # auto return type?
  if disp != nil and disp.typ.sons[0] != nil and disp.typ.sons[0].kind == tyExpr:
    let ret = s.typ.sons[0]
    disp.typ.sons[0] = ret
    if disp.ast[resultPos].kind == nkSym:
      if isEmptyType(ret): disp.ast.sons[resultPos] = emptyNode
      else: disp.ast[resultPos].sym.typ = ret

proc semConverterDef(c: PContext, n: PNode): PNode =
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "converter")
  checkSonsLen(n, bodyPos + 1)
  result = semProcAux(c, n, skConverter, converterPragmas)
  # macros can transform converters to nothing:
  if namePos >= result.safeLen: return result
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != nkConverterDef: return
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: localError(n.info, errXNeedsReturnType, "converter")
  if sonsLen(t) != 2: localError(n.info, errXRequiresOneArgument, "converter")
  addConverter(c, s)

proc semMacroDef(c: PContext, n: PNode): PNode =
  checkSonsLen(n, bodyPos + 1)
  result = semProcAux(c, n, skMacro, macroPragmas)
  # macros can transform macros to nothing:
  if namePos >= result.safeLen: return result
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != nkMacroDef: return
  var s = result.sons[namePos].sym
  var t = s.typ
  var allUntyped = true
  for i in 1 .. t.n.len-1:
    let param = t.n.sons[i].sym
    if param.typ.kind != tyExpr: allUntyped = false
  if allUntyped: incl(s.flags, sfAllUntyped)
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
        addSon(result, semStmt(c, gIncludeFile(c.graph, c.module, f, c.cache)))
        excl(c.includedFiles, f)

proc setLine(n: PNode, info: TLineInfo) =
  for i in 0 ..< safeLen(n): setLine(n.sons[i], info)
  n.info = info

proc semPragmaBlock(c: PContext, n: PNode): PNode =
  let pragmaList = n.sons[0]
  pragma(c, nil, pragmaList, exprPragmas)
  result = semExpr(c, n.sons[1])
  n.sons[1] = result
  for i in 0 ..< pragmaList.len:
    case whichPragma(pragmaList.sons[i])
    of wLine: setLine(result, pragmaList.sons[i].info)
    of wLocks, wGcSafe:
      result = n
      result.typ = n.sons[1].typ
    of wNoRewrite:
      incl(result.flags, nfNoRewrite)
    else: discard

proc semStaticStmt(c: PContext, n: PNode): PNode =
  #echo "semStaticStmt"
  #writeStackTrace()
  let a = semStmt(c, n.sons[0])
  n.sons[0] = a
  evalStaticStmt(c.module, c.cache, a, c.p.owner)
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

proc inferConceptStaticParam(c: PContext, inferred, n: PNode) =
  var typ = inferred.typ
  let res = semConstExpr(c, n)
  if not sameType(res.typ, typ.base):
    localError(n.info,
      "cannot infer the concept parameter '%s', due to a type mismatch. " &
      "attempt to equate '%s' and '%s'.",
      [inferred.renderTree, $res.typ, $typ.base])
  typ.n = res

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
    of nkFinally, nkExceptBranch:
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
        body.sons = n.sons[(i+1)..n.len-1]
      tryStmt.addSon(body)
      tryStmt.addSon(deferPart)
      n.sons[i] = semTry(c, tryStmt)
      n.sons.setLen(i+1)
      n.typ = n.sons[i].typ
      return
    else:
      var expr = semExpr(c, n.sons[i], flags)
      n.sons[i] = expr
      if c.matchedConcept != nil and expr.typ != nil and
         (nfFromTemplate notin n.flags or i != last):
        case expr.typ.kind
        of tyBool:
          if expr.kind == nkInfix and
             expr[0].kind == nkSym and
             expr[0].sym.name.s == "==":
            if expr[1].typ.isUnresolvedStatic:
              inferConceptStaticParam(c, expr[1], expr[2])
              continue
            elif expr[2].typ.isUnresolvedStatic:
              inferConceptStaticParam(c, expr[2], expr[1])
              continue

          let verdict = semConstExpr(c, n[i])
          if verdict.intVal == 0:
            localError(result.info, "concept predicate failed")
        of tyUnknown: continue
        else: discard
      if n.sons[i].typ == enforceVoidContext: #or usesResult(n.sons[i]):
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
      if n.sons[i].kind in LastBlockStmts or
         n.sons[i].kind in nkCallKinds and n.sons[i][0].kind == nkSym and sfNoReturn in n.sons[i][0].sym.flags:
        for j in countup(i + 1, length - 1):
          case n.sons[j].kind
          of nkPragma, nkCommentStmt, nkNilLit, nkEmpty, nkBlockExpr,
             nkBlockStmt, nkState: discard
          else: localError(n.sons[j].info, errStmtInvalidAfterReturn)
      else: discard

  if result.len == 1 and
     # concept bodies should be preserved as a stmt list:
     c.matchedConcept == nil and
     # also, don't make life complicated for macros.
     # they will always expect a proper stmtlist:
     nfBlockArg notin n.flags and
     result.sons[0].kind != nkDefer:
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
