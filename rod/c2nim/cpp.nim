# Preprocessor support

const
  c2nimSymbol = "C2NIM"

proc eatNewLine(p: var TParser, n: PNode) = 
  if p.tok.xkind == pxLineComment:
    skipCom(p, n)
    if p.tok.xkind == pxNewLine: getTok(p)
  else:
    eat(p, pxNewLine)

proc parseDefineBody(p: var TParser, tmplDef: PNode): string = 
  if p.tok.xkind == pxCurlyLe or 
    (p.tok.xkind == pxSymbol and (declKeyword(p.tok.s) or stmtKeyword(p.tok.s))):
    addSon(tmplDef, statement(p))
    result = "stmt"
  elif p.tok.xkind in {pxLineComment, pxNewLine}:
    addSon(tmplDef, buildStmtList(newNodeP(nkNilLit, p)))
    result = "stmt"
  else:
    addSon(tmplDef, buildStmtList(expression(p)))
    result = "expr"

proc parseDefine(p: var TParser): PNode = 
  if p.tok.xkind == pxDirectiveParLe: 
    # a macro with parameters:
    result = newNodeP(nkTemplateDef, p)
    getTok(p)
    addSon(result, skipIdent(p))
    eat(p, pxParLe)
    var params = newNodeP(nkFormalParams, p)
    # return type; not known yet:
    addSon(params, nil)  
    var identDefs = newNodeP(nkIdentDefs, p)
    while p.tok.xkind != pxParRi: 
      addSon(identDefs, skipIdent(p))
      skipStarCom(p, nil)
      if p.tok.xkind != pxComma: break
      getTok(p)
    addSon(identDefs, newIdentNodeP("expr", p))
    addSon(identDefs, nil)
    addSon(params, identDefs)
    eat(p, pxParRi)
    
    addSon(result, nil) # no generic parameters
    addSon(result, params)
    addSon(result, nil) # no pragmas
    var kind = parseDefineBody(p, result)
    params.sons[0] = newIdentNodeP(kind, p)
    eatNewLine(p, result)
  else:
    # a macro without parameters:
    result = newNodeP(nkConstSection, p)
    while p.tok.xkind == pxDirective and p.tok.s == "define":
      getTok(p) # skip #define
      var c = newNodeP(nkConstDef, p)
      addSon(c, skipIdent(p))
      addSon(c, nil)
      skipStarCom(p, c)
      if p.tok.xkind in {pxLineComment, pxNewLine, pxEof}:
        addSon(c, newIdentNodeP("true", p))
      else:
        addSon(c, expression(p))
      addSon(result, c)
      eatNewLine(p, c)
  
proc isDir(p: TParser, dir: string): bool = 
  result = p.tok.xkind in {pxDirectiveParLe, pxDirective} and p.tok.s == dir

proc parseInclude(p: var TParser): PNode = 
  result = newNodeP(nkImportStmt, p)
  while isDir(p, "include"):
    getTok(p) # skip "include"
    if p.tok.xkind == pxStrLit:
      var file = newStrNodeP(nkStrLit, p.tok.s, p)
      addSon(result, file)
      getTok(p)
      skipStarCom(p, file)
    elif p.tok.xkind == pxLt: 
      while p.tok.xkind notin {pxEof, pxNewLine, pxLineComment}: getTok(p)
    else:
      parMessage(p, errXExpected, "string literal")
    eatNewLine(p, nil)
  if sonsLen(result) == 0: 
    # we only parsed includes that we chose to ignore:
    result = nil

proc definedExprAux(p: var TParser): PNode = 
  result = newNodeP(nkCall, p)
  addSon(result, newIdentNodeP("defined", p))
  addSon(result, skipIdent(p))

proc parseStmtList(p: var TParser): PNode = 
  result = newNodeP(nkStmtList, p)
  while true: 
    case p.tok.xkind
    of pxEof: break 
    of pxDirectiveParLe, pxDirective: 
      case p.tok.s
      of "else", "endif", "elif": break
    else: nil
    addSon(result, statement(p))
  
proc parseIfDirAux(p: var TParser, result: PNode) = 
  addSon(result.sons[0], parseStmtList(p))
  while isDir(p, "elif"): 
    var b = newNodeP(nkElifBranch, p)
    getTok(p)
    addSon(b, expression(p))
    eatNewLine(p, nil)
    addSon(b, parseStmtList(p))
    addSon(result, b)
  if isDir(p, "else"): 
    var s = newNodeP(nkElse, p)
    while p.tok.xkind notin {pxEof, pxNewLine, pxLineComment}: getTok(p)
    eatNewLine(p, nil)
    addSon(s, parseStmtList(p))
    addSon(result, s)
  if isDir(p, "endif"): 
    while p.tok.xkind notin {pxEof, pxNewLine, pxLineComment}: getTok(p)
    eatNewLine(p, nil)
  else: 
    parMessage(p, errXExpected, "#endif")
  
proc specialIf(p: TParser): bool = 
  ExpectIdent(p)
  result = p.tok.s == c2nimSymbol
  
proc chooseBranch(whenStmt: PNode, branch: int): PNode = 
  var L = sonsLen(whenStmt)
  if branch < L: 
    if L == 2 and whenStmt[1].kind == nkElse or branch == 0: 
      result = lastSon(whenStmt[branch])
    else:
      var b = whenStmt[branch]
      assert(b.kind == nkElifBranch)
      result = newNodeI(nkWhenStmt, whenStmt.info)
      for i in branch .. L-1:
        addSon(result, whenStmt[i])
  
proc skipIfdefCPlusPlus(p: var TParser): PNode =
  while p.tok.xkind != pxEof:
    if isDir(p, "endif"): 
      while p.tok.xkind notin {pxEof, pxNewLine, pxLineComment}: getTok(p)
      eatNewLine(p, nil)
      return
    getTok(p)
  parMessage(p, errXExpected, "#endif")
  
proc parseIfdefDir(p: var TParser): PNode = 
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  var special = specialIf(p)
  if p.tok.s == "__cplusplus": 
    return skipIfdefCPlusPlus(p)
  addSon(result.sons[0], definedExprAux(p))
  eatNewLine(p, nil)
  parseIfDirAux(p, result)
  if special: 
    result = chooseBranch(result, 0)

proc parseIfndefDir(p: var TParser): PNode = 
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  var special = specialIf(p)
  var e = newNodeP(nkCall, p)
  addSon(e, newIdentNodeP("not", p))
  addSon(e, definedExprAux(p))
  eatNewLine(p, nil)
  addSon(result.sons[0], e)
  parseIfDirAux(p, result)
  if special:
    result = chooseBranch(result, 1)

proc parseIfDir(p: var TParser): PNode = 
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  addSon(result.sons[0], expression(p))
  eatNewLine(p, nil)
  parseIfDirAux(p, result)

proc parseMangleDir(p: var TParser) = 
  var col = getColumn(p.lex) + 2
  getTok(p)
  if p.tok.xkind != pxStrLit: ExpectIdent(p)
  try:
    var pattern = parsePeg(
      input = p.tok.s, 
      filename = p.lex.filename, 
      line = p.lex.linenumber, 
      col = col)
    getTok(p)
    if p.tok.xkind != pxStrLit: ExpectIdent(p)
    p.options.mangleRules.add((pattern, p.tok.s))
    getTok(p)
  except EInvalidPeg:
    parMessage(p, errUser, getCurrentExceptionMsg())
  eatNewLine(p, nil)

proc parseDir(p: var TParser): PNode = 
  assert(p.tok.xkind in {pxDirective, pxDirectiveParLe})
  case p.tok.s
  of "define": result = parseDefine(p)
  of "include": result = parseInclude(p)
  of "ifdef": result = parseIfdefDir(p)
  of "ifndef": result = parseIfndefDir(p)
  of "if": result = parseIfDir(p)
  of "cdecl", "stdcall", "ref": 
    discard setOption(p.options, p.tok.s)
    getTok(p)
    eatNewLine(p, nil)
  of "dynlib", "header", "prefix", "suffix", "skip": 
    var key = p.tok.s
    getTok(p)
    if p.tok.xkind != pxStrLit: ExpectIdent(p)
    discard setOption(p.options, key, p.tok.s)
    getTok(p)
    eatNewLine(p, nil)
  of "mangle":
    parseMangleDir(p)
  else: 
    # ignore unimportant/unknown directive ("undef", "pragma", "error")
    while true:
      getTok(p)
      if p.tok.xkind in {pxEof, pxNewLine, pxLineComment}: break
    eatNewLine(p, nil)

