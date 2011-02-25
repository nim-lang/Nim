#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
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

type 
  TSemGenericFlag = enum 
    withinBind, withinTypeDesc
  TSemGenericFlags = set[TSemGenericFlag]

proc semGenericStmt(c: PContext, n: PNode, flags: TSemGenericFlags = {}): PNode
proc semGenericStmtScope(c: PContext, n: PNode, 
                         flags: TSemGenericFlags = {}): PNode = 
  openScope(c.tab)
  result = semGenericStmt(c, n, flags)
  closeScope(c.tab)

proc semGenericStmtSymbol(c: PContext, n: PNode, s: PSym): PNode = 
  incl(s.flags, sfUsed)
  case s.kind
  of skUnknown: 
    # Introduced in this pass! Leave it as an identifier.
    result = n
  of skProc, skMethod, skIterator, skConverter: 
    result = symChoice(c, n, s)
  of skTemplate: 
    result = semTemplateExpr(c, n, s, false)
  of skMacro: 
    result = semMacroExpr(c, n, s, false)
  of skGenericParam: 
    result = newSymNode(s)
  of skParam: 
    result = n
  of skType: 
    if (s.typ != nil) and (s.typ.kind != tyGenericParam): result = newSymNode(s)
    else: result = n
  else: result = newSymNode(s)
  
proc getIdentNode(n: PNode): PNode = 
  case n.kind
  of nkPostfix: result = getIdentNode(n.sons[1])
  of nkPragmaExpr, nkAccQuoted: result = getIdentNode(n.sons[0])
  of nkIdent: result = n
  else: 
    illFormedAst(n)
    result = n

#  of nkAccQuoted: 
#    s = lookUp(c, n)
#    if withinBind in flags: result = symChoice(c, n, s)
#    else: result = semGenericStmtSymbol(c, n, s)

proc semGenericStmt(c: PContext, n: PNode, flags: TSemGenericFlags = {}): PNode = 
  var 
    L: int
    a: PNode
  result = n
  if gCmd == cmdIdeTools: suggestStmt(c, n)
  case n.kind
  of nkIdent:
    var s = SymtabGet(c.Tab, n.ident)
    if s == nil:
      # no error if symbol cannot be bound, unless in ``bind`` context:
      if withinBind in flags: 
        localError(n.info, errUndeclaredIdentifier, n.ident.s)
    else:
      if withinBind in flags: result = symChoice(c, n, s)
      else: result = semGenericStmtSymbol(c, n, s)
  of nkDotExpr: 
    var s = QualifiedLookUp(c, n, {})
    if s != nil: result = semGenericStmtSymbol(c, n, s)
  of nkEmpty, nkSym..nkNilLit: 
    nil
  of nkBind: 
    result = semGenericStmt(c, n.sons[0], {withinBind})
  of nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkCommand, nkCallStrLit: 
    # check if it is an expression macro:
    checkMinSonsLen(n, 1)
    var s = qualifiedLookup(c, n.sons[0], {})
    if s != nil: 
      incl(s.flags, sfUsed)
      case s.kind
      of skMacro: 
        return semMacroExpr(c, n, s, false)
      of skTemplate: 
        return semTemplateExpr(c, n, s, false)
      of skUnknown, skParam: 
        # Leave it as an identifier.
      of skProc, skMethod, skIterator, skConverter: 
        n.sons[0] = symChoice(c, n.sons[0], s)
      of skGenericParam: 
        n.sons[0] = newSymNode(s)
      of skType: 
        # bad hack for generics:
        if (s.typ != nil) and (s.typ.kind != tyGenericParam): 
          n.sons[0] = newSymNode(s)
      else: n.sons[0] = newSymNode(s)
    for i in countup(1, sonsLen(n) - 1): 
      n.sons[i] = semGenericStmt(c, n.sons[i], flags)
  of nkMacroStmt: 
    result = semMacroStmt(c, n, false)
  of nkIfStmt: 
    for i in countup(0, sonsLen(n)-1): 
      n.sons[i] = semGenericStmtScope(c, n.sons[i])
  of nkWhileStmt: 
    openScope(c.tab)
    for i in countup(0, sonsLen(n)-1): n.sons[i] = semGenericStmt(c, n.sons[i])
    closeScope(c.tab)
  of nkCaseStmt: 
    openScope(c.tab)
    n.sons[0] = semGenericStmt(c, n.sons[0])
    for i in countup(1, sonsLen(n)-1): 
      a = n.sons[i]
      checkMinSonsLen(a, 1)
      L = sonsLen(a)
      for j in countup(0, L - 2): a.sons[j] = semGenericStmt(c, a.sons[j])
      a.sons[L - 1] = semGenericStmtScope(c, a.sons[L - 1])
    closeScope(c.tab)
  of nkForStmt: 
    L = sonsLen(n)
    openScope(c.tab)
    n.sons[L - 2] = semGenericStmt(c, n.sons[L - 2])
    for i in countup(0, L - 3): addDecl(c, newSymS(skUnknown, n.sons[i], c))
    n.sons[L - 1] = semGenericStmt(c, n.sons[L - 1])
    closeScope(c.tab)
  of nkBlockStmt, nkBlockExpr, nkBlockType: 
    checkSonsLen(n, 2)
    openScope(c.tab)
    if n.sons[0].kind != nkEmpty: addDecl(c, newSymS(skUnknown, n.sons[0], c))
    n.sons[1] = semGenericStmt(c, n.sons[1])
    closeScope(c.tab)
  of nkTryStmt: 
    checkMinSonsLen(n, 2)
    n.sons[0] = semGenericStmtScope(c, n.sons[0])
    for i in countup(1, sonsLen(n) - 1): 
      a = n.sons[i]
      checkMinSonsLen(a, 1)
      L = sonsLen(a)
      for j in countup(0, L - 2): 
        a.sons[j] = semGenericStmt(c, a.sons[j], {withinTypeDesc})
      a.sons[L - 1] = semGenericStmtScope(c, a.sons[L - 1])
  of nkVarSection: 
    for i in countup(0, sonsLen(n) - 1): 
      a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkIdentDefs) and (a.kind != nkVarTuple): IllFormedAst(a)
      checkMinSonsLen(a, 3)
      L = sonsLen(a)
      a.sons[L - 2] = semGenericStmt(c, a.sons[L - 2], {withinTypeDesc})
      a.sons[L - 1] = semGenericStmt(c, a.sons[L - 1])
      for j in countup(0, L - 3): 
        addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[j]), c))
  of nkGenericParams: 
    for i in countup(0, sonsLen(n) - 1): 
      a = n.sons[i]
      if (a.kind != nkIdentDefs): IllFormedAst(a)
      checkMinSonsLen(a, 3)
      L = sonsLen(a)
      a.sons[L - 2] = semGenericStmt(c, a.sons[L - 2], {withinTypeDesc}) 
      # do not perform symbol lookup for default expressions 
      for j in countup(0, L - 3): 
        addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[j]), c))
  of nkConstSection: 
    for i in countup(0, sonsLen(n) - 1): 
      a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkConstDef): IllFormedAst(a)
      checkSonsLen(a, 3)
      addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[0]), c))
      a.sons[1] = semGenericStmt(c, a.sons[1], {withinTypeDesc})
      a.sons[2] = semGenericStmt(c, a.sons[2])
  of nkTypeSection: 
    for i in countup(0, sonsLen(n) - 1): 
      a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkTypeDef): IllFormedAst(a)
      checkSonsLen(a, 3)
      addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[0]), c))
    for i in countup(0, sonsLen(n) - 1): 
      a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if (a.kind != nkTypeDef): IllFormedAst(a)
      checkSonsLen(a, 3)
      if a.sons[1].kind != nkEmpty: 
        openScope(c.tab)
        a.sons[1] = semGenericStmt(c, a.sons[1])
        a.sons[2] = semGenericStmt(c, a.sons[2], {withinTypeDesc})
        closeScope(c.tab)
      else: 
        a.sons[2] = semGenericStmt(c, a.sons[2], {withinTypeDesc})
  of nkEnumTy: 
    checkMinSonsLen(n, 1)
    if n.sons[0].kind != nkEmpty: 
      n.sons[0] = semGenericStmt(c, n.sons[0], {withinTypeDesc})
    for i in countup(1, sonsLen(n) - 1): 
      case n.sons[i].kind
      of nkEnumFieldDef: a = n.sons[i].sons[0]
      of nkIdent: a = n.sons[i]
      else: illFormedAst(n)
      addDeclAt(c, newSymS(skUnknown, getIdentNode(a.sons[i]), c), c.tab.tos-1)
  of nkObjectTy, nkTupleTy: 
    nil
  of nkFormalParams: 
    checkMinSonsLen(n, 1)
    if n.sons[0].kind != nkEmpty: 
      n.sons[0] = semGenericStmt(c, n.sons[0], {withinTypeDesc})
    for i in countup(1, sonsLen(n) - 1): 
      a = n.sons[i]
      if (a.kind != nkIdentDefs): IllFormedAst(a)
      checkMinSonsLen(a, 3)
      L = sonsLen(a)
      a.sons[L - 1] = semGenericStmt(c, a.sons[L - 2], {withinTypeDesc})
      a.sons[L - 1] = semGenericStmt(c, a.sons[L - 1])
      for j in countup(0, L - 3): 
        addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[j]), c))
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkIteratorDef, nkLambda: 
    checkSonsLen(n, codePos + 1)
    addDecl(c, newSymS(skUnknown, getIdentNode(n.sons[0]), c))
    openScope(c.tab)
    n.sons[genericParamsPos] = semGenericStmt(c, n.sons[genericParamsPos])
    if n.sons[paramsPos].kind != nkEmpty: 
      if n.sons[paramsPos].sons[0].kind != nkEmpty: 
        addDecl(c, newSym(skUnknown, getIdent("result"), nil))
      n.sons[paramsPos] = semGenericStmt(c, n.sons[paramsPos])
    n.sons[pragmasPos] = semGenericStmt(c, n.sons[pragmasPos])
    n.sons[codePos] = semGenericStmtScope(c, n.sons[codePos])
    closeScope(c.tab)
  else: 
    for i in countup(0, sonsLen(n) - 1): 
      result.sons[i] = semGenericStmt(c, n.sons[i], flags)
  
