#
#
#      Pas2nim - Pascal to Nimrod source converter
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the parser of the Pascal variant Nimrod is written in.
# It transfers a Pascal module into a Nimrod AST. Then the renderer can be
# used to convert the AST to its text representation.

import
  os, llstream, paslex, idents, strutils, ast, astalgo, msgs, options

type
  TSection = enum
    seImplementation, seInterface
  TContext = enum
    conExpr, conStmt, conTypeDesc
  TParserFlag* = enum
    pfRefs,             ## use "ref" instead of "ptr" for Pascal's ^typ
    pfMoreReplacements, ## use more than the default replacements
    pfImportBlackList   ## use import blacklist
  TParser*{.final.} = object
    section: TSection
    inParamList: bool
    context: TContext     # needed for the @emit command
    lastVarSection: PNode
    lex: TLexer
    tok: TToken
    repl: TIdTable           # replacements
    flags: set[TParserFlag]

  TReplaceTuple* = array[0..1, string]

const
  ImportBlackList*: array[1..3, string] = ["nsystem", "sysutils", "charsets"]
  stdReplacements*: array[1..19, TReplaceTuple] = [["include", "incl"],
    ["exclude", "excl"], ["pchar", "cstring"], ["assignfile", "open"],
    ["integer", "int"], ["longword", "int32"], ["cardinal", "int"],
    ["boolean", "bool"], ["shortint", "int8"], ["smallint", "int16"],
    ["longint", "int32"], ["byte", "int8"], ["word", "int16"],
    ["single", "float32"], ["double", "float64"], ["real", "float"],
    ["length", "len"], ["len", "length"], ["setlength", "setlen"]]
  nimReplacements*: array[1..35, TReplaceTuple] = [["nimread", "read"],
    ["nimwrite", "write"], ["nimclosefile", "close"], ["closefile", "close"],
    ["openfile", "open"], ["nsystem", "system"], ["ntime", "times"],
    ["nos", "os"], ["nmath", "math"], ["ncopy", "copy"], ["addChar", "add"],
    ["halt", "quit"], ["nobject", "TObject"], ["eof", "EndOfFile"],
    ["input", "stdin"], ["output", "stdout"], ["addu", "`+%`"],
    ["subu", "`-%`"], ["mulu", "`*%`"], ["divu", "`/%`"], ["modu", "`%%`"],
    ["ltu", "`<%`"], ["leu", "`<=%`"], ["shlu", "`shl`"], ["shru", "`shr`"],
    ["assigned", "not isNil"], ["eintoverflow", "EOverflow"], ["format", "`%`"],
    ["snil", "nil"], ["tostringf", "$"], ["ttextfile", "tfile"],
    ["tbinaryfile", "tfile"], ["strstart", "0"], ["nl", "\"\\n\""],
    ["tostring", "$"]]

proc ParseUnit*(p: var TParser): PNode
proc openParser*(p: var TParser, filename: string, inputStream: PLLStream,
                 flags: set[TParserFlag] = {})
proc closeParser*(p: var TParser)
proc exSymbol*(n: var PNode)
proc fixRecordDef*(n: var PNode)
  # XXX: move these two to an auxiliary module

# implementation

proc OpenParser(p: var TParser, filename: string,
                inputStream: PLLStream, flags: set[TParserFlag] = {}) =
  OpenLexer(p.lex, filename, inputStream)
  initIdTable(p.repl)
  for i in countup(low(stdReplacements), high(stdReplacements)):
    IdTablePut(p.repl, getIdent(stdReplacements[i][0]),
               getIdent(stdReplacements[i][1]))
  if pfMoreReplacements in flags:
    for i in countup(low(nimReplacements), high(nimReplacements)):
      IdTablePut(p.repl, getIdent(nimReplacements[i][0]),
                 getIdent(nimReplacements[i][1]))
  p.flags = flags

proc CloseParser(p: var TParser) = CloseLexer(p.lex)
proc getTok(p: var TParser) = getTok(p.lex, p.tok)

proc parMessage(p: TParser, msg: TMsgKind, arg = "") =
  lexMessage(p.lex, msg, arg)

proc parLineInfo(p: TParser): TLineInfo =
  result = getLineInfo(p.lex)

proc skipCom(p: var TParser, n: PNode) =
  while p.tok.xkind == pxComment:
    if (n != nil):
      if n.comment == nil: n.comment = p.tok.literal
      else: add(n.comment, "\n" & p.tok.literal)
    else:
      parMessage(p, warnCommentXIgnored, p.tok.literal)
    getTok(p)

proc ExpectIdent(p: TParser) =
  if p.tok.xkind != pxSymbol:
    lexMessage(p.lex, errIdentifierExpected, $(p.tok))

proc Eat(p: var TParser, xkind: TTokKind) =
  if p.tok.xkind == xkind: getTok(p)
  else: lexMessage(p.lex, errTokenExpected, TokKindToStr(xkind))

proc Opt(p: var TParser, xkind: TTokKind) =
  if p.tok.xkind == xkind: getTok(p)

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

proc createIdentNodeP(ident: PIdent, p: TParser): PNode =
  result = newNodeP(nkIdent, p)
  var x = PIdent(IdTableGet(p.repl, ident))
  if x != nil: result.ident = x
  else: result.ident = ident

proc parseExpr(p: var TParser): PNode
proc parseStmt(p: var TParser): PNode
proc parseTypeDesc(p: var TParser, definition: PNode = nil): PNode

proc parseEmit(p: var TParser, definition: PNode): PNode =
  getTok(p)                   # skip 'emit'
  result = ast.emptyNode
  if p.tok.xkind != pxCurlyDirRi:
    case p.context
    of conExpr:
      result = parseExpr(p)
    of conStmt:
      result = parseStmt(p)
      if p.tok.xkind != pxCurlyDirRi:
        var a = result
        result = newNodeP(nkStmtList, p)
        addSon(result, a)
        while p.tok.xkind != pxCurlyDirRi:
          addSon(result, parseStmt(p))
    of conTypeDesc:
      result = parseTypeDesc(p, definition)
  eat(p, pxCurlyDirRi)

proc parseCommand(p: var TParser, definition: PNode = nil): PNode =
  result = ast.emptyNode
  getTok(p)
  if p.tok.ident.id == getIdent("discard").id:
    result = newNodeP(nkDiscardStmt, p)
    getTok(p)
    eat(p, pxCurlyDirRi)
    addSon(result, parseExpr(p))
  elif p.tok.ident.id == getIdent("set").id:
    getTok(p)
    eat(p, pxCurlyDirRi)
    result = parseExpr(p)
    if result.kind == nkEmpty: InternalError("emptyNode modified")
    result.kind = nkCurly
  elif p.tok.ident.id == getIdent("cast").id:
    getTok(p)
    eat(p, pxCurlyDirRi)
    var a = parseExpr(p)
    if (a.kind == nkCall) and (sonsLen(a) == 2):
      result = newNodeP(nkCast, p)
      addSon(result, a.sons[0])
      addSon(result, a.sons[1])
    else:
      parMessage(p, errInvalidDirectiveX, $p.tok)
      result = a
  elif p.tok.ident.id == getIdent("emit").id:
    result = parseEmit(p, definition)
  elif p.tok.ident.id == getIdent("ignore").id:
    getTok(p)
    eat(p, pxCurlyDirRi)
    while true:
      case p.tok.xkind
      of pxEof:
        parMessage(p, errTokenExpected, "{@emit}")
      of pxCommand:
        getTok(p)
        if p.tok.ident.id == getIdent("emit").id:
          result = parseEmit(p, definition)
          break
        else:
          while (p.tok.xkind != pxCurlyDirRi) and (p.tok.xkind != pxEof):
            getTok(p)
          eat(p, pxCurlyDirRi)
      else:
        getTok(p)             # skip token
  elif p.tok.ident.id == getIdent("ptr").id:
    result = newNodeP(nkPtrTy, p)
    getTok(p)
    eat(p, pxCurlyDirRi)
  elif p.tok.ident.id == getIdent("tuple").id:
    result = newNodeP(nkTupleTy, p)
    getTok(p)
    eat(p, pxCurlyDirRi)
  elif p.tok.ident.id == getIdent("acyclic").id:
    result = newIdentNodeP(p.tok.ident, p)
    getTok(p)
    eat(p, pxCurlyDirRi)
  else:
    parMessage(p, errInvalidDirectiveX, $p.tok)
    while true:
      getTok(p)
      if p.tok.xkind == pxCurlyDirRi or p.tok.xkind == pxEof: break
    eat(p, pxCurlyDirRi)
    result = ast.emptyNode

proc getPrecedence(kind: TTokKind): int =
  case kind
  of pxDiv, pxMod, pxStar, pxSlash, pxShl, pxShr, pxAnd: result = 5
  of pxPlus, pxMinus, pxOr, pxXor: result = 4
  of pxIn, pxEquals, pxLe, pxLt, pxGe, pxGt, pxNeq, pxIs: result = 3
  else: result = -1

proc rangeExpr(p: var TParser): PNode =
  var a = parseExpr(p)
  if p.tok.xkind == pxDotDot:
    result = newNodeP(nkRange, p)
    addSon(result, a)
    getTok(p)
    skipCom(p, result)
    addSon(result, parseExpr(p))
  else:
    result = a

proc bracketExprList(p: var TParser, first: PNode): PNode =
  result = newNodeP(nkBracketExpr, p)
  addSon(result, first)
  getTok(p)
  skipCom(p, result)
  while true:
    if p.tok.xkind == pxBracketRi:
      getTok(p)
      break
    if p.tok.xkind == pxEof:
      parMessage(p, errTokenExpected, TokKindToStr(pxBracketRi))
      break
    var a = rangeExpr(p)
    skipCom(p, a)
    if p.tok.xkind == pxComma:
      getTok(p)
      skipCom(p, a)
    addSon(result, a)

proc exprColonEqExpr(p: var TParser, kind: TNodeKind,
                     tok: TTokKind): PNode =
  var a = parseExpr(p)
  if p.tok.xkind == tok:
    result = newNodeP(kind, p)
    getTok(p)
    skipCom(p, result)
    addSon(result, a)
    addSon(result, parseExpr(p))
  else:
    result = a

proc exprListAux(p: var TParser, elemKind: TNodeKind,
                 endTok, sepTok: TTokKind, result: PNode) =
  getTok(p)
  skipCom(p, result)
  while true:
    if p.tok.xkind == endTok:
      getTok(p)
      break
    if p.tok.xkind == pxEof:
      parMessage(p, errTokenExpected, TokKindToStr(endtok))
      break
    var a = exprColonEqExpr(p, elemKind, sepTok)
    skipCom(p, a)
    if (p.tok.xkind == pxComma) or (p.tok.xkind == pxSemicolon):
      getTok(p)
      skipCom(p, a)
    addSon(result, a)

proc qualifiedIdent(p: var TParser): PNode =
  if p.tok.xkind == pxSymbol:
    result = createIdentNodeP(p.tok.ident, p)
  else:
    parMessage(p, errIdentifierExpected, $p.tok)
    return ast.emptyNode
  getTok(p)
  skipCom(p, result)
  if p.tok.xkind == pxDot:
    getTok(p)
    skipCom(p, result)
    if p.tok.xkind == pxSymbol:
      var a = result
      result = newNodeI(nkDotExpr, a.info)
      addSon(result, a)
      addSon(result, createIdentNodeP(p.tok.ident, p))
      getTok(p)
    else:
      parMessage(p, errIdentifierExpected, $p.tok)

proc qualifiedIdentListAux(p: var TParser, endTok: TTokKind,
                           result: PNode) =
  getTok(p)
  skipCom(p, result)
  while true:
    if p.tok.xkind == endTok:
      getTok(p)
      break
    if p.tok.xkind == pxEof:
      parMessage(p, errTokenExpected, TokKindToStr(endtok))
      break
    var a = qualifiedIdent(p)
    skipCom(p, a)
    if p.tok.xkind == pxComma:
      getTok(p)
      skipCom(p, a)
    addSon(result, a)

proc exprColonEqExprList(p: var TParser, kind, elemKind: TNodeKind,
                         endTok, sepTok: TTokKind): PNode =
  result = newNodeP(kind, p)
  exprListAux(p, elemKind, endTok, sepTok, result)

proc setBaseFlags(n: PNode, base: TNumericalBase) =
  case base
  of base10: nil
  of base2: incl(n.flags, nfBase2)
  of base8: incl(n.flags, nfBase8)
  of base16: incl(n.flags, nfBase16)

proc identOrLiteral(p: var TParser): PNode =
  case p.tok.xkind
  of pxSymbol:
    result = createIdentNodeP(p.tok.ident, p)
    getTok(p)
  of pxIntLit:
    result = newIntNodeP(nkIntLit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of pxInt64Lit:
    result = newIntNodeP(nkInt64Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of pxFloatLit:
    result = newFloatNodeP(nkFloatLit, p.tok.fNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p)
  of pxStrLit:
    if len(p.tok.literal) != 1: result = newStrNodeP(nkStrLit, p.tok.literal, p)
    else: result = newIntNodeP(nkCharLit, ord(p.tok.literal[0]), p)
    getTok(p)
  of pxNil:
    result = newNodeP(nkNilLit, p)
    getTok(p)
  of pxParLe:
    # () constructor
    result = exprColonEqExprList(p, nkPar, nkExprColonExpr, pxParRi, pxColon)
    #if hasSonWith(result, nkExprColonExpr) then
    #  replaceSons(result, nkExprColonExpr, nkExprEqExpr)
    if (sonsLen(result) > 1) and not hasSonWith(result, nkExprColonExpr):
      result.kind = nkBracket # is an array constructor
  of pxBracketLe:
    # [] constructor
    result = newNodeP(nkBracket, p)
    getTok(p)
    skipCom(p, result)
    while (p.tok.xkind != pxBracketRi) and (p.tok.xkind != pxEof):
      var a = rangeExpr(p)
      if a.kind == nkRange:
        result.kind = nkCurly # it is definitely a set literal
      opt(p, pxComma)
      skipCom(p, a)
      assert(a != nil)
      addSon(result, a)
    eat(p, pxBracketRi)
  of pxCommand:
    result = parseCommand(p)
  else:
    parMessage(p, errExprExpected, $(p.tok))
    getTok(p) # we must consume a token here to prevend endless loops!
    result = ast.emptyNode
  if result.kind != nkEmpty: skipCom(p, result)

proc primary(p: var TParser): PNode =
  # prefix operator?
  if (p.tok.xkind == pxNot) or (p.tok.xkind == pxMinus) or
      (p.tok.xkind == pxPlus):
    result = newNodeP(nkPrefix, p)
    var a = newIdentNodeP(getIdent($p.tok), p)
    addSon(result, a)
    getTok(p)
    skipCom(p, a)
    addSon(result, primary(p))
    return
  elif p.tok.xkind == pxAt:
    result = newNodeP(nkAddr, p)
    var a = newIdentNodeP(getIdent($p.tok), p)
    getTok(p)
    if p.tok.xkind == pxBracketLe:
      result = newNodeP(nkPrefix, p)
      addSon(result, a)
      addSon(result, identOrLiteral(p))
    else:
      addSon(result, primary(p))
    return
  result = identOrLiteral(p)
  while true:
    case p.tok.xkind
    of pxParLe:
      var a = result
      result = newNodeP(nkCall, p)
      addSon(result, a)
      exprListAux(p, nkExprEqExpr, pxParRi, pxEquals, result)
    of pxDot:
      var a = result
      result = newNodeP(nkDotExpr, p)
      addSon(result, a)
      getTok(p)               # skip '.'
      skipCom(p, result)
      if p.tok.xkind == pxSymbol:
        addSon(result, createIdentNodeP(p.tok.ident, p))
        getTok(p)
      else:
        parMessage(p, errIdentifierExpected, $p.tok)
    of pxHat:
      var a = result
      result = newNodeP(nkBracketExpr, p)
      addSon(result, a)
      getTok(p)
    of pxBracketLe:
      result = bracketExprList(p, result)
    else: break

proc lowestExprAux(p: var TParser, v: var PNode, limit: int): TTokKind =
  var
    nextop: TTokKind
    v2, node, opNode: PNode
  v = primary(p) # expand while operators have priorities higher than 'limit'
  var op = p.tok.xkind
  var opPred = getPrecedence(op)
  while (opPred > limit):
    node = newNodeP(nkInfix, p)
    opNode = newIdentNodeP(getIdent($(p.tok)), p) # skip operator:
    getTok(p)
    case op
    of pxPlus:
      case p.tok.xkind
      of pxPer:
        getTok(p)
        eat(p, pxCurlyDirRi)
        opNode.ident = getIdent("+%")
      of pxAmp:
        getTok(p)
        eat(p, pxCurlyDirRi)
        opNode.ident = getIdent("&")
      else:
        nil
    of pxMinus:
      if p.tok.xkind == pxPer:
        getTok(p)
        eat(p, pxCurlyDirRi)
        opNode.ident = getIdent("-%")
    of pxEquals:
      opNode.ident = getIdent("==")
    of pxNeq:
      opNode.ident = getIdent("!=")
    else:
      nil
    skipCom(p, opNode)        # read sub-expression with higher priority
    nextop = lowestExprAux(p, v2, opPred)
    addSon(node, opNode)
    addSon(node, v)
    addSon(node, v2)
    v = node
    op = nextop
    opPred = getPrecedence(nextop)
  result = op                 # return first untreated operator

proc fixExpr(n: PNode): PNode =
  result = n
  case n.kind
  of nkInfix:
    if n.sons[1].kind == nkBracket: n.sons[1].kind = nkCurly
    if n.sons[2].kind == nkBracket: n.sons[2].kind = nkCurly
    if (n.sons[0].kind == nkIdent):
      if (n.sons[0].ident.id == getIdent("+").id):
        if (n.sons[1].kind == nkCharLit) and (n.sons[2].kind == nkStrLit) and
            (n.sons[2].strVal == ""):
          result = newStrNode(nkStrLit, chr(int(n.sons[1].intVal)) & "")
          result.info = n.info
          return              # do not process sons as they don't exist anymore
        elif (n.sons[1].kind in {nkCharLit, nkStrLit}) or
            (n.sons[2].kind in {nkCharLit, nkStrLit}):
          n.sons[0].ident = getIdent("&") # fix operator
  else:
    nil
  if not (n.kind in {nkEmpty..nkNilLit}):
    for i in countup(0, sonsLen(n) - 1): result.sons[i] = fixExpr(n.sons[i])

proc parseExpr(p: var TParser): PNode =
  var oldcontext = p.context
  p.context = conExpr
  if p.tok.xkind == pxCommand:
    result = parseCommand(p)
  else:
    discard lowestExprAux(p, result, - 1)
    result = fixExpr(result)
  p.context = oldcontext

proc parseExprStmt(p: var TParser): PNode =
  var info = parLineInfo(p)
  var a = parseExpr(p)
  if p.tok.xkind == pxAsgn:
    getTok(p)
    skipCom(p, a)
    var b = parseExpr(p)
    result = newNodeI(nkAsgn, info)
    addSon(result, a)
    addSon(result, b)
  else:
    result = a

proc inImportBlackList(ident: PIdent): bool =
  for i in countup(low(ImportBlackList), high(ImportBlackList)):
    if ident.id == getIdent(ImportBlackList[i]).id:
      return true

proc parseUsesStmt(p: var TParser): PNode =
  var a: PNode
  result = newNodeP(nkImportStmt, p)
  getTok(p)                   # skip `import`
  skipCom(p, result)
  while true:
    case p.tok.xkind
    of pxEof: break
    of pxSymbol: a = newIdentNodeP(p.tok.ident, p)
    else:
      parMessage(p, errIdentifierExpected, $(p.tok))
      break
    getTok(p)                 # skip identifier, string
    skipCom(p, a)
    if pfImportBlackList notin p.flags or not inImportBlackList(a.ident):
      addSon(result, createIdentNodeP(a.ident, p))
    if p.tok.xkind == pxComma:
      getTok(p)
      skipCom(p, a)
    else:
      break
  if sonsLen(result) == 0: result = ast.emptyNode

proc parseIncludeDir(p: var TParser): PNode =
  result = newNodeP(nkIncludeStmt, p)
  getTok(p)                   # skip `include`
  var filename = ""
  while true:
    case p.tok.xkind
    of pxSymbol, pxDot, pxDotDot, pxSlash:
      add(filename, $p.tok)
      getTok(p)
    of pxStrLit:
      filename = p.tok.literal
      getTok(p)
      break
    of pxCurlyDirRi:
      break
    else:
      parMessage(p, errIdentifierExpected, $p.tok)
      break
  addSon(result, newStrNodeP(nkStrLit, changeFileExt(filename, "nim"), p))
  if filename == "config.inc": result = ast.emptyNode

proc definedExprAux(p: var TParser): PNode =
  result = newNodeP(nkCall, p)
  addSon(result, newIdentNodeP(getIdent("defined"), p))
  ExpectIdent(p)
  addSon(result, createIdentNodeP(p.tok.ident, p))
  getTok(p)

proc isHandledDirective(p: TParser): bool =
  if p.tok.xkind in {pxCurlyDirLe, pxStarDirLe}:
    case toLower(p.tok.ident.s)
    of "else", "endif": result = false
    else: result = true

proc parseStmtList(p: var TParser): PNode =
  result = newNodeP(nkStmtList, p)
  while true:
    case p.tok.xkind
    of pxEof:
      break
    of pxCurlyDirLe, pxStarDirLe:
      if not isHandledDirective(p): break
    else:
      nil
    addSon(result, parseStmt(p))
  if sonsLen(result) == 1: result = result.sons[0]

proc parseIfDirAux(p: var TParser, result: PNode) =
  addSon(result.sons[0], parseStmtList(p))
  if p.tok.xkind in {pxCurlyDirLe, pxStarDirLe}:
    var endMarker = succ(p.tok.xkind)
    if toLower(p.tok.ident.s) == "else":
      var s = newNodeP(nkElse, p)
      while p.tok.xkind != pxEof and p.tok.xkind != endMarker: getTok(p)
      eat(p, endMarker)
      addSon(s, parseStmtList(p))
      addSon(result, s)
    if p.tok.xkind in {pxCurlyDirLe, pxStarDirLe}:
      endMarker = succ(p.tok.xkind)
      if toLower(p.tok.ident.s) == "endif":
        while p.tok.xkind != pxEof and p.tok.xkind != endMarker: getTok(p)
        eat(p, endMarker)
      else:
        parMessage(p, errXExpected, "{$endif}")
  else:
    parMessage(p, errXExpected, "{$endif}")

proc parseIfdefDir(p: var TParser, endMarker: TTokKind): PNode =
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  addSon(result.sons[0], definedExprAux(p))
  eat(p, endMarker)
  parseIfDirAux(p, result)

proc parseIfndefDir(p: var TParser, endMarker: TTokKind): PNode =
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  var e = newNodeP(nkCall, p)
  addSon(e, newIdentNodeP(getIdent("not"), p))
  addSon(e, definedExprAux(p))
  eat(p, endMarker)
  addSon(result.sons[0], e)
  parseIfDirAux(p, result)

proc parseIfDir(p: var TParser, endMarker: TTokKind): PNode =
  result = newNodeP(nkWhenStmt, p)
  addSon(result, newNodeP(nkElifBranch, p))
  getTok(p)
  addSon(result.sons[0], parseExpr(p))
  eat(p, endMarker)
  parseIfDirAux(p, result)

proc parseDirective(p: var TParser): PNode =
  result = ast.emptyNode
  if not (p.tok.xkind in {pxCurlyDirLe, pxStarDirLe}): return
  var endMarker = succ(p.tok.xkind)
  if p.tok.ident != nil:
    case toLower(p.tok.ident.s)
    of "include":
      result = parseIncludeDir(p)
      eat(p, endMarker)
    of "if": result = parseIfDir(p, endMarker)
    of "ifdef": result = parseIfdefDir(p, endMarker)
    of "ifndef": result = parseIfndefDir(p, endMarker)
    else:
      # skip unknown compiler directive
      while p.tok.xkind != pxEof and p.tok.xkind != endMarker: getTok(p)
      eat(p, endMarker)
  else:
    eat(p, endMarker)

proc parseRaise(p: var TParser): PNode =
  result = newNodeP(nkRaiseStmt, p)
  getTok(p)
  skipCom(p, result)
  if p.tok.xkind != pxSemicolon: addSon(result, parseExpr(p))
  else: addSon(result, ast.emptyNode)

proc parseIf(p: var TParser): PNode =
  result = newNodeP(nkIfStmt, p)
  while true:
    getTok(p)                 # skip ``if``
    var branch = newNodeP(nkElifBranch, p)
    skipCom(p, branch)
    addSon(branch, parseExpr(p))
    eat(p, pxThen)
    skipCom(p, branch)
    addSon(branch, parseStmt(p))
    skipCom(p, branch)
    addSon(result, branch)
    if p.tok.xkind == pxElse:
      getTok(p)
      if p.tok.xkind != pxIf:
        # ordinary else part:
        branch = newNodeP(nkElse, p)
        skipCom(p, result)    # BUGFIX
        addSon(branch, parseStmt(p))
        addSon(result, branch)
        break
    else:
      break

proc parseWhile(p: var TParser): PNode =
  result = newNodeP(nkWhileStmt, p)
  getTok(p)
  skipCom(p, result)
  addSon(result, parseExpr(p))
  eat(p, pxDo)
  skipCom(p, result)
  addSon(result, parseStmt(p))

proc parseRepeat(p: var TParser): PNode =
  result = newNodeP(nkWhileStmt, p)
  getTok(p)
  skipCom(p, result)
  addSon(result, newIdentNodeP(getIdent("true"), p))
  var s = newNodeP(nkStmtList, p)
  while p.tok.xkind != pxEof and p.tok.xkind != pxUntil:
    addSon(s, parseStmt(p))
  eat(p, pxUntil)
  var a = newNodeP(nkIfStmt, p)
  skipCom(p, a)
  var b = newNodeP(nkElifBranch, p)
  var c = newNodeP(nkBreakStmt, p)
  addSon(c, ast.emptyNode)
  addSon(b, parseExpr(p))
  skipCom(p, a)
  addSon(b, c)
  addSon(a, b)
  if b.sons[0].kind == nkIdent and b.sons[0].ident.id == getIdent("false").id:
    nil
  else:
    addSon(s, a)
  addSon(result, s)

proc parseCase(p: var TParser): PNode =
  var b: PNode
  result = newNodeP(nkCaseStmt, p)
  getTok(p)
  addSon(result, parseExpr(p))
  eat(p, pxOf)
  skipCom(p, result)
  while (p.tok.xkind != pxEnd) and (p.tok.xkind != pxEof):
    if p.tok.xkind == pxElse:
      b = newNodeP(nkElse, p)
      getTok(p)
    else:
      b = newNodeP(nkOfBranch, p)
      while (p.tok.xkind != pxEof) and (p.tok.xkind != pxColon):
        addSon(b, rangeExpr(p))
        opt(p, pxComma)
        skipcom(p, b)
      eat(p, pxColon)
    skipCom(p, b)
    addSon(b, parseStmt(p))
    addSon(result, b)
    if b.kind == nkElse: break
  eat(p, pxEnd)

proc parseTry(p: var TParser): PNode =
  result = newNodeP(nkTryStmt, p)
  getTok(p)
  skipCom(p, result)
  var b = newNodeP(nkStmtList, p)
  while not (p.tok.xkind in {pxFinally, pxExcept, pxEof, pxEnd}):
    addSon(b, parseStmt(p))
  addSon(result, b)
  if p.tok.xkind == pxExcept:
    getTok(p)
    while p.tok.ident.id == getIdent("on").id:
      b = newNodeP(nkExceptBranch, p)
      getTok(p)
      var e = qualifiedIdent(p)
      if p.tok.xkind == pxColon:
        getTok(p)
        e = qualifiedIdent(p)
      addSon(b, e)
      eat(p, pxDo)
      addSon(b, parseStmt(p))
      addSon(result, b)
      if p.tok.xkind == pxCommand: discard parseCommand(p)
    if p.tok.xkind == pxElse:
      b = newNodeP(nkExceptBranch, p)
      getTok(p)
      addSon(b, parseStmt(p))
      addSon(result, b)
  if p.tok.xkind == pxFinally:
    b = newNodeP(nkFinally, p)
    getTok(p)
    var e = newNodeP(nkStmtList, p)
    while (p.tok.xkind != pxEof) and (p.tok.xkind != pxEnd):
      addSon(e, parseStmt(p))
    if sonsLen(e) == 0: addSon(e, newNodeP(nkNilLit, p))
    addSon(result, e)
  eat(p, pxEnd)

proc parseFor(p: var TParser): PNode =
  result = newNodeP(nkForStmt, p)
  getTok(p)
  skipCom(p, result)
  expectIdent(p)
  addSon(result, createIdentNodeP(p.tok.ident, p))
  getTok(p)
  eat(p, pxAsgn)
  var a = parseExpr(p)
  var b = ast.emptyNode
  var c = newNodeP(nkCall, p)
  if p.tok.xkind == pxTo:
    addSon(c, newIdentNodeP(getIdent("countup"), p))
    getTok(p)
    b = parseExpr(p)
  elif p.tok.xkind == pxDownto:
    addSon(c, newIdentNodeP(getIdent("countdown"), p))
    getTok(p)
    b = parseExpr(p)
  else:
    parMessage(p, errTokenExpected, TokKindToStr(pxTo))
  addSon(c, a)
  addSon(c, b)
  eat(p, pxDo)
  skipCom(p, result)
  addSon(result, c)
  addSon(result, parseStmt(p))

proc parseParam(p: var TParser): PNode =
  var a: PNode
  result = newNodeP(nkIdentDefs, p)
  var v = ast.emptyNode
  case p.tok.xkind
  of pxConst:
    getTok(p)
  of pxVar:
    getTok(p)
    v = newNodeP(nkVarTy, p)
  of pxOut:
    getTok(p)
    v = newNodeP(nkVarTy, p)
  else:
    nil
  while true:
    case p.tok.xkind
    of pxSymbol: a = createIdentNodeP(p.tok.ident, p)
    of pxColon, pxEof, pxParRi, pxEquals: break
    else:
      parMessage(p, errIdentifierExpected, $p.tok)
      return
    getTok(p)                 # skip identifier
    skipCom(p, a)
    if p.tok.xkind == pxComma:
      getTok(p)
      skipCom(p, a)
    addSon(result, a)
  if p.tok.xkind == pxColon:
    getTok(p)
    skipCom(p, result)
    if v.kind != nkEmpty: addSon(v, parseTypeDesc(p))
    else: v = parseTypeDesc(p)
    addSon(result, v)
  else:
    addSon(result, ast.emptyNode)
    if p.tok.xkind != pxEquals:
      parMessage(p, errColonOrEqualsExpected, $p.tok)
  if p.tok.xkind == pxEquals:
    getTok(p)
    skipCom(p, result)
    addSon(result, parseExpr(p))
  else:
    addSon(result, ast.emptyNode)

proc parseParamList(p: var TParser): PNode =
  var a: PNode
  result = newNodeP(nkFormalParams, p)
  addSon(result, ast.emptyNode)         # return type
  if p.tok.xkind == pxParLe:
    p.inParamList = true
    getTok(p)
    skipCom(p, result)
    while true:
      case p.tok.xkind
      of pxSymbol, pxConst, pxVar, pxOut:
        a = parseParam(p)
      of pxParRi:
        getTok(p)
        break
      else:
        parMessage(p, errTokenExpected, ")")
        break
      skipCom(p, a)
      if p.tok.xkind == pxSemicolon:
        getTok(p)
        skipCom(p, a)
      addSon(result, a)
    p.inParamList = false
  if p.tok.xkind == pxColon:
    getTok(p)
    skipCom(p, result)
    result.sons[0] = parseTypeDesc(p)

proc parseCallingConvention(p: var TParser): PNode =
  result = ast.emptyNode
  if p.tok.xkind == pxSymbol:
    case toLower(p.tok.ident.s)
    of "stdcall", "cdecl", "safecall", "syscall", "inline", "fastcall":
      result = newNodeP(nkPragma, p)
      addSon(result, newIdentNodeP(p.tok.ident, p))
      getTok(p)
      opt(p, pxSemicolon)
    of "register":
      result = newNodeP(nkPragma, p)
      addSon(result, newIdentNodeP(getIdent("fastcall"), p))
      getTok(p)
      opt(p, pxSemicolon)
    else:
      nil

proc parseRoutineSpecifiers(p: var TParser, noBody: var bool): PNode =
  var e: PNode
  result = parseCallingConvention(p)
  noBody = false
  while p.tok.xkind == pxSymbol:
    case toLower(p.tok.ident.s)
    of "assembler", "overload", "far":
      getTok(p)
      opt(p, pxSemicolon)
    of "forward":
      noBody = true
      getTok(p)
      opt(p, pxSemicolon)
    of "importc":
      # This is a fake for platform module. There is no ``importc``
      # directive in Pascal.
      if result.kind == nkEmpty: result = newNodeP(nkPragma, p)
      addSon(result, newIdentNodeP(getIdent("importc"), p))
      noBody = true
      getTok(p)
      opt(p, pxSemicolon)
    of "noconv":
      # This is a fake for platform module. There is no ``noconv``
      # directive in Pascal.
      if result.kind == nkEmpty: result = newNodeP(nkPragma, p)
      addSon(result, newIdentNodeP(getIdent("noconv"), p))
      noBody = true
      getTok(p)
      opt(p, pxSemicolon)
    of "procvar":
      # This is a fake for the Nimrod compiler. There is no ``procvar``
      # directive in Pascal.
      if result.kind == nkEmpty: result = newNodeP(nkPragma, p)
      addSon(result, newIdentNodeP(getIdent("procvar"), p))
      getTok(p)
      opt(p, pxSemicolon)
    of "varargs":
      if result.kind == nkEmpty: result = newNodeP(nkPragma, p)
      addSon(result, newIdentNodeP(getIdent("varargs"), p))
      getTok(p)
      opt(p, pxSemicolon)
    of "external":
      if result.kind == nkEmpty: result = newNodeP(nkPragma, p)
      getTok(p)
      noBody = true
      e = newNodeP(nkExprColonExpr, p)
      addSon(e, newIdentNodeP(getIdent("dynlib"), p))
      addSon(e, parseExpr(p))
      addSon(result, e)
      opt(p, pxSemicolon)
      if (p.tok.xkind == pxSymbol) and
          (p.tok.ident.id == getIdent("name").id):
        e = newNodeP(nkExprColonExpr, p)
        getTok(p)
        addSon(e, newIdentNodeP(getIdent("importc"), p))
        addSon(e, parseExpr(p))
        addSon(result, e)
      else:
        addSon(result, newIdentNodeP(getIdent("importc"), p))
      opt(p, pxSemicolon)
    else:
      e = parseCallingConvention(p)
      if e.kind == nkEmpty: break
      if result.kind == nkEmpty: result = newNodeP(nkPragma, p)
      addSon(result, e.sons[0])

proc parseRoutineType(p: var TParser): PNode =
  result = newNodeP(nkProcTy, p)
  getTok(p)
  skipCom(p, result)
  addSon(result, parseParamList(p))
  opt(p, pxSemicolon)
  addSon(result, parseCallingConvention(p))
  skipCom(p, result)

proc parseEnum(p: var TParser): PNode =
  var a: PNode
  result = newNodeP(nkEnumTy, p)
  getTok(p)
  skipCom(p, result)
  addSon(result, ast.emptyNode) # it does not inherit from any enumeration
  while true:
    case p.tok.xkind
    of pxEof, pxParRi: break
    of pxSymbol: a = newIdentNodeP(p.tok.ident, p)
    else:
      parMessage(p, errIdentifierExpected, $(p.tok))
      break
    getTok(p)                 # skip identifier
    skipCom(p, a)
    if (p.tok.xkind == pxEquals) or (p.tok.xkind == pxAsgn):
      getTok(p)
      skipCom(p, a)
      var b = a
      a = newNodeP(nkEnumFieldDef, p)
      addSon(a, b)
      addSon(a, parseExpr(p))
    if p.tok.xkind == pxComma:
      getTok(p)
      skipCom(p, a)
    addSon(result, a)
  eat(p, pxParRi)

proc identVis(p: var TParser): PNode =
  # identifier with visability
  var a = createIdentNodeP(p.tok.ident, p)
  if p.section == seInterface:
    result = newNodeP(nkPostfix, p)
    addSon(result, newIdentNodeP(getIdent("*"), p))
    addSon(result, a)
  else:
    result = a
  getTok(p)

type
  TSymbolParser = proc (p: var TParser): PNode {.nimcall.}

proc rawIdent(p: var TParser): PNode =
  result = createIdentNodeP(p.tok.ident, p)
  getTok(p)

proc parseIdentColonEquals(p: var TParser,
                           identParser: TSymbolParser): PNode =
  var a: PNode
  result = newNodeP(nkIdentDefs, p)
  while true:
    case p.tok.xkind
    of pxSymbol: a = identParser(p)
    of pxColon, pxEof, pxParRi, pxEquals: break
    else:
      parMessage(p, errIdentifierExpected, $(p.tok))
      return
    skipCom(p, a)
    if p.tok.xkind == pxComma:
      getTok(p)
      skipCom(p, a)
    addSon(result, a)
  if p.tok.xkind == pxColon:
    getTok(p)
    skipCom(p, result)
    addSon(result, parseTypeDesc(p))
  else:
    addSon(result, ast.emptyNode)
    if p.tok.xkind != pxEquals:
      parMessage(p, errColonOrEqualsExpected, $(p.tok))
  if p.tok.xkind == pxEquals:
    getTok(p)
    skipCom(p, result)
    addSon(result, parseExpr(p))
  else:
    addSon(result, ast.emptyNode)
  if p.tok.xkind == pxSemicolon:
    getTok(p)
    skipCom(p, result)

proc parseRecordCase(p: var TParser): PNode =
  var b, c: PNode
  result = newNodeP(nkRecCase, p)
  getTok(p)
  var a = newNodeP(nkIdentDefs, p)
  addSon(a, rawIdent(p))
  eat(p, pxColon)
  addSon(a, parseTypeDesc(p))
  addSon(a, ast.emptyNode)
  addSon(result, a)
  eat(p, pxOf)
  skipCom(p, result)
  while true:
    case p.tok.xkind
    of pxEof, pxEnd:
      break
    of pxElse:
      b = newNodeP(nkElse, p)
      getTok(p)
    else:
      b = newNodeP(nkOfBranch, p)
      while (p.tok.xkind != pxEof) and (p.tok.xkind != pxColon):
        addSon(b, rangeExpr(p))
        opt(p, pxComma)
        skipcom(p, b)
      eat(p, pxColon)
    skipCom(p, b)
    c = newNodeP(nkRecList, p)
    eat(p, pxParLe)
    while (p.tok.xkind != pxParRi) and (p.tok.xkind != pxEof):
      addSon(c, parseIdentColonEquals(p, rawIdent))
      opt(p, pxSemicolon)
      skipCom(p, lastSon(c))
    eat(p, pxParRi)
    opt(p, pxSemicolon)
    if sonsLen(c) > 0: skipCom(p, lastSon(c))
    else: addSon(c, newNodeP(nkNilLit, p))
    addSon(b, c)
    addSon(result, b)
    if b.kind == nkElse: break

proc parseRecordPart(p: var TParser): PNode =
  result = ast.emptyNode
  while (p.tok.xkind != pxEof) and (p.tok.xkind != pxEnd):
    if result.kind == nkEmpty: result = newNodeP(nkRecList, p)
    case p.tok.xkind
    of pxSymbol:
      addSon(result, parseIdentColonEquals(p, rawIdent))
      opt(p, pxSemicolon)
      skipCom(p, lastSon(result))
    of pxCase:
      addSon(result, parseRecordCase(p))
    of pxComment:
      skipCom(p, lastSon(result))
    else:
      parMessage(p, errIdentifierExpected, $p.tok)
      break

proc exSymbol(n: var PNode) =
  case n.kind
  of nkPostfix:
    nil
  of nkPragmaExpr:
    exSymbol(n.sons[0])
  of nkIdent, nkAccQuoted:
    var a = newNodeI(nkPostFix, n.info)
    addSon(a, newIdentNode(getIdent("*"), n.info))
    addSon(a, n)
    n = a
  else: internalError(n.info, "exSymbol(): " & $n.kind)

proc fixRecordDef(n: var PNode) =
  case n.kind
  of nkRecCase:
    fixRecordDef(n.sons[0])
    for i in countup(1, sonsLen(n) - 1):
      var length = sonsLen(n.sons[i])
      fixRecordDef(n.sons[i].sons[length - 1])
  of nkRecList, nkRecWhen, nkElse, nkOfBranch, nkElifBranch, nkObjectTy:
    for i in countup(0, sonsLen(n) - 1): fixRecordDef(n.sons[i])
  of nkIdentDefs:
    for i in countup(0, sonsLen(n) - 3): exSymbol(n.sons[i])
  of nkNilLit, nkEmpty: nil
  else: internalError(n.info, "fixRecordDef(): " & $n.kind)

proc addPragmaToIdent(ident: var PNode, pragma: PNode) =
  var pragmasNode: PNode
  if ident.kind != nkPragmaExpr:
    pragmasNode = newNodeI(nkPragma, ident.info)
    var e = newNodeI(nkPragmaExpr, ident.info)
    addSon(e, ident)
    addSon(e, pragmasNode)
    ident = e
  else:
    pragmasNode = ident.sons[1]
    if pragmasNode.kind != nkPragma:
      InternalError(ident.info, "addPragmaToIdent")
  addSon(pragmasNode, pragma)

proc parseRecordBody(p: var TParser, result, definition: PNode) =
  skipCom(p, result)
  var a = parseRecordPart(p)
  if result.kind != nkTupleTy: fixRecordDef(a)
  addSon(result, a)
  eat(p, pxEnd)
  case p.tok.xkind
  of pxSymbol:
    if p.tok.ident.id == getIdent("acyclic").id:
      if definition != nil:
        addPragmaToIdent(definition.sons[0], newIdentNodeP(p.tok.ident, p))
      else:
        InternalError(result.info, "anonymous record is not supported")
      getTok(p)
    else:
      InternalError(result.info, "parseRecordBody")
  of pxCommand:
    if definition != nil: addPragmaToIdent(definition.sons[0], parseCommand(p))
    else: InternalError(result.info, "anonymous record is not supported")
  else:
    nil
  opt(p, pxSemicolon)
  skipCom(p, result)

proc parseRecordOrObject(p: var TParser, kind: TNodeKind,
                         definition: PNode): PNode =
  result = newNodeP(kind, p)
  getTok(p)
  addSon(result, ast.emptyNode)
  if p.tok.xkind == pxParLe:
    var a = newNodeP(nkOfInherit, p)
    getTok(p)
    addSon(a, parseTypeDesc(p))
    addSon(result, a)
    eat(p, pxParRi)
  else:
    addSon(result, ast.emptyNode)
  parseRecordBody(p, result, definition)

proc parseTypeDesc(p: var TParser, definition: PNode = nil): PNode =
  var oldcontext = p.context
  p.context = conTypeDesc
  if p.tok.xkind == pxPacked: getTok(p)
  case p.tok.xkind
  of pxCommand:
    result = parseCommand(p, definition)
  of pxProcedure, pxFunction:
    result = parseRoutineType(p)
  of pxRecord:
    getTok(p)
    if p.tok.xkind == pxCommand:
      result = parseCommand(p)
      if result.kind != nkTupleTy: InternalError(result.info, "parseTypeDesc")
      parseRecordBody(p, result, definition)
      var a = lastSon(result)     # embed nkRecList directly into nkTupleTy
      for i in countup(0, sonsLen(a) - 1):
        if i == 0: result.sons[sonsLen(result) - 1] = a.sons[0]
        else: addSon(result, a.sons[i])
    else:
      result = newNodeP(nkObjectTy, p)
      addSon(result, ast.emptyNode)
      addSon(result, ast.emptyNode)
      parseRecordBody(p, result, definition)
      if definition != nil:
        addPragmaToIdent(definition.sons[0], newIdentNodeP(getIdent("final"), p))
      else:
        InternalError(result.info, "anonymous record is not supported")
  of pxObject: result = parseRecordOrObject(p, nkObjectTy, definition)
  of pxParLe: result = parseEnum(p)
  of pxArray:
    result = newNodeP(nkBracketExpr, p)
    getTok(p)
    if p.tok.xkind == pxBracketLe:
      addSon(result, newIdentNodeP(getIdent("array"), p))
      getTok(p)
      addSon(result, rangeExpr(p))
      eat(p, pxBracketRi)
    else:
      if p.inParamList: addSon(result, newIdentNodeP(getIdent("openarray"), p))
      else: addSon(result, newIdentNodeP(getIdent("seq"), p))
    eat(p, pxOf)
    addSon(result, parseTypeDesc(p))
  of pxSet:
    result = newNodeP(nkBracketExpr, p)
    getTok(p)
    eat(p, pxOf)
    addSon(result, newIdentNodeP(getIdent("set"), p))
    addSon(result, parseTypeDesc(p))
  of pxHat:
    getTok(p)
    if p.tok.xkind == pxCommand: result = parseCommand(p)
    elif pfRefs in p.flags: result = newNodeP(nkRefTy, p)
    else: result = newNodeP(nkPtrTy, p)
    addSon(result, parseTypeDesc(p))
  of pxType:
    getTok(p)
    result = parseTypeDesc(p)
  else:
    var a = primary(p)
    if p.tok.xkind == pxDotDot:
      result = newNodeP(nkBracketExpr, p)
      var r = newNodeP(nkRange, p)
      addSon(result, newIdentNodeP(getIdent("range"), p))
      getTok(p)
      addSon(r, a)
      addSon(r, parseExpr(p))
      addSon(result, r)
    else:
      result = a
  p.context = oldcontext

proc parseTypeDef(p: var TParser): PNode =
  result = newNodeP(nkTypeDef, p)
  addSon(result, identVis(p))
  addSon(result, ast.emptyNode)         # generic params
  if p.tok.xkind == pxEquals:
    getTok(p)
    skipCom(p, result)
    addSon(result, parseTypeDesc(p, result))
  else:
    addSon(result, ast.emptyNode)
  if p.tok.xkind == pxSemicolon:
    getTok(p)
    skipCom(p, result)

proc parseTypeSection(p: var TParser): PNode =
  result = newNodeP(nkTypeSection, p)
  getTok(p)
  skipCom(p, result)
  while p.tok.xkind == pxSymbol:
    addSon(result, parseTypeDef(p))

proc parseConstant(p: var TParser): PNode =
  result = newNodeP(nkConstDef, p)
  addSon(result, identVis(p))
  if p.tok.xkind == pxColon:
    getTok(p)
    skipCom(p, result)
    addSon(result, parseTypeDesc(p))
  else:
    addSon(result, ast.emptyNode)
    if p.tok.xkind != pxEquals:
      parMessage(p, errColonOrEqualsExpected, $(p.tok))
  if p.tok.xkind == pxEquals:
    getTok(p)
    skipCom(p, result)
    addSon(result, parseExpr(p))
  else:
    addSon(result, ast.emptyNode)
  if p.tok.xkind == pxSemicolon:
    getTok(p)
    skipCom(p, result)

proc parseConstSection(p: var TParser): PNode =
  result = newNodeP(nkConstSection, p)
  getTok(p)
  skipCom(p, result)
  while p.tok.xkind == pxSymbol:
    addSon(result, parseConstant(p))

proc parseVar(p: var TParser): PNode =
  result = newNodeP(nkVarSection, p)
  getTok(p)
  skipCom(p, result)
  while p.tok.xkind == pxSymbol:
    addSon(result, parseIdentColonEquals(p, identVis))
  p.lastVarSection = result

proc parseRoutine(p: var TParser): PNode =
  var noBody: bool
  result = newNodeP(nkProcDef, p)
  getTok(p)
  skipCom(p, result)
  expectIdent(p)
  addSon(result, identVis(p))
  # patterns, generic parameters:
  addSon(result, ast.emptyNode)
  addSon(result, ast.emptyNode)
  addSon(result, parseParamList(p))
  opt(p, pxSemicolon)
  addSon(result, parseRoutineSpecifiers(p, noBody))
  addSon(result, ast.emptyNode)
  if (p.section == seInterface) or noBody:
    addSon(result, ast.emptyNode)
  else:
    var stmts = newNodeP(nkStmtList, p)
    while true:
      case p.tok.xkind
      of pxVar: addSon(stmts, parseVar(p))
      of pxConst: addSon(stmts, parseConstSection(p))
      of pxType: addSon(stmts, parseTypeSection(p))
      of pxComment: skipCom(p, result)
      of pxBegin: break
      else:
        parMessage(p, errTokenExpected, "begin")
        break
    var a = parseStmt(p)
    for i in countup(0, sonsLen(a) - 1): addSon(stmts, a.sons[i])
    addSon(result, stmts)

proc fixExit(p: var TParser, n: PNode): bool =
  if (p.tok.ident.id == getIdent("exit").id):
    var length = sonsLen(n)
    if (length <= 0): return
    var a = n.sons[length-1]
    if (a.kind == nkAsgn) and (a.sons[0].kind == nkIdent) and
        (a.sons[0].ident.id == getIdent("result").id):
      delSon(a, 0)
      a.kind = nkReturnStmt
      result = true
      getTok(p)
      opt(p, pxSemicolon)
      skipCom(p, a)

proc fixVarSection(p: var TParser, counter: PNode) =
  if p.lastVarSection == nil: return
  assert(counter.kind == nkIdent)
  for i in countup(0, sonsLen(p.lastVarSection) - 1):
    var v = p.lastVarSection.sons[i]
    for j in countup(0, sonsLen(v) - 3):
      if v.sons[j].ident.id == counter.ident.id:
        delSon(v, j)
        if sonsLen(v) <= 2:
          delSon(p.lastVarSection, i)
        return

proc exSymbols(n: PNode) =
  case n.kind
  of nkEmpty..nkNilLit: nil
  of nkProcDef..nkIteratorDef: exSymbol(n.sons[namePos])
  of nkWhenStmt, nkStmtList:
    for i in countup(0, sonsLen(n) - 1): exSymbols(n.sons[i])
  of nkVarSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1): exSymbol(n.sons[i].sons[0])
  of nkTypeSection:
    for i in countup(0, sonsLen(n) - 1):
      exSymbol(n.sons[i].sons[0])
      if n.sons[i].sons[2].kind == nkObjectTy:
        fixRecordDef(n.sons[i].sons[2])
  else: nil

proc parseBegin(p: var TParser, result: PNode) =
  getTok(p)
  while true:
    case p.tok.xkind
    of pxComment: addSon(result, parseStmt(p))
    of pxSymbol:
      if not fixExit(p, result): addSon(result, parseStmt(p))
    of pxEnd:
      getTok(p)
      break
    of pxSemicolon: getTok(p)
    of pxEof: parMessage(p, errExprExpected)
    else:
      var a = parseStmt(p)
      if a.kind != nkEmpty: addSon(result, a)
  if sonsLen(result) == 0: addSon(result, newNodeP(nkNilLit, p))

proc parseStmt(p: var TParser): PNode =
  var oldcontext = p.context
  p.context = conStmt
  result = ast.emptyNode
  case p.tok.xkind
  of pxBegin:
    result = newNodeP(nkStmtList, p)
    parseBegin(p, result)
  of pxCommand: result = parseCommand(p)
  of pxCurlyDirLe, pxStarDirLe:
    if isHandledDirective(p): result = parseDirective(p)
  of pxIf: result = parseIf(p)
  of pxWhile: result = parseWhile(p)
  of pxRepeat: result = parseRepeat(p)
  of pxCase: result = parseCase(p)
  of pxTry: result = parseTry(p)
  of pxProcedure, pxFunction: result = parseRoutine(p)
  of pxType: result = parseTypeSection(p)
  of pxConst: result = parseConstSection(p)
  of pxVar: result = parseVar(p)
  of pxFor:
    result = parseFor(p)
    fixVarSection(p, result.sons[0])
  of pxRaise: result = parseRaise(p)
  of pxUses: result = parseUsesStmt(p)
  of pxProgram, pxUnit, pxLibrary:
    # skip the pointless header
    while not (p.tok.xkind in {pxSemicolon, pxEof}): getTok(p)
    getTok(p)
  of pxInitialization: getTok(p) # just skip the token
  of pxImplementation:
    p.section = seImplementation
    result = newNodeP(nkCommentStmt, p)
    result.comment = "# implementation"
    getTok(p)
  of pxInterface:
    p.section = seInterface
    getTok(p)
  of pxComment:
    result = newNodeP(nkCommentStmt, p)
    skipCom(p, result)
  of pxSemicolon: getTok(p)
  of pxSymbol:
    if p.tok.ident.id == getIdent("break").id:
      result = newNodeP(nkBreakStmt, p)
      getTok(p)
      skipCom(p, result)
      addSon(result, ast.emptyNode)
    elif p.tok.ident.id == getIdent("continue").id:
      result = newNodeP(nkContinueStmt, p)
      getTok(p)
      skipCom(p, result)
      addSon(result, ast.emptyNode)
    elif p.tok.ident.id == getIdent("exit").id:
      result = newNodeP(nkReturnStmt, p)
      getTok(p)
      skipCom(p, result)
      addSon(result, ast.emptyNode)
    else:
      result = parseExprStmt(p)
  of pxDot: getTok(p) # BUGFIX for ``end.`` in main program
  else: result = parseExprStmt(p)
  opt(p, pxSemicolon)
  if result.kind != nkEmpty: skipCom(p, result)
  p.context = oldcontext

proc parseUnit(p: var TParser): PNode =
  result = newNodeP(nkStmtList, p)
  getTok(p)                   # read first token
  while true:
    case p.tok.xkind
    of pxEof, pxEnd: break
    of pxBegin: parseBegin(p, result)
    of pxCurlyDirLe, pxStarDirLe:
      if isHandledDirective(p): addSon(result, parseDirective(p))
      else: parMessage(p, errXNotAllowedHere, p.tok.ident.s)
    else: addSon(result, parseStmt(p))
  opt(p, pxEnd)
  opt(p, pxDot)
  if p.tok.xkind != pxEof:
    addSon(result, parseStmt(p)) # comments after final 'end.'

