#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements the dispatcher for the different parsers.

import
  strutils, llstream, ast, astalgo, idents, lexer, options, msgs, parser,
  filters, filter_tmpl, renderer, lineinfos, pathutils

type
  TFilterKind* = enum
    filtNone, filtTemplate, filtReplace, filtStrip
  TParserKind* = enum
    skinStandard, skinEndX

const
  parserNames*: array[TParserKind, string] = ["standard",
                                              "endx"]
  filterNames*: array[TFilterKind, string] = ["none", "stdtmpl", "replace",
                                              "strip"]

type
  TParsers* = object
    skin*: TParserKind
    parser*: TParser

template config(p: TParsers): ConfigRef = p.parser.lex.config

proc parseAll*(p: var TParsers): PNode =
  case p.skin
  of skinStandard:
    result = parser.parseAll(p.parser)
  of skinEndX:
    internalError(p.config, "parser to implement")

proc parseTopLevelStmt*(p: var TParsers): PNode =
  case p.skin
  of skinStandard:
    result = parser.parseTopLevelStmt(p.parser)
  of skinEndX:
    internalError(p.config, "parser to implement")

proc utf8Bom(s: string): int =
  if s.len >= 3 and s[0] == '\xEF' and s[1] == '\xBB' and s[2] == '\xBF':
    result = 3
  else:
    result = 0

proc containsShebang(s: string, i: int): bool =
  if i+1 < s.len and s[i] == '#' and s[i+1] == '!':
    var j = i + 2
    while j < s.len and s[j] in Whitespace: inc(j)
    result = s[j] == '/'

proc parsePipe(filename: AbsoluteFile, inputStream: PLLStream; cache: IdentCache;
               config: ConfigRef): PNode =
  result = newNode(nkEmpty)
  var s = llStreamOpen(filename, fmRead)
  if s != nil:
    var line = newStringOfCap(80)
    discard llStreamReadLine(s, line)
    var i = utf8Bom(line)
    var linenumber = 1
    if containsShebang(line, i):
      discard llStreamReadLine(s, line)
      i = 0
      inc linenumber
    if i+1 < line.len and line[i] == '#' and line[i+1] == '?':
      when defined(nimpretty2):
        # XXX this is a bit hacky, but oh well...
        quit "can't nimpretty a source code filter"
      else:
        inc(i, 2)
        while i < line.len and line[i] in Whitespace: inc(i)
        var q: TParser
        parser.openParser(q, filename, llStreamOpen(substr(line, i)), cache, config)
        result = parser.parseAll(q)
        parser.closeParser(q)
    llStreamClose(s)

proc getFilter(ident: PIdent): TFilterKind =
  for i in low(TFilterKind) .. high(TFilterKind):
    if cmpIgnoreStyle(ident.s, filterNames[i]) == 0:
      return i
  result = filtNone

proc getParser(conf: ConfigRef; n: PNode; ident: PIdent): TParserKind =
  for i in low(TParserKind) .. high(TParserKind):
    if cmpIgnoreStyle(ident.s, parserNames[i]) == 0:
      return i
  localError(conf, n.info, "unknown parser: " & ident.s)

proc getCallee(conf: ConfigRef; n: PNode): PIdent =
  if n.kind in nkCallKinds and n.sons[0].kind == nkIdent:
    result = n.sons[0].ident
  elif n.kind == nkIdent:
    result = n.ident
  else:
    localError(conf, n.info, "invalid filter: " & renderTree(n))

proc applyFilter(p: var TParsers, n: PNode, filename: AbsoluteFile,
                 stdin: PLLStream): PLLStream =
  var ident = getCallee(p.config, n)
  var f = getFilter(ident)
  case f
  of filtNone:
    p.skin = getParser(p.config, n, ident)
    result = stdin
  of filtTemplate:
    result = filterTmpl(stdin, filename, n, p.config)
  of filtStrip:
    result = filterStrip(p.config, stdin, filename, n)
  of filtReplace:
    result = filterReplace(p.config, stdin, filename, n)
  if f != filtNone:
    assert p.config != nil
    if hintCodeBegin in p.config.notes:
      rawMessage(p.config, hintCodeBegin, [])
      msgWriteln(p.config, result.s)
      rawMessage(p.config, hintCodeEnd, [])

proc evalPipe(p: var TParsers, n: PNode, filename: AbsoluteFile,
              start: PLLStream): PLLStream =
  assert p.config != nil
  result = start
  if n.kind == nkEmpty: return
  if n.kind == nkInfix and n[0].kind == nkIdent and n[0].ident.s == "|":
    for i in 1 .. 2:
      if n.sons[i].kind == nkInfix:
        result = evalPipe(p, n.sons[i], filename, result)
      else:
        result = applyFilter(p, n.sons[i], filename, result)
  elif n.kind == nkStmtList:
    result = evalPipe(p, n.sons[0], filename, result)
  else:
    result = applyFilter(p, n, filename, result)

proc openParsers*(p: var TParsers, fileIdx: FileIndex, inputstream: PLLStream;
                  cache: IdentCache; config: ConfigRef) =
  assert config != nil
  var s: PLLStream
  p.skin = skinStandard
  let filename = toFullPathConsiderDirty(config, fileIdx)
  var pipe = parsePipe(filename, inputstream, cache, config)
  p.config() = config
  if pipe != nil: s = evalPipe(p, pipe, filename, inputstream)
  else: s = inputstream
  case p.skin
  of skinStandard, skinEndX:
    parser.openParser(p.parser, fileIdx, s, cache, config)

proc closeParsers*(p: var TParsers) =
  parser.closeParser(p.parser)

proc setupParsers*(p: var TParsers; fileIdx: FileIndex; cache: IdentCache;
                   config: ConfigRef): bool =
  var f: File
  let filename = toFullPathConsiderDirty(config, fileIdx)
  if not open(f, filename.string):
    rawMessage(config, errGenerated, "cannot open file: " & filename.string)
    return false
  openParsers(p, fileIdx, llStreamOpen(f), cache, config)
  result = true

proc parseFile*(fileIdx: FileIndex; cache: IdentCache; config: ConfigRef): PNode {.procvar.} =
  var p: TParsers
  if setupParsers(p, fileIdx, cache, config):
    result = parseAll(p)
    closeParsers(p)
