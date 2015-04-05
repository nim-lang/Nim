#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the renderer of the standard Nim representation.

import
  lexer, options, idents, strutils, ast, msgs, lists

type
  TRenderFlag* = enum
    renderNone, renderNoBody, renderNoComments, renderDocComments,
    renderNoPragmas, renderIds, renderNoProcDefs
  TRenderFlags* = set[TRenderFlag]
  TRenderTok*{.final.} = object
    kind*: TTokType
    length*: int16

  TRenderTokSeq* = seq[TRenderTok]
  TSrcGen*{.final.} = object
    indent*: int
    lineLen*: int
    pos*: int              # current position for iteration over the buffer
    idx*: int              # current token index for iteration over the buffer
    tokens*: TRenderTokSeq
    buf*: string
    pendingNL*: int        # negative if not active; else contains the
                           # indentation value
    comStack*: seq[PNode]  # comment stack
    flags*: TRenderFlags
    checkAnon: bool        # we're in a context that can contain sfAnon
    inPragma: int


proc renderModule*(n: PNode, filename: string, renderFlags: TRenderFlags = {})
proc renderTree*(n: PNode, renderFlags: TRenderFlags = {}): string
proc initTokRender*(r: var TSrcGen, n: PNode, renderFlags: TRenderFlags = {})
proc getNextTok*(r: var TSrcGen, kind: var TTokType, literal: var string)

proc `$`*(n: PNode): string = n.renderTree
# implementation
# We render the source code in a two phases: The first
# determines how long the subtree will likely be, the second
# phase appends to a buffer that will be the output.

proc isKeyword*(i: PIdent): bool =
  if (i.id >= ord(tokKeywordLow) - ord(tkSymbol)) and
      (i.id <= ord(tokKeywordHigh) - ord(tkSymbol)):
    result = true

proc isKeyword*(s: string): bool = isKeyword(getIdent(s))

proc renderDefinitionName*(s: PSym, noQuotes = false): string =
  ## Returns the definition name of the symbol.
  ##
  ## If noQuotes is false the symbol may be returned in backticks. This will
  ## happen if the name happens to be a keyword or the first character is not
  ## part of the SymStartChars set.
  let x = s.name.s
  if noQuotes or (x[0] in SymStartChars and not renderer.isKeyword(s.name)):
    result = x
  else:
    result = '`' & x & '`'

const
  IndentWidth = 2
  longIndentWid = 4
  MaxLineLen = 80
  LineCommentColumn = 30

proc initSrcGen(g: var TSrcGen, renderFlags: TRenderFlags) =
  g.comStack = @[]
  g.tokens = @[]
  g.indent = 0
  g.lineLen = 0
  g.pos = 0
  g.idx = 0
  g.buf = ""
  g.flags = renderFlags
  g.pendingNL = -1
  g.checkAnon = false

proc addTok(g: var TSrcGen, kind: TTokType, s: string) =
  var length = len(g.tokens)
  setLen(g.tokens, length + 1)
  g.tokens[length].kind = kind
  g.tokens[length].length = int16(len(s))
  add(g.buf, s)

proc addPendingNL(g: var TSrcGen) =
  if g.pendingNL >= 0:
    addTok(g, tkSpaces, "\n" & spaces(g.pendingNL))
    g.lineLen = g.pendingNL
    g.pendingNL = - 1

proc putNL(g: var TSrcGen, indent: int) =
  if g.pendingNL >= 0: addPendingNL(g)
  else: addTok(g, tkSpaces, "\n")
  g.pendingNL = indent
  g.lineLen = indent

proc putNL(g: var TSrcGen) =
  putNL(g, g.indent)

proc optNL(g: var TSrcGen, indent: int) =
  g.pendingNL = indent
  g.lineLen = indent          # BUGFIX

proc optNL(g: var TSrcGen) =
  optNL(g, g.indent)

proc indentNL(g: var TSrcGen) =
  inc(g.indent, IndentWidth)
  g.pendingNL = g.indent
  g.lineLen = g.indent

proc dedent(g: var TSrcGen) =
  dec(g.indent, IndentWidth)
  assert(g.indent >= 0)
  if g.pendingNL > IndentWidth:
    dec(g.pendingNL, IndentWidth)
    dec(g.lineLen, IndentWidth)

proc put(g: var TSrcGen, kind: TTokType, s: string) =
  addPendingNL(g)
  if len(s) > 0:
    addTok(g, kind, s)
    inc(g.lineLen, len(s))

proc putLong(g: var TSrcGen, kind: TTokType, s: string, lineLen: int) =
  # use this for tokens over multiple lines.
  addPendingNL(g)
  addTok(g, kind, s)
  g.lineLen = lineLen

proc toNimChar(c: char): string =
  case c
  of '\0': result = "\\0"
  of '\x01'..'\x1F', '\x80'..'\xFF': result = "\\x" & strutils.toHex(ord(c), 2)
  of '\'', '\"', '\\': result = '\\' & c
  else: result = c & ""

proc makeNimString(s: string): string =
  result = "\""
  for i in countup(0, len(s)-1): add(result, toNimChar(s[i]))
  add(result, '\"')

proc putComment(g: var TSrcGen, s: string) =
  if s.isNil: return
  var i = 0
  var comIndent = 1
  var isCode = (len(s) >= 2) and (s[1] != ' ')
  var ind = g.lineLen
  var com = ""
  while true:
    case s[i]
    of '\0':
      break
    of '\x0D':
      put(g, tkComment, com)
      com = ""
      inc(i)
      if s[i] == '\x0A': inc(i)
      optNL(g, ind)
    of '\x0A':
      put(g, tkComment, com)
      com = ""
      inc(i)
      optNL(g, ind)
    of '#':
      add(com, s[i])
      inc(i)
      comIndent = 0
      while s[i] == ' ':
        add(com, s[i])
        inc(i)
        inc(comIndent)
    of ' ', '\x09':
      add(com, s[i])
      inc(i)
    else:
      # we may break the comment into a multi-line comment if the line
      # gets too long:
      # compute length of the following word:
      var j = i
      while s[j] > ' ': inc(j)
      if not isCode and (g.lineLen + (j - i) > MaxLineLen):
        put(g, tkComment, com)
        optNL(g, ind)
        com = '#' & spaces(comIndent)
      while s[i] > ' ':
        add(com, s[i])
        inc(i)
  put(g, tkComment, com)
  optNL(g)

proc maxLineLength(s: string): int =
  if s.isNil: return 0
  var i = 0
  var lineLen = 0
  while true:
    case s[i]
    of '\0':
      break
    of '\x0D':
      inc(i)
      if s[i] == '\x0A': inc(i)
      result = max(result, lineLen)
      lineLen = 0
    of '\x0A':
      inc(i)
      result = max(result, lineLen)
      lineLen = 0
    else:
      inc(lineLen)
      inc(i)

proc putRawStr(g: var TSrcGen, kind: TTokType, s: string) =
  var i = 0
  var hi = len(s) - 1
  var str = ""
  while i <= hi:
    case s[i]
    of '\x0D':
      put(g, kind, str)
      str = ""
      inc(i)
      if (i <= hi) and (s[i] == '\x0A'): inc(i)
      optNL(g, 0)
    of '\x0A':
      put(g, kind, str)
      str = ""
      inc(i)
      optNL(g, 0)
    else:
      add(str, s[i])
      inc(i)
  put(g, kind, str)

proc containsNL(s: string): bool =
  for i in countup(0, len(s) - 1):
    case s[i]
    of '\x0D', '\x0A':
      return true
    else:
      discard
  result = false

proc pushCom(g: var TSrcGen, n: PNode) =
  var length = len(g.comStack)
  setLen(g.comStack, length + 1)
  g.comStack[length] = n

proc popAllComs(g: var TSrcGen) =
  setLen(g.comStack, 0)

proc popCom(g: var TSrcGen) =
  setLen(g.comStack, len(g.comStack) - 1)

const
  Space = " "

proc shouldRenderComment(g: var TSrcGen, n: PNode): bool =
  result = false
  if n.comment != nil:
    result = (renderNoComments notin g.flags) or
        (renderDocComments in g.flags) and startsWith(n.comment, "##")

proc gcom(g: var TSrcGen, n: PNode) =
  assert(n != nil)
  if shouldRenderComment(g, n):
    if (g.pendingNL < 0) and (len(g.buf) > 0) and (g.buf[len(g.buf)-1] != ' '):
      put(g, tkSpaces, Space)
      # Before long comments we cannot make sure that a newline is generated,
      # because this might be wrong. But it is no problem in practice.
    if (g.pendingNL < 0) and (len(g.buf) > 0) and
        (g.lineLen < LineCommentColumn):
      var ml = maxLineLength(n.comment)
      if ml + LineCommentColumn <= MaxLineLen:
        put(g, tkSpaces, spaces(LineCommentColumn - g.lineLen))
    putComment(g, n.comment)  #assert(g.comStack[high(g.comStack)] = n);

proc gcoms(g: var TSrcGen) =
  for i in countup(0, high(g.comStack)): gcom(g, g.comStack[i])
  popAllComs(g)

proc lsub(n: PNode): int
proc litAux(n: PNode, x: BiggestInt, size: int): string =
  proc skip(t: PType): PType =
    result = t
    while result.kind in {tyGenericInst, tyRange, tyVar, tyDistinct, tyOrdinal,
                          tyConst, tyMutable}:
      result = lastSon(result)
  if n.typ != nil and n.typ.skip.kind in {tyBool, tyEnum}:
    let enumfields = n.typ.skip.n
    # we need a slow linear search because of enums with holes:
    for e in items(enumfields):
      if e.sym.position == x: return e.sym.name.s

  if nfBase2 in n.flags: result = "0b" & toBin(x, size * 8)
  elif nfBase8 in n.flags: result = "0o" & toOct(x, size * 3)
  elif nfBase16 in n.flags: result = "0x" & toHex(x, size * 2)
  else: result = $x

proc ulitAux(n: PNode, x: BiggestInt, size: int): string =
  if nfBase2 in n.flags: result = "0b" & toBin(x, size * 8)
  elif nfBase8 in n.flags: result = "0o" & toOct(x, size * 3)
  elif nfBase16 in n.flags: result = "0x" & toHex(x, size * 2)
  else: result = $x
  # XXX proper unsigned output!

proc atom(n: PNode): string =
  var f: float32
  case n.kind
  of nkEmpty: result = ""
  of nkIdent: result = n.ident.s
  of nkSym: result = n.sym.name.s
  of nkStrLit: result = makeNimString(n.strVal)
  of nkRStrLit: result = "r\"" & replace(n.strVal, "\"", "\"\"")  & '\"'
  of nkTripleStrLit: result = "\"\"\"" & n.strVal & "\"\"\""
  of nkCharLit: result = '\'' & toNimChar(chr(int(n.intVal))) & '\''
  of nkIntLit: result = litAux(n, n.intVal, 4)
  of nkInt8Lit: result = litAux(n, n.intVal, 1) & "\'i8"
  of nkInt16Lit: result = litAux(n, n.intVal, 2) & "\'i16"
  of nkInt32Lit: result = litAux(n, n.intVal, 4) & "\'i32"
  of nkInt64Lit: result = litAux(n, n.intVal, 8) & "\'i64"
  of nkUIntLit: result = ulitAux(n, n.intVal, 4) & "\'u"
  of nkUInt8Lit: result = ulitAux(n, n.intVal, 1) & "\'u8"
  of nkUInt16Lit: result = ulitAux(n, n.intVal, 2) & "\'u16"
  of nkUInt32Lit: result = ulitAux(n, n.intVal, 4) & "\'u32"
  of nkUInt64Lit: result = ulitAux(n, n.intVal, 8) & "\'u64"
  of nkFloatLit:
    if n.flags * {nfBase2, nfBase8, nfBase16} == {}: result = $(n.floatVal)
    else: result = litAux(n, (cast[PInt64](addr(n.floatVal)))[] , 8)
  of nkFloat32Lit:
    if n.flags * {nfBase2, nfBase8, nfBase16} == {}:
      result = $n.floatVal & "\'f32"
    else:
      f = n.floatVal.float32
      result = litAux(n, (cast[PInt32](addr(f)))[], 4) & "\'f32"
  of nkFloat64Lit:
    if n.flags * {nfBase2, nfBase8, nfBase16} == {}:
      result = $n.floatVal & "\'f64"
    else:
      result = litAux(n, (cast[PInt64](addr(n.floatVal)))[], 8) & "\'f64"
  of nkNilLit: result = "nil"
  of nkType:
    if (n.typ != nil) and (n.typ.sym != nil): result = n.typ.sym.name.s
    else: result = "[type node]"
  else:
    internalError("rnimsyn.atom " & $n.kind)
    result = ""

proc lcomma(n: PNode, start: int = 0, theEnd: int = - 1): int =
  assert(theEnd < 0)
  result = 0
  for i in countup(start, sonsLen(n) + theEnd):
    inc(result, lsub(n.sons[i]))
    inc(result, 2)            # for ``, ``
  if result > 0:
    dec(result, 2)            # last does not get a comma!

proc lsons(n: PNode, start: int = 0, theEnd: int = - 1): int =
  assert(theEnd < 0)
  result = 0
  for i in countup(start, sonsLen(n) + theEnd): inc(result, lsub(n.sons[i]))

proc lsub(n: PNode): int =
  # computes the length of a tree
  if isNil(n): return 0
  if n.comment != nil: return MaxLineLen + 1
  case n.kind
  of nkEmpty: result = 0
  of nkTripleStrLit:
    if containsNL(n.strVal): result = MaxLineLen + 1
    else: result = len(atom(n))
  of succ(nkEmpty)..pred(nkTripleStrLit), succ(nkTripleStrLit)..nkNilLit:
    result = len(atom(n))
  of nkCall, nkBracketExpr, nkCurlyExpr, nkConv, nkPattern, nkObjConstr:
    result = lsub(n.sons[0]) + lcomma(n, 1) + 2
  of nkHiddenStdConv, nkHiddenSubConv, nkHiddenCallConv: result = lsub(n[1])
  of nkCast: result = lsub(n.sons[0]) + lsub(n.sons[1]) + len("cast[]()")
  of nkAddr: result = (if n.len>0: lsub(n.sons[0]) + len("addr()") else: 4)
  of nkStaticExpr: result = lsub(n.sons[0]) + len("static_")
  of nkHiddenAddr, nkHiddenDeref: result = lsub(n.sons[0])
  of nkCommand: result = lsub(n.sons[0]) + lcomma(n, 1) + 1
  of nkExprEqExpr, nkAsgn, nkFastAsgn: result = lsons(n) + 3
  of nkPar, nkCurly, nkBracket, nkClosure: result = lcomma(n) + 2
  of nkArgList: result = lcomma(n)
  of nkTableConstr:
    result = if n.len > 0: lcomma(n) + 2 else: len("{:}")
  of nkClosedSymChoice, nkOpenSymChoice:
    result = lsons(n) + len("()") + sonsLen(n) - 1
  of nkTupleTy: result = lcomma(n) + len("tuple[]")
  of nkTupleClassTy: result = len("tuple")
  of nkDotExpr: result = lsons(n) + 1
  of nkBind: result = lsons(n) + len("bind_")
  of nkBindStmt: result = lcomma(n) + len("bind_")
  of nkMixinStmt: result = lcomma(n) + len("mixin_")
  of nkCheckedFieldExpr: result = lsub(n.sons[0])
  of nkLambda: result = lsons(n) + len("proc__=_")
  of nkDo: result = lsons(n) + len("do__:_")
  of nkConstDef, nkIdentDefs:
    result = lcomma(n, 0, - 3)
    var L = sonsLen(n)
    if n.sons[L - 2].kind != nkEmpty: result = result + lsub(n.sons[L - 2]) + 2
    if n.sons[L - 1].kind != nkEmpty: result = result + lsub(n.sons[L - 1]) + 3
  of nkVarTuple: result = lcomma(n, 0, - 3) + len("() = ") + lsub(lastSon(n))
  of nkChckRangeF: result = len("chckRangeF") + 2 + lcomma(n)
  of nkChckRange64: result = len("chckRange64") + 2 + lcomma(n)
  of nkChckRange: result = len("chckRange") + 2 + lcomma(n)
  of nkObjDownConv, nkObjUpConv, nkStringToCString, nkCStringToString:
    result = 2
    if sonsLen(n) >= 1: result = result + lsub(n.sons[0])
    result = result + lcomma(n, 1)
  of nkExprColonExpr: result = lsons(n) + 2
  of nkInfix: result = lsons(n) + 2
  of nkPrefix:
    result = lsons(n)+1+(if n.len > 0 and n.sons[1].kind == nkInfix: 2 else: 0)
  of nkPostfix: result = lsons(n)
  of nkCallStrLit: result = lsons(n)
  of nkPragmaExpr: result = lsub(n.sons[0]) + lcomma(n, 1)
  of nkRange: result = lsons(n) + 2
  of nkDerefExpr: result = lsub(n.sons[0]) + 2
  of nkAccQuoted: result = lsons(n) + 2
  of nkIfExpr:
    result = lsub(n.sons[0].sons[0]) + lsub(n.sons[0].sons[1]) + lsons(n, 1) +
        len("if_:_")
  of nkElifExpr: result = lsons(n) + len("_elif_:_")
  of nkElseExpr: result = lsub(n.sons[0]) + len("_else:_") # type descriptions
  of nkTypeOfExpr: result = (if n.len > 0: lsub(n.sons[0]) else: 0)+len("type_")
  of nkRefTy: result = (if n.len > 0: lsub(n.sons[0])+1 else: 0) + len("ref")
  of nkPtrTy: result = (if n.len > 0: lsub(n.sons[0])+1 else: 0) + len("ptr")
  of nkVarTy: result = (if n.len > 0: lsub(n.sons[0])+1 else: 0) + len("var")
  of nkDistinctTy:
    result = len("distinct") + (if n.len > 0: lsub(n.sons[0])+1 else: 0)
    if n.len > 1:
      result += (if n[1].kind == nkWith: len("_with_") else: len("_without_"))
      result += lcomma(n[1])
  of nkStaticTy: result = (if n.len > 0: lsub(n.sons[0]) else: 0) +
                                                         len("static[]")
  of nkTypeDef: result = lsons(n) + 3
  of nkOfInherit: result = lsub(n.sons[0]) + len("of_")
  of nkProcTy: result = lsons(n) + len("proc_")
  of nkIteratorTy: result = lsons(n) + len("iterator_")
  of nkSharedTy: result = lsons(n) + len("shared_")
  of nkEnumTy:
    if sonsLen(n) > 0:
      result = lsub(n.sons[0]) + lcomma(n, 1) + len("enum_")
    else:
      result = len("enum")
  of nkEnumFieldDef: result = lsons(n) + 3
  of nkVarSection, nkLetSection:
    if sonsLen(n) > 1: result = MaxLineLen + 1
    else: result = lsons(n) + len("var_")
  of nkReturnStmt: result = lsub(n.sons[0]) + len("return_")
  of nkRaiseStmt: result = lsub(n.sons[0]) + len("raise_")
  of nkYieldStmt: result = lsub(n.sons[0]) + len("yield_")
  of nkDiscardStmt: result = lsub(n.sons[0]) + len("discard_")
  of nkBreakStmt: result = lsub(n.sons[0]) + len("break_")
  of nkContinueStmt: result = lsub(n.sons[0]) + len("continue_")
  of nkPragma: result = lcomma(n) + 4
  of nkCommentStmt: result = if n.comment.isNil: 0 else: len(n.comment)
  of nkOfBranch: result = lcomma(n, 0, - 2) + lsub(lastSon(n)) + len("of_:_")
  of nkImportAs: result = lsub(n.sons[0]) + len("_as_") + lsub(n.sons[1])
  of nkElifBranch: result = lsons(n) + len("elif_:_")
  of nkElse: result = lsub(n.sons[0]) + len("else:_")
  of nkFinally: result = lsub(n.sons[0]) + len("finally:_")
  of nkGenericParams: result = lcomma(n) + 2
  of nkFormalParams:
    result = lcomma(n, 1) + 2
    if n.sons[0].kind != nkEmpty: result = result + lsub(n.sons[0]) + 2
  of nkExceptBranch:
    result = lcomma(n, 0, -2) + lsub(lastSon(n)) + len("except_:_")
  else: result = MaxLineLen + 1

proc fits(g: TSrcGen, x: int): bool =
  result = x + g.lineLen <= MaxLineLen

type
  TSubFlag = enum
    rfLongMode, rfNoIndent, rfInConstExpr
  TSubFlags = set[TSubFlag]
  TContext = tuple[spacing: int, flags: TSubFlags]

const
  emptyContext: TContext = (spacing: 0, flags: {})

proc initContext(c: var TContext) =
  c.spacing = 0
  c.flags = {}

proc gsub(g: var TSrcGen, n: PNode, c: TContext)
proc gsub(g: var TSrcGen, n: PNode) =
  var c: TContext
  initContext(c)
  gsub(g, n, c)

proc hasCom(n: PNode): bool =
  result = false
  if n.comment != nil: return true
  case n.kind
  of nkEmpty..nkNilLit: discard
  else:
    for i in countup(0, sonsLen(n) - 1):
      if hasCom(n.sons[i]): return true

proc putWithSpace(g: var TSrcGen, kind: TTokType, s: string) =
  put(g, kind, s)
  put(g, tkSpaces, Space)

proc gcommaAux(g: var TSrcGen, n: PNode, ind: int, start: int = 0,
               theEnd: int = - 1, separator = tkComma) =
  for i in countup(start, sonsLen(n) + theEnd):
    var c = i < sonsLen(n) + theEnd
    var sublen = lsub(n.sons[i]) + ord(c)
    if not fits(g, sublen) and (ind + sublen < MaxLineLen): optNL(g, ind)
    let oldLen = g.tokens.len
    gsub(g, n.sons[i])
    if c:
      if g.tokens.len > oldLen:
        putWithSpace(g, separator, TokTypeToStr[separator])
      if hasCom(n.sons[i]):
        gcoms(g)
        optNL(g, ind)

proc gcomma(g: var TSrcGen, n: PNode, c: TContext, start: int = 0,
            theEnd: int = - 1) =
  var ind: int
  if rfInConstExpr in c.flags:
    ind = g.indent + IndentWidth
  else:
    ind = g.lineLen
    if ind > MaxLineLen div 2: ind = g.indent + longIndentWid
  gcommaAux(g, n, ind, start, theEnd)

proc gcomma(g: var TSrcGen, n: PNode, start: int = 0, theEnd: int = - 1) =
  var ind = g.lineLen
  if ind > MaxLineLen div 2: ind = g.indent + longIndentWid
  gcommaAux(g, n, ind, start, theEnd)

proc gsemicolon(g: var TSrcGen, n: PNode, start: int = 0, theEnd: int = - 1) =
  var ind = g.lineLen
  if ind > MaxLineLen div 2: ind = g.indent + longIndentWid
  gcommaAux(g, n, ind, start, theEnd, tkSemiColon)

proc gsons(g: var TSrcGen, n: PNode, c: TContext, start: int = 0,
           theEnd: int = - 1) =
  for i in countup(start, sonsLen(n) + theEnd): gsub(g, n.sons[i], c)

proc gsection(g: var TSrcGen, n: PNode, c: TContext, kind: TTokType,
              k: string) =
  if sonsLen(n) == 0: return # empty var sections are possible
  putWithSpace(g, kind, k)
  gcoms(g)
  indentNL(g)
  for i in countup(0, sonsLen(n) - 1):
    optNL(g)
    gsub(g, n.sons[i], c)
    gcoms(g)
  dedent(g)

proc longMode(n: PNode, start: int = 0, theEnd: int = - 1): bool =
  result = n.comment != nil
  if not result:
    # check further
    for i in countup(start, sonsLen(n) + theEnd):
      if (lsub(n.sons[i]) > MaxLineLen):
        result = true
        break

proc gstmts(g: var TSrcGen, n: PNode, c: TContext, doIndent=true) =
  if n.kind == nkEmpty: return
  if n.kind in {nkStmtList, nkStmtListExpr, nkStmtListType}:
    if doIndent: indentNL(g)
    for i in countup(0, sonsLen(n) - 1):
      optNL(g)
      if n.sons[i].kind in {nkStmtList, nkStmtListExpr, nkStmtListType}:
        gstmts(g, n.sons[i], c, doIndent=false)
      else:
        gsub(g, n.sons[i])
      gcoms(g)
    if doIndent: dedent(g)
  else:
    if rfLongMode in c.flags: indentNL(g)
    gsub(g, n)
    gcoms(g)
    optNL(g)
    if rfLongMode in c.flags: dedent(g)

proc gif(g: var TSrcGen, n: PNode) =
  var c: TContext
  gsub(g, n.sons[0].sons[0])
  initContext(c)
  putWithSpace(g, tkColon, ":")
  if longMode(n) or (lsub(n.sons[0].sons[1]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)                    # a good place for comments
  gstmts(g, n.sons[0].sons[1], c)
  var length = sonsLen(n)
  for i in countup(1, length - 1):
    optNL(g)
    gsub(g, n.sons[i], c)

proc gwhile(g: var TSrcGen, n: PNode) =
  var c: TContext
  putWithSpace(g, tkWhile, "while")
  gsub(g, n.sons[0])
  putWithSpace(g, tkColon, ":")
  initContext(c)
  if longMode(n) or (lsub(n.sons[1]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)                    # a good place for comments
  gstmts(g, n.sons[1], c)

proc gpattern(g: var TSrcGen, n: PNode) =
  var c: TContext
  put(g, tkCurlyLe, "{")
  initContext(c)
  if longMode(n) or (lsub(n.sons[0]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)                    # a good place for comments
  gstmts(g, n, c)
  put(g, tkCurlyRi, "}")

proc gpragmaBlock(g: var TSrcGen, n: PNode) =
  var c: TContext
  gsub(g, n.sons[0])
  putWithSpace(g, tkColon, ":")
  initContext(c)
  if longMode(n) or (lsub(n.sons[1]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)                    # a good place for comments
  gstmts(g, n.sons[1], c)

proc gtry(g: var TSrcGen, n: PNode) =
  var c: TContext
  put(g, tkTry, "try")
  putWithSpace(g, tkColon, ":")
  initContext(c)
  if longMode(n) or (lsub(n.sons[0]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)                    # a good place for comments
  gstmts(g, n.sons[0], c)
  gsons(g, n, c, 1)

proc gfor(g: var TSrcGen, n: PNode) =
  var c: TContext
  var length = sonsLen(n)
  putWithSpace(g, tkFor, "for")
  initContext(c)
  if longMode(n) or
      (lsub(n.sons[length - 1]) + lsub(n.sons[length - 2]) + 6 + g.lineLen >
      MaxLineLen):
    incl(c.flags, rfLongMode)
  gcomma(g, n, c, 0, - 3)
  put(g, tkSpaces, Space)
  putWithSpace(g, tkIn, "in")
  gsub(g, n.sons[length - 2], c)
  putWithSpace(g, tkColon, ":")
  gcoms(g)
  gstmts(g, n.sons[length - 1], c)

proc gmacro(g: var TSrcGen, n: PNode) =
  var c: TContext
  initContext(c)
  gsub(g, n.sons[0])
  putWithSpace(g, tkColon, ":")
  if longMode(n) or (lsub(n.sons[1]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)
  gsons(g, n, c, 1)

proc gcase(g: var TSrcGen, n: PNode) =
  var c: TContext
  initContext(c)
  var length = sonsLen(n)
  var last = if n.sons[length-1].kind == nkElse: -2 else: -1
  if longMode(n, 0, last): incl(c.flags, rfLongMode)
  putWithSpace(g, tkCase, "case")
  gsub(g, n.sons[0])
  gcoms(g)
  optNL(g)
  gsons(g, n, c, 1, last)
  if last == - 2:
    initContext(c)
    if longMode(n.sons[length - 1]): incl(c.flags, rfLongMode)
    gsub(g, n.sons[length - 1], c)

proc gproc(g: var TSrcGen, n: PNode) =
  var c: TContext
  if n.sons[namePos].kind == nkSym:
    put(g, tkSymbol, renderDefinitionName(n.sons[namePos].sym))
  else:
    gsub(g, n.sons[namePos])

  if n.sons[patternPos].kind != nkEmpty:
    gpattern(g, n.sons[patternPos])
  let oldCheckAnon = g.checkAnon
  g.checkAnon = true
  gsub(g, n.sons[genericParamsPos])
  g.checkAnon = oldCheckAnon
  gsub(g, n.sons[paramsPos])
  gsub(g, n.sons[pragmasPos])
  if renderNoBody notin g.flags:
    if n.sons[bodyPos].kind != nkEmpty:
      put(g, tkSpaces, Space)
      putWithSpace(g, tkEquals, "=")
      indentNL(g)
      gcoms(g)
      dedent(g)
      initContext(c)
      gstmts(g, n.sons[bodyPos], c)
      putNL(g)
    else:
      indentNL(g)
      gcoms(g)
      dedent(g)

proc gTypeClassTy(g: var TSrcGen, n: PNode) =
  var c: TContext
  initContext(c)
  putWithSpace(g, tkConcept, "concept")
  gsons(g, n[0], c) # arglist
  gsub(g, n[1]) # pragmas
  gsub(g, n[2]) # of
  gcoms(g)
  indentNL(g)
  gcoms(g)
  gstmts(g, n[3], c)
  dedent(g)

proc gblock(g: var TSrcGen, n: PNode) =
  var c: TContext
  initContext(c)
  if n.sons[0].kind != nkEmpty:
    putWithSpace(g, tkBlock, "block")
    gsub(g, n.sons[0])
  else:
    put(g, tkBlock, "block")
  putWithSpace(g, tkColon, ":")
  if longMode(n) or (lsub(n.sons[1]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)
  # XXX I don't get why this is needed here! gstmts should already handle this!
  indentNL(g)
  gstmts(g, n.sons[1], c)
  dedent(g)

proc gstaticStmt(g: var TSrcGen, n: PNode) =
  var c: TContext
  putWithSpace(g, tkStatic, "static")
  putWithSpace(g, tkColon, ":")
  initContext(c)
  if longMode(n) or (lsub(n.sons[0]) + g.lineLen > MaxLineLen):
    incl(c.flags, rfLongMode)
  gcoms(g)                    # a good place for comments
  gstmts(g, n.sons[0], c)

proc gasm(g: var TSrcGen, n: PNode) =
  putWithSpace(g, tkAsm, "asm")
  gsub(g, n.sons[0])
  gcoms(g)
  gsub(g, n.sons[1])

proc gident(g: var TSrcGen, n: PNode) =
  if g.checkAnon and n.kind == nkSym and sfAnon in n.sym.flags: return
  var t: TTokType
  var s = atom(n)
  if (s[0] in lexer.SymChars):
    if (n.kind == nkIdent):
      if (n.ident.id < ord(tokKeywordLow) - ord(tkSymbol)) or
          (n.ident.id > ord(tokKeywordHigh) - ord(tkSymbol)):
        t = tkSymbol
      else:
        t = TTokType(n.ident.id + ord(tkSymbol))
    else:
      t = tkSymbol
  else:
    t = tkOpr
  put(g, t, s)
  if n.kind == nkSym and renderIds in g.flags: put(g, tkIntLit, $n.sym.id)

proc doParamsAux(g: var TSrcGen, params: PNode) =
  if params.len > 1:
    put(g, tkParLe, "(")
    gsemicolon(g, params, 1)
    put(g, tkParRi, ")")

  if params.sons[0].kind != nkEmpty:
    putWithSpace(g, tkOpr, "->")
    gsub(g, params.sons[0])

proc gsub(g: var TSrcGen, n: PNode, c: TContext) =
  if isNil(n): return
  var
    a: TContext
  if n.comment != nil: pushCom(g, n)
  case n.kind                 # atoms:
  of nkTripleStrLit: putRawStr(g, tkTripleStrLit, n.strVal)
  of nkEmpty: discard
  of nkType: put(g, tkInvalid, atom(n))
  of nkSym, nkIdent: gident(g, n)
  of nkIntLit: put(g, tkIntLit, atom(n))
  of nkInt8Lit: put(g, tkInt8Lit, atom(n))
  of nkInt16Lit: put(g, tkInt16Lit, atom(n))
  of nkInt32Lit: put(g, tkInt32Lit, atom(n))
  of nkInt64Lit: put(g, tkInt64Lit, atom(n))
  of nkUIntLit: put(g, tkUIntLit, atom(n))
  of nkUInt8Lit: put(g, tkUInt8Lit, atom(n))
  of nkUInt16Lit: put(g, tkUInt16Lit, atom(n))
  of nkUInt32Lit: put(g, tkUInt32Lit, atom(n))
  of nkUInt64Lit: put(g, tkUInt64Lit, atom(n))
  of nkFloatLit: put(g, tkFloatLit, atom(n))
  of nkFloat32Lit: put(g, tkFloat32Lit, atom(n))
  of nkFloat64Lit: put(g, tkFloat64Lit, atom(n))
  of nkFloat128Lit: put(g, tkFloat128Lit, atom(n))
  of nkStrLit: put(g, tkStrLit, atom(n))
  of nkRStrLit: put(g, tkRStrLit, atom(n))
  of nkCharLit: put(g, tkCharLit, atom(n))
  of nkNilLit: put(g, tkNil, atom(n))    # complex expressions
  of nkCall, nkConv, nkDotCall, nkPattern, nkObjConstr:
    if sonsLen(n) >= 1: gsub(g, n.sons[0])
    put(g, tkParLe, "(")
    gcomma(g, n, 1)
    put(g, tkParRi, ")")
  of nkCallStrLit:
    gsub(g, n.sons[0])
    if n.sons[1].kind == nkRStrLit:
      put(g, tkRStrLit, '\"' & replace(n[1].strVal, "\"", "\"\"") & '\"')
    else:
      gsub(g, n.sons[1])
  of nkHiddenStdConv, nkHiddenSubConv, nkHiddenCallConv: gsub(g, n.sons[1])
  of nkCast:
    put(g, tkCast, "cast")
    put(g, tkBracketLe, "[")
    gsub(g, n.sons[0])
    put(g, tkBracketRi, "]")
    put(g, tkParLe, "(")
    gsub(g, n.sons[1])
    put(g, tkParRi, ")")
  of nkAddr:
    put(g, tkAddr, "addr")
    if n.len > 0:
      put(g, tkParLe, "(")
      gsub(g, n.sons[0])
      put(g, tkParRi, ")")
  of nkStaticExpr:
    put(g, tkStatic, "static")
    put(g, tkSpaces, Space)
    gsub(g, n.sons[0])
  of nkBracketExpr:
    gsub(g, n.sons[0])
    put(g, tkBracketLe, "[")
    gcomma(g, n, 1)
    put(g, tkBracketRi, "]")
  of nkCurlyExpr:
    gsub(g, n.sons[0])
    put(g, tkCurlyLe, "{")
    gcomma(g, n, 1)
    put(g, tkCurlyRi, "}")
  of nkPragmaExpr:
    gsub(g, n.sons[0])
    gcomma(g, n, 1)
  of nkCommand:
    gsub(g, n.sons[0])
    put(g, tkSpaces, Space)
    gcomma(g, n, 1)
  of nkExprEqExpr, nkAsgn, nkFastAsgn:
    gsub(g, n.sons[0])
    put(g, tkSpaces, Space)
    putWithSpace(g, tkEquals, "=")
    gsub(g, n.sons[1])
  of nkChckRangeF:
    put(g, tkSymbol, "chckRangeF")
    put(g, tkParLe, "(")
    gcomma(g, n)
    put(g, tkParRi, ")")
  of nkChckRange64:
    put(g, tkSymbol, "chckRange64")
    put(g, tkParLe, "(")
    gcomma(g, n)
    put(g, tkParRi, ")")
  of nkChckRange:
    put(g, tkSymbol, "chckRange")
    put(g, tkParLe, "(")
    gcomma(g, n)
    put(g, tkParRi, ")")
  of nkObjDownConv, nkObjUpConv, nkStringToCString, nkCStringToString:
    if sonsLen(n) >= 1: gsub(g, n.sons[0])
    put(g, tkParLe, "(")
    gcomma(g, n, 1)
    put(g, tkParRi, ")")
  of nkClosedSymChoice, nkOpenSymChoice:
    put(g, tkParLe, "(")
    for i in countup(0, sonsLen(n) - 1):
      if i > 0: put(g, tkOpr, "|")
      if n.sons[i].kind == nkSym:
        let s = n[i].sym
        if s.owner != nil:
          put g, tkSymbol, n[i].sym.owner.name.s
          put g, tkOpr, "."
        put g, tkSymbol, n[i].sym.name.s
      else:
        gsub(g, n.sons[i], c)
    put(g, tkParRi, if n.kind == nkOpenSymChoice: "|...)" else: ")")
  of nkPar, nkClosure:
    put(g, tkParLe, "(")
    gcomma(g, n, c)
    put(g, tkParRi, ")")
  of nkCurly:
    put(g, tkCurlyLe, "{")
    gcomma(g, n, c)
    put(g, tkCurlyRi, "}")
  of nkArgList:
    gcomma(g, n, c)
  of nkTableConstr:
    put(g, tkCurlyLe, "{")
    if n.len > 0: gcomma(g, n, c)
    else: put(g, tkColon, ":")
    put(g, tkCurlyRi, "}")
  of nkBracket:
    put(g, tkBracketLe, "[")
    gcomma(g, n, c)
    put(g, tkBracketRi, "]")
  of nkDotExpr:
    gsub(g, n.sons[0])
    put(g, tkDot, ".")
    gsub(g, n.sons[1])
  of nkBind:
    putWithSpace(g, tkBind, "bind")
    gsub(g, n.sons[0])
  of nkCheckedFieldExpr, nkHiddenAddr, nkHiddenDeref:
    gsub(g, n.sons[0])
  of nkLambda:
    putWithSpace(g, tkProc, "proc")
    gsub(g, n.sons[paramsPos])
    gsub(g, n.sons[pragmasPos])
    put(g, tkSpaces, Space)
    putWithSpace(g, tkEquals, "=")
    gsub(g, n.sons[bodyPos])
  of nkDo:
    putWithSpace(g, tkDo, "do")
    doParamsAux(g, n.sons[paramsPos])
    gsub(g, n.sons[pragmasPos])
    put(g, tkColon, ":")
    gsub(g, n.sons[bodyPos])
  of nkConstDef, nkIdentDefs:
    gcomma(g, n, 0, -3)
    var L = sonsLen(n)
    if L >= 2 and n.sons[L - 2].kind != nkEmpty:
      putWithSpace(g, tkColon, ":")
      gsub(g, n.sons[L - 2])
    if L >= 1 and n.sons[L - 1].kind != nkEmpty:
      put(g, tkSpaces, Space)
      putWithSpace(g, tkEquals, "=")
      gsub(g, n.sons[L - 1], c)
  of nkVarTuple:
    put(g, tkParLe, "(")
    gcomma(g, n, 0, -3)
    put(g, tkParRi, ")")
    put(g, tkSpaces, Space)
    putWithSpace(g, tkEquals, "=")
    gsub(g, lastSon(n), c)
  of nkExprColonExpr:
    gsub(g, n.sons[0])
    putWithSpace(g, tkColon, ":")
    gsub(g, n.sons[1])
  of nkInfix:
    gsub(g, n.sons[1])
    put(g, tkSpaces, Space)
    gsub(g, n.sons[0])        # binary operator
    if not fits(g, lsub(n.sons[2]) + lsub(n.sons[0]) + 1):
      optNL(g, g.indent + longIndentWid)
    else:
      put(g, tkSpaces, Space)
    gsub(g, n.sons[2])
  of nkPrefix:
    gsub(g, n.sons[0])
    if n.len > 1:
      put(g, tkSpaces, Space)
      if n.sons[1].kind == nkInfix:
        put(g, tkParLe, "(")
        gsub(g, n.sons[1])
        put(g, tkParRi, ")")
      else:
        gsub(g, n.sons[1])
  of nkPostfix:
    gsub(g, n.sons[1])
    gsub(g, n.sons[0])
  of nkRange:
    gsub(g, n.sons[0])
    put(g, tkDotDot, "..")
    gsub(g, n.sons[1])
  of nkDerefExpr:
    gsub(g, n.sons[0])
    put(g, tkOpr, "[]")
  of nkAccQuoted:
    put(g, tkAccent, "`")
    if n.len > 0: gsub(g, n.sons[0])
    for i in 1 .. <n.len:
      put(g, tkSpaces, Space)
      gsub(g, n.sons[i])
    put(g, tkAccent, "`")
  of nkIfExpr:
    putWithSpace(g, tkIf, "if")
    gsub(g, n.sons[0].sons[0])
    putWithSpace(g, tkColon, ":")
    gsub(g, n.sons[0].sons[1])
    gsons(g, n, emptyContext, 1)
  of nkElifExpr:
    putWithSpace(g, tkElif, " elif")
    gsub(g, n.sons[0])
    putWithSpace(g, tkColon, ":")
    gsub(g, n.sons[1])
  of nkElseExpr:
    put(g, tkElse, " else")
    putWithSpace(g, tkColon, ":")
    gsub(g, n.sons[0])
  of nkTypeOfExpr:
    putWithSpace(g, tkType, "type")
    if n.len > 0: gsub(g, n.sons[0])
  of nkRefTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkRef, "ref")
      gsub(g, n.sons[0])
    else:
      put(g, tkRef, "ref")
  of nkPtrTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkPtr, "ptr")
      gsub(g, n.sons[0])
    else:
      put(g, tkPtr, "ptr")
  of nkVarTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkVar, "var")
      gsub(g, n.sons[0])
    else:
      put(g, tkVar, "var")
  of nkDistinctTy:
    if n.len > 0:
      putWithSpace(g, tkDistinct, "distinct")
      gsub(g, n.sons[0])
      if n.len > 1:
        if n[1].kind == nkWith:
          putWithSpace(g, tkWith, " with")
        else:
          putWithSpace(g, tkWithout, " without")
        gcomma(g, n[1])
    else:
      put(g, tkDistinct, "distinct")
  of nkTypeDef:
    gsub(g, n.sons[0])
    gsub(g, n.sons[1])
    put(g, tkSpaces, Space)
    if n.sons[2].kind != nkEmpty:
      putWithSpace(g, tkEquals, "=")
      gsub(g, n.sons[2])
  of nkObjectTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkObject, "object")
      gsub(g, n.sons[0])
      gsub(g, n.sons[1])
      gcoms(g)
      gsub(g, n.sons[2])
    else:
      put(g, tkObject, "object")
  of nkRecList:
    indentNL(g)
    for i in countup(0, sonsLen(n) - 1):
      optNL(g)
      gsub(g, n.sons[i], c)
      gcoms(g)
    dedent(g)
    putNL(g)
  of nkOfInherit:
    putWithSpace(g, tkOf, "of")
    gsub(g, n.sons[0])
  of nkProcTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkProc, "proc")
      gsub(g, n.sons[0])
      gsub(g, n.sons[1])
    else:
      put(g, tkProc, "proc")
  of nkIteratorTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkIterator, "iterator")
      gsub(g, n.sons[0])
      gsub(g, n.sons[1])
    else:
      put(g, tkIterator, "iterator")
  of nkStaticTy:
    put(g, tkStatic, "static")
    put(g, tkBracketLe, "[")
    if n.len > 0:
      gsub(g, n.sons[0])
    put(g, tkBracketRi, "]")
  of nkEnumTy:
    if sonsLen(n) > 0:
      putWithSpace(g, tkEnum, "enum")
      gsub(g, n.sons[0])
      gcoms(g)
      indentNL(g)
      gcommaAux(g, n, g.indent, 1)
      gcoms(g)                  # BUGFIX: comment for the last enum field
      dedent(g)
    else:
      put(g, tkEnum, "enum")
  of nkEnumFieldDef:
    gsub(g, n.sons[0])
    put(g, tkSpaces, Space)
    putWithSpace(g, tkEquals, "=")
    gsub(g, n.sons[1])
  of nkStmtList, nkStmtListExpr, nkStmtListType: gstmts(g, n, emptyContext)
  of nkIfStmt:
    putWithSpace(g, tkIf, "if")
    gif(g, n)
  of nkWhen, nkRecWhen:
    putWithSpace(g, tkWhen, "when")
    gif(g, n)
  of nkWhileStmt: gwhile(g, n)
  of nkPragmaBlock: gpragmaBlock(g, n)
  of nkCaseStmt, nkRecCase: gcase(g, n)
  of nkTryStmt: gtry(g, n)
  of nkForStmt, nkParForStmt: gfor(g, n)
  of nkBlockStmt, nkBlockExpr: gblock(g, n)
  of nkStaticStmt: gstaticStmt(g, n)
  of nkAsmStmt: gasm(g, n)
  of nkProcDef:
    if renderNoProcDefs notin g.flags: putWithSpace(g, tkProc, "proc")
    gproc(g, n)
  of nkConverterDef:
    if renderNoProcDefs notin g.flags: putWithSpace(g, tkConverter, "converter")
    gproc(g, n)
  of nkMethodDef:
    if renderNoProcDefs notin g.flags: putWithSpace(g, tkMethod, "method")
    gproc(g, n)
  of nkIteratorDef:
    if renderNoProcDefs notin g.flags: putWithSpace(g, tkIterator, "iterator")
    gproc(g, n)
  of nkMacroDef:
    if renderNoProcDefs notin g.flags: putWithSpace(g, tkMacro, "macro")
    gproc(g, n)
  of nkTemplateDef:
    if renderNoProcDefs notin g.flags: putWithSpace(g, tkTemplate, "template")
    gproc(g, n)
  of nkTypeSection:
    gsection(g, n, emptyContext, tkType, "type")
  of nkConstSection:
    initContext(a)
    incl(a.flags, rfInConstExpr)
    gsection(g, n, a, tkConst, "const")
  of nkVarSection, nkLetSection:
    var L = sonsLen(n)
    if L == 0: return
    if n.kind == nkVarSection: putWithSpace(g, tkVar, "var")
    else: putWithSpace(g, tkLet, "let")
    if L > 1:
      gcoms(g)
      indentNL(g)
      for i in countup(0, L - 1):
        optNL(g)
        gsub(g, n.sons[i])
        gcoms(g)
      dedent(g)
    else:
      gsub(g, n.sons[0])
  of nkReturnStmt:
    putWithSpace(g, tkReturn, "return")
    gsub(g, n.sons[0])
  of nkRaiseStmt:
    putWithSpace(g, tkRaise, "raise")
    gsub(g, n.sons[0])
  of nkYieldStmt:
    putWithSpace(g, tkYield, "yield")
    gsub(g, n.sons[0])
  of nkDiscardStmt:
    putWithSpace(g, tkDiscard, "discard")
    gsub(g, n.sons[0])
  of nkBreakStmt:
    putWithSpace(g, tkBreak, "break")
    gsub(g, n.sons[0])
  of nkContinueStmt:
    putWithSpace(g, tkContinue, "continue")
    gsub(g, n.sons[0])
  of nkPragma:
    if renderNoPragmas notin g.flags:
      if g.inPragma <= 0:
        inc g.inPragma
        put(g, tkSpaces, Space)
        put(g, tkCurlyDotLe, "{.")
        gcomma(g, n, emptyContext)
        put(g, tkCurlyDotRi, ".}")
        dec g.inPragma
      else:
        gcomma(g, n, emptyContext)
  of nkImportStmt, nkExportStmt:
    if n.kind == nkImportStmt:
      putWithSpace(g, tkImport, "import")
    else:
      putWithSpace(g, tkExport, "export")
    gcoms(g)
    indentNL(g)
    gcommaAux(g, n, g.indent)
    dedent(g)
    putNL(g)
  of nkImportExceptStmt, nkExportExceptStmt:
    if n.kind == nkImportExceptStmt:
      putWithSpace(g, tkImport, "import")
    else:
      putWithSpace(g, tkExport, "export")
    gsub(g, n.sons[0])
    put(g, tkSpaces, Space)
    putWithSpace(g, tkExcept, "except")
    gcommaAux(g, n, g.indent, 1)
    gcoms(g)
    putNL(g)
  of nkFromStmt:
    putWithSpace(g, tkFrom, "from")
    gsub(g, n.sons[0])
    put(g, tkSpaces, Space)
    putWithSpace(g, tkImport, "import")
    gcomma(g, n, emptyContext, 1)
    putNL(g)
  of nkIncludeStmt:
    putWithSpace(g, tkInclude, "include")
    gcoms(g)
    indentNL(g)
    gcommaAux(g, n, g.indent)
    dedent(g)
    putNL(g)
  of nkCommentStmt:
    gcoms(g)
    optNL(g)
  of nkOfBranch:
    optNL(g)
    putWithSpace(g, tkOf, "of")
    gcomma(g, n, c, 0, - 2)
    putWithSpace(g, tkColon, ":")
    gcoms(g)
    gstmts(g, lastSon(n), c)
  of nkImportAs:
    gsub(g, n.sons[0])
    put(g, tkSpaces, Space)
    putWithSpace(g, tkAs, "as")
    gsub(g, n.sons[1])
  of nkBindStmt:
    putWithSpace(g, tkBind, "bind")
    gcomma(g, n, c)
  of nkMixinStmt:
    putWithSpace(g, tkMixin, "mixin")
    gcomma(g, n, c)
  of nkElifBranch:
    optNL(g)
    putWithSpace(g, tkElif, "elif")
    gsub(g, n.sons[0])
    putWithSpace(g, tkColon, ":")
    gcoms(g)
    gstmts(g, n.sons[1], c)
  of nkElse:
    optNL(g)
    put(g, tkElse, "else")
    putWithSpace(g, tkColon, ":")
    gcoms(g)
    gstmts(g, n.sons[0], c)
  of nkFinally, nkDefer:
    optNL(g)
    if n.kind == nkFinally:
      put(g, tkFinally, "finally")
    else:
      put(g, tkDefer, "defer")
    putWithSpace(g, tkColon, ":")
    gcoms(g)
    gstmts(g, n.sons[0], c)
  of nkExceptBranch:
    optNL(g)
    putWithSpace(g, tkExcept, "except")
    gcomma(g, n, 0, - 2)
    putWithSpace(g, tkColon, ":")
    gcoms(g)
    gstmts(g, lastSon(n), c)
  of nkGenericParams:
    put(g, tkBracketLe, "[")
    gcomma(g, n)
    put(g, tkBracketRi, "]")
  of nkFormalParams:
    put(g, tkParLe, "(")
    gsemicolon(g, n, 1)
    put(g, tkParRi, ")")
    if n.sons[0].kind != nkEmpty:
      putWithSpace(g, tkColon, ":")
      gsub(g, n.sons[0])
  of nkTupleTy:
    put(g, tkTuple, "tuple")
    put(g, tkBracketLe, "[")
    gcomma(g, n)
    put(g, tkBracketRi, "]")
  of nkTupleClassTy:
    put(g, tkTuple, "tuple")
  of nkMetaNode_Obsolete:
    put(g, tkParLe, "(META|")
    gsub(g, n.sons[0])
    put(g, tkParRi, ")")
  of nkGotoState, nkState:
    var c: TContext
    initContext c
    putWithSpace g, tkSymbol, if n.kind == nkState: "state" else: "goto"
    gsons(g, n, c)
  of nkTypeClassTy:
    gTypeClassTy(g, n)
  else:
    #nkNone, nkExplicitTypeListCall:
    internalError(n.info, "rnimsyn.gsub(" & $n.kind & ')')

proc renderTree(n: PNode, renderFlags: TRenderFlags = {}): string =
  var g: TSrcGen
  initSrcGen(g, renderFlags)
  gsub(g, n)
  result = g.buf

proc renderModule(n: PNode, filename: string,
                  renderFlags: TRenderFlags = {}) =
  var
    f: File
    g: TSrcGen
  initSrcGen(g, renderFlags)
  for i in countup(0, sonsLen(n) - 1):
    gsub(g, n.sons[i])
    optNL(g)
    case n.sons[i].kind
    of nkTypeSection, nkConstSection, nkVarSection, nkLetSection,
       nkCommentStmt: putNL(g)
    else: discard
  gcoms(g)
  if optStdout in gGlobalOptions:
    write(stdout, g.buf)
  elif open(f, filename, fmWrite):
    write(f, g.buf)
    close(f)
  else:
    rawMessage(errCannotOpenFile, filename)

proc initTokRender(r: var TSrcGen, n: PNode, renderFlags: TRenderFlags = {}) =
  initSrcGen(r, renderFlags)
  gsub(r, n)

proc getNextTok(r: var TSrcGen, kind: var TTokType, literal: var string) =
  if r.idx < len(r.tokens):
    kind = r.tokens[r.idx].kind
    var length = r.tokens[r.idx].length.int
    literal = substr(r.buf, r.pos, r.pos + length - 1)
    inc(r.pos, length)
    inc(r.idx)
  else:
    kind = tkEof
