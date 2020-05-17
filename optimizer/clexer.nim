#
#
#             C Optimizer
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a C scanner for our C optimizer.
## Keywords are not handled here, because there is no need.

import std / memfiles

import ".." / compiler / [options, llstream, msgs, lineinfos, pathutils]

const
  SymChars = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF'}
  SymStartChars = {'a'..'z', 'A'..'Z', '_', '\x80'..'\xFF'}

type
  TokenKind* = enum
    tkInvalid, tkEof,
    tkMacroParam,             # fake token: macro parameter (with its index)
    tkMacroParamToStr,        # macro parameter (with its index) applied to the
                              # toString operator (#) in a #define: #param
    tkStarComment,            # /* */ comment
    tkLineComment,            # // comment
    tkWhitespace,
    tkDirective,              # #define, etc.
    tkDirConc,                # ##
    tkNewLine,                # newline: end of directive
    tkAmp,                    # &
    tkAmpAmp,                 # &&
    tkAmpAsgn,                # &=
    tkAmpAmpAsgn,             # &&=
    tkBar,                    # |
    tkBarBar,                 # ||
    tkBarAsgn,                # |=
    tkBarBarAsgn,             # ||=
    tkNot,                    # !
    tkPlusPlus,               # ++
    tkMinusMinus,             # --
    tkPlus,                   # +
    tkPlusAsgn,               # +=
    tkMinus,                  # -
    tkMinusAsgn,              # -=
    tkMod,                    # %
    tkModAsgn,                # %=
    tkSlash,                  # /
    tkSlashAsgn,              # /=
    tkStar,                   # *
    tkStarAsgn,               # *=
    tkHat,                    # ^
    tkHatAsgn,                # ^=
    tkAsgn,                   # =
    tkEquals,                 # ==
    tkDot,                    # .
    tkDotDotDot,              # ...
    tkLe,                     # <=
    tkLt,                     # <
    tkGe,                     # >=
    tkGt,                     # >
    tkNeq,                    # !=
    tkConditional,            # ?
    tkShl,                    # <<
    tkShlAsgn,                # <<=
    tkShr,                    # >>
    tkShrAsgn,                # >>=
    tkTilde,                  # ~
    tkTildeAsgn,              # ~=
    tkArrow,                  # ->
    tkArrowStar,              # ->*
    tkScope,                  # ::

    tkLit,
    tkSymbol,                 # a symbol
    tkParLe, tkBracketLe, tkCurlyLe, # this order is important
    tkParRi, tkBracketRi, tkCurlyRi, # for macro argument parsing!
    tkComma, tkSemiColon, tkColon,
    tkAngleRi                # '>' but determined to be the end of a
                             # template's angle bracket

type
  Token* = object
    kind*: TokenKind          # the type of the token
    s*: string               # parsed symbol, integer, char or string literal

  Lexer* = object
    f: MemFile
    buf: cstring
    bufpos: int
    fileIdx*: FileIndex
    inDirective, debugMode*: bool
    config: ConfigRef

proc fillToken(L: var Token) =
  L.kind = tkInvalid
  L.s.setLen 0

proc openLexer*(lex: var Lexer, filename: AbsoluteFile, inputstream: PLLStream;
                config: ConfigRef) =
  #openBaseLexer(lex, inputstream, 2*1024*1024)
  lex.f = memfiles.open(filename.string)
  lex.fileIdx = fileInfoIdx(config, filename)
  lex.config = config
  lex.bufpos = 0
  lex.buf = cast[cstring](lex.f.mem)

proc closeLexer*(lex: var Lexer) =
  close lex.f
  #closeBaseLexer(lex)

template myadd(a, b): untyped =
  add(a, b)

when false:
  proc getColumn*(L: Lexer): int =
    result = getColNumber(L, L.bufPos)

  proc getLineInfo*(L: Lexer): TLineInfo =
    result = newLineInfo(L.fileIdx, L.linenumber, getColNumber(L, L.bufpos))

  proc lexMessage*(L: Lexer, msg: TMsgKind, arg = "") =
    if L.debugMode: writeStackTrace()
    msgs.globalError(L.config, getLineInfo(L), msg, arg)

  proc lexMessagePos(L: var Lexer, msg: TMsgKind, pos: int, arg = "") =
    var info = newLineInfo(L.fileIdx, L.linenumber, pos - L.lineStart)
    if L.debugMode: writeStackTrace()
    msgs.globalError(L.config, info, msg, arg)

proc tokKindToStr*(k: TokenKind): string =
  case k
  of tkEof: result = "[EOF]"
  of tkInvalid: result = "[invalid]"
  of tkMacroParam, tkMacroParamToStr: result = "[macro param]"
  of tkStarComment, tkLineComment: result = "[comment]"
  of tkLit: result = "[literal]"
  of tkWhitespace: result = "[whitespace]"

  of tkDirective: result = "#"             # #define, etc.
  of tkDirConc: result = "##"
  of tkNewLine: result = "[NewLine]"
  of tkAmp: result = "&"                   # &
  of tkAmpAmp: result = "&&"               # &&
  of tkAmpAsgn: result = "&="              # &=
  of tkAmpAmpAsgn: result = "&&="          # &&=
  of tkBar: result = "|"                   # |
  of tkBarBar: result = "||"               # ||
  of tkBarAsgn: result = "|="              # |=
  of tkBarBarAsgn: result = "||="          # ||=
  of tkNot: result = "!"                   # !
  of tkPlusPlus: result = "++"             # ++
  of tkMinusMinus: result = "--"           # --
  of tkPlus: result = "+"                  # +
  of tkPlusAsgn: result = "+="             # +=
  of tkMinus: result = "-"                 # -
  of tkMinusAsgn: result = "-="            # -=
  of tkMod: result = "%"                   # %
  of tkModAsgn: result = "%="              # %=
  of tkSlash: result = "/"                 # /
  of tkSlashAsgn: result = "/="            # /=
  of tkStar: result = "*"                  # *
  of tkStarAsgn: result = "*="             # *=
  of tkHat: result = "^"                   # ^
  of tkHatAsgn: result = "^="              # ^=
  of tkAsgn: result = "="                  # =
  of tkEquals: result = "=="               # ==
  of tkDot: result = "."                   # .
  of tkDotDotDot: result = "..."           # ...
  of tkLe: result = "<="                   # <=
  of tkLt: result = "<"                    # <
  of tkGe: result = ">="                   # >=
  of tkGt: result = ">"                    # >
  of tkNeq: result = "!="                  # !=
  of tkConditional: result = "?"
  of tkShl: result = "<<"
  of tkShlAsgn: result = "<<="
  of tkShr: result = ">>"
  of tkShrAsgn: result = ">>="
  of tkTilde: result = "~"
  of tkTildeAsgn: result = "~="
  of tkArrow: result = "->"
  of tkArrowStar: result = "->*"
  of tkScope: result = "::"

  of tkSymbol: result = "[identifier]"
  of tkParLe: result = "("
  of tkParRi: result = ")"
  of tkBracketLe: result = "["
  of tkBracketRi: result = "]"
  of tkComma: result = ","
  of tkSemiColon: result = ";"
  of tkColon: result = ":"
  of tkCurlyLe: result = "{"
  of tkCurlyRi: result = "}"
  of tkAngleRi: result = "> [end of template]"

proc `$`*(tok: Token): string =
  case tok.kind
  of tkSymbol, tkInvalid, tkStarComment, tkLineComment, tkLit, tkNewLine, tkWhitespace:
    result = tok.s
  else: result = tokKindToStr(tok.kind)

proc debugTok*(L: Lexer; tok: Token): string =
  result = $tok
  if L.debugMode: result.add(" (" & $tok.kind & ")")

proc printTok*(tok: Token) =
  writeLine(stdout, $tok)

proc matchUnderscoreChars(L: var Lexer, tok: var Token, chars: set[char]) =
  # matches ([chars]_)*
  var pos = L.bufpos              # use registers for pos, buf
  var buf = L.buf
  while true:
    if buf[pos] in chars:
      myadd(tok.s, buf[pos])
      inc(pos)
    else:
      break
    if buf[pos] == '_':
      myadd(tok.s, '_')
      inc(pos)
  L.bufPos = pos

when false:
  proc getNumber(L: var Lexer, tok: var Token) =
    var pos = L.bufpos + 2 # skip 0b
    while true:
      case L.buf[pos]
      of 'A'..'Z', 'a'..'z', '0'..'9', '.', '_':
        myadd(tok.s, L.buf[pos])
        inc(pos)
      else: break
    L.bufpos = pos

proc getFloating(L: var Lexer, tok: var Token) =
  matchUnderscoreChars(L, tok, {'0'..'9'})
  if L.buf[L.bufpos] in {'e', 'E'}:
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)
    if L.buf[L.bufpos] in {'+', '-'}:
      myadd(tok.s, L.buf[L.bufpos])
      inc(L.bufpos)
    matchUnderscoreChars(L, tok, {'0'..'9'})

proc getNumber(L: var Lexer, tok: var Token) =
  tok.kind = tkLit
  if L.buf[L.bufpos] == '.':
    myadd(tok.s, '.')
    inc(L.bufpos)
    getFloating(L, tok)
  else:
    matchUnderscoreChars(L, tok, {'0'..'9'})
    if L.buf[L.bufpos] in {'.','e','E'}:
      if L.buf[L.bufpos] == '.':
        myadd(tok.s, L.buf[L.bufpos])
        inc(L.bufpos)
      getFloating(L, tok)
  # ignore type suffix:
  while L.buf[L.bufpos] in {'A'..'Z', 'a'..'z'}:
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)

proc handleCRLF(L: var Lexer, pos: int): int =
  result = pos+1
  if pos >= L.f.size:
    L.buf = "\0"
    L.bufpos = 0
    L.f.size = 0
    result = 0

proc escape(L: var Lexer, tok: var Token, allowEmpty=false) =
  myadd(tok.s, L.buf[L.bufpos])
  inc(L.bufpos) # skip \
  case L.buf[L.bufpos]
  of 'b', 'B', 't', 'T', 'n', 'N', 'f', 'F', 'r', 'R', '\'', '"', '\\':
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)
  of '0'..'7':
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)
    if L.buf[L.bufpos] in {'0'..'7'}:
      myadd(tok.s, L.buf[L.bufpos])
      inc(L.bufpos)
      if L.buf[L.bufpos] in {'0'..'7'}:
        myadd(tok.s, L.buf[L.bufpos])
        inc(L.bufpos)
  of 'x':
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)
    while true:
      case L.buf[L.bufpos]
      of '0'..'9', 'a'..'f', 'A'..'F':
        myadd(tok.s, L.buf[L.bufpos])
        inc(L.bufpos)
      else:
        break
  else: discard
  #elif not allowEmpty:
  #  lexMessage(L, errGenerated, "invalid character constant")

proc getCharLit(L: var Lexer, tok: var Token) =
  myadd(tok.s, L.buf[L.bufpos])
  inc(L.bufpos)
  if L.buf[L.bufpos] == '\\':
    escape(L, tok)
  else:
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)
  if L.buf[L.bufpos] == '\'':
    myadd(tok.s, L.buf[L.bufpos])
    inc(L.bufpos)
  else:
    discard
    #lexMessage(L, errGenerated, "missing closing single quote")
  tok.kind = tkLit

proc getString(L: var Lexer, tok: var Token) =
  myadd(tok.s, L.buf[L.bufpos])
  var pos = L.bufPos + 1          # skip "
  var buf = L.buf                 # put `buf` in a register
  #var line = L.linenumber         # save linenumber for better error message
  while true:
    case buf[pos]
    of '\"':
      myadd(tok.s, buf[pos])
      inc(pos)
      break
    of '\10':
      myadd(tok.s, buf[pos])
      pos = handleCRLF(L, pos)
      buf = L.buf
    of '\13':
      myadd(tok.s, buf[pos])
      pos = handleCRLF(L, pos)
      buf = L.buf
    of '\0':
      #var line2 = L.linenumber
      #L.lineNumber = line
      #lexMessagePos(L, errGenerated, L.lineStart, "closing \" expected, but end of file reached")
      #L.lineNumber = line2
      break
    of '\\':
      # we allow an empty \ for line concatenation, but we don't require it
      # for line concatenation
      L.bufpos = pos
      escape(L, tok, allowEmpty=true)
      pos = L.bufpos
    else:
      myadd(tok.s, buf[pos])
      inc(pos)
  L.bufpos = pos
  tok.kind = tkLit

when false:
  const
    intrin = "<x86intrin.h>"
  {.localPassC: "-msse4.2".}
  type
    M128i {.importc: "__m128i", header: intrin, bycopy.} = object

  const
    SIDD_CMP_RANGES = 0b0000_0100'i32

  proc mm_loadu_si128(p: pointer): M128i {.importc: "_mm_loadu_si128", header: intrin.}
  proc mm_cmpestri(a: M128i; alen: int32; b: M128i; blen: int32;
                  options: int32): int32 {.importc: "_mm_cmpestri", header: intrin.}

  template `+!`(p: pointer, s: int): pointer =
    cast[pointer](cast[int](p) +% s)

  proc inSillyRanges(c: char; ranges: string): bool =
    # Since C did win nobody knows anymore how to represent set[char] properly so
    # we have to do this crap for SSE4.2.
    var i = 0
    while i < ranges.len:
      if ranges[i] <= c and c <= ranges[i+1]: return true
      inc i, 2

  proc scan(haystack: string; ranges: string): int =
    result = 0
    if haystack.len >= 16:
      let ranges16 = mm_loadu_si128(unsafeAddr(ranges[0]))
      var left = haystack.len and (not 15)
      var buf = cast[pointer](unsafeAddr haystack[0])
      while true:
        let b16 = mm_loadu_si128(buf)
        let r = mm_cmpestri(ranges16, ranges.len.int32, b16, 16, SIDD_CMP_RANGES)
        inc result, r
        if r != 16:
          return result

        buf = buf +! 16
        dec left, 16
        if left == 0: break
    else:
      for i in 0 ..< haystack.len:
        if haystack[i].inSillyRanges(ranges):
          return i
    result = -1

proc getSymbol(L: var Lexer, tok: var Token) =
  var pos = L.bufpos
  var buf = L.buf
  while true:
    var c = buf[pos]
    # speed hack, parse 4 letters at once:
    if c in SymChars and buf[pos+1] in SymChars and buf[pos+2] in SymChars and buf[pos+3] in SymChars:
      let L = tok.s.len
      setLen(tok.s, L+4)
      tok.s[L] = c
      tok.s[L+1] = buf[pos+1]
      tok.s[L+2] = buf[pos+2]
      tok.s[L+3] = buf[pos+3]
      inc(pos, 4)
    else:
      if c notin SymChars: break
      myadd(tok.s, c)
      inc(pos)
  L.bufpos = pos
  tok.kind = tkSymbol

proc scanLineComment(L: var Lexer, tok: var Token) =
  var pos = L.bufpos
  var buf = L.buf
  # a comment ends if the next line does not start with the // on the same
  # column after only whitespace
  tok.kind = tkLineComment
  #var col = getColNumber(L, pos)
  while true:
    myadd(tok.s, buf[pos])
    myadd(tok.s, buf[pos+1])
    inc(pos, 2)               # skip //
    #myadd(tok.s, '#')
    while buf[pos] notin {'\13', '\10'}:
      myadd(tok.s, buf[pos])
      inc(pos)
    myadd(tok.s, buf[pos])
    pos = handleCRLF(L, pos)
    buf = L.buf
    while buf[pos] == ' ':
      myadd(tok.s, buf[pos])
      inc(pos)
    if buf[pos] == '/' and buf[pos+1] == '/':
      discard
    else:
      break
  #while tok.s.len > 0 and tok.s[^1] in {'\t', ' '}: setLen(tok.s, tok.s.len-1)
  L.bufpos = pos

proc scanStarComment(L: var Lexer, tok: var Token) =
  var pos = L.bufpos
  var buf = L.buf
  tok.s = ""
  tok.kind = tkStarComment
  while true:
    case buf[pos]
    of '\13', '\10':
      myadd(tok.s, buf[pos])
      pos = handleCRLF(L, pos)
      buf = L.buf
    of '*':
      myadd(tok.s, buf[pos])
      inc(pos)
      if buf[pos] == '/':
        myadd(tok.s, buf[pos])
        inc(pos)
        break
    of '\0':
      #lexMessage(L, errGenerated, "expected closing '*/'")
      break
    else:
      myadd(tok.s, buf[pos])
      inc(pos)
  # strip trailing whitespace
  #while tok.s.len > 0 and tok.s[^1] in {'\t', ' '}: setLen(tok.s, tok.s.len-1)
  L.bufpos = pos

proc skip(L: var Lexer, tok: var Token) =
  var pos = L.bufpos
  var buf = L.buf
  while true:
    case buf[pos]
    of '\\':
      # Ignore \ line continuation characters when not inDirective
      myadd(tok.s, buf[pos])
      inc(pos)
      if L.inDirective:
        while buf[pos] in {' ', '\t'}:
          myadd(tok.s, buf[pos])
          inc(pos)
        if buf[pos] in {'\13', '\10'}:
          myadd(tok.s, buf[pos])
          pos = handleCRLF(L, pos)
          buf = L.buf
    of ' ', '\t':
      myadd(tok.s, buf[pos])
      inc(pos)                # newline is special:
    of '\13', '\10':
      myadd(tok.s, buf[pos])
      pos = handleCRLF(L, pos)
      buf = L.buf
      if L.inDirective:
        tok.kind = tkNewLine
        L.inDirective = false
    else:
      break                   # EndOfFile also leaves the loop
  L.bufpos = pos

proc getDirective(L: var Lexer, tok: var Token) =
  var pos = L.bufpos + 1
  var buf = L.buf
  myadd(tok.s, buf[pos-1])
  when false:
    while buf[pos] in {' ', '\t'}:
      myadd(tok.s, buf[pos])
      inc(pos)
    while buf[pos] in SymChars:
      myadd(tok.s, buf[pos])
      inc(pos)
  L.bufpos = pos
  tok.kind = tkDirective
  L.inDirective = true

proc getTok*(L: var Lexer, tok: var Token) =
  tok.kind = tkInvalid
  fillToken(tok)
  let pos = L.bufpos
  skip(L, tok)
  if tok.kind == tkNewLine: return
  if L.bufpos != pos:
    tok.kind = tkWhitespace
    return
  var c = L.buf[L.bufpos]
  if c in SymStartChars:
    getSymbol(L, tok)
  elif c in {'0'..'9'} or (c == '.' and L.buf[L.bufpos+1] in {'0'..'9'}):
    getNumber(L, tok)
  else:
    case c
    of ';':
      tok.kind = tkSemicolon
      inc(L.bufpos)
    of '/':
      if L.buf[L.bufpos + 1] == '/':
        scanLineComment(L, tok)
      elif L.buf[L.bufpos+1] == '*':
        scanStarComment(L, tok)
      elif L.buf[L.bufpos+1] == '=':
        inc(L.bufpos, 2)
        tok.kind = tkSlashAsgn
      else:
        tok.kind = tkSlash
        inc(L.bufpos)
    of ',':
      tok.kind = tkComma
      inc(L.bufpos)
    of '(':
      inc(L.bufpos)
      tok.kind = tkParLe
    of '*':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        inc(L.bufpos)
        tok.kind = tkStarAsgn
      else:
        tok.kind = tkStar
    of ')':
      inc(L.bufpos)
      tok.kind = tkParRi
    of '[':
      inc(L.bufpos)
      tok.kind = tkBracketLe
    of ']':
      inc(L.bufpos)
      tok.kind = tkBracketRi
    of '.':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.' and L.buf[L.bufpos+1] == '.':
        tok.kind = tkDotDotDot
        inc(L.bufpos, 2)
      else:
        tok.kind = tkDot
    of '{':
      inc(L.bufpos)
      tok.kind = tkCurlyLe
    of '}':
      inc(L.bufpos)
      tok.kind = tkCurlyRi
    of '+':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkPlusAsgn
        inc(L.bufpos)
      elif L.buf[L.bufpos] == '+':
        tok.kind = tkPlusPlus
        inc(L.bufpos)
      else:
        tok.kind = tkPlus
    of '-':
      inc(L.bufpos)
      case L.buf[L.bufpos]
      of '>':
        tok.kind = tkArrow
        inc(L.bufpos)
        if L.buf[L.bufpos] == '*':
          tok.kind = tkArrowStar
          inc(L.bufpos)
      of '=':
        tok.kind = tkMinusAsgn
        inc(L.bufpos)
      of '-':
        tok.kind = tkMinusMinus
        inc(L.bufpos)
      else:
        tok.kind = tkMinus
    of '?':
      inc(L.bufpos)
      tok.kind = tkConditional
    of ':':
      inc(L.bufpos)
      if L.buf[L.bufpos] == ':':
        tok.kind = tkScope
        inc(L.bufpos)
      else:
        tok.kind = tkColon
    of '!':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkNeq
        inc(L.bufpos)
      else:
        tok.kind = tkNot
    of '<':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        inc(L.bufpos)
        tok.kind = tkLe
      elif L.buf[L.bufpos] == '<':
        inc(L.bufpos)
        if L.buf[L.bufpos] == '=':
          inc(L.bufpos)
          tok.kind = tkShlAsgn
        else:
          tok.kind = tkShl
      else:
        tok.kind = tkLt
    of '>':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        inc(L.bufpos)
        tok.kind = tkGe
      elif L.buf[L.bufpos] == '>':
        inc(L.bufpos)
        if L.buf[L.bufpos] == '=':
          inc(L.bufpos)
          tok.kind = tkShrAsgn
        else:
          tok.kind = tkShr
      else:
        tok.kind = tkGt
    of '=':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkEquals
        inc(L.bufpos)
      else:
        tok.kind = tkAsgn
    of '&':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkAmpAsgn
        inc(L.bufpos)
      elif L.buf[L.bufpos] == '&':
        inc(L.bufpos)
        if L.buf[L.bufpos] == '=':
          inc(L.bufpos)
          tok.kind = tkAmpAmpAsgn
        else:
          tok.kind = tkAmpAmp
      else:
        tok.kind = tkAmp
    of '|':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkBarAsgn
        inc(L.bufpos)
      elif L.buf[L.bufpos] == '|':
        inc(L.bufpos)
        if L.buf[L.bufpos] == '=':
          inc(L.bufpos)
          tok.kind = tkBarBarAsgn
        else:
          tok.kind = tkBarBar
      else:
        tok.kind = tkBar
    of '^':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkHatAsgn
        inc(L.bufpos)
      else:
        tok.kind = tkHat
    of '%':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkModAsgn
        inc(L.bufpos)
      else:
        tok.kind = tkMod
    of '~':
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=':
        tok.kind = tkTildeAsgn
        inc(L.bufpos)
      else:
        tok.kind = tkTilde
    of '#':
      if L.buf[L.bufpos+1] == '#':
        inc(L.bufpos, 2)
        tok.kind = tkDirConc
      else:
        getDirective(L, tok)
    of '"': getString(L, tok)
    of '\'': getCharLit(L, tok)
    of '\0':
      tok.kind = tkEof
    else:
      tok.s = $c
      tok.kind = tkInvalid
      #lexMessage(L, errGenerated, "invalid token " & c & " (\\" & $(ord(c)) & ')')
      inc(L.bufpos)
