#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the parser of the standard Nimrod syntax.
# The parser strictly reflects the grammar ("doc/grammar.txt"); however
# it uses several helper routines to keep the parser small. A special
# efficient algorithm is used for the precedence levels. The parser here can
# be seen as a refinement of the grammar, as it specifies how the AST is build
# from the grammar and how comments belong to the AST.

import
  llstream, lexer, idents, strutils, ast, msgs

type
  TParser*{.final.} = object  # a TParser object represents a module that
                              # is being parsed
    lex*: TLexer              # the lexer that is used for parsing
    tok*: TToken              # the current token
  

proc ParseAll*(p: var TParser): PNode
proc openParser*(p: var TParser, filename: string, inputstream: PLLStream)
proc closeParser*(p: var TParser)
proc parseTopLevelStmt*(p: var TParser): PNode
  # implements an iterator. Returns the next top-level statement or
  # emtyNode if end of stream.

proc parseString*(s: string, filename: string = "", line: int = 0): PNode
  # filename and line could be set optionally, when the string originates 
  # from a certain source file. This way, the compiler could generate
  # correct error messages referring to the original source.
  
# helpers for the other parsers
proc getPrecedence*(tok: TToken): int
proc isOperator*(tok: TToken): bool
proc getTok*(p: var TParser)
proc parMessage*(p: TParser, msg: TMsgKind, arg: string = "")
proc skipComment*(p: var TParser, node: PNode)
proc newNodeP*(kind: TNodeKind, p: TParser): PNode
proc newIntNodeP*(kind: TNodeKind, intVal: BiggestInt, p: TParser): PNode
proc newFloatNodeP*(kind: TNodeKind, floatVal: BiggestFloat, p: TParser): PNode
proc newStrNodeP*(kind: TNodeKind, strVal: string, p: TParser): PNode
proc newIdentNodeP*(ident: PIdent, p: TParser): PNode
proc expectIdentOrKeyw*(p: TParser)
proc ExpectIdent*(p: TParser)
proc parLineInfo*(p: TParser): TLineInfo
proc Eat*(p: var TParser, TokType: TTokType)
proc skipInd*(p: var TParser)
proc optPar*(p: var TParser)
proc optInd*(p: var TParser, n: PNode)
proc indAndComment*(p: var TParser, n: PNode)
proc setBaseFlags*(n: PNode, base: TNumericalBase)
proc parseSymbol*(p: var TParser): PNode
proc parseTry(p: var TParser): PNode
proc parseCase(p: var TParser): PNode
# implementation

proc getTok(p: var TParser) = 
  rawGetTok(p.lex, p.tok)

proc OpenParser(p: var TParser, filename: string, inputStream: PLLStream) = 
  initToken(p.tok)
  OpenLexer(p.lex, filename, inputstream)
  getTok(p)                   # read the first token
  
proc CloseParser(p: var TParser) = 
  CloseLexer(p.lex)

proc parMessage(p: TParser, msg: TMsgKind, arg: string = "") = 
  lexMessage(p.lex, msg, arg)

proc parMessage(p: TParser, msg: TMsgKind, tok: TToken) = 
  lexMessage(p.lex, msg, prettyTok(tok))

proc skipComment(p: var TParser, node: PNode) = 
  if p.tok.tokType == tkComment: 
    if node != nil: 
      if node.comment == nil: node.comment = ""
      add(node.comment, p.tok.literal)
    else: 
      parMessage(p, errInternal, "skipComment")
    getTok(p)

proc skipInd(p: var TParser) = 
  if p.tok.tokType == tkInd: getTok(p)
  
proc optPar(p: var TParser) = 
  if p.tok.tokType == tkSad or p.tok.tokType == tkInd: getTok(p)
  
proc optInd(p: var TParser, n: PNode) = 
  skipComment(p, n)
  skipInd(p)

proc ExpectNl(p: TParser) = 
  if p.tok.tokType notin {tkEof, tkSad, tkInd, tkDed, tkComment}: 
    lexMessage(p.lex, errNewlineExpected, prettyTok(p.tok))

proc expectIdentOrKeyw(p: TParser) = 
  if p.tok.tokType != tkSymbol and not isKeyword(p.tok.tokType): 
    lexMessage(p.lex, errIdentifierExpected, prettyTok(p.tok))
  
proc ExpectIdent(p: TParser) = 
  if p.tok.tokType != tkSymbol: 
    lexMessage(p.lex, errIdentifierExpected, prettyTok(p.tok))
  
proc Eat(p: var TParser, TokType: TTokType) = 
  if p.tok.TokType == TokType: getTok(p)
  else: lexMessage(p.lex, errTokenExpected, TokTypeToStr[tokType])
  
proc parLineInfo(p: TParser): TLineInfo = 
  result = getLineInfo(p.lex)

proc indAndComment(p: var TParser, n: PNode) = 
  if p.tok.tokType == tkInd: 
    var info = parLineInfo(p)
    getTok(p)
    if p.tok.tokType == tkComment: skipComment(p, n)
    else: LocalError(info, errInvalidIndentation)
  else: 
    skipComment(p, n)
  
proc newNodeP(kind: TNodeKind, p: TParser): PNode = 
  result = newNodeI(kind, getLineInfo(p.lex))

proc newIntNodeP(kind: TNodeKind, intVal: BiggestInt, p: TParser): PNode = 
  result = newNodeP(kind, p)
  result.intVal = intVal

proc newFloatNodeP(kind: TNodeKind, floatVal: BiggestFloat, 
                   p: TParser): PNode =
  result = newNodeP(kind, p)
  result.floatVal = floatVal

proc newStrNodeP(kind: TNodeKind, strVal: string, p: TParser): PNode = 
  result = newNodeP(kind, p)
  result.strVal = strVal

proc newIdentNodeP(ident: PIdent, p: TParser): PNode = 
  result = newNodeP(nkIdent, p)
  result.ident = ident

proc parseExpr(p: var TParser): PNode
proc parseStmt(p: var TParser): PNode
proc parseTypeDesc(p: var TParser): PNode
proc parseDoBlocks(p: var TParser, call: PNode)
proc parseParamList(p: var TParser, retColon = true): PNode

proc relevantOprChar(ident: PIdent): char {.inline.} =
  result = ident.s[0]
  var L = ident.s.len
  if result == '\\' and L > 1:
    result = ident.s[1]

proc IsSigilLike(tok: TToken): bool {.inline.} =
  result = tok.tokType == tkOpr and relevantOprChar(tok.ident) == '@'

proc IsLeftAssociative(tok: TToken): bool {.inline.} =
  result = tok.tokType != tkOpr or relevantOprChar(tok.ident) != '^'

proc getPrecedence(tok: TToken): int = 
  case tok.tokType
  of tkOpr:
    let L = tok.ident.s.len
    let relevantChar = relevantOprChar(tok.ident)
    
    template considerAsgn(value: expr) = 
      result = if tok.ident.s[L-1] == '=': 1 else: value     
    
    case relevantChar
    of '$', '^': considerAsgn(10)
    of '*', '%', '/', '\\': considerAsgn(9)
    of '~': result = 8
    of '+', '-', '|': considerAsgn(8)
    of '&': considerAsgn(7)
    of '=', '<', '>', '!': result = 5
    of '.': considerAsgn(6)
    of '?': result = 2
    else: considerAsgn(2)
  of tkDiv, tkMod, tkShl, tkShr: result = 9
  of tkIn, tkNotIn, tkIs, tkIsNot, tkNot, tkOf: result = 5
  of tkDotDot: result = 6
  of tkAnd: result = 4
  of tkOr, tkXor: result = 3
  else: result = - 10
  
proc isOperator(tok: TToken): bool = 
  result = getPrecedence(tok) >= 0

proc parseSymbol(p: var TParser): PNode = 
  case p.tok.tokType
  of tkSymbol: 
    result = newIdentNodeP(p.tok.ident, p)
    getTok(p)
  of tkAccent: 
    result = newNodeP(nkAccQuoted, p)
    getTok(p)
    while true:
      case p.tok.tokType
      of tkBracketLe: 
        add(result, newIdentNodeP(getIdent"[]", p))
        getTok(p)
        eat(p, tkBracketRi)
      of tkEquals:
        add(result, newIdentNodeP(getIdent"=", p))
        getTok(p)
      of tkParLe:
        add(result, newIdentNodeP(getIdent"()", p))
        getTok(p)
        eat(p, tkParRi)
      of tkCurlyLe:
        add(result, newIdentNodeP(getIdent"{}", p))
        getTok(p)
        eat(p, tkCurlyRi)
      of tokKeywordLow..tokKeywordHigh, tkSymbol, tkOpr, tkDotDot:
        add(result, newIdentNodeP(p.tok.ident, p))
        getTok(p)
      of tkIntLit..tkCharLit:
        add(result, newIdentNodeP(getIdent(tokToStr(p.tok)), p))
        getTok(p)
      else:
        if result.len == 0: 
          parMessage(p, errIdentifierExpected, p.tok)
        break
    eat(p, tkAccent)
  else: 
    parMessage(p, errIdentifierExpected, p.tok)
    getTok(p) # BUGFIX: We must consume a token here to prevent endless loops!
    result = ast.emptyNode

proc indexExpr(p: var TParser): PNode = 
  result = parseExpr(p)

proc indexExprList(p: var TParser, first: PNode, k: TNodeKind, 
                   endToken: TTokType): PNode = 
  result = newNodeP(k, p)
  addSon(result, first)
  getTok(p)
  optInd(p, result)
  while p.tok.tokType notin {endToken, tkEof, tkSad}:
    var a = indexExpr(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  optPar(p)
  eat(p, endToken)

proc exprColonEqExpr(p: var TParser, kind: TNodeKind, tok: TTokType): PNode = 
  var a = parseExpr(p)
  if p.tok.tokType == tok: 
    result = newNodeP(kind, p)
    getTok(p)
    #optInd(p, result)
    addSon(result, a)
    addSon(result, parseExpr(p))
  else: 
    result = a

proc exprList(p: var TParser, endTok: TTokType, result: PNode) = 
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != endTok) and (p.tok.tokType != tkEof): 
    var a = parseExpr(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  eat(p, endTok)

proc dotExpr(p: var TParser, a: PNode): PNode =
  getTok(p)
  optInd(p, a)
  case p.tok.tokType
  of tkType:
    result = newNodeP(nkTypeOfExpr, p)
    getTok(p)
    addSon(result, a)
  of tkAddr:
    result = newNodeP(nkAddr, p)
    getTok(p)
    addSon(result, a)
  else:
    result = newNodeI(nkDotExpr, a.info)
    addSon(result, a)
    addSon(result, parseSymbol(p))

proc qualifiedIdent(p: var TParser): PNode = 
  result = parseSymbol(p)     #optInd(p, result);
  if p.tok.tokType == tkDot: result = dotExpr(p, result)

proc qualifiedIdentListAux(p: var TParser, endTok: TTokType, result: PNode) = 
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != endTok) and (p.tok.tokType != tkEof): 
    var a = qualifiedIdent(p)
    addSon(result, a)         #optInd(p, a);
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  eat(p, endTok)

proc exprColonEqExprListAux(p: var TParser, elemKind: TNodeKind, 
                            endTok, sepTok: TTokType, result: PNode) = 
  assert(endTok in {tkCurlyRi, tkCurlyDotRi, tkBracketRi, tkParRi})
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != endTok) and (p.tok.tokType != tkEof) and
      (p.tok.tokType != tkSad) and (p.tok.tokType != tkInd): 
    var a = exprColonEqExpr(p, elemKind, sepTok)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  optPar(p)
  eat(p, endTok)

proc exprColonEqExprList(p: var TParser, kind, elemKind: TNodeKind, 
                         endTok, sepTok: TTokType): PNode = 
  result = newNodeP(kind, p)
  exprColonEqExprListAux(p, elemKind, endTok, sepTok, result)

proc setOrTableConstr(p: var TParser): PNode =
  result = newNodeP(nkCurly, p)
  getTok(p) # skip '{'
  optInd(p, result)
  if p.tok.tokType == tkColon:
    getTok(p) # skip ':'
    result.kind = nkTableConstr
  else:
    while p.tok.tokType notin {tkCurlyRi, tkEof, tkSad, tkInd}: 
      var a = exprColonEqExpr(p, nkExprColonExpr, tkColon)
      if a.kind == nkExprColonExpr: result.kind = nkTableConstr
      addSon(result, a)
      if p.tok.tokType != tkComma: break 
      getTok(p)
      optInd(p, a)
  optPar(p)
  eat(p, tkCurlyRi) # skip '}'

proc parseCast(p: var TParser): PNode = 
  result = newNodeP(nkCast, p)
  getTok(p)
  eat(p, tkBracketLe)
  optInd(p, result)
  addSon(result, parseTypeDesc(p))
  optPar(p)
  eat(p, tkBracketRi)
  eat(p, tkParLe)
  optInd(p, result)
  addSon(result, parseExpr(p))
  optPar(p)
  eat(p, tkParRi)

proc parseAddr(p: var TParser): PNode = 
  result = newNodeP(nkAddr, p)
  getTok(p)
  eat(p, tkParLe)
  optInd(p, result)
  addSon(result, parseExpr(p))
  optPar(p)
  eat(p, tkParRi)

proc setBaseFlags(n: PNode, base: TNumericalBase) = 
  case base
  of base10: nil
  of base2: incl(n.flags, nfBase2)
  of base8: incl(n.flags, nfBase8)
  of base16: incl(n.flags, nfBase16)
  
proc parseGStrLit(p: var TParser, a: PNode): PNode = 
  case p.tok.tokType
  of tkGStrLit: 
    result = newNodeP(nkCallStrLit, p)
    addSon(result, a)
    addSon(result, newStrNodeP(nkRStrLit, p.tok.literal, p))
    getTok(p)
  of tkGTripleStrLit: 
    result = newNodeP(nkCallStrLit, p)
    addSon(result, a)
    addSon(result, newStrNodeP(nkTripleStrLit, p.tok.literal, p))
    getTok(p)
  else:
    result = a
  
proc identOrLiteral(p: var TParser): PNode = 
  case p.tok.tokType
  of tkSymbol: 
    result = newIdentNodeP(p.tok.ident, p)
    getTok(p)
    result = parseGStrLit(p, result)
  of tkAccent: 
    result = parseSymbol(p)       # literals
  of tkIntLit: 
    result = newIntNodeP(nkIntLit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkInt8Lit: 
    result = newIntNodeP(nkInt8Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkInt16Lit: 
    result = newIntNodeP(nkInt16Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkInt32Lit: 
    result = newIntNodeP(nkInt32Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkInt64Lit: 
    result = newIntNodeP(nkInt64Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkUIntLit: 
    result = newIntNodeP(nkUIntLit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkUInt8Lit: 
    result = newIntNodeP(nkUInt8Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkUInt16Lit: 
    result = newIntNodeP(nkUInt16Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkUInt32Lit: 
    result = newIntNodeP(nkUInt32Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkUInt64Lit: 
    result = newIntNodeP(nkUInt64Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkFloatLit: 
    result = newFloatNodeP(nkFloatLit, p.tok.fNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkFloat32Lit: 
    result = newFloatNodeP(nkFloat32Lit, p.tok.fNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkFloat64Lit: 
    result = newFloatNodeP(nkFloat64Lit, p.tok.fNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkFloat128Lit:
    result = newFloatNodeP(nkFloat128Lit, p.tok.fNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of tkStrLit: 
    result = newStrNodeP(nkStrLit, p.tok.literal, p)
    getTok(p)
  of tkRStrLit: 
    result = newStrNodeP(nkRStrLit, p.tok.literal, p)
    getTok(p)
  of tkTripleStrLit: 
    result = newStrNodeP(nkTripleStrLit, p.tok.literal, p)
    getTok(p)
  of tkCharLit: 
    result = newIntNodeP(nkCharLit, ord(p.tok.literal[0]), p)
    getTok(p)
  of tkNil: 
    result = newNodeP(nkNilLit, p)
    getTok(p)
  of tkParLe: 
    # () constructor
    result = exprColonEqExprList(p, nkPar, nkExprColonExpr, tkParRi, tkColon)
  of tkCurlyLe: 
    # {} constructor
    result = setOrTableConstr(p)
  of tkBracketLe: 
    # [] constructor
    result = exprColonEqExprList(p, nkBracket, nkExprColonExpr, tkBracketRi, 
                                 tkColon)
  of tkCast: 
    result = parseCast(p)
  else:
    parMessage(p, errExprExpected, p.tok)
    getTok(p)  # we must consume a token here to prevend endless loops!
    result = ast.emptyNode

proc primarySuffix(p: var TParser, r: PNode): PNode =
  result = r
  while true:
    case p.tok.tokType
    of tkParLe: 
      var a = result
      result = newNodeP(nkCall, p)
      addSon(result, a)
      exprColonEqExprListAux(p, nkExprEqExpr, tkParRi, tkEquals, result)
      parseDoBlocks(p, result)
    of tkDo:
      var a = result
      result = newNodeP(nkCall, p)
      addSon(result, a)
      parseDoBlocks(p, result)
    of tkDot:
      result = dotExpr(p, result)
      result = parseGStrLit(p, result)
    of tkBracketLe: 
      result = indexExprList(p, result, nkBracketExpr, tkBracketRi)
    of tkCurlyLe:
      result = indexExprList(p, result, nkCurlyExpr, tkCurlyRi)
    else: break

proc primary(p: var TParser, skipSuffix = false): PNode

proc lowestExprAux(p: var TParser, limit: int): PNode = 
  result = primary(p) 
  # expand while operators have priorities higher than 'limit'
  var opPrec = getPrecedence(p.tok)
  while opPrec >= limit: 
    var leftAssoc = ord(IsLeftAssociative(p.tok))
    var a = newNodeP(nkInfix, p)
    var opNode = newIdentNodeP(p.tok.ident, p) # skip operator:
    getTok(p)
    optInd(p, opNode)         
    # read sub-expression with higher priority:
    var b = lowestExprAux(p, opPrec + leftAssoc)
    addSon(a, opNode)
    addSon(a, result)
    addSon(a, b)
    result = a
    opPrec = getPrecedence(p.tok)
  
proc lowestExpr(p: var TParser): PNode = 
  result = lowestExprAux(p, -1)

proc parseIfExpr(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  while true: 
    getTok(p)                 # skip `if`, `elif`
    var branch = newNodeP(nkElifExpr, p)
    addSon(branch, parseExpr(p))
    eat(p, tkColon)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    optInd(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break 
  var branch = newNodeP(nkElseExpr, p)
  eat(p, tkElse)
  eat(p, tkColon)
  optInd(p, branch)
  addSon(branch, parseExpr(p))
  addSon(result, branch)

proc parsePragma(p: var TParser): PNode = 
  result = newNodeP(nkPragma, p)
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != tkCurlyDotRi) and (p.tok.tokType != tkCurlyRi) and
      (p.tok.tokType != tkEof) and (p.tok.tokType != tkSad): 
    var a = exprColonEqExpr(p, nkExprColonExpr, tkColon)
    addSon(result, a)
    if p.tok.tokType == tkComma: 
      getTok(p)
      optInd(p, a)
  optPar(p)
  if p.tok.tokType in {tkCurlyDotRi, tkCurlyRi}: getTok(p)
  else: parMessage(p, errTokenExpected, ".}")
  
proc identVis(p: var TParser): PNode = 
  # identifier with visability
  var a = parseSymbol(p)
  if p.tok.tokType == tkOpr: 
    result = newNodeP(nkPostfix, p)
    addSon(result, newIdentNodeP(p.tok.ident, p))
    addSon(result, a)
    getTok(p)
  else: 
    result = a
  
proc identWithPragma(p: var TParser): PNode = 
  var a = identVis(p)
  if p.tok.tokType == tkCurlyDotLe: 
    result = newNodeP(nkPragmaExpr, p)
    addSon(result, a)
    addSon(result, parsePragma(p))
  else: 
    result = a
  
type 
  TDeclaredIdentFlag = enum 
    withPragma,               # identifier may have pragma
    withBothOptional          # both ':' and '=' parts are optional
  TDeclaredIdentFlags = set[TDeclaredIdentFlag]

proc parseIdentColonEquals(p: var TParser, flags: TDeclaredIdentFlags): PNode = 
  var a: PNode
  result = newNodeP(nkIdentDefs, p)
  while true: 
    case p.tok.tokType
    of tkSymbol, tkAccent: 
      if withPragma in flags: a = identWithPragma(p)
      else: a = parseSymbol(p)
      if a.kind == nkEmpty: return 
    else: break 
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  if p.tok.tokType == tkColon: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseTypeDesc(p))
  else: 
    addSon(result, ast.emptyNode)
    if (p.tok.tokType != tkEquals) and not (withBothOptional in flags): 
      parMessage(p, errColonOrEqualsExpected, p.tok)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseExpr(p))
  else: 
    addSon(result, ast.emptyNode)
  
proc parseTuple(p: var TParser): PNode = 
  result = newNodeP(nkTupleTy, p)
  getTok(p)
  if p.tok.tokType == tkBracketLe:
    getTok(p)
    optInd(p, result)
    while (p.tok.tokType == tkSymbol) or (p.tok.tokType == tkAccent): 
      var a = parseIdentColonEquals(p, {})
      addSon(result, a)
      if p.tok.tokType notin {tkComma, tkSemicolon}: break 
      getTok(p)
      optInd(p, a)
    optPar(p)
    eat(p, tkBracketRi)

proc parseParamList(p: var TParser, retColon = true): PNode = 
  var a: PNode
  result = newNodeP(nkFormalParams, p)
  addSon(result, ast.emptyNode) # return type
  if p.tok.tokType == tkParLe:
    getTok(p)
    optInd(p, result)
    while true: 
      case p.tok.tokType      #optInd(p, a);
      of tkSymbol, tkAccent: 
        a = parseIdentColonEquals(p, {withBothOptional})
      of tkParRi: 
        break 
      else: 
        parMessage(p, errTokenExpected, ")")
        break 
      addSon(result, a)
      if p.tok.tokType notin {tkComma, tkSemicolon}: break 
      getTok(p)
      optInd(p, a)
    optPar(p)
    eat(p, tkParRi)
  let hasRet = if retColon: p.tok.tokType == tkColon
               else: p.tok.tokType == tkOpr and IdentEq(p.tok.ident, "->")
  if hasRet:
    getTok(p)
    optInd(p, result)
    result.sons[0] = parseTypeDesc(p)

proc optPragmas(p: var TParser): PNode =
  if p.tok.tokType == tkCurlyDotLe: result = parsePragma(p)
  else: result = ast.emptyNode

proc parseDoBlock(p: var TParser): PNode =
  var info = parLineInfo(p)
  getTok(p)
  var params = parseParamList(p, retColon=false)
  var pragmas = optPragmas(p)
  eat(p, tkColon)
  result = newNodeI(nkDo, info)
  addSon(result, ast.emptyNode)       # no name part
  addSon(result, ast.emptyNode)       # no generic parameters
  addSon(result, params)
  addSon(result, pragmas)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseDoBlocks(p: var TParser, call: PNode) =
  while p.tok.tokType == tkDo:
    addSon(call, parseDoBlock(p))
    
proc parseProcExpr(p: var TParser, isExpr: bool): PNode = 
  # either a proc type or a anonymous proc
  var 
    pragmas, params: PNode
    info: TLineInfo
  info = parLineInfo(p)
  getTok(p)
  let hasSignature = p.tok.tokType in {tkParLe, tkColon}
  params = parseParamList(p)
  pragmas = optPragmas(p)
  if (p.tok.tokType == tkEquals) and isExpr: 
    result = newNodeI(nkLambda, info)
    addSon(result, ast.emptyNode)       # no name part
    addSon(result, ast.emptyNode)       # no generic parameters
    addSon(result, params)
    addSon(result, pragmas)
    getTok(p)
    skipComment(p, result)
    addSon(result, parseStmt(p))
  else: 
    result = newNodeI(nkProcTy, info)
    if hasSignature:
      addSon(result, params)
      addSon(result, pragmas)

proc isExprStart(p: TParser): bool = 
  case p.tok.tokType
  of tkSymbol, tkAccent, tkOpr, tkNot, tkNil, tkCast, tkIf, tkProc, tkBind, 
     tkParLe, tkBracketLe, tkCurlyLe, tkIntLit..tkCharLit, tkVar, tkRef, tkPtr, 
     tkTuple, tkType, tkWhen:
    result = true
  else: result = false
  
proc parseTypeDescKAux(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  if not isOperator(p.tok) and isExprStart(p):
    addSon(result, parseTypeDesc(p))

proc parseExpr(p: var TParser): PNode = 
  #
  #expr ::= lowestExpr
  #     | 'if' expr ':' expr ('elif' expr ':' expr)* 'else' ':' expr
  #     | 'when' expr ':' expr ('elif' expr ':' expr)* 'else' ':' expr
  #
  case p.tok.tokType:
  of tkIf: result = parseIfExpr(p, nkIfExpr)
  of tkWhen: result = parseIfExpr(p, nkWhenExpr)
  of tkTry: result = parseTry(p)
  of tkCase: result = parseCase(p)
  else: result = lowestExpr(p)

proc primary(p: var TParser, skipSuffix = false): PNode = 
  # prefix operator?
  if isOperator(p.tok):
    let isSigil = IsSigilLike(p.tok)
    result = newNodeP(nkPrefix, p)
    var a = newIdentNodeP(p.tok.ident, p)
    addSon(result, a)
    getTok(p)
    optInd(p, a)
    if isSigil: 
      #XXX prefix operators
      addSon(result, primary(p, true))
      result = primarySuffix(p, result)
    else:
      addSon(result, primary(p))
    return
  
  case p.tok.tokType:
  of tkVar: result = parseTypeDescKAux(p, nkVarTy)
  of tkRef: result = parseTypeDescKAux(p, nkRefTy)
  of tkPtr: result = parseTypeDescKAux(p, nkPtrTy)
  of tkType: result = parseTypeDescKAux(p, nkTypeOfExpr)
  of tkTuple: result = parseTuple(p)
  of tkProc: result = parseProcExpr(p, true)
  of tkEnum:
    result = newNodeP(nkEnumTy, p)
    getTok(p)
  of tkObject:
    result = newNodeP(nkObjectTy, p)
    getTok(p)
  of tkDistinct:
    result = newNodeP(nkDistinctTy, p)
    getTok(p)
  of tkAddr:
    result = newNodeP(nkAddr, p)
    getTok(p)
    addSon(result, primary(p))
  of tkStatic:
    result = newNodeP(nkStaticExpr, p)
    getTok(p)
    addSon(result, primary(p))
  of tkBind: 
    result = newNodeP(nkBind, p)
    getTok(p)
    optInd(p, result)
    addSon(result, primary(p))
  else:
    result = identOrLiteral(p)
    if not skipSuffix:
      result = primarySuffix(p, result)
  
proc parseTypeDesc(p: var TParser): PNode = 
  if p.tok.toktype == tkProc: result = parseProcExpr(p, false)
  else: result = parseExpr(p)
  
proc parseExprStmt(p: var TParser): PNode = 
  var a = lowestExpr(p)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    var b = parseExpr(p)
    result = newNodeI(nkAsgn, a.info)
    addSon(result, a)
    addSon(result, b)
  else: 
    result = newNodeP(nkCommand, p)
    result.info = a.info
    addSon(result, a)
    while true: 
      if not isExprStart(p): break 
      var e = parseExpr(p)
      addSon(result, e)
      if p.tok.tokType != tkComma: break 
      getTok(p)
      optInd(p, a)
    if p.tok.tokType == tkDo:
      parseDoBlocks(p, result)
      return    
    if sonsLen(result) <= 1: result = a
    else: a = result
    if p.tok.tokType == tkColon:
      # macro statement
      result = newNodeP(nkMacroStmt, p)
      result.info = a.info
      addSon(result, a)
      getTok(p)
      skipComment(p, result)
      if p.tok.tokType == tkSad: getTok(p)
      if not (p.tok.TokType in {tkOf, tkElif, tkElse, tkExcept}): 
        addSon(result, parseStmt(p))
      while true: 
        if p.tok.tokType == tkSad: getTok(p)
        var b: PNode
        case p.tok.tokType
        of tkOf: 
          b = newNodeP(nkOfBranch, p)
          exprList(p, tkColon, b)
        of tkElif: 
          b = newNodeP(nkElifBranch, p)
          getTok(p)
          optInd(p, b)
          addSon(b, parseExpr(p))
          eat(p, tkColon)
        of tkExcept: 
          b = newNodeP(nkExceptBranch, p)
          qualifiedIdentListAux(p, tkColon, b)
          skipComment(p, b)
        of tkElse: 
          b = newNodeP(nkElse, p)
          getTok(p)
          eat(p, tkColon)
        else: break 
        addSon(b, parseStmt(p))
        addSon(result, b)
        if b.kind == nkElse: break 
    
proc parseImportOrIncludeStmt(p: var TParser, kind: TNodeKind): PNode = 
  var a: PNode
  result = newNodeP(kind, p)
  getTok(p)                   # skip `import` or `include`
  optInd(p, result)
  while true: 
    case p.tok.tokType
    of tkEof, tkSad, tkDed: 
      break 
    of tkSymbol, tkAccent: 
      a = parseSymbol(p)
    of tkRStrLit: 
      a = newStrNodeP(nkRStrLit, p.tok.literal, p)
      getTok(p)
    of tkStrLit: 
      a = newStrNodeP(nkStrLit, p.tok.literal, p)
      getTok(p)
    of tkTripleStrLit: 
      a = newStrNodeP(nkTripleStrLit, p.tok.literal, p)
      getTok(p)
    else: 
      parMessage(p, errIdentifierExpected, p.tok)
      break 
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  expectNl(p)

proc parseFromStmt(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkFromStmt, p)
  getTok(p)                   # skip `from`
  optInd(p, result)
  case p.tok.tokType
  of tkSymbol, tkAccent: 
    a = parseSymbol(p)
  of tkRStrLit: 
    a = newStrNodeP(nkRStrLit, p.tok.literal, p)
    getTok(p)
  of tkStrLit: 
    a = newStrNodeP(nkStrLit, p.tok.literal, p)
    getTok(p)
  of tkTripleStrLit: 
    a = newStrNodeP(nkTripleStrLit, p.tok.literal, p)
    getTok(p)
  else: 
    parMessage(p, errIdentifierExpected, p.tok)
    return 
  addSon(result, a)           #optInd(p, a);
  eat(p, tkImport)
  optInd(p, result)
  while true: 
    case p.tok.tokType        #optInd(p, a);
    of tkEof, tkSad, tkDed: 
      break 
    of tkSymbol, tkAccent: 
      a = parseSymbol(p)
    else: 
      parMessage(p, errIdentifierExpected, p.tok)
      break 
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  expectNl(p)

proc parseReturnOrRaise(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  case p.tok.tokType
  of tkEof, tkSad, tkDed: addSon(result, ast.emptyNode)
  else: addSon(result, parseExpr(p))
  
proc parseYieldOrDiscard(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  addSon(result, parseExpr(p))

proc parseBreakOrContinue(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  case p.tok.tokType
  of tkEof, tkSad, tkDed: addSon(result, ast.emptyNode)
  else: addSon(result, parseSymbol(p))
  
proc parseIfOrWhen(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  while true: 
    getTok(p)                 # skip `if`, `when`, `elif`
    var branch = newNodeP(nkElifBranch, p)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseStmt(p))
    skipComment(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break 
  if p.tok.tokType == tkElse: 
    var branch = newNodeP(nkElse, p)
    eat(p, tkElse)
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseStmt(p))
    addSon(result, branch)

proc parseWhile(p: var TParser): PNode = 
  result = newNodeP(nkWhileStmt, p)
  getTok(p)
  optInd(p, result)
  addSon(result, parseExpr(p))
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseCase(p: var TParser): PNode = 
  var 
    b: PNode
    inElif= false
    wasIndented = false
  result = newNodeP(nkCaseStmt, p)
  getTok(p)
  addSon(result, parseExpr(p))
  if p.tok.tokType == tkColon: getTok(p)
  skipComment(p, result)
  
  if p.tok.tokType == tkInd:
    pushInd(p.lex, p.tok.indent)
    getTok(p)
    wasIndented = true
  
  while true: 
    if p.tok.tokType == tkSad: getTok(p)
    case p.tok.tokType
    of tkOf: 
      if inElif: break 
      b = newNodeP(nkOfBranch, p)
      exprList(p, tkColon, b)
    of tkElif: 
      inElif = true
      b = newNodeP(nkElifBranch, p)
      getTok(p)
      optInd(p, b)
      addSon(b, parseExpr(p))
      eat(p, tkColon)
    of tkElse: 
      b = newNodeP(nkElse, p)
      getTok(p)
      eat(p, tkColon)
    else: break 
    skipComment(p, b)
    addSon(b, parseStmt(p))
    addSon(result, b)
    if b.kind == nkElse: break
  
  if wasIndented:
    eat(p, tkDed)
    popInd(p.lex)

proc parseTry(p: var TParser): PNode = 
  result = newNodeP(nkTryStmt, p)
  getTok(p)
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))
  var b: PNode = nil
  while true: 
    if p.tok.tokType == tkSad: getTok(p)
    case p.tok.tokType
    of tkExcept: 
      b = newNodeP(nkExceptBranch, p)
      qualifiedIdentListAux(p, tkColon, b)
    of tkFinally: 
      b = newNodeP(nkFinally, p)
      getTok(p)
      eat(p, tkColon)
    else: break 
    skipComment(p, b)
    addSon(b, parseStmt(p))
    addSon(result, b)
    if b.kind == nkFinally: break 
  if b == nil: parMessage(p, errTokenExpected, "except")

proc parseExceptBlock(p: var TParser, kind: TNodeKind): PNode =
  result = newNodeP(kind, p)
  getTok(p)
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseFor(p: var TParser): PNode = 
  result = newNodeP(nkForStmt, p)
  getTok(p)
  optInd(p, result)
  var a = parseSymbol(p)
  addSon(result, a)
  while p.tok.tokType == tkComma: 
    getTok(p)
    optInd(p, a)
    a = parseSymbol(p)
    addSon(result, a)
  eat(p, tkIn)
  addSon(result, parseExpr(p))
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseBlock(p: var TParser): PNode = 
  result = newNodeP(nkBlockStmt, p)
  getTok(p)
  optInd(p, result)
  case p.tok.tokType
  of tkEof, tkSad, tkDed, tkColon: addSon(result, ast.emptyNode)
  else: addSon(result, parseSymbol(p))
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseStatic(p: var TParser): PNode =
  result = newNodeP(nkStaticStmt, p)
  getTok(p)
  optInd(p, result)
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))
  
proc parseAsm(p: var TParser): PNode = 
  result = newNodeP(nkAsmStmt, p)
  getTok(p)
  optInd(p, result)
  if p.tok.tokType == tkCurlyDotLe: addSon(result, parsePragma(p))
  else: addSon(result, ast.emptyNode)
  case p.tok.tokType
  of tkStrLit: addSon(result, newStrNodeP(nkStrLit, p.tok.literal, p))
  of tkRStrLit: addSon(result, newStrNodeP(nkRStrLit, p.tok.literal, p))
  of tkTripleStrLit: addSon(result, 
                            newStrNodeP(nkTripleStrLit, p.tok.literal, p))
  else: 
    parMessage(p, errStringLiteralExpected)
    addSon(result, ast.emptyNode)
    return 
  getTok(p)

proc parseGenericParam(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkIdentDefs, p)
  while true: 
    case p.tok.tokType
    of tkSymbol, tkAccent: 
      a = parseSymbol(p)
      if a.kind == nkEmpty: return 
    else: break 
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  if p.tok.tokType == tkColon: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseExpr(p))
  else: 
    addSon(result, ast.emptyNode)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseExpr(p))
  else: 
    addSon(result, ast.emptyNode)

proc parseGenericParamList(p: var TParser): PNode = 
  result = newNodeP(nkGenericParams, p)
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType == tkSymbol) or (p.tok.tokType == tkAccent): 
    var a = parseGenericParam(p)
    addSon(result, a)
    if p.tok.tokType notin {tkComma, tkSemicolon}: break 
    getTok(p)
    optInd(p, a)
  optPar(p)
  eat(p, tkBracketRi)

proc parseRoutine(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  addSon(result, identVis(p))
  if p.tok.tokType == tkBracketLe: addSon(result, parseGenericParamList(p))
  else: addSon(result, ast.emptyNode)
  addSon(result, parseParamList(p))
  if p.tok.tokType == tkCurlyDotLe: addSon(result, parsePragma(p))
  else: addSon(result, ast.emptyNode)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    skipComment(p, result)
    addSon(result, parseStmt(p))
  else: 
    addSon(result, ast.emptyNode)
  indAndComment(p, result)    # XXX: document this in the grammar!
  
proc newCommentStmt(p: var TParser): PNode = 
  result = newNodeP(nkCommentStmt, p)
  result.info.line = result.info.line - int16(1)

type 
  TDefParser = proc (p: var TParser): PNode

proc parseSection(p: var TParser, kind: TNodeKind, 
                  defparser: TDefParser): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  skipComment(p, result)
  case p.tok.tokType
  of tkInd: 
    pushInd(p.lex, p.tok.indent)
    getTok(p)
    skipComment(p, result)
    while true: 
      case p.tok.tokType
      of tkSad: 
        getTok(p)
      of tkSymbol, tkAccent: 
        var a = defparser(p)
        skipComment(p, a)
        addSon(result, a)
      of tkDed: 
        getTok(p)
        break 
      of tkEof: 
        break                 # BUGFIX
      of tkComment: 
        var a = newCommentStmt(p)
        skipComment(p, a)
        addSon(result, a)
      else: 
        parMessage(p, errIdentifierExpected, p.tok)
        break 
    popInd(p.lex)
  of tkSymbol, tkAccent, tkParLe: 
    # tkParLe is allowed for ``var (x, y) = ...`` tuple parsing
    addSon(result, defparser(p))
  else: parMessage(p, errIdentifierExpected, p.tok)
  
proc parseConstant(p: var TParser): PNode = 
  result = newNodeP(nkConstDef, p)
  addSon(result, identWithPragma(p))
  if p.tok.tokType == tkColon: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseTypeDesc(p))
  else: 
    addSon(result, ast.emptyNode)
  eat(p, tkEquals)
  optInd(p, result)
  addSon(result, parseExpr(p))
  indAndComment(p, result)    # XXX: special extension!
  
proc parseEnum(p: var TParser): PNode = 
  var a, b: PNode
  result = newNodeP(nkEnumTy, p)
  a = nil
  getTok(p)
  if false and p.tok.tokType == tkOf: 
    a = newNodeP(nkOfInherit, p)
    getTok(p)
    optInd(p, a)
    addSon(a, parseTypeDesc(p))
    addSon(result, a)
  else: 
    addSon(result, ast.emptyNode)
  optInd(p, result)
  while true: 
    case p.tok.tokType
    of tkEof, tkSad, tkDed: break 
    else: a = parseSymbol(p)
    optInd(p, a)
    if p.tok.tokType == tkEquals: 
      getTok(p)
      optInd(p, a)
      b = a
      a = newNodeP(nkEnumFieldDef, p)
      addSon(a, b)
      addSon(a, parseExpr(p))
      skipComment(p, a)
    if p.tok.tokType == tkComma: 
      getTok(p)
      optInd(p, a)
    addSon(result, a)
  if result.len <= 1:
    lexMessage(p.lex, errIdentifierExpected, prettyTok(p.tok))

proc parseObjectPart(p: var TParser): PNode
proc parseObjectWhen(p: var TParser): PNode = 
  result = newNodeP(nkRecWhen, p)
  while true: 
    getTok(p)                 # skip `when`, `elif`
    var branch = newNodeP(nkElifBranch, p)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseObjectPart(p))
    skipComment(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break 
  if p.tok.tokType == tkElse: 
    var branch = newNodeP(nkElse, p)
    eat(p, tkElse)
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseObjectPart(p))
    addSon(result, branch)

proc parseObjectCase(p: var TParser): PNode = 
  result = newNodeP(nkRecCase, p)
  getTok(p)
  var a = newNodeP(nkIdentDefs, p)
  addSon(a, identWithPragma(p))
  eat(p, tkColon)
  addSon(a, parseTypeDesc(p))
  addSon(a, ast.emptyNode)
  addSon(result, a)
  if p.tok.tokType == tkColon: getTok(p)
  skipComment(p, result)
  var wasIndented = false
  if p.tok.tokType == tkInd:
    pushInd(p.lex, p.tok.indent)
    getTok(p)
    wasIndented = true
  while true: 
    if p.tok.tokType == tkSad: getTok(p)
    var b: PNode
    case p.tok.tokType
    of tkOf: 
      b = newNodeP(nkOfBranch, p)
      exprList(p, tkColon, b)
    of tkElse: 
      b = newNodeP(nkElse, p)
      getTok(p)
      eat(p, tkColon)
    else: break 
    skipComment(p, b)
    var fields = parseObjectPart(p)
    if fields.kind == nkEmpty:
      parMessage(p, errIdentifierExpected, p.tok)
      fields = newNodeP(nkNilLit, p) # don't break further semantic checking
    addSon(b, fields)
    addSon(result, b)
    if b.kind == nkElse: break 
  if wasIndented:
    eat(p, tkDed)
    popInd(p.lex)
  
proc parseObjectPart(p: var TParser): PNode = 
  case p.tok.tokType
  of tkInd: 
    result = newNodeP(nkRecList, p)
    pushInd(p.lex, p.tok.indent)
    getTok(p)
    skipComment(p, result)
    while true: 
      case p.tok.tokType
      of tkSad: 
        getTok(p)
      of tkCase, tkWhen, tkSymbol, tkAccent, tkNil: 
        addSon(result, parseObjectPart(p))
      of tkDed: 
        getTok(p)
        break 
      of tkEof: 
        break 
      else: 
        parMessage(p, errIdentifierExpected, p.tok)
        break 
    popInd(p.lex)
  of tkWhen: 
    result = parseObjectWhen(p)
  of tkCase: 
    result = parseObjectCase(p)
  of tkSymbol, tkAccent: 
    result = parseIdentColonEquals(p, {withPragma})
    skipComment(p, result)
  of tkNil: 
    result = newNodeP(nkNilLit, p)
    getTok(p)
  else: result = ast.emptyNode
  
proc parseObject(p: var TParser): PNode = 
  result = newNodeP(nkObjectTy, p)
  getTok(p)
  if p.tok.tokType == tkCurlyDotLe: addSon(result, parsePragma(p))
  else: addSon(result, ast.emptyNode)
  if p.tok.tokType == tkOf: 
    var a = newNodeP(nkOfInherit, p)
    getTok(p)
    addSon(a, parseTypeDesc(p))
    addSon(result, a)
  else: 
    addSon(result, ast.emptyNode)
  skipComment(p, result)
  addSon(result, parseObjectPart(p))

proc parseDistinct(p: var TParser): PNode = 
  result = newNodeP(nkDistinctTy, p)
  getTok(p)
  optInd(p, result)
  addSon(result, parseTypeDesc(p))

proc parseTypeDef(p: var TParser): PNode = 
  result = newNodeP(nkTypeDef, p)
  addSon(result, identWithPragma(p))
  if p.tok.tokType == tkBracketLe: addSon(result, parseGenericParamList(p))
  else: addSon(result, ast.emptyNode)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    var a: PNode
    case p.tok.tokType
    of tkObject: a = parseObject(p)
    of tkEnum: a = parseEnum(p)
    of tkDistinct: a = parseDistinct(p)
    else: a = parseTypeDesc(p)
    addSon(result, a)
  else: 
    addSon(result, ast.emptyNode)
  indAndComment(p, result)    # special extension!
  
proc parseVarTuple(p: var TParser): PNode = 
  result = newNodeP(nkVarTuple, p)
  getTok(p)                   # skip '('
  optInd(p, result)
  while (p.tok.tokType == tkSymbol) or (p.tok.tokType == tkAccent): 
    var a = identWithPragma(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  addSon(result, ast.emptyNode)         # no type desc
  optPar(p)
  eat(p, tkParRi)
  eat(p, tkEquals)
  optInd(p, result)
  addSon(result, parseExpr(p))

proc parseVariable(p: var TParser): PNode = 
  if p.tok.tokType == tkParLe: result = parseVarTuple(p)
  else: result = parseIdentColonEquals(p, {withPragma})
  indAndComment(p, result)    # special extension!
  
proc parseBind(p: var TParser): PNode =
  result = newNodeP(nkBindStmt, p)
  getTok(p)
  optInd(p, result)
  while p.tok.tokType == tkSymbol: 
    var a = newIdentNodeP(p.tok.ident, p)
    getTok(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  expectNl(p)
  
proc parseStmtPragma(p: var TParser): PNode =
  result = parsePragma(p)
  if p.tok.tokType == tkColon:
    let a = result
    result = newNodeI(nkPragmaBlock, a.info)
    getTok(p)
    result.add a
    result.add parseStmt(p)

proc simpleStmt(p: var TParser): PNode = 
  case p.tok.tokType
  of tkReturn: result = parseReturnOrRaise(p, nkReturnStmt)
  of tkRaise: result = parseReturnOrRaise(p, nkRaiseStmt)
  of tkYield: result = parseYieldOrDiscard(p, nkYieldStmt)
  of tkDiscard: result = parseYieldOrDiscard(p, nkDiscardStmt)
  of tkBreak: result = parseBreakOrContinue(p, nkBreakStmt)
  of tkContinue: result = parseBreakOrContinue(p, nkContinueStmt)
  of tkCurlyDotLe: result = parseStmtPragma(p)
  of tkImport: result = parseImportOrIncludeStmt(p, nkImportStmt)
  of tkFrom: result = parseFromStmt(p)
  of tkInclude: result = parseImportOrIncludeStmt(p, nkIncludeStmt)
  of tkComment: result = newCommentStmt(p)
  else: 
    if isExprStart(p): result = parseExprStmt(p)
    else: result = ast.emptyNode
  if result.kind != nkEmpty: skipComment(p, result)
  
proc complexOrSimpleStmt(p: var TParser): PNode = 
  case p.tok.tokType
  of tkIf: result = parseIfOrWhen(p, nkIfStmt)
  of tkWhile: result = parseWhile(p)
  of tkCase: result = parseCase(p)
  of tkTry: result = parseTry(p)
  of tkFinally: result = parseExceptBlock(p, nkFinally)
  of tkExcept: result = parseExceptBlock(p, nkExceptBranch)
  of tkFor: result = parseFor(p)
  of tkBlock: result = parseBlock(p)
  of tkStatic: result = parseStatic(p)
  of tkAsm: result = parseAsm(p)
  of tkProc: result = parseRoutine(p, nkProcDef)
  of tkMethod: result = parseRoutine(p, nkMethodDef)
  of tkIterator: result = parseRoutine(p, nkIteratorDef)
  of tkMacro: result = parseRoutine(p, nkMacroDef)
  of tkTemplate: result = parseRoutine(p, nkTemplateDef)
  of tkConverter: result = parseRoutine(p, nkConverterDef)
  of tkType: result = parseSection(p, nkTypeSection, parseTypeDef)
  of tkConst: result = parseSection(p, nkConstSection, parseConstant)
  of tkLet: result = parseSection(p, nkLetSection, parseVariable)
  of tkWhen: result = parseIfOrWhen(p, nkWhenStmt)
  of tkVar: result = parseSection(p, nkVarSection, parseVariable)
  of tkBind: result = parseBind(p)
  else: result = simpleStmt(p)
  
proc parseStmt(p: var TParser): PNode = 
  if p.tok.tokType == tkInd: 
    result = newNodeP(nkStmtList, p)
    pushInd(p.lex, p.tok.indent)
    getTok(p)
    while true: 
      case p.tok.tokType
      of tkSad, tkSemicolon: getTok(p)
      of tkEof: break 
      of tkDed: 
        getTok(p)
        break 
      else: 
        var a = complexOrSimpleStmt(p)
        if a.kind == nkEmpty:
          # XXX this needs a proper analysis;
          if isKeyword(p.tok.tokType): parMessage(p, errInvalidIndentation)
          break 
        addSon(result, a)
    popInd(p.lex)
  else:
    # the case statement is only needed for better error messages:
    case p.tok.tokType
    of tkIf, tkWhile, tkCase, tkTry, tkFor, tkBlock, tkAsm, tkProc, tkIterator,
       tkMacro, tkType, tkConst, tkWhen, tkVar:
      parMessage(p, errComplexStmtRequiresInd)
      result = ast.emptyNode
    else:
      result = simpleStmt(p)
      if result.kind == nkEmpty: parMessage(p, errExprExpected, p.tok)
      if p.tok.tokType == tkSemicolon: getTok(p)
      if p.tok.tokType == tkSad: getTok(p)
  
proc parseAll(p: var TParser): PNode = 
  result = newNodeP(nkStmtList, p)
  while true: 
    case p.tok.tokType
    of tkSad: getTok(p)
    of tkDed, tkInd: parMessage(p, errInvalidIndentation)
    of tkEof: break 
    else: 
      var a = complexOrSimpleStmt(p)
      if a.kind == nkEmpty: parMessage(p, errExprExpected, p.tok)
      addSon(result, a)

proc parseTopLevelStmt(p: var TParser): PNode = 
  result = ast.emptyNode
  while true: 
    case p.tok.tokType
    of tkSad, tkSemicolon: getTok(p)
    of tkDed, tkInd: 
      parMessage(p, errInvalidIndentation)
      getTok(p)
    of tkEof: break 
    else: 
      result = complexOrSimpleStmt(p)
      if result.kind == nkEmpty: parMessage(p, errExprExpected, p.tok)
      break

proc parseString(s: string, filename: string = "", line: int = 0): PNode =
  var stream = LLStreamOpen(s)
  stream.lineOffset = line

  var parser: TParser
  OpenParser(parser, filename, stream)

  result = parser.parseAll
  CloseParser(parser)
  
