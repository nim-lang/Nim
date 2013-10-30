#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# A HIGH-PERFORMANCE configuration file parser;
# the Nimrod version of this file is part of the
# standard library.

import
  llstream, nhashes, strutils, nimlexbase

type
  TCfgEventKind* = enum
    cfgEof,                   # end of file reached
    cfgSectionStart,          # a ``[section]`` has been parsed
    cfgKeyValuePair,          # a ``key=value`` pair has been detected
    cfgOption,                # a ``--key=value`` command line option
    cfgError # an error ocurred during parsing; msg contains the
             # error message
  TCfgEvent* = object of TObject
    case kind*: TCfgEventKind
    of cfgEof:
        nil

    of cfgSectionStart:
        section*: string

    of cfgKeyValuePair, cfgOption:
        key*, value*: string

    of cfgError:
        msg*: string


  TTokKind* = enum
    tkInvalid, tkEof,         # order is important here!
    tkSymbol, tkEquals, tkColon, tkBracketLe, tkBracketRi, tkDashDash
  TToken*{.final.} = object   # a token
    kind*: TTokKind           # the type of the token
    literal*: string          # the parsed (string) literal

  TParserState* = enum
    startState, commaState
  TCfgParser* = object of TBaseLexer
    tok*: TToken
    state*: TParserState
    filename*: string


proc Open*(c: var TCfgParser, filename: string, inputStream: PLLStream)
proc Close*(c: var TCfgParser)
proc next*(c: var TCfgParser): TCfgEvent
proc getColumn*(c: TCfgParser): int
proc getLine*(c: TCfgParser): int
proc getFilename*(c: TCfgParser): string
proc errorStr*(c: TCfgParser, msg: string): string
# implementation

const
  SymChars: TCharSet = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF'} #
                                                                           # ----------------------------------------------------------------------------

proc rawGetTok(c: var TCfgParser, tok: var TToken)
proc open(c: var TCfgParser, filename: string, inputStream: PLLStream) =
  openBaseLexer(c, inputStream)
  c.filename = filename
  c.state = startState
  c.tok.kind = tkInvalid
  c.tok.literal = ""
  rawGetTok(c, c.tok)

proc close(c: var TCfgParser) =
  closeBaseLexer(c)

proc getColumn(c: TCfgParser): int =
  result = getColNumber(c, c.bufPos)

proc getLine(c: TCfgParser): int =
  result = c.linenumber

proc getFilename(c: TCfgParser): string =
  result = c.filename

proc handleHexChar(c: var TCfgParser, xi: var int) =
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
    nil

proc handleDecChars(c: var TCfgParser, xi: var int) =
  while c.buf[c.bufpos] in {'0'..'9'}:
    xi = (xi * 10) + (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)

proc getEscapedChar(c: var TCfgParser, tok: var TToken) =
  var xi: int
  inc(c.bufpos)               # skip '\'
  case c.buf[c.bufpos]
  of 'n', 'N':
    tok.literal = tok.literal & "\n"
    Inc(c.bufpos)
  of 'r', 'R', 'c', 'C':
    add(tok.literal, CR)
    Inc(c.bufpos)
  of 'l', 'L':
    add(tok.literal, LF)
    Inc(c.bufpos)
  of 'f', 'F':
    add(tok.literal, FF)
    inc(c.bufpos)
  of 'e', 'E':
    add(tok.literal, ESC)
    Inc(c.bufpos)
  of 'a', 'A':
    add(tok.literal, BEL)
    Inc(c.bufpos)
  of 'b', 'B':
    add(tok.literal, BACKSPACE)
    Inc(c.bufpos)
  of 'v', 'V':
    add(tok.literal, VT)
    Inc(c.bufpos)
  of 't', 'T':
    add(tok.literal, Tabulator)
    Inc(c.bufpos)
  of '\'', '\"':
    add(tok.literal, c.buf[c.bufpos])
    Inc(c.bufpos)
  of '\\':
    add(tok.literal, '\\')
    Inc(c.bufpos)
  of 'x', 'X':
    inc(c.bufpos)
    xi = 0
    handleHexChar(c, xi)
    handleHexChar(c, xi)
    add(tok.literal, Chr(xi))
  of '0'..'9':
    xi = 0
    handleDecChars(c, xi)
    if (xi <= 255): add(tok.literal, Chr(xi))
    else: tok.kind = tkInvalid
  else: tok.kind = tkInvalid

proc HandleCRLF(c: var TCfgParser, pos: int): int =
  case c.buf[pos]
  of CR: result = lexbase.HandleCR(c, pos)
  of LF: result = lexbase.HandleLF(c, pos)
  else: result = pos

proc getString(c: var TCfgParser, tok: var TToken, rawMode: bool) =
  var
    pos: int
    ch: Char
    buf: cstring
  pos = c.bufPos + 1          # skip "
  buf = c.buf                 # put `buf` in a register
  tok.kind = tkSymbol
  if (buf[pos] == '\"') and (buf[pos + 1] == '\"'):
    # long string literal:
    inc(pos, 2)               # skip ""
                              # skip leading newline:
    pos = HandleCRLF(c, pos)
    buf = c.buf
    while true:
      case buf[pos]
      of '\"':
        if (buf[pos + 1] == '\"') and (buf[pos + 2] == '\"'): break
        add(tok.literal, '\"')
        Inc(pos)
      of CR, LF:
        pos = HandleCRLF(c, pos)
        buf = c.buf
        tok.literal = tok.literal & "\n"
      of lexbase.EndOfFile:
        tok.kind = tkInvalid
        break
      else:
        add(tok.literal, buf[pos])
        Inc(pos)
    c.bufpos = pos +
        3                     # skip the three """
  else:
    # ordinary string literal
    while true:
      ch = buf[pos]
      if ch == '\"':
        inc(pos)              # skip '"'
        break
      if ch in {CR, LF, lexbase.EndOfFile}:
        tok.kind = tkInvalid
        break
      if (ch == '\\') and not rawMode:
        c.bufPos = pos
        getEscapedChar(c, tok)
        pos = c.bufPos
      else:
        add(tok.literal, ch)
        Inc(pos)
    c.bufpos = pos

proc getSymbol(c: var TCfgParser, tok: var TToken) =
  var
    pos: int
    buf: cstring
  pos = c.bufpos
  buf = c.buf
  while true:
    add(tok.literal, buf[pos])
    Inc(pos)
    if not (buf[pos] in SymChars): break
  c.bufpos = pos
  tok.kind = tkSymbol

proc skip(c: var TCfgParser) =
  var
    buf: cstring
    pos: int
  pos = c.bufpos
  buf = c.buf
  while true:
    case buf[pos]
    of ' ':
      Inc(pos)
    of Tabulator:
      inc(pos)
    of '#', ';':
      while not (buf[pos] in {CR, LF, lexbase.EndOfFile}): inc(pos)
    of CR, LF:
      pos = HandleCRLF(c, pos)
      buf = c.buf
    else:
      break                   # EndOfFile also leaves the loop
  c.bufpos = pos

proc rawGetTok(c: var TCfgParser, tok: var TToken) =
  tok.kind = tkInvalid
  setlen(tok.literal, 0)
  skip(c)
  case c.buf[c.bufpos]
  of '=':
    tok.kind = tkEquals
    inc(c.bufpos)
    tok.literal = "="
  of '-':
    inc(c.bufPos)
    if c.buf[c.bufPos] == '-': inc(c.bufPos)
    tok.kind = tkDashDash
    tok.literal = "--"
  of ':':
    tok.kind = tkColon
    inc(c.bufpos)
    tok.literal = ":"
  of 'r', 'R':
    if c.buf[c.bufPos + 1] == '\"':
      Inc(c.bufPos)
      getString(c, tok, true)
    else:
      getSymbol(c, tok)
  of '[':
    tok.kind = tkBracketLe
    inc(c.bufpos)
    tok.literal = "["
  of ']':
    tok.kind = tkBracketRi
    Inc(c.bufpos)
    tok.literal = "]"
  of '\"':
    getString(c, tok, false)
  of lexbase.EndOfFile:
    tok.kind = tkEof
  else: getSymbol(c, tok)

proc errorStr(c: TCfgParser, msg: string): string =
  result = `%`("$1($2, $3) Error: $4",
               [c.filename, $(getLine(c)), $(getColumn(c)), msg])

proc getKeyValPair(c: var TCfgParser, kind: TCfgEventKind): TCfgEvent =
  if c.tok.kind == tkSymbol:
    result.kind = kind
    result.key = c.tok.literal
    result.value = ""
    rawGetTok(c, c.tok)
    while c.tok.literal == ".":
      add(result.key, '.')
      rawGetTok(c, c.tok)
      if c.tok.kind == tkSymbol:
        add(result.key, c.tok.literal)
        rawGetTok(c, c.tok)
      else:
        result.kind = cfgError
        result.msg = errorStr(c, "symbol expected, but found: " & c.tok.literal)
        break
    if c.tok.kind in {tkEquals, tkColon}:
      rawGetTok(c, c.tok)
      if c.tok.kind == tkSymbol:
        result.value = c.tok.literal
      else:
        result.kind = cfgError
        result.msg = errorStr(c, "symbol expected, but found: " & c.tok.literal)
      rawGetTok(c, c.tok)
  else:
    result.kind = cfgError
    result.msg = errorStr(c, "symbol expected, but found: " & c.tok.literal)
    rawGetTok(c, c.tok)

proc next(c: var TCfgParser): TCfgEvent =
  case c.tok.kind
  of tkEof:
    result.kind = cfgEof
  of tkDashDash:
    rawGetTok(c, c.tok)
    result = getKeyValPair(c, cfgOption)
  of tkSymbol:
    result = getKeyValPair(c, cfgKeyValuePair)
  of tkBracketLe:
    rawGetTok(c, c.tok)
    if c.tok.kind == tkSymbol:
      result.kind = cfgSectionStart
      result.section = c.tok.literal
    else:
      result.kind = cfgError
      result.msg = errorStr(c, "symbol expected, but found: " & c.tok.literal)
    rawGetTok(c, c.tok)
    if c.tok.kind == tkBracketRi:
      rawGetTok(c, c.tok)
    else:
      result.kind = cfgError
      result.msg = errorStr(c, "\']\' expected, but found: " & c.tok.literal)
  of tkInvalid, tkBracketRi, tkEquals, tkColon:
    result.kind = cfgError
    result.msg = errorStr(c, "invalid token: " & c.tok.literal)
    rawGetTok(c, c.tok)
