#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``parsesql`` module implements a high performance SQL file 
## parser. It parses PostgreSQL syntax and the SQL ANSI standard.

import 
  hashes, strutils, lexbase, streams

# ------------------- scanner -------------------------------------------------

type
  TTokKind = enum       ## enumeration of all SQL tokens
    tkInvalid,          ## invalid token
    tkEof,              ## end of file reached
    tkIdentifier,       ## abc
    tkQuotedIdentifier, ## "abc"
    tkStringConstant,   ## 'abc'
    tkEscapeConstant,       ## e'abc'
    tkDollarQuotedConstant, ## $tag$abc$tag$
    tkBitStringConstant,    ## B'00011'
    tkHexStringConstant,    ## x'00011'
    tkInteger,
    tkNumeric,
    tkOperator,             ## + - * / < > = ~ ! @ # % ^ & | ` ?
    tkSemicolon,            ## ';'
    tkColon,                ## ':'
    tkComma,                ## ','
    tkParLe,                ## '('
    tkParRi,                ## ')'
    tkBracketLe,            ## '['
    tkBracketRi,            ## ']'
    tkDot                   ## '.'
  
  TToken {.final.} = object  # a token
    kind: TTokKind           # the type of the token
    literal: string          # the parsed (string) literal
  
  TSqlLexer* = object of TBaseLexer ## the parser object.
    filename: string

const
  tokKindToStr: array[TTokKind, string] = [
    "invalid", "[EOF]", "identifier", "quoted identifier", "string constant",
    "escape string constant", "dollar quoted constant", "bit string constant",
    "hex string constant", "integer constant", "numeric constant", "operator",
    ";", ":", ",", "(", ")", "[", "]", "."
  ]

proc open(L: var TSqlLexer, input: PStream, filename: string) = 
  lexbase.open(L, input)
  L.filename = filename
  
proc close(L: var TSqlLexer) = 
  lexbase.close(L)

proc getColumn(L: TSqlLexer): int = 
  ## get the current column the parser has arrived at.
  result = getColNumber(L, L.bufPos)

proc getLine(L: TSqlLexer): int = 
  result = L.linenumber

proc handleHexChar(c: var TSqlLexer, xi: var int) = 
  case c.buf[c.bufpos]
  of '0'..'9': 
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)
  of 'a'..'f': 
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('a') + 10)
    inc(c.bufpos)
  of 'A'..'F': 
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('A') + 10)
    inc(c.bufpos)
  else: 
    discard

proc handleOctChar(c: var TSqlLexer, xi: var int) = 
  if c.buf[c.bufpos] in {'0'..'7'}:
    xi = (xi shl 3) or (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)

proc getEscapedChar(c: var TSqlLexer, tok: var TToken) = 
  inc(c.bufpos)
  case c.buf[c.bufpos]
  of 'n', 'N': 
    add(tok.literal, '\L')
    Inc(c.bufpos)
  of 'r', 'R', 'c', 'C': 
    add(tok.literal, '\c')
    Inc(c.bufpos)
  of 'l', 'L': 
    add(tok.literal, '\L')
    Inc(c.bufpos)
  of 'f', 'F': 
    add(tok.literal, '\f')
    inc(c.bufpos)
  of 'e', 'E': 
    add(tok.literal, '\e')
    Inc(c.bufpos)
  of 'a', 'A': 
    add(tok.literal, '\a')
    Inc(c.bufpos)
  of 'b', 'B': 
    add(tok.literal, '\b')
    Inc(c.bufpos)
  of 'v', 'V': 
    add(tok.literal, '\v')
    Inc(c.bufpos)
  of 't', 'T': 
    add(tok.literal, '\t')
    Inc(c.bufpos)
  of '\'', '\"': 
    add(tok.literal, c.buf[c.bufpos])
    Inc(c.bufpos)
  of '\\': 
    add(tok.literal, '\\')
    Inc(c.bufpos)
  of 'x', 'X': 
    inc(c.bufpos)
    var xi = 0
    handleHexChar(c, xi)
    handleHexChar(c, xi)
    add(tok.literal, Chr(xi))
  of '0'..'7': 
    var xi = 0
    handleOctChar(c, xi)
    handleOctChar(c, xi)
    handleOctChar(c, xi)
    if (xi <= 255): add(tok.literal, Chr(xi))
    else: tok.kind = tkInvalid
  else: tok.kind = tkInvalid
  
proc HandleCRLF(c: var TSqlLexer, pos: int): int = 
  case c.buf[pos]
  of '\c': result = lexbase.HandleCR(c, pos)
  of '\L': result = lexbase.HandleLF(c, pos)
  else: result = pos

proc skip(c: var TSqlLexer) = 
  var pos = c.bufpos
  var buf = c.buf
  var nested = 0
  while true: 
    case buf[pos]
    of ' ', '\t': 
      Inc(pos)
    of '-':
      if buf[pos+1] == '-':
        while not (buf[pos] in {'\c', '\L', lexbase.EndOfFile}): inc(pos)
      else:
        break
    of '/':
      if buf[pos+1] == '*':
        inc(pos,2)
        while true:
          case buf[pos]
          of '\0': break
          of '\c', '\L': 
            pos = HandleCRLF(c, pos)
            buf = c.buf
          of '*':
            if buf[pos+1] == '/':
              inc(pos, 2)
              if nested <= 0: break
              dec(nested)
            else:
              inc(pos)
          of '/':
            if buf[pos+1] == '*':
              inc(pos, 2)
              inc(nested)
            else:
              inc(pos)
          else: inc(pos)
      else: break
    of '\c', '\L': 
      pos = HandleCRLF(c, pos)
      buf = c.buf
    else: 
      break                   # EndOfFile also leaves the loop
  c.bufpos = pos
  
proc getString(c: var TSqlLexer, tok: var TToken, kind: TTokKind) = 
  var pos = c.bufPos + 1
  var buf = c.buf
  tok.kind = kind
  block parseLoop:
    while true:
      while true: 
        var ch = buf[pos]
        if ch == '\'':
          if buf[pos+1] == '\'':
            inc(pos, 2)
            add(tok.literal, '\'')
          else:
            inc(pos)
            break 
        elif ch in {'\c', '\L', lexbase.EndOfFile}: 
          tok.kind = tkInvalid
          break parseLoop
        elif (ch == '\\') and kind == tkEscapeConstant: 
          c.bufPos = pos
          getEscapedChar(c, tok)
          pos = c.bufPos
        else: 
          add(tok.literal, ch)
          Inc(pos)
      c.bufpos = pos
      var line = c.linenumber
      skip(c)
      if c.linenumber > line:
        # a new line whitespace has been parsed, so we check if the string
        # continues after the whitespace:
        buf = c.buf # may have been reallocated
        pos = c.bufpos
        if buf[pos] == '\'': inc(pos)
        else: break parseLoop
      else: break parseLoop
  c.bufpos = pos

proc getDollarString(c: var TSqlLexer, tok: var TToken) = 
  var pos = c.bufPos + 1
  var buf = c.buf
  tok.kind = tkDollarQuotedConstant
  var tag = "$"
  while buf[pos] in IdentChars:
    add(tag, buf[pos])
    inc(pos)
  if buf[pos] == '$': inc(pos)
  else:
    tok.kind = tkInvalid
    return
  while true:
    case buf[pos]
    of '\c', '\L': 
      pos = HandleCRLF(c, pos)
      buf = c.buf
      add(tok.literal, "\L")
    of '\0':
      tok.kind = tkInvalid
      break
    of '$':
      inc(pos)
      var tag2 = "$"
      while buf[pos] in IdentChars:
        add(tag2, buf[pos])
        inc(pos)
      if buf[pos] == '$': inc(pos)
      if tag2 == tag: break
      add(tok.literal, tag2)
      add(tok.literal, '$')
    else:
      add(tok.literal, buf[pos])
      inc(pos)
  c.bufpos = pos

proc getSymbol(c: var TSqlLexer, tok: var TToken) = 
  var pos = c.bufpos
  var buf = c.buf
  while true: 
    add(tok.literal, buf[pos])
    Inc(pos)
    if buf[pos] notin {'a'..'z','A'..'Z','0'..'9','_','$', '\128'..'\255'}:
      break
  c.bufpos = pos
  tok.kind = tkIdentifier

proc getQuotedIdentifier(c: var TSqlLexer, tok: var TToken) = 
  var pos = c.bufPos + 1
  var buf = c.buf
  tok.kind = tkQuotedIdentifier
  while true:
    var ch = buf[pos]
    if ch == '\"':
      if buf[pos+1] == '\"':
        inc(pos, 2)
        add(tok.literal, '\"')
      else:
        inc(pos)
        break
    elif ch in {'\c', '\L', lexbase.EndOfFile}: 
      tok.kind = tkInvalid
      break
    else:
      add(tok.literal, ch)
      Inc(pos)
  c.bufpos = pos

proc getBitHexString(c: var TSqlLexer, tok: var TToken, validChars: TCharSet) =
  var pos = c.bufPos + 1
  var buf = c.buf
  block parseLoop:
    while true:
      while true: 
        var ch = buf[pos]
        if ch in validChars:
          add(tok.literal, ch)
          Inc(pos)          
        elif ch == '\'':
          inc(pos)
          break
        else: 
          tok.kind = tkInvalid
          break parseLoop
      c.bufpos = pos
      var line = c.linenumber
      skip(c)
      if c.linenumber > line:
        # a new line whitespace has been parsed, so we check if the string
        # continues after the whitespace:
        buf = c.buf # may have been reallocated
        pos = c.bufpos
        if buf[pos] == '\'': inc(pos)
        else: break parseLoop
      else: break parseLoop
  c.bufpos = pos

proc getNumeric(c: var TSqlLexer, tok: var TToken) =
  tok.kind = tkInteger
  var pos = c.bufPos
  var buf = c.buf
  while buf[pos] in Digits:
    add(tok.literal, buf[pos])
    inc(pos)
  if buf[pos] == '.':
    tok.kind = tkNumeric
    add(tok.literal, buf[pos])
    inc(pos)
    while buf[pos] in Digits:
      add(tok.literal, buf[pos])
      inc(pos)
  if buf[pos] in {'E', 'e'}:
    tok.kind = tkNumeric
    add(tok.literal, buf[pos])
    inc(pos)
    if buf[pos] == '+':
      inc(pos)
    elif buf[pos] == '-':
      add(tok.literal, buf[pos])
      inc(pos)
    if buf[pos] in Digits:
      while buf[pos] in Digits:
        add(tok.literal, buf[pos])
        inc(pos)
    else:
      tok.kind = tkInvalid
  c.bufpos = pos  

proc getOperator(c: var TSqlLexer, tok: var TToken) =
  const operators = {'+', '-', '*', '/', '<', '>', '=', '~', '!', '@', '#', '%',
                     '^', '&', '|', '`', '?'}
  tok.kind = tkOperator
  var pos = c.bufPos
  var buf = c.buf
  var trailingPlusMinus = false
  while true:
    case buf[pos]
    of '-':
      if buf[pos] == '-': break
      if not trailingPlusMinus and buf[pos+1] notin operators and
           tok.literal.len > 0: break
    of '/':
      if buf[pos] == '*': break
    of '~', '!', '@', '#', '%', '^', '&', '|', '`', '?':
      trailingPlusMinus = true
    of '+':
      if not trailingPlusMinus and buf[pos+1] notin operators and
           tok.literal.len > 0: break
    of '*', '<', '>', '=': discard
    else: break
    add(tok.literal, buf[pos])
    inc(pos)
  c.bufpos = pos

proc getTok(c: var TSqlLexer, tok: var TToken) = 
  tok.kind = tkInvalid
  setlen(tok.literal, 0)
  skip(c)
  case c.buf[c.bufpos]
  of ';': 
    tok.kind = tkSemiColon
    inc(c.bufPos)
    add(tok.literal, ';')
  of ',':
    tok.kind = tkComma
    inc(c.bufpos)
    add(tok.literal, ',')
  of ':': 
    tok.kind = tkColon
    inc(c.bufpos)
    add(tok.literal, ':')
  of 'e', 'E': 
    if c.buf[c.bufPos + 1] == '\'': 
      Inc(c.bufPos)
      getString(c, tok, tkEscapeConstant)
    else: 
      getSymbol(c, tok)
  of 'b', 'B':
    if c.buf[c.bufPos + 1] == '\'':
      tok.kind = tkBitStringConstant
      getBitHexString(c, tok, {'0'..'1'})
    else:
      getSymbol(c, tok)
  of 'x', 'X':
    if c.buf[c.bufPos + 1] == '\'':
      tok.kind = tkHexStringConstant
      getBitHexString(c, tok, {'a'..'f','A'..'F','0'..'9'})
    else:
      getSymbol(c, tok)
  of '$': getDollarString(c, tok)
  of '[': 
    tok.kind = tkBracketLe
    inc(c.bufpos)
    add(tok.literal, '[')
  of ']': 
    tok.kind = tkBracketRi
    Inc(c.bufpos)
    add(tok.literal, ']')
  of '(':
    tok.kind = tkParLe
    Inc(c.bufpos)
    add(tok.literal, '(')
  of ')':
    tok.kind = tkParRi
    Inc(c.bufpos)
    add(tok.literal, ')')
  of '.': 
    if c.buf[c.bufPos + 1] in Digits:
      getNumeric(c, tok)
    else:
      tok.kind = tkDot
      inc(c.bufpos)
    add(tok.literal, '.')
  of '0'..'9': getNumeric(c, tok)
  of '\'': getString(c, tok, tkStringConstant)
  of '"': getQuotedIdentifier(c, tok)
  of lexbase.EndOfFile: 
    tok.kind = tkEof
    tok.literal = "[EOF]"
  of 'a', 'c', 'd', 'f'..'w', 'y', 'z', 'A', 'C', 'D', 'F'..'W', 'Y', 'Z', '_',
     '\128'..'\255':
    getSymbol(c, tok)
  of '+', '-', '*', '/', '<', '>', '=', '~', '!', '@', '#', '%',
     '^', '&', '|', '`', '?':
    getOperator(c, tok)
  else:
    add(tok.literal, c.buf[c.bufpos])
    inc(c.bufpos)
  
proc errorStr(L: TSqlLexer, msg: string): string = 
  result = "$1($2, $3) Error: $4" % [L.filename, $getLine(L), $getColumn(L), msg]


# ----------------------------- parser ----------------------------------------

# Operator/Element	Associativity	Description
# .	                left    	table/column name separator
# ::            	left	        PostgreSQL-style typecast
# [ ]	                left    	array element selection
# -	                right	        unary minus
# ^             	left	        exponentiation
# * / %	                left	        multiplication, division, modulo
# + -	                left	        addition, subtraction
# IS	 	IS TRUE, IS FALSE, IS UNKNOWN, IS NULL
# ISNULL	 	test for null
# NOTNULL	 	test for not null
# (any other)	        left    	all other native and user-defined oprs
# IN	          	set membership
# BETWEEN	 	range containment
# OVERLAPS	 	time interval overlap
# LIKE ILIKE SIMILAR	 	string pattern matching
# < >	 	less than, greater than
# =	                right	        equality, assignment
# NOT	                right	        logical negation
# AND	                left	        logical conjunction
# OR              	left	        logical disjunction

type
  TSqlNodeKind* = enum ## kind of SQL abstract syntax tree
    nkNone,
    nkIdent,
    nkStringLit,
    nkBitStringLit,
    nkHexStringLit,
    nkIntegerLit,
    nkNumericLit,
    nkPrimaryKey,
    nkForeignKey,
    nkNotNull,
    
    nkStmtList,
    nkDot,
    nkDotDot,
    nkPrefix,
    nkInfix,
    nkCall,
    nkColumnReference,
    nkReferences,
    nkDefault,
    nkCheck,
    nkConstraint,
    nkUnique,
    nkIdentity,
    nkColumnDef,        ## name, datatype, constraints
    nkInsert,
    nkUpdate,
    nkDelete,
    nkSelect,
    nkSelectDistinct,
    nkSelectColumns,
    nkAsgn,
    nkFrom,
    nkGroup,
    nkHaving,
    nkOrder,
    nkDesc,
    nkUnion,
    nkIntersect,
    nkExcept,
    nkColumnList,
    nkValueList,
    nkWhere,
    nkCreateTable,
    nkCreateTableIfNotExists, 
    nkCreateType,
    nkCreateTypeIfNotExists,
    nkCreateIndex,
    nkCreateIndexIfNotExists,
    nkEnumDef
    
type
  EInvalidSql* = object of EInvalidValue ## Invalid SQL encountered
  PSqlNode* = ref TSqlNode        ## an SQL abstract syntax tree node
  TSqlNode* = object              ## an SQL abstract syntax tree node
    case kind*: TSqlNodeKind      ## kind of syntax tree
    of nkIdent, nkStringLit, nkBitStringLit, nkHexStringLit,
                nkIntegerLit, nkNumericLit:
      strVal*: string             ## AST leaf: the identifier, numeric literal
                                  ## string literal, etc.
    else:
      sons*: seq[PSqlNode]        ## the node's children

  TSqlParser* = object of TSqlLexer ## SQL parser object
    tok: TToken

proc newNode(k: TSqlNodeKind): PSqlNode =
  new(result)
  result.kind = k

proc newNode(k: TSqlNodeKind, s: string): PSqlNode =
  new(result)
  result.kind = k
  result.strVal = s
  
proc len*(n: PSqlNode): int =
  if isNil(n.sons): result = 0
  else: result = n.sons.len
  
proc add*(father, n: PSqlNode) =
  if isNil(father.sons): father.sons = @[]
  add(father.sons, n)

proc getTok(p: var TSqlParser) =
  getTok(p, p.tok)

proc sqlError(p: TSqlParser, msg: string) =
  var e: ref EInvalidSql
  new(e)
  e.msg = errorStr(p, msg)
  raise e

proc isKeyw(p: TSqlParser, keyw: string): bool =
  result = p.tok.kind == tkIdentifier and
           cmpIgnoreCase(p.tok.literal, keyw) == 0

proc isOpr(p: TSqlParser, opr: string): bool =
  result = p.tok.kind == tkOperator and
           cmpIgnoreCase(p.tok.literal, opr) == 0

proc optKeyw(p: var TSqlParser, keyw: string) =
  if p.tok.kind == tkIdentifier and cmpIgnoreCase(p.tok.literal, keyw) == 0:
    getTok(p)

proc expectIdent(p: TSqlParser) =
  if p.tok.kind != tkIdentifier and p.tok.kind != tkQuotedIdentifier:
    sqlError(p, "identifier expected")

proc expect(p: TSqlParser, kind: TTokKind) =
  if p.tok.kind != kind:
    sqlError(p, tokKindToStr[kind] & " expected")

proc eat(p: var TSqlParser, kind: TTokKind) =
  if p.tok.kind == kind:
    getTok(p)
  else:
    sqlError(p, tokKindToStr[kind] & " expected")

proc eat(p: var TSqlParser, keyw: string) =
  if isKeyw(p, keyw):
    getTok(p)
  else:
    sqlError(p, keyw.toUpper() & " expected")

proc parseDataType(p: var TSqlParser): PSqlNode =
  if isKeyw(p, "enum"):
    result = newNode(nkEnumDef)
    getTok(p)
    if p.tok.kind == tkParLe:
      getTok(p)
      result.add(newNode(nkStringLit, p.tok.literal))
      getTok(p)
      while p.tok.kind == tkComma:
        getTok(p)
        result.add(newNode(nkStringLit, p.tok.literal))
        getTok(p)
      eat(p, tkParRi)
  else:
    expectIdent(p)
    result = newNode(nkIdent, p.tok.literal)
    getTok(p)
    # ignore (12, 13) part:
    if p.tok.kind == tkParLe:
      getTok(p)
      expect(p, tkInteger)
      getTok(p)
      while p.tok.kind == tkComma:
        getTok(p)
        expect(p, tkInteger)
        getTok(p)
      eat(p, tkParRi)

proc getPrecedence(p: TSqlParser): int = 
  if isOpr(p, "*") or isOpr(p, "/") or isOpr(p, "%"):
    result = 6
  elif isOpr(p, "+") or isOpr(p, "-"):
    result = 5  
  elif isOpr(p, "=") or isOpr(p, "<") or isOpr(p, ">") or isOpr(p, ">=") or
       isOpr(p, "<=") or isOpr(p, "<>") or isOpr(p, "!=") or isKeyw(p, "is") or
       isKeyw(p, "like"):
    result = 3
  elif isKeyw(p, "and"):
    result = 2
  elif isKeyw(p, "or"):
    result = 1
  elif p.tok.kind == tkOperator:
    # user-defined operator:
    result = 0
  else:
    result = - 1

proc parseExpr(p: var TSqlParser): PSqlNode

proc identOrLiteral(p: var TSqlParser): PSqlNode = 
  case p.tok.kind
  of tkIdentifier, tkQuotedIdentifier: 
    result = newNode(nkIdent, p.tok.literal)
    getTok(p)
  of tkStringConstant, tkEscapeConstant, tkDollarQuotedConstant:
    result = newNode(nkStringLit, p.tok.literal)
    getTok(p)
  of tkBitStringConstant:
    result = newNode(nkBitStringLit, p.tok.literal)
    getTok(p)
  of tkHexStringConstant:
    result = newNode(nkHexStringLit, p.tok.literal)
    getTok(p)
  of tkInteger:
    result = newNode(nkIntegerLit, p.tok.literal)
    getTok(p)
  of tkNumeric:
    result = newNode(nkNumericLit, p.tok.literal)
    getTok(p)
  of tkParLe:
    getTok(p)
    result = parseExpr(p)
    eat(p, tkParRi)
  else: 
    sqlError(p, "expression expected")
    getTok(p) # we must consume a token here to prevend endless loops!

proc primary(p: var TSqlParser): PSqlNode = 
  if p.tok.kind == tkOperator or isKeyw(p, "not"): 
    result = newNode(nkPrefix)
    result.add(newNode(nkIdent, p.tok.literal))
    getTok(p)
    result.add(primary(p))
    return
  result = identOrLiteral(p)
  while true: 
    case p.tok.kind
    of tkParLe: 
      var a = result
      result = newNode(nkCall)
      result.add(a)
      getTok(p)
      while true:
        result.add(parseExpr(p))
        if p.tok.kind == tkComma: getTok(p)
        else: break
      eat(p, tkParRi)
    of tkDot: 
      getTok(p)
      var a = result
      if p.tok.kind == tkDot:
        getTok(p)
        result = newNode(nkDotDot)
      else:
        result = newNode(nkDot)
      result.add(a)
      if isOpr(p, "*"):
        result.add(newNode(nkIdent, "*"))
      elif p.tok.kind in {tkIdentifier, tkQuotedIdentifier}:
        result.add(newNode(nkIdent, p.tok.literal))
      else:
        sqlError(p, "identifier expected")
      getTok(p)
    else: break
  
proc lowestExprAux(p: var TSqlParser, v: var PSqlNode, limit: int): int = 
  var
    v2, node, opNode: PSqlNode
  v = primary(p) # expand while operators have priorities higher than 'limit'
  var opPred = getPrecedence(p)
  result = opPred
  while opPred > limit: 
    node = newNode(nkInfix)
    opNode = newNode(nkIdent, p.tok.literal)
    getTok(p)
    result = lowestExprAux(p, v2, opPred)
    node.add(opNode)
    node.add(v)
    node.add(v2)
    v = node
    opPred = getPrecedence(p)
  
proc parseExpr(p: var TSqlParser): PSqlNode = 
  discard lowestExprAux(p, result, - 1)

proc parseTableName(p: var TSqlParser): PSqlNode =
  expectIdent(p)
  result = primary(p)

proc parseColumnReference(p: var TSqlParser): PSqlNode =
  result = parseTableName(p)
  if p.tok.kind == tkParLe:
    getTok(p)
    var a = result
    result = newNode(nkColumnReference)
    result.add(a)
    result.add(parseTableName(p))
    while p.tok.kind == tkComma:
      getTok(p)
      result.add(parseTableName(p))
    eat(p, tkParRi)

proc parseCheck(p: var TSqlParser): PSqlNode = 
  getTok(p)
  result = newNode(nkCheck)
  result.add(parseExpr(p))

proc parseConstraint(p: var TSqlParser): PSqlNode =
  getTok(p)
  result = newNode(nkConstraint)
  expectIdent(p)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  eat(p, "check")
  result.add(parseExpr(p))

proc parseColumnConstraints(p: var TSqlParser, result: PSqlNode) =
  while true:
    if isKeyw(p, "default"):
      getTok(p)
      var n = newNode(nkDefault)
      n.add(parseExpr(p))
      result.add(n)
    elif isKeyw(p, "references"):
      getTok(p)
      var n = newNode(nkReferences)
      n.add(parseColumnReference(p))
      result.add(n)
    elif isKeyw(p, "not"):
      getTok(p)
      eat(p, "null")
      result.add(newNode(nkNotNull))
    elif isKeyw(p, "identity"):
      getTok(p)
      result.add(newNode(nkIdentity))
    elif isKeyw(p, "primary"):
      getTok(p)
      eat(p, "key")
      result.add(newNode(nkPrimaryKey))
    elif isKeyw(p, "check"):
      result.add(parseCheck(p))
    elif isKeyw(p, "constraint"):
      result.add(parseConstraint(p))
    elif isKeyw(p, "unique"):
      result.add(newNode(nkUnique))
    else:
      break

proc parseColumnDef(p: var TSqlParser): PSqlNode =
  expectIdent(p)
  result = newNode(nkColumnDef)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  result.add(parseDataType(p))
  parseColumnConstraints(p, result)  

proc parseIfNotExists(p: var TSqlParser, k: TSqlNodeKind): PSqlNode = 
  getTok(p)
  if isKeyw(p, "if"):
    getTok(p)
    eat(p, "not")
    eat(p, "exists")
    result = newNode(succ(k))
  else:
    result = newNode(k)

proc parseParIdentList(p: var TSqlParser, father: PSqlNode) =
  eat(p, tkParLe)
  while true:
    expectIdent(p)
    father.add(newNode(nkIdent, p.tok.literal))
    getTok(p)
    if p.tok.kind != tkComma: break
    getTok(p)
  eat(p, tkParRi)

proc parseTableConstraint(p: var TSqlParser): PSqlNode =
  if isKeyw(p, "primary"):
    getTok(p)
    eat(p, "key")
    result = newNode(nkPrimaryKey)
    parseParIdentList(p, result)
  elif isKeyw(p, "foreign"):
    getTok(p)
    eat(p, "key")
    result = newNode(nkForeignKey)
    parseParIdentList(p, result)
    eat(p, "references")
    var m = newNode(nkReferences)
    m.add(parseColumnReference(p))
    result.add(m)
  elif isKeyw(p, "unique"):
    getTok(p)
    eat(p, "key")
    result = newNode(nkUnique)
    parseParIdentList(p, result)
  elif isKeyw(p, "check"):
    result = parseCheck(p)
  elif isKeyw(p, "constraint"):
    result = parseConstraint(p)
  else:
    sqlError(p, "column definition expected")

proc parseTableDef(p: var TSqlParser): PSqlNode =
  result = parseIfNotExists(p, nkCreateTable)
  expectIdent(p)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  if p.tok.kind == tkParLe:
    while true:
      getTok(p)
      if p.tok.kind == tkIdentifier or p.tok.kind == tkQuotedIdentifier:
        result.add(parseColumnDef(p))
      else:
        result.add(parseTableConstraint(p))
      if p.tok.kind != tkComma: break
    eat(p, tkParRi)
  
proc parseTypeDef(p: var TSqlParser): PSqlNode =
  result = parseIfNotExists(p, nkCreateType)
  expectIdent(p)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  eat(p, "as")
  result.add(parseDataType(p))

proc parseWhere(p: var TSqlParser): PSqlNode =
  getTok(p)
  result = newNode(nkWhere)
  result.add(parseExpr(p))

proc parseIndexDef(p: var TSqlParser): PSqlNode =
  result = parseIfNotExists(p, nkCreateIndex)
  if isKeyw(p, "primary"):
    getTok(p)
    eat(p, "key")
    result.add(newNode(nkPrimaryKey))
  else:
    expectIdent(p)
    result.add(newNode(nkIdent, p.tok.literal))
    getTok(p)
  eat(p, "on")
  expectIdent(p)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  eat(p, tkParLe)
  expectIdent(p)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  while p.tok.kind == tkComma:
    getTok(p)
    expectIdent(p)
    result.add(newNode(nkIdent, p.tok.literal))
    getTok(p)
  eat(p, tkParRi)

proc parseInsert(p: var TSqlParser): PSqlNode =
  getTok(p)
  eat(p, "into")
  expectIdent(p)
  result = newNode(nkInsert)
  result.add(newNode(nkIdent, p.tok.literal))
  getTok(p)
  if p.tok.kind == tkParLe:
    var n = newNode(nkColumnList)
    parseParIdentList(p, n)
  else:
    result.add(nil)
  if isKeyw(p, "default"):
    getTok(p)
    eat(p, "values")
    result.add(newNode(nkDefault))
  else:
    eat(p, "values")
    eat(p, tkParLe)
    var n = newNode(nkValueList)
    while true:
      n.add(parseExpr(p))
      if p.tok.kind != tkComma: break
      getTok(p)
    result.add(n)
    eat(p, tkParRi)

proc parseUpdate(p: var TSqlParser): PSqlNode =
  getTok(p)
  result = newNode(nkUpdate)
  result.add(primary(p))
  eat(p, "set")
  while true:
    var a = newNode(nkAsgn)
    expectIdent(p)
    a.add(newNode(nkIdent, p.tok.literal))
    getTok(p)
    if isOpr(p, "="): getTok(p)
    else: sqlError(p, "= expected")
    a.add(parseExpr(p))
    result.add(a)
    if p.tok.kind != tkComma: break
    getTok(p)
  if isKeyw(p, "where"):
    result.add(parseWhere(p))
  else:
    result.add(nil)
    
proc parseDelete(p: var TSqlParser): PSqlNode =
  getTok(p)
  result = newNode(nkDelete)
  eat(p, "from")
  result.add(primary(p))
  if isKeyw(p, "where"):
    result.add(parseWhere(p))
  else:
    result.add(nil)

proc parseSelect(p: var TSqlParser): PSqlNode =
  getTok(p)
  if isKeyw(p, "distinct"):
    getTok(p)
    result = newNode(nkSelectDistinct)
  elif isKeyw(p, "all"):
    getTok(p)
  result = newNode(nkSelect)
  var a = newNode(nkSelectColumns)
  while true:
    if isOpr(p, "*"):
      a.add(newNode(nkIdent, "*"))
      getTok(p)
    else:
      a.add(parseExpr(p))
    if p.tok.kind != tkComma: break
    getTok(p)
  result.add(a)
  if isKeyw(p, "from"):
    var f = newNode(nkFrom)
    while true:
      getTok(p)
      f.add(parseExpr(p))
      if p.tok.kind != tkComma: break
    result.add(f)
  if isKeyw(p, "where"):
    result.add(parseWhere(p))
  if isKeyw(p, "group"):
    getTok(p)
    eat(p, "by")
    var g = newNode(nkGroup)
    while true:
      g.add(parseExpr(p))
      if p.tok.kind != tkComma: break
      getTok(p)
    result.add(g)
  if isKeyw(p, "having"):
    var h = newNode(nkHaving)
    while true:
      getTok(p)
      h.add(parseExpr(p))
      if p.tok.kind != tkComma: break    
    result.add(h)
  if isKeyw(p, "union"):
    result.add(newNode(nkUnion))
    getTok(p)
  elif isKeyw(p, "intersect"):
    result.add(newNode(nkIntersect))
    getTok(p)  
  elif isKeyw(p, "except"):
    result.add(newNode(nkExcept))
    getTok(p)
  if isKeyw(p, "order"):
    getTok(p)
    eat(p, "by")
    var n = newNode(nkOrder)
    while true:
      var e = parseExpr(p)
      if isKeyw(p, "asc"): getTok(p) # is default
      elif isKeyw(p, "desc"):
        getTok(p)
        var x = newNode(nkDesc)
        x.add(e)
        e = x
      n.add(e)
      if p.tok.kind != tkComma: break
      getTok(p)
    result.add(n)

proc parseStmt(p: var TSqlParser): PSqlNode =
  if isKeyw(p, "create"):
    getTok(p)
    optKeyw(p, "cached")
    optKeyw(p, "memory")
    optKeyw(p, "temp")
    optKeyw(p, "global")
    optKeyw(p, "local")
    optKeyw(p, "temporary")
    optKeyw(p, "unique")
    optKeyw(p, "hash")
    if isKeyw(p, "table"):
      result = parseTableDef(p)
    elif isKeyw(p, "type"):
      result = parseTypeDef(p)
    elif isKeyw(p, "index"):
      result = parseIndexDef(p)
    else:
      sqlError(p, "TABLE expected")
  elif isKeyw(p, "insert"):
    result = parseInsert(p)
  elif isKeyw(p, "update"):
    result = parseUpdate(p)
  elif isKeyw(p, "delete"):
    result = parseDelete(p)
  elif isKeyw(p, "select"):
    result = parseSelect(p)
  else:
    sqlError(p, "CREATE expected")

proc open(p: var TSqlParser, input: PStream, filename: string) =
  ## opens the parser `p` and assigns the input stream `input` to it.
  ## `filename` is only used for error messages.
  open(TSqlLexer(p), input, filename)
  p.tok.kind = tkInvalid
  p.tok.literal = ""
  getTok(p)
  
proc parse(p: var TSqlParser): PSqlNode =
  ## parses the content of `p`'s input stream and returns the SQL AST.
  ## Syntax errors raise an `EInvalidSql` exception.
  result = newNode(nkStmtList)
  while p.tok.kind != tkEof:
    var s = parseStmt(p)
    eat(p, tkSemiColon)
    result.add(s)
  if result.len == 1:
    result = result.sons[0]
  
proc close(p: var TSqlParser) =
  ## closes the parser `p`. The associated input stream is closed too.
  close(TSqlLexer(p))

proc parseSQL*(input: PStream, filename: string): PSqlNode =
  ## parses the SQL from `input` into an AST and returns the AST. 
  ## `filename` is only used for error messages.
  ## Syntax errors raise an `EInvalidSql` exception.
  var p: TSqlParser
  open(p, input, filename)
  try:
    result = parse(p)
  finally:
    close(p)

proc ra(n: PSqlNode, s: var string, indent: int)

proc rs(n: PSqlNode, s: var string, indent: int,
        prefix = "(", suffix = ")",
        sep = ", ") = 
  if n.len > 0:
    s.add(prefix)
    for i in 0 .. n.len-1:
      if i > 0: s.add(sep)
      ra(n.sons[i], s, indent)
    s.add(suffix)

proc ra(n: PSqlNode, s: var string, indent: int) =
  if n == nil: return
  case n.kind
  of nkNone: discard
  of nkIdent:
    if allCharsInSet(n.strVal, {'\33'..'\127'}):
      s.add(n.strVal)
    else:
      s.add("\"" & replace(n.strVal, "\"", "\"\"") & "\"")
  of nkStringLit:
    s.add(escape(n.strVal, "e'", "'"))
  of nkBitStringLit:
    s.add("b'" & n.strVal & "'")
  of nkHexStringLit:
    s.add("x'" & n.strVal & "'")
  of nkIntegerLit, nkNumericLit:
    s.add(n.strVal)
  of nkPrimaryKey:
    s.add(" primary key")
    rs(n, s, indent)
  of nkForeignKey:
    s.add(" foreign key")
    rs(n, s, indent)
  of nkNotNull:
    s.add(" not null")
  of nkDot:
    ra(n.sons[0], s, indent)
    s.add(".")
    ra(n.sons[1], s, indent)
  of nkDotDot:
    ra(n.sons[0], s, indent)
    s.add(". .")
    ra(n.sons[1], s, indent)
  of nkPrefix:
    s.add('(')
    ra(n.sons[0], s, indent)
    s.add(' ')
    ra(n.sons[1], s, indent)
    s.add(')')
  of nkInfix:
    s.add('(')    
    ra(n.sons[1], s, indent)
    s.add(' ')
    ra(n.sons[0], s, indent)
    s.add(' ')
    ra(n.sons[2], s, indent)
    s.add(')')
  of nkCall, nkColumnReference:
    ra(n.sons[0], s, indent)
    s.add('(')
    for i in 1..n.len-1:
      if i > 1: s.add(", ")
      ra(n.sons[i], s, indent)
    s.add(')')
  of nkReferences:
    s.add(" references ")
    ra(n.sons[0], s, indent)
  of nkDefault:
    s.add(" default ")
    ra(n.sons[0], s, indent)
  of nkCheck:
    s.add(" check ")
    ra(n.sons[0], s, indent)
  of nkConstraint:
    s.add(" constraint ")
    ra(n.sons[0], s, indent)
    s.add(" check ")
    ra(n.sons[1], s, indent)
  of nkUnique:
    s.add(" unique")
    rs(n, s, indent)
  of nkIdentity:
    s.add(" identity")
  of nkColumnDef:
    s.add("\n  ")
    rs(n, s, indent, "", "", " ")
  of nkStmtList:
    for i in 0..n.len-1:
      ra(n.sons[i], s, indent)
      s.add("\n")
  of nkInsert:
    assert n.len == 3
    s.add("insert into ")
    ra(n.sons[0], s, indent)
    ra(n.sons[1], s, indent)
    if n.sons[2].kind == nkDefault: 
      s.add("default values")
    else:
      s.add("\nvalues ")
      ra(n.sons[2], s, indent)
    s.add(';')
  of nkUpdate: 
    s.add("update ")
    ra(n.sons[0], s, indent)
    s.add(" set ")
    var L = n.len
    for i in 1 .. L-2:
      if i > 1: s.add(", ")
      var it = n.sons[i]
      assert it.kind == nkAsgn
      ra(it, s, indent)
    ra(n.sons[L-1], s, indent)
    s.add(';')
  of nkDelete: 
    s.add("delete from ")
    ra(n.sons[0], s, indent)
    ra(n.sons[1], s, indent)
    s.add(';')
  of nkSelect, nkSelectDistinct:
    s.add("select ")
    if n.kind == nkSelectDistinct:
      s.add("distinct ")
    rs(n.sons[0], s, indent, "", "", ", ")
    for i in 1 .. n.len-1: ra(n.sons[i], s, indent)
    s.add(';')
  of nkSelectColumns: 
    assert(false)
  of nkAsgn:
    ra(n.sons[0], s, indent)
    s.add(" = ")
    ra(n.sons[1], s, indent)  
  of nkFrom:
    s.add("\nfrom ")
    rs(n, s, indent, "", "", ", ")
  of nkGroup:
    s.add("\ngroup by")
    rs(n, s, indent, "", "", ", ")
  of nkHaving:
    s.add("\nhaving")
    rs(n, s, indent, "", "", ", ")
  of nkOrder:
    s.add("\norder by ")
    rs(n, s, indent, "", "", ", ")
  of nkDesc:
    ra(n.sons[0], s, indent)
    s.add(" desc")
  of nkUnion:
    s.add(" union")
  of nkIntersect:
    s.add(" intersect")
  of nkExcept:
    s.add(" except")
  of nkColumnList:
    rs(n, s, indent)
  of nkValueList:
    s.add("values ")
    rs(n, s, indent)
  of nkWhere:
    s.add("\nwhere ")
    ra(n.sons[0], s, indent)
  of nkCreateTable, nkCreateTableIfNotExists:
    s.add("create table ")
    if n.kind == nkCreateTableIfNotExists:
      s.add("if not exists ")
    ra(n.sons[0], s, indent)
    s.add('(')
    for i in 1..n.len-1:
      if i > 1: s.add(", ")
      ra(n.sons[i], s, indent)
    s.add(");")
  of nkCreateType, nkCreateTypeIfNotExists:
    s.add("create type ")
    if n.kind == nkCreateTypeIfNotExists:
      s.add("if not exists ")
    ra(n.sons[0], s, indent)
    s.add(" as ")
    ra(n.sons[1], s, indent)
    s.add(';')
  of nkCreateIndex, nkCreateIndexIfNotExists:
    s.add("create index ")
    if n.kind == nkCreateIndexIfNotExists:
      s.add("if not exists ")
    ra(n.sons[0], s, indent)
    s.add(" on ")
    ra(n.sons[1], s, indent)
    s.add('(')
    for i in 2..n.len-1:
      if i > 2: s.add(", ")
      ra(n.sons[i], s, indent)
    s.add(");")
  of nkEnumDef:
    s.add("enum ")
    rs(n, s, indent)

# What I want: 
#
#select(columns = [T1.all, T2.name], 
#       fromm = [T1, T2],
#       where = T1.name ==. T2.name,
#       orderby = [name]):
#  
#for row in dbQuery(db, """select x, y, z 
#                          from a, b 
#                          where a.name = b.name"""):
#  

#select x, y, z:
#  fromm: Table1, Table2
#  where: x.name == y.name
#db.select(fromm = [t1, t2], where = t1.name == t2.name):
#for x, y, z in db.select(fromm = a, b where = a.name == b.name): 
#  writeln x, y, z

proc renderSQL*(n: PSqlNode): string =
  ## Converts an SQL abstract syntax tree to its string representation.
  result = ""
  ra(n, result, 0)

when isMainModule:
  echo(renderSQL(parseSQL(newStringStream("""
      CREATE TYPE happiness AS ENUM ('happy', 'very happy', 'ecstatic');
      CREATE TABLE holidays (
         num_weeks int,
         happiness happiness
      );
      CREATE INDEX table1_attr1 ON table1(attr1);
      
      SELECT * FROM myTab WHERE col1 = 'happy';
  """), "stdin")))

# CREATE TYPE happiness AS ENUM ('happy', 'very happy', 'ecstatic');
# CREATE TABLE holidays (
#    num_weeks int,
#    happiness happiness
# );
# CREATE INDEX table1_attr1 ON table1(attr1)
