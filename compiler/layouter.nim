#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Layouter for nimpretty.

import idents, lexer, lineinfos, llstream, options, msgs, strutils,
  pathutils
from os import changeFileExt

const
  MaxLineLen = 80
  LineCommentColumn = 30

type
  SplitKind = enum
    splitComma, splitParLe, splitAnd, splitOr, splitIn, splitBinary

  SemicolonKind = enum
    detectSemicolonKind, useSemicolon, dontTouch

  LayoutToken = enum
    ltSpaces, ltNewline, ltComment, ltLit, ltKeyword, ltExportMarker, ltIdent,
    ltOther, ltOpr

  Emitter* = object
    config: ConfigRef
    fid: FileIndex
    lastTok: TTokType
    inquote, lastTokWasTerse: bool
    semicolons: SemicolonKind
    col, lastLineNumber, lineSpan, indentLevel, indWidth*: int
    keepIndents*: int
    doIndentMore*: int
    content: string
    kinds: seq[LayoutToken]
    indentStack: seq[int]
    fixedUntil: int # marks where we must not go in the content
    altSplitPos: array[SplitKind, int] # alternative split positions

proc openEmitter*(em: var Emitter, cache: IdentCache;
                  config: ConfigRef, fileIdx: FileIndex) =
  let fullPath = Absolutefile config.toFullPath(fileIdx)
  if em.indWidth == 0:
    em.indWidth = getIndentWidth(fileIdx, llStreamOpen(fullPath, fmRead),
                                cache, config)
    if em.indWidth == 0: em.indWidth = 2
  em.config = config
  em.fid = fileIdx
  em.lastTok = tkInvalid
  em.inquote = false
  em.col = 0
  em.content = newStringOfCap(16_000)
  em.indentStack = newSeqOfCap[int](30)
  em.indentStack.add 0
  em.lastLineNumber = 1

proc closeEmitter*(em: var Emitter) =
  let outFile = em.config.absOutFile
  if fileExists(outFile) and readFile(outFile.string) == em.content:
    discard "do nothing, see #9499"
    return
  var f = llStreamOpen(outFile, fmWrite)
  if f == nil:
    rawMessage(em.config, errGenerated, "cannot open file: " & outFile.string)
    return
  f.llStreamWrite em.content
  llStreamClose(f)

proc countNewlines(s: string): int =
  result = 0
  for i in 0..<s.len:
    if s[i] == '\L': inc result

proc calcCol(em: var Emitter; s: string) =
  var i = s.len-1
  em.col = 0
  while i >= 0 and s[i] != '\L':
    dec i
    inc em.col

proc wr(em: var Emitter; x: string; lt: LayoutToken) =
  em.content.add x
  em.kinds.add lt
  inc em.col, x.len

when false:
  proc wrNewline(em: var Emitter) =
    em.tokens.add "\L"
    em.kinds.add ltNewline
    inc em.tokensSum, 1
    em.col = 0

  proc wrSpaces(em: var Emitter; spaces: Natural) =
    wr(em, strutils.repeat(' ', spaces), ltSpaces)

  proc removeSpaces(em: var Emitter) =
    while em.kinds.len > 0 and em.kinds[^1] == ltSpaces:
      let tokenLen = em.tokens[^1].len
      setLen(em.tokens, em.tokens.len-1)
      setLen(em.kinds, em.kinds.len-1)
      dec em.tokensSum, tokenLen
      dec em.col, tokenLen

template goodCol(col): bool = col in 40..MaxLineLen

const
  openPars = {tkParLe, tkParDotLe,
              tkBracketLe, tkBracketLeColon, tkCurlyDotLe,
              tkCurlyLe}
  splitters = openPars + {tkComma, tkSemicolon}
  oprSet = {tkOpr, tkDiv, tkMod, tkShl, tkShr, tkIn, tkNotin, tkIs,
            tkIsnot, tkNot, tkOf, tkAs, tkDotDot, tkAnd, tkOr, tkXor}

template rememberSplit(kind) =
  if goodCol(em.col):
    em.altSplitPos[kind] = em.content.len

template moreIndent(em): int =
  (if em.doIndentMore > 0: em.indWidth*2 else: em.indWidth)

proc softLinebreak(em: var Emitter, lit: string) =
  # XXX Use an algorithm that is outlined here:
  # https://llvm.org/devmtg/2013-04/jasper-slides.pdf
  # +2 because we blindly assume a comma or ' &' might follow
  if not em.inquote and em.col+lit.len+2 >= MaxLineLen:
    if em.lastTok in splitters:
      # bug #10295, check first if even more indentation would help:
      let spaces = em.indentLevel+moreIndent(em)
      if spaces < em.col:
        while em.content.len > 0 and em.content[em.content.high] == ' ':
          setLen(em.content, em.content.len-1)
        wr(em, "\L", ltNewline)
        em.col = 0
        for i in 1..spaces: wr(em, " ", ltSpaces)
    else:
      # search backwards for a good split position:
      for a in mitems(em.altSplitPos):
        if a > em.fixedUntil:
          var spaces = 0
          while a+spaces < em.content.len and em.content[a+spaces] == ' ':
            inc spaces
          if spaces > 0: delete(em.content, a, a+spaces-1)
          em.col = em.content.len - a
          let ws = "\L" & repeat(' ', em.indentLevel+moreIndent(em))
          em.content.insert(ws, a)
          a = -1
          break

proc emitTok*(em: var Emitter; L: TLexer; tok: TToken) =

  template endsInWhite(em): bool =
    em.content.len == 0 or em.content[em.content.high] in {' ', '\L'}
  template endsInAlpha(em): bool =
    em.content.len > 0 and em.content[em.content.high] in SymChars+{'_'}

  template wasExportMarker(em): bool =
    em.kinds.len > 0 and em.kinds[^1] == ltExportMarker

  proc emitComment(em: var Emitter; tok: TToken) =
    let lit = strip fileSection(em.config, em.fid, tok.commentOffsetA, tok.commentOffsetB)
    em.lineSpan = countNewlines(lit)
    if em.lineSpan > 0: calcCol(em, lit)
    if not endsInWhite(em):
      wr(em, " ", ltSpaces)
      if em.lineSpan == 0 and max(em.col, LineCommentColumn) + lit.len <= MaxLineLen:
        for i in 1 .. LineCommentColumn - em.col: wr(em, " ", ltSpaces)
    wr em, lit, ltComment

  if tok.tokType == tkComment and tok.literal.startsWith("#!nimpretty"):
    case tok.literal
    of "#!nimpretty off":
      inc em.keepIndents
      wr(em, "\L", ltNewline)
      em.lastLineNumber = tok.line + 1
    of "#!nimpretty on":
      dec em.keepIndents
      em.lastLineNumber = tok.line
    wr(em, "\L", ltNewline)
    #for i in 1 .. tok.indent: wr " "
    wr em, tok.literal, ltComment
    em.col = 0
    em.lineSpan = 0
    return

  var preventComment = false
  if tok.tokType == tkComment and tok.line == em.lastLineNumber and tok.indent >= 0:
    # we have an inline comment so handle it before the indentation token:
    emitComment(em, tok)
    preventComment = true
    em.fixedUntil = em.content.high

  elif tok.indent >= 0:
    if em.lastTok in (splitters + oprSet) or em.keepIndents > 0:
      em.indentLevel = tok.indent
    else:
      if tok.indent > em.indentStack[^1]:
        em.indentStack.add tok.indent
      else:
        # dedent?
        while em.indentStack.len > 1 and em.indentStack[^1] > tok.indent:
          discard em.indentStack.pop()
      em.indentLevel = em.indentStack.high * em.indWidth
    #[ we only correct the indentation if it is not in an expression context,
       so that code like

        const splitters = {tkComma, tkSemicolon, tkParLe, tkParDotLe,
                          tkBracketLe, tkBracketLeColon, tkCurlyDotLe,
                          tkCurlyLe}

       is not touched.
    ]#
    # remove trailing whitespace:
    while em.content.len > 0 and em.content[em.content.high] == ' ':
      setLen(em.content, em.content.len-1)
    wr(em, "\L", ltNewline)
    for i in 2..tok.line - em.lastLineNumber: wr(em, "\L", ltNewline)
    em.col = 0
    for i in 1..em.indentLevel:
      wr(em, " ", ltSpaces)
    em.fixedUntil = em.content.high

  var lastTokWasTerse = false
  case tok.tokType
  of tokKeywordLow..tokKeywordHigh:
    if endsInAlpha(em):
      wr(em, " ", ltSpaces)
    elif not em.inquote and not endsInWhite(em) and
        em.lastTok notin openPars and not em.lastTokWasTerse:
      #and tok.tokType in oprSet
      wr(em, " ", ltSpaces)

    if not em.inquote:
      wr(em, TokTypeToStr[tok.tokType], ltKeyword)

      case tok.tokType
      of tkAnd: rememberSplit(splitAnd)
      of tkOr: rememberSplit(splitOr)
      of tkIn, tkNotin:
        rememberSplit(splitIn)
        wr(em, " ", ltSpaces)
      else: discard
    else:
      # keywords in backticks are not normalized:
      wr(em, tok.ident.s, ltIdent)

  of tkColon:
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    wr(em, " ", ltSpaces)
  of tkSemicolon, tkComma:
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    rememberSplit(splitComma)
    wr(em, " ", ltSpaces)
  of tkParDotLe, tkParLe, tkBracketDotLe, tkBracketLe,
     tkCurlyLe, tkCurlyDotLe, tkBracketLeColon:
    if tok.strongSpaceA > 0 and not em.endsInWhite and not em.wasExportMarker:
      wr(em, " ", ltSpaces)
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    rememberSplit(splitParLe)
  of tkParRi,
     tkBracketRi, tkCurlyRi,
     tkBracketDotRi,
     tkCurlyDotRi,
     tkParDotRi,
     tkColonColon:
    wr(em, TokTypeToStr[tok.tokType], ltOther)
  of tkDot:
    lastTokWasTerse = true
    wr(em, TokTypeToStr[tok.tokType], ltOther)
  of tkEquals:
    if not em.inquote and not em.endsInWhite: wr(em, " ", ltSpaces)
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    if not em.inquote: wr(em, " ", ltSpaces)
  of tkOpr, tkDotDot:
    if ((tok.strongSpaceA == 0 and tok.strongSpaceB == 0) or em.inquote) and
      tok.ident.s notin ["<", ">", "<=", ">=", "==", "!="]:
      # bug #9504: remember to not spacify a keyword:
      lastTokWasTerse = true
      # if not surrounded by whitespace, don't produce any whitespace either:
      wr(em, tok.ident.s, ltOpr)
    else:
      if not em.endsInWhite: wr(em, " ", ltSpaces)
      wr(em, tok.ident.s, ltOpr)
      template isUnary(tok): bool =
        tok.strongSpaceB == 0 and tok.strongSpaceA > 0

      if not isUnary(tok):
        rememberSplit(splitBinary)
        wr(em, " ", ltSpaces)
  of tkAccent:
    if not em.inquote and endsInAlpha(em): wr(em, " ", ltSpaces)
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    em.inquote = not em.inquote
  of tkComment:
    if not preventComment:
      emitComment(em, tok)
  of tkIntLit..tkStrLit, tkRStrLit, tkTripleStrLit, tkGStrLit, tkGTripleStrLit, tkCharLit:
    let lit = fileSection(em.config, em.fid, tok.offsetA, tok.offsetB)
    softLinebreak(em, lit)
    if endsInAlpha(em) and tok.tokType notin {tkGStrLit, tkGTripleStrLit}: wr(em, " ", ltSpaces)
    em.lineSpan = countNewlines(lit)
    if em.lineSpan > 0: calcCol(em, lit)
    wr em, lit, ltLit
  of tkEof: discard
  else:
    let lit = if tok.ident != nil: tok.ident.s else: tok.literal
    softLinebreak(em, lit)
    if endsInAlpha(em): wr(em, " ", ltSpaces)
    wr em, lit, ltIdent

  em.lastTok = tok.tokType
  em.lastTokWasTerse = lastTokWasTerse
  em.lastLineNumber = tok.line + em.lineSpan
  em.lineSpan = 0

proc starWasExportMarker*(em: var Emitter) =
  em.kinds[^1] = ltExportMarker
  if em.content.endsWith(" * "):
    setLen(em.content, em.content.len-3)
    em.content.add("*")
    dec em.col, 2

proc commaWasSemicolon*(em: var Emitter) =
  if em.semicolons == detectSemicolonKind:
    em.semicolons = if em.content.endsWith(", "): dontTouch else: useSemicolon
  if em.semicolons == useSemicolon and em.content.endsWith(", "):
    setLen(em.content, em.content.len-2)
    em.content.add("; ")

proc curlyRiWasPragma*(em: var Emitter) =
  if em.content.endsWith("}"):
    setLen(em.content, em.content.len-1)
    em.content.add(".}")
