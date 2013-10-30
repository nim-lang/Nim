#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``parsecfg`` module implements a high performance configuration file
## parser. The configuration file's syntax is similar to the Windows ``.ini``
## format, but much more powerful, as it is not a line based parser. String
## literals, raw string literals and triple quoted string literals are supported
## as in the Nimrod programming language.

## This is an example of how a configuration file may look like:
##
## .. include:: doc/mytest.cfg
##     :literal:
## The file ``examples/parsecfgex.nim`` demonstrates how to use the
## configuration file parser:
##
## .. code-block:: nimrod
##     :file: examples/parsecfgex.nim


import
  hashes, strutils, lexbase, streams

include "system/inclrtl"

type
  TCfgEventKind* = enum ## enumeration of all events that may occur when parsing
    cfgEof,             ## end of file reached
    cfgSectionStart,    ## a ``[section]`` has been parsed
    cfgKeyValuePair,    ## a ``key=value`` pair has been detected
    cfgOption,          ## a ``--key=value`` command line option
    cfgError            ## an error ocurred during parsing

  TCfgEvent* = object of TObject ## describes a parsing event
    case kind*: TCfgEventKind    ## the kind of the event
    of cfgEof: nil
    of cfgSectionStart:
      section*: string           ## `section` contains the name of the
                                 ## parsed section start (syntax: ``[section]``)
    of cfgKeyValuePair, cfgOption:
      key*, value*: string       ## contains the (key, value) pair if an option
                                 ## of the form ``--key: value`` or an ordinary
                                 ## ``key= value`` pair has been parsed.
                                 ## ``value==""`` if it was not specified in the
                                 ## configuration file.
    of cfgError:                 ## the parser encountered an error: `msg`
      msg*: string               ## contains the error message. No exceptions
                                 ## are thrown if a parse error occurs.

  TTokKind = enum
    tkInvalid, tkEof,
    tkSymbol, tkEquals, tkColon, tkBracketLe, tkBracketRi, tkDashDash
  TToken {.final.} = object  # a token
    kind: TTokKind           # the type of the token
    literal: string          # the parsed (string) literal

  TCfgParser* = object of TBaseLexer ## the parser object.
    tok: TToken
    filename: string

# implementation

const
  SymChars: TCharSet = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF', '.',
                        '/', '\\'}

proc rawGetTok(c: var TCfgParser, tok: var TToken)

proc open*(c: var TCfgParser, input: PStream, filename: string,
           lineOffset = 0) {.
  rtl, extern: "npc$1".} =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages. `lineOffset` can be used to influence the line
  ## number information in the generated error messages.
  lexbase.open(c, input)
  c.filename = filename
  c.tok.kind = tkInvalid
  c.tok.literal = ""
  inc(c.linenumber, lineOffset)
  rawGetTok(c, c.tok)

proc close*(c: var TCfgParser) {.rtl, extern: "npc$1".} =
  ## closes the parser `c` and its associated input stream.
  lexbase.close(c)

proc getColumn*(c: TCfgParser): int {.rtl, extern: "npc$1".} =
  ## get the current column the parser has arrived at.
  result = getColNumber(c, c.bufPos)

proc getLine*(c: TCfgParser): int {.rtl, extern: "npc$1".} =
  ## get the current line the parser has arrived at.
  result = c.linenumber

proc getFilename*(c: TCfgParser): string {.rtl, extern: "npc$1".} =
  ## get the filename of the file that the parser processes.
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
  inc(c.bufpos)               # skip '\'
  case c.buf[c.bufpos]
  of 'n', 'N':
    add(tok.literal, "\n")
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
  of '\'', '"':
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
  of '0'..'9':
    var xi = 0
    handleDecChars(c, xi)
    if (xi <= 255): add(tok.literal, Chr(xi))
    else: tok.kind = tkInvalid
  else: tok.kind = tkInvalid

proc HandleCRLF(c: var TCfgParser, pos: int): int =
  case c.buf[pos]
  of '\c': result = lexbase.HandleCR(c, pos)
  of '\L': result = lexbase.HandleLF(c, pos)
  else: result = pos

proc getString(c: var TCfgParser, tok: var TToken, rawMode: bool) =
  var pos = c.bufPos + 1          # skip "
  var buf = c.buf                 # put `buf` in a register
  tok.kind = tkSymbol
  if (buf[pos] == '"') and (buf[pos + 1] == '"'):
    # long string literal:
    inc(pos, 2)               # skip ""
                              # skip leading newline:
    pos = HandleCRLF(c, pos)
    buf = c.buf
    while true:
      case buf[pos]
      of '"':
        if (buf[pos + 1] == '"') and (buf[pos + 2] == '"'): break
        add(tok.literal, '"')
        Inc(pos)
      of '\c', '\L':
        pos = HandleCRLF(c, pos)
        buf = c.buf
        add(tok.literal, "\n")
      of lexbase.EndOfFile:
        tok.kind = tkInvalid
        break
      else:
        add(tok.literal, buf[pos])
        Inc(pos)
    c.bufpos = pos + 3       # skip the three """
  else:
    # ordinary string literal
    while true:
      var ch = buf[pos]
      if ch == '"':
        inc(pos)              # skip '"'
        break
      if ch in {'\c', '\L', lexbase.EndOfFile}:
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
  var pos = c.bufpos
  var buf = c.buf
  while true:
    add(tok.literal, buf[pos])
    Inc(pos)
    if not (buf[pos] in SymChars): break
  c.bufpos = pos
  tok.kind = tkSymbol

proc skip(c: var TCfgParser) =
  var pos = c.bufpos
  var buf = c.buf
  while true:
    case buf[pos]
    of ' ', '\t':
      Inc(pos)
    of '#', ';':
      while not (buf[pos] in {'\c', '\L', lexbase.EndOfFile}): inc(pos)
    of '\c', '\L':
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
    tok.literal = "]"
  of ']':
    tok.kind = tkBracketRi
    Inc(c.bufpos)
    tok.literal = "]"
  of '"':
    getString(c, tok, false)
  of lexbase.EndOfFile:
    tok.kind = tkEof
    tok.literal = "[EOF]"
  else: getSymbol(c, tok)

proc errorStr*(c: TCfgParser, msg: string): string {.rtl, extern: "npc$1".} =
  ## returns a properly formated error message containing current line and
  ## column information.
  result = `%`("$1($2, $3) Error: $4",
               [c.filename, $getLine(c), $getColumn(c), msg])

proc warningStr*(c: TCfgParser, msg: string): string {.rtl, extern: "npc$1".} =
  ## returns a properly formated warning message containing current line and
  ## column information.
  result = `%`("$1($2, $3) Warning: $4",
               [c.filename, $getLine(c), $getColumn(c), msg])

proc ignoreMsg*(c: TCfgParser, e: TCfgEvent): string {.rtl, extern: "npc$1".} =
  ## returns a properly formated warning message containing that
  ## an entry is ignored.
  case e.kind
  of cfgSectionStart: result = c.warningStr("section ignored: " & e.section)
  of cfgKeyValuePair: result = c.warningStr("key ignored: " & e.key)
  of cfgOption:
    result = c.warningStr("command ignored: " & e.key & ": " & e.value)
  of cfgError: result = e.msg
  of cfgEof: result = ""

proc getKeyValPair(c: var TCfgParser, kind: TCfgEventKind): TCfgEvent =
  if c.tok.kind == tkSymbol:
    result.kind = kind
    result.key = c.tok.literal
    result.value = ""
    rawGetTok(c, c.tok)
    if c.tok.kind in {tkEquals, tkColon}:
      rawGetTok(c, c.tok)
      if c.tok.kind == tkSymbol:
        result.value = c.tok.literal
      else:
        reset result
        result.kind = cfgError
        result.msg = errorStr(c, "symbol expected, but found: " & c.tok.literal)
      rawGetTok(c, c.tok)
  else:
    result.kind = cfgError
    result.msg = errorStr(c, "symbol expected, but found: " & c.tok.literal)
    rawGetTok(c, c.tok)

proc next*(c: var TCfgParser): TCfgEvent {.rtl, extern: "npc$1".} =
  ## retrieves the first/next event. This controls the parser.
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
      result.msg = errorStr(c, "']' expected, but found: " & c.tok.literal)
  of tkInvalid, tkEquals, tkColon, tkBracketRi:
    result.kind = cfgError
    result.msg = errorStr(c, "invalid token: " & c.tok.literal)
    rawGetTok(c, c.tok)
