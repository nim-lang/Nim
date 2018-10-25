#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This scanner is handwritten for efficiency. I used an elegant buffering
# scheme which I have not seen anywhere else:
# We guarantee that a whole line is in the buffer. Thus only when scanning
# the \n or \r character we have to check wether we need to read in the next
# chunk. (\n or \r already need special handling for incrementing the line
# counter; choosing both \n and \r allows the scanner to properly read Unix,
# DOS or Macintosh text files, even when it is not the native format.

import
  hashes, options, msgs, strutils, platform, idents, nimlexbase, llstream,
  wordrecg, lineinfos, pathutils

const
  MaxLineLength* = 80         # lines longer than this lead to a warning
  numChars*: set[char] = {'0'..'9', 'a'..'z', 'A'..'Z'}
  SymChars*: set[char] = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}
  SymStartChars*: set[char] = {'a'..'z', 'A'..'Z', '\x80'..'\xFF'}
  OpChars*: set[char] = {'+', '-', '*', '/', '\\', '<', '>', '!', '?', '^', '.',
    '|', '=', '%', '&', '$', '@', '~', ':'}

# don't forget to update the 'highlite' module if these charsets should change

type
  TTokType* = enum
    tkInvalid, tkEof,         # order is important here!
    tkSymbol, # keywords:
    tkAddr, tkAnd, tkAs, tkAsm,
    tkBind, tkBlock, tkBreak, tkCase, tkCast,
    tkConcept, tkConst, tkContinue, tkConverter,
    tkDefer, tkDiscard, tkDistinct, tkDiv, tkDo,
    tkElif, tkElse, tkEnd, tkEnum, tkExcept, tkExport,
    tkFinally, tkFor, tkFrom, tkFunc,
    tkIf, tkImport, tkIn, tkInclude, tkInterface,
    tkIs, tkIsnot, tkIterator,
    tkLet,
    tkMacro, tkMethod, tkMixin, tkMod, tkNil, tkNot, tkNotin,
    tkObject, tkOf, tkOr, tkOut,
    tkProc, tkPtr, tkRaise, tkRef, tkReturn,
    tkShl, tkShr, tkStatic,
    tkTemplate,
    tkTry, tkTuple, tkType, tkUsing,
    tkVar, tkWhen, tkWhile, tkXor,
    tkYield, # end of keywords
    tkIntLit, tkInt8Lit, tkInt16Lit, tkInt32Lit, tkInt64Lit,
    tkUIntLit, tkUInt8Lit, tkUInt16Lit, tkUInt32Lit, tkUInt64Lit,
    tkFloatLit, tkFloat32Lit, tkFloat64Lit, tkFloat128Lit,
    tkStrLit, tkRStrLit, tkTripleStrLit,
    tkGStrLit, tkGTripleStrLit, tkCharLit, tkParLe, tkParRi, tkBracketLe,
    tkBracketRi, tkCurlyLe, tkCurlyRi,
    tkBracketDotLe, tkBracketDotRi, # [. and  .]
    tkCurlyDotLe, tkCurlyDotRi, # {.  and  .}
    tkParDotLe, tkParDotRi,   # (. and .)
    tkComma, tkSemiColon,
    tkColon, tkColonColon, tkEquals, tkDot, tkDotDot, tkBracketLeColon,
    tkOpr, tkComment, tkAccent,
    tkSpaces, tkInfixOpr, tkPrefixOpr, tkPostfixOpr

  TTokTypes* = set[TTokType]

const
  weakTokens = {tkComma, tkSemiColon, tkColon,
                tkParRi, tkParDotRi, tkBracketRi, tkBracketDotRi,
                tkCurlyRi} # \
    # tokens that should not be considered for previousToken
  tokKeywordLow* = succ(tkSymbol)
  tokKeywordHigh* = pred(tkIntLit)
  TokTypeToStr*: array[TTokType, string] = ["tkInvalid", "[EOF]",
    "tkSymbol",
    "addr", "and", "as", "asm",
    "bind", "block", "break", "case", "cast",
    "concept", "const", "continue", "converter",
    "defer", "discard", "distinct", "div", "do",
    "elif", "else", "end", "enum", "except", "export",
    "finally", "for", "from", "func", "if",
    "import", "in", "include", "interface", "is", "isnot", "iterator",
    "let",
    "macro", "method", "mixin", "mod",
    "nil", "not", "notin", "object", "of", "or",
    "out", "proc", "ptr", "raise", "ref", "return",
    "shl", "shr", "static",
    "template",
    "try", "tuple", "type", "using",
    "var", "when", "while", "xor",
    "yield",
    "tkIntLit", "tkInt8Lit", "tkInt16Lit", "tkInt32Lit", "tkInt64Lit",
    "tkUIntLit", "tkUInt8Lit", "tkUInt16Lit", "tkUInt32Lit", "tkUInt64Lit",
    "tkFloatLit", "tkFloat32Lit", "tkFloat64Lit", "tkFloat128Lit",
    "tkStrLit", "tkRStrLit",
    "tkTripleStrLit", "tkGStrLit", "tkGTripleStrLit", "tkCharLit", "(",
    ")", "[", "]", "{", "}", "[.", ".]", "{.", ".}", "(.", ".)",
    ",", ";",
    ":", "::", "=", ".", "..", "[:",
    "tkOpr", "tkComment", "`",
    "tkSpaces", "tkInfixOpr",
    "tkPrefixOpr", "tkPostfixOpr"]

type
  TNumericalBase* = enum
    base10,                   # base10 is listed as the first element,
                              # so that it is the correct default value
    base2, base8, base16

  CursorPosition* {.pure.} = enum ## XXX remove this again
    None, InToken, BeforeToken, AfterToken

  TToken* = object            # a Nim token
    tokType*: TTokType        # the type of the token
    indent*: int              # the indentation; != -1 if the token has been
                              # preceded with indentation
    ident*: PIdent            # the parsed identifier
    iNumber*: BiggestInt      # the parsed integer literal
    fNumber*: BiggestFloat    # the parsed floating point literal
    base*: TNumericalBase     # the numerical base; only valid for int
                              # or float literals
    strongSpaceA*: int8       # leading spaces of an operator
    strongSpaceB*: int8       # trailing spaces of an operator
    literal*: string          # the parsed (string) literal; and
                              # documentation comments are here too
    line*, col*: int
    when defined(nimpretty):
      offsetA*, offsetB*: int   # used for pretty printing so that literals
                                # like 0b01 or  r"\L" are unaffected
      commentOffsetA*, commentOffsetB*: int

  TErrorHandler* = proc (conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string)
  TLexer* = object of TBaseLexer
    fileIdx*: FileIndex
    indentAhead*: int         # if > 0 an indendation has already been read
                              # this is needed because scanning comments
                              # needs so much look-ahead
    currLineIndent*: int
    strongSpaces*, allowTabs*: bool
    cursor*: CursorPosition
    errorHandler*: TErrorHandler
    cache*: IdentCache
    when defined(nimsuggest):
      previousToken: TLineInfo
    config*: ConfigRef

when defined(nimpretty):
  var
    gIndentationWidth*: int

proc getLineInfo*(L: TLexer, tok: TToken): TLineInfo {.inline.} =
  result = newLineInfo(L.fileIdx, tok.line, tok.col)
  when defined(nimpretty):
    result.offsetA = tok.offsetA
    result.offsetB = tok.offsetB
    result.commentOffsetA = tok.commentOffsetA
    result.commentOffsetB = tok.commentOffsetB

proc isKeyword*(kind: TTokType): bool =
  result = (kind >= tokKeywordLow) and (kind <= tokKeywordHigh)

template ones(n): untyped = ((1 shl n)-1) # for utf-8 conversion

proc isNimIdentifier*(s: string): bool =
  let sLen = s.len
  if sLen > 0 and s[0] in SymStartChars:
    var i = 1
    while i < sLen:
      if s[i] == '_': inc(i)
      if i < sLen and s[i] notin SymChars: return
      inc(i)
    result = true

proc tokToStr*(tok: TToken): string =
  case tok.tokType
  of tkIntLit..tkInt64Lit: result = $tok.iNumber
  of tkFloatLit..tkFloat64Lit: result = $tok.fNumber
  of tkInvalid, tkStrLit..tkCharLit, tkComment: result = tok.literal
  of tkParLe..tkColon, tkEof, tkAccent:
    result = TokTypeToStr[tok.tokType]
  else:
    if tok.ident != nil:
      result = tok.ident.s
    else:
      result = ""

proc prettyTok*(tok: TToken): string =
  if isKeyword(tok.tokType): result = "keyword " & tok.ident.s
  else: result = tokToStr(tok)

proc printTok*(conf: ConfigRef; tok: TToken) =
  msgWriteln(conf, $tok.line & ":" & $tok.col & "\t" &
      TokTypeToStr[tok.tokType] & " " & tokToStr(tok))

proc initToken*(L: var TToken) =
  L.tokType = tkInvalid
  L.iNumber = 0
  L.indent = 0
  L.strongSpaceA = 0
  L.literal = ""
  L.fNumber = 0.0
  L.base = base10
  L.ident = nil
  when defined(nimpretty):
    L.commentOffsetA = 0
    L.commentOffsetB = 0

proc fillToken(L: var TToken) =
  L.tokType = tkInvalid
  L.iNumber = 0
  L.indent = 0
  L.strongSpaceA = 0
  setLen(L.literal, 0)
  L.fNumber = 0.0
  L.base = base10
  L.ident = nil
  when defined(nimpretty):
    L.commentOffsetA = 0
    L.commentOffsetB = 0

proc openLexer*(lex: var TLexer, fileIdx: FileIndex, inputstream: PLLStream;
                 cache: IdentCache; config: ConfigRef) =
  openBaseLexer(lex, inputstream)
  lex.fileIdx = fileidx
  lex.indentAhead = -1
  lex.currLineIndent = 0
  inc(lex.lineNumber, inputstream.lineOffset)
  lex.cache = cache
  when defined(nimsuggest):
    lex.previousToken.fileIndex = fileIdx
  lex.config = config

proc openLexer*(lex: var TLexer, filename: AbsoluteFile, inputstream: PLLStream;
                cache: IdentCache; config: ConfigRef) =
  openLexer(lex, fileInfoIdx(config, filename), inputstream, cache, config)

proc closeLexer*(lex: var TLexer) =
  if lex.config != nil:
    inc(lex.config.linesCompiled, lex.lineNumber)
  closeBaseLexer(lex)

proc getLineInfo(L: TLexer): TLineInfo =
  result = newLineInfo(L.fileIdx, L.lineNumber, getColNumber(L, L.bufpos))

proc dispMessage(L: TLexer; info: TLineInfo; msg: TMsgKind; arg: string) =
  if L.errorHandler.isNil:
    msgs.message(L.config, info, msg, arg)
  else:
    L.errorHandler(L.config, info, msg, arg)

proc lexMessage*(L: TLexer, msg: TMsgKind, arg = "") =
  L.dispMessage(getLineInfo(L), msg, arg)

proc lexMessageTok*(L: TLexer, msg: TMsgKind, tok: TToken, arg = "") =
  var info = newLineInfo(L.fileIdx, tok.line, tok.col)
  L.dispMessage(info, msg, arg)

proc lexMessagePos(L: var TLexer, msg: TMsgKind, pos: int, arg = "") =
  var info = newLineInfo(L.fileIdx, L.lineNumber, pos - L.lineStart)
  L.dispMessage(info, msg, arg)

proc matchTwoChars(L: TLexer, first: char, second: set[char]): bool =
  result = (L.buf[L.bufpos] == first) and (L.buf[L.bufpos + 1] in second)

template tokenBegin(tok, pos) {.dirty.} =
  when defined(nimsuggest):
    var colA = getColNumber(L, pos)
  when defined(nimpretty):
    tok.offsetA = L.offsetBase + pos

template tokenEnd(tok, pos) {.dirty.} =
  when defined(nimsuggest):
    let colB = getColNumber(L, pos)+1
    if L.fileIdx == L.config.m.trackPos.fileIndex and L.config.m.trackPos.col in colA..colB and
        L.lineNumber == L.config.m.trackPos.line.int and L.config.ideCmd in {ideSug, ideCon}:
      L.cursor = CursorPosition.InToken
      L.config.m.trackPos.col = colA.int16
    colA = 0
  when defined(nimpretty):
    tok.offsetB = L.offsetBase + pos

template tokenEndIgnore(tok, pos) =
  when defined(nimsuggest):
    let colB = getColNumber(L, pos)
    if L.fileIdx == L.config.m.trackPos.fileIndex and L.config.m.trackPos.col in colA..colB and
        L.lineNumber == L.config.m.trackPos.line.int and L.config.ideCmd in {ideSug, ideCon}:
      L.config.m.trackPos.fileIndex = trackPosInvalidFileIdx
      L.config.m.trackPos.line = 0'u16
    colA = 0
  when defined(nimpretty):
    tok.offsetB = L.offsetBase + pos

template tokenEndPrevious(tok, pos) =
  when defined(nimsuggest):
    # when we detect the cursor in whitespace, we attach the track position
    # to the token that came before that, but only if we haven't detected
    # the cursor in a string literal or comment:
    let colB = getColNumber(L, pos)
    if L.fileIdx == L.config.m.trackPos.fileIndex and L.config.m.trackPos.col in colA..colB and
        L.lineNumber == L.config.m.trackPos.line.int and L.config.ideCmd in {ideSug, ideCon}:
      L.cursor = CursorPosition.BeforeToken
      L.config.m.trackPos = L.previousToken
      L.config.m.trackPosAttached = true
    colA = 0
  when defined(nimpretty):
    tok.offsetB = L.offsetBase + pos

{.push overflowChecks: off.}
# We need to parse the largest uint literal without overflow checks
proc unsafeParseUInt(s: string, b: var BiggestInt, start = 0): int =
  var i = start
  if i < s.len and s[i] in {'0'..'9'}:
    b = 0
    while i < s.len and s[i] in {'0'..'9'}:
      b = b * 10 + (ord(s[i]) - ord('0'))
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored
    result = i - start
{.pop.} # overflowChecks


template eatChar(L: var TLexer, t: var TToken, replacementChar: char) =
  add(t.literal, replacementChar)
  inc(L.bufpos)

template eatChar(L: var TLexer, t: var TToken) =
  add(t.literal, L.buf[L.bufpos])
  inc(L.bufpos)

proc getNumber(L: var TLexer, result: var TToken) =
  proc matchUnderscoreChars(L: var TLexer, tok: var TToken, chars: set[char]): Natural =
    var pos = L.bufpos              # use registers for pos, buf
    var buf = L.buf
    result = 0
    while true:
      if buf[pos] in chars:
        add(tok.literal, buf[pos])
        inc(pos)
        inc(result)
      else:
        break
      if buf[pos] == '_':
        if buf[pos+1] notin chars:
          lexMessage(L, errGenerated,
            "only single underscores may occur in a token and token may not " &
            "end with an underscore: e.g. '1__1' and '1_' are invalid")
          break
        add(tok.literal, '_')
        inc(pos)
    L.bufpos = pos

  proc matchChars(L: var TLexer, tok: var TToken, chars: set[char]) =
    var pos = L.bufpos              # use registers for pos, buf
    var buf = L.buf
    while buf[pos] in chars:
      add(tok.literal, buf[pos])
      inc(pos)
    L.bufpos = pos

  proc lexMessageLitNum(L: var TLexer, msg: string, startpos: int, msgKind = errGenerated) =
    # Used to get slightly human friendlier err messages.
    const literalishChars = {'A'..'F', 'a'..'f', '0'..'9', 'X', 'x', 'o', 'O',
      'c', 'C', 'b', 'B', '_', '.', '\'', 'd', 'i', 'u'}
    var msgPos = L.bufpos
    var t: TToken
    t.literal = ""
    L.bufpos = startpos # Use L.bufpos as pos because of matchChars
    matchChars(L, t, literalishChars)
    # We must verify +/- specifically so that we're not past the literal
    if  L.buf[L.bufpos] in {'+', '-'} and
        L.buf[L.bufpos - 1] in {'e', 'E'}:
      add(t.literal, L.buf[L.bufpos])
      inc(L.bufpos)
      matchChars(L, t, literalishChars)
    if L.buf[L.bufpos] in {'\'', 'f', 'F', 'd', 'D', 'i', 'I', 'u', 'U'}:
      inc(L.bufpos)
      add(t.literal, L.buf[L.bufpos])
      matchChars(L, t, {'0'..'9'})
    L.bufpos = msgPos
    lexMessage(L, msgKind, msg % t.literal)

  var
    startpos, endpos: int
    xi: BiggestInt
    isBase10 = true
    numDigits = 0
  const
    # 'c', 'C' is deprecated
    baseCodeChars = {'X', 'x', 'o', 'b', 'B', 'c', 'C'}
    literalishChars = baseCodeChars + {'A'..'F', 'a'..'f', '0'..'9', '_', '\''}
    floatTypes = {tkFloatLit, tkFloat32Lit, tkFloat64Lit, tkFloat128Lit}
  result.tokType = tkIntLit   # int literal until we know better
  result.literal = ""
  result.base = base10
  startpos = L.bufpos
  tokenBegin(result, startPos)

  # First stage: find out base, make verifications, build token literal string
  # {'c', 'C'} is added for deprecation reasons to provide a clear error message
  if L.buf[L.bufpos] == '0' and L.buf[L.bufpos + 1] in baseCodeChars + {'c', 'C', 'O'}:
    isBase10 = false
    eatChar(L, result, '0')
    case L.buf[L.bufpos]
    of 'c', 'C':
      lexMessageLitNum(L,
                       "$1 will soon be invalid for oct literals; Use '0o' " &
                       "for octals. 'c', 'C' prefix",
                       startpos,
                       warnDeprecated)
      eatChar(L, result, 'c')
      numDigits = matchUnderscoreChars(L, result, {'0'..'7'})
    of 'O':
      lexMessageLitNum(L, "$1 is an invalid int literal; For octal literals " &
                          "use the '0o' prefix.", startpos)
    of 'x', 'X':
      eatChar(L, result, 'x')
      numDigits = matchUnderscoreChars(L, result, {'0'..'9', 'a'..'f', 'A'..'F'})
    of 'o':
      eatChar(L, result, 'o')
      numDigits = matchUnderscoreChars(L, result, {'0'..'7'})
    of 'b', 'B':
      eatChar(L, result, 'b')
      numDigits = matchUnderscoreChars(L, result, {'0'..'1'})
    else:
      internalError(L.config, getLineInfo(L), "getNumber")
    if numDigits == 0:
      lexMessageLitNum(L, "invalid number: '$1'", startpos)
  else:
    discard matchUnderscoreChars(L, result, {'0'..'9'})
    if (L.buf[L.bufpos] == '.') and (L.buf[L.bufpos + 1] in {'0'..'9'}):
      result.tokType = tkFloatLit
      eatChar(L, result, '.')
      discard matchUnderscoreChars(L, result, {'0'..'9'})
    if L.buf[L.bufpos] in {'e', 'E'}:
      result.tokType = tkFloatLit
      eatChar(L, result, 'e')
      if L.buf[L.bufpos] in {'+', '-'}:
        eatChar(L, result)
      discard matchUnderscoreChars(L, result, {'0'..'9'})
  endpos = L.bufpos

  # Second stage, find out if there's a datatype suffix and handle it
  var postPos = endpos
  if L.buf[postPos] in {'\'', 'f', 'F', 'd', 'D', 'i', 'I', 'u', 'U'}:
    if L.buf[postPos] == '\'':
      inc(postPos)

    case L.buf[postPos]
    of 'f', 'F':
      inc(postPos)
      if (L.buf[postPos] == '3') and (L.buf[postPos + 1] == '2'):
        result.tokType = tkFloat32Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '6') and (L.buf[postPos + 1] == '4'):
        result.tokType = tkFloat64Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '1') and
           (L.buf[postPos + 1] == '2') and
           (L.buf[postPos + 2] == '8'):
        result.tokType = tkFloat128Lit
        inc(postPos, 3)
      else:   # "f" alone defaults to float32
        result.tokType = tkFloat32Lit
    of 'd', 'D':  # ad hoc convenience shortcut for f64
      inc(postPos)
      result.tokType = tkFloat64Lit
    of 'i', 'I':
      inc(postPos)
      if (L.buf[postPos] == '6') and (L.buf[postPos + 1] == '4'):
        result.tokType = tkInt64Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '3') and (L.buf[postPos + 1] == '2'):
        result.tokType = tkInt32Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '1') and (L.buf[postPos + 1] == '6'):
        result.tokType = tkInt16Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '8'):
        result.tokType = tkInt8Lit
        inc(postPos)
      else:
        lexMessageLitNum(L, "invalid number: '$1'", startpos)
    of 'u', 'U':
      inc(postPos)
      if (L.buf[postPos] == '6') and (L.buf[postPos + 1] == '4'):
        result.tokType = tkUInt64Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '3') and (L.buf[postPos + 1] == '2'):
        result.tokType = tkUInt32Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '1') and (L.buf[postPos + 1] == '6'):
        result.tokType = tkUInt16Lit
        inc(postPos, 2)
      elif (L.buf[postPos] == '8'):
        result.tokType = tkUInt8Lit
        inc(postPos)
      else:
        result.tokType = tkUIntLit
    else:
      lexMessageLitNum(L, "invalid number: '$1'", startpos)

  # Is there still a literalish char awaiting? Then it's an error!
  if  L.buf[postPos] in literalishChars or
     (L.buf[postPos] == '.' and L.buf[postPos + 1] in {'0'..'9'}):
    lexMessageLitNum(L, "invalid number: '$1'", startpos)

  # Third stage, extract actual number
  L.bufpos = startpos            # restore position
  var pos: int = startpos
  try:
    if (L.buf[pos] == '0') and (L.buf[pos + 1] in baseCodeChars):
      inc(pos, 2)
      xi = 0                  # it is a base prefix

      case L.buf[pos - 1]
      of 'b', 'B':
        result.base = base2
        while pos < endpos:
          if L.buf[pos] != '_':
            xi = `shl`(xi, 1) or (ord(L.buf[pos]) - ord('0'))
          inc(pos)
      # 'c', 'C' is deprecated
      of 'o', 'c', 'C':
        result.base = base8
        while pos < endpos:
          if L.buf[pos] != '_':
            xi = `shl`(xi, 3) or (ord(L.buf[pos]) - ord('0'))
          inc(pos)
      of 'x', 'X':
        result.base = base16
        while pos < endpos:
          case L.buf[pos]
          of '_':
            inc(pos)
          of '0'..'9':
            xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('0'))
            inc(pos)
          of 'a'..'f':
            xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('a') + 10)
            inc(pos)
          of 'A'..'F':
            xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('A') + 10)
            inc(pos)
          else:
            break
      else:
        internalError(L.config, getLineInfo(L), "getNumber")

      case result.tokType
      of tkIntLit, tkInt64Lit: result.iNumber = xi
      of tkInt8Lit: result.iNumber = BiggestInt(int8(toU8(int(xi))))
      of tkInt16Lit: result.iNumber = BiggestInt(int16(toU16(int(xi))))
      of tkInt32Lit: result.iNumber = BiggestInt(int32(toU32(int64(xi))))
      of tkUIntLit, tkUInt64Lit: result.iNumber = xi
      of tkUInt8Lit: result.iNumber = BiggestInt(uint8(toU8(int(xi))))
      of tkUInt16Lit: result.iNumber = BiggestInt(uint16(toU16(int(xi))))
      of tkUInt32Lit: result.iNumber = BiggestInt(uint32(toU32(int64(xi))))
      of tkFloat32Lit:
        result.fNumber = (cast[PFloat32](addr(xi)))[]
        # note: this code is endian neutral!
        # XXX: Test this on big endian machine!
      of tkFloat64Lit, tkFloatLit:
        result.fNumber = (cast[PFloat64](addr(xi)))[]
      else: internalError(L.config, getLineInfo(L), "getNumber")

      # Bounds checks. Non decimal literals are allowed to overflow the range of
      # the datatype as long as their pattern don't overflow _bitwise_, hence
      # below checks of signed sizes against uint*.high is deliberate:
      # (0x80'u8 = 128, 0x80'i8 = -128, etc == OK)
      if result.tokType notin floatTypes:
        let outOfRange = case result.tokType:
        of tkUInt8Lit, tkUInt16Lit, tkUInt32Lit: result.iNumber != xi
        of tkInt8Lit: (xi > BiggestInt(uint8.high))
        of tkInt16Lit: (xi > BiggestInt(uint16.high))
        of tkInt32Lit: (xi > BiggestInt(uint32.high))
        else: false

        if outOfRange:
          #echo "out of range num: ", result.iNumber, " vs ", xi
          lexMessageLitNum(L, "number out of range: '$1'", startpos)

    else:
      case result.tokType
      of floatTypes:
        result.fNumber = parseFloat(result.literal)
      of tkUint64Lit:
        xi = 0
        let len = unsafeParseUInt(result.literal, xi)
        if len != result.literal.len or len == 0:
          raise newException(ValueError, "invalid integer: " & $xi)
        result.iNumber = xi
      else:
        result.iNumber = parseBiggestInt(result.literal)

      # Explicit bounds checks
      let outOfRange =
        case result.tokType
        of tkInt8Lit: (result.iNumber < int8.low or result.iNumber > int8.high)
        of tkUInt8Lit: (result.iNumber < BiggestInt(uint8.low) or
                        result.iNumber > BiggestInt(uint8.high))
        of tkInt16Lit: (result.iNumber < int16.low or result.iNumber > int16.high)
        of tkUInt16Lit: (result.iNumber < BiggestInt(uint16.low) or
                        result.iNumber > BiggestInt(uint16.high))
        of tkInt32Lit: (result.iNumber < int32.low or result.iNumber > int32.high)
        of tkUInt32Lit: (result.iNumber < BiggestInt(uint32.low) or
                        result.iNumber > BiggestInt(uint32.high))
        else: false

      if outOfRange: lexMessageLitNum(L, "number out of range: '$1'", startpos)

    # Promote int literal to int64? Not always necessary, but more consistent
    if result.tokType == tkIntLit:
      if (result.iNumber < low(int32)) or (result.iNumber > high(int32)):
        result.tokType = tkInt64Lit

  except ValueError:
    lexMessageLitNum(L, "invalid number: '$1'", startpos)
  except OverflowError, RangeError:
    lexMessageLitNum(L, "number out of range: '$1'", startpos)
  tokenEnd(result, postPos-1)
  L.bufpos = postPos

proc handleHexChar(L: var TLexer, xi: var int) =
  case L.buf[L.bufpos]
  of '0'..'9':
    xi = (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('0'))
    inc(L.bufpos)
  of 'a'..'f':
    xi = (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('a') + 10)
    inc(L.bufpos)
  of 'A'..'F':
    xi = (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('A') + 10)
    inc(L.bufpos)
  else:
    lexMessage(L, errGenerated,
      "expected a hex digit, but found: " & L.buf[L.bufpos])
    # Need to progress for `nim check`
    inc(L.bufpos)

proc handleDecChars(L: var TLexer, xi: var int) =
  while L.buf[L.bufpos] in {'0'..'9'}:
    xi = (xi * 10) + (ord(L.buf[L.bufpos]) - ord('0'))
    inc(L.bufpos)

proc addUnicodeCodePoint(s: var string, i: int) =
  # inlined toUTF-8 to avoid unicode and strutils dependencies.
  let pos = s.len
  if i <=% 127:
    s.setLen(pos+1)
    s[pos+0] = chr(i)
  elif i <=% 0x07FF:
    s.setLen(pos+2)
    s[pos+0] = chr((i shr 6) or 0b110_00000)
    s[pos+1] = chr((i and ones(6)) or 0b10_0000_00)
  elif i <=% 0xFFFF:
    s.setLen(pos+3)
    s[pos+0] = chr(i shr 12 or 0b1110_0000)
    s[pos+1] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i and ones(6) or 0b10_0000_00)
  elif i <=% 0x001FFFFF:
    s.setLen(pos+4)
    s[pos+0] = chr(i shr 18 or 0b1111_0000)
    s[pos+1] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i and ones(6) or 0b10_0000_00)
  elif i <=% 0x03FFFFFF:
    s.setLen(pos+5)
    s[pos+0] = chr(i shr 24 or 0b111110_00)
    s[pos+1] = chr(i shr 18 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+4] = chr(i and ones(6) or 0b10_0000_00)
  elif i <=% 0x7FFFFFFF:
    s.setLen(pos+6)
    s[pos+0] = chr(i shr 30 or 0b1111110_0)
    s[pos+1] = chr(i shr 24 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 18 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+4] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+5] = chr(i and ones(6) or 0b10_0000_00)

proc getEscapedChar(L: var TLexer, tok: var TToken) =
  inc(L.bufpos)               # skip '\'
  case L.buf[L.bufpos]
  of 'n', 'N':
    if L.config.oldNewlines:
      if tok.tokType == tkCharLit:
        lexMessage(L, errGenerated, "\\n not allowed in character literal")
      add(tok.literal, L.config.target.tnl)
    else:
      add(tok.literal, '\L')
    inc(L.bufpos)
  of 'p', 'P':
    if tok.tokType == tkCharLit:
      lexMessage(L, errGenerated, "\\p not allowed in character literal")
    add(tok.literal, L.config.target.tnl)
    inc(L.bufpos)
  of 'r', 'R', 'c', 'C':
    add(tok.literal, CR)
    inc(L.bufpos)
  of 'l', 'L':
    add(tok.literal, LF)
    inc(L.bufpos)
  of 'f', 'F':
    add(tok.literal, FF)
    inc(L.bufpos)
  of 'e', 'E':
    add(tok.literal, ESC)
    inc(L.bufpos)
  of 'a', 'A':
    add(tok.literal, BEL)
    inc(L.bufpos)
  of 'b', 'B':
    add(tok.literal, BACKSPACE)
    inc(L.bufpos)
  of 'v', 'V':
    add(tok.literal, VT)
    inc(L.bufpos)
  of 't', 'T':
    add(tok.literal, '\t')
    inc(L.bufpos)
  of '\'', '\"':
    add(tok.literal, L.buf[L.bufpos])
    inc(L.bufpos)
  of '\\':
    add(tok.literal, '\\')
    inc(L.bufpos)
  of 'x', 'X':
    inc(L.bufpos)
    var xi = 0
    handleHexChar(L, xi)
    handleHexChar(L, xi)
    add(tok.literal, chr(xi))
  of 'u', 'U':
    if tok.tokType == tkCharLit:
      lexMessage(L, errGenerated, "\\u not allowed in character literal")
    inc(L.bufpos)
    var xi = 0
    if L.buf[L.bufpos] == '{':
      inc(L.bufpos)
      var start = L.bufpos
      while L.buf[L.bufpos] != '}':
        handleHexChar(L, xi)
      if start == L.bufpos:
        lexMessage(L, errGenerated,
          "Unicode codepoint cannot be empty")
      inc(L.bufpos)
      if xi > 0x10FFFF:
        let hex = ($L.buf)[start..L.bufpos-2]
        lexMessage(L, errGenerated,
          "Unicode codepoint must be lower than 0x10FFFF, but was: " & hex)
    else:
      handleHexChar(L, xi)
      handleHexChar(L, xi)
      handleHexChar(L, xi)
      handleHexChar(L, xi)
    addUnicodeCodePoint(tok.literal, xi)
  of '0'..'9':
    if matchTwoChars(L, '0', {'0'..'9'}):
      lexMessage(L, warnOctalEscape)
    var xi = 0
    handleDecChars(L, xi)
    if (xi <= 255): add(tok.literal, chr(xi))
    else: lexMessage(L, errGenerated, "invalid character constant")
  else: lexMessage(L, errGenerated, "invalid character constant")

proc newString(s: cstring, len: int): string =
  ## XXX, how come there is no support for this?
  result = newString(len)
  for i in 0 ..< len:
    result[i] = s[i]

proc handleCRLF(L: var TLexer, pos: int): int =
  template registerLine =
    let col = L.getColNumber(pos)

    if col > MaxLineLength:
      lexMessagePos(L, hintLineTooLong, pos)

  case L.buf[pos]
  of CR:
    registerLine()
    result = nimlexbase.handleCR(L, pos)
  of LF:
    registerLine()
    result = nimlexbase.handleLF(L, pos)
  else: result = pos

type
  StringMode = enum
    normal,
    raw,
    generalized

proc getString(L: var TLexer, tok: var TToken, mode: StringMode) =
  var pos = L.bufpos
  var buf = L.buf                 # put `buf` in a register
  var line = L.lineNumber         # save linenumber for better error message
  tokenBegin(tok, pos - ord(mode == raw))
  inc pos # skip "
  if buf[pos] == '\"' and buf[pos+1] == '\"':
    tok.tokType = tkTripleStrLit # long string literal:
    inc(pos, 2)               # skip ""
    # skip leading newline:
    if buf[pos] in {' ', '\t'}:
      var newpos = pos+1
      while buf[newpos] in {' ', '\t'}: inc newpos
      if buf[newpos] in {CR, LF}: pos = newpos
    pos = handleCRLF(L, pos)
    buf = L.buf
    while true:
      case buf[pos]
      of '\"':
        if buf[pos+1] == '\"' and buf[pos+2] == '\"' and
            buf[pos+3] != '\"':
          tokenEndIgnore(tok, pos+2)
          L.bufpos = pos + 3 # skip the three """
          break
        add(tok.literal, '\"')
        inc(pos)
      of CR, LF:
        tokenEndIgnore(tok, pos)
        pos = handleCRLF(L, pos)
        buf = L.buf
        add(tok.literal, "\n")
      of nimlexbase.EndOfFile:
        tokenEndIgnore(tok, pos)
        var line2 = L.lineNumber
        L.lineNumber = line
        lexMessagePos(L, errGenerated, L.lineStart, "closing \"\"\" expected, but end of file reached")
        L.lineNumber = line2
        L.bufpos = pos
        break
      else:
        add(tok.literal, buf[pos])
        inc(pos)
  else:
    # ordinary string literal
    if mode != normal: tok.tokType = tkRStrLit
    else: tok.tokType = tkStrLit
    while true:
      var c = buf[pos]
      if c == '\"':
        if mode != normal and buf[pos+1] == '\"':
          inc(pos, 2)
          add(tok.literal, '"')
        else:
          tokenEndIgnore(tok, pos)
          inc(pos) # skip '"'
          break
      elif c in {CR, LF, nimlexbase.EndOfFile}:
        tokenEndIgnore(tok, pos)
        lexMessage(L, errGenerated, "closing \" expected")
        break
      elif (c == '\\') and mode == normal:
        L.bufpos = pos
        getEscapedChar(L, tok)
        pos = L.bufpos
      else:
        add(tok.literal, c)
        inc(pos)
    L.bufpos = pos

proc getCharacter(L: var TLexer, tok: var TToken) =
  tokenBegin(tok, L.bufpos)
  inc(L.bufpos)               # skip '
  var c = L.buf[L.bufpos]
  case c
  of '\0'..pred(' '), '\'': lexMessage(L, errGenerated, "invalid character literal")
  of '\\': getEscapedChar(L, tok)
  else:
    tok.literal = $c
    inc(L.bufpos)
  if L.buf[L.bufpos] != '\'':
    lexMessage(L, errGenerated, "missing closing ' for character literal")
  tokenEndIgnore(tok, L.bufpos)
  inc(L.bufpos)               # skip '

proc getSymbol(L: var TLexer, tok: var TToken) =
  var h: Hash = 0
  var pos = L.bufpos
  var buf = L.buf
  tokenBegin(tok, pos)
  while true:
    var c = buf[pos]
    case c
    of 'a'..'z', '0'..'9', '\x80'..'\xFF':
      h = h !& ord(c)
      inc(pos)
    of 'A'..'Z':
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h !& ord(c)
      inc(pos)
    of '_':
      if buf[pos+1] notin SymChars:
        lexMessage(L, errGenerated, "invalid token: trailing underscore")
        break
      inc(pos)
    else: break
  tokenEnd(tok, pos-1)
  h = !$h
  tok.ident = L.cache.getIdent(addr(L.buf[L.bufpos]), pos - L.bufpos, h)
  L.bufpos = pos
  if (tok.ident.id < ord(tokKeywordLow) - ord(tkSymbol)) or
      (tok.ident.id > ord(tokKeywordHigh) - ord(tkSymbol)):
    tok.tokType = tkSymbol
  else:
    tok.tokType = TTokType(tok.ident.id + ord(tkSymbol))

proc endOperator(L: var TLexer, tok: var TToken, pos: int,
                 hash: Hash) {.inline.} =
  var h = !$hash
  tok.ident = L.cache.getIdent(addr(L.buf[L.bufpos]), pos - L.bufpos, h)
  if (tok.ident.id < oprLow) or (tok.ident.id > oprHigh): tok.tokType = tkOpr
  else: tok.tokType = TTokType(tok.ident.id - oprLow + ord(tkColon))
  L.bufpos = pos

proc getOperator(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tokenBegin(tok, pos)
  var h: Hash = 0
  while true:
    var c = buf[pos]
    if c notin OpChars: break
    h = h !& ord(c)
    inc(pos)
  endOperator(L, tok, pos, h)
  tokenEnd(tok, pos-1)
  # advance pos but don't store it in L.bufpos so the next token (which might
  # be an operator too) gets the preceding spaces:
  tok.strongSpaceB = 0
  while buf[pos] == ' ':
    inc pos
    inc tok.strongSpaceB
  if buf[pos] in {CR, LF, nimlexbase.EndOfFile}:
    tok.strongSpaceB = -1

proc getPrecedence*(tok: TToken, strongSpaces: bool): int =
  ## Calculates the precedence of the given token.
  template considerStrongSpaces(x): untyped =
    x + (if strongSpaces: 100 - tok.strongSpaceA.int*10 else: 0)

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


proc newlineFollows*(L: TLexer): bool =
  var pos = L.bufpos
  var buf = L.buf
  while true:
    case buf[pos]
    of ' ', '\t':
      inc(pos)
    of CR, LF:
      result = true
      break
    of '#':
      inc(pos)
      if buf[pos] == '#': inc(pos)
      if buf[pos] != '[': return true
    else:
      break

proc skipMultiLineComment(L: var TLexer; tok: var TToken; start: int;
                          isDoc: bool) =
  var pos = start
  var buf = L.buf
  var toStrip = 0
  tokenBegin(tok, pos)
  # detect the amount of indentation:
  if isDoc:
    toStrip = getColNumber(L, pos)
    while buf[pos] == ' ': inc pos
    if buf[pos] in {CR, LF}:
      pos = handleCRLF(L, pos)
      buf = L.buf
      toStrip = 0
      while buf[pos] == ' ':
        inc pos
        inc toStrip
  var nesting = 0
  while true:
    case buf[pos]
    of '#':
      if isDoc:
        if buf[pos+1] == '#' and buf[pos+2] == '[':
          inc nesting
        tok.literal.add '#'
      elif buf[pos+1] == '[':
        inc nesting
      inc pos
    of ']':
      if isDoc:
        if buf[pos+1] == '#' and buf[pos+2] == '#':
          if nesting == 0:
            tokenEndIgnore(tok, pos+2)
            inc(pos, 3)
            break
          dec nesting
        tok.literal.add ']'
      elif buf[pos+1] == '#':
        if nesting == 0:
          tokenEndIgnore(tok, pos+1)
          inc(pos, 2)
          break
        dec nesting
      inc pos
    of CR, LF:
      tokenEndIgnore(tok, pos)
      pos = handleCRLF(L, pos)
      buf = L.buf
      # strip leading whitespace:
      when defined(nimpretty): tok.literal.add "\L"
      if isDoc:
        when not defined(nimpretty): tok.literal.add "\n"
        inc tok.iNumber
        var c = toStrip
        while buf[pos] == ' ' and c > 0:
          inc pos
          dec c
    of nimlexbase.EndOfFile:
      tokenEndIgnore(tok, pos)
      lexMessagePos(L, errGenerated, pos, "end of multiline comment expected")
      break
    else:
      if isDoc or defined(nimpretty): tok.literal.add buf[pos]
      inc(pos)
  L.bufpos = pos
  when defined(nimpretty):
    tok.commentOffsetB = L.offsetBase + pos - 1

proc scanComment(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tok.tokType = tkComment
  # iNumber contains the number of '\n' in the token
  tok.iNumber = 0
  assert buf[pos+1] == '#'
  when defined(nimpretty):
    tok.commentOffsetA = L.offsetBase + pos - 1

  if buf[pos+2] == '[':
    skipMultiLineComment(L, tok, pos+3, true)
    return
  tokenBegin(tok, pos)
  inc(pos, 2)

  var toStrip = 0
  while buf[pos] == ' ':
    inc pos
    inc toStrip

  while true:
    var lastBackslash = -1
    while buf[pos] notin {CR, LF, nimlexbase.EndOfFile}:
      if buf[pos] == '\\': lastBackslash = pos+1
      add(tok.literal, buf[pos])
      inc(pos)
    tokenEndIgnore(tok, pos)
    pos = handleCRLF(L, pos)
    buf = L.buf
    var indent = 0
    while buf[pos] == ' ':
      inc(pos)
      inc(indent)

    if buf[pos] == '#' and buf[pos+1] == '#':
      tok.literal.add "\n"
      inc(pos, 2)
      var c = toStrip
      while buf[pos] == ' ' and c > 0:
        inc pos
        dec c
      inc tok.iNumber
    else:
      if buf[pos] > ' ':
        L.indentAhead = indent
      tokenEndIgnore(tok, pos)
      break
  L.bufpos = pos
  when defined(nimpretty):
    tok.commentOffsetB = L.offsetBase + pos - 1

proc skip(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tokenBegin(tok, pos)
  tok.strongSpaceA = 0
  when defined(nimpretty):
    var hasComment = false
    var commentIndent = L.currLineIndent
    tok.commentOffsetA = L.offsetBase + pos
    tok.commentOffsetB = tok.commentOffsetA
    tok.line = -1
  while true:
    case buf[pos]
    of ' ':
      inc(pos)
      inc(tok.strongSpaceA)
    of '\t':
      if not L.allowTabs: lexMessagePos(L, errGenerated, pos, "tabulators are not allowed")
      inc(pos)
    of CR, LF:
      tokenEndPrevious(tok, pos)
      pos = handleCRLF(L, pos)
      buf = L.buf
      var indent = 0
      while true:
        if buf[pos] == ' ':
          inc(pos)
          inc(indent)
        elif buf[pos] == '#' and buf[pos+1] == '[':
          when defined(nimpretty):
            hasComment = true
            if tok.line < 0:
              tok.line = L.lineNumber
              commentIndent = indent
          skipMultiLineComment(L, tok, pos+2, false)
          pos = L.bufpos
          buf = L.buf
        else:
          break
      tok.strongSpaceA = 0
      when defined(nimpretty):
        if buf[pos] == '#' and tok.line < 0: commentIndent = indent
      if buf[pos] > ' ' and (buf[pos] != '#' or buf[pos+1] == '#'):
        tok.indent = indent
        L.currLineIndent = indent
        break
    of '#':
      # do not skip documentation comment:
      if buf[pos+1] == '#': break
      when defined(nimpretty):
        hasComment = true
        if tok.line < 0:
          tok.line = L.lineNumber

      if buf[pos+1] == '[':
        skipMultiLineComment(L, tok, pos+2, false)
        pos = L.bufpos
        buf = L.buf
      else:
        tokenBegin(tok, pos)
        while buf[pos] notin {CR, LF, nimlexbase.EndOfFile}:
          when defined(nimpretty): tok.literal.add buf[pos]
          inc(pos)
        tokenEndIgnore(tok, pos+1)
        when defined(nimpretty):
          tok.commentOffsetB = L.offsetBase + pos + 1
    else:
      break                   # EndOfFile also leaves the loop
  tokenEndPrevious(tok, pos-1)
  L.bufpos = pos
  when defined(nimpretty):
    if hasComment:
      tok.commentOffsetB = L.offsetBase + pos - 1
      tok.tokType = tkComment
      tok.indent = commentIndent
    if gIndentationWidth <= 0:
      gIndentationWidth = tok.indent

proc rawGetTok*(L: var TLexer, tok: var TToken) =
  template atTokenEnd() {.dirty.} =
    when defined(nimsuggest):
      # we attach the cursor to the last *strong* token
      if tok.tokType notin weakTokens:
        L.previousToken.line = tok.line.uint16
        L.previousToken.col = tok.col.int16

  when defined(nimsuggest):
    L.cursor = CursorPosition.None
  fillToken(tok)
  if L.indentAhead >= 0:
    tok.indent = L.indentAhead
    L.currLineIndent = L.indentAhead
    L.indentAhead = -1
  else:
    tok.indent = -1
  skip(L, tok)
  when defined(nimpretty):
    if tok.tokType == tkComment:
      L.indentAhead = L.currLineIndent
      return
  var c = L.buf[L.bufpos]
  tok.line = L.lineNumber
  tok.col = getColNumber(L, L.bufpos)
  if c in SymStartChars - {'r', 'R'}:
    getSymbol(L, tok)
  else:
    case c
    of '#':
      scanComment(L, tok)
    of '*':
      # '*:' is unfortunately a special case, because it is two tokens in
      # 'var v*: int'.
      if L.buf[L.bufpos+1] == ':' and L.buf[L.bufpos+2] notin OpChars:
        var h = 0 !& ord('*')
        endOperator(L, tok, L.bufpos+1, h)
      else:
        getOperator(L, tok)
    of ',':
      tok.tokType = tkComma
      inc(L.bufpos)
    of 'r', 'R':
      if L.buf[L.bufpos + 1] == '\"':
        inc(L.bufpos)
        getString(L, tok, raw)
      else:
        getSymbol(L, tok)
    of '(':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.' and L.buf[L.bufpos+1] != '.':
        tok.tokType = tkParDotLe
        inc(L.bufpos)
      else:
        tok.tokType = tkParLe
        when defined(nimsuggest):
          if L.fileIdx == L.config.m.trackPos.fileIndex and tok.col < L.config.m.trackPos.col and
                    tok.line == L.config.m.trackPos.line.int and L.config.ideCmd == ideCon:
            L.config.m.trackPos.col = tok.col.int16
    of ')':
      tok.tokType = tkParRi
      inc(L.bufpos)
    of '[':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.' and L.buf[L.bufpos+1] != '.':
        tok.tokType = tkBracketDotLe
        inc(L.bufpos)
      elif L.buf[L.bufpos] == ':':
        tok.tokType = tkBracketLeColon
        inc(L.bufpos)
      else:
        tok.tokType = tkBracketLe
    of ']':
      tok.tokType = tkBracketRi
      inc(L.bufpos)
    of '.':
      when defined(nimsuggest):
        if L.fileIdx == L.config.m.trackPos.fileIndex and tok.col+1 == L.config.m.trackPos.col and
            tok.line == L.config.m.trackPos.line.int and L.config.ideCmd == ideSug:
          tok.tokType = tkDot
          L.cursor = CursorPosition.InToken
          L.config.m.trackPos.col = tok.col.int16
          inc(L.bufpos)
          atTokenEnd()
          return
      if L.buf[L.bufpos+1] == ']':
        tok.tokType = tkBracketDotRi
        inc(L.bufpos, 2)
      elif L.buf[L.bufpos+1] == '}':
        tok.tokType = tkCurlyDotRi
        inc(L.bufpos, 2)
      elif L.buf[L.bufpos+1] == ')':
        tok.tokType = tkParDotRi
        inc(L.bufpos, 2)
      else:
        getOperator(L, tok)
    of '{':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.' and L.buf[L.bufpos+1] != '.':
        tok.tokType = tkCurlyDotLe
        inc(L.bufpos)
      else:
        tok.tokType = tkCurlyLe
    of '}':
      tok.tokType = tkCurlyRi
      inc(L.bufpos)
    of ';':
      tok.tokType = tkSemiColon
      inc(L.bufpos)
    of '`':
      tok.tokType = tkAccent
      inc(L.bufpos)
    of '_':
      inc(L.bufpos)
      if L.buf[L.bufpos] notin SymChars+{'_'}:
        tok.tokType = tkSymbol
        tok.ident = L.cache.getIdent("_")
      else:
        tok.literal = $c
        tok.tokType = tkInvalid
        lexMessage(L, errGenerated, "invalid token: " & c & " (\\" & $(ord(c)) & ')')
    of '\"':
      # check for generalized raw string literal:
      let mode = if L.bufpos > 0 and L.buf[L.bufpos-1] in SymChars: generalized else: normal
      getString(L, tok, mode)
      if mode == generalized:
        # tkRStrLit -> tkGStrLit
        # tkTripleStrLit -> tkGTripleStrLit
        inc(tok.tokType, 2)
    of '\'':
      tok.tokType = tkCharLit
      getCharacter(L, tok)
      tok.tokType = tkCharLit
    of '0'..'9':
      getNumber(L, tok)
      let c = L.buf[L.bufpos]
      if c in SymChars+{'_'}:
        lexMessage(L, errGenerated, "invalid token: no whitespace between number and identifier")
    else:
      if c in OpChars:
        getOperator(L, tok)
      elif c == nimlexbase.EndOfFile:
        tok.tokType = tkEof
        tok.indent = 0
      else:
        tok.literal = $c
        tok.tokType = tkInvalid
        lexMessage(L, errGenerated, "invalid token: " & c & " (\\" & $(ord(c)) & ')')
        inc(L.bufpos)
  atTokenEnd()

proc getIndentWidth*(fileIdx: FileIndex, inputstream: PLLStream;
                     cache: IdentCache; config: ConfigRef): int =
  var lex: TLexer
  var tok: TToken
  initToken(tok)
  openLexer(lex, fileIdx, inputstream, cache, config)
  while true:
    rawGetTok(lex, tok)
    result = tok.indent
    if result > 0 or tok.tokType == tkEof: break
  closeLexer(lex)

proc getPrecedence*(ident: PIdent): int =
  ## assumes ident is binary operator already
  var tok: TToken
  initToken(tok)
  tok.ident = ident
  tok.tokType =
    if tok.ident.id in ord(tokKeywordLow) - ord(tkSymbol) .. ord(tokKeywordHigh) - ord(tkSymbol):
      TTokType(tok.ident.id + ord(tkSymbol))
    else: tkOpr
  getPrecedence(tok, false)
