#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `JSON`:idx:
## parser. JSON (JavaScript Object Notation) is a lightweight 
## data-interchange format that is easy for humans to read and write 
## (unlike XML). It is easy for machines to parse and generate.
## JSON is based on a subset of the JavaScript Programming Language,
## Standard ECMA-262 3rd Edition - December 1999.

import 
  hashes, strutils, lexbase, streams, unicode

type 
  TJsonEventKind* = enum ## enumation of all events that may occur when parsing
    jsonError,           ## an error ocurred during parsing
    jsonEof,             ## end of file reached
    jsonString,          ## a string literal
    jsonNumber,          ## a number literal
    jsonTrue,            ## the value ``true``
    jsonFalse,           ## the value ``false``
    jsonNull,            ## the value ``null``
    jsonObjectStart,     ## start of an object: the ``{`` token
    jsonObjectEnd,       ## end of an object: the ``}`` token
    jsonArrayStart,      ## start of an array: the ``[`` token
    jsonArrayEnd         ## start of an array: the ``]`` token
    
  TTokKind = enum        # must be synchronized with TJsonEventKind!
    tkError,
    tkEof,
    tkString,
    tkNumber,
    tkTrue,
    tkFalse,
    tkNull,
    tkCurlyLe,
    tkCurlyRi,
    tkBracketLe,
    tkBracketRi,
    tkColon,
    tkComma
    
  TJsonError* = enum       ## enumeration that lists all errors that can occur
    errNone,               ## no error
    errInvalidToken,       ## invalid token
    errStringExpected,     ## string expected
    errColonExpected,      ## ``:`` expected
    errCommaExpected,      ## ``,`` expected
    errBracketRiExpected,  ## ``]`` expected
    errCurlyRiExpected,    ## ``}`` expected
    errQuoteExpected,      ## ``"`` or ``'`` expected
    errEOC_Expected,       ## ``*/`` expected
    errEofExpected,        ## EOF expected
    errExprExpected        ## expr expected
    
  TParserState = enum 
    stateEof, stateStart, stateObject, stateArray, stateExpectArrayComma,
    stateExpectObjectComma, stateExpectColon, stateExpectValue

  TJsonParser* = object of TBaseLexer ## the parser object.
    a: string
    kind: TJsonEventKind
    err: TJsonError
    state: seq[TParserState]
    filename: string
 
const
  errorMessages: array [TJsonError, string] = [
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

proc open*(my: var TJsonParser, input: PStream, filename: string) =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages.
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateStart]
  my.kind = jsonError
  my.a = ""
  
proc close*(my: var TJsonParser) {.inline.} = 
  ## closes the parser `my` and its associated input stream.
  lexbase.close(my)

proc str*(my: TJsonParser): string {.inline.} = 
  ## returns the character data for the events: ``jsonNumber``, 
  ## ``jsonString``
  assert(my.kind in {jsonNumber, jsonString})
  return my.a

proc number*(my: TJsonParser): float {.inline.} = 
  ## returns the number for the event: ``jsonNumber``
  assert(my.kind == jsonNumber)
  return parseFloat(my.a)

proc kind*(my: TJsonParser): TJsonEventKind {.inline.} = 
  ## returns the current event type for the JSON parser
  return my.kind
  
proc getColumn*(my: TJsonParser): int {.inline.} = 
  ## get the current column the parser has arrived at.
  result = getColNumber(my, my.bufPos)

proc getLine*(my: TJsonParser): int {.inline.} = 
  ## get the current line the parser has arrived at.
  result = my.linenumber

proc getFilename*(my: TJsonParser): string {.inline.} = 
  ## get the filename of the file that the parser processes.
  result = my.filename
  
proc errorMsg*(my: TJsonParser): string = 
  ## returns a helpful error message for the event ``jsonError``
  assert(my.kind == jsonError)
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), errorMessages[my.err]]

proc errorMsgExpected*(my: TJsonParser, e: string): string = 
  ## returns an error message "`e` expected" in the same format as the
  ## other error messages 
  result = "$1($2, $3) Error: $4" % [
    my.filename, $getLine(my), $getColumn(my), e & " expected"]

proc handleHexChar(c: Char, x: var int): bool = 
  result = true # Success
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else: result = false # error

proc parseString(my: var TJsonParser): TTokKind =
  result = tkString
  var pos = my.bufpos + 1
  var buf = my.buf
  while true:
    case buf[pos] 
    of '\0': 
      my.err = errQuoteExpected
      result = tkError
      break
    of '"':
      inc(pos)
      break
    of '\\':
      case buf[pos+1]
      of '\\', '"', '\'', '/': 
        add(my.a, buf[pos+1])
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
      of 'u':
        inc(pos, 2)
        var r: int
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        add(my.a, toUTF8(TRune(r)))
      else: 
        # don't bother with the error
        add(my.a, buf[pos])
        inc(pos)
    of '\c': 
      pos = lexbase.HandleCR(my, pos)
      buf = my.buf
      add(my.a, '\c')
    of '\L': 
      pos = lexbase.HandleLF(my, pos)
      buf = my.buf
      add(my.a, '\L')
    else:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos # store back
  
proc skip(my: var TJsonParser) = 
  var pos = my.bufpos
  var buf = my.buf
  while true: 
    case buf[pos]
    of '/': 
      if buf[pos+1] == '/': 
        # skip line comment:
        inc(pos, 2)
        while true:
          case buf[pos] 
          of '\0': 
            break
          of '\c': 
            pos = lexbase.HandleCR(my, pos)
            buf = my.buf
            break
          of '\L': 
            pos = lexbase.HandleLF(my, pos)
            buf = my.buf
            break
          else:
            inc(pos)
      elif buf[pos+1] == '*':
        # skip long comment:
        inc(pos, 2)
        while true:
          case buf[pos] 
          of '\0': 
            my.err = errEOC_Expected
            break
          of '\c': 
            pos = lexbase.HandleCR(my, pos)
            buf = my.buf
          of '\L': 
            pos = lexbase.HandleLF(my, pos)
            buf = my.buf
          of '*':
            inc(pos)
            if buf[pos] == '/': 
              inc(pos)
              break
          else:
            inc(pos)
      else: 
        break
    of ' ', '\t': 
      Inc(pos)
    of '\c':  
      pos = lexbase.HandleCR(my, pos)
      buf = my.buf
    of '\L': 
      pos = lexbase.HandleLF(my, pos)
      buf = my.buf
    else:
      break
  my.bufpos = pos

proc parseNumber(my: var TJsonParser) = 
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] == '-': 
    add(my.a, '-')
    inc(pos)
  if buf[pos] == '.': 
    add(my.a, "0.")
    inc(pos)
  else:
    while buf[pos] in Digits:
      add(my.a, buf[pos])
      inc(pos)
    if buf[pos] == '.':
      add(my.a, '.')
      inc(pos)
  # digits after the dot:
  while buf[pos] in Digits:
    add(my.a, buf[pos])
    inc(pos)
  if buf[pos] in {'E', 'e'}:
    add(my.a, buf[pos])
    inc(pos)
    if buf[pos] in {'+', '-'}:
      add(my.a, buf[pos])
      inc(pos)
    while buf[pos] in Digits:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc parseName(my: var TJsonParser) = 
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] in IdentStartChars:
    while buf[pos] in IdentChars:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc getTok(my: var TJsonParser): TTokKind = 
  setLen(my.a, 0)
  skip(my) # skip whitespace, comments
  case my.buf[my.bufpos]
  of '-', '.', '0'..'9': 
    parseNumber(my)
    result = tkNumber
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

proc next*(my: var TJsonParser) = 
  ## retrieves the first/next event. This controls the parser.
  var tk = getTok(my)
  var i = my.state.len-1
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
    of tkString, tkNumber, tkTrue, tkFalse, tkNull:
      my.state[i] = stateEof # expect EOF next!
      my.kind = TJsonEventKind(ord(tk))
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
    of tkString, tkNumber, tkTrue, tkFalse, tkNull:
      my.state.add(stateExpectColon)
      my.kind = TJsonEventKind(ord(tk))
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
    of tkString, tkNumber, tkTrue, tkFalse, tkNull:
      my.state.add(stateExpectArrayComma) # expect value next!
      my.kind = TJsonEventKind(ord(tk))
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
    of tkString, tkNumber, tkTrue, tkFalse, tkNull:
      my.state[i] = stateExpectObjectComma
      my.kind = TJsonEventKind(ord(tk))
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
  
when isMainModule:
  import os
  var s = newFileStream(ParamStr(1), fmRead)
  if s == nil: quit("cannot open the file" & ParamStr(1))
  var x: TJsonParser
  open(x, s, ParamStr(1))
  while true:
    next(x)
    case x.kind
    of jsonError:
      Echo(x.errorMsg())
      break
    of jsonEof: break
    of jsonString, jsonNumber: echo(x.str)
    of jsonTrue: Echo("!TRUE")
    of jsonFalse: Echo("!FALSE")
    of jsonNull: Echo("!NULL")
    of jsonObjectStart: Echo("{")
    of jsonObjectEnd: Echo("}")
    of jsonArrayStart: Echo("[")
    of jsonArrayEnd: Echo("]")
    
  close(x)

