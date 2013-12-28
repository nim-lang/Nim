#
#
#      Pas2nim - Pascal to Nimrod source converter
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a FreePascal scanner. This is an adaption from
# the scanner module.

import
  hashes, options, msgs, strutils, platform, idents, nimlexbase, llstream

const
  MaxLineLength* = 80         # lines longer than this lead to a warning
  numChars*: TCharSet = {'0'..'9', 'a'..'z', 'A'..'Z'}
  SymChars*: TCharSet = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}
  SymStartChars*: TCharSet = {'a'..'z', 'A'..'Z', '\x80'..'\xFF'}
  OpChars*: TCharSet = {'+', '-', '*', '/', '<', '>', '!', '?', '^', '.', '|',
    '=', ':', '%', '&', '$', '@', '~', '\x80'..'\xFF'}

# keywords are sorted!

type
  TTokKind* = enum
    pxInvalid, pxEof,
    pxAnd, pxArray, pxAs, pxAsm, pxBegin, pxCase, pxClass, pxConst,
    pxConstructor, pxDestructor, pxDiv, pxDo, pxDownto, pxElse, pxEnd, pxExcept,
    pxExports, pxFinalization, pxFinally, pxFor, pxFunction, pxGoto, pxIf,
    pxImplementation, pxIn, pxInherited, pxInitialization, pxInline,
    pxInterface, pxIs, pxLabel, pxLibrary, pxMod, pxNil, pxNot, pxObject, pxOf,
    pxOr, pxOut, pxPacked, pxProcedure, pxProgram, pxProperty, pxRaise,
    pxRecord, pxRepeat, pxResourcestring, pxSet, pxShl, pxShr, pxThen,
    pxThreadvar, pxTo, pxTry, pxType, pxUnit, pxUntil, pxUses, pxVar, pxWhile,
    pxWith, pxXor,
    pxComment,                # ordinary comment
    pxCommand,                # {@}
    pxAmp,                    # {&}
    pxPer,                    # {%}
    pxStrLit, pxSymbol,       # a symbol
    pxIntLit, pxInt64Lit, # long constant like 0x70fffffff or out of int range
    pxFloatLit, pxParLe, pxParRi, pxBracketLe, pxBracketRi, pxComma,
    pxSemiColon, pxColon,     # operators
    pxAsgn, pxEquals, pxDot, pxDotDot, pxHat, pxPlus, pxMinus, pxStar, pxSlash,
    pxLe, pxLt, pxGe, pxGt, pxNeq, pxAt, pxStarDirLe, pxStarDirRi, pxCurlyDirLe,
    pxCurlyDirRi
  TTokKinds* = set[TTokKind]

const
  Keywords = ["and", "array", "as", "asm", "begin", "case", "class", "const",
    "constructor", "destructor", "div", "do", "downto", "else", "end", "except",
    "exports", "finalization", "finally", "for", "function", "goto", "if",
    "implementation", "in", "inherited", "initialization", "inline",
    "interface", "is", "label", "library", "mod", "nil", "not", "object", "of",
    "or", "out", "packed", "procedure", "program", "property", "raise",
    "record", "repeat", "resourcestring", "set", "shl", "shr", "then",
    "threadvar", "to", "try", "type", "unit", "until", "uses", "var", "while",
    "with", "xor"]

  firstKeyword = pxAnd
  lastKeyword = pxXor

type
  TNumericalBase* = enum base10, base2, base8, base16
  TToken* = object
    xkind*: TTokKind          # the type of the token
    ident*: PIdent            # the parsed identifier
    iNumber*: BiggestInt      # the parsed integer literal
    fNumber*: BiggestFloat    # the parsed floating point literal
    base*: TNumericalBase     # the numerical base; only valid for int
                              # or float literals
    literal*: string          # the parsed (string) literal

  TLexer* = object of TBaseLexer
    filename*: string


proc getTok*(L: var TLexer, tok: var TToken)
proc printTok*(tok: TToken)
proc `$`*(tok: TToken): string
# implementation

var
  dummyIdent: PIdent
  gLinesCompiled: int

proc fillToken(L: var TToken) =
  L.xkind = pxInvalid
  L.iNumber = 0
  L.literal = ""
  L.fNumber = 0.0
  L.base = base10
  L.ident = dummyIdent        # this prevents many bugs!

proc openLexer*(lex: var TLexer, filename: string, inputstream: PLLStream) =
  openBaseLexer(lex, inputstream)
  lex.filename = filename

proc closeLexer*(lex: var TLexer) =
  inc(gLinesCompiled, lex.LineNumber)
  closeBaseLexer(lex)

proc getColumn(L: TLexer): int =
  result = getColNumber(L, L.bufPos)

proc getLineInfo*(L: TLexer): TLineInfo =
  result = newLineInfo(L.filename, L.linenumber, getColNumber(L, L.bufpos))

proc lexMessage*(L: TLexer, msg: TMsgKind, arg = "") =
  msgs.globalError(getLineInfo(L), msg, arg)

proc lexMessagePos(L: var TLexer, msg: TMsgKind, pos: int, arg = "") =
  var info = newLineInfo(L.filename, L.linenumber, pos - L.lineStart)
  msgs.globalError(info, msg, arg)

proc tokKindToStr*(k: TTokKind): string =
  case k
  of pxEof: result = "[EOF]"
  of firstKeyword..lastKeyword:
    result = Keywords[ord(k)-ord(firstKeyword)]
  of pxInvalid, pxComment, pxStrLit: result = "string literal"
  of pxCommand: result = "{@"
  of pxAmp: result = "{&"
  of pxPer: result = "{%"
  of pxSymbol: result = "identifier"
  of pxIntLit, pxInt64Lit: result = "integer literal"
  of pxFloatLit: result = "floating point literal"
  of pxParLe: result = "("
  of pxParRi: result = ")"
  of pxBracketLe: result = "["
  of pxBracketRi: result = "]"
  of pxComma: result = ","
  of pxSemiColon: result = ";"
  of pxColon: result = ":"
  of pxAsgn: result = ":="
  of pxEquals: result = "="
  of pxDot: result = "."
  of pxDotDot: result = ".."
  of pxHat: result = "^"
  of pxPlus: result = "+"
  of pxMinus: result = "-"
  of pxStar: result = "*"
  of pxSlash: result = "/"
  of pxLe: result = "<="
  of pxLt: result = "<"
  of pxGe: result = ">="
  of pxGt: result = ">"
  of pxNeq: result = "<>"
  of pxAt: result = "@"
  of pxStarDirLe: result = "(*$"
  of pxStarDirRi: result = "*)"
  of pxCurlyDirLe: result = "{$"
  of pxCurlyDirRi: result = "}"

proc `$`(tok: TToken): string =
  case tok.xkind
  of pxInvalid, pxComment, pxStrLit: result = tok.literal
  of pxSymbol: result = tok.ident.s
  of pxIntLit, pxInt64Lit: result = $tok.iNumber
  of pxFloatLit: result = $tok.fNumber
  else: result = tokKindToStr(tok.xkind)

proc printTok(tok: TToken) =
  writeln(stdout, $tok)

proc setKeyword(L: var TLexer, tok: var TToken) =
  var x = binaryStrSearch(keywords, toLower(tok.ident.s))
  if x < 0: tok.xkind = pxSymbol
  else: tok.xKind = TTokKind(x + ord(firstKeyword))

proc matchUnderscoreChars(L: var TLexer, tok: var TToken, chars: TCharSet) =
  # matches ([chars]_)*
  var pos = L.bufpos              # use registers for pos, buf
  var buf = L.buf
  while true:
    if buf[pos] in chars:
      add(tok.literal, buf[pos])
      inc(pos)
    else:
      break
    if buf[pos] == '_':
      add(tok.literal, '_')
      inc(pos)
  L.bufPos = pos

proc isFloatLiteral(s: string): bool =
  for i in countup(0, len(s)-1):
    if s[i] in {'.', 'e', 'E'}:
      return true

proc getNumber2(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos + 1 # skip %
  if not (L.buf[pos] in {'0'..'1'}):
    # BUGFIX for %date%
    tok.xkind = pxInvalid
    add(tok.literal, '%')
    inc(L.bufpos)
    return
  tok.base = base2
  var xi: BiggestInt = 0
  var bits = 0
  while true:
    case L.buf[pos]
    of 'A'..'Z', 'a'..'z', '2'..'9', '.':
      lexMessage(L, errInvalidNumber)
      inc(pos)
    of '_':
      inc(pos)
    of '0', '1':
      xi = `shl`(xi, 1) or (ord(L.buf[pos]) - ord('0'))
      inc(pos)
      inc(bits)
    else: break
  tok.iNumber = xi
  if (bits > 32): tok.xkind = pxInt64Lit
  else: tok.xkind = pxIntLit
  L.bufpos = pos

proc getNumber16(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos + 1          # skip $
  tok.base = base16
  var xi: BiggestInt = 0
  var bits = 0
  while true:
    case L.buf[pos]
    of 'G'..'Z', 'g'..'z', '.':
      lexMessage(L, errInvalidNumber)
      inc(pos)
    of '_': inc(pos)
    of '0'..'9':
      xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('0'))
      inc(pos)
      inc(bits, 4)
    of 'a'..'f':
      xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('a') + 10)
      inc(pos)
      inc(bits, 4)
    of 'A'..'F':
      xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('A') + 10)
      inc(pos)
      inc(bits, 4)
    else: break
  tok.iNumber = xi
  if (bits > 32):
    tok.xkind = pxInt64Lit
  else:
    tok.xkind = pxIntLit
  L.bufpos = pos

proc getNumber10(L: var TLexer, tok: var TToken) =
  tok.base = base10
  matchUnderscoreChars(L, tok, {'0'..'9'})
  if (L.buf[L.bufpos] == '.') and (L.buf[L.bufpos + 1] in {'0'..'9'}):
    add(tok.literal, '.')
    inc(L.bufpos)
    matchUnderscoreChars(L, tok, {'e', 'E', '+', '-', '0'..'9'})
  try:
    if isFloatLiteral(tok.literal):
      tok.fnumber = parseFloat(tok.literal)
      tok.xkind = pxFloatLit
    else:
      tok.iNumber = parseInt(tok.literal)
      if (tok.iNumber < low(int32)) or (tok.iNumber > high(int32)):
        tok.xkind = pxInt64Lit
      else:
        tok.xkind = pxIntLit
  except EInvalidValue:
    lexMessage(L, errInvalidNumber, tok.literal)
  except EOverflow:
    lexMessage(L, errNumberOutOfRange, tok.literal)

proc handleCRLF(L: var TLexer, pos: int): int =
  case L.buf[pos]
  of CR: result = nimlexbase.handleCR(L, pos)
  of LF: result = nimlexbase.handleLF(L, pos)
  else: result = pos

proc getString(L: var TLexer, tok: var TToken) =
  var xi: int
  var pos = L.bufPos
  var buf = L.buf
  while true:
    if buf[pos] == '\'':
      inc(pos)
      while true:
        case buf[pos]
        of CR, LF, nimlexbase.EndOfFile:
          lexMessage(L, errClosingQuoteExpected)
          break
        of '\'':
          inc(pos)
          if buf[pos] == '\'':
            inc(pos)
            add(tok.literal, '\'')
          else:
            break
        else:
          add(tok.literal, buf[pos])
          inc(pos)
    elif buf[pos] == '#':
      inc(pos)
      xi = 0
      case buf[pos]
      of '$':
        inc(pos)
        xi = 0
        while true:
          case buf[pos]
          of '0'..'9': xi = (xi shl 4) or (ord(buf[pos]) - ord('0'))
          of 'a'..'f': xi = (xi shl 4) or (ord(buf[pos]) - ord('a') + 10)
          of 'A'..'F': xi = (xi shl 4) or (ord(buf[pos]) - ord('A') + 10)
          else: break
          inc(pos)
      of '0'..'9':
        xi = 0
        while buf[pos] in {'0'..'9'}:
          xi = (xi * 10) + (ord(buf[pos]) - ord('0'))
          inc(pos)
      else: lexMessage(L, errInvalidCharacterConstant)
      if (xi <= 255): add(tok.literal, chr(xi))
      else: lexMessage(L, errInvalidCharacterConstant)
    else:
      break
  tok.xkind = pxStrLit
  L.bufpos = pos

proc getSymbol(L: var TLexer, tok: var TToken) =
  var h: THash = 0
  var pos = L.bufpos
  var buf = L.buf
  while true:
    var c = buf[pos]
    case c
    of 'a'..'z', '0'..'9', '\x80'..'\xFF':
      h = h +% ord(c)
      h = h +% h shl 10
      h = h xor (h shr 6)
    of 'A'..'Z':
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h +% ord(c)
      h = h +% h shl 10
      h = h xor (h shr 6)
    of '_': nil
    else: break
    inc(pos)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  tok.ident = getIdent(addr(L.buf[L.bufpos]), pos - L.bufpos, h)
  L.bufpos = pos
  setKeyword(L, tok)

proc scanLineComment(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  # a comment ends if the next line does not start with the // on the same
  # column after only whitespace
  tok.xkind = pxComment
  var col = getColNumber(L, pos)
  while true:
    inc(pos, 2)               # skip //
    add(tok.literal, '#')
    while not (buf[pos] in {CR, LF, nimlexbase.EndOfFile}):
      add(tok.literal, buf[pos])
      inc(pos)
    pos = handleCRLF(L, pos)
    buf = L.buf
    var indent = 0
    while buf[pos] == ' ':
      inc(pos)
      inc(indent)
    if (col == indent) and (buf[pos] == '/') and (buf[pos + 1] == '/'):
      tok.literal = tok.literal & "\n"
    else:
      break
  L.bufpos = pos

proc scanCurlyComment(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tok.literal = "#"
  tok.xkind = pxComment
  while true:
    case buf[pos]
    of CR, LF:
      pos = handleCRLF(L, pos)
      buf = L.buf
      add(tok.literal, "\n#")
    of '}':
      inc(pos)
      break
    of nimlexbase.EndOfFile: lexMessage(L, errTokenExpected, "}")
    else:
      add(tok.literal, buf[pos])
      inc(pos)
  L.bufpos = pos

proc scanStarComment(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  tok.literal = "#"
  tok.xkind = pxComment
  while true:
    case buf[pos]
    of CR, LF:
      pos = handleCRLF(L, pos)
      buf = L.buf
      add(tok.literal, "\n#")
    of '*':
      inc(pos)
      if buf[pos] == ')':
        inc(pos)
        break
      else:
        add(tok.literal, '*')
    of nimlexbase.EndOfFile:
      lexMessage(L, errTokenExpected, "*)")
    else:
      add(tok.literal, buf[pos])
      inc(pos)
  L.bufpos = pos

proc skip(L: var TLexer, tok: var TToken) =
  var pos = L.bufpos
  var buf = L.buf
  while true:
    case buf[pos]
    of ' ', Tabulator:
      inc(pos)                # newline is special:
    of CR, LF:
      pos = handleCRLF(L, pos)
      buf = L.buf
    else:
      break                   # EndOfFile also leaves the loop
  L.bufpos = pos

proc getTok(L: var TLexer, tok: var TToken) =
  tok.xkind = pxInvalid
  fillToken(tok)
  skip(L, tok)
  var c = L.buf[L.bufpos]
  if c in SymStartChars:
    getSymbol(L, tok)
  elif c in {'0'..'9'}:
    getNumber10(L, tok)
  else:
    case c
    of ';':
      tok.xkind = pxSemicolon
      inc(L.bufpos)
    of '/':
      if L.buf[L.bufpos + 1] == '/':
        scanLineComment(L, tok)
      else:
        tok.xkind = pxSlash
        inc(L.bufpos)
    of ',':
      tok.xkind = pxComma
      inc(L.bufpos)
    of '(':
      inc(L.bufpos)
      if (L.buf[L.bufPos] == '*'):
        if (L.buf[L.bufPos + 1] == '$'):
          inc(L.bufpos, 2)
          skip(L, tok)
          getSymbol(L, tok)
          tok.xkind = pxStarDirLe
        else:
          inc(L.bufpos)
          scanStarComment(L, tok)
      else:
        tok.xkind = pxParLe
    of '*':
      inc(L.bufpos)
      if L.buf[L.bufpos] == ')':
        inc(L.bufpos)
        tok.xkind = pxStarDirRi
      else:
        tok.xkind = pxStar
    of ')':
      tok.xkind = pxParRi
      inc(L.bufpos)
    of '[':
      inc(L.bufpos)
      tok.xkind = pxBracketLe
    of ']':
      inc(L.bufpos)
      tok.xkind = pxBracketRi
    of '.':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.':
        tok.xkind = pxDotDot
        inc(L.bufpos)
      else:
        tok.xkind = pxDot
    of '{':
      inc(L.bufpos)
      case L.buf[L.bufpos]
      of '$':
        inc(L.bufpos)
        skip(L, tok)
        getSymbol(L, tok)
        tok.xkind = pxCurlyDirLe
      of '&':
        inc(L.bufpos)
        tok.xkind = pxAmp
      of '%':
        inc(L.bufpos)
        tok.xkind = pxPer
      of '@':
        inc(L.bufpos)
        tok.xkind = pxCommand
      else: scanCurlyComment(L, tok)
    of '+':
      tok.xkind = pxPlus
      inc(L.bufpos)
    of '-':
      tok.xkind = pxMinus
      inc(L.bufpos)
    of ':':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        inc(L.bufpos)
        tok.xkind = pxAsgn
      else:
        tok.xkind = pxColon
    of '<':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '>':
        inc(L.bufpos)
        tok.xkind = pxNeq
      elif L.buf[L.bufpos] == '=':
        inc(L.bufpos)
        tok.xkind = pxLe
      else:
        tok.xkind = pxLt
    of '>':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        inc(L.bufpos)
        tok.xkind = pxGe
      else:
        tok.xkind = pxGt
    of '=':
      tok.xkind = pxEquals
      inc(L.bufpos)
    of '@':
      tok.xkind = pxAt
      inc(L.bufpos)
    of '^':
      tok.xkind = pxHat
      inc(L.bufpos)
    of '}':
      tok.xkind = pxCurlyDirRi
      inc(L.bufpos)
    of '\'', '#':
      getString(L, tok)
    of '$':
      getNumber16(L, tok)
    of '%':
      getNumber2(L, tok)
    of nimlexbase.EndOfFile:
      tok.xkind = pxEof
    else:
      tok.literal = c & ""
      tok.xkind = pxInvalid
      lexMessage(L, errInvalidToken, c & " (\\" & $(ord(c)) & ')')
      inc(L.bufpos)
