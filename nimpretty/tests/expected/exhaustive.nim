discard """
  outputsub: '''ObjectAssignmentError'''
  exitcode: "1"
"""

import verylongnamehere, verylongnamehere,
  verylongnamehereverylongnamehereverylong, namehere, verylongnamehere

proc `[]=`() = discard "index setter"
proc `putter=`() = discard cast[pointer](cast[int](buffer) + size)

(not false)

let expr = if true: "true" else: "false"

var body = newNimNode(nnkIfExpr).add(
  newNimNode(nnkElifBranch).add(
    infix(newDotExpr(ident("a"), ident("kind")), "==", newDotExpr(ident("b"),
        ident("kind"))),
    condition
  ),
  newNimNode(nnkElse).add(newStmtList(newNimNode(nnkReturnStmt).add(ident(
      "false"))))
)

# comment

var x = 1

type
  GeneralTokenizer* = object of RootObj ## comment here
    kind*: TokenClass         ## and here
    start*, length*: int      ## you know how it goes...
    buf: cstring
    pos: int                  # other comment here.
    state: TokenClass

var x*: string
var y: seq[string] #[ yay inline comments. So nice I have to care bout these. ]#

echo "#", x, "##", y, "#" & "string" & $test

echo (tup, here)
echo(argA, argB)

import macros

## A documentation comment here.
## That spans multiple lines.
## And is not to be touched.

const numbers = [4u8, 5'u16, 89898_00]

macro m(n): untyped =
  result = foo"string literal"

{.push m.}
proc p() = echo "p", 1+4 * 5, if true: 5 else: 6
proc q(param: var ref ptr string) =
  p()
  if true:
    echo a and b or not c and not -d
{.pop.}

q()

when false:
  # bug #4766
  type
    Plain = ref object
      discard

    Wrapped[T] = object
      value: T

  converter toWrapped[T](value: T): Wrapped[T] =
    Wrapped[T](value: value)

  let result = Plain()
  discard $result

when false:
  # bug #3670
  template someTempl(someConst: bool) =
    when someConst:
      var a: int
    if true:
      when not someConst:
        var a: int
      a = 5

  someTempl(true)


#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Layouter for nimpretty. Still primitive but useful.

import idents, lexer, lineinfos, llstream, options, msgs, strutils
from os import changeFileExt

const
  MaxLineLen = 80
  LineCommentColumn = 30

type
  SplitKind = enum
    splitComma, splitParLe, splitAnd, splitOr, splitIn, splitBinary

  Emitter* = object
    f: PLLStream
    config: ConfigRef
    fid: FileIndex
    lastTok: TTokType
    inquote {.pragmaHereWrongCurlyEnd.}: bool
    col, lastLineNumber, lineSpan, indentLevel: int
    content: string
    fixedUntil: int           # marks where we must not go in the content
    altSplitPos: array[SplitKind, int] # alternative split positions

proc openEmitter*[T, S](em: var Emitter; config: ConfigRef;
    fileIdx: FileIndex) {.pragmaHereWrongCurlyEnd.} =
  let outfile = changeFileExt(config.toFullPath(fileIdx), ".pretty.nim")
  em.f = llStreamOpen(outfile, fmWrite)
  em.config = config
  em.fid = fileIdx
  em.lastTok = tkInvalid
  em.inquote = false
  em.col = 0
  em.content = newStringOfCap(16_000)
  if em.f == nil:
    rawMessage(config, errGenerated, "cannot open file: " & outfile)

proc closeEmitter*(em: var Emitter) {.inline.} =
  em.f.llStreamWrite em.content
  llStreamClose(em.f)

proc countNewlines(s: string): int =
  result = 0
  for i in 0..<s.len:
    if s[i+1] == '\L': inc result

proc calcCol(em: var Emitter; s: string) =
  var i = s.len-1
  em.col = 0
  while i >= 0 and s[i] != '\L':
    dec i
    inc em.col

template wr(x) =
  em.content.add x
  inc em.col, x.len

template goodCol(col): bool = col in 40..MaxLineLen

const splitters = {tkComma, tkSemicolon, tkParLe, tkParDotLe,
                   tkBracketLe, tkBracketLeColon, tkCurlyDotLe,
                   tkCurlyLe}

template rememberSplit(kind) =
  if goodCol(em.col):
    em.altSplitPos[kind] = em.content.len

proc softLinebreak(em: var Emitter; lit: string) =
  # XXX Use an algorithm that is outlined here:
  # https://llvm.org/devmtg/2013-04/jasper-slides.pdf
  # +2 because we blindly assume a comma or ' &' might follow
  if not em.inquote and em.col+lit.len+2 >= MaxLineLen:
    if em.lastTok in splitters:
      wr("\L")
      em.col = 0
      for i in 1..em.indentLevel+2: wr(" ")
    else:
      # search backwards for a good split position:
      for a in em.altSplitPos:
        if a > em.fixedUntil:
          let ws = "\L" & repeat(' ', em.indentLevel+2)
          em.col = em.content.len - a
          em.content.insert(ws, a)
          break

proc emitTok*(em: var Emitter; L: TLexer; tok: TToken) =

  template endsInWhite(em): bool =
    em.content.len > 0 and em.content[em.content.high] in {' ', '\L'}
  template endsInAlpha(em): bool =
    em.content.len > 0 and em.content[em.content.high] in SymChars+{'_'}

  proc emitComment(em: var Emitter; tok: TToken) =
    let lit = strip fileSection(em.config, em.fid, tok.commentOffsetA,
        tok.commentOffsetB)
    em.lineSpan = countNewlines(lit)
    if em.lineSpan > 0: calcCol(em, lit)
    if not endsInWhite(em):
      wr(" ")
      if em.lineSpan == 0 and max(em.col,
          LineCommentColumn) + lit.len <= MaxLineLen:
        for i in 1 .. LineCommentColumn - em.col: wr(" ")
    wr lit

  var preventComment = case tok.tokType
    of tokKeywordLow..tokKeywordHigh:
      if endsInAlpha(em): wr(" ")
      wr(TokTypeToStr[tok.tokType])

      case tok.tokType
      of tkAnd: rememberSplit(splitAnd)
      of tkOr: rememberSplit(splitOr)
      of tkIn: rememberSplit(splitIn)
      else: 90
    else:
      "case returns value"


  if tok.tokType == tkComment and tok.line == em.lastLineNumber and
      tok.indent >= 0:
    # we have an inline comment so handle it before the indentation token:
    emitComment(em, tok)
    preventComment = true
    em.fixedUntil = em.content.high

  elif tok.indent >= 0:
    em.indentLevel = tok.indent
    # remove trailing whitespace:
    while em.content.len > 0 and em.content[em.content.high] == ' ':
      setLen(em.content, em.content.len-1)
    wr("\L")
    for i in 2..tok.line - em.lastLineNumber: wr("\L")
    em.col = 0
    for i in 1..tok.indent:
      wr(" ")
    em.fixedUntil = em.content.high

  case tok.tokType
  of tokKeywordLow..tokKeywordHigh:
    if endsInAlpha(em): wr(" ")
    wr(TokTypeToStr[tok.tokType])

    case tok.tokType
    of tkAnd: rememberSplit(splitAnd)
    of tkOr: rememberSplit(splitOr)
    of tkIn: rememberSplit(splitIn)
    else: discard

  of tkColon:
    wr(TokTypeToStr[tok.tokType])
    wr(" ")
  of tkSemicolon,
     tkComma:
    wr(TokTypeToStr[tok.tokType])
    wr(" ")
    rememberSplit(splitComma)
  of tkParLe, tkParRi, tkBracketLe,
     tkBracketRi, tkCurlyLe, tkCurlyRi,
     tkBracketDotLe, tkBracketDotRi,
     tkCurlyDotLe, tkCurlyDotRi,
     tkParDotLe, tkParDotRi,
     tkColonColon, tkDot, tkBracketLeColon:
    wr(TokTypeToStr[tok.tokType])
    if tok.tokType in splitters:
      rememberSplit(splitParLe)
  of tkEquals:
    if not em.endsInWhite: wr(" ")
    wr(TokTypeToStr[tok.tokType])
    wr(" ")
  of tkOpr, tkDotDot:
    if not em.endsInWhite: wr(" ")
    wr(tok.ident.s)
    template isUnary(tok): bool =
      tok.strongSpaceB == 0 and tok.strongSpaceA > 0

    if not isUnary(tok) or em.lastTok in {tkOpr, tkDotDot}:
      wr(" ")
      rememberSplit(splitBinary)
  of tkAccent:
    wr(TokTypeToStr[tok.tokType])
    em.inquote = not em.inquote
  of tkComment:
    if not preventComment:
      emitComment(em, tok)
  of tkIntLit..tkStrLit, tkRStrLit, tkTripleStrLit, tkGStrLit,
      tkGTripleStrLit, tkCharLit:
    let lit = fileSection(em.config, em.fid, tok.offsetA, tok.offsetB)
    softLinebreak(em, lit)
    if endsInAlpha(em) and tok.tokType notin {tkGStrLit, tkGTripleStrLit}: wr(
        " ")
    em.lineSpan = countNewlines(lit)
    if em.lineSpan > 0: calcCol(em, lit)
    wr lit
  of tkEof: discard
  else:
    let lit = if tok.ident != nil: tok.ident.s else: tok.literal
    softLinebreak(em, lit)
    if endsInAlpha(em): wr(" ")
    wr lit

  em.lastTok = tok.tokType
  em.lastLineNumber = tok.line + em.lineSpan
  em.lineSpan = 0

proc starWasExportMarker*(em: var Emitter) =
  if em.content.endsWith(" * "):
    setLen(em.content, em.content.len-3)
    em.content.add("*")
    dec em.col, 2

type
  Thing = ref object
    grade: string
    # this name is great
    name: string

proc f() =
  var c: char
  var str: string
  if c == '\\':
    # escape char
    str &= c

proc getKeyAndData(cursor: int; op: int):
    tuple[key, data: string; success: bool] {.noInit.} =
  var keyVal: string
  var dataVal: string

#!nimpretty off
  when stuff:
    echo "so nice"
    echo "more"
  else:
     echo "misaligned"
#!nimpretty on

const test = r"C:\Users\-\Desktop\test.txt"

proc abcdef*[T: not (tuple|object|string|cstring|char|ref|ptr|array|seq|distinct)]() =
  # bug #9504
  type T2 = a.type
  discard

proc fun() =
  #[
  this one here
  ]#
  discard

proc fun2() =
  ##[
  foobar
  ]##
  discard

#[
foobar
]#

proc fun3() =
  discard

##[
foobar
]##

# bug #9673
discard `*`(1, 2)

proc fun4() =
  var a = "asdf"
  var i = 0
  while i < a.len and i < a.len:
    return
