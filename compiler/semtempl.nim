#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from sem.nim

discard """
  hygienic templates:

    template `||` (a, b: untyped): untyped =
      let aa = a
      if aa: aa else: b

    var
      a, b: T

    echo a || b || a

  Each evaluation context has to be different and we need to perform
  some form of preliminary symbol lookup in template definitions. Hygiene is
  a way to achieve lexical scoping at compile time.
"""

const
  errImplOfXNotAllowed = "implementation of '$1' is not allowed"

type
  TSymBinding = enum
    spNone, spGenSym, spInject

proc symBinding(n: PNode): TSymBinding =
  for i in countup(0, sonsLen(n) - 1):
    var it = n.sons[i]
    var key = if it.kind == nkExprColonExpr: it.sons[0] else: it
    if key.kind == nkIdent:
      case whichKeyword(key.ident)
      of wGensym: return spGenSym
      of wInject: return spInject
      else: discard

type
  TSymChoiceRule = enum
    scClosed, scOpen, scForceOpen

proc symChoice(c: PContext, n: PNode, s: PSym, r: TSymChoiceRule): PNode =
  var
    a: PSym
    o: TOverloadIter
  var i = 0
  a = initOverloadIter(o, c, n)
  while a != nil:
    if a.kind != skModule:
      inc(i)
      if i > 1: break
    a = nextOverloadIter(o, c, n)
  let info = getCallLineInfo(n)
  if i <= 1 and r != scForceOpen:
    # XXX this makes more sense but breaks bootstrapping for now:
    # (s.kind notin routineKinds or s.magic != mNone):
    # for instance 'nextTry' is both in tables.nim and astalgo.nim ...
    result = newSymNode(s, info)
    markUsed(c.config, info, s, c.graph.usageSym)
    onUse(info, s)
  else:
    # semantic checking requires a type; ``fitNode`` deals with it
    # appropriately
    let kind = if r == scClosed or n.kind == nkDotExpr: nkClosedSymChoice
               else: nkOpenSymChoice
    result = newNodeIT(kind, info, newTypeS(tyNone, c))
    a = initOverloadIter(o, c, n)
    while a != nil:
      if a.kind != skModule:
        incl(a.flags, sfUsed)
        addSon(result, newSymNode(a, info))
        onUse(info, a)
      a = nextOverloadIter(o, c, n)

proc semBindStmt(c: PContext, n: PNode, toBind: var IntSet): PNode =
  for i in 0 ..< n.len:
    var a = n.sons[i]
    # If 'a' is an overloaded symbol, we used to use the first symbol
    # as a 'witness' and use the fact that subsequent lookups will yield
    # the same symbol!
    # This is however not true anymore for hygienic templates as semantic
    # processing for them changes the symbol table...
    let s = qualifiedLookUp(c, a, {checkUndeclared})
    if s != nil:
      # we need to mark all symbols:
      let sc = symChoice(c, n, s, scClosed)
      if sc.kind == nkSym:
        toBind.incl(sc.sym.id)
      else:
        for x in items(sc): toBind.incl(x.sym.id)
    else:
      illFormedAst(a, c.config)
  result = newNodeI(nkEmpty, n.info)

proc semMixinStmt(c: PContext, n: PNode, toMixin: var IntSet): PNode =
  for i in 0 ..< n.len:
    toMixin.incl(considerQuotedIdent(c, n.sons[i]).id)
  result = newNodeI(nkEmpty, n.info)

proc replaceIdentBySym(c: PContext; n: var PNode, s: PNode) =
  case n.kind
  of nkPostfix: replaceIdentBySym(c, n.sons[1], s)
  of nkPragmaExpr: replaceIdentBySym(c, n.sons[0], s)
  of nkIdent, nkAccQuoted, nkSym: n = s
  else: illFormedAst(n, c.config)

type
  TemplCtx = object
    c: PContext
    toBind, toMixin, toInject: IntSet
    owner: PSym
    cursorInBody: bool # only for nimsuggest
    scopeN: int

template withBracketExpr(ctx, x, body: untyped) =
  body

proc getIdentNode(c: var TemplCtx, n: PNode): PNode =
  case n.kind
  of nkPostfix: result = getIdentNode(c, n.sons[1])
  of nkPragmaExpr: result = getIdentNode(c, n.sons[0])
  of nkIdent:
    result = n
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil:
      if s.owner == c.owner and s.kind == skParam:
        result = newSymNode(s, n.info)
  of nkAccQuoted, nkSym: result = n
  else:
    illFormedAst(n, c.c.config)
    result = n

proc isTemplParam(c: TemplCtx, n: PNode): bool {.inline.} =
  result = n.kind == nkSym and n.sym.kind == skParam and
           n.sym.owner == c.owner and sfGenSym notin n.sym.flags

proc semTemplBody(c: var TemplCtx, n: PNode): PNode

proc openScope(c: var TemplCtx) =
  openScope(c.c)

proc closeScope(c: var TemplCtx) =
  closeScope(c.c)

proc semTemplBodyScope(c: var TemplCtx, n: PNode): PNode =
  openScope(c)
  result = semTemplBody(c, n)
  closeScope(c)

proc onlyReplaceParams(c: var TemplCtx, n: PNode): PNode =
  result = n
  if n.kind == nkIdent:
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil:
      if s.owner == c.owner and s.kind == skParam:
        incl(s.flags, sfUsed)
        result = newSymNode(s, n.info)
        onUse(n.info, s)
  else:
    for i in 0 ..< n.safeLen:
      result.sons[i] = onlyReplaceParams(c, n.sons[i])

proc newGenSym(kind: TSymKind, n: PNode, c: var TemplCtx): PSym =
  result = newSym(kind, considerQuotedIdent(c.c, n), c.owner, n.info)
  incl(result.flags, sfGenSym)
  incl(result.flags, sfShadowed)

proc addLocalDecl(c: var TemplCtx, n: var PNode, k: TSymKind) =
  # locals default to 'gensym':
  if n.kind == nkPragmaExpr and symBinding(n.sons[1]) == spInject:
    # even if injected, don't produce a sym choice here:
    #n = semTemplBody(c, n)
    var x = n[0]
    while true:
      case x.kind
      of nkPostfix: x = x[1]
      of nkPragmaExpr: x = x[0]
      of nkIdent: break
      of nkAccQuoted:
        # consider:  type `T TemplParam` {.inject.}
        # it suffices to return to treat it like 'inject':
        n = onlyReplaceParams(c, n)
        return
      else:
        illFormedAst(x, c.c.config)
    let ident = getIdentNode(c, x)
    if not isTemplParam(c, ident):
      c.toInject.incl(x.ident.id)
    else:
      replaceIdentBySym(c.c, n, ident)
  else:
    let ident = getIdentNode(c, n)
    if not isTemplParam(c, ident):
      # fix #2670, consider:
      #
      # when b:
      #    var a = "hi"
      # else:
      #    var a = 5
      # echo a
      #
      # We need to ensure that both 'a' produce the same gensym'ed symbol.
      # So we need only check the *current* scope.
      let s = localSearchInScope(c.c, considerQuotedIdent(c.c, ident))
      if s != nil and s.owner == c.owner and sfGenSym in s.flags:
        onUse(n.info, s)
        replaceIdentBySym(c.c, n, newSymNode(s, n.info))
      elif not (n.kind == nkSym and sfGenSym in n.sym.flags):
        let local = newGenSym(k, ident, c)
        addPrelimDecl(c.c, local)
        styleCheckDef(c.c.config, n.info, local)
        onDef(n.info, local)
        replaceIdentBySym(c.c, n, newSymNode(local, n.info))
    else:
      replaceIdentBySym(c.c, n, ident)

proc semTemplSymbol(c: PContext, n: PNode, s: PSym): PNode =
  incl(s.flags, sfUsed)
  # we do not call onUse here, as the identifier is not really
  # resolved here. We will fixup the used identifiers later.
  case s.kind
  of skUnknown:
    # Introduced in this pass! Leave it as an identifier.
    result = n
  of OverloadableSyms:
    result = symChoice(c, n, s, scOpen)
  of skGenericParam:
    result = newSymNodeTypeDesc(s, n.info)
  of skParam:
    result = n
  of skType:
    result = newSymNodeTypeDesc(s, n.info)
  else:
    result = newSymNode(s, n.info)

proc semRoutineInTemplName(c: var TemplCtx, n: PNode): PNode =
  result = n
  if n.kind == nkIdent:
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil:
      if s.owner == c.owner and (s.kind == skParam or sfGenSym in s.flags):
        incl(s.flags, sfUsed)
        result = newSymNode(s, n.info)
        onUse(n.info, s)
  else:
    for i in countup(0, safeLen(n) - 1):
      result.sons[i] = semRoutineInTemplName(c, n.sons[i])

proc semRoutineInTemplBody(c: var TemplCtx, n: PNode, k: TSymKind): PNode =
  result = n
  checkSonsLen(n, bodyPos + 1, c.c.config)
  # routines default to 'inject':
  if n.kind notin nkLambdaKinds and symBinding(n.sons[pragmasPos]) == spGenSym:
    let ident = getIdentNode(c, n.sons[namePos])
    if not isTemplParam(c, ident):
      var s = newGenSym(k, ident, c)
      s.ast = n
      addPrelimDecl(c.c, s)
      styleCheckDef(c.c.config, n.info, s)
      onDef(n.info, s)
      n.sons[namePos] = newSymNode(s, n.sons[namePos].info)
    else:
      n.sons[namePos] = ident
  else:
    n.sons[namePos] = semRoutineInTemplName(c, n.sons[namePos])
  # open scope for parameters
  openScope(c)
  for i in patternPos..miscPos:
    n.sons[i] = semTemplBody(c, n.sons[i])
  # open scope for locals
  inc c.scopeN
  openScope(c)
  n.sons[bodyPos] = semTemplBody(c, n.sons[bodyPos])
  # close scope for locals
  closeScope(c)
  dec c.scopeN
  # close scope for parameters
  closeScope(c)

proc semTemplSomeDecl(c: var TemplCtx, n: PNode, symKind: TSymKind; start=0) =
  for i in countup(start, sonsLen(n) - 1):
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue
    if (a.kind != nkIdentDefs) and (a.kind != nkVarTuple): illFormedAst(a, c.c.config)
    checkMinSonsLen(a, 3, c.c.config)
    var L = sonsLen(a)
    when defined(nimsuggest):
      inc c.c.inTypeContext
    a.sons[L-2] = semTemplBody(c, a.sons[L-2])
    when defined(nimsuggest):
      dec c.c.inTypeContext
    a.sons[L-1] = semTemplBody(c, a.sons[L-1])
    for j in countup(0, L-3):
      addLocalDecl(c, a.sons[j], symKind)

proc semPattern(c: PContext, n: PNode): PNode

proc semTemplBodySons(c: var TemplCtx, n: PNode): PNode =
  result = n
  for i in 0 ..< n.len:
    result.sons[i] = semTemplBody(c, n.sons[i])

proc semTemplBody(c: var TemplCtx, n: PNode): PNode =
  result = n
  semIdeForTemplateOrGenericCheck(c.c.config, n, c.cursorInBody)
  case n.kind
  of nkIdent:
    if n.ident.id in c.toInject: return n
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil:
      if s.owner == c.owner and s.kind == skParam:
        incl(s.flags, sfUsed)
        result = newSymNode(s, n.info)
        onUse(n.info, s)
      elif contains(c.toBind, s.id):
        result = symChoice(c.c, n, s, scClosed)
      elif contains(c.toMixin, s.name.id):
        result = symChoice(c.c, n, s, scForceOpen)
      elif s.owner == c.owner and sfGenSym in s.flags:
        # template tmp[T](x: var seq[T]) =
        # var yz: T
        incl(s.flags, sfUsed)
        result = newSymNode(s, n.info)
        onUse(n.info, s)
      else:
        result = semTemplSymbol(c.c, n, s)
  of nkBind:
    result = semTemplBody(c, n.sons[0])
  of nkBindStmt:
    result = semBindStmt(c.c, n, c.toBind)
  of nkMixinStmt:
    if c.scopeN > 0: result = semTemplBodySons(c, n)
    else: result = semMixinStmt(c.c, n, c.toMixin)
  of nkEmpty, nkSym..nkNilLit, nkComesFrom:
    discard
  of nkIfStmt:
    for i in countup(0, sonsLen(n)-1):
      var it = n.sons[i]
      if it.len == 2:
        openScope(c)
        it.sons[0] = semTemplBody(c, it.sons[0])
        it.sons[1] = semTemplBody(c, it.sons[1])
        closeScope(c)
      else:
        n.sons[i] = semTemplBodyScope(c, it)
  of nkWhileStmt:
    openScope(c)
    for i in countup(0, sonsLen(n)-1):
      n.sons[i] = semTemplBody(c, n.sons[i])
    closeScope(c)
  of nkCaseStmt:
    openScope(c)
    n.sons[0] = semTemplBody(c, n.sons[0])
    for i in countup(1, sonsLen(n)-1):
      var a = n.sons[i]
      checkMinSonsLen(a, 1, c.c.config)
      var L = sonsLen(a)
      for j in countup(0, L-2):
        a.sons[j] = semTemplBody(c, a.sons[j])
      a.sons[L-1] = semTemplBodyScope(c, a.sons[L-1])
    closeScope(c)
  of nkForStmt, nkParForStmt:
    var L = sonsLen(n)
    openScope(c)
    n.sons[L-2] = semTemplBody(c, n.sons[L-2])
    for i in countup(0, L - 3):
      addLocalDecl(c, n.sons[i], skForVar)
    openScope(c)
    n.sons[L-1] = semTemplBody(c, n.sons[L-1])
    closeScope(c)
    closeScope(c)
  of nkBlockStmt, nkBlockExpr, nkBlockType:
    checkSonsLen(n, 2, c.c.config)
    openScope(c)
    if n.sons[0].kind != nkEmpty:
      addLocalDecl(c, n.sons[0], skLabel)
      when false:
        # labels are always 'gensym'ed:
        let s = newGenSym(skLabel, n.sons[0], c)
        addPrelimDecl(c.c, s)
        styleCheckDef(c.c.config, s)
        onDef(n[0].info, s)
        n.sons[0] = newSymNode(s, n.sons[0].info)
    n.sons[1] = semTemplBody(c, n.sons[1])
    closeScope(c)
  of nkTryStmt:
    checkMinSonsLen(n, 2, c.c.config)
    n.sons[0] = semTemplBodyScope(c, n.sons[0])
    for i in countup(1, sonsLen(n)-1):
      var a = n.sons[i]
      checkMinSonsLen(a, 1, c.c.config)
      var L = sonsLen(a)
      openScope(c)
      for j in countup(0, L-2):
        if a.sons[j].isInfixAs():
          addLocalDecl(c, a.sons[j].sons[2], skLet)
          a.sons[j].sons[1] = semTemplBody(c, a.sons[j][1])
        else:
          a.sons[j] = semTemplBody(c, a.sons[j])
      a.sons[L-1] = semTemplBodyScope(c, a.sons[L-1])
      closeScope(c)
  of nkVarSection: semTemplSomeDecl(c, n, skVar)
  of nkLetSection: semTemplSomeDecl(c, n, skLet)
  of nkFormalParams:
    checkMinSonsLen(n, 1, c.c.config)
    n.sons[0] = semTemplBody(c, n.sons[0])
    semTemplSomeDecl(c, n, skParam, 1)
  of nkConstSection:
    for i in countup(0, sonsLen(n) - 1):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkConstDef): illFormedAst(a, c.c.config)
      checkSonsLen(a, 3, c.c.config)
      addLocalDecl(c, a.sons[0], skConst)
      a.sons[1] = semTemplBody(c, a.sons[1])
      a.sons[2] = semTemplBody(c, a.sons[2])
  of nkTypeSection:
    for i in countup(0, sonsLen(n) - 1):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkTypeDef): illFormedAst(a, c.c.config)
      checkSonsLen(a, 3, c.c.config)
      addLocalDecl(c, a.sons[0], skType)
    for i in countup(0, sonsLen(n) - 1):
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      if (a.kind != nkTypeDef): illFormedAst(a, c.c.config)
      checkSonsLen(a, 3, c.c.config)
      if a.sons[1].kind != nkEmpty:
        openScope(c)
        a.sons[1] = semTemplBody(c, a.sons[1])
        a.sons[2] = semTemplBody(c, a.sons[2])
        closeScope(c)
      else:
        a.sons[2] = semTemplBody(c, a.sons[2])
  of nkProcDef, nkLambdaKinds:
    result = semRoutineInTemplBody(c, n, skProc)
  of nkFuncDef:
    result = semRoutineInTemplBody(c, n, skFunc)
  of nkMethodDef:
    result = semRoutineInTemplBody(c, n, skMethod)
  of nkIteratorDef:
    result = semRoutineInTemplBody(c, n, skIterator)
  of nkTemplateDef:
    result = semRoutineInTemplBody(c, n, skTemplate)
  of nkMacroDef:
    result = semRoutineInTemplBody(c, n, skMacro)
  of nkConverterDef:
    result = semRoutineInTemplBody(c, n, skConverter)
  of nkPragmaExpr:
    result.sons[0] = semTemplBody(c, n.sons[0])
  of nkPostfix:
    result.sons[1] = semTemplBody(c, n.sons[1])
  of nkPragma:
    for x in n:
      if x.kind == nkExprColonExpr:
        x.sons[1] = semTemplBody(c, x.sons[1])
  of nkBracketExpr:
    result = newNodeI(nkCall, n.info)
    result.add newIdentNode(getIdent(c.c.cache, "[]"), n.info)
    for i in 0 ..< n.len: result.add(n[i])
    let n0 = semTemplBody(c, n.sons[0])
    withBracketExpr c, n0:
      result = semTemplBodySons(c, result)
  of nkCurlyExpr:
    result = newNodeI(nkCall, n.info)
    result.add newIdentNode(getIdent(c.c.cache, "{}"), n.info)
    for i in 0 ..< n.len: result.add(n[i])
    result = semTemplBodySons(c, result)
  of nkAsgn, nkFastAsgn:
    checkSonsLen(n, 2, c.c.config)
    let a = n.sons[0]
    let b = n.sons[1]

    let k = a.kind
    case k
    of nkBracketExpr:
      result = newNodeI(nkCall, n.info)
      result.add newIdentNode(getIdent(c.c.cache, "[]="), n.info)
      for i in 0 ..< a.len: result.add(a[i])
      result.add(b)
      let a0 = semTemplBody(c, a.sons[0])
      withBracketExpr c, a0:
        result = semTemplBodySons(c, result)
    of nkCurlyExpr:
      result = newNodeI(nkCall, n.info)
      result.add newIdentNode(getIdent(c.c.cache, "{}="), n.info)
      for i in 0 ..< a.len: result.add(a[i])
      result.add(b)
      result = semTemplBodySons(c, result)
    else:
      result = semTemplBodySons(c, n)
  of nkCallKinds-{nkPostfix}:
    # do not transform runnableExamples (bug #9143)
    if not isRunnableExamples(n[0]):
      result = semTemplBodySons(c, n)
  of nkDotExpr, nkAccQuoted:
    # dotExpr is ambiguous: note that we explicitly allow 'x.TemplateParam',
    # so we use the generic code for nkDotExpr too
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil:
      # do not symchoice a quoted template parameter (bug #2390):
      if s.owner == c.owner and s.kind == skParam and
          n.kind == nkAccQuoted and n.len == 1:
        incl(s.flags, sfUsed)
        onUse(n.info, s)
        return newSymNode(s, n.info)
      elif contains(c.toBind, s.id):
        return symChoice(c.c, n, s, scClosed)
      elif contains(c.toMixin, s.name.id):
        return symChoice(c.c, n, s, scForceOpen)
      else:
        return symChoice(c.c, n, s, scOpen)
    result = semTemplBodySons(c, n)
  else:
    result = semTemplBodySons(c, n)

proc semTemplBodyDirty(c: var TemplCtx, n: PNode): PNode =
  result = n
  semIdeForTemplateOrGenericCheck(c.c.config, n, c.cursorInBody)
  case n.kind
  of nkIdent:
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil:
      if s.owner == c.owner and s.kind == skParam:
        result = newSymNode(s, n.info)
      elif contains(c.toBind, s.id):
        result = symChoice(c.c, n, s, scClosed)
  of nkBind:
    result = semTemplBodyDirty(c, n.sons[0])
  of nkBindStmt:
    result = semBindStmt(c.c, n, c.toBind)
  of nkEmpty, nkSym..nkNilLit, nkComesFrom:
    discard
  else:
    # dotExpr is ambiguous: note that we explicitly allow 'x.TemplateParam',
    # so we use the generic code for nkDotExpr too
    if n.kind == nkDotExpr or n.kind == nkAccQuoted:
      let s = qualifiedLookUp(c.c, n, {})
      if s != nil and contains(c.toBind, s.id):
        return symChoice(c.c, n, s, scClosed)
    result = n
    for i in countup(0, sonsLen(n) - 1):
      result.sons[i] = semTemplBodyDirty(c, n.sons[i])

proc semTemplateDef(c: PContext, n: PNode): PNode =
  var s: PSym
  if isTopLevel(c):
    s = semIdentVis(c, skTemplate, n.sons[0], {sfExported})
    incl(s.flags, sfGlobal)
  else:
    s = semIdentVis(c, skTemplate, n.sons[0], {})

  if s.owner != nil and sfSystemModule in s.owner.flags and
      s.name.s in ["!=", ">=", ">", "incl", "excl", "in", "notin", "isnot"]:
    incl(s.flags, sfCallsite)

  styleCheckDef(c.config, s)
  onDef(n[0].info, s)
  # check parameter list:
  #s.scope = c.currentScope
  pushOwner(c, s)
  openScope(c)
  n.sons[namePos] = newSymNode(s, n.sons[namePos].info)
  if n.sons[pragmasPos].kind != nkEmpty:
    pragma(c, s, n.sons[pragmasPos], templatePragmas)

  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty:
    n.sons[genericParamsPos] = semGenericParamList(c, n.sons[genericParamsPos])
    gp = n.sons[genericParamsPos]
  else:
    gp = newNodeI(nkGenericParams, n.info)
  # process parameters:
  var allUntyped = true
  if n.sons[paramsPos].kind != nkEmpty:
    semParamList(c, n.sons[paramsPos], gp, s)
    # a template's parameters are not gensym'ed even if that was originally the
    # case as we determine whether it's a template parameter in the template
    # body by the absence of the sfGenSym flag:
    for i in 1 .. s.typ.n.len-1:
      let param = s.typ.n.sons[i].sym
      param.flags.excl sfGenSym
      if param.typ.kind != tyExpr: allUntyped = false
    if sonsLen(gp) > 0:
      if n.sons[genericParamsPos].kind == nkEmpty:
        # we have a list of implicit type parameters:
        n.sons[genericParamsPos] = gp
    # no explicit return type? -> use tyStmt
    if n.sons[paramsPos].sons[0].kind == nkEmpty:
      # use ``stmt`` as implicit result type
      s.typ.sons[0] = newTypeS(tyStmt, c)
      s.typ.n.sons[0] = newNodeIT(nkType, n.info, s.typ.sons[0])
  else:
    s.typ = newTypeS(tyProc, c)
    # XXX why do we need tyStmt as a return type again?
    s.typ.n = newNodeI(nkFormalParams, n.info)
    rawAddSon(s.typ, newTypeS(tyStmt, c))
    addSon(s.typ.n, newNodeIT(nkType, n.info, s.typ.sons[0]))
  if allUntyped: incl(s.flags, sfAllUntyped)
  if n.sons[patternPos].kind != nkEmpty:
    n.sons[patternPos] = semPattern(c, n.sons[patternPos])
  var ctx: TemplCtx
  ctx.toBind = initIntSet()
  ctx.toMixin = initIntSet()
  ctx.toInject = initIntSet()
  ctx.c = c
  ctx.owner = s
  if sfDirty in s.flags:
    n.sons[bodyPos] = semTemplBodyDirty(ctx, n.sons[bodyPos])
  else:
    n.sons[bodyPos] = semTemplBody(ctx, n.sons[bodyPos])
  # only parameters are resolved, no type checking is performed
  semIdeForTemplateOrGeneric(c, n.sons[bodyPos], ctx.cursorInBody)
  closeScope(c)
  popOwner(c)
  s.ast = n
  result = n
  if sfCustomPragma in s.flags:
    if n.sons[bodyPos].kind != nkEmpty:
      localError(c.config, n.sons[bodyPos].info, errImplOfXNotAllowed % s.name.s)
  elif n.sons[bodyPos].kind == nkEmpty:
    localError(c.config, n.info, "implementation of '$1' expected" % s.name.s)
  var proto = searchForProc(c, c.currentScope, s)
  if proto == nil:
    addInterfaceOverloadableSymAt(c, c.currentScope, s)
  else:
    symTabReplace(c.currentScope.symbols, proto, s)
  if n.sons[patternPos].kind != nkEmpty:
    c.patterns.add(s)

proc semPatternBody(c: var TemplCtx, n: PNode): PNode =
  template templToExpand(s: untyped): untyped =
    s.kind == skTemplate and (s.typ.len == 1 or sfAllUntyped in s.flags)

  proc newParam(c: var TemplCtx, n: PNode, s: PSym): PNode =
    # the param added in the current scope is actually wrong here for
    # macros because they have a shadowed param of type 'PNimNode' (see
    # semtypes.addParamOrResult). Within the pattern we have to ensure
    # to use the param with the proper type though:
    incl(s.flags, sfUsed)
    onUse(n.info, s)
    let x = c.owner.typ.n.sons[s.position+1].sym
    assert x.name == s.name
    result = newSymNode(x, n.info)

  proc handleSym(c: var TemplCtx, n: PNode, s: PSym): PNode =
    result = n
    if s != nil:
      if s.owner == c.owner and s.kind == skParam:
        result = newParam(c, n, s)
      elif contains(c.toBind, s.id):
        result = symChoice(c.c, n, s, scClosed)
      elif templToExpand(s):
        result = semPatternBody(c, semTemplateExpr(c.c, n, s, {efNoSemCheck}))
      else:
        discard
        # we keep the ident unbound for matching instantiated symbols and
        # more flexibility

  proc expectParam(c: var TemplCtx, n: PNode): PNode =
    let s = qualifiedLookUp(c.c, n, {})
    if s != nil and s.owner == c.owner and s.kind == skParam:
      result = newParam(c, n, s)
    else:
      localError(c.c.config, n.info, "invalid expression")
      result = n

  proc stupidStmtListExpr(n: PNode): bool =
    for i in 0 .. n.len-2:
      if n[i].kind notin {nkEmpty, nkCommentStmt}: return false
    result = true

  result = n
  case n.kind
  of nkIdent:
    let s = qualifiedLookUp(c.c, n, {})
    result = handleSym(c, n, s)
  of nkBindStmt:
    result = semBindStmt(c.c, n, c.toBind)
  of nkEmpty, nkSym..nkNilLit: discard
  of nkCurlyExpr:
    # we support '(pattern){x}' to bind a subpattern to a parameter 'x';
    # '(pattern){|x}' does the same but the matches will be gathered in 'x'
    if n.len != 2:
      localError(c.c.config, n.info, "invalid expression")
    elif n.sons[1].kind == nkIdent:
      n.sons[0] = semPatternBody(c, n.sons[0])
      n.sons[1] = expectParam(c, n.sons[1])
    elif n.sons[1].kind == nkPrefix and n.sons[1].sons[0].kind == nkIdent:
      let opr = n.sons[1].sons[0]
      if opr.ident.s == "|":
        n.sons[0] = semPatternBody(c, n.sons[0])
        n.sons[1].sons[1] = expectParam(c, n.sons[1].sons[1])
      else:
        localError(c.c.config, n.info, "invalid expression")
    else:
      localError(c.c.config, n.info, "invalid expression")
  of nkStmtList, nkStmtListExpr:
    if stupidStmtListExpr(n):
      result = semPatternBody(c, n.lastSon)
    else:
      for i in countup(0, sonsLen(n) - 1):
        result.sons[i] = semPatternBody(c, n.sons[i])
  of nkCallKinds:
    let s = qualifiedLookUp(c.c, n.sons[0], {})
    if s != nil:
      if s.owner == c.owner and s.kind == skParam: discard
      elif contains(c.toBind, s.id): discard
      elif templToExpand(s):
        return semPatternBody(c, semTemplateExpr(c.c, n, s, {efNoSemCheck}))

    if n.kind == nkInfix and (let id = considerQuotedIdent(c.c, n[0]); id != nil):
      # we interpret `*` and `|` only as pattern operators if they occur in
      # infix notation, so that '`*`(a, b)' can be used for verbatim matching:
      if id.s == "*" or id.s == "**":
        result = newNodeI(nkPattern, n.info, n.len)
        result.sons[0] = newIdentNode(id, n.info)
        result.sons[1] = semPatternBody(c, n.sons[1])
        result.sons[2] = expectParam(c, n.sons[2])
        return
      elif id.s == "|":
        result = newNodeI(nkPattern, n.info, n.len)
        result.sons[0] = newIdentNode(id, n.info)
        result.sons[1] = semPatternBody(c, n.sons[1])
        result.sons[2] = semPatternBody(c, n.sons[2])
        return

    if n.kind == nkPrefix and (let id = considerQuotedIdent(c.c, n[0]); id != nil):
      if id.s == "~":
        result = newNodeI(nkPattern, n.info, n.len)
        result.sons[0] = newIdentNode(id, n.info)
        result.sons[1] = semPatternBody(c, n.sons[1])
        return

    for i in countup(0, sonsLen(n) - 1):
      result.sons[i] = semPatternBody(c, n.sons[i])
  else:
    # dotExpr is ambiguous: note that we explicitly allow 'x.TemplateParam',
    # so we use the generic code for nkDotExpr too
    case n.kind
    of nkDotExpr, nkAccQuoted:
      let s = qualifiedLookUp(c.c, n, {})
      if s != nil:
        if contains(c.toBind, s.id):
          return symChoice(c.c, n, s, scClosed)
        else:
          return newIdentNode(s.name, n.info)
    of nkPar:
      if n.len == 1: return semPatternBody(c, n.sons[0])
    else: discard
    for i in countup(0, sonsLen(n) - 1):
      result.sons[i] = semPatternBody(c, n.sons[i])

proc semPattern(c: PContext, n: PNode): PNode =
  openScope(c)
  var ctx: TemplCtx
  ctx.toBind = initIntSet()
  ctx.toMixin = initIntSet()
  ctx.toInject = initIntSet()
  ctx.c = c
  ctx.owner = getCurrOwner(c)
  result = flattenStmts(semPatternBody(ctx, n))
  if result.kind in {nkStmtList, nkStmtListExpr}:
    if result.len == 1:
      result = result.sons[0]
    elif result.len == 0:
      localError(c.config, n.info, "a pattern cannot be empty")
  closeScope(c)
