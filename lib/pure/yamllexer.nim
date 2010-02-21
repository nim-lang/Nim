#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `YAML`:idx:
## lexer. This is used by the ``yamlparser`` module, but it can be useful
## to avoid ``yamlparser`` for its overhead. 

import 
  hashes, strutils, lexbase, streams, unicode

type 
  TTokenKind* = enum ## YAML tokens
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

  TYamlLexer* = object of TBaseLexer ## the lexer object.
    a: string
    kind: TJsonEventKind
    err: TJsonError
    state: seq[TParserState]
    filename: string
 
proc open*(my: var TYamlLexer, input: PStream, filename: string) =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages.
  lexbase.open(my, input)
  my.filename = filename
  my.state = @[stateNormal]
  my.kind = jsonError
  my.a = ""
  
proc close*(my: var TYamlLexer) {.inline.} = 
  ## closes the parser `my` and its associated input stream.
  lexbase.close(my)

proc getColumn*(my: TYamlLexer): int {.inline.} = 
  ## get the current column the parser has arrived at.
  result = getColNumber(my, my.bufPos)

proc getLine*(my: TYamlLexer): int {.inline.} = 
  ## get the current line the parser has arrived at.
  result = my.linenumber

proc getFilename*(my: TYamlLexer): string {.inline.} = 
  ## get the filename of the file that the parser processes.
  result = my.filename
  
proc handleHexChar(c: Char, x: var TRune): bool = 
  result = true # Success
  case c
  of '0'..'9': x = (x shl 4) or (ord(c) - ord('0'))
  of 'a'..'f': x = (x shl 4) or (ord(c) - ord('a') + 10)
  of 'A'..'F': x = (x shl 4) or (ord(c) - ord('A') + 10)
  else: result = false # error

proc parseString(my: var TYamlLexer): TTokKind =
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
        var r: TRune
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        if handleHexChar(buf[pos], r): inc(pos)
        add(my.a, toUTF8(r))
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
  
proc skip(my: var TYamlLexer) = 
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

proc parseNumber(my: var TYamlLexer) = 
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

proc parseName(my: var TYamlLexer) = 
  var pos = my.bufpos
  var buf = my.buf
  if buf[pos] in IdentStartChars:
    while buf[pos] in IdentChars:
      add(my.a, buf[pos])
      inc(pos)
  my.bufpos = pos

proc getTok(my: var TYamlLexer): TTokKind = 
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
  
when isMainModule:
  import os
  var s = newFileStream(ParamStr(1), fmRead)
  if s == nil: quit("cannot open the file" & ParamStr(1))
  var x: TYamlLexer
  open(x, s, ParamStr(1))
  while true:
    next(x)
    case x.kind
    of jsonError: Echo(x.errorMsg())
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

