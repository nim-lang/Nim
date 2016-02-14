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
  wordrecg, etcpriv

const
  MaxLineLength* = 80         # lines longer than this lead to a warning
  numChars*: set[char] = {'0'..'9', 'a'..'z', 'A'..'Z'}
  SymChars*: set[char] = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}
  SymStartChars*: set[char] = {'a'..'z', 'A'..'Z', '\x80'..'\xFF'}
  OpChars*: set[char] = {'+', '-', '*', '/', '\\', '<', '>', '!', '?', '^', '.',
    '|', '=', '%', '&', '$', '@', '~', ':', '\x80'..'\xFF'}

# don't forget to update the 'highlite' module if these charsets should change

type
  TTokType* = enum
    tkInvalid, tkEof,         # order is important here!
    tkSymbol, # keywords:
    tkAddr, tkAnd, tkAs, tkAsm, tkAtomic,
    tkBind, tkBlock, tkBreak, tkCase, tkCast,
    tkConcept, tkConst, tkContinue, tkConverter,
    tkDefer, tkDiscard, tkDistinct, tkDiv, tkDo,
    tkElif, tkElse, tkEnd, tkEnum, tkExcept, tkExport,
    tkFinally, tkFor, tkFrom, tkFunc,
    tkGeneric, tkIf, tkImport, tkIn, tkInclude, tkInterface,
    tkIs, tkIsnot, tkIterator,
    tkLet,
    tkMacro, tkMethod, tkMixin, tkMod, tkNil, tkNot, tkNotin,
    tkObject, tkOf, tkOr, tkOut,
    tkProc, tkPtr, tkRaise, tkRef, tkReturn, tkShl, tkShr, tkStatic,
    tkTemplate,
    tkTry, tkTuple, tkType, tkUsing,
    tkVar, tkWhen, tkWhile, tkWith, tkWithout, tkXor,
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
    tkColon, tkColonColon, tkEquals, tkDot, tkDotDot,
    tkOpr, tkComment, tkAccent,
    tkSpaces, tkInfixOpr, tkPrefixOpr, tkPostfixOpr

  TTokTypes* = set[TTokType]

const
  tokKeywordLow* = succ(tkSymbol)
  tokKeywordHigh* = pred(tkIntLit)
  TokTypeToStr*: array[TTokType, string] = ["tkInvalid", "[EOF]",
    "tkSymbol",
    "addr", "and", "as", "asm", "atomic",
    "bind", "block", "break", "case", "cast",
    "concept", "const", "continue", "converter",
    "defer", "discard", "distinct", "div", "do",
    "elif", "else", "end", "enum", "except", "export",
    "finally", "for", "from", "func", "generic", "if",
    "import", "in", "include", "interface", "is", "isnot", "iterator",
    "let",
    "macro", "method", "mixin", "mod",
    "nil", "not", "notin", "object", "of", "or",
    "out", "proc", "ptr", "raise", "ref", "return",
    "shl", "shr", "static",
    "template",
    "try", "tuple", "type", "using",
    "var", "when", "while", "with", "without", "xor",
    "yield",
    "tkIntLit", "tkInt8Lit", "tkInt16Lit", "tkInt32Lit", "tkInt64Lit",
    "tkUIntLit", "tkUInt8Lit", "tkUInt16Lit", "tkUInt32Lit", "tkUInt64Lit",
    "tkFloatLit", "tkFloat32Lit", "tkFloat64Lit", "tkFloat128Lit",
    "tkStrLit", "tkRStrLit",
    "tkTripleStrLit", "tkGStrLit", "tkGTripleStrLit", "tkCharLit", "(",
    ")", "[", "]", "{", "}", "[.", ".]", "{.", ".}", "(.", ".)",
    ",", ";",
    ":", "::", "=", ".", "..",
    "tkOpr", "tkComment", "`",
    "tkSpaces", "tkInfixOpr",
    "tkPrefixOpr", "tkPostfixOpr"]

type
  TNumericalBase* = enum
    base10,                   # base10 is listed as the first element,
                              # so that it is the correct default value
    base2, base8, base16

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

  TErrorHandler* = proc (info: TLineInfo; msg: TMsgKind; arg: string)
  TLexer* = object of TBaseLexer
    fileIdx*: int32
    indentAhead*: int         # if > 0 an indendation has already been read
                              # this is needed because scanning comments
                              # needs so much look-ahead
    currLineIndent*: int
    strongSpaces*: bool
    errorHandler*: TErrorHandler

var gLinesCompiled*: int  # all lines that have been compiled

proc getLineInfo*(L: TLexer, tok: TToken): TLineInfo {.inline.} =
  newLineInfo(L.fileIdx, tok.line, tok.col)

proc isKeyword*(kind: TTokType): bool =
  result = (kind >= tokKeywordLow) and (kind <= tokKeywordHigh)

proc isNimIdentifier*(s: string): bool =
  if s[0] in SymStartChars:
    var i = 1
    var sLen = s.len
    while i < sLen:
      if s[i] == '_':
        inc(i)
      elif isMagicIdentSeparatorRune(cstring s, i):
        inc(i, magicIdentSeparatorRuneByteWidth)
      if s[i] notin SymChars: return
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
      internalError("tokToStr")
      result = ""

proc prettyTok*(tok: TToken): string =
  if isKeyword(tok.tokType): result = "keyword " & tok.ident.s
  else: result = tokToStr(tok)

proc printTok*(tok: TToken) =
  msgWriteln($tok.line & ":" & $tok.col & "\t" &
      TokTypeToStr[tok.tokType] & " " & tokToStr(tok))

var dummyIdent: PIdent

proc initToken*(L: var TToken) =
  L.tokType = tkInvalid
  L.iNumber = 0
  L.indent = 0
  L.strongSpaceA = 0
  L.literal = ""
  L.fNumber = 0.0
  L.base = base10
  L.ident = dummyIdent

proc fillToken(L: var TToken) =
  L.tokType = tkInvalid
  L.iNumber = 0
  L.indent = 0
  L.strongSpaceA = 0
  setLen(L.literal, 0)
  L.fNumber = 0.0
  L.base = base10
  L.ident = dummyIdent

proc openLexer*(lex: var TLexer, fileIdx: int32, inputstream: PLLStream) =
  openBaseLexer(lex, inputstream)
  lex.fileIdx = fileidx
  lex.indentAhead = - 1
  lex.currLineIndent = 0
  inc(lex.lineNumber, inputstream.lineOffset)

proc openLexer*(lex: var TLexer, filename: string, inputstream: PLLStream) =
  openLexer(lex, filename.fileInfoIdx, inputstream)

proc closeLexer*(lex: var TLexer) =
  inc(gLinesCompiled, lex.lineNumber)
  closeBaseLexer(lex)

proc getColumn(L: TLexer): int =
  result = getColNumber(L, L.bufpos)

proc getLineInfo(L: TLexer): TLineInfo =
  result = newLineInfo(L.fileIdx, L.lineNumber, getColNumber(L, L.bufpos))

proc dispMessage(L: TLexer; info: TLineInfo; msg: TMsgKind; arg: string) =
  if L.errorHandler.isNil:
    msgs.message(info, msg, arg)
  else:
    L.errorHandler(info, msg, arg)

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

proc isFloatLiteral(s: string): bool =
  for i in countup(0, len(s) - 1):
    if s[i] in {'.', 'e', 'E'}:
      return true
  result = false

{.push overflowChecks: off.}
# We need to parse the largest uint literal without overflow checks
proc unsafeParseUInt(s: string, b: var BiggestInt, start = 0): int =
  var i = start
  if s[i] in {'0'..'9'}:
    b = 0
    while s[i] in {'0'..'9'}:
      b = b * 10 + (ord(s[i]) - ord('0'))
      inc(i)
      while s[i] == '_': inc(i) # underscores are allowed and ignored
    result = i - start
{.pop.} # overflowChecks


template eatChar(L: var TLexer, t: var TToken, replacementChar: char) =
  add(t.literal, replacementChar)
  inc(L.bufpos)

template eatChar(L: var TLexer, t: var TToken) =
  add(t.literal, L.buf[L.bufpos])
  inc(L.bufpos)

proc getNumber(L: var TLexer): TToken =
  proc matchUnderscoreChars(L: var TLexer, tok: var TToken, chars: set[char]) =
    var pos = L.bufpos              # use registers for pos, buf
    var buf = L.buf
    while true:
      if buf[pos] in chars:
        add(tok.literal, buf[pos])
        inc(pos)
      else:
        break
      if buf[pos] == '_':
        if buf[pos+1] notin chars:
          lexMessage(L, errInvalidToken, "_")
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

  proc lexMessageLitNum(L: var TLexer, msg: TMsgKind, startpos: int) =
    # Used to get slightly human friendlier err messages.
    # Note: the erroneous 'O' char in the character set is intentional
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
    lexMessage(L, msg, t.literal)

  var
    startpos, endpos: int
    xi: BiggestInt
    isBase10 = true
  const
    baseCodeChars = {'X', 'x', 'o', 'c', 'C', 'b', 'B'}
    literalishChars = baseCodeChars + {'A'..'F', 'a'..'f', '0'..'9', '_', '\''}
    floatTypes = {tkFloatLit, tkFloat32Lit, tkFloat64Lit, tkFloat128Lit}
  result.tokType = tkIntLit   # int literal until we know better
  result.literal = ""
  result.base = base10
  startpos = L.bufpos

  # First stage: find out base, make verifications, build token literal string
  if L.buf[L.bufpos] == '0' and L.buf[L.bufpos + 1] in baseCodeChars + {'O'}:
    isBase10 = false
    eatChar(L, result, '0')
    case L.buf[L.bufpos]
    of 'O':
      lexMessageLitNum(L, errInvalidNumberOctalCode, startpos)
    of 'x', 'X':
      eatChar(L, result, 'x')
      matchUnderscoreChars(L, result, {'0'..'9', 'a'..'f', 'A'..'F'})
    of 'o', 'c', 'C':
      eatChar(L, result, 'c')
      matchUnderscoreChars(L, result, {'0'..'7'})
    of 'b', 'B':
      eatChar(L, result, 'b')
      matchUnderscoreChars(L, result, {'0'..'1'})
    else:
      internalError(getLineInfo(L), "getNumber")
  else:
    matchUnderscoreChars(L, result, {'0'..'9'})
    if (L.buf[L.bufpos] == '.') and (L.buf[L.bufpos + 1] in {'0'..'9'}):
      result.tokType = tkFloat64Lit
      eatChar(L, result, '.')
      matchUnderscoreChars(L, result, {'0'..'9'})
    if L.buf[L.bufpos] in {'e', 'E'}:
      result.tokType = tkFloat64Lit
      eatChar(L, result, 'e')
      if L.buf[L.bufpos] in {'+', '-'}:
        eatChar(L, result)
      matchUnderscoreChars(L, result, {'0'..'9'})
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
        lexMessageLitNum(L, errInvalidNumber, startpos)
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
      lexMessageLitNum(L, errInvalidNumber, startpos)

  # Is there still a literalish char awaiting? Then it's an error!
  if  L.buf[postPos] in literalishChars or
     (L.buf[postPos] == '.' and L.buf[postPos + 1] in {'0'..'9'}):
    lexMessageLitNum(L, errInvalidNumber, startpos)

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
        internalError(getLineInfo(L), "getNumber")

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
      of tkFloat64Lit: result.fNumber = (cast[PFloat64](addr(xi)))[]
      else: internalError(getLineInfo(L), "getNumber")

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
          lexMessageLitNum(L, errNumberOutOfRange, startpos)

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
      let outOfRange = case result.tokType:
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

      if outOfRange: lexMessageLitNum(L, errNumberOutOfRange, startpos)

    # Promote int literal to int64? Not always necessary, but more consistent
    if result.tokType == tkIntLit:
      if (result.iNumber < low(int32)) or (result.iNumber > high(int32)):
        result.tokType = tkInt64Lit

  except ValueError:
    lexMessageLitNum(L, errInvalidNumber, startpos)
  except OverflowError, RangeError:
    lexMessageLitNum(L, errNumberOutOfRange, startpos)
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
  else: discard

proc handleDecChars(L: var TLexer, xi: var int) =
  while L.buf[L.bufpos] in {'0'..'9'}:
    xi = (xi * 10) + (ord(L.buf[L.bufpos]) - ord('0'))
    inc(L.bufpos)

proc getEscapedChar(L: var TLexer, tok: var TToken) =
  inc(L.bufpos)               # skip '\'
  case L.buf[L.bufpos]
  of 'n', 'N':
    if tok.tokType == tkCharLit: lexMessage(L, errNnotAllowedInCharacter)
    add(tok.literal, tnl)
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
  of '0'..'9':
    if matchTwoChars(L, '0', {'0'..'9'}):
      lexMessage(L, warnOctalEscape)
    var xi = 0
    handleDecChars(L, xi)
    if (xi <= 255): add(tok.literal, chr(xi))
    else: lexMessage(L, errInvalidCharacterConstant)
  else: lexMessage(L, errInvalidCharacterConstant)

proc newString(s: cstring, len: int): string =
  ## XXX, how come there is no support for this?
  result = newString(len)
  for i in 0 .. <len:
    result[i] = s[i]

proc handleCRLF(L: var TLexer, pos: int): int =
  template registerLine =
    let col = L.getColNumber(pos)

    if col > MaxLineLength:
      lexMessagePos(L, hintLineTooLong, pos)

    if optEmbedOrigSrc in gGlobalOptions:
      let lineStart = cast[ByteAddress](L.buf) + L.lineStart
      let line = newString(cast[cstring](lineStart), col)
      addSourceLine(L.fileIdx, line)

  case L.buf[pos]
  of CR:
    registerLine()
    result = nimlexbase.handleCR(L, pos)
  of LF:
    registerLine()
    result = nimlexbase.handleLF(L, pos)
  else: result = pos

proc getString(L: var TLexer, tok: var TToken, rawMode: bool) =
  var pos = L.bufpos + 1          # skip "
  var buf = L.buf                 # put `buf` in a register
  var line = L.lineNumber         # save linenumber for better error message
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
          L.bufpos = pos + 3 # skip the three """
          break
        add(tok.literal, '\"')
        inc(pos)
      of CR, LF:
        pos = handleCRLF(L, pos)
        buf = L.buf
        add(tok.literal, tnl)
      of nimlexbase.EndOfFile:
        var line2 = L.lineNumber
        L.lineNumber = line
        lexMessagePos(L, errClosingTripleQuoteExpected, L.lineStart)
        L.lineNumber = line2
        L.bufpos = pos
        break
      else:
        add(tok.literal, buf[pos])
        inc(pos)
  else:
    # ordinary string literal
    if rawMode: tok.tokType = tkRStrLit
    else: tok.tokType = tkStrLit
    while true:
      var c = buf[pos]
      if c == '\"':
        if rawMode and buf[pos+1] == '\"':
          inc(pos, 2)
          add(tok.literal, '"')
        else:
          inc(pos) # skip '"'
          break
      elif c in {CR, LF, nimlexbase.EndOfFile}:
        lexMessage(L, errClosingQuoteExpected)
        break
      elif (c == '\\') and not rawMode:
        L.bufpos = pos
        getEscapedChar(L, tok)
        pos = L.bufpos
      else:
        add(tok.literal, c)
        inc(pos)
    L.bufpos = pos

proc getCharacter(L: var TLexer, tok: var TToken) =
  inc(L.bufpos)               # skip '
  var c = L.buf[L.bufpos]
  case c
  of '\0'..pred(' '), '\'': lexMessage(L, errInvalidCharacterConstant)
  of '\\': getEscapedChar(L, tok)
  else:
    tok.literal = $c
    inc(L.bufpos)
  if L.buf[L.bufpos] != '\'': lexMessage(L, errMissingFinalQuote)
  inc(L.bufpos)               # skip '

proc getSymbol(L: var TLexer, tok: var TToken) =
  var h: Hash = 0
  var pos = L.bufpos
  var buf = L.buf
  while true:
    var c = buf[pos]
    case c
    of 'a'..'z', '0'..'9', '\x80'..'\xFF':
      if  c == '\226' and
          buf[pos+1] == '\128' and
          buf[pos+2] == '\147':  # It's a 'magic separator' en-dash Unicode
        if buf[pos + magicIdentSeparatorRuneByteWidth] notin SymChars:
          lexMessage(L, errInvalidToken, "–")
          break
        inc(pos, magicIdentSeparatorRuneByteWidth)
      else:
        h = h !& ord(c)
        inc(pos)
    of 'A'..'Z':
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h !& ord(c)
      inc(pos)
    of '_':
      if buf[pos+1] notin SymChars:
        lexMessage(L, errInvalidToken, "_")
        break
      inc(pos)

    else: break
  h = !$h
  tok.ident = getIdent(addr(L.buf[L.bufpos]), pos - L.bufpos, h)
  L.bufpos = pos
  if (tok.ident.id < ord(tokKeywordLow) - ord(tkSymbol)) or
      (tok.ident.id > ord(tokKeywordHigh) - ord(tkSymbol)):
    tok.tokType = tkSymbol
  else:
    tok.tokType = TTokType(tok.ident.id + ord(tkSymbol))

proc endOperator(L: var TLexer, tok: var TToken, pos: int,
                 hash: Hash) {.inline.} =
  var h = !$hash
  tok.ident = getIdent(addr(L.buf[L.bufpos]), pos - L.bufpos, h)
  if (tok.ident.id < oprLow) or (tok.ident.id > oprHigh): tok.tokType = tkOpr
  else: tok.tokType = TTokType(tok.ident.id - oprLow + ord(tkColon))
  L.bufpos = pos

proc getOperator(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  var h: Hash = 0
  while true:
    var c = buf[pos]
    if c notin OpChars: break
    h = h !& ord(c)
    inc(pos)
  endOperator(L, tok, pos, h)
  # advance pos but don't store it in L.bufpos so the next token (which might
  # be an operator too) gets the preceding spaces:
  tok.strongSpaceB = 0
  while buf[pos] == ' ':
    inc pos
    inc tok.strongSpaceB
  if buf[pos] in {CR, LF, nimlexbase.EndOfFile}:
    tok.strongSpaceB = -1

proc skipMultiLineComment(L: var TLexer; tok: var TToken; start: int;
                          isDoc: bool) =
  var pos = start
  var buf = L.buf
  var toStrip = 0
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
            inc(pos, 3)
            break
          dec nesting
        tok.literal.add ']'
      elif buf[pos+1] == '#':
        if nesting == 0:
          inc(pos, 2)
          break
        dec nesting
      inc pos
    of '\t':
      lexMessagePos(L, errTabulatorsAreNotAllowed, pos)
      inc(pos)
      if isDoc: tok.literal.add '\t'
    of CR, LF:
      pos = handleCRLF(L, pos)
      buf = L.buf
      # strip leading whitespace:
      if isDoc:
        tok.literal.add "\n"
        inc tok.iNumber
        var c = toStrip
        while buf[pos] == ' ' and c > 0:
          inc pos
          dec c
    of nimlexbase.EndOfFile:
      lexMessagePos(L, errGenerated, pos, "end of multiline comment expected")
      break
    else:
      if isDoc: tok.literal.add buf[pos]
      inc(pos)
  L.bufpos = pos

proc scanComment(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tok.tokType = tkComment
  # iNumber contains the number of '\n' in the token
  tok.iNumber = 0
  when not defined(nimfix):
    assert buf[pos+1] == '#'
    if buf[pos+2] == '[':
      skipMultiLineComment(L, tok, pos+3, true)
      return
    inc(pos, 2)

  var toStrip = 0
  while buf[pos] == ' ':
    inc pos
    inc toStrip

  when defined(nimfix):
    var col = getColNumber(L, pos)
  while true:
    var lastBackslash = -1
    while buf[pos] notin {CR, LF, nimlexbase.EndOfFile}:
      if buf[pos] == '\\': lastBackslash = pos+1
      add(tok.literal, buf[pos])
      inc(pos)
    when defined(nimfix):
      if lastBackslash > 0:
        # a backslash is a continuation character if only followed by spaces
        # plus a newline:
        while buf[lastBackslash] == ' ': inc(lastBackslash)
        if buf[lastBackslash] notin {CR, LF, nimlexbase.EndOfFile}:
          # false positive:
          lastBackslash = -1

    pos = handleCRLF(L, pos)
    buf = L.buf
    var indent = 0
    while buf[pos] == ' ':
      inc(pos)
      inc(indent)

    when defined(nimfix):
      template doContinue(): expr =
        buf[pos] == '#' and (col == indent or lastBackslash > 0)
    else:
      template doContinue(): expr =
        buf[pos] == '#' and buf[pos+1] == '#'
    if doContinue():
      tok.literal.add "\n"
      when defined(nimfix): col = indent
      else:
        inc(pos, 2)
        var c = toStrip
        while buf[pos] == ' ' and c > 0:
          inc pos
          dec c
      inc tok.iNumber
    else:
      if buf[pos] > ' ':
        L.indentAhead = indent
      break
  L.bufpos = pos

proc skip(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tok.strongSpaceA = 0
  while true:
    case buf[pos]
    of ' ':
      inc(pos)
      inc(tok.strongSpaceA)
    of '\t':
      lexMessagePos(L, errTabulatorsAreNotAllowed, pos)
      inc(pos)
    of CR, LF:
      pos = handleCRLF(L, pos)
      buf = L.buf
      var indent = 0
      while true:
        if buf[pos] == ' ':
          inc(pos)
          inc(indent)
        elif buf[pos] == '#' and buf[pos+1] == '[':
          skipMultiLineComment(L, tok, pos+2, false)
          pos = L.bufpos
          buf = L.buf
        else:
          break
      tok.strongSpaceA = 0
      when defined(nimfix):
        template doBreak(): expr = buf[pos] > ' '
      else:
        template doBreak(): expr =
          buf[pos] > ' ' and (buf[pos] != '#' or buf[pos+1] == '#')
      if doBreak():
        tok.indent = indent
        L.currLineIndent = indent
        break
    of '#':
      when defined(nimfix):
        break
      else:
        # do not skip documentation comment:
        if buf[pos+1] == '#': break
        if buf[pos+1] == '[':
          skipMultiLineComment(L, tok, pos+2, false)
          pos = L.bufpos
          buf = L.buf
        else:
          while buf[pos] notin {CR, LF, nimlexbase.EndOfFile}: inc(pos)
    else:
      break                   # EndOfFile also leaves the loop
  L.bufpos = pos

proc rawGetTok*(L: var TLexer, tok: var TToken) =
  fillToken(tok)
  if L.indentAhead >= 0:
    tok.indent = L.indentAhead
    L.currLineIndent = L.indentAhead
    L.indentAhead = -1
  else:
    tok.indent = -1
  skip(L, tok)
  var c = L.buf[L.bufpos]
  tok.line = L.lineNumber
  tok.col = getColNumber(L, L.bufpos)
  if c in SymStartChars - {'r', 'R', 'l'}:
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
    of 'l':
      # if we parsed exactly one character and its a small L (l), this
      # is treated as a warning because it may be confused with the number 1
      if L.buf[L.bufpos+1] notin (SymChars + {'_'}):
        lexMessage(L, warnSmallLshouldNotBeUsed)
      getSymbol(L, tok)
    of 'r', 'R':
      if L.buf[L.bufpos + 1] == '\"':
        inc(L.bufpos)
        getString(L, tok, true)
      else:
        getSymbol(L, tok)
    of '(':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.' and L.buf[L.bufpos+1] != '.':
        tok.tokType = tkParDotLe
        inc(L.bufpos)
      else:
        tok.tokType = tkParLe
    of ')':
      tok.tokType = tkParRi
      inc(L.bufpos)
    of '[':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.' and L.buf[L.bufpos+1] != '.':
        tok.tokType = tkBracketDotLe
        inc(L.bufpos)
      else:
        tok.tokType = tkBracketLe
    of ']':
      tok.tokType = tkBracketRi
      inc(L.bufpos)
    of '.':
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
      if L.buf[L.bufpos] notin SymChars:
        tok.tokType = tkSymbol
        tok.ident = getIdent("_")
      else:
        tok.literal = $c
        tok.tokType = tkInvalid
        lexMessage(L, errInvalidToken, c & " (\\" & $(ord(c)) & ')')
    of '\"':
      # check for extended raw string literal:
      var rawMode = L.bufpos > 0 and L.buf[L.bufpos-1] in SymChars
      getString(L, tok, rawMode)
      if rawMode:
        # tkRStrLit -> tkGStrLit
        # tkTripleStrLit -> tkGTripleStrLit
        inc(tok.tokType, 2)
    of '\'':
      tok.tokType = tkCharLit
      getCharacter(L, tok)
      tok.tokType = tkCharLit
    of '0'..'9':
      tok = getNumber(L)
    else:
      if c in OpChars:
        getOperator(L, tok)
      elif c == nimlexbase.EndOfFile:
        tok.tokType = tkEof
        tok.indent = 0
      else:
        tok.literal = $c
        tok.tokType = tkInvalid
        lexMessage(L, errInvalidToken, c & " (\\" & $(ord(c)) & ')')
        inc(L.bufpos)

dummyIdent = getIdent("")
