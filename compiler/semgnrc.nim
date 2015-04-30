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

proc getIdentNode(n: PNode): PNode =
  case n.kind
  of nkPostfix: result = getIdentNode(n.sons[1])
  of nkPragmaExpr: result = getIdentNode(n.sons[0])
  of nkIdent, nkAccQuoted, nkSym: result = n
  else:
    illFormedAst(n)
    result = n

type
  GenericCtx = object
    toMixin: IntSet
    cursorInBody: bool # only for nimsuggest

type
  TSemGenericFlag = enum
    withinBind, withinTypeDesc, withinMixin
  TSemGenericFlags = set[TSemGenericFlag]

proc semGenericStmt(c: PContext, n: PNode,
                    flags: TSemGenericFlags, ctx: var GenericCtx): PNode

proc semGenericStmtScope(c: PContext, n: PNode, 
                         flags: TSemGenericFlags,
                         ctx: var GenericCtx): PNode = 
  openScope(c)
  result = semGenericStmt(c, n, flags, ctx)
  closeScope(c)

template macroToExpand(s: expr): expr =
  s.kind in {skMacro, skTemplate} and (s.typ.len == 1 or sfImmediate in s.flags)

proc semGenericStmtSymbol(c: PContext, n: PNode, s: PSym,
                          ctx: var GenericCtx): PNode =
  semIdeForTemplateOrGenericCheck(n, ctx.cursorInBody)
  incl(s.flags, sfUsed)
  case s.kind
  of skUnknown:
    # Introduced in this pass! Leave it as an identifier.
    result = n
  of skProc, skMethod, skIterators, skConverter:
    result = symChoice(c, n, s, scOpen)
  of skTemplate:
    if macroToExpand(s):
      styleCheckUse(n.info, s)
      result = semTemplateExpr(c, n, s, {efNoSemCheck})
      result = semGenericStmt(c, result, {}, ctx)
    else:
      result = symChoice(c, n, s, scOpen)
  of skMacro:
    if macroToExpand(s):
      styleCheckUse(n.info, s)
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
    styleCheckUse(n.info, s)
  of skParam:
    result = n
    styleCheckUse(n.info, s)
  of skType: 
    if (s.typ != nil) and
       (s.typ.flags * {tfGenericTypeParam, tfImplicitTypeParam} == {}):
      result = newSymNodeTypeDesc(s, n.info)
    else: 
      result = n
    styleCheckUse(n.info, s)
  else:
    result = newSymNode(s, n.info)
    styleCheckUse(n.info, s)

proc lookup(c: PContext, n: PNode, flags: TSemGenericFlags, 
            ctx: var GenericCtx): PNode =
  result = n
  let ident = considerQuotedIdent(n)
  var s = searchInScopes(c, ident).skipAlias(n)
  if s == nil:
    if ident.id notin ctx.toMixin and withinMixin notin flags:
      localError(n.info, errUndeclaredIdentifier, ident.s)
  else:
    if withinBind in flags:
      result = symChoice(c, n, s, scClosed)
    elif s.name.id in ctx.toMixin:
      result = symChoice(c, n, s, scForceOpen)
    else:
      result = semGenericStmtSymbol(c, n, s, ctx)
  # else: leave as nkIdent

proc newDot(n, b: PNode): PNode =
  result = newNodeI(nkDotExpr, n.info)
  result.add(n.sons[0])
  result.add(b)

proc fuzzyLookup(c: PContext, n: PNode, flags: TSemGenericFlags, 
                 ctx: var GenericCtx; isMacro: var bool): PNode =
  assert n.kind == nkDotExpr
  semIdeForTemplateOrGenericCheck(n, ctx.cursorInBody)

  let luf = if withinMixin notin flags: {checkUndeclared} else: {}
  
  var s = qualifiedLookUp(c, n, luf)
  if s != nil:
    result = semGenericStmtSymbol(c, n, s, ctx)
  else:
    n.sons[0] = semGenericStmt(c, n.sons[0], flags, ctx)
    result = n
    let n = n[1]
    let ident = considerQuotedIdent(n)
    var s = searchInScopes(c, ident).skipAlias(n)
    if s != nil and s.kind in routineKinds:
      isMacro = s.kind in {skTemplate, skMacro}
      if withinBind in flags:
        result = newDot(result, symChoice(c, n, s, scClosed))
      elif s.name.id in ctx.toMixin:
        result = newDot(result, symChoice(c, n, s, scForceOpen))
      else:
        let sym = semGenericStmtSymbol(c, n, s, ctx)
        if sym.kind == nkSym:
          result = newDot(result, symChoice(c, n, s, scForceOpen))
        else:
          result = newDot(result, sym)

proc addTempDecl(c: PContext; n: PNode; kind: TSymKind) =
  let s = newSymS(skUnknown, getIdentNode(n), c)
  addPrelimDecl(c, s)
  styleCheckDef(n.info, s, kind)

proc semGenericStmt(c: PContext, n: PNode, 
                    flags: TSemGenericFlags, ctx: var GenericCtx): PNode =
  result = n
  #if gCmd == cmdIdeTools: suggestStmt(c, n)
  semIdeForTemplateOrGenericCheck(n, ctx.cursorInBody)

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
  of nkEmpty, nkSym..nkNilLit:
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
    checkMinSonsLen(n, 1)
    let fn = n.sons[0]
    var s = qualifiedLookUp(c, fn, {})
    if s == nil and withinMixin notin flags and
        fn.kind in {nkIdent, nkAccQuoted} and 
        considerQuotedIdent(fn).id notin ctx.toMixin:
      localError(n.info, errUndeclaredIdentifier, fn.renderTree)
    
    var first = 0
    var mixinContext = false
    if s != nil:
      incl(s.flags, sfUsed)
      mixinContext = s.magic in {mDefined, mDefinedInScope, mCompiles}
      let scOption = if s.name.id in ctx.toMixin: scForceOpen else: scOpen
      case s.kind
      of skMacro:
        if macroToExpand(s):
          styleCheckUse(fn.info, s)
          result = semMacroExpr(c, n, n, s, {efNoSemCheck})
          result = semGenericStmt(c, result, {}, ctx)
        else:
          n.sons[0] = symChoice(c, fn, s, scOption)
          result = n
        mixinContext = true
      of skTemplate:
        if macroToExpand(s):
          styleCheckUse(fn.info, s)
          result = semTemplateExpr(c, n, s, {efNoSemCheck})
          result = semGenericStmt(c, result, {}, ctx)
        else:
          n.sons[0] = symChoice(c, fn, s, scOption)
          result = n
        # BUGFIX: we must not return here, we need to do first phase of
        # symbol lookup. Also since templates and macros can do scope injections
        # we need to put the ``c`` in ``t(c)`` in a mixin context to prevent
        # the famous "undeclared identifier: it" bug:
        mixinContext = true
      of skUnknown, skParam: 
        # Leave it as an identifier.
        discard
      of skProc, skMethod, skIterators, skConverter:
        result.sons[0] = symChoice(c, fn, s, scOption)
        first = 1
      of skGenericParam:
        result.sons[0] = newSymNodeTypeDesc(s, fn.info)
        styleCheckUse(fn.info, s)
        first = 1
      of skType: 
        # bad hack for generics:
        if (s.typ != nil) and (s.typ.kind != tyGenericParam): 
          result.sons[0] = newSymNodeTypeDesc(s, fn.info)
          styleCheckUse(fn.info, s)
          first = 1
      else:
        result.sons[0] = newSymNode(s, fn.info)
        styleCheckUse(fn.info, s)
        first = 1
    elif fn.kind == nkDotExpr:
      result.sons[0] = fuzzyLookup(c, fn, flags, ctx, mixinContext)
      first = 1
    # Consider 'when declared(globalsSlot): ThreadVarSetValue(globalsSlot, ...)'
    # in threads.nim: the subtle preprocessing here binds 'globalsSlot' which 
    # is not exported and yet the generic 'threadProcWrapper' works correctly.
    let flags = if mixinContext: flags+{withinMixin} else: flags
    for i in countup(first, sonsLen(result) - 1):
      result.sons[i] = semGenericStmt(c, result.sons[i], flags, ctx)
  of nkIfStmt: 
    for i in countup(0, sonsLen(n)-1): 
      n.sons[i] = semGenericStmtScope(c, n.sons[i], flags, ctx)
  of nkWhenStmt:
    for i in countup(0, sonsLen(n)-1):
      n.sons[i] = semGenericStmt(c, n.sons[i], flags+{withinMixin}, ctx)
  of nkWhileStmt: 
    openScope(c)
    for i in countup(0, sonsLen(n)-1): 
      n.sons[i] = semGenericStmt(c, n.sons[i], flags, ctx)
    closeScope(c)
  of nkCaseStmt: 
    openScope(c)
    n.sons[0] = semGenericStmt(c, n.sons[0], flags, ctx)
    for i in countup(1, sonsLen(n)-1): 
      var a = n.sons[i]
      checkMinSonsLen(a, 1)
      var L = sonsLen(a)
      for j in countup(0, L-2): 
        a.sons[j] = semGenericStmt(c, a.sons[j], flags, ctx)
      a.sons[L - 1] = semGenericStmtScope(c, a.sons[L-1], flags, ctx)
    closeScope(c)
  of nkForStmt, nkParForStmt: 
    var L = sonsLen(n)
    openScope(c)
    n.sons[L - 2] = semGenericStmt(c, n.sons[L-2], flags, ctx)
    for i in countup(0, L - 3):
      addTempDecl(c, n.sons[i], skForVar)
    n.sons[L - 1] = semGenericStmt(c, n.sons[L-1], flags, ctx)
    closeScope(c)
  of nkBlockStmt, nkBlockExpr, nkBlockType: 
    checkSonsLen(n, 2)
    openScope(c)
    if n.sons[0].kind != nkEmpty: 
      addTempDecl(c, n.sons[0], skLabel)
    n.sons[1] = semGenericStmt(c, n.sons[1], flags, ctx)
    closeScope(c)
  of nkTryStmt: 
    checkMinSonsLen(n, 2)
    n.sons[0] = semGenericStmtScope(c, n.sons[0], flags, ctx)
    for i in countup(1, sonsLen(n)-1): 
      var a = n.sons[i]
      checkMinSonsLen(a, 1)
      var L = sonsLen(a)
      for j in countup(0, L-2): 
        a.sons[j] = semGenericStmt(c, a.sons[j], flags+{withinTypeDesc}, ctx)
      a.sons[L-1] = semGenericStmtScope(c, a.sons[L-1], flags, ctx)
  of nkVarSection, nkLetSection: 
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkIdentDefs) and (a.kind != nkVarTuple): illFormedAst(a)
      checkMinSonsLen(a, 3)
      var L = sonsLen(a)
      a.sons[L-2] = semGenericStmt(c, a.sons[L-2], flags+{withinTypeDesc}, ctx)
      a.sons[L-1] = semGenericStmt(c, a.sons[L-1], flags, ctx)
      for j in countup(0, L-3):
        addTempDecl(c, getIdentNode(a.sons[j]), skVar)
  of nkGenericParams: 
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if (a.kind != nkIdentDefs): illFormedAst(a)
      checkMinSonsLen(a, 3)
      var L = sonsLen(a)
      a.sons[L-2] = semGenericStmt(c, a.sons[L-2], flags+{withinTypeDesc}, ctx) 
      # do not perform symbol lookup for default expressions 
      for j in countup(0, L-3): 
        addTempDecl(c, getIdentNode(a.sons[j]), skType)
  of nkConstSection: 
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkConstDef): illFormedAst(a)
      checkSonsLen(a, 3)
      addTempDecl(c, getIdentNode(a.sons[0]), skConst)
      a.sons[1] = semGenericStmt(c, a.sons[1], flags+{withinTypeDesc}, ctx)
      a.sons[2] = semGenericStmt(c, a.sons[2], flags, ctx)
  of nkTypeSection:
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkTypeDef): illFormedAst(a)
      checkSonsLen(a, 3)
      addTempDecl(c, getIdentNode(a.sons[0]), skType)
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkTypeDef): illFormedAst(a)
      checkSonsLen(a, 3)
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
      for i in countup(1, sonsLen(n) - 1): 
        var a: PNode
        case n.sons[i].kind
        of nkEnumFieldDef: a = n.sons[i].sons[0]
        of nkIdent: a = n.sons[i]
        else: illFormedAst(n)
        addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[i]), c))
  of nkObjectTy, nkTupleTy, nkTupleClassTy:
    discard
  of nkFormalParams:
    checkMinSonsLen(n, 1)
    if n.sons[0].kind != nkEmpty: 
      n.sons[0] = semGenericStmt(c, n.sons[0], flags+{withinTypeDesc}, ctx)
    for i in countup(1, sonsLen(n) - 1): 
      var a = n.sons[i]
      if (a.kind != nkIdentDefs): illFormedAst(a)
      checkMinSonsLen(a, 3)
      var L = sonsLen(a)
      a.sons[L-2] = semGenericStmt(c, a.sons[L-2], flags+{withinTypeDesc}, ctx)
      a.sons[L-1] = semGenericStmt(c, a.sons[L-1], flags, ctx)
      for j in countup(0, L-3): 
        addTempDecl(c, getIdentNode(a.sons[j]), skParam)
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkIteratorDef, nkLambdaKinds: 
    checkSonsLen(n, bodyPos + 1)
    if n.sons[namePos].kind != nkEmpty:
      addTempDecl(c, getIdentNode(n.sons[0]), skProc)
    openScope(c)
    n.sons[genericParamsPos] = semGenericStmt(c, n.sons[genericParamsPos], 
                                              flags, ctx)
    if n.sons[paramsPos].kind != nkEmpty: 
      if n.sons[paramsPos].sons[0].kind != nkEmpty:
        addPrelimDecl(c, newSym(skUnknown, getIdent("result"), nil, n.info))
      n.sons[paramsPos] = semGenericStmt(c, n.sons[paramsPos], flags, ctx)
    n.sons[pragmasPos] = semGenericStmt(c, n.sons[pragmasPos], flags, ctx)
    var body: PNode
    if n.sons[namePos].kind == nkSym: body = n.sons[namePos].sym.getBody
    else: body = n.sons[bodyPos]
    n.sons[bodyPos] = semGenericStmtScope(c, body, flags, ctx)
    closeScope(c)
  of nkPragma, nkPragmaExpr: discard
  of nkExprColonExpr, nkExprEqExpr:
    checkMinSonsLen(n, 2)
    result.sons[1] = semGenericStmt(c, n.sons[1], flags, ctx)
  else:
    for i in countup(0, sonsLen(n) - 1): 
      result.sons[i] = semGenericStmt(c, n.sons[i], flags, ctx)

proc semGenericStmt(c: PContext, n: PNode): PNode =
  var ctx: GenericCtx
  ctx.toMixin = initIntset()
  result = semGenericStmt(c, n, {}, ctx)
  semIdeForTemplateOrGeneric(c, result, ctx.cursorInBody)
