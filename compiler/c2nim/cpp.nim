#
#
#      c2nim - C to Nimrod source converter
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Preprocessor support

const
  c2nimSymbol = "C2NIM"

proc eatNewLine(p: var TParser, n: PNode) = 
  if p.tok.xkind == pxLineComment:
    skipCom(p, n)
    if p.tok.xkind == pxNewLine: getTok(p)
  elif p.tok.xkind == pxNewLine: 
    eat(p, pxNewLine)
  
proc skipLine(p: var TParser) = 
  while p.tok.xkind notin {pxEof, pxNewLine, pxLineComment}: getTok(p)
  eatNewLine(p, nil)

proc parseDefineBody(p: var TParser, tmplDef: PNode): string = 
  if p.tok.xkind == pxCurlyLe or 
    (p.tok.xkind == pxSymbol and (
        declKeyword(p, p.tok.s) or stmtKeyword(p.tok.s))):
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
    addSon(result, skipIdentExport(p))
    addSon(result, ast.emptyNode)
    eat(p, pxParLe)
    var params = newNodeP(nkFormalParams, p)
    # return type; not known yet:
    addSon(params, ast.emptyNode)
    if p.tok.xkind != pxParRi:
      var identDefs = newNodeP(nkIdentDefs, p)
      while p.tok.xkind != pxParRi: 
        addSon(identDefs, skipIdent(p))
        skipStarCom(p, nil)
        if p.tok.xkind != pxComma: break
        getTok(p)
      addSon(identDefs, newIdentNodeP("expr", p))
      addSon(identDefs, ast.emptyNode)
      addSon(params, identDefs)
    eat(p, pxParRi)
    
    addSon(result, ast.emptyNode) # no generic parameters
    addSon(result, params)
    addSon(result, ast.emptyNode) # no pragmas
    addSon(result, ast.emptyNode)
    var kind = parseDefineBody(p, result)
    params.sons[0] = newIdentNodeP(kind, p)
    eatNewLine(p, result)
  else:
    # a macro without parameters:
    result = newNodeP(nkConstSection, p)
    while p.tok.xkind == pxDirective and p.tok.s == "define":
      getTok(p) # skip #define
      var c = newNodeP(nkConstDef, p)
      addSon(c, skipIdentExport(p))
      addSon(c, ast.emptyNode)
      skipStarCom(p, c)
      if p.tok.xkind in {pxLineComment, pxNewLine, pxEof}:
        addSon(c, newIdentNodeP("true", p))
      else:
        addSon(c, expression(p))
      addSon(result, c)
      eatNewLine(p, c)
  assert result != nil
  
proc parseDefBody(p: var TParser, m: var TMacro, params: seq[string]) =
  m.body = @[]
  # A little hack: We safe the context, so that every following token will be 
  # put into a newly allocated TToken object. Thus we can just save a
  # reference to the token in the macro's body.
  saveContext(p)
  while p.tok.xkind notin {pxEof, pxNewLine, pxLineComment}: 
    case p.tok.xkind 
    of pxSymbol:
      # is it a parameter reference?
      var tok = p.tok
      for i in 0..high(params):
        if params[i] == p.tok.s: 
          new(tok)
          tok.xkind = pxMacroParam
          tok.iNumber = i
          break
      m.body.add(tok)
    of pxDirConc: 
      # just ignore this token: this implements token merging correctly
      nil
    else:
      m.body.add(p.tok)
    # we do not want macro expansion here:
    rawGetTok(p)
  eatNewLine(p, nil)
  closeContext(p) 
  # newline token might be overwritten, but this is not
  # part of the macro body, so it is safe.
  
proc parseDef(p: var TParser, m: var TMacro) = 
  var hasParams = p.tok.xkind == pxDirectiveParLe
  getTok(p)
  expectIdent(p)
  m.name = p.tok.s
  getTok(p)
  var params: seq[string] = @[]
  # parse parameters:
  if hasParams:
    eat(p, pxParLe)
    while p.tok.xkind != pxParRi: 
      expectIdent(p)
      params.add(p.tok.s)
      getTok(p)
      skipStarCom(p, nil)
      if p.tok.xkind != pxComma: break
      getTok(p)
    eat(p, pxParRi)
  m.params = params.len
  parseDefBody(p, m, params)
  
proc isDir(p: TParser, dir: string): bool = 
  result = p.tok.xkind in {pxDirectiveParLe, pxDirective} and p.tok.s == dir

proc parseInclude(p: var TParser): PNode = 
  result = newNodeP(nkImportStmt, p)
  while isDir(p, "include"):
    getTok(p) # skip "include"
    if p.tok.xkind == pxStrLit and pfSkipInclude notin p.options.flags:
      var file = newStrNodeP(nkStrLit, changeFileExt(p.tok.s, ""), p)
      addSon(result, file)
      getTok(p)
      skipStarCom(p, file)
      eatNewLine(p, nil)
    else:
      skipLine(p)
  if sonsLen(result) == 0: 
    # we only parsed includes that we chose to ignore:
    result = ast.emptyNode

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
  
proc eatEndif(p: var TParser) =
  if isDir(p, "endif"): 
    skipLine(p)
  else: 
    parMessage(p, errXExpected, "#endif")
  
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
    skipLine(p)
    addSon(s, parseStmtList(p))
    addSon(result, s)
  eatEndif(p)
    
proc skipUntilEndif(p: var TParser) =
  var nested = 1
  while p.tok.xkind != pxEof:
    if isDir(p, "ifdef") or isDir(p, "ifndef") or isDir(p, "if"): 
      inc(nested)
    elif isDir(p, "endif"): 
      dec(nested)
      if nested <= 0:
        skipLine(p)
        return
    getTok(p)
  parMessage(p, errXExpected, "#endif")
  
type
  TEndifMarker = enum
    emElif, emElse, emEndif
  
proc skipUntilElifElseEndif(p: var TParser): TEndifMarker =
  var nested = 1
  while p.tok.xkind != pxEof:
    if isDir(p, "ifdef") or isDir(p, "ifndef") or isDir(p, "if"): 
      inc(nested)
    elif isDir(p, "elif") and nested <= 1:
      return emElif
    elif isDir(p, "else") and nested <= 1:
      return emElse
    elif isDir(p, "endif"): 
      dec(nested)
      if nested <= 0:
        return emEndif
    getTok(p)
  parMessage(p, errXExpected, "#endif")
  
proc parseIfdef(p: var TParser): PNode = 
  getTok(p) # skip #ifdef
  ExpectIdent(p)
  case p.tok.s
  of "__cplusplus":
    skipUntilEndif(p)
    result = ast.emptyNode
  of c2nimSymbol:
    skipLine(p)
    result = parseStmtList(p)
    skipUntilEndif(p)
  else:
    result = newNodeP(nkWhenStmt, p)
    addSon(result, newNodeP(nkElifBranch, p))
    addSon(result.sons[0], definedExprAux(p))
    eatNewLine(p, nil)
    parseIfDirAux(p, result)
  
proc parseIfndef(p: var TParser): PNode = 
  result = ast.emptyNode
  getTok(p) # skip #ifndef
  ExpectIdent(p)
  if p.tok.s == c2nimSymbol: 
    skipLine(p)
    case skipUntilElifElseEndif(p)
    of emElif:
      result = newNodeP(nkWhenStmt, p)
      addSon(result, newNodeP(nkElifBranch, p))
      getTok(p)
      addSon(result.sons[0], expression(p))
      eatNewLine(p, nil)
      parseIfDirAux(p, result)
    of emElse:
      skipLine(p)
      result = parseStmtList(p)
      eatEndif(p)
    of emEndif: skipLine(p)
  else:
    result = newNodeP(nkWhenStmt, p)
    addSon(result, newNodeP(nkElifBranch, p))
    var e = newNodeP(nkCall, p)
    addSon(e, newIdentNodeP("not", p))
    addSon(e, definedExprAux(p))
    eatNewLine(p, nil)
    addSon(result.sons[0], e)
    parseIfDirAux(p, result)
  
proc parseIfDir(p: var TParser): PNode = 
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  addSon(result.sons[0], expression(p))
  eatNewLine(p, nil)
  parseIfDirAux(p, result)

proc parsePegLit(p: var TParser): TPeg =
  var col = getColumn(p.lex) + 2
  getTok(p)
  if p.tok.xkind != pxStrLit: ExpectIdent(p)
  try:
    result = parsePeg(
      pattern = if p.tok.xkind == pxStrLit: p.tok.s else: escapePeg(p.tok.s), 
      filename = p.lex.fileIdx.ToFilename, 
      line = p.lex.linenumber, 
      col = col)
    getTok(p)
  except EInvalidPeg:
    parMessage(p, errUser, getCurrentExceptionMsg())

proc parseMangleDir(p: var TParser) = 
  var pattern = parsePegLit(p)
  if p.tok.xkind != pxStrLit: ExpectIdent(p)
  p.options.mangleRules.add((pattern, p.tok.s))
  getTok(p)
  eatNewLine(p, nil)

proc modulePragmas(p: var TParser): PNode = 
  if p.options.dynlibSym.len > 0 and not p.hasDeadCodeElimPragma:
    p.hasDeadCodeElimPragma = true
    result = newNodeP(nkPragma, p)
    var e = newNodeP(nkExprColonExpr, p)
    addSon(e, newIdentNodeP("deadCodeElim", p), newIdentNodeP("on", p))
    addSon(result, e)
  else:
    result = ast.emptyNode

proc parseDir(p: var TParser): PNode = 
  result = ast.emptyNode
  assert(p.tok.xkind in {pxDirective, pxDirectiveParLe})
  case p.tok.s
  of "define": result = parseDefine(p)
  of "include": result = parseInclude(p)
  of "ifdef": result = parseIfdef(p)
  of "ifndef": result = parseIfndef(p)
  of "if": result = parseIfDir(p)
  of "cdecl", "stdcall", "ref", "skipinclude", "typeprefixes", "skipcomments": 
    discard setOption(p.options, p.tok.s)
    getTok(p)
    eatNewLine(p, nil)
  of "dynlib", "header", "prefix", "suffix", "class": 
    var key = p.tok.s
    getTok(p)
    if p.tok.xkind != pxStrLit: ExpectIdent(p)
    discard setOption(p.options, key, p.tok.s)
    getTok(p)
    eatNewLine(p, nil)
    result = modulePragmas(p)
  of "mangle":
    parseMangleDir(p)
  of "def":
    var L = p.options.macros.len
    setLen(p.options.macros, L+1)
    parseDef(p, p.options.macros[L])
  of "private":
    var pattern = parsePegLit(p)
    p.options.privateRules.add(pattern)
    eatNewLine(p, nil)
  else: 
    # ignore unimportant/unknown directive ("undef", "pragma", "error")
    skipLine(p)

