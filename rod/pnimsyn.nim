#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the parser of the standard Nimrod representation.
# The parser strictly reflects the grammar ("doc/grammar.txt"); however
# it uses several helper routines to keep the parser small. A special
# efficient algorithm is used for the precedence levels. The parser here can
# be seen as a refinement of the grammar, as it specifies how the AST is build
# from the grammar and how comments belong to the AST.

import
  llstream, scanner, idents, strutils, ast, msgs

type 
  TParser*{.final.} = object  # a TParser object represents a module that
                              # is being parsed
    lex*: PLexer              # the lexer that is used for parsing
    tok*: PToken              # the current token
  

proc ParseAll*(p: var TParser): PNode
proc openParser*(p: var TParser, filename: string, inputstream: PLLStream)
proc closeParser*(p: var TParser)
proc parseTopLevelStmt*(p: var TParser): PNode
  # implements an iterator. Returns the next top-level statement or nil if end
  # of stream.
  
# helpers for the other parsers
proc getPrecedence*(tok: PToken): int
proc isOperator*(tok: PToken): bool
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
proc expectIdentOrOpr*(p: TParser)
proc parLineInfo*(p: TParser): TLineInfo
proc Eat*(p: var TParser, TokType: TTokType)
proc skipInd*(p: var TParser)
proc optPar*(p: var TParser)
proc optInd*(p: var TParser, n: PNode)
proc indAndComment*(p: var TParser, n: PNode)
proc setBaseFlags*(n: PNode, base: TNumericalBase)
proc parseSymbol*(p: var TParser): PNode
proc accExpr*(p: var TParser): PNode
# implementation

proc initParser(p: var TParser) = 
  new(p.lex)
  new(p.tok)

proc getTok(p: var TParser) = 
  rawGetTok(p.lex^, p.tok^)

proc OpenParser(p: var TParser, filename: string, inputStream: PLLStream) = 
  initParser(p)
  OpenLexer(p.lex^, filename, inputstream)
  getTok(p)                   # read the first token
  
proc CloseParser(p: var TParser) = 
  CloseLexer(p.lex^)

proc parMessage(p: TParser, msg: TMsgKind, arg: string = "") = 
  lexMessage(p.lex^, msg, arg)

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

proc expectIdentOrKeyw(p: TParser) = 
  if (p.tok.tokType != tkSymbol) and not isKeyword(p.tok.tokType): 
    lexMessage(p.lex^, errIdentifierExpected, tokToStr(p.tok))
  
proc ExpectIdent(p: TParser) = 
  if p.tok.tokType != tkSymbol: 
    lexMessage(p.lex^, errIdentifierExpected, tokToStr(p.tok))
  
proc expectIdentOrOpr(p: TParser) = 
  if not (p.tok.tokType in tokOperators): 
    lexMessage(p.lex^, errOperatorExpected, tokToStr(p.tok))
  
proc Eat(p: var TParser, TokType: TTokType) = 
  if p.tok.TokType == TokType: getTok(p)
  else: lexMessage(p.lex^, errTokenExpected, TokTypeToStr[tokType])
  
proc parLineInfo(p: TParser): TLineInfo = 
  result = getLineInfo(p.lex^)

proc indAndComment(p: var TParser, n: PNode) = 
  if p.tok.tokType == tkInd: 
    var info = parLineInfo(p)
    getTok(p)
    if p.tok.tokType == tkComment: skipComment(p, n)
    else: liMessage(info, errInvalidIndentation)
  else: 
    skipComment(p, n)
  
proc newNodeP(kind: TNodeKind, p: TParser): PNode = 
  result = newNodeI(kind, getLineInfo(p.lex^))

proc newIntNodeP(kind: TNodeKind, intVal: BiggestInt, p: TParser): PNode = 
  result = newNodeP(kind, p)
  result.intVal = intVal

proc newFloatNodeP(kind: TNodeKind, floatVal: BiggestFloat, p: TParser): PNode = 
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
proc parseParamList(p: var TParser): PNode

proc getPrecedence(tok: PToken): int = 
  case tok.tokType
  of tkOpr: 
    case tok.ident.s[0]
    of '$': result = 7
    of '*', '%', '/', '\\': result = 6
    of '+', '-', '~', '|': result = 5
    of '&': result = 4
    of '=', '<', '>', '!': result = 3
    else: result = 0
  of tkDiv, tkMod, tkShl, tkShr: result = 6
  of tkIn, tkNotIn, tkIs, tkIsNot: result = 3
  of tkAnd: result = 2
  of tkOr, tkXor: result = 1
  else: result = - 1
  
proc isOperator(tok: PToken): bool = 
  result = getPrecedence(tok) >= 0

proc parseSymbol(p: var TParser): PNode = 
  case p.tok.tokType
  of tkSymbol: 
    result = newIdentNodeP(p.tok.ident, p)
    getTok(p)
  of tkAccent: 
    result = newNodeP(nkAccQuoted, p)
    getTok(p)
    case p.tok.tokType
    of tkBracketLe: 
      var s = "["
      getTok(p)
      while true:
        if p.tok.tokType == tkComma:
          add(s, ",")
          getTok(p)
        elif (p.tok.tokType == tkOpr) and (p.tok.ident.s == "$"): 
          add(s, "$..")
          getTok(p)
          eat(p, tkDotDot)
          if (p.tok.tokType == tkOpr) and (p.tok.ident.s == "$"): 
            add(s, '$')
            getTok(p)
        elif p.tok.tokType == tkDotDot: 
          add(s, "..")
          getTok(p)
          if (p.tok.tokType == tkOpr) and (p.tok.ident.s == "$"): 
            add(s, '$')
            getTok(p)
        else: break
      eat(p, tkBracketRi)
      add(s, ']')
      if p.tok.tokType == tkEquals: 
        add(s, '=')
        getTok(p)
      addSon(result, newIdentNodeP(getIdent(s), p))
    of tkParLe: 
      addSon(result, newIdentNodeP(getIdent("()"), p))
      getTok(p)
      eat(p, tkParRi)
    of tokKeywordLow..tokKeywordHigh, tkSymbol, tkOpr: 
      var id = p.tok.ident
      getTok(p)
      if p.tok.tokType == tkEquals: 
        addSon(result, newIdentNodeP(getIdent(id.s & '='), p))
        getTok(p)
      else: 
        addSon(result, newIdentNodeP(id, p))
    else: 
      parMessage(p, errIdentifierExpected, tokToStr(p.tok))
      result = nil
    eat(p, tkAccent)
  else: 
    parMessage(p, errIdentifierExpected, tokToStr(p.tok))
    result = nil

proc accExpr(p: var TParser): PNode = 
  var x, y: PNode
  result = newNodeP(nkAccQuoted, p)
  getTok(p)                   # skip `
  x = nil
  y = nil
  case p.tok.tokType
  of tkSymbol, tkOpr, tokKeywordLow..tokKeywordHigh: 
    x = newIdentNodeP(p.tok.ident, p)
    getTok(p)
  else: 
    parMessage(p, errIdentifierExpected, tokToStr(p.tok))
  if p.tok.tokType == tkDot: 
    getTok(p)
    case p.tok.tokType
    of tkSymbol, tkOpr, tokKeywordLow..tokKeywordHigh: 
      y = newNodeP(nkDotExpr, p)
      addSon(y, x)
      addSon(y, newIdentNodeP(p.tok.ident, p))
      getTok(p)
      x = y
    else: 
      parMessage(p, errIdentifierExpected, tokToStr(p.tok))
  addSon(result, x)
  eat(p, tkAccent)

proc optExpr(p: var TParser): PNode = 
  # [expr]
  if (p.tok.tokType != tkComma) and (p.tok.tokType != tkBracketRi) and
      (p.tok.tokType != tkDotDot): 
    result = parseExpr(p)
  else: 
    result = nil
  
proc dotdotExpr(p: var TParser, first: PNode = nil): PNode = 
  result = newNodeP(nkRange, p)
  addSon(result, first)
  getTok(p)
  optInd(p, result)
  addSon(result, optExpr(p))

proc indexExpr(p: var TParser): PNode = 
  # indexExpr ::= '..' [expr] | expr ['=' expr | '..' expr]
  var a, b: PNode
  if p.tok.tokType == tkDotDot: 
    result = dotdotExpr(p)
  else: 
    a = parseExpr(p)
    case p.tok.tokType
    of tkEquals: 
      result = newNodeP(nkExprEqExpr, p)
      addSon(result, a)
      getTok(p)
      if p.tok.tokType == tkDotDot: 
        addSon(result, dotdotExpr(p))
      else: 
        b = parseExpr(p)
        if p.tok.tokType == tkDotDot: b = dotdotExpr(p, b)
        addSon(result, b)
    of tkDotDot: 
      result = dotdotExpr(p, a)
    else: result = a
  
proc indexExprList(p: var TParser, first: PNode): PNode = 
  result = newNodeP(nkBracketExpr, p)
  addSon(result, first)
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != tkBracketRi) and (p.tok.tokType != tkEof) and
      (p.tok.tokType != tkSad): 
    var a = indexExpr(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  optPar(p)
  eat(p, tkBracketRi)

proc exprColonEqExpr(p: var TParser, kind: TNodeKind, tok: TTokType): PNode = 
  var a = parseExpr(p)
  if p.tok.tokType == tok: 
    result = newNodeP(kind, p)
    getTok(p)                 #optInd(p, result);
    addSon(result, a)
    addSon(result, parseExpr(p))
  else: 
    result = a
  
proc exprListAux(p: var TParser, elemKind: TNodeKind, endTok, sepTok: TTokType, 
                 result: PNode) = 
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != endTok) and (p.tok.tokType != tkEof): 
    var a = exprColonEqExpr(p, elemKind, sepTok)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  eat(p, endTok)

proc qualifiedIdent(p: var TParser): PNode = 
  result = parseSymbol(p)     #optInd(p, result);
  if p.tok.tokType == tkDot: 
    getTok(p)
    optInd(p, result)
    var a = result
    result = newNodeI(nkDotExpr, a.info)
    addSon(result, a)
    addSon(result, parseSymbol(p))

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
  of base10: 
    nil
  of base2: 
    incl(n.flags, nfBase2)
  of base8: 
    incl(n.flags, nfBase8)
  of base16: 
    incl(n.flags, nfBase16)
  
proc identOrLiteral(p: var TParser): PNode = 
  case p.tok.tokType
  of tkSymbol: 
    result = newIdentNodeP(p.tok.ident, p)
    getTok(p)
  of tkAccent: 
    result = accExpr(p)       # literals
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
  of tkStrLit: 
    result = newStrNodeP(nkStrLit, p.tok.literal, p)
    getTok(p)
  of tkRStrLit: 
    result = newStrNodeP(nkRStrLit, p.tok.literal, p)
    getTok(p)
  of tkTripleStrLit: 
    result = newStrNodeP(nkTripleStrLit, p.tok.literal, p)
    getTok(p)
  of tkCallRStrLit: 
    result = newNodeP(nkCallStrLit, p)
    addSon(result, newIdentNodeP(p.tok.ident, p))
    addSon(result, newStrNodeP(nkRStrLit, p.tok.literal, p))
    getTok(p)
  of tkCallTripleStrLit: 
    result = newNodeP(nkCallStrLit, p)
    addSon(result, newIdentNodeP(p.tok.ident, p))
    addSon(result, newStrNodeP(nkTripleStrLit, p.tok.literal, p))
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
    result = exprColonEqExprList(p, nkCurly, nkRange, tkCurlyRi, tkDotDot)
  of tkBracketLe: 
    # [] constructor
    result = exprColonEqExprList(p, nkBracket, nkExprColonExpr, tkBracketRi, 
                                 tkColon)
  of tkCast: 
    result = parseCast(p)
  of tkAddr: 
    result = parseAddr(p)
  else: 
    parMessage(p, errExprExpected, tokToStr(p.tok))
    getTok(p)                 # we must consume a token here to prevend endless loops!
    result = nil

proc primary(p: var TParser): PNode = 
  var a: PNode
  # prefix operator?
  if (p.tok.tokType == tkNot) or (p.tok.tokType == tkOpr): 
    result = newNodeP(nkPrefix, p)
    a = newIdentNodeP(p.tok.ident, p)
    addSon(result, a)
    getTok(p)
    optInd(p, a)
    addSon(result, primary(p))
    return 
  elif p.tok.tokType == tkBind: 
    result = newNodeP(nkBind, p)
    getTok(p)
    optInd(p, result)
    addSon(result, primary(p))
    return 
  result = identOrLiteral(p)
  while true: 
    case p.tok.tokType
    of tkParLe: 
      a = result
      result = newNodeP(nkCall, p)
      addSon(result, a)
      exprColonEqExprListAux(p, nkExprEqExpr, tkParRi, tkEquals, result)
    of tkDot: 
      a = result
      result = newNodeP(nkDotExpr, p)
      addSon(result, a)
      getTok(p)               # skip '.'
      optInd(p, result)
      addSon(result, parseSymbol(p))
    of tkHat: 
      a = result
      result = newNodeP(nkDerefExpr, p)
      addSon(result, a)
      getTok(p)
    of tkBracketLe: 
      result = indexExprList(p, result)
    else: break 
  
proc lowestExprAux(p: var TParser, v: var PNode, limit: int): PToken = 
  var 
    op, nextop: PToken
    opPred: int
    v2, node, opNode: PNode
  v = primary(p) # expand while operators have priorities higher than 'limit'
  op = p.tok
  opPred = getPrecedence(p.tok)
  while (opPred > limit): 
    node = newNodeP(nkInfix, p)
    opNode = newIdentNodeP(op.ident, p) # skip operator:
    getTok(p)
    optInd(p, opNode)         # read sub-expression with higher priority
    nextop = lowestExprAux(p, v2, opPred)
    addSon(node, opNode)
    addSon(node, v)
    addSon(node, v2)
    v = node
    op = nextop
    opPred = getPrecedence(nextop)
  result = op                 # return first untreated operator
  
proc lowestExpr(p: var TParser): PNode = 
  discard lowestExprAux(p, result, - 1)

proc parseIfExpr(p: var TParser): PNode = 
  var branch: PNode
  result = newNodeP(nkIfExpr, p)
  while true: 
    getTok(p)                 # skip `if`, `elif`
    branch = newNodeP(nkElifExpr, p)
    addSon(branch, parseExpr(p))
    eat(p, tkColon)
    addSon(branch, parseExpr(p))
    addSon(result, branch)
    if p.tok.tokType != tkElif: break 
  branch = newNodeP(nkElseExpr, p)
  eat(p, tkElse)
  eat(p, tkColon)
  addSon(branch, parseExpr(p))
  addSon(result, branch)

proc parsePragma(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkPragma, p)
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != tkCurlyDotRi) and (p.tok.tokType != tkCurlyRi) and
      (p.tok.tokType != tkEof) and (p.tok.tokType != tkSad): 
    a = exprColonEqExpr(p, nkExprColonExpr, tkColon)
    addSon(result, a)
    if p.tok.tokType == tkComma: 
      getTok(p)
      optInd(p, a)
  optPar(p)
  if (p.tok.tokType == tkCurlyDotRi) or (p.tok.tokType == tkCurlyRi): getTok(p)
  else: parMessage(p, errTokenExpected, ".}")
  
proc identVis(p: var TParser): PNode = 
  # identifier with visability
  var a: PNode
  a = parseSymbol(p)
  if p.tok.tokType == tkOpr: 
    result = newNodeP(nkPostfix, p)
    addSon(result, newIdentNodeP(p.tok.ident, p))
    addSon(result, a)
    getTok(p)
  else: 
    result = a
  
proc identWithPragma(p: var TParser): PNode = 
  var a: PNode
  a = identVis(p)
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
      if a == nil: return 
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
    addSon(result, nil)
    if (p.tok.tokType != tkEquals) and not (withBothOptional in flags): 
      parMessage(p, errColonOrEqualsExpected, tokToStr(p.tok))
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseExpr(p))
  else: 
    addSon(result, nil)
  
proc parseTuple(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkTupleTy, p)
  getTok(p)
  eat(p, tkBracketLe)
  optInd(p, result)
  while (p.tok.tokType == tkSymbol) or (p.tok.tokType == tkAccent): 
    a = parseIdentColonEquals(p, {})
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  optPar(p)
  eat(p, tkBracketRi)

proc parseParamList(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkFormalParams, p)
  addSon(result, nil)         # return type
  if p.tok.tokType == tkParLe: 
    getTok(p)
    optInd(p, result)
    while true: 
      case p.tok.tokType      #optInd(p, a);
      of tkSymbol, tkAccent: 
        a = parseIdentColonEquals(p, {})
      of tkParRi: 
        break 
      else: 
        parMessage(p, errTokenExpected, ")")
        break 
      addSon(result, a)
      if p.tok.tokType != tkComma: break 
      getTok(p)
      optInd(p, a)
    optPar(p)
    eat(p, tkParRi)
  if p.tok.tokType == tkColon: 
    getTok(p)
    optInd(p, result)
    result.sons[0] = parseTypeDesc(p)

proc parseProcExpr(p: var TParser, isExpr: bool): PNode = 
  # either a proc type or a anonymous proc
  var 
    pragmas, params: PNode
    info: TLineInfo
  info = parLineInfo(p)
  getTok(p)
  params = parseParamList(p)
  if p.tok.tokType == tkCurlyDotLe: pragmas = parsePragma(p)
  else: pragmas = nil
  if (p.tok.tokType == tkEquals) and isExpr: 
    result = newNodeI(nkLambda, info)
    addSon(result, nil)       # no name part
    addSon(result, nil)       # no generic parameters
    addSon(result, params)
    addSon(result, pragmas)
    getTok(p)
    skipComment(p, result)
    addSon(result, parseStmt(p))
  else: 
    result = newNodeI(nkProcTy, info)
    addSon(result, params)
    addSon(result, pragmas)

proc parseTypeDescKAux(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  addSon(result, parseTypeDesc(p))

proc parseExpr(p: var TParser): PNode = 
  #
  #expr ::= lowestExpr
  #     | 'if' expr ':' expr ('elif' expr ':' expr)* 'else' ':' expr
  #     | 'var' expr
  #     | 'ref' expr
  #     | 'ptr' expr
  #     | 'type' expr
  #     | 'tuple' tupleDesc
  #     | 'proc' paramList [pragma] ['=' stmt] 
  #
  case p.tok.toktype
  of tkVar: result = parseTypeDescKAux(p, nkVarTy)
  of tkRef: result = parseTypeDescKAux(p, nkRefTy)
  of tkPtr: result = parseTypeDescKAux(p, nkPtrTy)
  of tkType: result = parseTypeDescKAux(p, nkTypeOfExpr)
  of tkTuple: result = parseTuple(p)
  of tkProc: result = parseProcExpr(p, true)
  of tkIf: result = parseIfExpr(p)
  else: result = lowestExpr(p)
  
proc parseTypeDesc(p: var TParser): PNode = 
  if p.tok.toktype == tkProc: result = parseProcExpr(p, false)
  else: result = parseExpr(p)
  
proc isExprStart(p: TParser): bool = 
  case p.tok.tokType
  of tkSymbol, tkAccent, tkOpr, tkNot, tkNil, tkCast, tkIf, tkProc, tkBind, 
     tkParLe, tkBracketLe, tkCurlyLe, tkIntLit..tkCharLit, tkVar, tkRef, tkPtr, 
     tkTuple, tkType: 
    result = true
  else: result = false
  
proc parseExprStmt(p: var TParser): PNode = 
  var a, b, e: PNode
  a = lowestExpr(p)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    b = parseExpr(p)
    result = newNodeI(nkAsgn, a.info)
    addSon(result, a)
    addSon(result, b)
  else: 
    result = newNodeP(nkCommand, p)
    result.info = a.info
    addSon(result, a)
    while true: 
      if not isExprStart(p): break 
      e = parseExpr(p)
      addSon(result, e)
      if p.tok.tokType != tkComma: break 
      getTok(p)
      optInd(p, a)
    if sonsLen(result) <= 1: result = a
    else: a = result
    if p.tok.tokType == tkColon: 
      # macro statement
      result = newNodeP(nkMacroStmt, p)
      result.info = a.info
      addSon(result, a)
      getTok(p)
      skipComment(p, result)
      if (p.tok.tokType == tkInd) or
          not (p.tok.TokType in {tkOf, tkElif, tkElse, tkExcept}): 
        addSon(result, parseStmt(p))
      while true: 
        if p.tok.tokType == tkSad: getTok(p)
        case p.tok.tokType
        of tkOf: 
          b = newNodeP(nkOfBranch, p)
          exprListAux(p, nkRange, tkColon, tkDotDot, b)
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
      parMessage(p, errIdentifierExpected, tokToStr(p.tok))
      break 
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)

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
    parMessage(p, errIdentifierExpected, tokToStr(p.tok))
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
      parMessage(p, errIdentifierExpected, tokToStr(p.tok))
      break 
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)

proc parseReturnOrRaise(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  case p.tok.tokType
  of tkEof, tkSad, tkDed: addSon(result, nil)
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
  of tkEof, tkSad, tkDed: addSon(result, nil)
  else: addSon(result, parseSymbol(p))
  
proc parseIfOrWhen(p: var TParser, kind: TNodeKind): PNode = 
  var branch: PNode
  result = newNodeP(kind, p)
  while true: 
    getTok(p)                 # skip `if`, `when`, `elif`
    branch = newNodeP(nkElifBranch, p)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseStmt(p))
    skipComment(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break 
  if p.tok.tokType == tkElse: 
    branch = newNodeP(nkElse, p)
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
    inElif: bool
  result = newNodeP(nkCaseStmt, p)
  getTok(p)
  addSon(result, parseExpr(p))
  if p.tok.tokType == tkColon: getTok(p)
  skipComment(p, result)
  inElif = false
  while true: 
    if p.tok.tokType == tkSad: getTok(p)
    case p.tok.tokType
    of tkOf: 
      if inElif: break 
      b = newNodeP(nkOfBranch, p)
      exprListAux(p, nkRange, tkColon, tkDotDot, b)
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
  
proc parseTry(p: var TParser): PNode = 
  var b: PNode
  result = newNodeP(nkTryStmt, p)
  getTok(p)
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))
  b = nil
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
  
proc parseFor(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkForStmt, p)
  getTok(p)
  optInd(p, result)
  a = parseSymbol(p)
  addSon(result, a)
  while p.tok.tokType == tkComma: 
    getTok(p)
    optInd(p, a)
    a = parseSymbol(p)
    addSon(result, a)
  eat(p, tkIn)
  addSon(result, exprColonEqExpr(p, nkRange, tkDotDot))
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseBlock(p: var TParser): PNode = 
  result = newNodeP(nkBlockStmt, p)
  getTok(p)
  optInd(p, result)
  case p.tok.tokType
  of tkEof, tkSad, tkDed, tkColon: addSon(result, nil)
  else: addSon(result, parseSymbol(p))
  eat(p, tkColon)
  skipComment(p, result)
  addSon(result, parseStmt(p))

proc parseAsm(p: var TParser): PNode = 
  result = newNodeP(nkAsmStmt, p)
  getTok(p)
  optInd(p, result)
  if p.tok.tokType == tkCurlyDotLe: addSon(result, parsePragma(p))
  else: addSon(result, nil)
  case p.tok.tokType
  of tkStrLit: addSon(result, newStrNodeP(nkStrLit, p.tok.literal, p))
  of tkRStrLit: addSon(result, newStrNodeP(nkRStrLit, p.tok.literal, p))
  of tkTripleStrLit: addSon(result, 
                            newStrNodeP(nkTripleStrLit, p.tok.literal, p))
  else: 
    parMessage(p, errStringLiteralExpected)
    addSon(result, nil)
    return 
  getTok(p)

proc parseGenericParamList(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkGenericParams, p)
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType == tkSymbol) or (p.tok.tokType == tkAccent): 
    a = parseIdentColonEquals(p, {withBothOptional})
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
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
  else: addSon(result, nil)
  addSon(result, parseParamList(p))
  if p.tok.tokType == tkCurlyDotLe: addSon(result, parsePragma(p))
  else: addSon(result, nil)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    skipComment(p, result)
    addSon(result, parseStmt(p))
  else: 
    addSon(result, nil)
  indAndComment(p, result)    # XXX: document this in the grammar!
  
proc newCommentStmt(p: var TParser): PNode = 
  result = newNodeP(nkCommentStmt, p)
  result.info.line = result.info.line - int16(1)

type 
  TDefParser = proc (p: var TParser): PNode

proc parseSection(p: var TParser, kind: TNodeKind, 
                  defparser: TDefParser): PNode = 
  var a: PNode
  result = newNodeP(kind, p)
  getTok(p)
  skipComment(p, result)
  case p.tok.tokType
  of tkInd: 
    pushInd(p.lex^ , p.tok.indent)
    getTok(p)
    skipComment(p, result)
    while true: 
      case p.tok.tokType
      of tkSad: 
        getTok(p)
      of tkSymbol, tkAccent: 
        a = defparser(p)
        skipComment(p, a)
        addSon(result, a)
      of tkDed: 
        getTok(p)
        break 
      of tkEof: 
        break                 # BUGFIX
      of tkComment: 
        a = newCommentStmt(p)
        skipComment(p, a)
        addSon(result, a)
      else: 
        parMessage(p, errIdentifierExpected, tokToStr(p.tok))
        break 
    popInd(p.lex^ )
  of tkSymbol, tkAccent, tkParLe: 
    # tkParLe is allowed for ``var (x, y) = ...`` tuple parsing
    addSon(result, defparser(p))
  else: parMessage(p, errIdentifierExpected, tokToStr(p.tok))
  
proc parseConstant(p: var TParser): PNode = 
  result = newNodeP(nkConstDef, p)
  addSon(result, identWithPragma(p))
  if p.tok.tokType == tkColon: 
    getTok(p)
    optInd(p, result)
    addSon(result, parseTypeDesc(p))
  else: 
    addSon(result, nil)
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
    addSon(result, nil)
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

proc parseObjectPart(p: var TParser): PNode
proc parseObjectWhen(p: var TParser): PNode = 
  var branch: PNode
  result = newNodeP(nkRecWhen, p)
  while true: 
    getTok(p)                 # skip `when`, `elif`
    branch = newNodeP(nkElifBranch, p)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseObjectPart(p))
    skipComment(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break 
  if p.tok.tokType == tkElse: 
    branch = newNodeP(nkElse, p)
    eat(p, tkElse)
    eat(p, tkColon)
    skipComment(p, branch)
    addSon(branch, parseObjectPart(p))
    addSon(result, branch)

proc parseObjectCase(p: var TParser): PNode = 
  var a, b: PNode
  result = newNodeP(nkRecCase, p)
  getTok(p)
  a = newNodeP(nkIdentDefs, p)
  addSon(a, identWithPragma(p))
  eat(p, tkColon)
  addSon(a, parseTypeDesc(p))
  addSon(a, nil)
  addSon(result, a)
  skipComment(p, result)
  while true: 
    if p.tok.tokType == tkSad: getTok(p)
    case p.tok.tokType
    of tkOf: 
      b = newNodeP(nkOfBranch, p)
      exprListAux(p, nkRange, tkColon, tkDotDot, b)
    of tkElse: 
      b = newNodeP(nkElse, p)
      getTok(p)
      eat(p, tkColon)
    else: break 
    skipComment(p, b)
    addSon(b, parseObjectPart(p))
    addSon(result, b)
    if b.kind == nkElse: break 
  
proc parseObjectPart(p: var TParser): PNode = 
  case p.tok.tokType
  of tkInd: 
    result = newNodeP(nkRecList, p)
    pushInd(p.lex^ , p.tok.indent)
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
        parMessage(p, errIdentifierExpected, tokToStr(p.tok))
        break 
    popInd(p.lex^)
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
  else: result = nil
  
proc parseObject(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkObjectTy, p)
  getTok(p)
  if p.tok.tokType == tkCurlyDotLe: addSon(result, parsePragma(p))
  else: addSon(result, nil)
  if p.tok.tokType == tkOf: 
    a = newNodeP(nkOfInherit, p)
    getTok(p)
    addSon(a, parseTypeDesc(p))
    addSon(result, a)
  else: 
    addSon(result, nil)
  skipComment(p, result)
  addSon(result, parseObjectPart(p))

proc parseDistinct(p: var TParser): PNode = 
  result = newNodeP(nkDistinctTy, p)
  getTok(p)
  optInd(p, result)
  addSon(result, parseTypeDesc(p))

proc parseTypeDef(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkTypeDef, p)
  addSon(result, identWithPragma(p))
  if p.tok.tokType == tkBracketLe: addSon(result, parseGenericParamList(p))
  else: addSon(result, nil)
  if p.tok.tokType == tkEquals: 
    getTok(p)
    optInd(p, result)
    case p.tok.tokType
    of tkObject: a = parseObject(p)
    of tkEnum: a = parseEnum(p)
    of tkDistinct: a = parseDistinct(p)
    else: a = parseTypeDesc(p)
    addSon(result, a)
  else: 
    addSon(result, nil)
  indAndComment(p, result)    # special extension!
  
proc parseVarTuple(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkVarTuple, p)
  getTok(p)                   # skip '('
  optInd(p, result)
  while (p.tok.tokType == tkSymbol) or (p.tok.tokType == tkAccent): 
    a = identWithPragma(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break 
    getTok(p)
    optInd(p, a)
  addSon(result, nil)         # no type desc
  optPar(p)
  eat(p, tkParRi)
  eat(p, tkEquals)
  optInd(p, result)
  addSon(result, parseExpr(p))

proc parseVariable(p: var TParser): PNode = 
  if p.tok.tokType == tkParLe: result = parseVarTuple(p)
  else: result = parseIdentColonEquals(p, {withPragma})
  indAndComment(p, result)    # special extension!
  
proc simpleStmt(p: var TParser): PNode = 
  case p.tok.tokType
  of tkReturn: result = parseReturnOrRaise(p, nkReturnStmt)
  of tkRaise: result = parseReturnOrRaise(p, nkRaiseStmt)
  of tkYield: result = parseYieldOrDiscard(p, nkYieldStmt)
  of tkDiscard: result = parseYieldOrDiscard(p, nkDiscardStmt)
  of tkBreak: result = parseBreakOrContinue(p, nkBreakStmt)
  of tkContinue: result = parseBreakOrContinue(p, nkContinueStmt)
  of tkCurlyDotLe: result = parsePragma(p)
  of tkImport: result = parseImportOrIncludeStmt(p, nkImportStmt)
  of tkFrom: result = parseFromStmt(p)
  of tkInclude: result = parseImportOrIncludeStmt(p, nkIncludeStmt)
  of tkComment: result = newCommentStmt(p)
  else: 
    if isExprStart(p): result = parseExprStmt(p)
    else: result = nil
  if result != nil: skipComment(p, result)
  
proc complexOrSimpleStmt(p: var TParser): PNode = 
  case p.tok.tokType
  of tkIf: result = parseIfOrWhen(p, nkIfStmt)
  of tkWhile: result = parseWhile(p)
  of tkCase: result = parseCase(p)
  of tkTry: result = parseTry(p)
  of tkFor: result = parseFor(p)
  of tkBlock: result = parseBlock(p)
  of tkAsm: result = parseAsm(p)
  of tkProc: result = parseRoutine(p, nkProcDef)
  of tkMethod: result = parseRoutine(p, nkMethodDef)
  of tkIterator: result = parseRoutine(p, nkIteratorDef)
  of tkMacro: result = parseRoutine(p, nkMacroDef)
  of tkTemplate: result = parseRoutine(p, nkTemplateDef)
  of tkConverter: result = parseRoutine(p, nkConverterDef)
  of tkType: result = parseSection(p, nkTypeSection, parseTypeDef)
  of tkConst: result = parseSection(p, nkConstSection, parseConstant)
  of tkWhen: result = parseIfOrWhen(p, nkWhenStmt)
  of tkVar: result = parseSection(p, nkVarSection, parseVariable)
  else: result = simpleStmt(p)
  
proc parseStmt(p: var TParser): PNode = 
  var a: PNode
  if p.tok.tokType == tkInd: 
    result = newNodeP(nkStmtList, p)
    pushInd(p.lex^ , p.tok.indent)
    getTok(p)
    while true: 
      case p.tok.tokType
      of tkSad: getTok(p)
      of tkEof: break 
      of tkDed: 
        getTok(p)
        break 
      else: 
        a = complexOrSimpleStmt(p)
        if a == nil: break 
        addSon(result, a)
    popInd(p.lex^ )
  else: 
    # the case statement is only needed for better error messages:
    case p.tok.tokType
    of tkIf, tkWhile, tkCase, tkTry, tkFor, tkBlock, tkAsm, tkProc, tkIterator, 
       tkMacro, tkType, tkConst, tkWhen, tkVar: 
      parMessage(p, errComplexStmtRequiresInd)
      result = nil
    else: 
      result = simpleStmt(p)
      if result == nil: parMessage(p, errExprExpected, tokToStr(p.tok))
      if p.tok.tokType == tkSad: getTok(p)
  
proc parseAll(p: var TParser): PNode = 
  var a: PNode
  result = newNodeP(nkStmtList, p)
  while true: 
    case p.tok.tokType
    of tkSad: getTok(p)
    of tkDed, tkInd: parMessage(p, errInvalidIndentation)
    of tkEof: break 
    else: 
      a = complexOrSimpleStmt(p)
      if a == nil: parMessage(p, errExprExpected, tokToStr(p.tok))
      addSon(result, a)

proc parseTopLevelStmt(p: var TParser): PNode = 
  result = nil
  while true: 
    case p.tok.tokType
    of tkSad: getTok(p)
    of tkDed, tkInd: 
      parMessage(p, errInvalidIndentation)
      break 
    of tkEof: break 
    else: 
      result = complexOrSimpleStmt(p)
      if result == nil: parMessage(p, errExprExpected, tokToStr(p.tok))
      break 
