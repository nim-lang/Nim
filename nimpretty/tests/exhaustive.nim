discard """
  outputsub: '''ObjectAssignmentDefect'''
  exitcode: "1"
"""

import verylongnamehere,verylongnamehere,verylongnamehereverylongnamehereverylong,namehere,verylongnamehere

proc `[]=`() = discard "index setter"
proc `putter=`() = discard cast[pointer](cast[int](buffer) + size)

(not false)

let expr = if true: "true" else: "false"

var body = newNimNode(nnkIfExpr).add(
  newNimNode(nnkElifBranch).add(
    infix(newDotExpr(ident("a"), ident("kind")), "==", newDotExpr(ident("b"), ident("kind"))),
    condition
  ),
  newNimNode(nnkElse).add(newStmtList(newNimNode(nnkReturnStmt).add(ident("false"))))
)

# comment

var x = 1

type
  GeneralTokenizer* = object of RootObj ## comment here
    kind*: TokenClass ## and here
    start*, length*: int ## you know how it goes...
    buf: cstring
    pos: int # other comment here.
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
    inquote {.pragmaHereWrongCurlyEnd}: bool
    col, lastLineNumber, lineSpan, indentLevel: int
    content: string
    fixedUntil: int # marks where we must not go in the content
    altSplitPos: array[SplitKind, int] # alternative split positions

proc openEmitter*[T, S](em: var Emitter; config: ConfigRef; fileIdx: FileIndex) {.pragmaHereWrongCurlyEnd} =
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

proc softLinebreak(em: var Emitter, lit: string) =
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
          let ws = "\L" & repeat(' ',em.indentLevel+2)
          em.col = em.content.len - a
          em.content.insert(ws, a)
          break

proc emitTok*(em: var Emitter; L: TLexer; tok: TToken) =

  template endsInWhite(em): bool =
    em.content.len > 0 and em.content[em.content.high] in {' ', '\L'}
  template endsInAlpha(em): bool =
    em.content.len > 0 and em.content[em.content.high] in SymChars+{'_'}

  proc emitComment(em: var Emitter; tok: TToken) =
    let lit = strip fileSection(em.config, em.fid, tok.commentOffsetA, tok.commentOffsetB)
    em.lineSpan = countNewlines(lit)
    if em.lineSpan > 0: calcCol(em, lit)
    if not endsInWhite(em):
      wr(" ")
      if em.lineSpan == 0 and max(em.col, LineCommentColumn) + lit.len <= MaxLineLen:
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


  if tok.tokType == tkComment and tok.line == em.lastLineNumber and tok.indent >= 0:
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
  of tkIntLit..tkStrLit, tkRStrLit, tkTripleStrLit, tkGStrLit, tkGTripleStrLit, tkCharLit:
    let lit = fileSection(em.config, em.fid, tok.offsetA, tok.offsetB)
    softLinebreak(em, lit)
    if endsInAlpha(em) and tok.tokType notin {tkGStrLit, tkGTripleStrLit}: wr(" ")
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

proc getKeyAndData(cursor: int, op: int):
    tuple[key, data: string, success: bool] {.noInit.} =
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

proc abcdef*[T:not (tuple|object|string|cstring|char|ref|ptr|array|seq|distinct)]() =
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
discard `* `(1, 2)

proc fun4() =
  var a = "asdf"
  var i = 0
  while i<a.len and i<a.len:
    return


# bug #10295

import osproc
let res = execProcess(
    "echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates")

let res = execProcess("echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates")


# bug #10177

proc foo  *  () =
  discard

proc foo* [T]() =
  discard


# bug #10159

proc fun() =
  discard

proc main() =
    echo "foo"; echo "bar";
    discard

main()

type
  TCallingConvention* = enum
    ccDefault,                # proc has no explicit calling convention
    ccStdCall,    # procedure is stdcall
    ccCDecl,                  # cdecl
    ccSafeCall,               # safecall
    ccSysCall, # system call
    ccInline,                 # proc should be inlined
    ccNoInline,               # proc should not be inlined
    ccFastCall,               # fastcall (pass parameters in registers)
    ccClosure,        # proc has a closure
    ccNoConvention       # needed for generating proper C procs sometimes


proc isValid1*[A](s: HashSet[A]): bool {.deprecated:
    "Deprecated since v0.20; sets are initialized by default".} =
  ## Returns `true` if the set has been initialized (with `initHashSet proc
  ## <#initHashSet,int>`_ or `init proc <#init,HashSet[A],int>`_).
  result = s.data.len > 0
  # bug #11468

assert $typeof(a) == "Option[system.int]"
foo(a, $typeof(b), c)
foo(typeof(b), c) # this is ok

proc `<`*[A](s, t: A): bool = discard
proc `==`*[A](s, t: HashSet[A]): bool = discard
proc `<=`*[A](s, t: HashSet[A]): bool = discard

# these are ok:
proc `$`*[A](s: HashSet[A]): string = discard
proc `*`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} = discard
proc `-+-`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} = discard

# bug #11470


# bug #11467

type
  FirstEnum = enum ## doc comment here
    first,  ## this is first
    second, ## second doc
    third,  ## third one
    fourth  ## the last one


type
  SecondEnum = enum ## doc comment here
    first,  ## this is first
    second, ## second doc
    third,  ## third one
    fourth, ## the last one


type
  ThirdEnum = enum ## doc comment here
    first    ## this is first
    second   ## second doc
    third    ## third one
    fourth   ## the last one


type
  HttpMethod* = enum  ## the requested HttpMethod
    HttpHead,         ## Asks for the response identical to the one that would
                      ## correspond to a GET request, but without the response
                      ## body.
    HttpGet,          ## Retrieves the specified resource.
    HttpPost,         ## Submits data to be processed to the identified
                      ## resource. The data is included in the body of the
                      ## request.
    HttpPut,          ## Uploads a representation of the specified resource.
    HttpDelete,       ## Deletes the specified resource.
    HttpTrace,        ## Echoes back the received request, so that a client
                      ## can see what intermediate servers are adding or
                      ## changing in the request.
    HttpOptions,      ## Returns the HTTP methods that the server supports
                      ## for specified address.
    HttpConnect,      ## Converts the request connection to a transparent
                      ## TCP/IP tunnel, usually used for proxies.
    HttpPatch         ## Applies partial modifications to a resource.

type
  HtmlTag* = enum  ## list of all supported HTML tags; order will always be
                   ## alphabetically
    tagUnknown,    ## unknown HTML element
    tagA,          ## the HTML ``a`` element
    tagAbbr,       ## the deprecated HTML ``abbr`` element
    tagAcronym,    ## the HTML ``acronym`` element
    tagAddress,    ## the HTML ``address`` element
    tagApplet,     ## the deprecated HTML ``applet`` element
    tagArea,       ## the HTML ``area`` element
    tagArticle,    ## the HTML ``article`` element
    tagAside,      ## the HTML ``aside`` element
    tagAudio,      ## the HTML ``audio`` element
    tagB,          ## the HTML ``b`` element
    tagBase,       ## the HTML ``base`` element
    tagBdi,        ## the HTML ``bdi`` element
    tagBdo,        ## the deprecated HTML ``dbo`` element
    tagBasefont,   ## the deprecated HTML ``basefont`` element
    tagBig,        ## the HTML ``big`` element
    tagBlockquote, ## the HTML ``blockquote`` element
    tagBody,       ## the HTML ``body`` element
    tagBr,         ## the HTML ``br`` element
    tagButton,     ## the HTML ``button`` element
    tagCanvas,     ## the HTML ``canvas`` element
    tagCaption,    ## the HTML ``caption`` element
    tagCenter,     ## the deprecated HTML ``center`` element
    tagCite,       ## the HTML ``cite`` element
    tagCode,       ## the HTML ``code`` element
    tagCol,        ## the HTML ``col`` element
    tagColgroup,   ## the HTML ``colgroup`` element
    tagCommand,    ## the HTML ``command`` element
    tagDatalist,   ## the HTML ``datalist`` element
    tagDd,         ## the HTML ``dd`` element
    tagDel,        ## the HTML ``del`` element
    tagDetails,    ## the HTML ``details`` element
    tagDfn,        ## the HTML ``dfn`` element
    tagDialog,     ## the HTML ``dialog`` element
    tagDiv,        ## the HTML ``div`` element
    tagDir,        ## the deprecated HTLM ``dir`` element
    tagDl,         ## the HTML ``dl`` element
    tagDt,         ## the HTML ``dt`` element
    tagEm,         ## the HTML ``em`` element
    tagEmbed,      ## the HTML ``embed`` element
    tagFieldset,   ## the HTML ``fieldset`` element
    tagFigcaption, ## the HTML ``figcaption`` element
    tagFigure,     ## the HTML ``figure`` element
    tagFont,       ## the deprecated HTML ``font`` element
    tagFooter,     ## the HTML ``footer`` element
    tagForm,       ## the HTML ``form`` element
    tagFrame,      ## the HTML ``frame`` element
    tagFrameset,   ## the deprecated HTML ``frameset`` element
    tagH1,         ## the HTML ``h1`` element
    tagH2,         ## the HTML ``h2`` element
    tagH3,         ## the HTML ``h3`` element
    tagH4,         ## the HTML ``h4`` element
    tagH5,         ## the HTML ``h5`` element
    tagH6,         ## the HTML ``h6`` element
    tagHead,       ## the HTML ``head`` element
    tagHeader,     ## the HTML ``header`` element
    tagHgroup,     ## the HTML ``hgroup`` element
    tagHtml,       ## the HTML ``html`` element
    tagHr,         ## the HTML ``hr`` element
    tagI,          ## the HTML ``i`` element
    tagIframe,     ## the deprecated HTML ``iframe`` element
    tagImg,        ## the HTML ``img`` element
    tagInput,      ## the HTML ``input`` element
    tagIns,        ## the HTML ``ins`` element
    tagIsindex,    ## the deprecated HTML ``isindex`` element
    tagKbd,        ## the HTML ``kbd`` element
    tagKeygen,     ## the HTML ``keygen`` element
    tagLabel,      ## the HTML ``label`` element
    tagLegend,     ## the HTML ``legend`` element
    tagLi,         ## the HTML ``li`` element
    tagLink,       ## the HTML ``link`` element
    tagMap,        ## the HTML ``map`` element
    tagMark,       ## the HTML ``mark`` element
    tagMenu,       ## the deprecated HTML ``menu`` element
    tagMeta,       ## the HTML ``meta`` element
    tagMeter,      ## the HTML ``meter`` element
    tagNav,        ## the HTML ``nav`` element
    tagNobr,       ## the deprecated HTML ``nobr`` element
    tagNoframes,   ## the deprecated HTML ``noframes`` element
    tagNoscript,   ## the HTML ``noscript`` element
    tagObject,     ## the HTML ``object`` element
    tagOl,         ## the HTML ``ol`` element
    tagOptgroup,   ## the HTML ``optgroup`` element
    tagOption,     ## the HTML ``option`` element
    tagOutput,     ## the HTML ``output`` element
    tagP,          ## the HTML ``p`` element
    tagParam,      ## the HTML ``param`` element
    tagPre,        ## the HTML ``pre`` element
    tagProgress,   ## the HTML ``progress`` element
    tagQ,          ## the HTML ``q`` element
    tagRp,         ## the HTML ``rp`` element
    tagRt,         ## the HTML ``rt`` element
    tagRuby,       ## the HTML ``ruby`` element
    tagS,          ## the deprecated HTML ``s`` element
    tagSamp,       ## the HTML ``samp`` element
    tagScript,     ## the HTML ``script`` element
    tagSection,    ## the HTML ``section`` element
    tagSelect,     ## the HTML ``select`` element
    tagSmall,      ## the HTML ``small`` element
    tagSource,     ## the HTML ``source`` element
    tagSpan,       ## the HTML ``span`` element
    tagStrike,     ## the deprecated HTML ``strike`` element
    tagStrong,     ## the HTML ``strong`` element
    tagStyle,      ## the HTML ``style`` element
    tagSub,        ## the HTML ``sub`` element
    tagSummary,    ## the HTML ``summary`` element
    tagSup,        ## the HTML ``sup`` element
    tagTable,      ## the HTML ``table`` element
    tagTbody,      ## the HTML ``tbody`` element
    tagTd,         ## the HTML ``td`` element
    tagTextarea,   ## the HTML ``textarea`` element
    tagTfoot,      ## the HTML ``tfoot`` element
    tagTh,         ## the HTML ``th`` element
    tagThead,      ## the HTML ``thead`` element
    tagTime,       ## the HTML ``time`` element
    tagTitle,      ## the HTML ``title`` element
    tagTr,         ## the HTML ``tr`` element
    tagTrack,      ## the HTML ``track`` element
    tagTt,         ## the HTML ``tt`` element
    tagU,          ## the deprecated HTML ``u`` element
    tagUl,         ## the HTML ``ul`` element
    tagVar,        ## the HTML ``var`` element
    tagVideo,      ## the HTML ``video`` element
    tagWbr         ## the HTML ``wbr`` element


# bug #11469
const lookup: array[32, uint8] = [0'u8, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 16, 17,
    25, 17, 4, 8, 31, 27, 13, 23]

veryLongVariableName.createVar("future" & $node[1][0].toStrLit, node[1], futureValue1,
    futureValue2, node)

veryLongVariableName.createVar("future" & $node[1][0].toStrLit, node[1], futureValue1,
                               futureValue2, node)

type
  CmdLineKind* = enum         ## The detected command line token.
    cmdEnd,                   ## End of command line reached
    cmdArgument,              ## An argument such as a filename
    cmdLongOption,            ## A long option such as --option
    cmdShortOption            ## A short option such as -c
  OptParser* = object of RootObj ## \
    ## Implementation of the command line parser. Here is even more text yad.
    ##
    ## To initialize it, use the
    ## `initOptParser proc<#initOptParser,string,set[char],seq[string]>`_.
    pos*: int
    inShortState: bool
    allowWhitespaceAfterColon: bool
    shortNoVal: set[char]
    longNoVal: seq[string]
    cmds: seq[string]
    idx: int
    kind*: CmdLineKind        ## The detected command line token
    key*, val*: TaintedString ## Key and value pair; the key is the option
                              ## or the argument, and the value is not "" if
                              ## the option was given a value

  OptParserDifferently* = object of RootObj ## Implementation of the command line parser.
    ##
    ## To initialize it, use the
    ## `initOptParser proc<#initOptParser,string,set[char],seq[string]>`_.
    pos*: int
    inShortState: bool
    allowWhitespaceAfterColon: bool
    shortNoVal: set[char]
    longNoVal: seq[string]
    cmds: seq[string]
    idx: int
    kind*: CmdLineKind        ## The detected command line token
    key*, val*: TaintedString ## Key and value pair; the key is the option
                              ## or the argument, and the value is not "" if
                              ## the option was given a value

block:
  var t = 3

## This MUST be a multiline comment,
## single line comment would be ok.
block:
  var x = 7


block:
  var t = 3
  ## another
  ## multi

## This MUST be a multiline comment,
## single line comment would be ok.
block:
  var x = 7


proc newRecordGen(ctx: Context; typ: TypRef): PNode =
  result = nkTypeDef.t(
    newId(typ.optSym.name, true, pragmas = [id(if typ.isUnion: "cUnion" else: "cStruct")]),
    empty(),
    nkObjectTy.t(
      empty(),
      empty(),
      nkRecList.t(
        typ.recFields.map(newRecFieldGen))))


##[
String `interpolation`:idx: / `format`:idx: inspired by
Python's ``f``-strings.

.. code-block:: nim

    import strformat
    let msg = "hello"
    doAssert fmt"{msg}\n" == "hello\\n"

Because the literal is a raw string literal, the ``\n`` is not interpreted as
an escape sequence.


=================        ====================================================
  Sign                   Meaning
=================        ====================================================
``+``                    Indicates that a sign should be used for both
                         positive as well as negative numbers.
``-``                    Indicates that a sign should be used only for
                         negative numbers (this is the default behavior).
(space)                  Indicates that a leading space should be used on
                         positive numbers.
=================        ====================================================

]##


let
  lla = 42394219 - 42429849 + 1293293 - 13918391 + 424242 # this here is an okayish comment
  llb = 42394219 - 42429849 + 1293293 - 13918391 + 424242 # this here is a very long comment which should be split
  llc = 42394219 - 42429849 + 1293293 - 13918391 + 424242 - 3429424 + 4239489 - 42399
  lld = 42394219 - 42429849 + 1293293 - 13918391 + 424242 - 342949924 + 423948999 - 42399

type
  MyLongEnum = enum ## doc comment here
    first, ## this is a long comment here, but please align it
    secondWithAVeryLongNameMightBreak, ## this is a short one
    thirdOne ## it's ok

if true: # just one space before comment
  echo 7

# colors.nim:18
proc `==` *(a, b: Color): bool
  ## Compares two colors.
  ##

# colors.nim:18
proc `==` *(a, b: Color): bool {.borrow.}
  ## Compares two colors.
  ##


var rows1 = await pool.rows(sql"""
    SELECT STUFF
    WHERE fffffffffffffffffffffffffffffff
  """,
  @[
    "AAAA",
    "BBBB"
  ]
)

var rows2 = await pool.rows(sql"""
    SELECT STUFF
    WHERE fffffffffffffffffffffffffffffffgggggggggggggggggggggggggghhhhhhhhhhhhhhhheeeeeeiiiijklm""",
  @[
    "AAAA",
    "BBBB"
  ]
)


# bug #11699

const keywords = @[
  "foo", "bar", "foo", "bar", "foo", "bar", "foo", "bar", "foo", "bar", "foo", "bar", "foo", "bar",
  "zzz", "ggg", "ddd",
]

let keywords1 = @[
  "foo1", "bar1", "foo2", "bar2", "foo3", "bar3", "foo4", "bar4", "foo5", "bar5", "foo6", "bar6", "foo7",
  "zzz", "ggg", "ddd",
]

let keywords2 = @[
  "foo1", "bar1", "foo2", "bar2", "foo3", "bar3", "foo4", "bar4", "foo5", "bar5", "foo6", "bar6", "foo7",
  "foo1", "bar1", "foo2", "bar2", "foo3", "bar3", "foo4", "bar4", "foo5", "bar5", "foo6", "bar6", "foo7",
  "zzz", "ggg", "ddd",
]

if true:
  let keywords3 = @[
    "foo1", "bar1", "foo2", "bar2", "foo3", "bar3", "foo4", "bar4", "foo5", "bar5", "foo6", "bar6", "foo7",
    "zzz", "ggg", "ddd",
  ]

const b = true
let fooB =
  if true:
    if b: 7 else: 8
  else: ord(b)

let foo = if cond:
            if b: T else: F
          else: b

let a =
  [[aaadsfas, bbb],
   [ccc, ddd]]

let b = [
  [aaa, bbb],
  [ccc, ddd]
]

# bug #11616
proc newRecordGen(ctx: Context; typ: TypRef): PNode =
  result = nkTypeDef.t(
    newId(typ.optSym.name, true, pragmas = [id(if typ.isUnion: "cUnion"
                                               else: "cStruct")]),
    empty(),
    nkObjectTy.t(
      empty(),
      empty(),
      nkRecList.t(
        typ.recFields.map(newRecFieldGen))))

proc f =
  # doesn't break the code, but leaving indentation as is would be nice.
  let x = if true: callingProcWhatever()
          else: callingADifferentProc()


type
  EventKind = enum
    Stop, StopSuccess, StopError,
    SymbolChange, TextChange,

  SpinnyEvent = tuple
    kind: EventKind
    payload: string


type
  EventKind2 = enum
    Stop2, StopSuccess2, StopError2,
    SymbolChange2, TextChange2,

type
  SpinnyEvent2 = tuple
    kind: EventKind
    payload: string


proc hid_open*(vendor_id: cushort; product_id: cushort; serial_number: cstring): ptr HidDevice {.
    importc: "hid_open", dynlib: hidapi.}
