#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements the dispatcher for the different parsers.

import 
  strutils, llstream, ast, astalgo, idents, lexer, options, msgs, parser, 
  pbraces, filters, filter_tmpl, renderer

type 
  TFilterKind* = enum 
    filtNone, filtTemplate, filtReplace, filtStrip
  TParserKind* = enum 
    skinStandard, skinStrongSpaces, skinBraces, skinEndX

const 
  parserNames*: array[TParserKind, string] = ["standard", "strongspaces",
                                              "braces", "endx"]
  filterNames*: array[TFilterKind, string] = ["none", "stdtmpl", "replace",
                                              "strip"]

type
  TParsers*{.final.} = object 
    skin*: TParserKind
    parser*: TParser


proc parseFile*(fileIdx: int32): PNode{.procvar.}
proc openParsers*(p: var TParsers, fileIdx: int32, inputstream: PLLStream)
proc closeParsers*(p: var TParsers)
proc parseAll*(p: var TParsers): PNode
proc parseTopLevelStmt*(p: var TParsers): PNode
  # implements an iterator. Returns the next top-level statement or nil if end
  # of stream.

# implementation

proc parseFile(fileIdx: int32): PNode =
  var 
    p: TParsers
    f: TFile
  let filename = fileIdx.toFullPath
  if not open(f, filename):
    rawMessage(errCannotOpenFile, filename)
    return 
  openParsers(p, fileIdx, llStreamOpen(f))
  result = parseAll(p)
  closeParsers(p)

proc parseAll(p: var TParsers): PNode = 
  case p.skin
  of skinStandard, skinStrongSpaces:
    result = parser.parseAll(p.parser)
  of skinBraces: 
    result = pbraces.parseAll(p.parser)
  of skinEndX: 
    internalError("parser to implement") 
    result = ast.emptyNode
  
proc parseTopLevelStmt(p: var TParsers): PNode = 
  case p.skin
  of skinStandard, skinStrongSpaces:
    result = parser.parseTopLevelStmt(p.parser)
  of skinBraces: 
    result = pbraces.parseTopLevelStmt(p.parser)
  of skinEndX: 
    internalError("parser to implement") 
    result = ast.emptyNode
  
proc utf8Bom(s: string): int = 
  if (s[0] == '\xEF') and (s[1] == '\xBB') and (s[2] == '\xBF'): 
    result = 3
  else: 
    result = 0
  
proc containsShebang(s: string, i: int): bool = 
  if (s[i] == '#') and (s[i + 1] == '!'): 
    var j = i + 2
    while s[j] in Whitespace: inc(j)
    result = s[j] == '/'

proc parsePipe(filename: string, inputStream: PLLStream): PNode = 
  result = ast.emptyNode
  var s = llStreamOpen(filename, fmRead)
  if s != nil: 
    var line = newStringOfCap(80)
    discard llStreamReadLine(s, line)
    var i = utf8Bom(line)
    if containsShebang(line, i):
      discard llStreamReadLine(s, line)
      i = 0
    if line[i] == '#' and line[i+1] == '!':
      inc(i, 2)
      while line[i] in Whitespace: inc(i)
      var q: TParser
      openParser(q, filename, llStreamOpen(substr(line, i)))
      result = parser.parseAll(q)
      closeParser(q)
    llStreamClose(s)

proc getFilter(ident: PIdent): TFilterKind = 
  for i in countup(low(TFilterKind), high(TFilterKind)): 
    if identEq(ident, filterNames[i]): 
      return i
  result = filtNone

proc getParser(ident: PIdent): TParserKind = 
  for i in countup(low(TParserKind), high(TParserKind)): 
    if identEq(ident, parserNames[i]): 
      return i
  rawMessage(errInvalidDirectiveX, ident.s)

proc getCallee(n: PNode): PIdent = 
  if n.kind in nkCallKinds and n.sons[0].kind == nkIdent: 
    result = n.sons[0].ident
  elif n.kind == nkIdent: 
    result = n.ident
  else: 
    rawMessage(errXNotAllowedHere, renderTree(n))
  
proc applyFilter(p: var TParsers, n: PNode, filename: string, 
                 stdin: PLLStream): PLLStream = 
  var ident = getCallee(n)
  var f = getFilter(ident)
  case f
  of filtNone: 
    p.skin = getParser(ident)
    result = stdin
  of filtTemplate: 
    result = filterTmpl(stdin, filename, n)
  of filtStrip: 
    result = filterStrip(stdin, filename, n)
  of filtReplace: 
    result = filterReplace(stdin, filename, n)
  if f != filtNone: 
    if gVerbosity >= 2: 
      rawMessage(hintCodeBegin, [])
      msgWriteln(result.s)
      rawMessage(hintCodeEnd, [])

proc evalPipe(p: var TParsers, n: PNode, filename: string, 
              start: PLLStream): PLLStream = 
  result = start
  if n.kind == nkEmpty: return 
  if n.kind == nkInfix and n.sons[0].kind == nkIdent and
      identEq(n.sons[0].ident, "|"):
    for i in countup(1, 2):
      if n.sons[i].kind == nkInfix:
        result = evalPipe(p, n.sons[i], filename, result)
      else:
        result = applyFilter(p, n.sons[i], filename, result)
  elif n.kind == nkStmtList:
    result = evalPipe(p, n.sons[0], filename, result)
  else:
    result = applyFilter(p, n, filename, result)
  
proc openParsers(p: var TParsers, fileIdx: int32, inputstream: PLLStream) = 
  var s: PLLStream
  p.skin = skinStandard
  let filename = fileIdx.toFullPath
  var pipe = parsePipe(filename, inputstream)
  if pipe != nil: s = evalPipe(p, pipe, filename, inputstream)
  else: s = inputstream
  case p.skin
  of skinStandard, skinBraces, skinEndX:
    parser.openParser(p.parser, fileIdx, s, false)
  of skinStrongSpaces:
    parser.openParser(p.parser, fileIdx, s, true)
  
proc closeParsers(p: var TParsers) =
  parser.closeParser(p.parser)
