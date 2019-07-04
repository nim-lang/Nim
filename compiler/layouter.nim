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
from sequtils import delete

const
  MaxLineLen = 80
  MinLineLen = 10

type
  SplitKind = enum
    splitComma, splitParLe, splitAnd, splitOr, splitIn, splitBinary

  SemicolonKind = enum
    detectSemicolonKind, useSemicolon, dontTouch

  LayoutToken = enum
    ltSpaces,
    ltCrucialNewline, ## a semantically crucial newline (indentation!)
    ltSplittingNewline, ## newline used for splitting up long
                        ## expressions (like after a comma or a binary operator)
    ltTab,
    ltOptionalNewline, ## optional newline introduced by nimpretty
    ltComment, ltLit, ltKeyword, ltExportMarker, ltIdent,
    ltOther, ltOpr,
    ltBeginSection, ltEndSection

  Emitter* = object
    config: ConfigRef
    fid: FileIndex
    lastTok: TTokType
    inquote, lastTokWasTerse: bool
    semicolons: SemicolonKind
    col, lastLineNumber, lineSpan, indentLevel, indWidth*: int
    keepIndents*: int
    doIndentMore*: int
    kinds: seq[LayoutToken]
    tokens: seq[string]
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
  em.indentStack = newSeqOfCap[int](30)
  em.indentStack.add 0
  em.lastLineNumber = 1

proc computeMax(em: Emitter; pos: int): int =
  var p = pos
  result = 0
  while p < em.tokens.len and em.kinds[p] != ltEndSection:
    var lhs = 0
    var lineLen = 0
    var foundTab = false
    while p < em.tokens.len and em.kinds[p] != ltEndSection:
      if em.kinds[p] in {ltCrucialNewline, ltSplittingNewline}:
        if foundTab and lineLen <= MaxLineLen: result = max(result, lhs+1)
        inc p
        break
      if em.kinds[p] == ltTab:
        foundTab = true
      else:
        if not foundTab:
          inc lhs, em.tokens[p].len
        inc lineLen, em.tokens[p].len
      inc p

proc computeRhs(em: Emitter; pos: int): int =
  var p = pos
  result = 0
  while p < em.tokens.len and em.kinds[p] notin {ltCrucialNewline, ltSplittingNewline}:
    inc result, em.tokens[p].len
    inc p

proc isLongEnough(lineLen, startPos, endPos: int): bool =
  result = lineLen > MinLineLen and endPos > startPos + 4

proc findNewline(em: Emitter; p, lineLen: var int) =
  while p < em.tokens.len and em.kinds[p] notin {ltCrucialNewline, ltSplittingNewline}:
    inc lineLen, em.tokens[p].len
    inc p

proc optionalIsGood(em: var Emitter; pos: int): bool =
  let ourIndent = em.tokens[pos].len
  var p = pos+1
  var lineLen = 0
  em.findNewline(p, lineLen)
  if p+1 < em.tokens.len and em.kinds[p+1] == ltSpaces and
      em.kinds[p-1] == ltOptionalNewline:
    if em.tokens[p+1].len == ourIndent:
      # concatenate lines with the same indententation
      var nlPos = p
      var lineLenTotal = lineLen
      inc p
      em.findNewline(p, lineLenTotal)
      if isLongEnough(lineLenTotal, nlPos, p):
        em.kinds[nlPos] = ltOptionalNewline
        if em.kinds[nlPos+1] == ltSpaces:
          # inhibit extra spaces when concatenating two lines
          em.tokens[nlPos+1] = if em.tokens[nlPos-2] == ",": " " else: ""
      result = true
    elif em.tokens[p+1].len < ourIndent:
      result = isLongEnough(lineLen, pos, p)
  elif em.kinds[pos+1] == ltOther: # note: pos+1, not p+1
    result = false
  else:
    result = isLongEnough(lineLen, pos, p)

proc lenOfNextTokens(em: Emitter; pos: int): int =
  result = 0
  for i in 1 ..< em.tokens.len-pos:
    if em.kinds[pos+i] in {ltCrucialNewline, ltSplittingNewline, ltOptionalNewline}: break
    inc result, em.tokens[pos+i].len

proc closeEmitter*(em: var Emitter) =
  let outFile = em.config.absOutFile

  var content = newStringOfCap(16_000)
  var maxLhs = 0
  var lineLen = 0
  var lineBegin = 0
  var i = 0
  while i <= em.tokens.high:
    when defined(debug):
      echo "i-th token ", em.kinds[i], " ", em.tokens[i]
    case em.kinds[i]
    of ltBeginSection:
      maxLhs = computeMax(em, lineBegin)
    of ltEndSection:
      maxLhs = 0
      lineBegin = i+1
    of ltTab:
      if i >= 2 and em.kinds[i-2] in {ltCrucialNewline, ltSplittingNewline} and
          em.kinds[i-1] in {ltCrucialNewline, ltSplittingNewline, ltSpaces}:
        # a previous section has ended
        maxLhs = 0

      if maxLhs == 0:
        content.add em.tokens[i]
        inc lineLen, em.tokens[i].len
      else:
        # pick the shorter indentation token:
        var spaces = maxLhs - lineLen
        if spaces < em.tokens[i].len or computeRhs(em, i+1)+maxLhs <= MaxLineLen:
          if spaces <= 0 and content[^1] notin {' ', '\L'}: spaces = 1
          for j in 1..spaces: content.add ' '
          inc lineLen, spaces
        else:
          content.add em.tokens[i]
          inc lineLen, em.tokens[i].len
    of ltCrucialNewline, ltSplittingNewline:
      content.add em.tokens[i]
      lineLen = 0
      lineBegin = i+1
    of ltOptionalNewline:
      let totalLineLen = lineLen + lenOfNextTokens(em, i)
      if totalLineLen > MaxLineLen + MinLineLen or
         totalLineLen > MaxLineLen and optionalIsGood(em, i):
        if i-1 >= 0 and em.kinds[i-1] == ltSpaces:
          let spaces = em.tokens[i-1].len
          content.setLen(content.len - spaces)
        content.add "\L"
        content.add em.tokens[i]
        lineLen = em.tokens[i].len
        lineBegin = i+1
        if i+1 < em.kinds.len and em.kinds[i+1] == ltSpaces:
          # inhibit extra spaces at the start of a new line
          inc i
    else:
      content.add em.tokens[i]
      inc lineLen, em.tokens[i].len
    inc i

  if fileExists(outFile) and readFile(outFile.string) == content:
    discard "do nothing, see #9499"
    return
  var f = llStreamOpen(outFile, fmWrite)
  if f == nil:
    rawMessage(em.config, errGenerated, "cannot open file: " & outFile.string)
    return
  f.llStreamWrite content
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
  em.tokens.add x
  em.kinds.add lt
  inc em.col, x.len
  assert em.tokens.len == em.kinds.len

proc wrNewline(em: var Emitter; kind = ltCrucialNewline) =
  em.tokens.add "\L"
  em.kinds.add kind
  em.col = 0

proc newlineWasSplitting*(em: var Emitter) =
  if em.kinds.len >= 3 and em.kinds[^3] == ltCrucialNewline:
    em.kinds[^3] = ltSplittingNewline

#[
Splitting newlines can occur:
- after commas, semicolon, '[', '('.
- after binary operators, '='.
- after ':' type

We only need parser support for the "after type" case.
]#

proc wrSpaces(em: var Emitter; spaces: int) =
  if spaces > 0:
    wr(em, strutils.repeat(' ', spaces), ltSpaces)

proc wrSpace(em: var Emitter) =
  wr(em, " ", ltSpaces)

proc wrTab(em: var Emitter) =
  wr(em, " ", ltTab)

proc beginSection*(em: var Emitter) =
  em.tokens.insert "", em.tokens.len-2
  em.kinds.insert ltBeginSection, em.kinds.len-2

#wr(em, "", ltBeginSection)
proc endSection*(em: var Emitter) =
  em.tokens.insert "", em.tokens.len-2
  em.kinds.insert ltEndSection, em.kinds.len-2

#wr(em, "", ltEndSection)

proc removeSpaces(em: var Emitter) =
  while em.kinds.len > 0 and em.kinds[^1] == ltSpaces:
    let tokenLen = em.tokens[^1].len
    setLen(em.tokens, em.tokens.len-1)
    setLen(em.kinds, em.kinds.len-1)
    dec em.col, tokenLen


const
  openPars = {tkParLe, tkParDotLe,
              tkBracketLe, tkBracketLeColon, tkCurlyDotLe,
              tkCurlyLe}
  closedPars = {tkParRi, tkParDotRi,
              tkBracketRi, tkCurlyDotRi,
              tkCurlyRi}

  splitters = openPars + {tkComma, tkSemicolon} # do not add 'tkColon' here!
  oprSet = {tkOpr, tkDiv, tkMod, tkShl, tkShr, tkIn, tkNotin, tkIs,
            tkIsnot, tkNot, tkOf, tkAs, tkDotDot, tkAnd, tkOr, tkXor}

template goodCol(col): bool = col >= MaxLineLen div 2

template moreIndent(em): int =
  if em.doIndentMore > 0: em.indWidth*2 else: em.indWidth

template rememberSplit(kind) =
  if goodCol(em.col) and not em.inquote:
    let spaces = em.indentLevel+moreIndent(em)
    if spaces < em.col and spaces > 0:
      wr(em, strutils.repeat(' ', spaces), ltOptionalNewline)
    #em.altSplitPos[kind] = em.tokens.len

proc emitMultilineComment(em: var Emitter, lit: string, col: int) =
  # re-align every line in the multi-line comment:
  var i = 0
  var lastIndent = em.indentStack[^1]
  var b = 0
  for commentLine in splitLines(lit):
    let stripped = commentLine.strip()
    var a = 0
    while a < commentLine.len and commentLine[a] == ' ': inc a
    if i == 0:
      if em.kinds.len > 0 and em.kinds[^1] != ltTab:
        wr(em, "", ltTab)
    elif stripped.len == 0:
      wrNewline em
    else:
      if a > lastIndent:
        b += em.indWidth
        lastIndent = a
      elif a < lastIndent:
        b -= em.indWidth
        lastIndent = a
      wrNewline em
      #wrSpaces em, col + b
      if col + b > 0:
        wr(em, repeat(' ', col+b), ltTab)
      else:
        wr(em, "", ltTab)
    wr em, stripped, ltComment
    inc i

proc lastChar(s: string): char =
  result = if s.len > 0: s[s.high] else: '\0'

proc endsInWhite(em: Emitter): bool =
  var i = em.tokens.len-1
  while i >= 0 and em.kinds[i] in {ltBeginSection, ltEndSection}: dec(i)
  result = if i >= 0: em.kinds[i] in {ltSpaces, ltCrucialNewline, ltSplittingNewline, ltTab} else: true

proc endsInNewline(em: Emitter): bool =
  var i = em.tokens.len-1
  while i >= 0 and em.kinds[i] in {ltBeginSection, ltEndSection, ltSpaces}: dec(i)
  result = if i >= 0: em.kinds[i] in {ltCrucialNewline, ltSplittingNewline, ltTab} else: true

proc endsInAlpha(em: Emitter): bool =
  var i = em.tokens.len-1
  while i >= 0 and em.kinds[i] in {ltBeginSection, ltEndSection}: dec(i)
  result = if i >= 0: em.tokens[i].lastChar in SymChars+{'_'} else: false

proc emitComment(em: var Emitter; tok: TToken) =
  let col = em.col
  let lit = strip fileSection(em.config, em.fid, tok.commentOffsetA, tok.commentOffsetB)
  em.lineSpan = countNewlines(lit)
  if em.lineSpan > 0: calcCol(em, lit)
  if em.lineSpan == 0:
    if not endsInNewline(em):
      wrTab em
    wr em, lit, ltComment
  else:
    if not endsInWhite(em):
      wrTab em
    emitMultilineComment(em, lit, col)

proc emitTok*(em: var Emitter; L: TLexer; tok: TToken) =
  template wasExportMarker(em): bool =
    em.kinds.len > 0 and em.kinds[^1] == ltExportMarker

  if tok.tokType == tkComment and tok.literal.startsWith("#!nimpretty"):
    case tok.literal
    of "#!nimpretty off":
      inc em.keepIndents
      wrNewline em
      em.lastLineNumber = tok.line + 1
    of "#!nimpretty on":
      dec em.keepIndents
      em.lastLineNumber = tok.line
    wrNewline em
    wr em, tok.literal, ltComment
    em.col = 0
    em.lineSpan = 0
    return

  var preventComment = false
  if tok.tokType == tkComment and tok.line == em.lastLineNumber and tok.indent >= 0:
    # we have an inline comment so handle it before the indentation token:
    emitComment(em, tok)
    preventComment = true
    em.fixedUntil = em.tokens.high

  elif tok.indent >= 0:
    var newlineKind = ltCrucialNewline
    if em.keepIndents > 0:
      em.indentLevel = tok.indent
    elif (em.lastTok in (splitters + oprSet) and tok.tokType notin closedPars):
      # aka: we are in an expression context:
      let alignment = max(tok.indent - em.indentStack[^1], 0)
      em.indentLevel = alignment + em.indentStack.high * em.indWidth
      newlineKind = ltSplittingNewline
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
    removeSpaces em
    wrNewline em, newlineKind
    for i in 2..tok.line - em.lastLineNumber: wrNewline(em)
    wrSpaces em, em.indentLevel
    em.fixedUntil = em.tokens.high

  var lastTokWasTerse = false
  case tok.tokType
  of tokKeywordLow..tokKeywordHigh:
    if endsInAlpha(em):
      wrSpace em
    elif not em.inquote and not endsInWhite(em) and
        em.lastTok notin (openPars+{tkOpr, tkDotDot}) and not em.lastTokWasTerse:
      #and tok.tokType in oprSet
      wrSpace em

    if not em.inquote:
      wr(em, TokTypeToStr[tok.tokType], ltKeyword)
      if tok.tokType in {tkAnd, tkOr, tkIn, tkNotin}:
        rememberSplit(splitIn)
        wrSpace em
    else:
      # keywords in backticks are not normalized:
      wr(em, tok.ident.s, ltIdent)

  of tkColon:
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    wrSpace em
  of tkSemicolon, tkComma:
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    rememberSplit(splitComma)
    wrSpace em
  of tkParDotLe, tkParLe, tkBracketDotLe, tkBracketLe,
     tkCurlyLe, tkCurlyDotLe, tkBracketLeColon:
    if tok.strongSpaceA > 0 and not em.endsInWhite and not em.wasExportMarker:
      wrSpace em
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
    if not em.inquote and not em.endsInWhite: wrSpace(em)
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    if not em.inquote: wrSpace(em)
  of tkOpr, tkDotDot:
    if em.inquote or ((tok.strongSpaceA == 0 and tok.strongSpaceB == 0) and
        tok.ident.s notin ["<", ">", "<=", ">=", "==", "!="]):
      # bug #9504: remember to not spacify a keyword:
      lastTokWasTerse = true
      # if not surrounded by whitespace, don't produce any whitespace either:
      wr(em, tok.ident.s, ltOpr)
    else:
      if not em.endsInWhite: wrSpace(em)
      wr(em, tok.ident.s, ltOpr)
      template isUnary(tok): bool =
        tok.strongSpaceB == 0 and tok.strongSpaceA > 0

      if not isUnary(tok):
        rememberSplit(splitBinary)
        wrSpace(em)
  of tkAccent:
    if not em.inquote and endsInAlpha(em): wrSpace(em)
    wr(em, TokTypeToStr[tok.tokType], ltOther)
    em.inquote = not em.inquote
  of tkComment:
    if not preventComment:
      emitComment(em, tok)
  of tkIntLit..tkStrLit, tkRStrLit, tkTripleStrLit, tkGStrLit, tkGTripleStrLit, tkCharLit:
    let lit = fileSection(em.config, em.fid, tok.offsetA, tok.offsetB)
    if endsInAlpha(em) and tok.tokType notin {tkGStrLit, tkGTripleStrLit}: wrSpace(em)
    em.lineSpan = countNewlines(lit)
    if em.lineSpan > 0: calcCol(em, lit)
    wr em, lit, ltLit
  of tkEof: discard
  else:
    let lit = if tok.ident != nil: tok.ident.s else: tok.literal
    if endsInAlpha(em): wrSpace(em)
    wr em, lit, ltIdent

  em.lastTok = tok.tokType
  em.lastTokWasTerse = lastTokWasTerse
  em.lastLineNumber = tok.line + em.lineSpan
  em.lineSpan = 0

proc endsWith(em: Emitter; k: varargs[string]): bool =
  if em.tokens.len < k.len: return false
  for i in 0..high(k):
    if em.tokens[em.tokens.len - k.len + i] != k[i]: return false
  return true

proc starWasExportMarker*(em: var Emitter) =
  if em.endsWith(" ", "*", " "):
    setLen(em.tokens, em.tokens.len-3)
    setLen(em.kinds, em.kinds.len-3)
    em.tokens.add("*")
    em.kinds.add ltExportMarker
    dec em.col, 2

proc commaWasSemicolon*(em: var Emitter) =
  if em.semicolons == detectSemicolonKind:
    em.semicolons = if em.endsWith(",", " "): dontTouch else: useSemicolon
  if em.semicolons == useSemicolon and em.endsWith(",", " "):
    em.tokens[em.tokens.len-2] = ";"

proc curlyRiWasPragma*(em: var Emitter) =
  if em.endsWith("}"):
    em.tokens[em.tokens.len-1] = ".}"
    inc em.col
