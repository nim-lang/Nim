#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Nimrod's standard template filter.

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
    subsChar, NimDirective: Char
    emit, conc, toStr: string
    curly, bracket, par: int
    pendingExprLine: bool


const
  PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '.', '_'}

proc newLine(p: var TTmplParser) =
  LLStreamWrite(p.outp, repeatChar(p.emitPar, ')'))
  p.emitPar = 0
  if p.info.line > int16(1): LLStreamWrite(p.outp, "\n")
  if p.pendingExprLine:
    LLStreamWrite(p.outp, repeatChar(2))
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
    else: nil
    inc(i)

proc withInExpr(p: TTmplParser): bool {.inline.} =
  result = p.par > 0 or p.bracket > 0 or p.curly > 0

proc parseLine(p: var TTmplParser) =
  var
    d, j, curly: int
    keyw: string
  j = 0
  while p.x[j] == ' ': inc(j)
  if (p.x[0] == p.NimDirective) and (p.x[0 + 1] == '!'):
    newLine(p)
  elif (p.x[j] == p.NimDirective):
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
        LocalError(p.info, errXNotAllowedHere, "end")
      LLStreamWrite(p.outp, repeatChar(p.indent))
      LLStreamWrite(p.outp, "#end")
    of wIf, wWhen, wTry, wWhile, wFor, wBlock, wCase, wProc, wIterator,
       wConverter, wMacro, wTemplate, wMethod:
      LLStreamWrite(p.outp, repeatChar(p.indent))
      LLStreamWrite(p.outp, substr(p.x, d))
      inc(p.indent, 2)
    of wElif, wOf, wElse, wExcept, wFinally:
      LLStreamWrite(p.outp, repeatChar(p.indent - 2))
      LLStreamWrite(p.outp, substr(p.x, d))
    of wLet, wVar, wConst, wType:
      LLStreamWrite(p.outp, repeatChar(p.indent))
      LLStreamWrite(p.outp, substr(p.x, d))
      if not p.x.contains({':', '='}):
        # no inline element --> treat as block:
        inc(p.indent, 2)
    else:
      LLStreamWrite(p.outp, repeatChar(p.indent))
      LLStreamWrite(p.outp, substr(p.x, d))
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
      LLStreamWrite(p.outp, p.conc)
      LLStreamWrite(p.outp, "\n")
      LLStreamWrite(p.outp, repeatChar(p.indent + 2))
      LLStreamWrite(p.outp, "\"")
    of psDirective:
      newLine(p)
      LLStreamWrite(p.outp, repeatChar(p.indent))
      LLStreamWrite(p.outp, p.emit)
      LLStreamWrite(p.outp, "(\"")
      inc(p.emitPar)
    p.state = psTempl
    while true:
      case p.x[j]
      of '\0':
        break
      of '\x01'..'\x1F', '\x80'..'\xFF':
        LLStreamWrite(p.outp, "\\x")
        LLStreamWrite(p.outp, toHex(ord(p.x[j]), 2))
        inc(j)
      of '\\':
        LLStreamWrite(p.outp, "\\\\")
        inc(j)
      of '\'':
        LLStreamWrite(p.outp, "\\\'")
        inc(j)
      of '\"':
        LLStreamWrite(p.outp, "\\\"")
        inc(j)
      else:
        if p.x[j] == p.subsChar:
          # parse Nimrod expression:
          inc(j)
          case p.x[j]
          of '{':
            p.info.col = int16(j)
            LLStreamWrite(p.outp, '\"')
            LLStreamWrite(p.outp, p.conc)
            LLStreamWrite(p.outp, p.toStr)
            LLStreamWrite(p.outp, '(')
            inc(j)
            curly = 0
            while true:
              case p.x[j]
              of '\0':
                LocalError(p.info, errXExpected, "}")
                break
              of '{':
                inc(j)
                inc(curly)
                LLStreamWrite(p.outp, '{')
              of '}':
                inc(j)
                if curly == 0: break
                if curly > 0: dec(curly)
                LLStreamWrite(p.outp, '}')
              else:
                LLStreamWrite(p.outp, p.x[j])
                inc(j)
            LLStreamWrite(p.outp, ')')
            LLStreamWrite(p.outp, p.conc)
            LLStreamWrite(p.outp, '\"')
          of 'a'..'z', 'A'..'Z', '\x80'..'\xFF':
            LLStreamWrite(p.outp, '\"')
            LLStreamWrite(p.outp, p.conc)
            LLStreamWrite(p.outp, p.toStr)
            LLStreamWrite(p.outp, '(')
            while p.x[j] in PatternChars:
              LLStreamWrite(p.outp, p.x[j])
              inc(j)
            LLStreamWrite(p.outp, ')')
            LLStreamWrite(p.outp, p.conc)
            LLStreamWrite(p.outp, '\"')
          else:
            if p.x[j] == p.subsChar:
              LLStreamWrite(p.outp, p.subsChar)
              inc(j)
            else:
              p.info.col = int16(j)
              LocalError(p.info, errInvalidExpression, "$")
        else:
          LLStreamWrite(p.outp, p.x[j])
          inc(j)
    LLStreamWrite(p.outp, "\\n\"")

proc filterTmpl(stdin: PLLStream, filename: string, call: PNode): PLLStream =
  var p: TTmplParser
  p.info = newLineInfo(filename, 0, 0)
  p.outp = LLStreamOpen("")
  p.inp = stdin
  p.subsChar = charArg(call, "subschar", 1, '$')
  p.nimDirective = charArg(call, "metachar", 2, '#')
  p.emit = strArg(call, "emit", 3, "result.add")
  p.conc = strArg(call, "conc", 4, " & ")
  p.toStr = strArg(call, "tostring", 5, "$")
  p.x = newStringOfCap(120)
  while LLStreamReadLine(p.inp, p.x):
    p.info.line = p.info.line + int16(1)
    parseLine(p)
  newLine(p)
  result = p.outp
  LLStreamClose(p.inp)
