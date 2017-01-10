#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the parser of the braces Nim syntax.

import
  llstream, lexer, idents, strutils, ast, astalgo, msgs

from parser import TParser

proc getTok(p: var TParser) =
  ## Get the next token from the parser's lexer, and store it in the parser's
  ## `tok` member.
  rawGetTok(p.lex, p.tok)

proc openParser*(p: var TParser, fileIdx: int32, inputStream: PLLStream;
                 cache: IdentCache) =
  ## Open a parser, using the given arguments to set up its internal state.
  ##
  initToken(p.tok)
  openLexer(p.lex, fileIdx, inputStream, cache)
  getTok(p)                   # read the first token
  p.lex.allowTabs = true

proc openParser*(p: var TParser, filename: string, inputStream: PLLStream;
                 cache: IdentCache) =
  openParser(p, filename.fileInfoIdx, inputStream, cache)

proc closeParser*(p: var TParser) =
  ## Close a parser, freeing up its resources.
  closeLexer(p.lex)

proc parMessage(p: TParser, msg: TMsgKind, arg = "") =
  ## Produce and emit the parser message `arg` to output.
  lexMessageTok(p.lex, msg, p.tok, arg)

proc parMessage(p: TParser, msg: TMsgKind, tok: TToken) =
  ## Produce and emit a parser message to output about the token `tok`
  parMessage(p, msg, prettyTok(tok))

proc rawSkipComment(p: var TParser, node: PNode) =
  if p.tok.tokType == tkComment:
    if node != nil:
      if node.comment == nil: node.comment = ""
      add(node.comment, p.tok.literal)
    else:
      parMessage(p, errInternal, "skipComment")
    getTok(p)

proc skipComment(p: var TParser, node: PNode) =
  rawSkipComment(p, node)

proc flexComment(p: var TParser, node: PNode) =
  rawSkipComment(p, node)

proc skipInd(p: var TParser) = discard
proc optPar(p: var TParser) = discard

proc optInd(p: var TParser, n: PNode) =
  skipComment(p, n)

proc getTokNoInd(p: var TParser) =
  getTok(p)

proc expectIdentOrKeyw(p: TParser) =
  if p.tok.tokType != tkSymbol and not isKeyword(p.tok.tokType):
    lexMessage(p.lex, errIdentifierExpected, prettyTok(p.tok))

proc expectIdent(p: TParser) =
  if p.tok.tokType != tkSymbol:
    lexMessage(p.lex, errIdentifierExpected, prettyTok(p.tok))

proc eat(p: var TParser, tokType: TTokType) =
  ## Move the parser to the next token if the current token is of type
  ## `tokType`, otherwise error.
  if p.tok.tokType == tokType:
    getTok(p)
  else:
    lexMessageTok(p.lex, errTokenExpected, p.tok, TokTypeToStr[tokType])

proc parLineInfo(p: TParser): TLineInfo =
  ## Retrieve the line information associated with the parser's current state.
  result = getLineInfo(p.lex, p.tok)

proc indAndComment(p: var TParser, n: PNode) =
  rawSkipComment(p, n)

proc newNodeP(kind: TNodeKind, p: TParser): PNode =
  result = newNodeI(kind, parLineInfo(p))

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
proc parseStmtPragma(p: var TParser): PNode
proc parseCase(p: var TParser): PNode
proc parseTry(p: var TParser): PNode

proc isSigilLike(tok: TToken): bool {.inline.} =
  result = tok.tokType == tkOpr and tok.ident.s[0] == '@'

proc isAt(tok: TToken): bool {.inline.} =
  tok.tokType == tkOpr and tok.ident.s == "@" and tok.strongSpaceB == 0

proc isRightAssociative(tok: TToken): bool {.inline.} =
  ## Determines whether the token is right assocative.
  result = tok.tokType == tkOpr and tok.ident.s[0] == '^'
  # or (let L = tok.ident.s.len; L > 1 and tok.ident.s[L-1] == '>'))

proc getPrecedence(tok: TToken): int =
  ## Calculates the precedence of the given token.
  template considerStrongSpaces(x): untyped = x

  case tok.tokType
  of tkOpr:
    let L = tok.ident.s.len
    let relevantChar = tok.ident.s[0]

    # arrow like?
    if L > 1 and tok.ident.s[L-1] == '>' and
      tok.ident.s[L-2] in {'-', '~', '='}: return considerStrongSpaces(1)

    template considerAsgn(value: untyped) =
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
  of tkIn, tkNotin, tkIs, tkIsnot, tkNot, tkOf, tkAs: result = 5
  of tkDotDot: result = 6
  of tkAnd: result = 4
  of tkOr, tkXor, tkPtr, tkRef: result = 3
  else: return -10
  result = considerStrongSpaces(result)

proc isOperator(tok: TToken): bool =
  ## Determines if the given token is an operator type token.
  tok.tokType in {tkOpr, tkDiv, tkMod, tkShl, tkShr, tkIn, tkNotin, tkIs,
                  tkIsnot, tkNot, tkOf, tkAs, tkDotDot, tkAnd, tkOr, tkXor}

proc isUnary(p: TParser): bool =
  ## Check if the current parser token is a unary operator
  if p.tok.tokType in {tkOpr, tkDotDot}:
      result = true

proc checkBinary(p: TParser) {.inline.} =
  ## Check if the current parser token is a binary operator.
  # we don't check '..' here as that's too annoying
  discard

#| module = stmt ^* (';' / IND{=})
#|
#| comma = ',' COMMENT?
#| semicolon = ';' COMMENT?
#| colon = ':' COMMENT?
#| colcom = ':' COMMENT?
#|
#| operator =  OP0 | OP1 | OP2 | OP3 | OP4 | OP5 | OP6 | OP7 | OP8 | OP9
#|          | 'or' | 'xor' | 'and'
#|          | 'is' | 'isnot' | 'in' | 'notin' | 'of'
#|          | 'div' | 'mod' | 'shl' | 'shr' | 'not' | 'static' | '..'
#|
#| prefixOperator = operator
#|
#| optInd = COMMENT?
#| optPar = (IND{>} | IND{=})?
#|
#| simpleExpr = arrowExpr (OP0 optInd arrowExpr)*
#| arrowExpr = assignExpr (OP1 optInd assignExpr)*
#| assignExpr = orExpr (OP2 optInd orExpr)*
#| orExpr = andExpr (OP3 optInd andExpr)*
#| andExpr = cmpExpr (OP4 optInd cmpExpr)*
#| cmpExpr = sliceExpr (OP5 optInd sliceExpr)*
#| sliceExpr = ampExpr (OP6 optInd ampExpr)*
#| ampExpr = plusExpr (OP7 optInd plusExpr)*
#| plusExpr = mulExpr (OP8 optInd mulExpr)*
#| mulExpr = dollarExpr (OP9 optInd dollarExpr)*
#| dollarExpr = primary (OP10 optInd primary)*

proc colcom(p: var TParser, n: PNode) =
  skipComment(p, n)

proc parseSymbol(p: var TParser, allowNil = false): PNode =
  #| symbol = '`' (KEYW|IDENT|literal|(operator|'('|')'|'['|']'|'{'|'}'|'=')+)+ '`'
  #|        | IDENT | 'addr' | 'type'
  case p.tok.tokType
  of tkSymbol, tkAddr, tkType:
    result = newIdentNodeP(p.tok.ident, p)
    getTok(p)
  of tkAccent:
    result = newNodeP(nkAccQuoted, p)
    getTok(p)
    while true:
      case p.tok.tokType
      of tkAccent:
        if result.len == 0:
          parMessage(p, errIdentifierExpected, p.tok)
        break
      of tkOpr, tkDot, tkDotDot, tkEquals, tkParLe..tkParDotRi:
        var accm = ""
        while p.tok.tokType in {tkOpr, tkDot, tkDotDot, tkEquals,
                                tkParLe..tkParDotRi}:
          accm.add(tokToStr(p.tok))
          getTok(p)
        result.add(newIdentNodeP(p.lex.cache.getIdent(accm), p))
      of tokKeywordLow..tokKeywordHigh, tkSymbol, tkIntLit..tkCharLit:
        result.add(newIdentNodeP(p.lex.cache.getIdent(tokToStr(p.tok)), p))
        getTok(p)
      else:
        parMessage(p, errIdentifierExpected, p.tok)
        break
    eat(p, tkAccent)
  else:
    if allowNil and p.tok.tokType == tkNil:
      result = newNodeP(nkNilLit, p)
      getTok(p)
    else:
      parMessage(p, errIdentifierExpected, p.tok)
      # BUGFIX: We must consume a token here to prevent endless loops!
      # But: this really sucks for idetools and keywords, so we don't do it
      # if it is a keyword:
      if not isKeyword(p.tok.tokType): getTok(p)
      result = ast.emptyNode

proc colonOrEquals(p: var TParser, a: PNode): PNode =
  if p.tok.tokType == tkColon:
    result = newNodeP(nkExprColonExpr, p)
    getTok(p)
    #optInd(p, result)
    addSon(result, a)
    addSon(result, parseExpr(p))
  elif p.tok.tokType == tkEquals:
    result = newNodeP(nkExprEqExpr, p)
    getTok(p)
    #optInd(p, result)
    addSon(result, a)
    addSon(result, parseExpr(p))
  else:
    result = a

proc exprColonEqExpr(p: var TParser): PNode =
  #| exprColonEqExpr = expr (':'|'=' expr)?
  var a = parseExpr(p)
  result = colonOrEquals(p, a)

proc exprList(p: var TParser, endTok: TTokType, result: PNode) =
  #| exprList = expr ^+ comma
  getTok(p)
  optInd(p, result)
  while (p.tok.tokType != endTok) and (p.tok.tokType != tkEof):
    var a = parseExpr(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break
    getTok(p)
    optInd(p, a)

proc dotExpr(p: var TParser, a: PNode): PNode =
  #| dotExpr = expr '.' optInd symbol
  var info = p.parLineInfo
  getTok(p)
  result = newNodeI(nkDotExpr, info)
  optInd(p, result)
  addSon(result, a)
  addSon(result, parseSymbol(p))

proc qualifiedIdent(p: var TParser): PNode =
  #| qualifiedIdent = symbol ('.' optInd symbol)?
  result = parseSymbol(p)
  if p.tok.tokType == tkDot: result = dotExpr(p, result)

proc exprColonEqExprListAux(p: var TParser, endTok: TTokType, result: PNode) =
  assert(endTok in {tkCurlyLe, tkCurlyRi, tkCurlyDotRi, tkBracketRi, tkParRi})
  getTok(p)
  optInd(p, result)
  while p.tok.tokType != endTok and p.tok.tokType != tkEof:
    var a = exprColonEqExpr(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break
    getTok(p)
    skipComment(p, a)
  optPar(p)
  eat(p, endTok)

proc exprColonEqExprList(p: var TParser, kind: TNodeKind,
                         endTok: TTokType): PNode =
  #| exprColonEqExprList = exprColonEqExpr (comma exprColonEqExpr)* (comma)?
  result = newNodeP(kind, p)
  exprColonEqExprListAux(p, endTok, result)

proc setOrTableConstr(p: var TParser): PNode =
  result = newNodeP(nkCurly, p)
  getTok(p)
  optInd(p, result)
  if p.tok.tokType == tkColon:
    getTok(p) # skip ':'
    result.kind = nkTableConstr
  else:
    while p.tok.tokType notin {tkBracketDotRi, tkEof}:
      var a = exprColonEqExpr(p)
      if a.kind == nkExprColonExpr: result.kind = nkTableConstr
      addSon(result, a)
      if p.tok.tokType != tkComma: break
      getTok(p)
      skipComment(p, a)
  optPar(p)
  eat(p, tkBracketDotRi)

proc parseCast(p: var TParser): PNode =
  #| castExpr = 'cast' '[' optInd typeDesc optPar ']' '(' optInd expr optPar ')'
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

proc setBaseFlags(n: PNode, base: TNumericalBase) =
  case base
  of base10: discard
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

type
  TPrimaryMode = enum pmNormal, pmTypeDesc, pmTypeDef, pmSkipSuffix

proc complexOrSimpleStmt(p: var TParser): PNode
proc simpleExpr(p: var TParser, mode = pmNormal): PNode

proc semiStmtList(p: var TParser, result: PNode) =
  inc p.inSemiStmtList
  result.add(complexOrSimpleStmt(p))
  while p.tok.tokType == tkSemiColon:
    getTok(p)
    optInd(p, result)
    result.add(complexOrSimpleStmt(p))
  dec p.inSemiStmtList
  result.kind = nkStmtListExpr

proc parsePar(p: var TParser): PNode =
  #| parKeyw = 'discard' | 'include' | 'if' | 'while' | 'case' | 'try'
  #|         | 'finally' | 'except' | 'for' | 'block' | 'const' | 'let'
  #|         | 'when' | 'var' | 'mixin'
  #| par = '(' optInd
  #|           ( &parKeyw complexOrSimpleStmt ^+ ';'
  #|           | ';' complexOrSimpleStmt ^+ ';'
  #|           | pragmaStmt
  #|           | simpleExpr ( ('=' expr (';' complexOrSimpleStmt ^+ ';' )? )
  #|                        | (':' expr (',' exprColonEqExpr     ^+ ',' )? ) ) )
  #|           optPar ')'
  #
  # unfortunately it's ambiguous: (expr: expr) vs (exprStmt); however a
  # leading ';' could be used to enforce a 'stmt' context ...
  result = newNodeP(nkPar, p)
  getTok(p)
  optInd(p, result)
  if p.tok.tokType in {tkDiscard, tkInclude, tkIf, tkWhile, tkCase,
                       tkTry, tkDefer, tkFinally, tkExcept, tkFor, tkBlock,
                       tkConst, tkLet, tkWhen, tkVar,
                       tkMixin}:
    # XXX 'bind' used to be an expression, so we exclude it here;
    # tests/reject/tbind2 fails otherwise.
    semiStmtList(p, result)
  elif p.tok.tokType == tkSemiColon:
    # '(;' enforces 'stmt' context:
    getTok(p)
    optInd(p, result)
    semiStmtList(p, result)
  elif p.tok.tokType == tkCurlyDotLe:
    result.add(parseStmtPragma(p))
  elif p.tok.tokType != tkParRi:
    var a = simpleExpr(p)
    if p.tok.tokType == tkEquals:
      # special case: allow assignments
      getTok(p)
      optInd(p, result)
      let b = parseExpr(p)
      let asgn = newNodeI(nkAsgn, a.info, 2)
      asgn.sons[0] = a
      asgn.sons[1] = b
      result.add(asgn)
      if p.tok.tokType == tkSemiColon:
        semiStmtList(p, result)
    elif p.tok.tokType == tkSemiColon:
      # stmt context:
      result.add(a)
      semiStmtList(p, result)
    else:
      a = colonOrEquals(p, a)
      result.add(a)
      if p.tok.tokType == tkComma:
        getTok(p)
        skipComment(p, a)
        while p.tok.tokType != tkParRi and p.tok.tokType != tkEof:
          var a = exprColonEqExpr(p)
          addSon(result, a)
          if p.tok.tokType != tkComma: break
          getTok(p)
          skipComment(p, a)
  optPar(p)
  eat(p, tkParRi)

proc identOrLiteral(p: var TParser, mode: TPrimaryMode): PNode =
  #| literal = | INT_LIT | INT8_LIT | INT16_LIT | INT32_LIT | INT64_LIT
  #|           | UINT_LIT | UINT8_LIT | UINT16_LIT | UINT32_LIT | UINT64_LIT
  #|           | FLOAT_LIT | FLOAT32_LIT | FLOAT64_LIT
  #|           | STR_LIT | RSTR_LIT | TRIPLESTR_LIT
  #|           | CHAR_LIT
  #|           | NIL
  #| generalizedLit = GENERALIZED_STR_LIT | GENERALIZED_TRIPLESTR_LIT
  #| identOrLiteral = generalizedLit | symbol | literal
  #|                | par | arrayConstr | setOrTableConstr
  #|                | castExpr
  #| tupleConstr = '(' optInd (exprColonEqExpr comma?)* optPar ')'
  #| arrayConstr = '[' optInd (exprColonEqExpr comma?)* optPar ']'
  case p.tok.tokType
  of tkSymbol, tkType, tkAddr:
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
    if mode in {pmTypeDesc, pmTypeDef}:
      result = exprColonEqExprList(p, nkPar, tkParRi)
    else:
      result = parsePar(p)
  of tkBracketDotLe:
    # {} constructor
    result = setOrTableConstr(p)
  of tkBracketLe:
    # [] constructor
    result = exprColonEqExprList(p, nkBracket, tkBracketRi)
  of tkCast:
    result = parseCast(p)
  else:
    parMessage(p, errExprExpected, p.tok)
    getTok(p)  # we must consume a token here to prevend endless loops!
    result = ast.emptyNode

proc namedParams(p: var TParser, callee: PNode,
                 kind: TNodeKind, endTok: TTokType): PNode =
  let a = callee
  result = newNodeP(kind, p)
  addSon(result, a)
  exprColonEqExprListAux(p, endTok, result)

proc parseMacroColon(p: var TParser, x: PNode): PNode
proc primarySuffix(p: var TParser, r: PNode): PNode =
  #| primarySuffix = '(' (exprColonEqExpr comma?)* ')' doBlocks?
  #|       | doBlocks
  #|       | '.' optInd symbol generalizedLit?
  #|       | '[' optInd indexExprList optPar ']'
  #|       | '{' optInd indexExprList optPar '}'
  #|       | &( '`'|IDENT|literal|'cast'|'addr'|'type') expr # command syntax
  result = r

  template somePar() = discard
  while p.tok.indent < 0:
    case p.tok.tokType
    of tkParLe:
      somePar()
      result = namedParams(p, result, nkCall, tkParRi)
      if result.len > 1 and result.sons[1].kind == nkExprColonExpr:
        result.kind = nkObjConstr
      else:
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
      somePar()
      result = namedParams(p, result, nkBracketExpr, tkBracketRi)
    of tkBracketDotLe:
      somePar()
      result = namedParams(p, result, nkCurlyExpr, tkBracketDotRi)
    of tkSymbol, tkAccent, tkIntLit..tkCharLit, tkNil, tkCast, tkAddr, tkType:
      if p.inPragma == 0:
        # actually parsing {.push hints:off.} as {.push(hints:off).} is a sweet
        # solution, but pragmas.nim can't handle that
        let a = result
        result = newNodeP(nkCommand, p)
        addSon(result, a)
        when true:
          addSon result, parseExpr(p)
        else:
          while p.tok.tokType != tkEof:
            let x = parseExpr(p)
            addSon(result, x)
            if p.tok.tokType != tkComma: break
            getTok(p)
            optInd(p, x)
          if p.tok.tokType == tkDo:
            parseDoBlocks(p, result)
          else:
            result = parseMacroColon(p, result)
      break
    else:
      break

proc primary(p: var TParser, mode: TPrimaryMode): PNode
proc simpleExprAux(p: var TParser, limit: int, mode: TPrimaryMode): PNode

proc parseOperators(p: var TParser, headNode: PNode,
                    limit: int, mode: TPrimaryMode): PNode =
  result = headNode
  # expand while operators have priorities higher than 'limit'
  var opPrec = getPrecedence(p.tok)
  let modeB = if mode == pmTypeDef: pmTypeDesc else: mode
  # the operator itself must not start on a new line:
  while opPrec >= limit and p.tok.indent < 0 and not isAt(p.tok):
    checkBinary(p)
    var leftAssoc = 1-ord(isRightAssociative(p.tok))
    var a = newNodeP(nkInfix, p)
    var opNode = newIdentNodeP(p.tok.ident, p) # skip operator:
    getTok(p)
    optInd(p, a)
    # read sub-expression with higher priority:
    var b = simpleExprAux(p, opPrec + leftAssoc, modeB)
    addSon(a, opNode)
    addSon(a, result)
    addSon(a, b)
    result = a
    opPrec = getPrecedence(p.tok)

proc simpleExprAux(p: var TParser, limit: int, mode: TPrimaryMode): PNode =
  result = primary(p, mode)
  result = parseOperators(p, result, limit, mode)

proc simpleExpr(p: var TParser, mode = pmNormal): PNode =
  result = simpleExprAux(p, -1, mode)

proc parseIfExpr(p: var TParser, kind: TNodeKind): PNode =
  #| condExpr = expr colcom expr optInd
  #|         ('elif' expr colcom expr optInd)*
  #|          'else' colcom expr
  #| ifExpr = 'if' condExpr
  #| whenExpr = 'when' condExpr
  result = newNodeP(kind, p)
  while true:
    getTok(p)                 # skip `if`, `elif`
    var branch = newNodeP(nkElifExpr, p)
    addSon(branch, parseExpr(p))
    colcom(p, branch)
    addSon(branch, parseExpr(p))
    optInd(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break
  var branch = newNodeP(nkElseExpr, p)
  eat(p, tkElse)
  colcom(p, branch)
  addSon(branch, parseExpr(p))
  addSon(result, branch)

proc parsePragma(p: var TParser): PNode =
  result = newNodeP(nkPragma, p)
  inc p.inPragma
  if isAt(p.tok):
    while isAt(p.tok):
      getTok(p)
      var a = parseExpr(p)
      optInd(p, a)
      if a.kind in nkCallKinds and a.len == 2:
        let repaired = newNodeI(nkExprColonExpr, a.info)
        repaired.add a[0]
        repaired.add a[1]
        a = repaired
      addSon(result, a)
      skipComment(p, a)
  else:
    getTok(p)
    optInd(p, result)
    while p.tok.tokType notin {tkCurlyDotRi, tkCurlyRi, tkEof}:
      var a = exprColonEqExpr(p)
      addSon(result, a)
      if p.tok.tokType == tkComma:
        getTok(p)
        skipComment(p, a)
    optPar(p)
    if p.tok.tokType in {tkCurlyDotRi, tkCurlyRi}: getTok(p)
    else: parMessage(p, errTokenExpected, ".}")
  dec p.inPragma

proc identVis(p: var TParser; allowDot=false): PNode =
  #| identVis = symbol opr?  # postfix position
  #| identVisDot = symbol '.' optInd symbol opr?
  var a = parseSymbol(p)
  if p.tok.tokType == tkOpr:
    result = newNodeP(nkPostfix, p)
    addSon(result, newIdentNodeP(p.tok.ident, p))
    addSon(result, a)
    getTok(p)
  elif p.tok.tokType == tkDot and allowDot:
    result = dotExpr(p, a)
  else:
    result = a

proc identWithPragma(p: var TParser; allowDot=false): PNode =
  #| identWithPragma = identVis pragma?
  #| identWithPragmaDot = identVisDot pragma?
  var a = identVis(p, allowDot)
  if p.tok.tokType == tkCurlyDotLe or isAt(p.tok):
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
  #| declColonEquals = identWithPragma (comma identWithPragma)* comma?
  #|                   (':' optInd typeDesc)? ('=' optInd expr)?
  #| identColonEquals = ident (comma ident)* comma?
  #|      (':' optInd typeDesc)? ('=' optInd expr)?)
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
    if p.tok.tokType != tkEquals and withBothOptional notin flags:
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
  if p.tok.tokType in {tkBracketLe, tkCurlyLe}:
    let usedCurly = p.tok.tokType == tkCurlyLe
    getTok(p)
    optInd(p, result)
    while p.tok.tokType in {tkSymbol, tkAccent}:
      var a = parseIdentColonEquals(p, {})
      addSon(result, a)
      if p.tok.tokType notin {tkComma, tkSemiColon}: break
      getTok(p)
      skipComment(p, a)
    optPar(p)
    if usedCurly: eat(p, tkCurlyRi)
    else: eat(p, tkBracketRi)
  else:
    result = newNodeP(nkTupleClassTy, p)

proc parseParamList(p: var TParser, retColon = true): PNode =
  #| paramList = '(' declColonEquals ^* (comma/semicolon) ')'
  #| paramListArrow = paramList? ('->' optInd typeDesc)?
  #| paramListColon = paramList? (':' optInd typeDesc)?
  var a: PNode
  result = newNodeP(nkFormalParams, p)
  addSon(result, ast.emptyNode) # return type
  let hasParLe = p.tok.tokType == tkParLe and p.tok.indent < 0
  if hasParLe:
    getTok(p)
    optInd(p, result)
    while true:
      case p.tok.tokType
      of tkSymbol, tkAccent:
        a = parseIdentColonEquals(p, {withBothOptional, withPragma})
      of tkParRi:
        break
      else:
        parMessage(p, errTokenExpected, ")")
        break
      addSon(result, a)
      if p.tok.tokType notin {tkComma, tkSemiColon}: break
      getTok(p)
      skipComment(p, a)
    optPar(p)
    eat(p, tkParRi)
  let hasRet = if retColon: p.tok.tokType == tkColon
               else: p.tok.tokType == tkOpr and p.tok.ident.s == "->"
  if hasRet and p.tok.indent < 0:
    getTok(p)
    optInd(p, result)
    result.sons[0] = parseTypeDesc(p)
  elif not retColon and not hasParle:
    # Mark as "not there" in order to mark for deprecation in the semantic pass:
    result = ast.emptyNode

proc optPragmas(p: var TParser): PNode =
  if p.tok.tokType == tkCurlyDotLe or isAt(p.tok):
    result = parsePragma(p)
  else:
    result = ast.emptyNode

proc parseDoBlock(p: var TParser): PNode =
  #| doBlock = 'do' paramListArrow pragmas? colcom stmt
  let info = parLineInfo(p)
  getTok(p)
  let params = parseParamList(p, retColon=false)
  let pragmas = optPragmas(p)
  colcom(p, result)
  result = newProcNode(nkDo, info, parseStmt(p),
                       params = params,
                       pragmas = pragmas)

proc parseDoBlocks(p: var TParser, call: PNode) =
  #| doBlocks = doBlock ^* IND{=}
  while p.tok.tokType == tkDo:
    addSon(call, parseDoBlock(p))

proc parseCurlyStmt(p: var TParser): PNode =
  result = newNodeP(nkStmtList, p)
  eat(p, tkCurlyLe)
  result.add parseStmt(p)
  while p.tok.tokType notin {tkEof, tkCurlyRi}:
    if p.tok.tokType == tkSemicolon: getTok(p)
    elif p.tok.indent < 0: break
    result.add parseStmt(p)
  eat(p, tkCurlyRi)

proc parseProcExpr(p: var TParser, isExpr: bool): PNode =
  #| procExpr = 'proc' paramListColon pragmas? ('=' COMMENT? stmt)?
  # either a proc type or a anonymous proc
  let info = parLineInfo(p)
  getTok(p)
  let hasSignature = p.tok.tokType in {tkParLe, tkColon} and p.tok.indent < 0
  let params = parseParamList(p)
  let pragmas = optPragmas(p)
  if p.tok.tokType == tkCurlyLe and isExpr:
    result = newProcNode(nkLambda, info, parseCurlyStmt(p),
                         params = params,
                         pragmas = pragmas)
  else:
    result = newNodeI(nkProcTy, info)
    if hasSignature:
      addSon(result, params)
      addSon(result, pragmas)

proc isExprStart(p: TParser): bool =
  case p.tok.tokType
  of tkSymbol, tkAccent, tkOpr, tkNot, tkNil, tkCast, tkIf,
     tkProc, tkIterator, tkBind, tkAddr,
     tkParLe, tkBracketLe, tkCurlyLe, tkIntLit..tkCharLit, tkVar, tkRef, tkPtr,
     tkTuple, tkObject, tkType, tkWhen, tkCase, tkOut:
    result = true
  else: result = false

proc parseSymbolList(p: var TParser, result: PNode, allowNil = false) =
  while true:
    var s = parseSymbol(p, allowNil)
    if s.kind == nkEmpty: break
    addSon(result, s)
    if p.tok.tokType != tkComma: break
    getTok(p)
    optInd(p, s)

proc parseTypeDescKAux(p: var TParser, kind: TNodeKind,
                       mode: TPrimaryMode): PNode =
  #| distinct = 'distinct' optInd typeDesc
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  if not isOperator(p.tok) and isExprStart(p):
    addSon(result, primary(p, mode))
  if kind == nkDistinctTy and p.tok.tokType in {tkWith, tkWithout}:
    let nodeKind = if p.tok.tokType == tkWith: nkWith
                   else: nkWithout
    getTok(p)
    let list = newNodeP(nodeKind, p)
    result.addSon list
    parseSymbolList(p, list, allowNil = true)

proc parseExpr(p: var TParser): PNode =
  #| expr = (ifExpr
  #|       | whenExpr
  #|       | caseExpr
  #|       | tryExpr)
  #|       / simpleExpr
  case p.tok.tokType:
  of tkIf: result = parseIfExpr(p, nkIfExpr)
  of tkWhen: result = parseIfExpr(p, nkWhenExpr)
  of tkCase: result = parseCase(p)
  of tkTry: result = parseTry(p)
  else: result = simpleExpr(p)

proc parseEnum(p: var TParser): PNode
proc parseObject(p: var TParser): PNode
proc parseTypeClass(p: var TParser): PNode

proc primary(p: var TParser, mode: TPrimaryMode): PNode =
  #| typeKeyw = 'var' | 'out' | 'ref' | 'ptr' | 'shared' | 'tuple'
  #|          | 'proc' | 'iterator' | 'distinct' | 'object' | 'enum'
  #| primary = typeKeyw typeDescK
  #|         /  prefixOperator* identOrLiteral primarySuffix*
  #|         / 'static' primary
  #|         / 'bind' primary
  if isOperator(p.tok):
    let isSigil = isSigilLike(p.tok)
    result = newNodeP(nkPrefix, p)
    var a = newIdentNodeP(p.tok.ident, p)
    addSon(result, a)
    getTok(p)
    optInd(p, a)
    if isSigil:
      #XXX prefix operators
      addSon(result, primary(p, pmSkipSuffix))
      result = primarySuffix(p, result)
    else:
      addSon(result, primary(p, pmNormal))
    return

  case p.tok.tokType:
  of tkTuple: result = parseTuple(p)
  of tkProc: result = parseProcExpr(p, mode notin {pmTypeDesc, pmTypeDef})
  of tkIterator:
    result = parseProcExpr(p, mode notin {pmTypeDesc, pmTypeDef})
    if result.kind == nkLambda: result.kind = nkIteratorDef
    else: result.kind = nkIteratorTy
  of tkEnum:
    if mode == pmTypeDef:
      result = parseEnum(p)
    else:
      result = newNodeP(nkEnumTy, p)
      getTok(p)
  of tkObject:
    if mode == pmTypeDef:
      result = parseObject(p)
    else:
      result = newNodeP(nkObjectTy, p)
      getTok(p)
  of tkConcept:
    if mode == pmTypeDef:
      result = parseTypeClass(p)
    else:
      parMessage(p, errInvalidToken, p.tok)
  of tkStatic:
    let info = parLineInfo(p)
    getTokNoInd(p)
    let next = primary(p, pmNormal)
    if next.kind == nkBracket and next.sonsLen == 1:
      result = newNode(nkStaticTy, info, @[next.sons[0]])
    else:
      result = newNode(nkStaticExpr, info, @[next])
  of tkBind:
    result = newNodeP(nkBind, p)
    getTok(p)
    optInd(p, result)
    addSon(result, primary(p, pmNormal))
  of tkVar: result = parseTypeDescKAux(p, nkVarTy, mode)
  of tkOut: result = parseTypeDescKAux(p, nkVarTy, mode)
  of tkRef: result = parseTypeDescKAux(p, nkRefTy, mode)
  of tkPtr: result = parseTypeDescKAux(p, nkPtrTy, mode)
  of tkDistinct: result = parseTypeDescKAux(p, nkDistinctTy, mode)
  else:
    result = identOrLiteral(p, mode)
    if mode != pmSkipSuffix:
      result = primarySuffix(p, result)

proc parseTypeDesc(p: var TParser): PNode =
  #| typeDesc = simpleExpr
  result = simpleExpr(p, pmTypeDesc)

proc parseTypeDefAux(p: var TParser): PNode =
  #| typeDefAux = simpleExpr
  #|            | 'concept' typeClass
  result = simpleExpr(p, pmTypeDef)

proc makeCall(n: PNode): PNode =
  ## Creates a call if the given node isn't already a call.
  if n.kind in nkCallKinds:
    result = n
  else:
    result = newNodeI(nkCall, n.info)
    result.add n

proc parseMacroColon(p: var TParser, x: PNode): PNode =
  #| macroColon = ':' stmt? ( IND{=} 'of' exprList ':' stmt
  #|                        | IND{=} 'elif' expr ':' stmt
  #|                        | IND{=} 'except' exprList ':' stmt
  #|                        | IND{=} 'else' ':' stmt )*
  result = x
  if p.tok.tokType == tkColon and p.tok.indent < 0:
    result = makeCall(result)
    getTok(p)
    skipComment(p, result)
    let stmtList = newNodeP(nkStmtList, p)
    if p.tok.tokType notin {tkOf, tkElif, tkElse, tkExcept}:
      let body = parseStmt(p)
      stmtList.add body
      #addSon(result, makeStmtList(body))
    while true:
      var b: PNode
      case p.tok.tokType
      of tkOf:
        b = newNodeP(nkOfBranch, p)
        exprList(p, tkCurlyLe, b)
      of tkElif:
        b = newNodeP(nkElifBranch, p)
        getTok(p)
        optInd(p, b)
        addSon(b, parseExpr(p))
      of tkExcept:
        b = newNodeP(nkExceptBranch, p)
        exprList(p, tkCurlyLe, b)
      of tkElse:
        b = newNodeP(nkElse, p)
        getTok(p)
      else: break
      addSon(b, parseCurlyStmt(p))
      addSon(stmtList, b)
      if b.kind == nkElse: break
    if stmtList.len == 1 and stmtList[0].kind == nkStmtList:
      # to keep backwards compatibility (see tests/vm/tstringnil)
      result.add stmtList[0]
    else:
      result.add stmtList

proc parseExprStmt(p: var TParser): PNode =
  #| exprStmt = simpleExpr
  #|          (( '=' optInd expr )
  #|          / ( expr ^+ comma
  #|              doBlocks
  #|               / macroColon
  #|            ))?
  var a = simpleExpr(p)
  if p.tok.tokType == tkEquals:
    getTok(p)
    optInd(p, result)
    var b = parseExpr(p)
    result = newNodeI(nkAsgn, a.info)
    addSon(result, a)
    addSon(result, b)
  else:
    # simpleExpr parsed 'p a' from 'p a, b'?
    if p.tok.indent < 0 and p.tok.tokType == tkComma and a.kind == nkCommand:
      result = a
      while true:
        getTok(p)
        optInd(p, result)
        var e = parseExpr(p)
        addSon(result, e)
        if p.tok.tokType != tkComma: break
    elif p.tok.indent < 0 and isExprStart(p):
      if a.kind == nkCommand:
        result = a
      else:
        result = newNode(nkCommand, a.info, @[a])
      while true:
        var e = parseExpr(p)
        addSon(result, e)
        if p.tok.tokType != tkComma: break
        getTok(p)
        optInd(p, result)
    else:
      result = a
    if p.tok.tokType == tkDo and p.tok.indent < 0:
      result = makeCall(result)
      parseDoBlocks(p, result)
      return result
    result = parseMacroColon(p, result)

proc parseModuleName(p: var TParser, kind: TNodeKind): PNode =
  result = parseExpr(p)

proc parseImport(p: var TParser, kind: TNodeKind): PNode =
  #| importStmt = 'import' optInd expr
  #|               ((comma expr)*
  #|               / 'except' optInd (expr ^+ comma))
  result = newNodeP(kind, p)
  getTok(p)                   # skip `import` or `export`
  optInd(p, result)
  var a = parseModuleName(p, kind)
  addSon(result, a)
  if p.tok.tokType in {tkComma, tkExcept}:
    if p.tok.tokType == tkExcept:
      result.kind = succ(kind)
    getTok(p)
    optInd(p, result)
    while true:
      # was: while p.tok.tokType notin {tkEof, tkSad, tkDed}:
      a = parseModuleName(p, kind)
      if a.kind == nkEmpty: break
      addSon(result, a)
      if p.tok.tokType != tkComma: break
      getTok(p)
      optInd(p, a)
  #expectNl(p)

proc parseIncludeStmt(p: var TParser): PNode =
  #| includeStmt = 'include' optInd expr ^+ comma
  result = newNodeP(nkIncludeStmt, p)
  getTok(p)                   # skip `import` or `include`
  optInd(p, result)
  while true:
    # was: while p.tok.tokType notin {tkEof, tkSad, tkDed}:
    var a = parseExpr(p)
    if a.kind == nkEmpty: break
    addSon(result, a)
    if p.tok.tokType != tkComma: break
    getTok(p)
    optInd(p, a)
  #expectNl(p)

proc parseFromStmt(p: var TParser): PNode =
  #| fromStmt = 'from' moduleName 'import' optInd expr (comma expr)*
  result = newNodeP(nkFromStmt, p)
  getTok(p)                   # skip `from`
  optInd(p, result)
  var a = parseModuleName(p, nkImportStmt)
  addSon(result, a)           #optInd(p, a);
  eat(p, tkImport)
  optInd(p, result)
  while true:
    # p.tok.tokType notin {tkEof, tkSad, tkDed}:
    a = parseExpr(p)
    if a.kind == nkEmpty: break
    addSon(result, a)
    if p.tok.tokType != tkComma: break
    getTok(p)
    optInd(p, a)
  #expectNl(p)

proc parseReturnOrRaise(p: var TParser, kind: TNodeKind): PNode =
  #| returnStmt = 'return' optInd expr?
  #| raiseStmt = 'raise' optInd expr?
  #| yieldStmt = 'yield' optInd expr?
  #| discardStmt = 'discard' optInd expr?
  #| breakStmt = 'break' optInd expr?
  #| continueStmt = 'break' optInd expr?
  result = newNodeP(kind, p)
  getTok(p)
  if p.tok.tokType == tkComment:
    skipComment(p, result)
    addSon(result, ast.emptyNode)
  elif p.tok.indent >= 0 or not isExprStart(p):
    # NL terminates:
    addSon(result, ast.emptyNode)
  else:
    addSon(result, parseExpr(p))

proc parseIfOrWhen(p: var TParser, kind: TNodeKind): PNode =
  #| condStmt = expr colcom stmt COMMENT?
  #|            (IND{=} 'elif' expr colcom stmt)*
  #|            (IND{=} 'else' colcom stmt)?
  #| ifStmt = 'if' condStmt
  #| whenStmt = 'when' condStmt
  result = newNodeP(kind, p)
  while true:
    getTok(p)                 # skip `if`, `when`, `elif`
    var branch = newNodeP(nkElifBranch, p)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    colcom(p, branch)
    addSon(branch, parseCurlyStmt(p))
    skipComment(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break
  if p.tok.tokType == tkElse:
    var branch = newNodeP(nkElse, p)
    eat(p, tkElse)
    addSon(branch, parseCurlyStmt(p))
    addSon(result, branch)

proc parseWhile(p: var TParser): PNode =
  #| whileStmt = 'while' expr colcom stmt
  result = newNodeP(nkWhileStmt, p)
  getTok(p)
  optInd(p, result)
  addSon(result, parseExpr(p))
  colcom(p, result)
  addSon(result, parseCurlyStmt(p))

proc parseCase(p: var TParser): PNode =
  #| ofBranch = 'of' exprList colcom stmt
  #| ofBranches = ofBranch (IND{=} ofBranch)*
  #|                       (IND{=} 'elif' expr colcom stmt)*
  #|                       (IND{=} 'else' colcom stmt)?
  #| caseStmt = 'case' expr ':'? COMMENT?
  #|             (IND{>} ofBranches DED
  #|             | IND{=} ofBranches)
  var
    b: PNode
    inElif= false
  result = newNodeP(nkCaseStmt, p)
  getTok(p)
  addSon(result, parseExpr(p))
  eat(p, tkCurlyLe)
  skipComment(p, result)

  while true:
    case p.tok.tokType
    of tkOf:
      if inElif: break
      b = newNodeP(nkOfBranch, p)
      exprList(p, tkCurlyLe, b)
    of tkElif:
      inElif = true
      b = newNodeP(nkElifBranch, p)
      getTok(p)
      optInd(p, b)
      addSon(b, parseExpr(p))
    of tkElse:
      b = newNodeP(nkElse, p)
      getTok(p)
    else: break
    skipComment(p, b)
    addSon(b, parseCurlyStmt(p))
    addSon(result, b)
    if b.kind == nkElse: break
  eat(p, tkCurlyRi)

proc parseTry(p: var TParser): PNode =
  #| tryStmt = 'try' colcom stmt &(IND{=}? 'except'|'finally')
  #|            (IND{=}? 'except' exprList colcom stmt)*
  #|            (IND{=}? 'finally' colcom stmt)?
  #| tryExpr = 'try' colcom stmt &(optInd 'except'|'finally')
  #|            (optInd 'except' exprList colcom stmt)*
  #|            (optInd 'finally' colcom stmt)?
  result = newNodeP(nkTryStmt, p)
  getTok(p)
  colcom(p, result)
  addSon(result, parseCurlyStmt(p))
  var b: PNode = nil
  while true:
    case p.tok.tokType
    of tkExcept:
      b = newNodeP(nkExceptBranch, p)
      exprList(p, tkCurlyLe, b)
    of tkFinally:
      b = newNodeP(nkFinally, p)
      getTok(p)
    else: break
    skipComment(p, b)
    addSon(b, parseCurlyStmt(p))
    addSon(result, b)
    if b.kind == nkFinally: break
  if b == nil: parMessage(p, errTokenExpected, "except")

proc parseFor(p: var TParser): PNode =
  #| forStmt = 'for' (identWithPragma ^+ comma) 'in' expr colcom stmt
  result = newNodeP(nkForStmt, p)
  getTokNoInd(p)
  var a = identWithPragma(p)
  addSon(result, a)
  while p.tok.tokType == tkComma:
    getTok(p)
    optInd(p, a)
    a = identWithPragma(p)
    addSon(result, a)
  eat(p, tkIn)
  addSon(result, parseExpr(p))
  colcom(p, result)
  addSon(result, parseCurlyStmt(p))

proc parseBlock(p: var TParser): PNode =
  #| blockStmt = 'block' symbol? colcom stmt
  result = newNodeP(nkBlockStmt, p)
  getTokNoInd(p)
  if p.tok.tokType == tkCurlyLe: addSon(result, ast.emptyNode)
  else: addSon(result, parseSymbol(p))
  colcom(p, result)
  addSon(result, parseCurlyStmt(p))

proc parseStaticOrDefer(p: var TParser; k: TNodeKind): PNode =
  #| staticStmt = 'static' colcom stmt
  #| deferStmt = 'defer' colcom stmt
  result = newNodeP(k, p)
  getTok(p)
  colcom(p, result)
  addSon(result, parseCurlyStmt(p))

proc parseAsm(p: var TParser): PNode =
  #| asmStmt = 'asm' pragma? (STR_LIT | RSTR_LIT | TRIPLE_STR_LIT)
  result = newNodeP(nkAsmStmt, p)
  getTokNoInd(p)
  if p.tok.tokType == tkCurlyDotLe or isAt(p.tok): addSon(result, parsePragma(p))
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
  #| genericParam = symbol (comma symbol)* (colon expr)? ('=' optInd expr)?
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
  #| genericParamList = '[' optInd
  #|   genericParam ^* (comma/semicolon) optPar ']'
  result = newNodeP(nkGenericParams, p)
  getTok(p)
  optInd(p, result)
  while p.tok.tokType in {tkSymbol, tkAccent}:
    var a = parseGenericParam(p)
    addSon(result, a)
    if p.tok.tokType notin {tkComma, tkSemiColon}: break
    getTok(p)
    skipComment(p, a)
  optPar(p)
  eat(p, tkBracketRi)

proc parsePattern(p: var TParser): PNode =
  eat(p, tkBracketDotLe)
  result = parseStmt(p)
  eat(p, tkBracketDotRi)

proc validInd(p: TParser): bool = p.tok.indent < 0

proc parseRoutine(p: var TParser, kind: TNodeKind): PNode =
  #| indAndComment = (IND{>} COMMENT)? | COMMENT?
  #| routine = optInd identVis pattern? genericParamList?
  #|   paramListColon pragma? ('=' COMMENT? stmt)? indAndComment
  result = newNodeP(kind, p)
  getTok(p)
  optInd(p, result)
  addSon(result, identVis(p))
  if p.tok.tokType == tkBracketDotLe and p.validInd:
    addSon(result, p.parsePattern)
  else:
    addSon(result, ast.emptyNode)
  if p.tok.tokType == tkBracketLe and p.validInd:
    result.add(p.parseGenericParamList)
  else:
    addSon(result, ast.emptyNode)
  addSon(result, p.parseParamList)
  if (p.tok.tokType == tkCurlyDotLe or isAt(p.tok)) and p.validInd:
    addSon(result, p.parsePragma)
  else:
    addSon(result, ast.emptyNode)
  # empty exception tracking:
  addSon(result, ast.emptyNode)
  if p.tok.tokType == tkCurlyLe:
    addSon(result, parseCurlyStmt(p))
  else:
    addSon(result, ast.emptyNode)
  indAndComment(p, result)

proc newCommentStmt(p: var TParser): PNode =
  #| commentStmt = COMMENT
  result = newNodeP(nkCommentStmt, p)
  result.comment = p.tok.literal
  getTok(p)

type
  TDefParser = proc (p: var TParser): PNode {.nimcall.}

proc parseSection(p: var TParser, kind: TNodeKind,
                  defparser: TDefParser): PNode =
  #| section(p) = COMMENT? p / (IND{>} (p / COMMENT)^+IND{=} DED)
  result = newNodeP(kind, p)
  if kind != nkTypeSection: getTok(p)
  skipComment(p, result)
  if p.tok.tokType == tkParLe:
    getTok(p)
    skipComment(p, result)
    while true:
      case p.tok.tokType
      of tkSymbol, tkAccent, tkParLe:
        var a = defparser(p)
        skipComment(p, a)
        addSon(result, a)
      of tkComment:
        var a = newCommentStmt(p)
        addSon(result, a)
      of tkParRi: break
      else:
        parMessage(p, errIdentifierExpected, p.tok)
        break
    eat(p, tkParRi)
    if result.len == 0: parMessage(p, errIdentifierExpected, p.tok)
  elif p.tok.tokType in {tkSymbol, tkAccent, tkBracketLe}:
    # tkBracketLe is allowed for ``var [x, y] = ...`` tuple parsing
    addSon(result, defparser(p))
  else:
    parMessage(p, errIdentifierExpected, p.tok)

proc parseConstant(p: var TParser): PNode =
  #| constant = identWithPragma (colon typedesc)? '=' optInd expr indAndComment
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
  indAndComment(p, result)

proc parseEnum(p: var TParser): PNode =
  #| enum = 'enum' optInd (symbol optInd ('=' optInd expr COMMENT?)? comma?)+
  result = newNodeP(nkEnumTy, p)
  getTok(p)
  addSon(result, ast.emptyNode)
  optInd(p, result)
  flexComment(p, result)
  eat(p, tkCurlyLe)
  optInd(p, result)
  while p.tok.tokType notin {tkEof, tkCurlyRi}:
    var a = parseSymbol(p)
    if a.kind == nkEmpty: return
    if p.tok.tokType == tkEquals:
      getTok(p)
      optInd(p, a)
      var b = a
      a = newNodeP(nkEnumFieldDef, p)
      addSon(a, b)
      addSon(a, parseExpr(p))
      if p.tok.indent < 0:
        rawSkipComment(p, a)
    if p.tok.tokType == tkComma:
      getTok(p)
      rawSkipComment(p, a)
    addSon(result, a)
  eat(p, tkCurlyRi)
  if result.len <= 1:
    lexMessageTok(p.lex, errIdentifierExpected, p.tok, prettyTok(p.tok))

proc parseObjectPart(p: var TParser; needsCurly: bool): PNode
proc parseObjectWhen(p: var TParser): PNode =
  result = newNodeP(nkRecWhen, p)
  while true:
    getTok(p)                 # skip `when`, `elif`
    var branch = newNodeP(nkElifBranch, p)
    optInd(p, branch)
    addSon(branch, parseExpr(p))
    colcom(p, branch)
    addSon(branch, parseObjectPart(p, true))
    flexComment(p, branch)
    addSon(result, branch)
    if p.tok.tokType != tkElif: break
  if p.tok.tokType == tkElse:
    var branch = newNodeP(nkElse, p)
    eat(p, tkElse)
    colcom(p, branch)
    addSon(branch, parseObjectPart(p, true))
    flexComment(p, branch)
    addSon(result, branch)

proc parseObjectCase(p: var TParser): PNode =
  result = newNodeP(nkRecCase, p)
  getTokNoInd(p)
  var a = newNodeP(nkIdentDefs, p)
  addSon(a, identWithPragma(p))
  eat(p, tkColon)
  addSon(a, parseTypeDesc(p))
  addSon(a, ast.emptyNode)
  addSon(result, a)
  eat(p, tkCurlyLe)
  flexComment(p, result)
  while true:
    var b: PNode
    case p.tok.tokType
    of tkOf:
      b = newNodeP(nkOfBranch, p)
      exprList(p, tkColon, b)
    of tkElse:
      b = newNodeP(nkElse, p)
      getTok(p)
    else: break
    colcom(p, b)
    var fields = parseObjectPart(p, true)
    if fields.kind == nkEmpty:
      parMessage(p, errIdentifierExpected, p.tok)
      fields = newNodeP(nkNilLit, p) # don't break further semantic checking
    addSon(b, fields)
    addSon(result, b)
    if b.kind == nkElse: break
  eat(p, tkCurlyRi)

proc parseObjectPart(p: var TParser; needsCurly: bool): PNode =
  if p.tok.tokType == tkCurlyLe:
    result = newNodeP(nkRecList, p)
    getTok(p)
    rawSkipComment(p, result)
    while true:
      case p.tok.tokType
      of tkCase, tkWhen, tkSymbol, tkAccent, tkNil, tkDiscard:
        addSon(result, parseObjectPart(p, false))
      of tkCurlyRi: break
      else:
        parMessage(p, errIdentifierExpected, p.tok)
        break
    eat(p, tkCurlyRi)
  else:
    if needsCurly:
      parMessage(p, errTokenExpected, "{")
    case p.tok.tokType
    of tkWhen:
      result = parseObjectWhen(p)
    of tkCase:
      result = parseObjectCase(p)
    of tkSymbol, tkAccent:
      result = parseIdentColonEquals(p, {withPragma})
      if p.tok.indent < 0: rawSkipComment(p, result)
    of tkNil, tkDiscard:
      result = newNodeP(nkNilLit, p)
      getTok(p)
    else:
      result = ast.emptyNode

proc parseObject(p: var TParser): PNode =
  result = newNodeP(nkObjectTy, p)
  getTok(p)
  if (p.tok.tokType == tkCurlyDotLe or isAt(p.tok)) and p.validInd:
    addSon(result, parsePragma(p))
  else:
    addSon(result, ast.emptyNode)
  if p.tok.tokType == tkOf and p.tok.indent < 0:
    var a = newNodeP(nkOfInherit, p)
    getTok(p)
    addSon(a, parseTypeDesc(p))
    addSon(result, a)
  else:
    addSon(result, ast.emptyNode)
  skipComment(p, result)
  # an initial IND{>} HAS to follow:
  addSon(result, parseObjectPart(p, true))

proc parseTypeClassParam(p: var TParser): PNode =
  if p.tok.tokType in {tkOut, tkVar}:
    result = newNodeP(nkVarTy, p)
    getTok(p)
    result.addSon(p.parseSymbol)
  else:
    result = p.parseSymbol

proc parseTypeClass(p: var TParser): PNode =
  #| typeClassParam = ('var' | 'out')? symbol
  #| typeClass = typeClassParam ^* ',' (pragma)? ('of' typeDesc ^* ',')?
  #|               &IND{>} stmt
  result = newNodeP(nkTypeClassTy, p)
  getTok(p)
  var args = newNodeP(nkArgList, p)
  addSon(result, args)
  addSon(args, p.parseTypeClassParam)
  while p.tok.tokType == tkComma:
    getTok(p)
    addSon(args, p.parseTypeClassParam)
  if (p.tok.tokType == tkCurlyDotLe or isAt(p.tok)) and p.validInd:
    addSon(result, parsePragma(p))
  else:
    addSon(result, ast.emptyNode)
  if p.tok.tokType == tkOf and p.tok.indent < 0:
    var a = newNodeP(nkOfInherit, p)
    getTok(p)
    while true:
      addSon(a, parseTypeDesc(p))
      if p.tok.tokType != tkComma: break
      getTok(p)
    addSon(result, a)
  else:
    addSon(result, ast.emptyNode)
  if p.tok.tokType == tkComment:
    skipComment(p, result)
  addSon(result, parseCurlyStmt(p))

proc parseTypeDef(p: var TParser): PNode =
  #|
  #| typeDef = identWithPragmaDot genericParamList? '=' optInd typeDefAux
  #|             indAndComment?
  result = newNodeP(nkTypeDef, p)
  addSon(result, identWithPragma(p, allowDot=true))
  if p.tok.tokType == tkBracketLe and p.validInd:
    addSon(result, parseGenericParamList(p))
  else:
    addSon(result, ast.emptyNode)
  if p.tok.tokType == tkEquals:
    getTok(p)
    optInd(p, result)
    addSon(result, parseTypeDefAux(p))
  else:
    addSon(result, ast.emptyNode)
  indAndComment(p, result)    # special extension!

proc parseVarTuple(p: var TParser): PNode =
  #| varTuple = '(' optInd identWithPragma ^+ comma optPar ')' '=' optInd expr
  result = newNodeP(nkVarTuple, p)
  getTok(p)                   # skip '('
  optInd(p, result)
  while p.tok.tokType in {tkSymbol, tkAccent}:
    var a = identWithPragma(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break
    getTok(p)
    skipComment(p, a)
  addSon(result, ast.emptyNode)         # no type desc
  optPar(p)
  eat(p, tkBracketRi)
  eat(p, tkEquals)
  optInd(p, result)
  addSon(result, parseExpr(p))

proc parseVariable(p: var TParser): PNode =
  #| variable = (varTuple / identColonEquals) indAndComment
  if p.tok.tokType == tkBracketLe: result = parseVarTuple(p)
  else: result = parseIdentColonEquals(p, {withPragma})
  indAndComment(p, result)

proc parseBind(p: var TParser, k: TNodeKind): PNode =
  #| bindStmt = 'bind' optInd qualifiedIdent ^+ comma
  #| mixinStmt = 'mixin' optInd qualifiedIdent ^+ comma
  result = newNodeP(k, p)
  getTok(p)
  optInd(p, result)
  while true:
    var a = qualifiedIdent(p)
    addSon(result, a)
    if p.tok.tokType != tkComma: break
    getTok(p)
    optInd(p, a)

proc parseStmtPragma(p: var TParser): PNode =
  result = parsePragma(p)
  if p.tok.tokType == tkCurlyLe:
    let a = result
    result = newNodeI(nkPragmaBlock, a.info)
    getTok(p)
    skipComment(p, result)
    result.add a
    result.add parseStmt(p)
    eat(p, tkCurlyRi)

proc simpleStmt(p: var TParser): PNode =
  case p.tok.tokType
  of tkReturn: result = parseReturnOrRaise(p, nkReturnStmt)
  of tkRaise: result = parseReturnOrRaise(p, nkRaiseStmt)
  of tkYield: result = parseReturnOrRaise(p, nkYieldStmt)
  of tkDiscard: result = parseReturnOrRaise(p, nkDiscardStmt)
  of tkBreak: result = parseReturnOrRaise(p, nkBreakStmt)
  of tkContinue: result = parseReturnOrRaise(p, nkContinueStmt)
  of tkCurlyDotLe: result = parseStmtPragma(p)
  of tkImport: result = parseImport(p, nkImportStmt)
  of tkExport: result = parseImport(p, nkExportStmt)
  of tkFrom: result = parseFromStmt(p)
  of tkInclude: result = parseIncludeStmt(p)
  of tkComment: result = newCommentStmt(p)
  else:
    if isExprStart(p): result = parseExprStmt(p)
    else: result = ast.emptyNode
  if result.kind notin {nkEmpty, nkCommentStmt}: skipComment(p, result)

proc complexOrSimpleStmt(p: var TParser): PNode =
  case p.tok.tokType
  of tkIf: result = parseIfOrWhen(p, nkIfStmt)
  of tkWhile: result = parseWhile(p)
  of tkCase: result = parseCase(p)
  of tkTry: result = parseTry(p)
  of tkFor: result = parseFor(p)
  of tkBlock: result = parseBlock(p)
  of tkStatic: result = parseStaticOrDefer(p, nkStaticStmt)
  of tkDefer: result = parseStaticOrDefer(p, nkDefer)
  of tkAsm: result = parseAsm(p)
  of tkProc: result = parseRoutine(p, nkProcDef)
  of tkMethod: result = parseRoutine(p, nkMethodDef)
  of tkIterator: result = parseRoutine(p, nkIteratorDef)
  of tkMacro: result = parseRoutine(p, nkMacroDef)
  of tkTemplate: result = parseRoutine(p, nkTemplateDef)
  of tkConverter: result = parseRoutine(p, nkConverterDef)
  of tkType:
    getTok(p)
    if p.tok.tokType == tkBracketLe:
      getTok(p)
      result = newNodeP(nkTypeOfExpr, p)
      result.addSon(primary(p, pmTypeDesc))
      eat(p, tkBracketRi)
      result = parseOperators(p, result, -1, pmNormal)
    else:
      result = parseSection(p, nkTypeSection, parseTypeDef)
  of tkConst: result = parseSection(p, nkConstSection, parseConstant)
  of tkLet: result = parseSection(p, nkLetSection, parseVariable)
  of tkWhen: result = parseIfOrWhen(p, nkWhenStmt)
  of tkVar: result = parseSection(p, nkVarSection, parseVariable)
  of tkBind: result = parseBind(p, nkBindStmt)
  of tkMixin: result = parseBind(p, nkMixinStmt)
  of tkUsing: result = parseSection(p, nkUsingStmt, parseVariable)
  else: result = simpleStmt(p)

proc parseStmt(p: var TParser): PNode =
  result = complexOrSimpleStmt(p)

proc parseAll*(p: var TParser): PNode =
  ## Parses the rest of the input stream held by the parser into a PNode.
  result = newNodeP(nkStmtList, p)
  while p.tok.tokType != tkEof:
    var a = complexOrSimpleStmt(p)
    if a.kind != nkEmpty:
      addSon(result, a)
    else:
      parMessage(p, errExprExpected, p.tok)
      # bugfix: consume a token here to prevent an endless loop:
      getTok(p)

proc parseTopLevelStmt*(p: var TParser): PNode =
  ## Implements an iterator which, when called repeatedly, returns the next
  ## top-level statement or emptyNode if end of stream.
  result = ast.emptyNode
  while true:
    case p.tok.tokType
    of tkSemiColon: getTok(p)
    of tkEof: break
    else:
      result = complexOrSimpleStmt(p)
      if result.kind == nkEmpty: parMessage(p, errExprExpected, p.tok)
      break
