#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from sem.nim

proc isExpr(n: PNode): bool = 
  # returns true if ``n`` looks like an expression
  case n.kind
  of nkIdent..nkNilLit: 
    result = true
  of nkCall..pred(nkAsgn): 
    for i in countup(0, sonsLen(n) - 1): 
      if not isExpr(n.sons[i]): 
        return false
    result = true
  else: result = false
  
proc isTypeDesc(n: PNode): bool = 
  # returns true if ``n`` looks like a type desc
  case n.kind
  of nkIdent, nkSym, nkType: 
    result = true
  of nkDotExpr, nkBracketExpr: 
    for i in countup(0, sonsLen(n) - 1): 
      if not isTypeDesc(n.sons[i]): 
        return false
    result = true
  of nkTypeOfExpr..nkEnumTy: 
    result = true
  else: result = false
  
var evalTemplateCounter: int = 0
  # to prevend endless recursion in templates instantation

proc evalTemplateArgs(c: PContext, n: PNode, s: PSym): PNode = 
  var 
    f, a: int
    arg: PNode
  f = sonsLen(s.typ) 
  # if the template has zero arguments, it can be called without ``()``
  # `n` is then a nkSym or something similar
  case n.kind
  of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit: 
    a = sonsLen(n)
  else: a = 0
  if a > f: LocalError(n.info, errWrongNumberOfArguments)
  result = copyNode(n)
  for i in countup(1, f - 1): 
    if i < a: arg = n.sons[i]
    else: arg = copyTree(s.typ.n.sons[i].sym.ast)
    if arg == nil or arg.kind == nkEmpty: 
      LocalError(n.info, errWrongNumberOfArguments)
    addSon(result, arg)

proc evalTemplate*(c: PContext, n: PNode, sym: PSym): PNode = 
  var args: PNode
  inc(evalTemplateCounter)
  if evalTemplateCounter <= 100: 
    # replace each param by the corresponding node:
    args = evalTemplateArgs(c, n, sym)
    result = evalTemplateAux(sym.getBody, args, sym)
    dec(evalTemplateCounter)
  else:
    GlobalError(n.info, errTemplateInstantiationTooNested)
    result = n

proc symChoice(c: PContext, n: PNode, s: PSym): PNode = 
  var 
    a: PSym
    o: TOverloadIter
    i: int
  i = 0
  a = initOverloadIter(o, c, n)
  while a != nil: 
    a = nextOverloadIter(o, c, n)
    inc(i)
  if i <= 1: 
    result = newSymNode(s)
    result.info = n.info
    markUsed(n, s)
  else: 
    # semantic checking requires a type; ``fitNode`` deals with it
    # appropriately
    result = newNodeIT(nkSymChoice, n.info, newTypeS(tyNone, c))
    a = initOverloadIter(o, c, n)
    while a != nil:
      incl(a.flags, sfUsed)
      addSon(result, newSymNode(a))
      a = nextOverloadIter(o, c, n)

proc semBindStmt(c: PContext, n: PNode, toBind: var TIntSet): PNode =
  for i in 0 .. < n.len:
    var a = n.sons[i]
    if a.kind == nkIdent:
      var s = SymtabGet(c.Tab, a.ident)
      if s != nil:
        toBind.incl(s.name.id)
      else:
        localError(a.info, errUndeclaredIdentifier, a.ident.s)
    else: 
      illFormedAst(a)
  result = newNodeI(nkEmpty, n.info)

proc resolveTemplateParams(c: PContext, n: PNode, withinBind: bool, 
                           toBind: var TIntSet): PNode = 
  var s: PSym
  case n.kind
  of nkIdent: 
    if not withinBind and not Contains(toBind, n.ident.id): 
      s = SymTabLocalGet(c.Tab, n.ident)
      if s != nil: 
        result = newSymNode(s)
        result.info = n.info
      else: 
        result = n
    else: 
      Incl(toBind, n.ident.id)
      result = symChoice(c, n, lookup(c, n))
  of nkEmpty, nkSym..nkNilLit:         # atom
    result = n
  of nkBind: 
    result = resolveTemplateParams(c, n.sons[0], true, toBind)
  of nkBindStmt:
    result = semBindStmt(c, n, toBind)
  else: 
    result = n
    for i in countup(0, sonsLen(n) - 1): 
      result.sons[i] = resolveTemplateParams(c, n.sons[i], withinBind, toBind)
  
proc transformToExpr(n: PNode): PNode = 
  var realStmt: int
  result = n
  case n.kind
  of nkStmtList: 
    realStmt = - 1
    for i in countup(0, sonsLen(n) - 1): 
      case n.sons[i].kind
      of nkCommentStmt, nkEmpty, nkNilLit: 
        nil
      else: 
        if realStmt == - 1: realStmt = i
        else: realStmt = - 2
    if realStmt >= 0: result = transformToExpr(n.sons[realStmt])
    else: n.kind = nkStmtListExpr
  of nkBlockStmt: 
    n.kind = nkBlockExpr
    #nkIfStmt: n.kind := nkIfExpr; // this is not correct!
  else: 
    nil

proc semTemplateDef(c: PContext, n: PNode): PNode = 
  var s: PSym
  if c.p.owner.kind == skModule: 
    s = semIdentVis(c, skTemplate, n.sons[0], {sfExported})
    incl(s.flags, sfGlobal)
  else:
    s = semIdentVis(c, skTemplate, n.sons[0], {})
  # check parameter list:
  pushOwner(s)
  openScope(c.tab)
  n.sons[namePos] = newSymNode(s)
  if n.sons[pragmasPos].kind != nkEmpty:
    pragma(c, s, n.sons[pragmasPos], templatePragmas)
  # check that no generic parameters exist:
  if n.sons[genericParamsPos].kind != nkEmpty: 
    LocalError(n.info, errNoGenericParamsAllowedForX, "template")
  if n.sons[paramsPos].kind == nkEmpty: 
    # use ``stmt`` as implicit result type
    s.typ = newTypeS(tyProc, c)
    s.typ.n = newNodeI(nkFormalParams, n.info)
    addSon(s.typ, newTypeS(tyStmt, c))
    addSon(s.typ.n, newNodeIT(nkType, n.info, s.typ.sons[0]))
  else: 
    semParamList(c, n.sons[ParamsPos], nil, s)
    if n.sons[paramsPos].sons[0].kind == nkEmpty: 
      # use ``stmt`` as implicit result type
      s.typ.sons[0] = newTypeS(tyStmt, c)
      s.typ.n.sons[0] = newNodeIT(nkType, n.info, s.typ.sons[0])
  var toBind = initIntSet()
  n.sons[bodyPos] = resolveTemplateParams(c, n.sons[bodyPos], false, toBind)
  if s.typ.sons[0].kind notin {tyStmt, tyTypeDesc}:
    n.sons[bodyPos] = transformToExpr(n.sons[bodyPos]) 
    # only parameters are resolved, no type checking is performed
  closeScope(c.tab)
  popOwner()
  s.ast = n
  result = n
  if n.sons[bodyPos].kind == nkEmpty: 
    LocalError(n.info, errImplOfXexpected, s.name.s)
  let curScope = c.tab.tos - 1
  var proto = SearchForProc(c, s, curScope)
  if proto == nil:
    addInterfaceOverloadableSymAt(c, s, curScope)
  else:
    SymTabReplace(c.tab.stack[curScope], proto, s)

