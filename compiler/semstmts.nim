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

const
  errNoSymbolToBorrowFromFound = "no symbol to borrow from found"
  errDiscardValueX = "value of type '$1' has to be used (or discarded)"
  errInvalidDiscard = "statement returns no value that can be discarded"
  errInvalidControlFlowX = "invalid control flow: $1"
  errSelectorMustBeOfCertainTypes = "selector must be of an ordinal type, float or string"
  errExprCannotBeRaised = "only a 'ref object' can be raised"
  errBreakOnlyInLoop = "'break' only allowed in loop construct"
  errExceptionAlreadyHandled = "exception already handled"
  errYieldNotAllowedHere = "'yield' only allowed in an iterator"
  errYieldNotAllowedInTryStmt = "'yield' cannot be used within 'try' in a non-inlined iterator"
  errInvalidNumberOfYieldExpr = "invalid number of 'yield' expressions"
  errCannotReturnExpr = "current routine cannot return an expression"
  errGenericLambdaNotAllowed = "A nested proc can have generic parameters only when " &
    "it is used as an operand to another routine and the types " &
    "of the generic paramers can be inferred from the expected signature."
  errCannotInferTypeOfTheLiteral = "cannot infer the type of the $1"
  errCannotInferReturnType = "cannot infer the return type of '$1'"
  errCannotInferStaticParam = "cannot infer the value of the static param '$1'"
  errProcHasNoConcreteType = "'$1' doesn't have a concrete type, due to unspecified generic parameters."
  errLetNeedsInit = "'let' symbol requires an initialization"
  errThreadvarCannotInit = "a thread var cannot be initialized explicitly; this would only run for the main thread"
  errImplOfXexpected = "implementation of '$1' expected"
  errRecursiveDependencyX = "recursive dependency: '$1'"
  errRecursiveDependencyIteratorX = "recursion is not supported in iterators: '$1'"
  errPragmaOnlyInHeaderOfProcX = "pragmas are only allowed in the header of a proc; redefinition of $1"

proc semDiscard(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1, c.config)
  if n[0].kind != nkEmpty:
    n[0] = semExprWithType(c, n[0])
    let sonType = n[0].typ
    let sonKind = n[0].kind
    if isEmptyType(sonType) or sonType.kind in {tyNone, tyTypeDesc} or sonKind == nkTypeOfExpr:
      localError(c.config, n.info, errInvalidDiscard)
    if sonType.kind == tyProc and sonKind notin nkCallKinds:
      # tyProc is disallowed to prevent ``discard foo`` to be valid, when ``discard foo()`` is meant.
      localError(c.config, n.info, "illegal discard proc, did you mean: " & $n[0] & "()")

proc semBreakOrContinue(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1, c.config)
  if n[0].kind != nkEmpty:
    if n.kind != nkContinueStmt:
      var s: PSym
      case n[0].kind
      of nkIdent: s = lookUp(c, n[0])
      of nkSym: s = n[0].sym
      else: illFormedAst(n, c.config)
      s = getGenSym(c, s)
      if s.kind == skLabel and s.owner.id == c.p.owner.id:
        var x = newSymNode(s)
        x.info = n.info
        incl(s.flags, sfUsed)
        n[0] = x
        suggestSym(c.graph, x.info, s, c.graph.usageSym)
        onUse(x.info, s)
      else:
        localError(c.config, n.info, errInvalidControlFlowX % s.name.s)
    else:
      localError(c.config, n.info, errGenerated, "'continue' cannot have a label")
  elif (c.p.nestedLoopCounter <= 0) and ((c.p.nestedBlockCounter <= 0) or n.kind == nkContinueStmt):
    localError(c.config, n.info, errInvalidControlFlowX %
               renderTree(n, {renderNoComments}))

proc semAsm(c: PContext, n: PNode): PNode =
  checkSonsLen(n, 2, c.config)
  var marker = pragmaAsm(c, n[0])
  if marker == '\0': marker = '`' # default marker
  result = semAsmOrEmit(c, n, marker)

proc semWhile(c: PContext, n: PNode; flags: TExprFlags): PNode =
  result = n
  checkSonsLen(n, 2, c.config)
  openScope(c)
  n[0] = forceBool(c, semExprWithType(c, n[0]))
  inc(c.p.nestedLoopCounter)
  n[1] = semStmt(c, n[1], flags)
  dec(c.p.nestedLoopCounter)
  closeScope(c)
  if n[1].typ == c.enforceVoidContext:
    result.typ = c.enforceVoidContext
  elif efInTypeof in flags:
    result.typ = n[1].typ

proc semProc(c: PContext, n: PNode): PNode

proc semExprBranch(c: PContext, n: PNode; flags: TExprFlags = {}): PNode =
  result = semExpr(c, n, flags)
  if result.typ != nil:
    # XXX tyGenericInst here?
    if result.typ.kind in {tyVar, tyLent}: result = newDeref(result)

proc semExprBranchScope(c: PContext, n: PNode): PNode =
  openScope(c)
  result = semExprBranch(c, n)
  closeScope(c)

const
  skipForDiscardable = {nkIfStmt, nkIfExpr, nkCaseStmt, nkOfBranch,
    nkElse, nkStmtListExpr, nkTryStmt, nkFinally, nkExceptBranch,
    nkElifBranch, nkElifExpr, nkElseExpr, nkBlockStmt, nkBlockExpr,
    nkHiddenStdConv, nkHiddenDeref}

proc implicitlyDiscardable(n: PNode): bool =
  var n = n
  while n.kind in skipForDiscardable: n = n.lastSon
  result = n.kind in nkLastBlockStmts or
           (isCallExpr(n) and n[0].kind == nkSym and
           sfDiscardable in n[0].sym.flags)

proc fixNilType(c: PContext; n: PNode) =
  if isAtom(n):
    if n.kind != nkNilLit and n.typ != nil:
      localError(c.config, n.info, errDiscardValueX % n.typ.typeToString)
  elif n.kind in {nkStmtList, nkStmtListExpr}:
    n.transitionSonsKind(nkStmtList)
    for it in n: fixNilType(c, it)
  n.typ = nil

proc discardCheck(c: PContext, result: PNode, flags: TExprFlags) =
  if c.matchedConcept != nil or efInTypeof in flags: return

  if result.typ != nil and result.typ.kind notin {tyTyped, tyVoid}:
    if implicitlyDiscardable(result):
      var n = newNodeI(nkDiscardStmt, result.info, 1)
      n[0] = result
    elif result.typ.kind != tyError and c.config.cmd != cmdInteractive:
      var n = result
      while n.kind in skipForDiscardable: n = n.lastSon
      var s = "expression '" & $n & "' is of type '" &
          result.typ.typeToString & "' and has to be used (or discarded)"
      if result.info.line != n.info.line or
          result.info.fileIndex != n.info.fileIndex:
        s.add "; start of expression here: " & c.config$result.info
      if result.typ.kind == tyProc:
        s.add "; for a function call use ()"
      localError(c.config, n.info, s)

proc semIf(c: PContext, n: PNode; flags: TExprFlags): PNode =
  result = n
  var typ = commonTypeBegin
  var hasElse = false
  for i in 0..<n.len:
    var it = n[i]
    if it.len == 2:
      openScope(c)
      it[0] = forceBool(c, semExprWithType(c, it[0]))
      it[1] = semExprBranch(c, it[1], flags)
      typ = commonType(c, typ, it[1])
      closeScope(c)
    elif it.len == 1:
      hasElse = true
      it[0] = semExprBranchScope(c, it[0])
      typ = commonType(c, typ, it[0])
    else: illFormedAst(it, c.config)
  if isEmptyType(typ) or typ.kind in {tyNil, tyUntyped} or
      (not hasElse and efInTypeof notin flags):
    for it in n: discardCheck(c, it.lastSon, flags)
    result.transitionSonsKind(nkIfStmt)
    # propagate any enforced VoidContext:
    if typ == c.enforceVoidContext: result.typ = c.enforceVoidContext
  else:
    for it in n:
      let j = it.len-1
      if not endsInNoReturn(it[j]):
        it[j] = fitNode(c, typ, it[j], it[j].info)
    result.transitionSonsKind(nkIfExpr)
    result.typ = typ

proc semTry(c: PContext, n: PNode; flags: TExprFlags): PNode =
  var check = initIntSet()
  template semExceptBranchType(typeNode: PNode): bool =
    # returns true if exception type is imported type
    let typ = semTypeNode(c, typeNode, nil).toObject()
    var isImported = false
    if isImportedException(typ, c.config):
      isImported = true
    elif not isException(typ):
      localError(c.config, typeNode.info, errExprCannotBeRaised)

    if containsOrIncl(check, typ.id):
      localError(c.config, typeNode.info, errExceptionAlreadyHandled)
    typeNode = newNodeIT(nkType, typeNode.info, typ)
    isImported

  result = n
  inc c.p.inTryStmt
  checkMinSonsLen(n, 2, c.config)

  var typ = commonTypeBegin
  n[0] = semExprBranchScope(c, n[0])
  typ = commonType(c, typ, n[0].typ)

  var last = n.len - 1
  var catchAllExcepts = 0

  for i in 1..last:
    let a = n[i]
    checkMinSonsLen(a, 1, c.config)
    openScope(c)
    if a.kind == nkExceptBranch:

      if a.len == 2 and a[0].kind == nkBracket:
        # rewrite ``except [a, b, c]: body`` -> ```except a, b, c: body```
        a.sons[0..0] = a[0].sons

      if a.len == 2 and a[0].isInfixAs():
        # support ``except Exception as ex: body``
        let isImported = semExceptBranchType(a[0][1])
        let symbol = newSymG(skLet, a[0][2], c)
        symbol.typ = if isImported: a[0][1].typ
                     else: a[0][1].typ.toRef(c.idgen)
        addDecl(c, symbol)
        # Overwrite symbol in AST with the symbol in the symbol table.
        a[0][2] = newSymNode(symbol, a[0][2].info)

      elif a.len == 1:
        # count number of ``except: body`` blocks
        inc catchAllExcepts

      else:
        # support ``except KeyError, ValueError, ... : body``
        if catchAllExcepts > 0:
          # if ``except: body`` already encountered,
          # cannot be followed by a ``except KeyError, ... : body`` block
          inc catchAllExcepts
        var isNative, isImported: bool
        for j in 0..<a.len-1:
          let tmp = semExceptBranchType(a[j])
          if tmp: isImported = true
          else: isNative = true

        if isNative and isImported:
          localError(c.config, a[0].info, "Mix of imported and native exception types is not allowed in one except branch")

    elif a.kind == nkFinally:
      if i != n.len-1:
        localError(c.config, a.info, "Only one finally is allowed after all other branches")

    else:
      illFormedAst(n, c.config)

    if catchAllExcepts > 1:
      # if number of ``except: body`` blocks is greater than 1
      # or more specific exception follows a general except block, it is invalid
      localError(c.config, a.info, "Only one general except clause is allowed after more specific exceptions")

    # last child of an nkExcept/nkFinally branch is a statement:
    a[^1] = semExprBranchScope(c, a[^1])
    if a.kind != nkFinally: typ = commonType(c, typ, a[^1])
    else: dec last
    closeScope(c)

  dec c.p.inTryStmt
  if isEmptyType(typ) or typ.kind in {tyNil, tyUntyped}:
    discardCheck(c, n[0], flags)
    for i in 1..<n.len: discardCheck(c, n[i].lastSon, flags)
    if typ == c.enforceVoidContext:
      result.typ = c.enforceVoidContext
  else:
    if n.lastSon.kind == nkFinally: discardCheck(c, n.lastSon.lastSon, flags)
    n[0] = fitNode(c, typ, n[0], n[0].info)
    for i in 1..last:
      var it = n[i]
      let j = it.len-1
      if not endsInNoReturn(it[j]):
        it[j] = fitNode(c, typ, it[j], it[j].info)
    result.typ = typ

proc fitRemoveHiddenConv(c: PContext, typ: PType, n: PNode): PNode =
  result = fitNode(c, typ, n, n.info)
  if result.kind in {nkHiddenStdConv, nkHiddenSubConv}:
    let r1 = result[1]
    if r1.kind in {nkCharLit..nkUInt64Lit} and typ.skipTypes(abstractRange).kind in {tyFloat..tyFloat128}:
      result = newFloatNode(nkFloatLit, BiggestFloat r1.intVal)
      result.info = n.info
      result.typ = typ
      if not floatRangeCheck(result.floatVal, typ):
        localError(c.config, n.info, errFloatToString % [$result.floatVal, typeToString(typ)])
    else:
      changeType(c, r1, typ, check=true)
      result = r1
  elif not sameType(result.typ, typ):
    changeType(c, result, typ, check=false)

proc findShadowedVar(c: PContext, v: PSym): PSym =
  for scope in localScopesFrom(c, c.currentScope.parent):
    let shadowed = strTableGet(scope.symbols, v.name)
    if shadowed != nil and shadowed.kind in skLocalVars:
      return shadowed

proc identWithin(n: PNode, s: PIdent): bool =
  for i in 0..n.safeLen-1:
    if identWithin(n[i], s): return true
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
  result.options = c.config.options

  proc getLineInfo(n: PNode): TLineInfo =
    case n.kind
    of nkPostfix:
      if len(n) > 1:
        return getLineInfo(n[1])
    of nkAccQuoted, nkPragmaExpr:
      if len(n) > 0:
        return getLineInfo(n[0])
    else:
      discard
    result = n.info
  let info = getLineInfo(n)
  suggestSym(c.graph, info, result, c.graph.usageSym)

proc checkNilable(c: PContext; v: PSym) =
  if {sfGlobal, sfImportc} * v.flags == {sfGlobal} and v.typ.requiresInit:
    if v.astdef.isNil:
      message(c.config, v.info, warnProveInit, v.name.s)
    elif tfNotNil in v.typ.flags and not v.astdef.typ.isNil and tfNotNil notin v.astdef.typ.flags:
      message(c.config, v.info, warnProveInit, v.name.s)

#include liftdestructors

proc addToVarSection(c: PContext; result: PNode; orig, identDefs: PNode) =
  let value = identDefs[^1]
  if result.kind == nkStmtList:
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
  result = c.graph.emptyNode
  if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "using")
  for i in 0..<n.len:
    var a = n[i]
    if c.config.cmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if a.kind notin {nkIdentDefs, nkVarTuple, nkConstDef}: illFormedAst(a, c.config)
    checkMinSonsLen(a, 3, c.config)
    if a[^2].kind != nkEmpty:
      let typ = semTypeNode(c, a[^2], nil)
      for j in 0..<a.len-2:
        let v = semIdentDef(c, a[j], skParam)
        styleCheckDef(c.config, v)
        onDef(a[j].info, v)
        v.typ = typ
        strTableIncl(c.signatures, v)
    else:
      localError(c.config, a.info, "'using' section must have a type")
    var def: PNode
    if a[^1].kind != nkEmpty:
      localError(c.config, a.info, "'using' sections cannot contain assignments")

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
  t = skipTypes(t, {tyGenericInst, tyAlias, tySink, tyOwned})
  result = n
  if t.kind in {tyVar, tyLent}:
    result = newNodeIT(nkHiddenDeref, n.info, t[0])
    result.add n
    t = skipTypes(t[0], {tyGenericInst, tyAlias, tySink, tyOwned})
  while t.kind in {tyPtr, tyRef}:
    var a = result
    let baseTyp = t.lastSon
    result = newNodeIT(nkHiddenDeref, n.info, baseTyp)
    result.add a
    t = skipTypes(baseTyp, {tyGenericInst, tyAlias, tySink, tyOwned})

proc fillPartialObject(c: PContext; n: PNode; typ: PType) =
  if n.len == 2:
    let x = semExprWithType(c, n[0])
    let y = considerQuotedIdent(c, n[1])
    let obj = x.typ.skipTypes(abstractPtrs)
    if obj.kind == tyObject and tfPartial in obj.flags:
      let field = newSym(skField, getIdent(c.cache, y.s), nextSymId c.idgen, obj.sym, n[1].info)
      field.typ = skipIntLit(typ, c.idgen)
      field.position = obj.n.len
      obj.n.add newSymNode(field)
      n[0] = makeDeref x
      n[1] = newSymNode(field)
      n.typ = field.typ
    else:
      localError(c.config, n.info, "implicit object field construction " &
        "requires a .partial object, but got " & typeToString(obj))
  else:
    localError(c.config, n.info, "nkDotNode requires 2 children")

proc setVarType(c: PContext; v: PSym, typ: PType) =
  if v.typ != nil and not sameTypeOrNil(v.typ, typ):
    localError(c.config, v.info, "inconsistent typing for reintroduced symbol '" &
        v.name.s & "': previous type was: " & typeToString(v.typ, preferDesc) &
        "; new type is: " & typeToString(typ, preferDesc))
  v.typ = typ

proc semLowerLetVarCustomPragma(c: PContext, a: PNode, n: PNode): PNode =
  var b = a[0]
  if b.kind == nkPragmaExpr:
    if b[1].len != 1:
      # we could in future support pragmas w args e.g.: `var foo {.bar:"goo".} = expr`
      return nil
    let nodePragma = b[1][0]
    # see: `singlePragma`
    if nodePragma.kind notin {nkIdent, nkAccQuoted}:
      return nil
    let ident = considerQuotedIdent(c, nodePragma)
    var userPragma = strTableGet(c.userPragmas, ident)
    if userPragma != nil: return nil

    let w = nodePragma.whichPragma
    if n.kind == nkVarSection and w in varPragmas or
      n.kind == nkLetSection and w in letPragmas or
      n.kind == nkConstSection and w in constPragmas:
      return nil

    var amb = false
    let sym = searchInScopes(c, ident, amb)
    # XXX what if amb is true?
    if sym == nil or sfCustomPragma in sym.flags: return nil
      # skip if not in scope; skip `template myAttr() {.pragma.}`
    let lhs = b[0]
    let clash = strTableGet(c.currentScope.symbols, lhs.ident)
    if clash != nil:
      # refs https://github.com/nim-lang/Nim/issues/8275
      wrongRedefinition(c, lhs.info, lhs.ident.s, clash.info)

    result = newTree(nkCall)
    doAssert nodePragma.kind in {nkIdent, nkAccQuoted}, $nodePragma.kind
    result.add nodePragma
    result.add lhs
    if a[1].kind != nkEmpty:
      result.add a[1]
    else:
      result.add newNodeIT(nkNilLit, a.info, c.graph.sysTypes[tyNil])
    result.add a[2]
    result.info = a.info
    let ret = newNodeI(nkStmtList, a.info)
    ret.add result
    result = semExprNoType(c, ret)

proc semVarOrLet(c: PContext, n: PNode, symkind: TSymKind): PNode =
  if n.len == 1:
    result = semLowerLetVarCustomPragma(c, n[0], n)
    if result != nil: return result

  var b: PNode
  result = copyNode(n)
  for i in 0..<n.len:
    var a = n[i]
    if c.config.cmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if a.kind notin {nkIdentDefs, nkVarTuple}: illFormedAst(a, c.config)
    checkMinSonsLen(a, 3, c.config)

    var typ: PType = nil
    if a[^2].kind != nkEmpty:
      typ = semTypeNode(c, a[^2], nil)

    var typFlags: TTypeAllowedFlags

    var def: PNode = c.graph.emptyNode
    if a[^1].kind != nkEmpty:
      def = semExprWithType(c, a[^1], {efAllowDestructor})

      if def.kind == nkSym and def.sym.kind in {skTemplate, skMacro}:
        typFlags.incl taIsTemplateOrMacro
      elif def.typ.kind == tyTypeDesc and c.p.owner.kind != skMacro:
        typFlags.incl taProcContextIsNotMacro

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
        typ = def.typ.skipTypes({tyStatic, tySink}).skipIntLit(c.idgen)
        if typ.kind in tyUserTypeClasses and typ.isResolvedUserTypeClass:
          typ = typ.lastSon
        if hasEmpty(typ):
          localError(c.config, def.info, errCannotInferTypeOfTheLiteral % typ.kind.toHumanStr)
        elif typ.kind == tyProc and tfUnresolved in typ.flags:
          localError(c.config, def.info, errProcHasNoConcreteType % def.renderTree)
        when false:
          # XXX This typing rule is neither documented nor complete enough to
          # justify it. Instead use the newer 'unowned x' until we figured out
          # a more general solution.
          if symkind == skVar and typ.kind == tyOwned and def.kind notin nkCallKinds:
            # special type inference rule: 'var it = ownedPointer' is turned
            # into an unowned pointer.
            typ = typ.lastSon

    # this can only happen for errornous var statements:
    if typ == nil: continue

    if c.matchedConcept != nil:
      typFlags.incl taConcept
    typeAllowedCheck(c, a.info, typ, symkind, typFlags)

    var tup = skipTypes(typ, {tyGenericInst, tyAlias, tySink})
    if a.kind == nkVarTuple:
      if tup.kind != tyTuple:
        localError(c.config, a.info, errXExpected, "tuple")
      elif a.len-2 != tup.len:
        localError(c.config, a.info, errWrongNumberOfVariables)
      b = newNodeI(nkVarTuple, a.info)
      newSons(b, a.len)
      # keep type desc for doc generator
      # NOTE: at the moment this is always ast.emptyNode, see parser.nim
      b[^2] = a[^2]
      b[^1] = def
      addToVarSection(c, result, n, b)
    elif tup.kind == tyTuple and def.kind in {nkPar, nkTupleConstr} and
        a.kind == nkIdentDefs and a.len > 3:
      message(c.config, a.info, warnEachIdentIsTuple)

    for j in 0..<a.len-2:
      if a[j].kind == nkDotExpr:
        fillPartialObject(c, a[j],
          if a.kind != nkVarTuple: typ else: tup[j])
        addToVarSection(c, result, n, a)
        continue
      var v = semIdentDef(c, a[j], symkind)
      styleCheckDef(c.config, v)
      onDef(a[j].info, v)
      if sfGenSym notin v.flags:
        if not isDiscardUnderscore(v): addInterfaceDecl(c, v)
      else:
        if v.owner == nil: v.owner = c.p.owner
      when oKeepVariableNames:
        if c.inUnrolledContext > 0: v.flags.incl(sfShadowed)
        else:
          let shadowed = findShadowedVar(c, v)
          if shadowed != nil:
            shadowed.flags.incl(sfShadowed)
            if shadowed.kind == skResult and sfGenSym notin v.flags:
              message(c.config, a.info, warnResultShadowed)
      if a.kind != nkVarTuple:
        if def.kind != nkEmpty:
          if sfThread in v.flags: localError(c.config, def.info, errThreadvarCannotInit)
        setVarType(c, v, typ)
        b = newNodeI(nkIdentDefs, a.info)
        if importantComments(c.config):
          # keep documentation information:
          b.comment = a.comment
        b.add newSymNode(v)
        # keep type desc for doc generator
        b.add a[^2]
        b.add copyTree(def)
        addToVarSection(c, result, n, b)
        # this is needed for the evaluation pass, guard checking
        #  and custom pragmas:
        var ast = newNodeI(nkIdentDefs, a.info)
        if a[j].kind == nkPragmaExpr:
          var p = newNodeI(nkPragmaExpr, a.info)
          p.add newSymNode(v)
          p.add a[j][1].copyTree
          ast.add p
        else:
          ast.add newSymNode(v)
        ast.add a[^2].copyTree
        ast.add def
        v.ast = ast
      else:
        if def.kind in {nkPar, nkTupleConstr}: v.ast = def[j]
        # bug #7663, for 'nim check' this can be a non-tuple:
        if tup.kind == tyTuple: setVarType(c, v, tup[j])
        else: v.typ = tup
        b[j] = newSymNode(v)
      if def.kind == nkEmpty:
        let actualType = v.typ.skipTypes({tyGenericInst, tyAlias,
                                          tyUserTypeClassInst})
        if actualType.kind in {tyObject, tyDistinct} and
           actualType.requiresInit:
          defaultConstructionError(c, v.typ, v.info)
        else:
          checkNilable(c, v)
        # allow let to not be initialised if imported from C:
        if v.kind == skLet and sfImportc notin v.flags:
          localError(c.config, a.info, errLetNeedsInit)
      if sfCompileTime in v.flags:
        var x = newNodeI(result.kind, v.info)
        x.add result[i]
        vm.setupCompileTimeVar(c.module, c.idgen, c.graph, x)
      if v.flags * {sfGlobal, sfThread} == {sfGlobal}:
        message(c.config, v.info, hintGlobalVar)

proc semConst(c: PContext, n: PNode): PNode =
  result = copyNode(n)
  inc c.inStaticContext
  for i in 0..<n.len:
    var a = n[i]
    if c.config.cmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue
    if a.kind notin {nkConstDef, nkVarTuple}: illFormedAst(a, c.config)
    checkMinSonsLen(a, 3, c.config)

    var typ: PType = nil
    if a[^2].kind != nkEmpty:
      typ = semTypeNode(c, a[^2], nil)

    var typFlags: TTypeAllowedFlags

    # don't evaluate here since the type compatibility check below may add a converter
    var def = semExprWithType(c, a[^1])

    if def.kind == nkSym and def.sym.kind in {skTemplate, skMacro}:
      typFlags.incl taIsTemplateOrMacro
    elif def.typ.kind == tyTypeDesc and c.p.owner.kind != skMacro:
      typFlags.incl taProcContextIsNotMacro

    # check type compatibility between def.typ and typ:
    if typ != nil:
      if typ.isMetaType:
        def = inferWithMetatype(c, typ, def)
        typ = def.typ
      else:
        def = fitRemoveHiddenConv(c, typ, def)
    else:
      typ = def.typ

    # evaluate the node
    def = semConstExpr(c, def)
    if def == nil:
      localError(c.config, a[^1].info, errConstExprExpected)
      continue
    if def.kind != nkNilLit:
      if c.matchedConcept != nil:
        typFlags.incl taConcept
      typeAllowedCheck(c, a.info, typ, skConst, typFlags)

    var b: PNode
    if a.kind == nkVarTuple:
      if typ.kind != tyTuple:
        localError(c.config, a.info, errXExpected, "tuple")
      elif a.len-2 != typ.len:
        localError(c.config, a.info, errWrongNumberOfVariables)
      b = newNodeI(nkVarTuple, a.info)
      newSons(b, a.len)
      b[^2] = a[^2]
      b[^1] = def

    for j in 0..<a.len-2:
      var v = semIdentDef(c, a[j], skConst)
      if sfGenSym notin v.flags: addInterfaceDecl(c, v)
      elif v.owner == nil: v.owner = getCurrOwner(c)
      styleCheckDef(c.config, v)
      onDef(a[j].info, v)

      if a.kind != nkVarTuple:
        setVarType(c, v, typ)
        v.ast = def               # no need to copy
        b = newNodeI(nkConstDef, a.info)
        if importantComments(c.config): b.comment = a.comment
        b.add newSymNode(v)
        b.add a[1]
        b.add copyTree(def)
      else:
        setVarType(c, v, typ[j])
        v.ast = if def[j].kind != nkExprColonExpr: def[j]
                else: def[j][1]
        b[j] = newSymNode(v)
    result.add b
  dec c.inStaticContext

include semfields


proc symForVar(c: PContext, n: PNode): PSym =
  let m = if n.kind == nkPragmaExpr: n[0] else: n
  result = newSymG(skForVar, m, c)
  styleCheckDef(c.config, result)
  onDef(n.info, result)
  if n.kind == nkPragmaExpr:
    pragma(c, result, n[1], forVarPragmas)

proc semForVars(c: PContext, n: PNode; flags: TExprFlags): PNode =
  result = n
  let iterBase = n[^2].typ
  var iter = skipTypes(iterBase, {tyGenericInst, tyAlias, tySink, tyOwned})
  var iterAfterVarLent = iter.skipTypes({tyGenericInst, tyAlias, tyLent, tyVar})
  # n.len == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if iterAfterVarLent.kind != tyTuple or n.len == 3:
    if n.len == 3:
      if n[0].kind == nkVarTuple:
        if n[0].len-1 != iterAfterVarLent.len:
          localError(c.config, n[0].info, errWrongNumberOfVariables)
        for i in 0..<n[0].len-1:
          var v = symForVar(c, n[0][i])
          if getCurrOwner(c).kind == skModule: incl(v.flags, sfGlobal)
          case iter.kind
          of tyVar, tyLent:
            v.typ = newTypeS(iter.kind, c)
            v.typ.add iterAfterVarLent[i]
            if tfVarIsPtr in iter.flags:
              v.typ.flags.incl tfVarIsPtr
          else:
            v.typ = iter[i]
          n[0][i] = newSymNode(v)
          if sfGenSym notin v.flags and not isDiscardUnderscore(v): addDecl(c, v)
          elif v.owner == nil: v.owner = getCurrOwner(c)
      else:
        var v = symForVar(c, n[0])
        if getCurrOwner(c).kind == skModule: incl(v.flags, sfGlobal)
        # BUGFIX: don't use `iter` here as that would strip away
        # the ``tyGenericInst``! See ``tests/compile/tgeneric.nim``
        # for an example:
        v.typ = iterBase
        n[0] = newSymNode(v)
        if sfGenSym notin v.flags and not isDiscardUnderscore(v): addDecl(c, v)
        elif v.owner == nil: v.owner = getCurrOwner(c)
    else:
      localError(c.config, n.info, errWrongNumberOfVariables)
  elif n.len-2 != iterAfterVarLent.len:
    localError(c.config, n.info, errWrongNumberOfVariables)
  else:
    for i in 0..<n.len - 2:
      if n[i].kind == nkVarTuple:
        var mutable = false
        var isLent = false
        case iter[i].kind
        of tyVar:
          mutable = true
          iter[i] = iter[i].skipTypes({tyVar})
        of tyLent:
          isLent = true
          iter[i] = iter[i].skipTypes({tyLent})
        else: discard

        if n[i].len-1 != iter[i].len:
          localError(c.config, n[i].info, errWrongNumberOfVariables)
        for j in 0..<n[i].len-1:
          var v = symForVar(c, n[i][j])
          if getCurrOwner(c).kind == skModule: incl(v.flags, sfGlobal)
          if mutable:
            v.typ = newTypeS(tyVar, c)
            v.typ.add iter[i][j]
          elif isLent:
            v.typ = newTypeS(tyLent, c)
            v.typ.add iter[i][j]
          else:
            v.typ = iter[i][j]
          n[i][j] = newSymNode(v)
          if not isDiscardUnderscore(v): addDecl(c, v)
          elif v.owner == nil: v.owner = getCurrOwner(c)
      else:
        var v = symForVar(c, n[i])
        if getCurrOwner(c).kind == skModule: incl(v.flags, sfGlobal)
        case iter.kind
        of tyVar, tyLent:
          v.typ = newTypeS(iter.kind, c)
          v.typ.add iterAfterVarLent[i]
          if tfVarIsPtr in iter.flags:
            v.typ.flags.incl tfVarIsPtr
        else:
          v.typ = iter[i]
        n[i] = newSymNode(v)
        if sfGenSym notin v.flags:
          if not isDiscardUnderscore(v): addDecl(c, v)
        elif v.owner == nil: v.owner = getCurrOwner(c)
  inc(c.p.nestedLoopCounter)
  openScope(c)
  n[^1] = semExprBranch(c, n[^1], flags)
  if efInTypeof notin flags:
    discardCheck(c, n[^1], flags)
  closeScope(c)
  dec(c.p.nestedLoopCounter)

proc implicitIterator(c: PContext, it: string, arg: PNode): PNode =
  result = newNodeI(nkCall, arg.info)
  result.add(newIdentNode(getIdent(c.cache, it), arg.info))
  if arg.typ != nil and arg.typ.kind in {tyVar, tyLent}:
    result.add newDeref(arg)
  else:
    result.add arg
  result = semExprNoDeref(c, result, {efWantIterator})

proc isTrivalStmtExpr(n: PNode): bool =
  for i in 0..<n.len-1:
    if n[i].kind notin {nkEmpty, nkCommentStmt}:
      return false
  result = true

proc handleStmtMacro(c: PContext; n, selector: PNode; magicType: string;
                     flags: TExprFlags): PNode =
  if selector.kind in nkCallKinds:
    # we transform
    # n := for a, b, c in m(x, y, z): Y
    # to
    # m(n)
    let maType = magicsys.getCompilerProc(c.graph, magicType)
    if maType == nil: return

    let headSymbol = selector[0]
    var o: TOverloadIter
    var match: PSym = nil
    var symx = initOverloadIter(o, c, headSymbol)
    while symx != nil:
      if symx.kind in {skTemplate, skMacro}:
        if symx.typ.len == 2 and symx.typ[1] == maType.typ:
          if match == nil:
            match = symx
          else:
            localError(c.config, n.info, errAmbiguousCallXYZ % [
              getProcHeader(c.config, match),
              getProcHeader(c.config, symx), $selector])
      symx = nextOverloadIter(o, c, headSymbol)

    if match == nil: return
    var callExpr = newNodeI(nkCall, n.info)
    callExpr.add newSymNode(match)
    callExpr.add n
    case match.kind
    of skMacro: result = semMacroExpr(c, callExpr, callExpr, match, flags)
    of skTemplate: result = semTemplateExpr(c, callExpr, match, flags)
    else: result = nil

proc handleForLoopMacro(c: PContext; n: PNode; flags: TExprFlags): PNode =
  result = handleStmtMacro(c, n, n[^2], "ForLoopStmt", flags)

proc handleCaseStmtMacro(c: PContext; n: PNode; flags: TExprFlags): PNode =
  # n[0] has been sem'checked and has a type. We use this to resolve
  # '`case`(n[0])' but then we pass 'n' to the `case` macro. This seems to
  # be the best solution.
  var toResolve = newNodeI(nkCall, n.info)
  toResolve.add newIdentNode(getIdent(c.cache, "case"), n.info)
  toResolve.add n[0]

  var errors: CandidateErrors
  var r = resolveOverloads(c, toResolve, toResolve, {skTemplate, skMacro}, {},
                           errors, false)
  if r.state == csMatch:
    var match = r.calleeSym
    markUsed(c, n[0].info, match)
    onUse(n[0].info, match)

    # but pass 'n' to the `case` macro, not 'n[0]':
    r.call[1] = n
    let toExpand = semResolvedCall(c, r, r.call, {})
    case match.kind
    of skMacro: result = semMacroExpr(c, toExpand, toExpand, match, flags)
    of skTemplate: result = semTemplateExpr(c, toExpand, match, flags)
    else: result = nil
  # this would be the perfectly consistent solution with 'for loop macros',
  # but it kinda sucks for pattern matching as the matcher is not attached to
  # a type then:
  when false:
    result = handleStmtMacro(c, n, n[0], "CaseStmt")

proc semFor(c: PContext, n: PNode; flags: TExprFlags): PNode =
  checkMinSonsLen(n, 3, c.config)
  result = handleForLoopMacro(c, n, flags)
  if result != nil: return result
  openScope(c)
  result = n
  n[^2] = semExprNoDeref(c, n[^2], {efWantIterator})
  var call = n[^2]
  if call.kind == nkStmtListExpr and isTrivalStmtExpr(call):
    call = call.lastSon
    n[^2] = call
  let isCallExpr = call.kind in nkCallKinds
  if isCallExpr and call[0].kind == nkSym and
      call[0].sym.magic in {mFields, mFieldPairs, mOmpParFor}:
    if call[0].sym.magic == mOmpParFor:
      result = semForVars(c, n, flags)
      result.transitionSonsKind(nkParForStmt)
    else:
      result = semForFields(c, n, call[0].sym.magic)
  elif isCallExpr and isClosureIterator(call[0].typ.skipTypes(abstractInst)):
    # first class iterator:
    result = semForVars(c, n, flags)
  elif not isCallExpr or call[0].kind != nkSym or
      call[0].sym.kind != skIterator:
    if n.len == 3:
      n[^2] = implicitIterator(c, "items", n[^2])
    elif n.len == 4:
      n[^2] = implicitIterator(c, "pairs", n[^2])
    else:
      localError(c.config, n[^2].info, "iterator within for loop context expected")
    result = semForVars(c, n, flags)
  else:
    result = semForVars(c, n, flags)
  # propagate any enforced VoidContext:
  if n[^1].typ == c.enforceVoidContext:
    result.typ = c.enforceVoidContext
  elif efInTypeof in flags:
    result.typ = result.lastSon.typ
  closeScope(c)

proc semCase(c: PContext, n: PNode; flags: TExprFlags): PNode =
  result = n
  checkMinSonsLen(n, 2, c.config)
  openScope(c)
  pushCaseContext(c, n)
  n[0] = semExprWithType(c, n[0])
  var chckCovered = false
  var covered: Int128 = toInt128(0)
  var typ = commonTypeBegin
  var hasElse = false
  let caseTyp = skipTypes(n[0].typ, abstractVar-{tyTypeDesc})
  const shouldChckCovered = {tyInt..tyInt64, tyChar, tyEnum, tyUInt..tyUInt32, tyBool}
  case caseTyp.kind
  of shouldChckCovered:
    chckCovered = true
  of tyRange:
    if skipTypes(caseTyp[0], abstractInst).kind in shouldChckCovered:
      chckCovered = true
  of tyFloat..tyFloat128, tyString, tyError:
    discard
  else:
    popCaseContext(c)
    closeScope(c)
    if caseStmtMacros in c.features:
      result = handleCaseStmtMacro(c, n, flags)
      if result != nil:
        return result
    localError(c.config, n[0].info, errSelectorMustBeOfCertainTypes)
    return
  for i in 1..<n.len:
    setCaseContextIdx(c, i)
    var x = n[i]
    when defined(nimsuggest):
      if c.config.ideCmd == ideSug and exactEquals(c.config.m.trackPos, x.info) and caseTyp.kind == tyEnum:
        suggestEnum(c, x, caseTyp)
    case x.kind
    of nkOfBranch:
      checkMinSonsLen(x, 2, c.config)
      semCaseBranch(c, n, x, i, covered)
      var last = x.len-1
      x[last] = semExprBranchScope(c, x[last])
      typ = commonType(c, typ, x[last])
    of nkElifBranch:
      chckCovered = false
      checkSonsLen(x, 2, c.config)
      openScope(c)
      x[0] = forceBool(c, semExprWithType(c, x[0]))
      x[1] = semExprBranch(c, x[1])
      typ = commonType(c, typ, x[1])
      closeScope(c)
    of nkElse:
      checkSonsLen(x, 1, c.config)
      x[0] = semExprBranchScope(c, x[0])
      typ = commonType(c, typ, x[0])
      if (chckCovered and covered == toCover(c, n[0].typ)) or hasElse:
        message(c.config, x.info, warnUnreachableElse)
      hasElse = true
      chckCovered = false
    else:
      illFormedAst(x, c.config)
  if chckCovered:
    if covered == toCover(c, n[0].typ):
      hasElse = true
    elif n[0].typ.skipTypes(abstractRange).kind in {tyEnum, tyChar}:
      localError(c.config, n.info, "not all cases are covered; missing: $1" %
                 formatMissingEnums(c, n))
    else:
      localError(c.config, n.info, "not all cases are covered")
  popCaseContext(c)
  closeScope(c)
  if isEmptyType(typ) or typ.kind in {tyNil, tyUntyped} or
      (not hasElse and efInTypeof notin flags):
    for i in 1..<n.len: discardCheck(c, n[i].lastSon, flags)
    # propagate any enforced VoidContext:
    if typ == c.enforceVoidContext:
      result.typ = c.enforceVoidContext
  else:
    for i in 1..<n.len:
      var it = n[i]
      let j = it.len-1
      if not endsInNoReturn(it[j]):
        it[j] = fitNode(c, typ, it[j], it[j].info)
    result.typ = typ

proc semRaise(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1, c.config)
  if n[0].kind != nkEmpty:
    n[0] = semExprWithType(c, n[0])
    var typ = n[0].typ
    if not isImportedException(typ, c.config):
      typ = typ.skipTypes({tyAlias, tyGenericInst, tyOwned})
      if typ.kind != tyRef:
        localError(c.config, n.info, errExprCannotBeRaised)
      if typ.len > 0 and not isException(typ.lastSon):
        localError(c.config, n.info, "raised object of type $1 does not inherit from Exception",
                          [typeToString(typ)])

proc addGenericParamListToScope(c: PContext, n: PNode) =
  if n.kind != nkGenericParams: illFormedAst(n, c.config)
  for i in 0..<n.len:
    var a = n[i]
    if a.kind == nkSym: addDecl(c, a.sym)
    else: illFormedAst(a, c.config)

proc typeSectionTypeName(c: PContext; n: PNode): PNode =
  if n.kind == nkPragmaExpr:
    if n.len == 0: illFormedAst(n, c.config)
    result = n[0]
  else:
    result = n
  if result.kind != nkSym: illFormedAst(n, c.config)

proc typeDefLeftSidePass(c: PContext, typeSection: PNode, i: int) =
  let typeDef = typeSection[i]
  checkSonsLen(typeDef, 3, c.config)
  var name = typeDef[0]
  var s: PSym
  if name.kind == nkDotExpr and typeDef[2].kind == nkObjectTy:
    let pkgName = considerQuotedIdent(c, name[0])
    let typName = considerQuotedIdent(c, name[1])
    let pkg = c.graph.packageSyms.strTableGet(pkgName)
    if pkg.isNil or pkg.kind != skPackage:
      localError(c.config, name.info, "unknown package name: " & pkgName.s)
    else:
      let typsym = c.graph.packageTypes.strTableGet(typName)
      if typsym.isNil:
        s = semIdentDef(c, name[1], skType)
        onDef(name[1].info, s)
        s.typ = newTypeS(tyObject, c)
        s.typ.sym = s
        s.flags.incl sfForward
        c.graph.packageTypes.strTableAdd s
        addInterfaceDecl(c, s)
      elif typsym.kind == skType and sfForward in typsym.flags:
        s = typsym
        addInterfaceDecl(c, s)
      else:
        localError(c.config, name.info, typsym.name.s & " is not a type that can be forwarded")
        s = typsym
  else:
    s = semIdentDef(c, name, skType)
    onDef(name.info, s)
    s.typ = newTypeS(tyForward, c)
    s.typ.sym = s             # process pragmas:
    if name.kind == nkPragmaExpr:
      let rewritten = applyTypeSectionPragmas(c, name[1], typeDef)
      if rewritten != nil:
        typeSection[i] = rewritten
        typeDefLeftSidePass(c, typeSection, i)
        return
      pragma(c, s, name[1], typePragmas)
    if sfForward in s.flags:
      # check if the symbol already exists:
      let pkg = c.module.owner
      if not isTopLevel(c) or pkg.isNil:
        localError(c.config, name.info, "only top level types in a package can be 'package'")
      else:
        let typsym = c.graph.packageTypes.strTableGet(s.name)
        if typsym != nil:
          if sfForward notin typsym.flags or sfNoForward notin typsym.flags:
            typeCompleted(typsym)
            typsym.info = s.info
          else:
            localError(c.config, name.info, "cannot complete type '" & s.name.s & "' twice; " &
                    "previous type completion was here: " & c.config$typsym.info)
          s = typsym
    # add it here, so that recursive types are possible:
    if sfGenSym notin s.flags: addInterfaceDecl(c, s)
    elif s.owner == nil: s.owner = getCurrOwner(c)

  if name.kind == nkPragmaExpr:
    typeDef[0][0] = newSymNode(s)
  else:
    typeDef[0] = newSymNode(s)

proc typeSectionLeftSidePass(c: PContext, n: PNode) =
  # process the symbols on the left side for the whole type section, before
  # we even look at the type definitions on the right
  for i in 0..<n.len:
    var a = n[i]
    when defined(nimsuggest):
      if c.config.cmd == cmdIdeTools:
        inc c.inTypeContext
        suggestStmt(c, a)
        dec c.inTypeContext
    if a.kind == nkCommentStmt: continue
    if a.kind != nkTypeDef: illFormedAst(a, c.config)
    typeDefLeftSidePass(c, n, i)

proc checkCovariantParamsUsages(c: PContext; genericType: PType) =
  var body = genericType[^1]

  proc traverseSubTypes(c: PContext; t: PType): bool =
    template error(msg) = localError(c.config, genericType.sym.info, msg)
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
        subresult traverseSubTypes(c, field.typ)
    of tyArray:
      return traverseSubTypes(c, t[1])
    of tyProc:
      for subType in t.sons:
        if subType != nil:
          subresult traverseSubTypes(c, subType)
      if result:
        error("non-invariant type param used in a proc type: " & $t)
    of tySequence:
      return traverseSubTypes(c, t[0])
    of tyGenericInvocation:
      let targetBody = t[0]
      for i in 1..<t.len:
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
          subresult traverseSubTypes(c, param)
    of tyAnd, tyOr, tyNot, tyStatic, tyBuiltInTypeClass, tyCompositeTypeClass:
      error("non-invariant type parameters cannot be used with types such '" & $t & "'")
    of tyUserTypeClass, tyUserTypeClassInst:
      error("non-invariant type parameters are not supported in concepts")
    of tyTuple:
      for fieldType in t.sons:
        subresult traverseSubTypes(c, fieldType)
    of tyPtr, tyRef, tyVar, tyLent:
      if t.base.kind == tyGenericParam: return true
      return traverseSubTypes(c, t.base)
    of tyDistinct, tyAlias, tySink, tyOwned:
      return traverseSubTypes(c, t.lastSon)
    of tyGenericInst:
      internalAssert c.config, false
    else:
      discard
  discard traverseSubTypes(c, body)

proc typeSectionRightSidePass(c: PContext, n: PNode) =
  for i in 0..<n.len:
    var a = n[i]
    if a.kind == nkCommentStmt: continue
    if a.kind != nkTypeDef: illFormedAst(a, c.config)
    checkSonsLen(a, 3, c.config)
    let name = typeSectionTypeName(c, a[0])
    var s = name.sym
    if s.magic == mNone and a[2].kind == nkEmpty:
      localError(c.config, a.info, errImplOfXexpected % s.name.s)
    if s.magic != mNone: processMagicType(c, s)
    if a[1].kind != nkEmpty:
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
      s.typ.n = semGenericParamList(c, a[1], s.typ)
      a[1] = s.typ.n
      s.typ.size = -1 # could not be computed properly
      # we fill it out later. For magic generics like 'seq', it won't be filled
      # so we use tyNone instead of nil to not crash for strange conversions
      # like: mydata.seq
      rawAddSon(s.typ, newTypeS(tyNone, c))
      s.ast = a
      inc c.inGenericContext
      var body = semTypeNode(c, a[2], nil)
      dec c.inGenericContext
      if body != nil:
        body.sym = s
        body.size = -1 # could not be computed properly
        s.typ[^1] = body
        if tfCovariant in s.typ.flags:
          checkCovariantParamsUsages(c, s.typ)
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
              body.n.sons = @[]

      popOwner(c)
      closeScope(c)
    elif a[2].kind != nkEmpty:
      # process the type's body:
      pushOwner(c, s)
      var t = semTypeNode(c, a[2], s.typ)
      if s.typ == nil:
        s.typ = t
      elif t != s.typ and (s.typ == nil or s.typ.kind != tyAlias):
        # this can happen for e.g. tcan_alias_specialised_generic:
        assignType(s.typ, t)
        #debug s.typ
      s.ast = a
      popOwner(c)
      # If the right hand side expression was a macro call we replace it with
      # its evaluated result here so that we don't execute it once again in the
      # final pass
      if a[2].kind in nkCallKinds:
        incl a[2].flags, nfSem # bug #10548
    if sfExportc in s.flags and s.typ.kind == tyAlias:
      localError(c.config, name.info, "{.exportc.} not allowed for type aliases")
    if tfBorrowDot in s.typ.flags and s.typ.kind != tyDistinct:
      excl s.typ.flags, tfBorrowDot
      localError(c.config, name.info, "only a 'distinct' type can borrow `.`")
    let aa = a[2]
    if aa.kind in {nkRefTy, nkPtrTy} and aa.len == 1 and
       aa[0].kind == nkObjectTy:
      # give anonymous object a dummy symbol:
      var st = s.typ
      if st.kind == tyGenericBody: st = st.lastSon
      internalAssert c.config, st.kind in {tyPtr, tyRef}
      internalAssert c.config, st.lastSon.sym == nil
      incl st.flags, tfRefsAnonObj
      let obj = newSym(skType, getIdent(c.cache, s.name.s & ":ObjectType"),
                       nextSymId c.idgen, getCurrOwner(c), s.info)
      let symNode = newSymNode(obj)
      obj.ast = a.shallowCopy
      case a[0].kind
        of nkSym: obj.ast[0] = symNode
        of nkPragmaExpr:
          obj.ast[0] = a[0].shallowCopy
          obj.ast[0][0] = symNode
          obj.ast[0][1] = a[0][1]
        else: assert(false)
      obj.ast[1] = a[1]
      obj.ast[2] = a[2][0]
      if sfPure in s.flags:
        obj.flags.incl sfPure
      obj.typ = st.lastSon
      st.lastSon.sym = obj

proc checkForMetaFields(c: PContext; n: PNode) =
  proc checkMeta(c: PContext; n: PNode; t: PType) =
    if t != nil and t.isMetaType and tfGenericTypeParam notin t.flags:
      if t.kind == tyBuiltInTypeClass and t.len == 1 and t[0].kind == tyProc:
        localError(c.config, n.info, ("'$1' is not a concrete type; " &
          "for a callback without parameters use 'proc()'") % t.typeToString)
      else:
        localError(c.config, n.info, errTIsNotAConcreteType % t.typeToString)

  if n.isNil: return
  case n.kind
  of nkRecList, nkRecCase:
    for s in n: checkForMetaFields(c, s)
  of nkOfBranch, nkElse:
    checkForMetaFields(c, n.lastSon)
  of nkSym:
    let t = n.sym.typ
    case t.kind
    of tySequence, tySet, tyArray, tyOpenArray, tyVar, tyLent, tyPtr, tyRef,
       tyProc, tyGenericInvocation, tyGenericInst, tyAlias, tySink, tyOwned:
      let start = ord(t.kind in {tyGenericInvocation, tyGenericInst})
      for i in start..<t.len:
        checkMeta(c, n, t[i])
    else:
      checkMeta(c, n, t)
  else:
    internalAssert c.config, false

proc typeSectionFinalPass(c: PContext, n: PNode) =
  for i in 0..<n.len:
    var a = n[i]
    if a.kind == nkCommentStmt: continue
    let name = typeSectionTypeName(c, a[0])
    var s = name.sym
    # check the style here after the pragmas have been processed:
    styleCheckDef(c.config, s)
    # compute the type's size and check for illegal recursions:
    if a[1].kind == nkEmpty:
      var x = a[2]
      if x.kind in nkCallKinds and nfSem in x.flags:
        discard "already semchecked, see line marked with bug #10548"
      else:
        while x.kind in {nkStmtList, nkStmtListExpr} and x.len > 0:
          x = x.lastSon
        # we need the 'safeSkipTypes' here because illegally recursive types
        # can enter at this point, see bug #13763
        if x.kind notin {nkObjectTy, nkDistinctTy, nkEnumTy, nkEmpty} and
            s.typ.safeSkipTypes(abstractPtrs).kind notin {tyObject, tyEnum}:
          # type aliases are hard:
          var t = semTypeNode(c, x, nil)
          assert t != nil
          if s.typ != nil and s.typ.kind notin {tyAlias, tySink}:
            if t.kind in {tyProc, tyGenericInst} and not t.isMetaType:
              assignType(s.typ, t)
              s.typ.itemId = t.itemId
            elif t.kind in {tyObject, tyEnum, tyDistinct}:
              assert s.typ != nil
              assignType(s.typ, t)
              s.typ.itemId = t.itemId     # same id
        checkConstructedType(c.config, s.info, s.typ)
        if s.typ.kind in {tyObject, tyTuple} and not s.typ.n.isNil:
          checkForMetaFields(c, s.typ.n)
          # fix bug #5170: ensure locally scoped object types get a unique name:
          if s.typ.kind == tyObject and not isTopLevel(c): incl(s.flags, sfGenSym)
  #instAllTypeBoundOp(c, n.info)


proc semAllTypeSections(c: PContext; n: PNode): PNode =
  proc gatherStmts(c: PContext; n: PNode; result: PNode) {.nimcall.} =
    case n.kind
    of nkIncludeStmt:
      for i in 0..<n.len:
        var f = checkModuleName(c.config, n[i])
        if f != InvalidFileIdx:
          if containsOrIncl(c.includedFiles, f.int):
            localError(c.config, n.info, errRecursiveDependencyX % toMsgFilename(c.config, f))
          else:
            let code = c.graph.includeFileCallback(c.graph, c.module, f)
            gatherStmts c, code, result
            excl(c.includedFiles, f.int)
    of nkStmtList:
      for i in 0..<n.len:
        gatherStmts(c, n[i], result)
    of nkTypeSection:
      incl n.flags, nfSem
      typeSectionLeftSidePass(c, n)
      result.add n
    else:
      result.add n

  result = newNodeI(nkStmtList, n.info)
  gatherStmts(c, n, result)

  template rec(name) =
    for i in 0..<result.len:
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
          for i in 0..<n.len:
            `name rec`(c, n[i])
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

proc addParams(c: PContext, n: PNode, kind: TSymKind) =
  for i in 1..<n.len:
    if n[i].kind == nkSym: addParamOrResult(c, n[i].sym, kind)
    else: illFormedAst(n, c.config)

proc semBorrow(c: PContext, n: PNode, s: PSym) =
  # search for the correct alias:
  var b = searchForBorrowProc(c, c.currentScope.parent, s)
  if b != nil:
    # store the alias:
    n[bodyPos] = newSymNode(b)
    # Carry over the original symbol magic, this is necessary in order to ensure
    # the semantic pass is correct
    s.magic = b.magic
  else:
    localError(c.config, n.info, errNoSymbolToBorrowFromFound)

proc addResult(c: PContext, n: PNode, t: PType, owner: TSymKind) =
  if owner == skMacro or t != nil:
    if n.len > resultPos and n[resultPos] != nil:
      if n[resultPos].sym.kind != skResult or n[resultPos].sym.owner != getCurrOwner(c):
        localError(c.config, n.info, "incorrect result proc symbol")
      c.p.resultSym = n[resultPos].sym
    else:
      var s = newSym(skResult, getIdent(c.cache, "result"), nextSymId c.idgen, getCurrOwner(c), n.info)
      s.typ = t
      incl(s.flags, sfUsed)
      c.p.resultSym = s
      n.add newSymNode(c.p.resultSym)
    addParamOrResult(c, c.p.resultSym, owner)

proc copyExcept(n: PNode, i: int): PNode =
  result = copyNode(n)
  for j in 0..<n.len:
    if j != i: result.add(n[j])

proc semProcAnnotation(c: PContext, prc: PNode;
                       validPragmas: TSpecialWords): PNode =
  var n = prc[pragmasPos]
  if n == nil or n.kind == nkEmpty: return
  for i in 0..<n.len:
    let it = n[i]
    let key = if it.kind in nkPragmaCallKinds and it.len >= 1: it[0] else: it

    if whichPragma(it) != wInvalid:
      # Not a custom pragma
      continue
    else:
      let ident = considerQuotedIdent(c, key)
      if strTableGet(c.userPragmas, ident) != nil:
        continue # User defined pragma
      else:
        var amb = false
        let sym = searchInScopes(c, ident, amb)
        if sym != nil and sfCustomPragma in sym.flags:
          continue # User custom pragma

    # we transform ``proc p {.m, rest.}`` into ``m(do: proc p {.rest.})`` and
    # let the semantic checker deal with it:
    var x = newNodeI(nkCall, key.info)
    x.add(key)

    if it.kind in nkPragmaCallKinds and it.len > 1:
      # pass pragma arguments to the macro too:
      for i in 1..<it.len:
        x.add(it[i])

    # Drop the pragma from the list, this prevents getting caught in endless
    # recursion when the nkCall is semanticized
    prc[pragmasPos] = copyExcept(n, i)
    if prc[pragmasPos].kind != nkEmpty and prc[pragmasPos].len == 0:
      prc[pragmasPos] = c.graph.emptyNode

    x.add(prc)

    # recursion assures that this works for multiple macro annotations too:
    var r = semOverloadedCall(c, x, x, {skMacro, skTemplate}, {efNoUndeclared})
    if r == nil:
      # Restore the old list of pragmas since we couldn't process this
      prc[pragmasPos] = n
      # No matching macro was found but there's always the possibility this may
      # be a .pragma. template instead
      continue

    doAssert r[0].kind == nkSym
    let m = r[0].sym
    case m.kind
    of skMacro: result = semMacroExpr(c, r, r, m, {})
    of skTemplate: result = semTemplateExpr(c, r, m, {})
    else:
      prc[pragmasPos] = n
      continue

    doAssert result != nil

    # since a proc annotation can set pragmas, we process these here again.
    # This is required for SqueakNim-like export pragmas.
    if result.kind in procDefs and result[namePos].kind == nkSym and
        result[pragmasPos].kind != nkEmpty:
      pragma(c, result[namePos].sym, result[pragmasPos], validPragmas)

    return

proc setGenericParamsMisc(c: PContext; n: PNode): PNode =
  let orig = n[genericParamsPos]
  # we keep the original params around for better error messages, see
  # issue https://github.com/nim-lang/Nim/issues/1713
  result = semGenericParamList(c, orig)
  if n[miscPos].kind == nkEmpty:
    n[miscPos] = newTree(nkBracket, c.graph.emptyNode, orig)
  else:
    n[miscPos][1] = orig
  n[genericParamsPos] = result

proc semLambda(c: PContext, n: PNode, flags: TExprFlags): PNode =
  # XXX semProcAux should be good enough for this now, we will eventually
  # remove semLambda
  result = semProcAnnotation(c, n, lambdaPragmas)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1, c.config)
  var s: PSym
  if n[namePos].kind != nkSym:
    s = newSym(skProc, c.cache.idAnon, nextSymId c.idgen, getCurrOwner(c), n.info)
    s.ast = n
    n[namePos] = newSymNode(s)
  else:
    s = n[namePos].sym
  pushOwner(c, s)
  openScope(c)
  var gp: PNode
  if n[genericParamsPos].kind != nkEmpty:
    gp = setGenericParamsMisc(c, n)
  else:
    gp = newNodeI(nkGenericParams, n.info)

  if n[paramsPos].kind != nkEmpty:
    semParamList(c, n[paramsPos], gp, s)
    # paramsTypeCheck(c, s.typ)
    if gp.len > 0 and n[genericParamsPos].kind == nkEmpty:
      # we have a list of implicit type parameters:
      n[genericParamsPos] = gp
  else:
    s.typ = newProcType(c, n.info)
  if n[pragmasPos].kind != nkEmpty:
    pragma(c, s, n[pragmasPos], lambdaPragmas)
  s.options = c.config.options
  if n[bodyPos].kind != nkEmpty:
    if sfImportc in s.flags:
      localError(c.config, n[bodyPos].info, errImplOfXNotAllowed % s.name.s)
    #if efDetermineType notin flags:
    # XXX not good enough; see tnamedparamanonproc.nim
    if gp.len == 0 or (gp.len == 1 and tfRetType in gp[0].typ.flags):
      pushProcCon(c, s)
      addResult(c, n, s.typ[0], skProc)
      s.ast[bodyPos] = hloBody(c, semProcBody(c, n[bodyPos]))
      trackProc(c, s, s.ast[bodyPos])
      popProcCon(c)
    elif efOperand notin flags:
      localError(c.config, n.info, errGenericLambdaNotAllowed)
    sideEffectsCheck(c, s)
  else:
    localError(c.config, n.info, errImplOfXexpected % s.name.s)
  closeScope(c)           # close scope for parameters
  popOwner(c)
  result.typ = s.typ
  if optOwnedRefs in c.config.globalOptions:
    result.typ = makeVarType(c, result.typ, tyOwned)

proc semInferredLambda(c: PContext, pt: TIdTable, n: PNode): PNode {.nosinks.} =
  var n = n

  let original = n[namePos].sym
  let s = original #copySym(original, false)
  #incl(s.flags, sfFromGeneric)
  #s.owner = original

  n = replaceTypesInBody(c, pt, n, original)
  result = n
  s.ast = result
  n[namePos].sym = s
  n[genericParamsPos] = c.graph.emptyNode
  # for LL we need to avoid wrong aliasing
  let params = copyTree n.typ.n
  n[paramsPos] = params
  s.typ = n.typ
  for i in 1..<params.len:
    if params[i].typ.kind in {tyTypeDesc, tyGenericParam,
                              tyFromExpr}+tyTypeClasses:
      localError(c.config, params[i].info, "cannot infer type of parameter: " &
                 params[i].sym.name.s)
    #params[i].sym.owner = s
  openScope(c)
  pushOwner(c, s)
  addParams(c, params, skProc)
  pushProcCon(c, s)
  addResult(c, n, n.typ[0], skProc)
  s.ast[bodyPos] = hloBody(c, semProcBody(c, n[bodyPos]))
  trackProc(c, s, s.ast[bodyPos])
  popProcCon(c)
  popOwner(c)
  closeScope(c)
  if optOwnedRefs in c.config.globalOptions and result.typ != nil:
    result.typ = makeVarType(c, result.typ, tyOwned)
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
      for i in 1..<n.len: activate(c, n[i])
    else:
      discard

proc maybeAddResult(c: PContext, s: PSym, n: PNode) =
  if s.kind == skMacro:
    let resultType = sysTypeFromName(c.graph, n.info, "NimNode")
    addResult(c, n, resultType, s.kind)
  elif s.typ[0] != nil and not isInlineIterator(s.typ):
    addResult(c, n, s.typ[0], s.kind)

proc canonType(c: PContext, t: PType): PType =
  if t.kind == tySequence:
    result = c.graph.sysTypes[tySequence]
  else:
    result = t

proc prevDestructor(c: PContext; prevOp: PSym; obj: PType; info: TLineInfo) =
  var msg = "cannot bind another '" & prevOp.name.s & "' to: " & typeToString(obj)
  if sfOverriden notin prevOp.flags:
    msg.add "; previous declaration was constructed here implicitly: " & (c.config $ prevOp.info)
  else:
    msg.add "; previous declaration was here: " & (c.config $ prevOp.info)
  localError(c.config, info, errGenerated, msg)

proc whereToBindTypeHook(c: PContext; t: PType): PType =
  result = t
  while true:
    if result.kind in {tyGenericBody, tyGenericInst}: result = result.lastSon
    elif result.kind == tyGenericInvocation: result = result[0]
    else: break
  if result.kind in {tyObject, tyDistinct, tySequence, tyString}:
    result = canonType(c, result)

proc bindTypeHook(c: PContext; s: PSym; n: PNode; op: TTypeAttachedOp) =
  let t = s.typ
  var noError = false
  let cond = if op == attachedDestructor:
               t.len == 2 and t[0] == nil and t[1].kind == tyVar
             else:
               t.len >= 2 and t[0] == nil

  if cond:
    var obj = t[1].skipTypes({tyVar})
    while true:
      incl(obj.flags, tfHasAsgn)
      if obj.kind in {tyGenericBody, tyGenericInst}: obj = obj.lastSon
      elif obj.kind == tyGenericInvocation: obj = obj[0]
      else: break
    if obj.kind in {tyObject, tyDistinct, tySequence, tyString}:
      obj = canonType(c, obj)
      let ao = getAttachedOp(c.graph, obj, op)
      if ao == s:
        discard "forward declared destructor"
      elif ao.isNil and tfCheckedForDestructor notin obj.flags:
        setAttachedOp(c.graph, c.module.position, obj, op, s)
      else:
        prevDestructor(c, ao, obj, n.info)
      noError = true
      if obj.owner.getModule != s.getModule:
        localError(c.config, n.info, errGenerated,
          "type bound operation `" & s.name.s & "` can be defined only in the same module with its type (" & obj.typeToString() & ")")
  if not noError and sfSystemModule notin s.owner.flags:
    localError(c.config, n.info, errGenerated,
      "signature for '" & s.name.s & "' must be proc[T: object](x: var T)")
  incl(s.flags, sfUsed)
  incl(s.flags, sfOverriden)

proc semOverride(c: PContext, s: PSym, n: PNode) =
  let name = s.name.s.normalize
  case name
  of "=destroy":
    bindTypeHook(c, s, n, attachedDestructor)
  of "deepcopy", "=deepcopy":
    if s.typ.len == 2 and
        s.typ[1].skipTypes(abstractInst).kind in {tyRef, tyPtr} and
        sameType(s.typ[1], s.typ[0]):
      # Note: we store the deepCopy in the base of the pointer to mitigate
      # the problem that pointers are structural types:
      var t = s.typ[1].skipTypes(abstractInst).lastSon.skipTypes(abstractInst)
      while true:
        if t.kind == tyGenericBody: t = t.lastSon
        elif t.kind == tyGenericInvocation: t = t[0]
        else: break
      if t.kind in {tyObject, tyDistinct, tyEnum, tySequence, tyString}:
        if getAttachedOp(c.graph, t, attachedDeepCopy).isNil:
          setAttachedOp(c.graph, c.module.position, t, attachedDeepCopy, s)
        else:
          localError(c.config, n.info, errGenerated,
                     "cannot bind another 'deepCopy' to: " & typeToString(t))
      else:
        localError(c.config, n.info, errGenerated,
                   "cannot bind 'deepCopy' to: " & typeToString(t))

      if t.owner.getModule != s.getModule:
        localError(c.config, n.info, errGenerated,
          "type bound operation `" & name & "` can be defined only in the same module with its type (" & t.typeToString() & ")")

    else:
      localError(c.config, n.info, errGenerated,
                 "signature for 'deepCopy' must be proc[T: ptr|ref](x: T): T")
    incl(s.flags, sfUsed)
    incl(s.flags, sfOverriden)
  of "=", "=copy", "=sink":
    if s.magic == mAsgn: return
    incl(s.flags, sfUsed)
    incl(s.flags, sfOverriden)
    let t = s.typ
    if t.len == 3 and t[0] == nil and t[1].kind == tyVar:
      var obj = t[1][0]
      while true:
        incl(obj.flags, tfHasAsgn)
        if obj.kind == tyGenericBody: obj = obj.lastSon
        elif obj.kind == tyGenericInvocation: obj = obj[0]
        else: break
      var objB = t[2]
      while true:
        if objB.kind == tyGenericBody: objB = objB.lastSon
        elif objB.kind in {tyGenericInvocation, tyGenericInst}:
          objB = objB[0]
        else: break
      if obj.kind in {tyObject, tyDistinct, tySequence, tyString} and sameType(obj, objB):
        # attach these ops to the canonical tySequence
        obj = canonType(c, obj)
        #echo "ATTACHING TO ", obj.id, " ", s.name.s, " ", cast[int](obj)
        let k = if name == "=" or name == "=copy": attachedAsgn else: attachedSink
        let ao = getAttachedOp(c.graph, obj, k)
        if ao == s:
          discard "forward declared op"
        elif ao.isNil and tfCheckedForDestructor notin obj.flags:
          setAttachedOp(c.graph, c.module.position, obj, k, s)
        else:
          prevDestructor(c, ao, obj, n.info)
        if obj.owner.getModule != s.getModule:
          localError(c.config, n.info, errGenerated,
            "type bound operation `" & name & "` can be defined only in the same module with its type (" & obj.typeToString() & ")")

        return
    if sfSystemModule notin s.owner.flags:
      localError(c.config, n.info, errGenerated,
                "signature for '" & s.name.s & "' must be proc[T: object](x: var T; y: T)")
  of "=trace":
    bindTypeHook(c, s, n, attachedTrace)
  of "=dispose":
    bindTypeHook(c, s, n, attachedDispose)
  else:
    if sfOverriden in s.flags:
      localError(c.config, n.info, errGenerated,
                 "'destroy' or 'deepCopy' expected for 'override'")

proc cursorInProcAux(conf: ConfigRef; n: PNode): bool =
  if inCheckpoint(n.info, conf.m.trackPos) != cpNone: return true
  for i in 0..<n.safeLen:
    if cursorInProcAux(conf, n[i]): return true

proc cursorInProc(conf: ConfigRef; n: PNode): bool =
  if n.info.fileIndex == conf.m.trackPos.fileIndex:
    result = cursorInProcAux(conf, n)

type
  TProcCompilationSteps = enum
    stepRegisterSymbol,
    stepDetermineType,

proc hasObjParam(s: PSym): bool =
  var t = s.typ
  for col in 1..<t.len:
    if skipTypes(t[col], skipPtrs).kind == tyObject:
      return true

proc finishMethod(c: PContext, s: PSym) =
  if hasObjParam(s):
    methodDef(c.graph, c.idgen, s)

proc semMethodPrototype(c: PContext; s: PSym; n: PNode) =
  if isGenericRoutine(s):
    let tt = s.typ
    var foundObj = false
    # we start at 1 for now so that tparsecombnum continues to compile.
    # XXX Revisit this problem later.
    for col in 1..<tt.len:
      let t = tt[col]
      if t != nil and t.kind == tyGenericInvocation:
        var x = skipTypes(t[0], {tyVar, tyLent, tyPtr, tyRef, tyGenericInst,
                                      tyGenericInvocation, tyGenericBody,
                                      tyAlias, tySink, tyOwned})
        if x.kind == tyObject and t.len-1 == n[genericParamsPos].len:
          foundObj = true
          addMethodToGeneric(c.graph, c.module.position, x, col, s)
    message(c.config, n.info, warnDeprecated, "generic methods are deprecated")
    #if not foundObj:
    #  message(c.config, n.info, warnDeprecated, "generic method not attachable to object type is deprecated")
  else:
    # why check for the body? bug #2400 has none. Checking for sfForward makes
    # no sense either.
    # and result[bodyPos].kind != nkEmpty:
    if hasObjParam(s):
      methodDef(c.graph, c.idgen, s)
    else:
      localError(c.config, n.info, "'method' needs a parameter that has an object type")

proc semProcAux(c: PContext, n: PNode, kind: TSymKind,
                validPragmas: TSpecialWords,
                phase = stepRegisterSymbol): PNode =
  result = semProcAnnotation(c, n, validPragmas)
  if result != nil: return result
  result = n
  checkMinSonsLen(n, bodyPos + 1, c.config)
  var s: PSym
  var typeIsDetermined = false
  var isAnon = false
  if n[namePos].kind != nkSym:
    assert phase == stepRegisterSymbol

    if n[namePos].kind == nkEmpty:
      s = newSym(kind, c.cache.idAnon, nextSymId c.idgen, getCurrOwner(c), n.info)
      incl(s.flags, sfUsed)
      isAnon = true
    else:
      s = semIdentDef(c, n[0], kind)
    n[namePos] = newSymNode(s)
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

  s.options = c.config.options

  # before compiling the proc body, set as current the scope
  # where the proc was declared
  let oldScope = c.currentScope
  #c.currentScope = s.scope
  pushOwner(c, s)
  openScope(c)
  var gp: PNode
  if n[genericParamsPos].kind != nkEmpty:
    gp = setGenericParamsMisc(c, n)
  else:
    gp = newNodeI(nkGenericParams, n.info)
  # process parameters:
  if n[paramsPos].kind != nkEmpty:
    semParamList(c, n[paramsPos], gp, s)
    if gp.len > 0:
      if n[genericParamsPos].kind == nkEmpty:
        # we have a list of implicit type parameters:
        n[genericParamsPos] = gp
        # check for semantics again:
        # semParamList(c, n[ParamsPos], nil, s)
  else:
    s.typ = newProcType(c, n.info)
  if tfTriggersCompileTime in s.typ.flags: incl(s.flags, sfCompileTime)
  if n[patternPos].kind != nkEmpty:
    n[patternPos] = semPattern(c, n[patternPos])
  if s.kind == skIterator:
    s.typ.flags.incl(tfIterator)
  elif s.kind == skFunc:
    incl(s.flags, sfNoSideEffect)
    incl(s.typ.flags, tfNoSideEffect)
  var (proto, comesFromShadowScope) = if isAnon: (nil, false)
                                      else: searchForProc(c, oldScope, s)
  if proto == nil and sfForward in s.flags:
    #This is a definition that shares its sym with its forward declaration (generated by a macro),
    #if the symbol is also gensymmed we won't find it with searchForProc, so we check here
    proto = s
  if proto == nil:
    if s.kind == skIterator:
      if s.typ.callConv != ccClosure:
        s.typ.callConv = if isAnon: ccClosure else: ccInline
    else:
      s.typ.callConv = lastOptionEntry(c).defaultCC
    # add it here, so that recursive procs are possible:
    if sfGenSym in s.flags:
      if s.owner == nil: s.owner = getCurrOwner(c)
    elif kind in OverloadableSyms:
      if not typeIsDetermined:
        addInterfaceOverloadableSymAt(c, oldScope, s)
    else:
      if not typeIsDetermined:
        addInterfaceDeclAt(c, oldScope, s)
    if n[pragmasPos].kind != nkEmpty:
      pragma(c, s, n[pragmasPos], validPragmas)
    else:
      implicitPragmas(c, s, n, validPragmas)
    styleCheckDef(c.config, s)
    onDef(n[namePos].info, s)
  else:
    if n[pragmasPos].kind != nkEmpty:
      pragma(c, s, n[pragmasPos], validPragmas)
      # To ease macro generation that produce forwarded .async procs we now
      # allow a bit redundancy in the pragma declarations. The rule is
      # a prototype's pragma list must be a superset of the current pragma
      # list.
      # XXX This needs more checks eventually, for example that external
      # linking names do agree:
      if proto.typ.callConv != s.typ.callConv or proto.typ.flags < s.typ.flags:
        localError(c.config, n[pragmasPos].info, errPragmaOnlyInHeaderOfProcX %
          ("'" & proto.name.s & "' from " & c.config$proto.info))
    styleCheckDef(c.config, s)
    onDefResolveForward(n[namePos].info, proto)
    if sfForward notin proto.flags and proto.magic == mNone:
      wrongRedefinition(c, n.info, proto.name.s, proto.info)
    if not comesFromShadowScope:
      excl(proto.flags, sfForward)
      incl(proto.flags, sfWasForwarded)
    suggestSym(c.graph, s.info, proto, c.graph.usageSym)
    closeScope(c)         # close scope with wrong parameter symbols
    openScope(c)          # open scope for old (correct) parameter symbols
    if proto.ast[genericParamsPos].kind != nkEmpty:
      addGenericParamListToScope(c, proto.ast[genericParamsPos])
    addParams(c, proto.typ.n, proto.kind)
    proto.info = s.info       # more accurate line information
    proto.options = s.options
    s = proto
    n[genericParamsPos] = proto.ast[genericParamsPos]
    n[paramsPos] = proto.ast[paramsPos]
    n[pragmasPos] = proto.ast[pragmasPos]
    if n[namePos].kind != nkSym: internalError(c.config, n.info, "semProcAux")
    n[namePos].sym = proto
    if importantComments(c.config) and proto.ast.comment.len > 0:
      n.comment = proto.ast.comment
    proto.ast = n             # needed for code generation
    popOwner(c)
    pushOwner(c, s)

  if sfOverriden in s.flags or s.name.s[0] == '=': semOverride(c, s, n)
  if s.name.s[0] in {'.', '('}:
    if s.name.s in [".", ".()", ".="] and {Feature.destructor, dotOperators} * c.features == {}:
      localError(c.config, n.info, "the overloaded " & s.name.s &
        " operator has to be enabled with {.experimental: \"dotOperators\".}")
    elif s.name.s == "()" and callOperator notin c.features:
      localError(c.config, n.info, "the overloaded " & s.name.s &
        " operator has to be enabled with {.experimental: \"callOperator\".}")

  if n[bodyPos].kind != nkEmpty and sfError notin s.flags:
    # for DLL generation we allow sfImportc to have a body, for use in VM
    if sfBorrow in s.flags:
      localError(c.config, n[bodyPos].info, errImplOfXNotAllowed % s.name.s)
    let usePseudoGenerics = kind in {skMacro, skTemplate}
    # Macros and Templates can have generic parameters, but they are
    # only used for overload resolution (there is no instantiation of
    # the symbol, so we must process the body now)
    if not usePseudoGenerics and c.config.ideCmd in {ideSug, ideCon} and not
        cursorInProc(c.config, n[bodyPos]):
      discard "speed up nimsuggest"
      if s.kind == skMethod: semMethodPrototype(c, s, n)
    else:
      pushProcCon(c, s)
      if n[genericParamsPos].kind == nkEmpty or usePseudoGenerics:
        if not usePseudoGenerics and s.magic == mNone: paramsTypeCheck(c, s.typ)

        maybeAddResult(c, s, n)
        # semantic checking also needed with importc in case used in VM
        s.ast[bodyPos] = hloBody(c, semProcBody(c, n[bodyPos]))
        # unfortunately we cannot skip this step when in 'system.compiles'
        # context as it may even be evaluated in 'system.compiles':
        trackProc(c, s, s.ast[bodyPos])
        if s.kind == skMethod: semMethodPrototype(c, s, n)
      else:
        if (s.typ[0] != nil and kind != skIterator) or kind == skMacro:
          addDecl(c, newSym(skUnknown, getIdent(c.cache, "result"), nextSymId c.idgen, nil, n.info))

        openScope(c)
        n[bodyPos] = semGenericStmt(c, n[bodyPos])
        closeScope(c)
        if s.magic == mNone:
          fixupInstantiatedSymbols(c, s)
        if s.kind == skMethod: semMethodPrototype(c, s, n)
      if sfImportc in s.flags:
        # don't ignore the body in case used in VM
        # n[bodyPos] = c.graph.emptyNode
        discard
      popProcCon(c)
  else:
    if s.kind in {skProc, skFunc} and s.typ[0] != nil and s.typ[0].kind == tyUntyped:
      # `auto` is represented as `tyUntyped` at this point in compilation.
      localError(c.config, n[paramsPos][0].info, "return type 'auto' cannot be used in forward declarations")

    if s.kind == skMethod: semMethodPrototype(c, s, n)
    if proto != nil: localError(c.config, n.info, errImplOfXexpected % proto.name.s)
    if {sfImportc, sfBorrow, sfError} * s.flags == {} and s.magic == mNone:
      incl(s.flags, sfForward)
      incl(s.flags, sfWasForwarded)
    elif sfBorrow in s.flags: semBorrow(c, n, s)
  sideEffectsCheck(c, s)
  closeScope(c)           # close scope for parameters
  # c.currentScope = oldScope
  popOwner(c)
  if n[patternPos].kind != nkEmpty:
    c.patterns.add(s)
  if isAnon:
    n.transitionSonsKind(nkLambda)
    result.typ = s.typ
    if optOwnedRefs in c.config.globalOptions:
      result.typ = makeVarType(c, result.typ, tyOwned)
  if isTopLevel(c) and s.kind != skIterator and
      s.typ.callConv == ccClosure:
    localError(c.config, s.info, "'.closure' calling convention for top level routines is invalid")

proc determineType(c: PContext, s: PSym) =
  if s.typ != nil: return
  #if s.magic != mNone: return
  #if s.ast.isNil: return
  discard semProcAux(c, s.ast, s.kind, {}, stepDetermineType)

proc semIterator(c: PContext, n: PNode): PNode =
  # gensym'ed iterator?
  if n[namePos].kind == nkSym:
    # gensym'ed iterators might need to become closure iterators:
    n[namePos].sym.owner = getCurrOwner(c)
    n[namePos].sym.transitionRoutineSymKind(skIterator)
  result = semProcAux(c, n, skIterator, iteratorPragmas)
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != n.kind: return
  var s = result[namePos].sym
  var t = s.typ
  if t[0] == nil and s.typ.callConv != ccClosure:
    localError(c.config, n.info, "iterator needs a return type")
  # iterators are either 'inline' or 'closure'; for backwards compatibility,
  # we require first class iterators to be marked with 'closure' explicitly
  # -- at least for 0.9.2.
  if s.typ.callConv == ccClosure:
    incl(s.typ.flags, tfCapturesEnv)
  else:
    s.typ.callConv = ccInline
  if n[bodyPos].kind == nkEmpty and s.magic == mNone and c.inConceptDecl == 0:
    localError(c.config, n.info, errImplOfXexpected % s.name.s)
  if optOwnedRefs in c.config.globalOptions and result.typ != nil:
    result.typ = makeVarType(c, result.typ, tyOwned)
    result.typ.callConv = ccClosure

proc semProc(c: PContext, n: PNode): PNode =
  result = semProcAux(c, n, skProc, procPragmas)

proc semFunc(c: PContext, n: PNode): PNode =
  result = semProcAux(c, n, skFunc, procPragmas)

proc semMethod(c: PContext, n: PNode): PNode =
  if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "method")
  result = semProcAux(c, n, skMethod, methodPragmas)
  # macros can transform converters to nothing:
  if namePos >= result.safeLen: return result
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != nkMethodDef: return
  var s = result[namePos].sym
  # we need to fix the 'auto' return type for the dispatcher here (see tautonotgeneric
  # test case):
  let disp = getDispatcher(s)
  # auto return type?
  if disp != nil and disp.typ[0] != nil and disp.typ[0].kind == tyUntyped:
    let ret = s.typ[0]
    disp.typ[0] = ret
    if disp.ast[resultPos].kind == nkSym:
      if isEmptyType(ret): disp.ast[resultPos] = c.graph.emptyNode
      else: disp.ast[resultPos].sym.typ = ret

proc semConverterDef(c: PContext, n: PNode): PNode =
  if not isTopLevel(c): localError(c.config, n.info, errXOnlyAtModuleScope % "converter")
  checkSonsLen(n, bodyPos + 1, c.config)
  result = semProcAux(c, n, skConverter, converterPragmas)
  # macros can transform converters to nothing:
  if namePos >= result.safeLen: return result
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != nkConverterDef: return
  var s = result[namePos].sym
  var t = s.typ
  if t[0] == nil: localError(c.config, n.info, errXNeedsReturnType % "converter")
  if t.len != 2: localError(c.config, n.info, "a converter takes exactly one argument")
  addConverter(c, LazySym(sym: s))

proc semMacroDef(c: PContext, n: PNode): PNode =
  checkSonsLen(n, bodyPos + 1, c.config)
  result = semProcAux(c, n, skMacro, macroPragmas)
  # macros can transform macros to nothing:
  if namePos >= result.safeLen: return result
  # bug #7093: if after a macro transformation we don't have an
  # nkIteratorDef aynmore, return. The iterator then might have been
  # sem'checked already. (Or not, if the macro skips it.)
  if result.kind != nkMacroDef: return
  var s = result[namePos].sym
  var t = s.typ
  var allUntyped = true
  for i in 1..<t.n.len:
    let param = t.n[i].sym
    if param.typ.kind != tyUntyped: allUntyped = false
  if allUntyped: incl(s.flags, sfAllUntyped)
  if n[bodyPos].kind == nkEmpty:
    localError(c.config, n.info, errImplOfXexpected % s.name.s)

proc incMod(c: PContext, n: PNode, it: PNode, includeStmtResult: PNode) =
  var f = checkModuleName(c.config, it)
  if f != InvalidFileIdx:
    addIncludeFileDep(c, f)
    if containsOrIncl(c.includedFiles, f.int):
      localError(c.config, n.info, errRecursiveDependencyX % toMsgFilename(c.config, f))
    else:
      includeStmtResult.add semStmt(c, c.graph.includeFileCallback(c.graph, c.module, f), {})
      excl(c.includedFiles, f.int)

proc evalInclude(c: PContext, n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  result.add n
  for i in 0..<n.len:
    var imp: PNode
    let it = n[i]
    if it.kind == nkInfix and it.len == 3 and it[0].ident.s != "/":
      localError(c.config, it.info, "Cannot use '" & it[0].ident.s & "' in 'include'.")
    if it.kind == nkInfix and it.len == 3 and it[2].kind == nkBracket:
      let sep = it[0]
      let dir = it[1]
      imp = newNodeI(nkInfix, it.info)
      imp.add sep
      imp.add dir
      imp.add sep # dummy entry, replaced in the loop
      for x in it[2]:
        imp[2] = x
        incMod(c, n, imp, result)
    else:
      incMod(c, n, it, result)

proc setLine(n: PNode, info: TLineInfo) =
  for i in 0..<n.safeLen: setLine(n[i], info)
  n.info = info

proc semPragmaBlock(c: PContext, n: PNode): PNode =
  checkSonsLen(n, 2, c.config)
  let pragmaList = n[0]
  pragma(c, nil, pragmaList, exprPragmas, isStatement = true)
  n[1] = semExpr(c, n[1])
  result = n
  result.typ = n[1].typ
  for i in 0..<pragmaList.len:
    case whichPragma(pragmaList[i])
    of wLine: setLine(result, pragmaList[i].info)
    of wNoRewrite: incl(result.flags, nfNoRewrite)
    else: discard

proc semStaticStmt(c: PContext, n: PNode): PNode =
  #echo "semStaticStmt"
  #writeStackTrace()
  inc c.inStaticContext
  openScope(c)
  let a = semStmt(c, n[0], {})
  closeScope(c)
  dec c.inStaticContext
  n[0] = a
  evalStaticStmt(c.module, c.idgen, c.graph, a, c.p.owner)
  when false:
    # for incremental replays, keep the AST as required for replays:
    result = n
  else:
    result = newNodeI(nkDiscardStmt, n.info, 1)
    result[0] = c.graph.emptyNode

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
    localError(c.config, n.info,
      "cannot infer the concept parameter '%s', due to a type mismatch. " &
      "attempt to equate '%s' and '%s'.",
      [inferred.renderTree, $res.typ, $typ.base])
  typ.n = res

proc semStmtList(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = n
  result.transitionSonsKind(nkStmtList)
  var voidContext = false
  var last = n.len-1
  # by not allowing for nkCommentStmt etc. we ensure nkStmtListExpr actually
  # really *ends* in the expression that produces the type: The compiler now
  # relies on this fact and it's too much effort to change that. And arguably
  #  'R(); #comment' shouldn't produce R's type anyway.
  #while last > 0 and n[last].kind in {nkPragma, nkCommentStmt,
  #                                         nkNilLit, nkEmpty}:
  #  dec last
  for i in 0..<n.len:
    var expr = semExpr(c, n[i], flags)
    n[i] = expr
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
        if verdict == nil or verdict.kind != nkIntLit or verdict.intVal == 0:
          localError(c.config, result.info, "concept predicate failed")
      of tyUnknown: continue
      else: discard
    if n[i].typ == c.enforceVoidContext: #or usesResult(n[i]):
      voidContext = true
      n.typ = c.enforceVoidContext
    if i == last and (n.len == 1 or ({efWantValue, efInTypeof} * flags != {})):
      n.typ = n[i].typ
      if not isEmptyType(n.typ): n.transitionSonsKind(nkStmtListExpr)
    elif i != last or voidContext:
      discardCheck(c, n[i], flags)
    else:
      n.typ = n[i].typ
      if not isEmptyType(n.typ): n.transitionSonsKind(nkStmtListExpr)
    if n[i].kind in nkLastBlockStmts or
        n[i].kind in nkCallKinds and n[i][0].kind == nkSym and
        sfNoReturn in n[i][0].sym.flags:
      for j in i + 1..<n.len:
        case n[j].kind
        of nkPragma, nkCommentStmt, nkNilLit, nkEmpty, nkState: discard
        else: message(c.config, n[j].info, warnUnreachableCode)
    else: discard

  if result.len == 1 and
     # concept bodies should be preserved as a stmt list:
     c.matchedConcept == nil and
     # also, don't make life complicated for macros.
     # they will always expect a proper stmtlist:
     nfBlockArg notin n.flags and
     result[0].kind != nkDefer:
    result = result[0]

  when defined(nimfix):
    if result.kind == nkCommentStmt and not result.comment.isNil and
        not (result.comment[0] == '#' and result.comment[1] == '#'):
      # it is an old-style comment statement: we replace it with 'discard ""':
      prettybase.replaceComment(result.info)

proc semStmt(c: PContext, n: PNode; flags: TExprFlags): PNode =
  if efInTypeof notin flags:
    result = semExprNoType(c, n)
  else:
    result = semExpr(c, n, flags)
