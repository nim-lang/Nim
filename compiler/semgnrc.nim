#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This implements the first pass over the generic body; it resolves some
# symbols. Thus for generics there is a two-phase symbol lookup just like
# in C++.
# A problem is that it cannot be detected if the symbol is introduced
# as in ``var x = ...`` or used because macros/templates can hide this!
# So we have to eval templates/macros right here so that symbol
# lookup can be accurate.

# included from sem.nim

proc getIdentNode(c: PContext; n: PNode): PNode =
  case n.kind
  of nkPostfix: result = getIdentNode(c, n.sons[1])
  of nkPragmaExpr: result = getIdentNode(c, n.sons[0])
  of nkIdent, nkAccQuoted, nkSym: result = n
  else:
    illFormedAst(n, c.config)
    result = n

type
  GenericCtx = object
    toMixin: IntSet
    cursorInBody: bool # only for nimsuggest
    bracketExpr: PNode

  TSemGenericFlag = enum
    withinBind,
    withinTypeDesc,
    withinMixin,
    withinConcept

  TSemGenericFlags = set[TSemGenericFlag]

proc semGenericStmt(c: PContext, n: PNode,
                    flags: TSemGenericFlags, ctx: var GenericCtx): PNode

proc semGenericStmtScope(c: PContext, n: PNode,
                         flags: TSemGenericFlags,
                         ctx: var GenericCtx): PNode =
  openScope(c)
  result = semGenericStmt(c, n, flags, ctx)
  closeScope(c)

template macroToExpand(s): untyped =
  s.kind in {skMacro, skTemplate} and (s.typ.len == 1 or sfAllUntyped in s.flags)

template macroToExpandSym(s): untyped =
  sfCustomPragma notin s.flags and s.kind in {skMacro, skTemplate} and
    (s.typ.len == 1) and not fromDotExpr

template isMixedIn(sym): bool =
  let s = sym
  s.name.id in ctx.toMixin or (withinConcept in flags and
                               s.magic == mNone and
                               s.kind in OverloadableSyms)

proc semGenericStmtSymbol(c: PContext, n: PNode, s: PSym,
                          ctx: var GenericCtx; flags: TSemGenericFlags,
                          fromDotExpr=false): PNode =
  semIdeForTemplateOrGenericCheck(c.config, n, ctx.cursorInBody)
  incl(s.flags, sfUsed)
  case s.kind
  of skUnknown:
    # Introduced in this pass! Leave it as an identifier.
    result = n
  of skProc, skFunc, skMethod, skIterator, skConverter, skModule:
    result = symChoice(c, n, s, scOpen)
  of skTemplate:
    if macroToExpandSym(s):
      onUse(n.info, s)
      result = semTemplateExpr(c, n, s, {efNoSemCheck})
      result = semGenericStmt(c, result, {}, ctx)
    else:
      result = symChoice(c, n, s, scOpen)
  of skMacro:
    if macroToExpandSym(s):
      onUse(n.info, s)
      result = semMacroExpr(c, n, n, s, {efNoSemCheck})
      result = semGenericStmt(c, result, {}, ctx)
    else:
      result = symChoice(c, n, s, scOpen)
  of skGenericParam:
    if s.typ != nil and s.typ.kind == tyStatic:
      if s.typ.n != nil:
        result = s.typ.n
      else:
        result = n
    else:
      result = newSymNodeTypeDesc(s, n.info)
    onUse(n.info, s)
  of skParam:
    result = n
    onUse(n.info, s)
  of skType:
    if (s.typ != nil) and
       (s.typ.flags * {tfGenericTypeParam, tfImplicitTypeParam} == {}):
      result = newSymNodeTypeDesc(s, n.info)
    else:
      result = n
    onUse(n.info, s)
  else:
    result = newSymNode(s, n.info)
    onUse(n.info, s)

proc lookup(c: PContext, n: PNode, flags: TSemGenericFlags,
            ctx: var GenericCtx): PNode =
  result = n
  let ident = considerQuotedIdent(c, n)
  var s = searchInScopes(c, ident).skipAlias(n, c.config)
  if s == nil:
    s = strTableGet(c.pureEnumFields, ident)
    if s != nil and contains(c.ambiguousSymbols, s.id):
      s = nil
  if s == nil:
    if ident.id notin ctx.toMixin and withinMixin notin flags:
      errorUndeclaredIdentifier(c, n.info, ident.s)
  else:
    if withinBind in flags:
      result = symChoice(c, n, s, scClosed)
    elif s.isMixedIn:
      result = symChoice(c, n, s, scForceOpen)
    else:
      result = semGenericStmtSymbol(c, n, s, ctx, flags)
  # else: leave as nkIdent

proc newDot(n, b: PNode): PNode =
  result = newNodeI(nkDotExpr, n.info)
  result.add(n.sons[0])
  result.add(b)

proc fuzzyLookup(c: PContext, n: PNode, flags: TSemGenericFlags,
                 ctx: var GenericCtx; isMacro: var bool): PNode =
  assert n.kind == nkDotExpr
  semIdeForTemplateOrGenericCheck(c.config, n, ctx.cursorInBody)

  let luf = if withinMixin notin flags: {checkUndeclared, checkModule} else: {checkModule}

  var s = qualifiedLookUp(c, n, luf)
  if s != nil:
    result = semGenericStmtSymbol(c, n, s, ctx, flags)
  else:
    n.sons[0] = semGenericStmt(c, n.sons[0], flags, ctx)
    result = n
    let n = n[1]
    let ident = considerQuotedIdent(c, n)
    var s = searchInScopes(c, ident).skipAlias(n, c.config)
    if s != nil and s.kind in routineKinds:
      isMacro = s.kind in {skTemplate, skMacro}
      if withinBind in flags:
        result = newDot(result, symChoice(c, n, s, scClosed))
      elif s.isMixedIn:
        result = newDot(result, symChoice(c, n, s, scForceOpen))
      else:
        let syms = semGenericStmtSymbol(c, n, s, ctx, flags, fromDotExpr=true)
        if syms.kind == nkSym:
          let choice = symChoice(c, n, s, scForceOpen)
          choice.kind = nkClosedSymChoice
          result = newDot(result, choice)
        else:
          result = newDot(result, syms)

proc addTempDecl(c: PContext; n: PNode; kind: TSymKind) =
  let s = newSymS(skUnknown, getIdentNode(c, n), c)
  addPrelimDecl(c, s)
  styleCheckDef(c.config, n.info, s, kind)
  onDef(n.info, s)

proc semGenericStmt(c: PContext, n: PNode,
                    flags: TSemGenericFlags, ctx: var GenericCtx): PNode =
  result = n

  when defined(nimsuggest):
    if withinTypeDesc in flags: inc c.inTypeContext

  #if conf.cmd == cmdIdeTools: suggestStmt(c, n)
  semIdeForTemplateOrGenericCheck(c.config, n, ctx.cursorInBody)

  case n.kind
  of nkIdent, nkAccQuoted:
    result = lookup(c, n, flags, ctx)
  of nkDotExpr:
    #let luf = if withinMixin notin flags: {checkUndeclared} else: {}
    #var s = qualifiedLookUp(c, n, luf)
    #if s != nil: result = semGenericStmtSymbol(c, n, s)
    # XXX for example: ``result.add`` -- ``add`` needs to be looked up here...
    var dummy: bool
    result = fuzzyLookup(c, n, flags, ctx, dummy)
  of nkSym:
    let a = n.sym
    let b = getGenSym(c, a)
    if b != a: n.sym = b
  of nkEmpty, succ(nkSym)..nkNilLit, nkComesFrom:
    # see tests/compile/tgensymgeneric.nim:
    # We need to open the gensym'ed symbol again so that the instantiation
    # creates a fresh copy; but this is wrong the very first reason for gensym
    # is that scope rules cannot be used! So simply removing 'sfGenSym' does
    # not work. Copying the symbol does not work either because we're already
    # the owner of the symbol! What we need to do is to copy the symbol
    # in the generic instantiation process...
    discard
  of nkBind:
    result = semGenericStmt(c, n.sons[0], flags+{withinBind}, ctx)
  of nkMixinStmt:
    result = semMixinStmt(c, n, ctx.toMixin)
  of nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkCommand, nkCallStrLit:
    # check if it is an expression macro:
    checkMinSonsLen(n, 1, c.config)
    let fn = n.sons[0]
    var s = qualifiedLookUp(c, fn, {})
    if s == nil and
        {withinMixin, withinConcept}*flags == {} and
        fn.kind in {nkIdent, nkAccQuoted} and
        considerQuotedIdent(c, fn).id notin ctx.toMixin:
      errorUndeclaredIdentifier(c, n.info, fn.renderTree)

    var first = int ord(withinConcept in flags)
    var mixinContext = false
    if s != nil:
      incl(s.flags, sfUsed)
      mixinContext = s.magic in {mDefined, mDefinedInScope, mCompiles}
      let sc = symChoice(c, fn, s, if s.isMixedIn: scForceOpen else: scOpen)
      case s.kind
      of skMacro:
        if macroToExpand(s) and sc.safeLen <= 1:
          onUse(fn.info, s)
          result = semMacroExpr(c, n, n, s, {efNoSemCheck})
          result = semGenericStmt(c, result, flags, ctx)
        else:
          n.sons[0] = sc
          result = n
        mixinContext = true
      of skTemplate:
        if macroToExpand(s) and sc.safeLen <= 1:
          onUse(fn.info, s)
          result = semTemplateExpr(c, n, s, {efNoSemCheck})
          result = semGenericStmt(c, result, flags, ctx)
        else:
          n.sons[0] = sc
          result = n
        # BUGFIX: we must not return here, we need to do first phase of
        # symbol lookup. Also since templates and macros can do scope injections
        # we need to put the ``c`` in ``t(c)`` in a mixin context to prevent
        # the famous "undeclared identifier: it" bug:
        mixinContext = true
      of skUnknown, skParam:
        # Leave it as an identifier.
        discard
      of skProc, skFunc, skMethod, skIterator, skConverter, skModule:
        result.sons[0] = sc
        first = 1
        # We're not interested in the example code during this pass so let's
        # skip it
        if s.magic == mRunnableExamples:
          inc first
      of skGenericParam:
        result.sons[0] = newSymNodeTypeDesc(s, fn.info)
        onUse(fn.info, s)
        first = 1
      of skType:
        # bad hack for generics:
        if (s.typ != nil) and (s.typ.kind != tyGenericParam):
          result.sons[0] = newSymNodeTypeDesc(s, fn.info)
          onUse(fn.info, s)
          first = 1
      else:
        result.sons[0] = newSymNode(s, fn.info)
        onUse(fn.info, s)
        first = 1
    elif fn.kind == nkDotExpr:
      result.sons[0] = fuzzyLookup(c, fn, flags, ctx, mixinContext)
      first = 1
    # Consider 'when declared(globalsSlot): ThreadVarSetValue(globalsSlot, ...)'
    # in threads.nim: the subtle preprocessing here binds 'globalsSlot' which
    # is not exported and yet the generic 'threadProcWrapper' works correctly.
    let flags = if mixinContext: flags+{withinMixin} else: flags
    for i in first ..< sonsLen(result):
      result.sons[i] = semGenericStmt(c, result.sons[i], flags, ctx)
  of nkCurlyExpr:
    result = newNodeI(nkCall, n.info)
    result.add newIdentNode(getIdent(c.cache, "{}"), n.info)
    for i in 0 ..< n.len: result.add(n[i])
    result = semGenericStmt(c, result, flags, ctx)
  of nkBracketExpr:
    result = newNodeI(nkCall, n.info)
    result.add newIdentNode(getIdent(c.cache, "[]"), n.info)
    for i in 0 ..< n.len: result.add(n[i])
    withBracketExpr ctx, n.sons[0]:
      result = semGenericStmt(c, result, flags, ctx)
  of nkAsgn, nkFastAsgn:
    checkSonsLen(n, 2, c.config)
    let a = n.sons[0]
    let b = n.sons[1]

    let k = a.kind
    case k
    of nkCurlyExpr:
      result = newNodeI(nkCall, n.info)
      result.add newIdentNode(getIdent(c.cache, "{}="), n.info)
      for i in 0 ..< a.len: result.add(a[i])
      result.add(b)
      result = semGenericStmt(c, result, flags, ctx)
    of nkBracketExpr:
      result = newNodeI(nkCall, n.info)
      result.add newIdentNode(getIdent(c.cache, "[]="), n.info)
      for i in 0 ..< a.len: result.add(a[i])
      result.add(b)
      withBracketExpr ctx, a.sons[0]:
        result = semGenericStmt(c, result, flags, ctx)
    else:
      for i in 0 ..< sonsLen(n):
        result.sons[i] = semGenericStmt(c, n.sons[i], flags, ctx)
  of nkIfStmt:
    for i in 0 ..< sonsLen(n):
      n.sons[i] = semGenericStmtScope(c, n.sons[i], flags, ctx)
  of nkWhenStmt:
    for i in 0 ..< sonsLen(n):
      # bug #8603: conditions of 'when' statements are not
      # in a 'mixin' context:
      let it = n[i]
      if it.kind in {nkElifExpr, nkElifBranch}:
        n.sons[i].sons[0] = semGenericStmt(c, it[0], flags, ctx)
        n.sons[i].sons[1] = semGenericStmt(c, it[1], flags+{withinMixin}, ctx)
      else:
        n.sons[i] = semGenericStmt(c, it, flags+{withinMixin}, ctx)
  of nkWhileStmt:
    openScope(c)
    for i in 0 ..< sonsLen(n):
      n.sons[i] = semGenericStmt(c, n.sons[i], flags, ctx)
    closeScope(c)
  of nkCaseStmt:
    openScope(c)
    n.sons[0] = semGenericStmt(c, n.sons[0], flags, ctx)
    for i in 1 ..< sonsLen(n):
      var a = n.sons[i]
      checkMinSonsLen(a, 1, c.config)
      var L = sonsLen(a)
      for j in 0 .. L-2:
        a.sons[j] = semGenericStmt(c, a.sons[j], flags, ctx)
      a.sons[L - 1] = semGenericStmtScope(c, a.sons[L-1], flags, ctx)
    closeScope(c)
  of nkForStmt, nkParForStmt:
    var L = sonsLen(n)
    openScope(c)
    n.sons[L - 2] = semGenericStmt(c, n.sons[L-2], flags, ctx)
    for i in 0 .. L - 3:
      if (n.sons[i].kind == nkVarTuple):
        for s in n.sons[i]:
          if (s.kind == nkIdent):
            addTempDecl(c,s,skForVar)
      else:
        addTempDecl(c, n.sons[i], skForVar)
    openScope(c)
    n.sons[L - 1] = semGenericStmt(c, n.sons[L-1], flags, ctx)
    closeScope(c)
    closeScope(c)
  of nkBlockStmt, nkBlockExpr, nkBlockType:
    checkSonsLen(n, 2, c.config)
    openScope(c)
    if n.sons[0].kind != nkEmpty:
      addTempDecl(c, n.sons[0], skLabel)
    n.sons[1] = semGenericStmt(c, n.sons[1], flags, ctx)
    closeScope(c)
  of nkTryStmt, nkHiddenTryStmt:
    checkMinSonsLen(n, 2, c.config)
    n.sons[0] = semGenericStmtScope(c, n.sons[0], flags, ctx)
    for i in 1 ..< sonsLen(n):
      var a = n.sons[i]
      checkMinSonsLen(a, 1, c.config)
      var L = sonsLen(a)
      openScope(c)
      for j in 0 .. L-2:
        if a.sons[j].isInfixAs():
          addTempDecl(c, getIdentNode(c, a.sons[j][2]), skLet)
          a.sons[j].sons[1] = semGenericStmt(c, a.sons[j][1], flags+{withinTypeDesc}, ctx)
        else:
          a.sons[j] = semGenericStmt(c, a.sons[j], flags+{withinTypeDesc}, ctx)
      a.sons[L-1] = semGenericStmtScope(c, a.sons[L-1], flags, ctx)
      closeScope(c)

  of nkVarSection, nkLetSection:
    for i in 0 ..< sonsLen(n):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkIdentDefs) and (a.kind != nkVarTuple): illFormedAst(a, c.config)
      checkMinSonsLen(a, 3, c.config)
      var L = sonsLen(a)
      a.sons[L-2] = semGenericStmt(c, a.sons[L-2], flags+{withinTypeDesc}, ctx)
      a.sons[L-1] = semGenericStmt(c, a.sons[L-1], flags, ctx)
      for j in 0 .. L-3:
        addTempDecl(c, getIdentNode(c, a.sons[j]), skVar)
  of nkGenericParams:
    for i in 0 ..< sonsLen(n):
      var a = n.sons[i]
      if (a.kind != nkIdentDefs): illFormedAst(a, c.config)
      checkMinSonsLen(a, 3, c.config)
      var L = sonsLen(a)
      a.sons[L-2] = semGenericStmt(c, a.sons[L-2], flags+{withinTypeDesc}, ctx)
      # do not perform symbol lookup for default expressions
      for j in 0 .. L-3:
        addTempDecl(c, getIdentNode(c, a.sons[j]), skType)
  of nkConstSection:
    for i in 0 ..< sonsLen(n):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkConstDef): illFormedAst(a, c.config)
      checkSonsLen(a, 3, c.config)
      addTempDecl(c, getIdentNode(c, a.sons[0]), skConst)
      a.sons[1] = semGenericStmt(c, a.sons[1], flags+{withinTypeDesc}, ctx)
      a.sons[2] = semGenericStmt(c, a.sons[2], flags, ctx)
  of nkTypeSection:
    for i in 0 ..< sonsLen(n):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkTypeDef): illFormedAst(a, c.config)
      checkSonsLen(a, 3, c.config)
      addTempDecl(c, getIdentNode(c, a.sons[0]), skType)
    for i in 0 ..< sonsLen(n):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkTypeDef): illFormedAst(a, c.config)
      checkSonsLen(a, 3, c.config)
      if a.sons[1].kind != nkEmpty:
        openScope(c)
        a.sons[1] = semGenericStmt(c, a.sons[1], flags, ctx)
        a.sons[2] = semGenericStmt(c, a.sons[2], flags+{withinTypeDesc}, ctx)
        closeScope(c)
      else:
        a.sons[2] = semGenericStmt(c, a.sons[2], flags+{withinTypeDesc}, ctx)
  of nkEnumTy:
    if n.sonsLen > 0:
      if n.sons[0].kind != nkEmpty:
        n.sons[0] = semGenericStmt(c, n.sons[0], flags+{withinTypeDesc}, ctx)
      for i in 1 ..< sonsLen(n):
        var a: PNode
        case n.sons[i].kind
        of nkEnumFieldDef: a = n.sons[i].sons[0]
        of nkIdent: a = n.sons[i]
        else: illFormedAst(n, c.config)
        addDecl(c, newSymS(skUnknown, getIdentNode(c, a), c))
  of nkObjectTy, nkTupleTy, nkTupleClassTy:
    discard
  of nkFormalParams:
    checkMinSonsLen(n, 1, c.config)
    if n.sons[0].kind != nkEmpty:
      n.sons[0] = semGenericStmt(c, n.sons[0], flags+{withinTypeDesc}, ctx)
    for i in 1 ..< sonsLen(n):
      var a = n.sons[i]
      if (a.kind != nkIdentDefs): illFormedAst(a, c.config)
      checkMinSonsLen(a, 3, c.config)
      var L = sonsLen(a)
      a.sons[L-2] = semGenericStmt(c, a.sons[L-2], flags+{withinTypeDesc}, ctx)
      a.sons[L-1] = semGenericStmt(c, a.sons[L-1], flags, ctx)
      for j in 0 .. L-3:
        addTempDecl(c, getIdentNode(c, a.sons[j]), skParam)
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
     nkFuncDef, nkIteratorDef, nkLambdaKinds:
    checkSonsLen(n, bodyPos + 1, c.config)
    if n.sons[namePos].kind != nkEmpty:
      addTempDecl(c, getIdentNode(c, n.sons[0]), skProc)
    openScope(c)
    n.sons[genericParamsPos] = semGenericStmt(c, n.sons[genericParamsPos],
                                              flags, ctx)
    if n.sons[paramsPos].kind != nkEmpty:
      if n.sons[paramsPos].sons[0].kind != nkEmpty:
        addPrelimDecl(c, newSym(skUnknown, getIdent(c.cache, "result"), nil, n.info))
      n.sons[paramsPos] = semGenericStmt(c, n.sons[paramsPos], flags, ctx)
    n.sons[pragmasPos] = semGenericStmt(c, n.sons[pragmasPos], flags, ctx)
    var body: PNode
    if n.sons[namePos].kind == nkSym:
      let s = n.sons[namePos].sym
      if sfGenSym in s.flags and s.ast == nil:
        body = n.sons[bodyPos]
      else:
        body = s.getBody
    else: body = n.sons[bodyPos]
    n.sons[bodyPos] = semGenericStmtScope(c, body, flags, ctx)
    closeScope(c)
  of nkPragma, nkPragmaExpr: discard
  of nkExprColonExpr, nkExprEqExpr:
    checkMinSonsLen(n, 2, c.config)
    result.sons[1] = semGenericStmt(c, n.sons[1], flags, ctx)
  else:
    for i in 0 ..< sonsLen(n):
      result.sons[i] = semGenericStmt(c, n.sons[i], flags, ctx)

  when defined(nimsuggest):
    if withinTypeDesc in flags: dec c.inTypeContext

proc semGenericStmt(c: PContext, n: PNode): PNode =
  var ctx: GenericCtx
  ctx.toMixin = initIntset()
  result = semGenericStmt(c, n, {}, ctx)
  semIdeForTemplateOrGeneric(c, result, ctx.cursorInBody)

proc semConceptBody(c: PContext, n: PNode): PNode =
  var ctx: GenericCtx
  ctx.toMixin = initIntset()
  result = semGenericStmt(c, n, {withinConcept}, ctx)
  semIdeForTemplateOrGeneric(c, result, ctx.cursorInBody)

