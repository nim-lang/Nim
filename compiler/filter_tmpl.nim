#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Nim's standard template filter.

import 
  llstream, os, wordrecg, idents, strutils, ast, astalgo, msgs, options, 
  renderer, filters

proc filterTmpl*(stdin: PLLStream, filename: string, call: PNode): PLLStream
  # #! template(subsChar='$', metaChar='#') | standard(version="0.7.2")
# implementation

type 
  TParseState = enum 
    psDirective, psTempl
  TTmplParser{.final.} = object 
    inp: PLLStream
    state: TParseState
    info: TLineInfo
    indent, emitPar: int
    x: string                # the current input line
    outp: PLLStream          # the ouput will be parsed by pnimsyn
    subsChar, nimDirective: char
    emit, conc, toStr: string
    curly, bracket, par: int
    pendingExprLine: bool


const 
  PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '.', '_'}

proc newLine(p: var TTmplParser) = 
  llStreamWrite(p.outp, repeat(')', p.emitPar))
  p.emitPar = 0
  if p.info.line > int16(1): llStreamWrite(p.outp, "\n")
  if p.pendingExprLine:
    llStreamWrite(p.outp, spaces(2))
    p.pendingExprLine = false
  
proc scanPar(p: var TTmplParser, d: int) = 
  var i = d
  while true:
    case p.x[i]
    of '\0': break
    of '(': inc(p.par)
    of ')': dec(p.par)
    of '[': inc(p.bracket)
    of ']': dec(p.bracket)
    of '{': inc(p.curly)
    of '}': dec(p.curly)
    else: discard
    inc(i)

proc withInExpr(p: TTmplParser): bool {.inline.} = 
  result = p.par > 0 or p.bracket > 0 or p.curly > 0
  
proc parseLine(p: var TTmplParser) = 
  var 
    d, j, curly: int
    keyw: string
  j = 0
  while p.x[j] == ' ': inc(j)
  if (p.x[0] == p.nimDirective) and (p.x[0 + 1] == '!'): 
    newLine(p)
  elif (p.x[j] == p.nimDirective): 
    newLine(p)
    inc(j)
    while p.x[j] == ' ': inc(j)
    d = j
    keyw = ""
    while p.x[j] in PatternChars: 
      add(keyw, p.x[j])
      inc(j)
    
    scanPar(p, j)
    p.pendingExprLine = withInExpr(p) or llstream.endsWithOpr(p.x)
    case whichKeyword(keyw)
    of wEnd: 
      if p.indent >= 2: 
        dec(p.indent, 2)
      else: 
        p.info.col = int16(j)
        localError(p.info, errXNotAllowedHere, "end")
      llStreamWrite(p.outp, spaces(p.indent))
      llStreamWrite(p.outp, "#end")
    of wIf, wWhen, wTry, wWhile, wFor, wBlock, wCase, wProc, wIterator, 
       wConverter, wMacro, wTemplate, wMethod: 
      llStreamWrite(p.outp, spaces(p.indent))
      llStreamWrite(p.outp, substr(p.x, d))
      inc(p.indent, 2)
    of wElif, wOf, wElse, wExcept, wFinally: 
      llStreamWrite(p.outp, spaces(p.indent - 2))
      llStreamWrite(p.outp, substr(p.x, d))
    of wLet, wVar, wConst, wType:
      llStreamWrite(p.outp, spaces(p.indent))
      llStreamWrite(p.outp, substr(p.x, d))
      if not p.x.contains({':', '='}):
        # no inline element --> treat as block:
        inc(p.indent, 2)
    else:
      llStreamWrite(p.outp, spaces(p.indent))
      llStreamWrite(p.outp, substr(p.x, d))
    p.state = psDirective
  else: 
    # data line
    # reset counters
    p.par = 0
    p.curly = 0
    p.bracket = 0
    j = 0
    case p.state
    of psTempl: 
      # next line of string literal:
      llStreamWrite(p.outp, p.conc)
      llStreamWrite(p.outp, "\n")
      llStreamWrite(p.outp, spaces(p.indent + 2))
      llStreamWrite(p.outp, "\"")
    of psDirective: 
      newLine(p)
      llStreamWrite(p.outp, spaces(p.indent))
      llStreamWrite(p.outp, p.emit)
      llStreamWrite(p.outp, "(\"")
      inc(p.emitPar)
    p.state = psTempl
    while true: 
      case p.x[j]
      of '\0': 
        break 
      of '\x01'..'\x1F', '\x80'..'\xFF': 
        llStreamWrite(p.outp, "\\x")
        llStreamWrite(p.outp, toHex(ord(p.x[j]), 2))
        inc(j)
      of '\\': 
        llStreamWrite(p.outp, "\\\\")
        inc(j)
      of '\'': 
        llStreamWrite(p.outp, "\\\'")
        inc(j)
      of '\"': 
        llStreamWrite(p.outp, "\\\"")
        inc(j)
      else: 
        if p.x[j] == p.subsChar: 
          # parse Nim expression:
          inc(j)
          case p.x[j]
          of '{': 
            p.info.col = int16(j)
            llStreamWrite(p.outp, '\"')
            llStreamWrite(p.outp, p.conc)
            llStreamWrite(p.outp, p.toStr)
            llStreamWrite(p.outp, '(')
            inc(j)
            curly = 0
            while true: 
              case p.x[j]
              of '\0': 
                localError(p.info, errXExpected, "}")
                break
              of '{': 
                inc(j)
                inc(curly)
                llStreamWrite(p.outp, '{')
              of '}': 
                inc(j)
                if curly == 0: break 
                if curly > 0: dec(curly)
                llStreamWrite(p.outp, '}')
              else: 
                llStreamWrite(p.outp, p.x[j])
                inc(j)
            llStreamWrite(p.outp, ')')
            llStreamWrite(p.outp, p.conc)
            llStreamWrite(p.outp, '\"')
          of 'a'..'z', 'A'..'Z', '\x80'..'\xFF': 
            llStreamWrite(p.outp, '\"')
            llStreamWrite(p.outp, p.conc)
            llStreamWrite(p.outp, p.toStr)
            llStreamWrite(p.outp, '(')
            while p.x[j] in PatternChars: 
              llStreamWrite(p.outp, p.x[j])
              inc(j)
            llStreamWrite(p.outp, ')')
            llStreamWrite(p.outp, p.conc)
            llStreamWrite(p.outp, '\"')
          else: 
            if p.x[j] == p.subsChar: 
              llStreamWrite(p.outp, p.subsChar)
              inc(j)
            else: 
              p.info.col = int16(j)
              localError(p.info, errInvalidExpression, "$")
        else: 
          llStreamWrite(p.outp, p.x[j])
          inc(j)
    llStreamWrite(p.outp, "\\n\"")

proc filterTmpl(stdin: PLLStream, filename: string, call: PNode): PLLStream = 
  var p: TTmplParser
  p.info = newLineInfo(filename, 0, 0)
  p.outp = llStreamOpen("")
  p.inp = stdin
  p.subsChar = charArg(call, "subschar", 1, '$')
  p.nimDirective = charArg(call, "metachar", 2, '#')
  p.emit = strArg(call, "emit", 3, "result.add")
  p.conc = strArg(call, "conc", 4, " & ")
  p.toStr = strArg(call, "tostring", 5, "$")
  p.x = newStringOfCap(120)
  while llStreamReadLine(p.inp, p.x):
    p.info.line = p.info.line + int16(1)
    parseLine(p)
  newLine(p)
  result = p.outp
  llStreamClose(p.inp)
