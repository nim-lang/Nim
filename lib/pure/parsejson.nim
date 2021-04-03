#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a json parser. It is used
## and exported by the `json` standard library
## module, but can also be used in its own right.

import strutils, lexbase, streams, unicode
import std/private/decode_helpers

type
  JsonEventKind* = enum ## enumeration of all events that may occur when parsing
    jsonError,          ## an error occurred during parsing
    jsonEof,            ## end of file reached
    jsonString,         ## a string literal
    jsonInt,            ## an integer literal
    jsonFloat,          ## a float literal
    jsonTrue,           ## the value `true`
    jsonFalse,          ## the value `false`
    jsonNull,           ## the value `null`
    jsonObjectStart,    ## start of an object: the `{` token
    jsonObjectEnd,      ## end of an object: the `}` token
    jsonArrayStart,     ## start of an array: the `[` token
    jsonArrayEnd        ## end of an array: the `]` token

  TokKind* = enum # must be synchronized with TJsonEventKind!
    tkError,
    tkEof,
    tkString,
    tkInt,
    tkFloat,
    tkTrue,
    tkFalse,
    tkNull,
    tkCurlyLe,
    tkCurlyRi,
    tkBracketLe,
    tkBracketRi,
    tkColon,
    tkComma

  JsonError* = enum       ## enumeration that lists all errors that can occur
    errNone,              ## no error
    errInvalidToken,      ## invalid token
    errStringExpected,    ## string expected
    errColonExpected,     ## `:` expected
    errCommaExpected,     ## `,` expected
    errBracketRiExpected, ## `]` expected
    errCurlyRiExpected,   ## `}` expected
    errQuoteExpected,     ## `"` or `'` expected
    errEOC_Expected,      ## `*/` expected
    errEofExpected,       ## EOF expected
    errExprExpected       ## expr expected

  ParserState = enum
    stateEof, stateStart, stateObject, stateArray, stateExpectArrayComma,
    stateExpectObjectComma, stateExpectColon, stateExpectValue

  JsonParser* = object of BaseLexer ## the parser object.
    a*: string
    tok*: TokKind
    kind: JsonEventKind
    err: JsonError
    state: seq[ParserState]
    filename: string
    rawStringLiterals: bool

  JsonKindError* = object of ValueError ## raised by the `to` macro if the
                                        ## JSON kind is incorrect.
  JsonParsingError* = object of ValueError ## is raised for a JSON error

const
  errorMessages*: array[JsonError, string] = [
    "no error",
    "invalid token",
    "string expected",
    "':' expected",
    "',' expected",
    "']' expected",
    "'}' expected",
    "'\"' or \"'\" expected",
    "'*/' expected",
    "EOF expected",
    "expression expected"
  ]
  tokToStr: array[TokKind, string] = [
    "invalid token",
    "EOF",
    "string literal",
    "int literal",
    "float literal",
    "true",
    "false",
    "null",
    "{", "}", "[", "]", ":", ","
  ]

proc open*(my: var JsonParser, input: Stream, filename: string;
           rawStringLiterals = false) =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages. If `rawStringLiterals` is true, string literals
  ## are kept with their surrounding quotes and escape sequences in them are
  ## left untouched too.
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = jsonError
  my.a = ""
  my.rawStringLiterals = rawStringLiterals

proc close*(my: var JsonParser) {.inline.} =
  ## closes the parser `my` and its associated input stream.
  lexbase.close(my)

proc str*(my: JsonParser): string {.inline.} =
  ## returns the character data for the events: `jsonInt`, `jsonFloat`,
  ## `jsonString`
  assert(my.kind in {jsonInt, jsonFloat, jsonString})
  return my.a

proc getInt*(my: JsonParser): BiggestInt {.inline.} =
  ## returns the number for the event: `jsonInt`
  assert(my.kind == jsonInt)
  return parseBiggestInt(my.a)

proc getFloat*(my: JsonParser): float {.inline.} =
  ## returns the number for the event: `jsonFloat`
  assert(my.kind == jsonFloat)
  return parseFloat(my.a)

proc kind*(my: JsonParser): JsonEventKind {.inline.} =
  ## returns the current event type for the JSON parser
  return my.kind

proc getColumn*(my: JsonParser): int {.inline.} =
  ## get the current column the parser has arrived at.
  result = getColNumber(my, my.bufpos)

proc getLine*(my: JsonParser): int {.inline.} =
  ## get the current line the parser has arrived at.
  result = my.lineNumber

proc getFilename*(my: JsonParser): string {.inline.} =
  ## get the filename of the file that the parser processes.
  result = my.filename

proc errorMsg*(my: JsonParser): string =
  ## returns a helpful error message for the event `jsonError`
  assert(my.kind == jsonError)
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), errorMessages[my.err]]

proc errorMsgExpected*(my: JsonParser, e: string): string =
  ## returns an error message "`e` expected" in the same format as the
  ## other error messages
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), e & " expected"]

proc parseEscapedUTF16*(buf: cstring, pos: var int): int =
  result = 0
  #UTF-16 escape is always 4 bytes.
  for _ in 0..3:
    # if char in '0' .. '9', 'a' .. 'f', 'A' .. 'F'
    if handleHexChar(buf[pos], result):
      inc(pos)
    else:
      return -1

proc parseString(my: var JsonParser): TokKind =
  result = tkString
  var pos = my.bufpos + 1
  if my.rawStringLiterals:
    add(my.a, '"')
  while true:
    case my.buf[pos]
    of '\0':
      my.err = errQuoteExpected
      result = tkError
      break
    of '"':
      if my.rawStringLiterals:
        add(my.a, '"')
      inc(pos)
      break
    of '\\':
      if my.rawStringLiterals:
        add(my.a, '\\')
      case my.buf[pos+1]
      of '\\', '"', '\'', '/':
        add(my.a, my.buf[pos+1])
        inc(pos, 2)
      of 'b':
        add(my.a, '\b')
        inc(pos, 2)
      of 'f':
        add(my.a, '\f')
        inc(pos, 2)
      of 'n':
        add(my.a, '\L')
        inc(pos, 2)
      of 'r':
        add(my.a, '\C')
        inc(pos, 2)
      of 't':
        add(my.a, '\t')
        inc(pos, 2)
      of 'v':
        add(my.a, '\v')
        inc(pos, 2)
      of 'u':
        if my.rawStringLiterals:
          add(my.a, 'u')
        inc(pos, 2)
        var pos2 = pos
        var r = parseEscapedUTF16(my.buf, pos)
        if r < 0:
          my.err = errInvalidToken
          break
        # Deal with surrogates
        if (r and 0xfc00) == 0xd800:
          if my.buf[pos] != '\\' or my.buf[pos+1] != 'u':
            my.err = errInvalidToken
            break
          inc(pos, 2)
          var s = parseEscapedUTF16(my.buf, pos)
          if (s and 0xfc00) == 0xdc00 and s > 0:
            r = 0x10000 + (((r - 0xd800) shl 10) or (s - 0xdc00))
          else:
            my.err = errInvalidToken
            break
        if my.rawStringLiterals:
          let length = pos - pos2
          for i in 1 .. length:
            if my.buf[pos2] in {'0'..'9', 'A'..'F', 'a'..'f'}:
              add(my.a, my.buf[pos2])
              inc pos2
            else:
              break
        else:
          add(my.a, toUTF8(Rune(r)))
      else:
        # don't bother with the error
        add(my.a, my.buf[pos])
        inc(pos)
    of '\c':
      pos = lexbase.handleCR(my, pos)
      add(my.a, '\c')
    of '\L':
      pos = lexbase.handleLF(my, pos)
      add(my.a, '\L')
    else:
      add(my.a, my.buf[pos])
      inc(pos)
  my.bufpos = pos # store back

proc skip(my: var JsonParser) =
  var pos = my.bufpos
  while true:
    case my.buf[pos]
    of '/':
      if my.buf[pos+1] == '/':
        # skip line comment:
        inc(pos, 2)
        while true:
          case my.buf[pos]
          of '\0':
            break
          of '\c':
            pos = lexbase.handleCR(my, pos)
            break
          of '\L':
            pos = lexbase.handleLF(my, pos)
            break
          else:
            inc(pos)
      elif my.buf[pos+1] == '*':
        # skip long comment:
        inc(pos, 2)
        while true:
          case my.buf[pos]
          of '\0':
            my.err = errEOC_Expected
            break
          of '\c':
            pos = lexbase.handleCR(my, pos)
          of '\L':
            pos = lexbase.handleLF(my, pos)
          of '*':
            inc(pos)
            if my.buf[pos] == '/':
              inc(pos)
              break
          else:
            inc(pos)
      else:
        break
    of ' ', '\t':
      inc(pos)
    of '\c':
      pos = lexbase.handleCR(my, pos)
    of '\L':
      pos = lexbase.handleLF(my, pos)
    else:
      break
  my.bufpos = pos

proc parseNumber(my: var JsonParser) =
  var pos = my.bufpos
  if my.buf[pos] == '-':
    add(my.a, '-')
    inc(pos)
  if my.buf[pos] == '.':
    add(my.a, "0.")
    inc(pos)
  else:
    while my.buf[pos] in Digits:
      add(my.a, my.buf[pos])
      inc(pos)
    if my.buf[pos] == '.':
      add(my.a, '.')
      inc(pos)
  # digits after the dot:
  while my.buf[pos] in Digits:
    add(my.a, my.buf[pos])
    inc(pos)
  if my.buf[pos] in {'E', 'e'}:
    add(my.a, my.buf[pos])
    inc(pos)
    if my.buf[pos] in {'+', '-'}:
      add(my.a, my.buf[pos])
      inc(pos)
    while my.buf[pos] in Digits:
      add(my.a, my.buf[pos])
      inc(pos)
  my.bufpos = pos

proc parseName(my: var JsonParser) =
  var pos = my.bufpos
  if my.buf[pos] in IdentStartChars:
    while my.buf[pos] in IdentChars:
      add(my.a, my.buf[pos])
      inc(pos)
  my.bufpos = pos

proc getTok*(my: var JsonParser): TokKind =
  setLen(my.a, 0)
  skip(my) # skip whitespace, comments
  case my.buf[my.bufpos]
  of '-', '.', '0'..'9':
    parseNumber(my)
    if {'.', 'e', 'E'} in my.a:
      result = tkFloat
    else:
      result = tkInt
  of '"':
    result = parseString(my)
  of '[':
    inc(my.bufpos)
    result = tkBracketLe
  of '{':
    inc(my.bufpos)
    result = tkCurlyLe
  of ']':
    inc(my.bufpos)
    result = tkBracketRi
  of '}':
    inc(my.bufpos)
    result = tkCurlyRi
  of ',':
    inc(my.bufpos)
    result = tkComma
  of ':':
    inc(my.bufpos)
    result = tkColon
  of '\0':
    result = tkEof
  of 'a'..'z', 'A'..'Z', '_':
    parseName(my)
    case my.a
    of "null": result = tkNull
    of "true": result = tkTrue
    of "false": result = tkFalse
    else: result = tkError
  else:
    inc(my.bufpos)
    result = tkError
  my.tok = result


proc next*(my: var JsonParser) =
  ## retrieves the first/next event. This controls the parser.
  var tk = getTok(my)
  var i = my.state.len-1
  # the following code is a state machine. If we had proper coroutines,
  # the code could be much simpler.
  case my.state[i]
  of stateEof:
    if tk == tkEof:
      my.kind = jsonEof
    else:
      my.kind = jsonError
      my.err = errEofExpected
  of stateStart:
    # tokens allowed?
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state[i] = stateEof # expect EOF next!
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state.add(stateArray) # we expect any
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    of tkEof:
      my.kind = jsonEof
    else:
      my.kind = jsonError
      my.err = errEofExpected
  of stateObject:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state.add(stateExpectColon)
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state.add(stateExpectColon)
      my.state.add(stateArray)
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state.add(stateExpectColon)
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    of tkCurlyRi:
      my.kind = jsonObjectEnd
      discard my.state.pop()
    else:
      my.kind = jsonError
      my.err = errCurlyRiExpected
  of stateArray:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state.add(stateExpectArrayComma) # expect value next!
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state.add(stateExpectArrayComma)
      my.state.add(stateArray)
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state.add(stateExpectArrayComma)
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    of tkBracketRi:
      my.kind = jsonArrayEnd
      discard my.state.pop()
    else:
      my.kind = jsonError
      my.err = errBracketRiExpected
  of stateExpectArrayComma:
    case tk
    of tkComma:
      discard my.state.pop()
      next(my)
    of tkBracketRi:
      my.kind = jsonArrayEnd
      discard my.state.pop() # pop stateExpectArrayComma
      discard my.state.pop() # pop stateArray
    else:
      my.kind = jsonError
      my.err = errBracketRiExpected
  of stateExpectObjectComma:
    case tk
    of tkComma:
      discard my.state.pop()
      next(my)
    of tkCurlyRi:
      my.kind = jsonObjectEnd
      discard my.state.pop() # pop stateExpectObjectComma
      discard my.state.pop() # pop stateObject
    else:
      my.kind = jsonError
      my.err = errCurlyRiExpected
  of stateExpectColon:
    case tk
    of tkColon:
      my.state[i] = stateExpectValue
      next(my)
    else:
      my.kind = jsonError
      my.err = errColonExpected
  of stateExpectValue:
    case tk
    of tkString, tkInt, tkFloat, tkTrue, tkFalse, tkNull:
      my.state[i] = stateExpectObjectComma
      my.kind = JsonEventKind(ord(tk))
    of tkBracketLe:
      my.state[i] = stateExpectObjectComma
      my.state.add(stateArray)
      my.kind = jsonArrayStart
    of tkCurlyLe:
      my.state[i] = stateExpectObjectComma
      my.state.add(stateObject)
      my.kind = jsonObjectStart
    else:
      my.kind = jsonError
      my.err = errExprExpected

proc raiseParseErr*(p: JsonParser, msg: string) {.noinline, noreturn.} =
  ## raises an `EJsonParsingError` exception.
  raise newException(JsonParsingError, errorMsgExpected(p, msg))

proc eat*(p: var JsonParser, tok: TokKind) =
  if p.tok == tok: discard getTok(p)
  else: raiseParseErr(p, tokToStr[tok])
