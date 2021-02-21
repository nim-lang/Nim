#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## ==================================
## rst: Nim-flavored reStructuredText
## ==================================
##
## This module implements a `reStructuredText`:idx: (RST) parser.
## A large subset is implemented with some limitations_ and
## `Nim-specific features`_.
## A few `extra features`_ of the `Markdown`:idx: syntax are
## also supported.
##
## Nim can output the result to HTML [#html]_ or Latex [#latex]_.
##
## .. [#html] commands ``nim doc`` for ``*.nim`` files and
##    ``nim rst2html`` for ``*.rst`` files
##
## .. [#latex] command ``nim rst2tex`` for ``*.rst``.
##
## If you are new to RST please consider reading the following:
##
## 1) a short `quick introduction`_
## 2) an `RST reference`_: a comprehensive cheatsheet for RST
## 3) a more formal 50-page `RST specification`_.
##
## Features
## --------
##
## Supported standard RST features:
##
## * body elements
##   + sections
##   + transitions
##   + paragraphs
##   + bullet lists using \+, \*, \-
##   + enumerated lists using arabic numerals or alphabet
##     characters:  1. ... 2. ... *or* a. ... b. ... *or* A. ... B. ...
##   + footnotes (including manually numbered, auto-numbered, auto-numbered
##     with label, and auto-symbol footnotes) and citations
##   + definition lists
##   + field lists
##   + option lists
##   + indented literal blocks
##   + simple tables
##   + directives (see official documentation in `RST directives list`_):
##     - ``image``, ``figure`` for including images and videos
##     - ``code``
##     - ``contents`` (table of contents), ``container``, ``raw``
##     - ``include``
##     - admonitions: "attention", "caution", "danger", "error", "hint",
##       "important", "note", "tip", "warning", "admonition"
##     - substitution definitions: `replace` and `image`
##   + comments
## * inline markup
##   + *emphasis*, **strong emphasis**,
##     ``inline literals``, hyperlink references (including embedded URI),
##     substitution references, standalone hyperlinks,
##     internal links (inline and outline)
##   + \`interpreted text\` with roles ``:literal:``, ``:strong:``,
##     ``emphasis``, ``:sub:``/``:subscript:``, ``:sup:``/``:supscript:``
##     (see `RST roles list`_ for description).
##   + inline internal targets
##
## .. _`Nim-specific features`:
##
## Additional Nim-specific features:
##
## * directives: ``code-block`` [cmp:Sphinx]_, ``title``,
##   ``index`` [cmp:Sphinx]_
##
## * ***triple emphasis*** (bold and italic) using \*\*\*
## * ``:idx:`` role for \`interpreted text\` to include the link to this
##   text into an index (example: `Nim index`_).
##
## .. [cmp:Sphinx] similar but different from the directives of
##    Python `Sphinx directives`_ extensions
##
## .. _`extra features`:
##
## Optional additional features, turned on by ``options: RstParseOption`` in
## `rstParse proc <#rstParse,string,string,int,int,bool,RstParseOptions,FindFileHandler,MsgHandler>`_:
##
## * emoji / smiley symbols
## * Markdown tables
## * Markdown code blocks
## * Markdown links
## * Markdown headlines
## * using ``1`` as auto-enumerator in enumerated lists like RST ``#``
##   (auto-enumerator ``1`` can not be used with ``#`` in the same list)
##
## .. Note:: By default Nim has ``roSupportMarkdown`` and
##    ``roSupportRawDirective`` turned **on**.
##
## .. warning:: Using Nim-specific features can cause other RST implementations
##   to fail on your document.
##
## Limitations
## -----------
##
## * no Unicode support in character width calculations
## * body elements
##   - no roman numerals in enumerated lists
##   - no quoted literal blocks
##   - no doctest blocks
##   - no grid tables
##   - some directives are missing (check official `RST directives list`_):
##     ``parsed-literal``, ``sidebar``, ``topic``, ``math``, ``rubric``,
##     ``epigraph``, ``highlights``, ``pull-quote``, ``compound``,
##     ``table``, ``csv-table``, ``list-table``, ``section-numbering``,
##     ``header``, ``footer``, ``meta``, ``class``
##     - no ``role`` directives and no custom interpreted text roles
##     - some standard roles are not supported (check `RST roles list`_)
## * inline markup
##   - no simple-inline-markup
##   - no embedded aliases
##
## Usage
## -----
##
## See `Nim DocGen Tools Guide <docgen.html>`_ for the details about
## ``nim doc``, ``nim rst2html`` and ``nim rst2tex`` commands.
##
## See `packages/docutils/rstgen module <rstgen.html>`_ to know how to
## generate HTML or Latex strings to embed them into your documents.
##
## .. Tip:: Import ``packages/docutils/rst`` to use this module
##    programmatically.
##
## .. _quick introduction: https://docutils.sourceforge.io/docs/user/rst/quickstart.html
## .. _RST reference: https://docutils.sourceforge.io/docs/user/rst/quickref.html
## .. _RST specification: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html
## .. _RST directives list: https://docutils.sourceforge.io/docs/ref/rst/directives.html
## .. _RST roles list: https://docutils.sourceforge.io/docs/ref/rst/roles.html
## .. _Nim index: https://nim-lang.org/docs/theindex.html
## .. _Sphinx directives: https://www.sphinx-doc.org/en/master/usage/restructuredtext/directives.html

import
  os, strutils, rstast, algorithm, lists, sequtils

type
  RstParseOption* = enum     ## options for the RST parser
    roSkipPounds,             ## skip ``#`` at line beginning (documentation
                              ## embedded in Nim comments)
    roSupportSmilies,         ## make the RST parser support smilies like ``:)``
    roSupportRawDirective,    ## support the ``raw`` directive (don't support
                              ## it for sandboxing)
    roSupportMarkdown         ## support additional features of Markdown

  RstParseOptions* = set[RstParseOption]

  MsgClass* = enum
    mcHint = "Hint",
    mcWarning = "Warning",
    mcError = "Error"

  MsgKind* = enum          ## the possible messages
    meCannotOpenFile = "cannot open '$1'",
    meExpected = "'$1' expected",
    meGridTableNotImplemented = "grid table is not implemented",
    meMarkdownIllformedTable = "illformed delimiter row of a Markdown table",
    meNewSectionExpected = "new section expected $1",
    meGeneralParseError = "general parse error",
    meInvalidDirective = "invalid directive: '$1'",
    meFootnoteMismatch = "mismatch in number of footnotes and their refs: $1",
    mwRedefinitionOfLabel = "redefinition of label '$1'",
    mwUnknownSubstitution = "unknown substitution '$1'",
    mwUnsupportedLanguage = "language '$1' not supported",
    mwUnsupportedField = "field '$1' not supported",
    mwRstStyle = "RST style: $1"

  MsgHandler* = proc (filename: string, line, col: int, msgKind: MsgKind,
                       arg: string) {.closure, gcsafe.} ## what to do in case of an error
  FindFileHandler* = proc (filename: string): string {.closure, gcsafe.}

proc rstnodeToRefname*(n: PRstNode): string
proc addNodes*(n: PRstNode): string
proc getFieldValue*(n: PRstNode, fieldname: string): string
proc getArgument*(n: PRstNode): string

# ----------------------------- scanner part --------------------------------

const
  SymChars: set[char] = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}
  SmileyStartChars: set[char] = {':', ';', '8'}
  Smilies = {
    ":D": "icon_e_biggrin",
    ":-D": "icon_e_biggrin",
    ":)": "icon_e_smile",
    ":-)": "icon_e_smile",
    ";)": "icon_e_wink",
    ";-)": "icon_e_wink",
    ":(": "icon_e_sad",
    ":-(": "icon_e_sad",
    ":o": "icon_e_surprised",
    ":-o": "icon_e_surprised",
    ":shock:": "icon_eek",
    ":?": "icon_e_confused",
    ":-?": "icon_e_confused",
    ":-/": "icon_e_confused",

    "8-)": "icon_cool",

    ":lol:": "icon_lol",
    ":x": "icon_mad",
    ":-x": "icon_mad",
    ":P": "icon_razz",
    ":-P": "icon_razz",
    ":oops:": "icon_redface",
    ":cry:": "icon_cry",
    ":evil:": "icon_evil",
    ":twisted:": "icon_twisted",
    ":roll:": "icon_rolleyes",
    ":!:": "icon_exclaim",

    ":?:": "icon_question",
    ":idea:": "icon_idea",
    ":arrow:": "icon_arrow",
    ":|": "icon_neutral",
    ":-|": "icon_neutral",
    ":mrgreen:": "icon_mrgreen",
    ":geek:": "icon_e_geek",
    ":ugeek:": "icon_e_ugeek"
  }

type
  TokType = enum
    tkEof, tkIndent,
    tkWhite, tkWord,
    tkAdornment,              # used for chapter adornment, transitions and
                              # horizontal table borders
    tkPunct,                  # one or many punctuation characters
    tkOther
  Token = object              # a RST token
    kind*: TokType            # the type of the token
    ival*: int                # the indentation or parsed integer value
    symbol*: string           # the parsed symbol as string
    line*, col*: int          # line and column of the token

  TokenSeq = seq[Token]
  Lexer = object of RootObj
    buf*: cstring
    bufpos*: int
    line*, col*, baseIndent*: int
    skipPounds*: bool
    adornmentLine*: bool

proc getThing(L: var Lexer, tok: var Token, s: set[char]) =
  tok.kind = tkWord
  tok.line = L.line
  tok.col = L.col
  var pos = L.bufpos
  while true:
    tok.symbol.add(L.buf[pos])
    inc pos
    if L.buf[pos] notin s: break
  inc L.col, pos - L.bufpos
  L.bufpos = pos

proc isCurrentLineAdornment(L: var Lexer): bool =
  var pos = L.bufpos
  let c = L.buf[pos]
  while true:
    inc pos
    if L.buf[pos] in {'\c', '\l', '\0'}:
      break
    if c == '+':  # grid table
      if L.buf[pos] notin {'-', '=', '+'}:
        return false
    else:  # section adornment or table horizontal border
      if L.buf[pos] notin {c, ' ', '\t', '\v', '\f'}:
        return false
  result = true

proc getPunctAdornment(L: var Lexer, tok: var Token) =
  if L.adornmentLine:
    tok.kind = tkAdornment
  else:
    tok.kind = tkPunct
  tok.line = L.line
  tok.col = L.col
  var pos = L.bufpos
  let c = L.buf[pos]
  while true:
    tok.symbol.add(L.buf[pos])
    inc pos
    if L.buf[pos] != c: break
  inc L.col, pos - L.bufpos
  L.bufpos = pos
  if tok.symbol == "\\": tok.kind = tkPunct
    # nim extension: standalone \ can not be adornment

proc getBracket(L: var Lexer, tok: var Token) =
  tok.kind = tkPunct
  tok.line = L.line
  tok.col = L.col
  tok.symbol.add(L.buf[L.bufpos])
  inc L.col
  inc L.bufpos

proc getIndentAux(L: var Lexer, start: int): int =
  var pos = start
  # skip the newline (but include it in the token!)
  if L.buf[pos] == '\x0D':
    if L.buf[pos + 1] == '\x0A': inc pos, 2
    else: inc pos
  elif L.buf[pos] == '\x0A':
    inc pos
  if L.skipPounds:
    if L.buf[pos] == '#': inc pos
    if L.buf[pos] == '#': inc pos
  while true:
    case L.buf[pos]
    of ' ', '\x0B', '\x0C':
      inc pos
      inc result
    of '\x09':
      inc pos
      result = result - (result mod 8) + 8
    else:
      break                   # EndOfFile also leaves the loop
  if L.buf[pos] == '\0':
    result = 0
  elif L.buf[pos] == '\x0A' or L.buf[pos] == '\x0D':
    # look at the next line for proper indentation:
    result = getIndentAux(L, pos)
  L.bufpos = pos              # no need to set back buf

proc getIndent(L: var Lexer, tok: var Token) =
  tok.col = 0
  tok.kind = tkIndent         # skip the newline (but include it in the token!)
  tok.ival = getIndentAux(L, L.bufpos)
  inc L.line
  tok.line = L.line
  L.col = tok.ival
  tok.ival = max(tok.ival - L.baseIndent, 0)
  tok.symbol = "\n" & spaces(tok.ival)

proc rawGetTok(L: var Lexer, tok: var Token) =
  tok.symbol = ""
  tok.ival = 0
  if L.col == 0:
    L.adornmentLine = false
  var c = L.buf[L.bufpos]
  case c
  of 'a'..'z', 'A'..'Z', '\x80'..'\xFF', '0'..'9':
    getThing(L, tok, SymChars)
  of ' ', '\x09', '\x0B', '\x0C':
    getThing(L, tok, {' ', '\x09'})
    tok.kind = tkWhite
    if L.buf[L.bufpos] in {'\x0D', '\x0A'}:
      rawGetTok(L, tok)       # ignore spaces before \n
  of '\x0D', '\x0A':
    getIndent(L, tok)
    L.adornmentLine = false
  of '!', '\"', '#', '$', '%', '&', '\'',  '*', '+', ',', '-', '.',
     '/', ':', ';', '<', '=', '>', '?', '@', '\\', '^', '_', '`',
     '|', '~':
    if L.col == 0:
      L.adornmentLine = L.isCurrentLineAdornment()
    getPunctAdornment(L, tok)
  of '(', ')', '[', ']', '{', '}':
    getBracket(L, tok)
  else:
    tok.line = L.line
    tok.col = L.col
    if c == '\0':
      tok.kind = tkEof
    else:
      tok.kind = tkOther
      tok.symbol.add(c)
      inc L.bufpos
      inc L.col
  tok.col = max(tok.col - L.baseIndent, 0)

proc getTokens(buffer: string, skipPounds: bool, tokens: var TokenSeq): int =
  var L: Lexer
  var length = tokens.len
  L.buf = cstring(buffer)
  L.line = 0                  # skip UTF-8 BOM
  if L.buf[0] == '\xEF' and L.buf[1] == '\xBB' and L.buf[2] == '\xBF':
    inc L.bufpos, 3
  L.skipPounds = skipPounds
  if skipPounds:
    if L.buf[L.bufpos] == '#':
      inc L.bufpos
      inc result
    if L.buf[L.bufpos] == '#':
      inc L.bufpos
      inc result
    L.baseIndent = 0
    while L.buf[L.bufpos] == ' ':
      inc L.bufpos
      inc L.baseIndent
      inc result
  while true:
    inc length
    setLen(tokens, length)
    rawGetTok(L, tokens[length - 1])
    if tokens[length - 1].kind == tkEof: break
  if tokens[0].kind == tkWhite:
    # BUGFIX
    tokens[0].ival = tokens[0].symbol.len
    tokens[0].kind = tkIndent

type
  LevelMap = array[char, int]
  Substitution = object
    key*: string
    value*: PRstNode
  AnchorSubst = tuple
    mainAnchor: string
    aliases: seq[string]
  FootnoteType = enum
    fnManualNumber,     # manually numbered footnote like [3]
    fnAutoNumber,       # auto-numbered footnote [#]
    fnAutoNumberLabel,  # auto-numbered with label [#label]
    fnAutoSymbol,       # auto-symbol footnote [*]
    fnCitation          # simple text label like [citation2021]
  FootnoteSubst = tuple
    kind: FootnoteType  # discriminator
    number: int         # valid for fnManualNumber (always) and fnAutoNumber,
                        # fnAutoNumberLabel after resolveSubs is called
    autoNumIdx: int     # order of occurence: fnAutoNumber, fnAutoNumberLabel
    autoSymIdx: int     # order of occurence: fnAutoSymbol
    label: string       # valid for fnAutoNumberLabel

  SharedState = object
    options: RstParseOptions    # parsing options
    uLevel, oLevel: int         # counters for the section levels
    subs: seq[Substitution]     # substitutions
    refs: seq[Substitution]     # references
    anchors: seq[AnchorSubst]   # internal target substitutions
    lineFootnoteNum: seq[int]     # footnote line, auto numbers .. [#]
    lineFootnoteNumRef: seq[int]  # footnote line, their reference [#]_
    lineFootnoteSym: seq[int]     # footnote line, auto symbols .. [*]
    lineFootnoteSymRef: seq[int]  # footnote line, their reference [*]_
    footnotes: seq[FootnoteSubst] # correspondence b/w footnote label,
                                  # number, order of occurrence
    underlineToLevel: LevelMap  # Saves for each possible title adornment
                                # character its level in the
                                # current document.
                                # This is for single underline adornments.
    overlineToLevel: LevelMap   # Saves for each possible title adornment
                                # character its level in the current
                                # document.
                                # This is for over-underline adornments.
    msgHandler: MsgHandler      # How to handle errors.
    findFile: FindFileHandler   # How to find files.

  PSharedState = ref SharedState
  RstParser = object of RootObj
    idx*: int
    tok*: TokenSeq
    s*: PSharedState
    indentStack*: seq[int]
    filename*: string
    line*, col*: int
    hasToc*: bool
    curAnchor*: string          # variable to track latest anchor in s.anchors

  EParseError* = object of ValueError

template currentTok(p: RstParser): Token = p.tok[p.idx]
template prevTok(p: RstParser): Token = p.tok[p.idx - 1]
template nextTok(p: RstParser): Token = p.tok[p.idx + 1]

proc whichMsgClass*(k: MsgKind): MsgClass =
  ## returns which message class `k` belongs to.
  case ($k)[1]
  of 'e', 'E': result = mcError
  of 'w', 'W': result = mcWarning
  of 'h', 'H': result = mcHint
  else: assert false, "msgkind does not fit naming scheme"

proc defaultMsgHandler*(filename: string, line, col: int, msgkind: MsgKind,
                        arg: string) =
  let mc = msgkind.whichMsgClass
  let a = $msgkind % arg
  let message = "$1($2, $3) $4: $5" % [filename, $line, $col, $mc, a]
  if mc == mcError: raise newException(EParseError, message)
  else: writeLine(stdout, message)

proc defaultFindFile*(filename: string): string =
  if fileExists(filename): result = filename
  else: result = ""

proc newSharedState(options: RstParseOptions,
                    findFile: FindFileHandler,
                    msgHandler: MsgHandler): PSharedState =
  new(result)
  result.subs = @[]
  result.refs = @[]
  result.options = options
  result.msgHandler = if not isNil(msgHandler): msgHandler else: defaultMsgHandler
  result.findFile = if not isNil(findFile): findFile else: defaultFindFile

proc curLine(p: RstParser): int = p.line + currentTok(p).line

proc findRelativeFile(p: RstParser; filename: string): string =
  result = p.filename.splitFile.dir / filename
  if not fileExists(result):
    result = p.s.findFile(filename)

proc rstMessage(p: RstParser, msgKind: MsgKind, arg: string) =
  p.s.msgHandler(p.filename, curLine(p),
                             p.col + currentTok(p).col, msgKind, arg)

proc rstMessage(p: RstParser, msgKind: MsgKind, arg: string, line, col: int) =
  p.s.msgHandler(p.filename, p.line + line,
                             p.col + col, msgKind, arg)

proc rstMessage(p: RstParser, msgKind: MsgKind) =
  p.s.msgHandler(p.filename, curLine(p),
                             p.col + currentTok(p).col, msgKind,
                             currentTok(p).symbol)

proc currInd(p: RstParser): int =
  result = p.indentStack[high(p.indentStack)]

proc pushInd(p: var RstParser, ind: int) =
  p.indentStack.add(ind)

proc popInd(p: var RstParser) =
  if p.indentStack.len > 1: setLen(p.indentStack, p.indentStack.len - 1)

proc initParser(p: var RstParser, sharedState: PSharedState) =
  p.indentStack = @[0]
  p.tok = @[]
  p.idx = 0
  p.filename = ""
  p.hasToc = false
  p.col = 0
  p.line = 1
  p.s = sharedState

proc addNodesAux(n: PRstNode, result: var string) =
  if n.kind == rnLeaf:
    result.add(n.text)
  else:
    for i in 0 ..< n.len: addNodesAux(n.sons[i], result)

proc addNodes(n: PRstNode): string =
  n.addNodesAux(result)

proc rstnodeToRefnameAux(n: PRstNode, r: var string, b: var bool) =
  template special(s) =
    if b:
      r.add('-')
      b = false
    r.add(s)

  if n == nil: return
  if n.kind == rnLeaf:
    for i in 0 ..< n.text.len:
      case n.text[i]
      of '0'..'9':
        if b:
          r.add('-')
          b = false
        if r.len == 0: r.add('Z')
        r.add(n.text[i])
      of 'a'..'z', '\128'..'\255':
        if b:
          r.add('-')
          b = false
        r.add(n.text[i])
      of 'A'..'Z':
        if b:
          r.add('-')
          b = false
        r.add(chr(ord(n.text[i]) - ord('A') + ord('a')))
      of '$': special "dollar"
      of '%': special "percent"
      of '&': special "amp"
      of '^': special "roof"
      of '!': special "emark"
      of '?': special "qmark"
      of '*': special "star"
      of '+': special "plus"
      of '-': special "minus"
      of '/': special "slash"
      of '\\': special "backslash"
      of '=': special "eq"
      of '<': special "lt"
      of '>': special "gt"
      of '~': special "tilde"
      of ':': special "colon"
      of '.': special "dot"
      of '@': special "at"
      of '|': special "bar"
      else:
        if r.len > 0: b = true
  else:
    for i in 0 ..< n.len: rstnodeToRefnameAux(n.sons[i], r, b)

proc rstnodeToRefname(n: PRstNode): string =
  var b = false
  rstnodeToRefnameAux(n, result, b)

proc findSub(p: var RstParser, n: PRstNode): int =
  var key = addNodes(n)
  # the spec says: if no exact match, try one without case distinction:
  for i in countup(0, high(p.s.subs)):
    if key == p.s.subs[i].key:
      return i
  for i in countup(0, high(p.s.subs)):
    if cmpIgnoreStyle(key, p.s.subs[i].key) == 0:
      return i
  result = -1

proc setSub(p: var RstParser, key: string, value: PRstNode) =
  var length = p.s.subs.len
  for i in 0 ..< length:
    if key == p.s.subs[i].key:
      p.s.subs[i].value = value
      return
  p.s.subs.add(Substitution(key: key, value: value))

proc setRef(p: var RstParser, key: string, value: PRstNode) =
  var length = p.s.refs.len
  for i in 0 ..< length:
    if key == p.s.refs[i].key:
      if p.s.refs[i].value.addNodes != value.addNodes:
        rstMessage(p, mwRedefinitionOfLabel, key)
      p.s.refs[i].value = value
      return
  p.s.refs.add(Substitution(key: key, value: value))

proc findRef(p: var RstParser, key: string): PRstNode =
  for i in countup(0, high(p.s.refs)):
    if key == p.s.refs[i].key:
      return p.s.refs[i].value

proc addAnchor(p: var RstParser, refn: string, reset: bool) =
  ## add anchor `refn` to anchor aliases and update last anchor ``curAnchor``
  if p.curAnchor == "":
    p.s.anchors.add (refn, @[refn])
  else:
    p.s.anchors[^1].mainAnchor = refn
    p.s.anchors[^1].aliases.add refn
  if reset:
    p.curAnchor = ""
  else:
    p.curAnchor = refn

proc findMainAnchor(p: RstParser, refn: string): string =
  for subst in p.s.anchors:
    if subst.mainAnchor == refn:  # no need to rename
      result = subst.mainAnchor
      break
    var toLeave = false
    for anchor in subst.aliases:
      if anchor == refn:  # this anchor will be named as mainAnchor
        result = subst.mainAnchor
        toLeave = true
    if toLeave:
      break

proc addFootnoteNumManual(p: var RstParser, num: int) =
  ## add manually-numbered footnote
  for fnote in p.s.footnotes:
    if fnote.number == num:
      rstMessage(p, mwRedefinitionOfLabel, $num)
      return
  p.s.footnotes.add((fnManualNumber, num, -1, -1, $num))

proc addFootnoteNumAuto(p: var RstParser, label: string) =
  ## add auto-numbered footnote.
  ## Empty label [#] means it'll be resolved by the occurrence.
  if label == "":  # simple auto-numbered [#]
    p.s.lineFootnoteNum.add curLine(p)
    p.s.footnotes.add((fnAutoNumber, -1, p.s.lineFootnoteNum.len, -1, label))
  else:           # auto-numbered with label [#label]
    for fnote in p.s.footnotes:
      if fnote.label == label:
        rstMessage(p, mwRedefinitionOfLabel, label)
        return
    p.s.footnotes.add((fnAutoNumberLabel, -1, -1, -1, label))

proc addFootnoteSymAuto(p: var RstParser) =
  p.s.lineFootnoteSym.add curLine(p)
  p.s.footnotes.add((fnAutoSymbol, -1, -1, p.s.lineFootnoteSym.len, ""))

proc orderFootnotes(p: var RstParser) =
  ## numerate auto-numbered footnotes taking into account that all
  ## manually numbered ones always have preference.
  ## Save the result back to p.s.footnotes.

  # Report an error if found any mismatch in number of automatic footnotes
  proc listFootnotes(lines: seq[int]): string =
    result.add $lines.len & " (lines " & join(lines, ", ") & ")"
  if p.s.lineFootnoteNum.len != p.s.lineFootnoteNumRef.len:
    rstMessage(p, meFootnoteMismatch,
      "$1 != $2" % [listFootnotes(p.s.lineFootnoteNum),
                    listFootnotes(p.s.lineFootnoteNumRef)] &
        " for auto-numbered footnotes")
  if p.s.lineFootnoteSym.len != p.s.lineFootnoteSymRef.len:
    rstMessage(p, meFootnoteMismatch,
      "$1 != $2" % [listFootnotes(p.s.lineFootnoteSym),
                    listFootnotes(p.s.lineFootnoteSymRef)] &
        " for auto-symbol footnotes")

  var result: seq[FootnoteSubst]
  var manuallyN, autoN, autoSymbol: seq[FootnoteSubst]
  for fs in p.s.footnotes:
    if fs.kind == fnManualNumber: manuallyN.add fs
    elif fs.kind in {fnAutoNumber, fnAutoNumberLabel}: autoN.add fs
    else: autoSymbol.add fs

  if autoN.len == 0:
    result = manuallyN
  else:
    # fill gaps between manually numbered footnotes in ascending order
    manuallyN.sort()  # sort by number - its first field
    var lst = initSinglyLinkedList[FootnoteSubst]()
    for elem in manuallyN: lst.append(elem)
    var firstAuto = 0
    if lst.head == nil or lst.head.value.number != 1:
      # no manual footnote [1], start numeration from 1 for auto-numbered
      lst.prepend (autoN[0].kind, 1, autoN[0].autoNumIdx, -1, autoN[0].label)
      firstAuto = 1
    var curNode = lst.head
    var nextNode: SinglyLinkedNode[FootnoteSubst]
    # go simultaneously through `autoN` and `lst` looking for gaps
    for (kind, x, autoNumIdx, y, label) in autoN[firstAuto .. ^1]:
      while (nextNode = curNode.next; nextNode != nil):
        if nextNode.value.number - curNode.value.number > 1:
          # gap found, insert new node `n` between curNode and nextNode:
          var n = newSinglyLinkedNode((kind, curNode.value.number + 1,
                                       autoNumIdx, -1, label))
          curNode.next = n
          n.next = nextNode
          curNode = n
          break
        else:
          curNode = nextNode
      if nextNode == nil:  # no gap found, just append
        lst.append (kind, curNode.value.number + 1, autoNumIdx, -1, label)
        curNode = lst.tail
    result = lst.toSeq

  # we use ASCII symbols instead of those recommended in RST specification:
  const footnoteAutoSymbols = ["*", "^", "+", "=", "~", "$", "@", "%", "&"]
  for fs in autoSymbol:
    # assignment order: *, **, ***, ^, ^^, ^^^, ... &&&, ****, *****, ...
    let i = fs.autoSymIdx - 1
    let symbolNum = (i div 3) mod footnoteAutoSymbols.len
    let nSymbols = (1 + i mod 3) + 3 * (i div (3 * footnoteAutoSymbols.len))
    let label = footnoteAutoSymbols[symbolNum].repeat(nSymbols)
    result.add((fs.kind, -1, -1, fs.autoSymIdx, label))

  p.s.footnotes = result

proc getFootnoteNum(p: var RstParser, label: string): int =
  ## get number from label. Must be called after `orderFootnotes`.
  result = -1
  for fnote in p.s.footnotes:
    if fnote.label == label:
      return fnote.number

proc getFootnoteNum(p: var RstParser, order: int): int =
  ## get number from occurrence. Must be called after `orderFootnotes`.
  result = -1
  for fnote in p.s.footnotes:
    if fnote.autoNumIdx == order:
      return fnote.number

proc getAutoSymbol(p: var RstParser, order: int): string =
  ## get symbol from occurrence of auto-symbol footnote.
  result = "???"
  for fnote in p.s.footnotes:
    if fnote.autoSymIdx == order:
      return fnote.label

proc newRstNodeA(p: var RstParser, kind: RstNodeKind): PRstNode =
  ## create node and consume the current anchor
  result = newRstNode(kind)
  if p.curAnchor != "":
    result.anchor = p.curAnchor
    p.curAnchor = ""

template newLeaf(s: string): PRstNode = newRstLeaf(s)

proc newLeaf(p: var RstParser): PRstNode =
  result = newLeaf(currentTok(p).symbol)

proc getReferenceName(p: var RstParser, endStr: string): PRstNode =
  var res = newRstNode(rnInner)
  while true:
    case currentTok(p).kind
    of tkWord, tkOther, tkWhite:
      res.add(newLeaf(p))
    of tkPunct:
      if currentTok(p).symbol == endStr:
        inc p.idx
        break
      else:
        res.add(newLeaf(p))
    else:
      rstMessage(p, meExpected, endStr)
      break
    inc p.idx
  result = res

proc untilEol(p: var RstParser): PRstNode =
  result = newRstNode(rnInner)
  while currentTok(p).kind notin {tkIndent, tkEof}:
    result.add(newLeaf(p))
    inc p.idx

proc expect(p: var RstParser, tok: string) =
  if currentTok(p).symbol == tok: inc p.idx
  else: rstMessage(p, meExpected, tok)

proc isInlineMarkupEnd(p: RstParser, markup: string): bool =
  # rst rules: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#inline-markup-recognition-rules
  result = currentTok(p).symbol == markup
  if not result: return
  # Rule 2:
  result = prevTok(p).kind notin {tkIndent, tkWhite}
  if not result: return
  # Rule 7:
  result = nextTok(p).kind in {tkIndent, tkWhite, tkEof} or
      markup in ["``", "`"] and nextTok(p).kind in {tkIndent, tkWhite, tkWord, tkEof} or
      nextTok(p).symbol[0] in
      {'\'', '\"', ')', ']', '}', '>', '-', '/', '\\', ':', '.', ',', ';', '!', '?', '_'}
  if not result: return
  # Rule 4:
  if p.idx > 0:
    if markup != "``" and prevTok(p).symbol == "\\":
      result = false

proc isInlineMarkupStart(p: RstParser, markup: string): bool =
  # rst rules: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#inline-markup-recognition-rules
  var d: char
  if markup != "_`":
    result = currentTok(p).symbol == markup
  else:  # _` is a 2 token case
    result = currentTok(p).symbol == "_" and nextTok(p).symbol == "`"
  if not result: return
  # Rule 6:
  result = p.idx == 0 or prevTok(p).kind in {tkIndent, tkWhite} or
      (markup in ["``", "`"] and prevTok(p).kind in {tkIndent, tkWhite, tkWord}) or
      prevTok(p).symbol[0] in {'\'', '\"', '(', '[', '{', '<', '-', '/', ':', '_'}
  if not result: return
  # Rule 1:
  result = nextTok(p).kind notin {tkIndent, tkWhite, tkEof}
  if not result: return
  # Rules 4 & 5:
  if p.idx > 0:
    if prevTok(p).symbol == "\\":
      result = false
    else:
      var c = prevTok(p).symbol[0]
      case c
      of '\'', '\"': d = c
      of '(': d = ')'
      of '[': d = ']'
      of '{': d = '}'
      of '<': d = '>'
      else: d = '\0'
      if d != '\0': result = nextTok(p).symbol[0] != d

proc match(p: RstParser, start: int, expr: string): bool =
  # regular expressions are:
  # special char     exact match
  # 'w'              tkWord
  # ' '              tkWhite
  # 'a'              tkAdornment
  # 'i'              tkIndent
  # 'I'              tkIndent or tkEof
  # 'p'              tkPunct
  # 'T'              always true
  # 'E'              whitespace, indent or eof
  # 'e'              any enumeration sequence or '#' (for enumeration lists)
  # 'x'              a..z or '#' (for enumeration lists)
  # 'n'              0..9 or '#' (for enumeration lists)
  var i = 0
  var j = start
  var last = expr.len - 1
  while i <= last:
    case expr[i]
    of 'w': result = p.tok[j].kind == tkWord
    of ' ': result = p.tok[j].kind == tkWhite
    of 'i': result = p.tok[j].kind == tkIndent
    of 'I': result = p.tok[j].kind in {tkIndent, tkEof}
    of 'p': result = p.tok[j].kind == tkPunct
    of 'a': result = p.tok[j].kind == tkAdornment
    of 'o': result = p.tok[j].kind == tkOther
    of 'T': result = true
    of 'E': result = p.tok[j].kind in {tkEof, tkWhite, tkIndent}
    of 'e', 'x', 'n':
      result = p.tok[j].kind == tkWord or p.tok[j].symbol == "#"
      if result:
        case p.tok[j].symbol[0]
        of '#': result = true
        of 'a'..'z', 'A'..'Z':
          result = expr[i] in {'e', 'x'} and p.tok[j].symbol.len == 1
        of '0'..'9':
          result = expr[i] in {'e', 'n'} and
                     allCharsInSet(p.tok[j].symbol, {'0'..'9'})
        else: result = false
    else:
      var c = expr[i]
      var length = 0
      while i <= last and expr[i] == c:
        inc i
        inc length
      dec i
      result = p.tok[j].kind in {tkPunct, tkAdornment} and
          p.tok[j].symbol.len == length and p.tok[j].symbol[0] == c
    if not result: return
    inc j
    inc i
  result = true

proc fixupEmbeddedRef(n, a, b: PRstNode) =
  var sep = - 1
  for i in countdown(n.len - 2, 0):
    if n.sons[i].text == "<":
      sep = i
      break
  var incr = if sep > 0 and n.sons[sep - 1].text[0] == ' ': 2 else: 1
  for i in countup(0, sep - incr): a.add(n.sons[i])
  for i in countup(sep + 1, n.len - 2): b.add(n.sons[i])

proc parsePostfix(p: var RstParser, n: PRstNode): PRstNode =
  var newKind = n.kind
  var newSons = n.sons
  if isInlineMarkupEnd(p, "_") or isInlineMarkupEnd(p, "__"):
    inc p.idx
    if p.tok[p.idx-2].symbol == "`" and p.tok[p.idx-3].symbol == ">":
      var a = newRstNode(rnInner)
      var b = newRstNode(rnInner)
      fixupEmbeddedRef(n, a, b)
      if a.len == 0:
        newKind = rnStandaloneHyperlink
        newSons = @[b]
      else:
        newKind = rnHyperlink
        newSons = @[a, b]
        setRef(p, rstnodeToRefname(a), b)
    elif n.kind == rnInterpretedText:
      newKind = rnRef
    else:
      newKind = rnRef
      newSons = @[n]
    result = newRstNode(newKind, newSons)
  elif match(p, p.idx, ":w:"):
    # a role:
    if nextTok(p).symbol == "idx":
      newKind = rnIdx
    elif nextTok(p).symbol == "literal":
      newKind = rnInlineLiteral
    elif nextTok(p).symbol == "strong":
      newKind = rnStrongEmphasis
    elif nextTok(p).symbol == "emphasis":
      newKind = rnEmphasis
    elif nextTok(p).symbol == "sub" or
        nextTok(p).symbol == "subscript":
      newKind = rnSub
    elif nextTok(p).symbol == "sup" or
        nextTok(p).symbol == "supscript":
      newKind = rnSup
    else:
      newKind = rnGeneralRole
      let newN = newRstNode(rnInner, n.sons)
      newSons = @[newN, newLeaf(nextTok(p).symbol)]
    inc p.idx, 3
    result = newRstNode(newKind, newSons)
  else:  # no change
    result = n

proc matchVerbatim(p: RstParser, start: int, expr: string): int =
  result = start
  var j = 0
  while j < expr.len and result < p.tok.len and
        continuesWith(expr, p.tok[result].symbol, j):
    inc j, p.tok[result].symbol.len
    inc result
  if j < expr.len: result = 0

proc parseSmiley(p: var RstParser): PRstNode =
  if currentTok(p).symbol[0] notin SmileyStartChars: return
  for key, val in items(Smilies):
    let m = matchVerbatim(p, p.idx, key)
    if m > 0:
      p.idx = m
      result = newRstNode(rnSmiley)
      result.text = val
      return

proc isUrl(p: RstParser, i: int): bool =
  result = p.tok[i+1].symbol == ":" and p.tok[i+2].symbol == "//" and
    p.tok[i+3].kind == tkWord and
    p.tok[i].symbol in ["http", "https", "ftp", "telnet", "file"]

proc parseWordOrUrl(p: var RstParser, father: PRstNode) =
  #if currentTok(p).symbol[strStart] == '<':
  if isUrl(p, p.idx):
    var n = newRstNode(rnStandaloneHyperlink)
    while true:
      case currentTok(p).kind
      of tkWord, tkAdornment, tkOther: discard
      of tkPunct:
        if nextTok(p).kind notin {tkWord, tkAdornment, tkOther, tkPunct}:
          break
      else: break
      n.add(newLeaf(p))
      inc p.idx
    father.add(n)
  else:
    var n = newLeaf(p)
    inc p.idx
    if currentTok(p).symbol == "_": n = parsePostfix(p, n)
    father.add(n)

proc parseBackslash(p: var RstParser, father: PRstNode) =
  assert(currentTok(p).kind == tkPunct)
  if currentTok(p).symbol == "\\\\":
    father.add newLeaf("\\")
    inc p.idx
  elif currentTok(p).symbol == "\\":
    # XXX: Unicode?
    inc p.idx
    if currentTok(p).kind != tkWhite: father.add(newLeaf(p))
    if currentTok(p).kind != tkEof: inc p.idx
  else:
    father.add(newLeaf(p))
    inc p.idx

proc parseUntil(p: var RstParser, father: PRstNode, postfix: string,
                interpretBackslash: bool) =
  let
    line = currentTok(p).line
    col = currentTok(p).col
  inc p.idx
  while true:
    case currentTok(p).kind
    of tkPunct:
      if isInlineMarkupEnd(p, postfix):
        inc p.idx
        break
      elif interpretBackslash:
        parseBackslash(p, father)
      else:
        father.add(newLeaf(p))
        inc p.idx
    of tkAdornment, tkWord, tkOther:
      father.add(newLeaf(p))
      inc p.idx
    of tkIndent:
      father.add newLeaf(" ")
      inc p.idx
      if currentTok(p).kind == tkIndent:
        rstMessage(p, meExpected, postfix, line, col)
        break
    of tkWhite:
      father.add newLeaf(" ")
      inc p.idx
    else: rstMessage(p, meExpected, postfix, line, col)

proc parseMarkdownCodeblock(p: var RstParser): PRstNode =
  var args = newRstNode(rnDirArg)
  if currentTok(p).kind == tkWord:
    args.add(newLeaf(p))
    inc p.idx
  else:
    args = nil
  var n = newLeaf("")
  while true:
    case currentTok(p).kind
    of tkEof:
      rstMessage(p, meExpected, "```")
      break
    of tkPunct, tkAdornment:
      if currentTok(p).symbol == "```":
        inc p.idx
        break
      else:
        n.text.add(currentTok(p).symbol)
        inc p.idx
    else:
      n.text.add(currentTok(p).symbol)
      inc p.idx
  var lb = newRstNode(rnLiteralBlock)
  lb.add(n)
  result = newRstNodeA(p, rnCodeBlock)
  result.add(args)
  result.add(PRstNode(nil))
  result.add(lb)

proc parseMarkdownLink(p: var RstParser; father: PRstNode): bool =
  result = true
  var desc, link = ""
  var i = p.idx

  template parse(endToken, dest) =
    inc i # skip begin token
    while true:
      if p.tok[i].kind in {tkEof, tkIndent}: return false
      if p.tok[i].symbol == endToken: break
      dest.add p.tok[i].symbol
      inc i
    inc i # skip end token

  parse("]", desc)
  if p.tok[i].symbol != "(": return false
  parse(")", link)
  let child = newRstNode(rnHyperlink)
  child.add desc
  child.add link
  # only commit if we detected no syntax error:
  father.add child
  p.idx = i
  result = true

proc getFootnoteType(label: PRstNode): (FootnoteType, int) =
  if label.sons.len >= 1 and label.sons[0].kind == rnLeaf and
      label.sons[0].text == "#":
    if label.sons.len == 1:
      result = (fnAutoNumber, -1)
    else:
      result = (fnAutoNumberLabel, -1)
  elif label.len == 1 and label.sons[0].kind == rnLeaf and
       label.sons[0].text == "*":
    result = (fnAutoSymbol, -1)
  elif label.len == 1 and label.sons[0].kind == rnLeaf:
    try:
      result = (fnManualNumber, parseInt(label.sons[0].text))
    except:
      result = (fnCitation, -1)
  else:
    result = (fnCitation, -1)

proc validRefnamePunct(x: string): bool =
  ## https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#reference-names
  x.len == 1 and x[0] in {'-', '_', '.', ':', '+'}

proc parseFootnoteName(p: var RstParser, reference: bool): PRstNode =
  ## parse footnote/citation label. Precondition: start at `[`.
  ## Label text should be valid ref. name symbol, otherwise nil is returned.
  var i = p.idx + 1
  result = newRstNode(rnInner)
  while true:
    if p.tok[i].kind in {tkEof, tkIndent, tkWhite}:
      return nil
    if p.tok[i].kind == tkPunct:
      case p.tok[i].symbol:
      of "]":
        if i > p.idx + 1 and (not reference or (p.tok[i+1].kind == tkPunct and p.tok[i+1].symbol == "_")):
          inc i                # skip ]
          if reference: inc i  # skip _
          break  # to succeed, it's a footnote/citation indeed
        else:
          return nil
      of "#":
        if i != p.idx + 1:
          return nil
      of "*":
        if i != p.idx + 1 and p.tok[i].kind != tkPunct and p.tok[i+1].symbol != "]":
          return nil
      else:
        if not validRefnamePunct(p.tok[i].symbol):
          return nil
    result.add newLeaf(p.tok[i].symbol)
    inc i
  p.idx = i

proc parseInline(p: var RstParser, father: PRstNode) =
  var n: PRstNode  # to be used in `if` condition
  case currentTok(p).kind
  of tkPunct:
    if isInlineMarkupStart(p, "***"):
      var n = newRstNode(rnTripleEmphasis)
      parseUntil(p, n, "***", true)
      father.add(n)
    elif isInlineMarkupStart(p, "**"):
      var n = newRstNode(rnStrongEmphasis)
      parseUntil(p, n, "**", true)
      father.add(n)
    elif isInlineMarkupStart(p, "*"):
      var n = newRstNode(rnEmphasis)
      parseUntil(p, n, "*", true)
      father.add(n)
    elif isInlineMarkupStart(p, "_`"):
      var n = newRstNode(rnInlineTarget)
      inc p.idx
      parseUntil(p, n, "`", false)
      let refn = rstnodeToRefname(n)
      p.s.anchors.add (refn, @[refn])
      father.add(n)
    elif roSupportMarkdown in p.s.options and currentTok(p).symbol == "```":
      inc p.idx
      father.add(parseMarkdownCodeblock(p))
    elif isInlineMarkupStart(p, "``"):
      var n = newRstNode(rnInlineLiteral)
      parseUntil(p, n, "``", false)
      father.add(n)
    elif isInlineMarkupStart(p, "`"):
      var n = newRstNode(rnInterpretedText)
      parseUntil(p, n, "`", true)
      n = parsePostfix(p, n)
      father.add(n)
    elif isInlineMarkupStart(p, "|"):
      var n = newRstNode(rnSubstitutionReferences)
      parseUntil(p, n, "|", false)
      father.add(n)
    elif roSupportMarkdown in p.s.options and
        currentTok(p).symbol == "[" and nextTok(p).symbol != "[" and
        parseMarkdownLink(p, father):
      discard "parseMarkdownLink already processed it"
    elif isInlineMarkupStart(p, "[") and nextTok(p).symbol != "[" and
         (n = parseFootnoteName(p, reference=true); n != nil):
      var nn = newRstNode(rnFootnoteRef)
      nn.add n
      let (fnType, _) = getFootnoteType(n)
      case fnType
      of fnAutoSymbol:
        p.s.lineFootnoteSymRef.add curLine(p)
        nn.order = p.s.lineFootnoteSymRef.len
      of fnAutoNumber:
        p.s.lineFootnoteNumRef.add curLine(p)
        nn.order = p.s.lineFootnoteNumRef.len
      else: discard
      father.add(nn)
    else:
      if roSupportSmilies in p.s.options:
        let n = parseSmiley(p)
        if n != nil:
          father.add(n)
          return
      parseBackslash(p, father)
  of tkWord:
    if roSupportSmilies in p.s.options:
      let n = parseSmiley(p)
      if n != nil:
        father.add(n)
        return
    parseWordOrUrl(p, father)
  of tkAdornment, tkOther, tkWhite:
    if roSupportMarkdown in p.s.options and currentTok(p).symbol == "```":
      inc p.idx
      father.add(parseMarkdownCodeblock(p))
      return
    if roSupportSmilies in p.s.options:
      let n = parseSmiley(p)
      if n != nil:
        father.add(n)
        return
    father.add(newLeaf(p))
    inc p.idx
  else: discard

proc getDirective(p: var RstParser): string =
  if currentTok(p).kind == tkWhite and nextTok(p).kind == tkWord:
    var j = p.idx
    inc p.idx
    result = currentTok(p).symbol
    inc p.idx
    while currentTok(p).kind in {tkWord, tkPunct, tkAdornment, tkOther}:
      if currentTok(p).symbol == "::": break
      result.add(currentTok(p).symbol)
      inc p.idx
    if currentTok(p).kind == tkWhite: inc p.idx
    if currentTok(p).symbol == "::":
      inc p.idx
      if currentTok(p).kind == tkWhite: inc p.idx
    else:
      p.idx = j               # set back
      result = ""             # error
  else:
    result = ""
  result = result.toLowerAscii()

proc parseComment(p: var RstParser): PRstNode =
  case currentTok(p).kind
  of tkIndent, tkEof:
    if currentTok(p).kind != tkEof and nextTok(p).kind == tkIndent:
      inc p.idx              # empty comment
    else:
      var indent = currentTok(p).ival
      while true:
        case currentTok(p).kind
        of tkEof:
          break
        of tkIndent:
          if currentTok(p).ival < indent: break
        else:
          discard
        inc p.idx
  else:
    while currentTok(p).kind notin {tkIndent, tkEof}: inc p.idx
  result = nil

proc parseLine(p: var RstParser, father: PRstNode) =
  while true:
    case currentTok(p).kind
    of tkWhite, tkWord, tkOther, tkPunct: parseInline(p, father)
    else: break

proc parseUntilNewline(p: var RstParser, father: PRstNode) =
  while true:
    case currentTok(p).kind
    of tkWhite, tkWord, tkAdornment, tkOther, tkPunct: parseInline(p, father)
    of tkEof, tkIndent: break

proc parseSection(p: var RstParser, result: PRstNode) {.gcsafe.}
proc parseField(p: var RstParser): PRstNode =
  ## Returns a parsed rnField node.
  ##
  ## rnField nodes have two children nodes, a rnFieldName and a rnFieldBody.
  result = newRstNode(rnField)
  var col = currentTok(p).col
  var fieldname = newRstNode(rnFieldName)
  parseUntil(p, fieldname, ":", false)
  var fieldbody = newRstNode(rnFieldBody)
  if currentTok(p).kind != tkIndent: parseLine(p, fieldbody)
  if currentTok(p).kind == tkIndent:
    var indent = currentTok(p).ival
    if indent > col:
      pushInd(p, indent)
      parseSection(p, fieldbody)
      popInd(p)
  result.add(fieldname)
  result.add(fieldbody)

proc parseFields(p: var RstParser): PRstNode =
  ## Parses fields for a section or directive block.
  ##
  ## This proc may return nil if the parsing doesn't find anything of value,
  ## otherwise it will return a node of rnFieldList type with children.
  result = nil
  var atStart = p.idx == 0 and p.tok[0].symbol == ":"
  if currentTok(p).kind == tkIndent and nextTok(p).symbol == ":" or
      atStart:
    var col = if atStart: currentTok(p).col else: currentTok(p).ival
    result = newRstNodeA(p, rnFieldList)
    if not atStart: inc p.idx
    while true:
      result.add(parseField(p))
      if currentTok(p).kind == tkIndent and currentTok(p).ival == col and
          nextTok(p).symbol == ":":
        inc p.idx
      else:
        break

proc getFieldValue*(n: PRstNode): string =
  ## Returns the value of a specific ``rnField`` node.
  ##
  ## This proc will assert if the node is not of the expected type. The empty
  ## string will be returned as a minimum. Any value in the rst will be
  ## stripped form leading/trailing whitespace.
  assert n.kind == rnField
  assert n.len == 2
  assert n.sons[0].kind == rnFieldName
  assert n.sons[1].kind == rnFieldBody
  result = addNodes(n.sons[1]).strip

proc getFieldValue(n: PRstNode, fieldname: string): string =
  if n.sons[1] == nil: return
  if n.sons[1].kind != rnFieldList:
    #InternalError("getFieldValue (2): " & $n.sons[1].kind)
    # We don't like internal errors here anymore as that would break the forum!
    return
  for i in 0 ..< n.sons[1].len:
    var f = n.sons[1].sons[i]
    if cmpIgnoreStyle(addNodes(f.sons[0]), fieldname) == 0:
      result = addNodes(f.sons[1])
      if result == "": result = "\x01\x01" # indicates that the field exists
      return

proc getArgument(n: PRstNode): string =
  if n.sons[0] == nil: result = ""
  else: result = addNodes(n.sons[0])

proc parseDotDot(p: var RstParser): PRstNode {.gcsafe.}
proc parseLiteralBlock(p: var RstParser): PRstNode =
  result = newRstNodeA(p, rnLiteralBlock)
  var n = newLeaf("")
  if currentTok(p).kind == tkIndent:
    var indent = currentTok(p).ival
    inc p.idx
    while true:
      case currentTok(p).kind
      of tkEof:
        break
      of tkIndent:
        if currentTok(p).ival < indent:
          break
        else:
          n.text.add("\n")
          n.text.add(spaces(currentTok(p).ival - indent))
          inc p.idx
      else:
        n.text.add(currentTok(p).symbol)
        inc p.idx
  else:
    while currentTok(p).kind notin {tkIndent, tkEof}:
      n.text.add(currentTok(p).symbol)
      inc p.idx
  result.add(n)

proc getLevel(map: var LevelMap, lvl: var int, c: char): int =
  if map[c] == 0:
    inc lvl
    map[c] = lvl
  result = map[c]

proc tokenAfterNewline(p: RstParser): int =
  result = p.idx
  while true:
    case p.tok[result].kind
    of tkEof:
      break
    of tkIndent:
      inc result
      break
    else: inc result

proc isAdornmentHeadline(p: RstParser, adornmentIdx: int): bool =
  ## check that underline/overline length is enough for the heading.
  ## No support for Unicode.
  if p.tok[adornmentIdx].symbol in ["::", "..", "|"]:
    return false
  var headlineLen = 0
  var failure = ""
  if p.idx < adornmentIdx:  # check for underline
    if p.idx > 0:
      headlineLen = currentTok(p).col - p.tok[adornmentIdx].col
    if headlineLen > 0:
      rstMessage(p, mwRstStyle, "indentation of heading text allowed" &
          " only for overline titles")
    for i in p.idx ..< adornmentIdx-1:  # adornmentIdx-1 is a linebreak
      headlineLen += p.tok[i].symbol.len
    result = p.tok[adornmentIdx].symbol.len >= headlineLen and headlineLen != 0
    if not result:
      failure = "(underline '" & p.tok[adornmentIdx].symbol & "' is too short)"
  else:  # p.idx == adornmentIdx, at overline. Check overline and underline
    var i = p.idx + 2
    headlineLen = p.tok[i].col - p.tok[adornmentIdx].col
    while p.tok[i].kind notin {tkEof, tkIndent}:
      headlineLen += p.tok[i].symbol.len
      inc i
    result = p.tok[adornmentIdx].symbol.len >= headlineLen and
         headlineLen != 0
    if result:
      result = result and p.tok[i].kind == tkIndent and
         p.tok[i+1].kind == tkAdornment and
         p.tok[i+1].symbol == p.tok[adornmentIdx].symbol
      if not result:
        failure = "(underline '" & p.tok[i+1].symbol & "' does not match " &
            "overline '" & p.tok[adornmentIdx].symbol & "')"
    else:
      failure = "(overline '" & p.tok[adornmentIdx].symbol & "' is too short)"
  if not result:
    rstMessage(p, meNewSectionExpected, failure)

proc isLineBlock(p: RstParser): bool =
  var j = tokenAfterNewline(p)
  result = currentTok(p).col == p.tok[j].col and p.tok[j].symbol == "|" or
      p.tok[j].col > currentTok(p).col or
      p.tok[j].symbol == "\n"

proc predNL(p: RstParser): bool =
  result = true
  if p.idx > 0:
    result = prevTok(p).kind == tkIndent and
        prevTok(p).ival == currInd(p)

proc isDefList(p: RstParser): bool =
  var j = tokenAfterNewline(p)
  result = currentTok(p).col < p.tok[j].col and
      p.tok[j].kind in {tkWord, tkOther, tkPunct} and
      p.tok[j - 2].symbol != "::"

proc isOptionList(p: RstParser): bool =
  result = match(p, p.idx, "-w") or match(p, p.idx, "--w") or
           match(p, p.idx, "/w") or match(p, p.idx, "//w")

proc isMarkdownHeadlinePattern(s: string): bool =
  if s.len >= 1 and s.len <= 6:
    for c in s:
      if c != '#': return false
    result = true

proc isMarkdownHeadline(p: RstParser): bool =
  if roSupportMarkdown in p.s.options:
    if isMarkdownHeadlinePattern(currentTok(p).symbol) and nextTok(p).kind == tkWhite:
      if p.tok[p.idx+2].kind in {tkWord, tkOther, tkPunct}:
        result = true

proc findPipe(p: RstParser, start: int): bool =
  var i = start
  while true:
    if p.tok[i].symbol == "|": return true
    if p.tok[i].kind in {tkIndent, tkEof}: return false
    inc i

proc whichSection(p: RstParser): RstNodeKind =
  if currentTok(p).kind in {tkAdornment, tkPunct}:
    # for punctuation sequences that can be both tkAdornment and tkPunct
    if roSupportMarkdown in p.s.options and currentTok(p).symbol == "```":
      return rnCodeBlock
    elif currentTok(p).symbol == "::":
      return rnLiteralBlock
    elif currentTok(p).symbol == ".." and predNL(p):
     return rnDirective
  case currentTok(p).kind
  of tkAdornment:
    if match(p, p.idx + 1, "iI") and currentTok(p).symbol.len >= 4:
      result = rnTransition
    elif match(p, p.idx, "+a+"):
      result = rnGridTable
      rstMessage(p, meGridTableNotImplemented)
    elif match(p, p.idx + 1, " a"): result = rnTable
    elif currentTok(p).symbol == "|" and isLineBlock(p):
      result = rnLineBlock
    elif match(p, p.idx + 1, "i") and isAdornmentHeadline(p, p.idx):
      result = rnOverline
    else:
      result = rnLeaf
  of tkPunct:
    if isMarkdownHeadline(p):
      result = rnHeadline
    elif roSupportMarkdown in p.s.options and predNL(p) and
        match(p, p.idx, "| w") and findPipe(p, p.idx+3):
      result = rnMarkdownTable
    elif currentTok(p).symbol == "|" and isLineBlock(p):
      result = rnLineBlock
    elif match(p, tokenAfterNewline(p), "aI") and
        isAdornmentHeadline(p, tokenAfterNewline(p)):
      result = rnHeadline
    elif predNL(p) and
        currentTok(p).symbol in ["+", "*", "-"] and nextTok(p).kind == tkWhite:
      result = rnBulletList
    elif match(p, p.idx, ":w:") and predNL(p):
      # (currentTok(p).symbol == ":")
      result = rnFieldList
    elif match(p, p.idx, "(e) ") or match(p, p.idx, "e) ") or
         match(p, p.idx, "e. "):
      result = rnEnumList
    elif isDefList(p):
      result = rnDefList
    elif isOptionList(p):
      result = rnOptionList
    else:
      result = rnParagraph
  of tkWord, tkOther, tkWhite:
    let tokIdx = tokenAfterNewline(p)
    if match(p, tokIdx, "aI"):
      if isAdornmentHeadline(p, tokIdx): result = rnHeadline
      else: result = rnParagraph
    elif match(p, p.idx, "e) ") or match(p, p.idx, "e. "): result = rnEnumList
    elif isDefList(p): result = rnDefList
    else: result = rnParagraph
  else: result = rnLeaf

proc parseLineBlock(p: var RstParser): PRstNode =
  ## Returns rnLineBlock with all sons of type rnLineBlockItem
  result = nil
  if nextTok(p).kind in {tkWhite, tkIndent}:
    var col = currentTok(p).col
    result = newRstNodeA(p, rnLineBlock)
    while true:
      var item = newRstNode(rnLineBlockItem)
      if nextTok(p).kind == tkWhite:
        if nextTok(p).symbol.len > 1:  # pass additional indentation after '| '
          item.lineIndent = nextTok(p).symbol
        inc p.idx, 2
        pushInd(p, p.tok[p.idx].col)
        parseSection(p, item)
        popInd(p)
      else:  # tkIndent => add an empty line
        item.lineIndent = "\n"
        inc p.idx, 1
      result.add(item)
      if currentTok(p).kind == tkIndent and currentTok(p).ival == col and
          nextTok(p).symbol == "|" and
          p.tok[p.idx + 2].kind in {tkWhite, tkIndent}:
        inc p.idx, 1
      else:
        break

proc parseParagraph(p: var RstParser, result: PRstNode) =
  while true:
    case currentTok(p).kind
    of tkIndent:
      if nextTok(p).kind == tkIndent:
        inc p.idx
        break
      elif currentTok(p).ival == currInd(p):
        inc p.idx
        case whichSection(p)
        of rnParagraph, rnLeaf, rnHeadline, rnOverline, rnDirective:
          result.add newLeaf(" ")
        of rnLineBlock:
          result.addIfNotNil(parseLineBlock(p))
        else: break
      else:
        break
    of tkPunct:
      if currentTok(p).symbol == "::" and
          nextTok(p).kind == tkIndent and
          currInd(p) < nextTok(p).ival:
        result.add newLeaf(":")
        inc p.idx            # skip '::'
        result.add(parseLiteralBlock(p))
        break
      else:
        parseInline(p, result)
    of tkWhite, tkWord, tkAdornment, tkOther:
      parseInline(p, result)
    else: break

proc parseHeadline(p: var RstParser): PRstNode =
  result = newRstNode(rnHeadline)
  if isMarkdownHeadline(p):
    result.level = currentTok(p).symbol.len
    assert(nextTok(p).kind == tkWhite)
    inc p.idx, 2
    parseUntilNewline(p, result)
  else:
    parseUntilNewline(p, result)
    assert(currentTok(p).kind == tkIndent)
    assert(nextTok(p).kind == tkAdornment)
    var c = nextTok(p).symbol[0]
    inc p.idx, 2
    result.level = getLevel(p.s.underlineToLevel, p.s.uLevel, c)
  addAnchor(p, rstnodeToRefname(result), reset=true)

type
  IntSeq = seq[int]
  ColumnLimits = tuple
    first, last: int
  ColSeq = seq[ColumnLimits]

proc tokEnd(p: RstParser): int =
  result = currentTok(p).col + currentTok(p).symbol.len - 1

proc getColumns(p: var RstParser, cols: var IntSeq) =
  var L = 0
  while true:
    inc L
    setLen(cols, L)
    cols[L - 1] = tokEnd(p)
    assert(currentTok(p).kind == tkAdornment)
    inc p.idx
    if currentTok(p).kind != tkWhite: break
    inc p.idx
    if currentTok(p).kind != tkAdornment: break
  if currentTok(p).kind == tkIndent: inc p.idx
  # last column has no limit:
  cols[L - 1] = 32000

proc parseDoc(p: var RstParser): PRstNode {.gcsafe.}

proc parseSimpleTable(p: var RstParser): PRstNode =
  var
    cols: IntSeq
    row: seq[string]
    i, last, line: int
    c: char
    q: RstParser
    a, b: PRstNode
  result = newRstNodeA(p, rnTable)
  cols = @[]
  row = @[]
  a = nil
  c = currentTok(p).symbol[0]
  while true:
    if currentTok(p).kind == tkAdornment:
      last = tokenAfterNewline(p)
      if p.tok[last].kind in {tkEof, tkIndent}:
        # skip last adornment line:
        p.idx = last
        break
      getColumns(p, cols)
      setLen(row, cols.len)
      if a != nil:
        for j in 0 ..< a.len:  # fix rnTableDataCell -> rnTableHeaderCell
          a.sons[j] = newRstNode(rnTableHeaderCell, a.sons[j].sons)
    if currentTok(p).kind == tkEof: break
    for j in countup(0, high(row)): row[j] = ""
    # the following while loop iterates over the lines a single cell may span:
    line = currentTok(p).line
    while true:
      i = 0
      while currentTok(p).kind notin {tkIndent, tkEof}:
        if tokEnd(p) <= cols[i]:
          row[i].add(currentTok(p).symbol)
          inc p.idx
        else:
          if currentTok(p).kind == tkWhite: inc p.idx
          inc i
      if currentTok(p).kind == tkIndent: inc p.idx
      if tokEnd(p) <= cols[0]: break
      if currentTok(p).kind in {tkEof, tkAdornment}: break
      for j in countup(1, high(row)): row[j].add('\x0A')
    a = newRstNode(rnTableRow)
    for j in countup(0, high(row)):
      initParser(q, p.s)
      q.col = cols[j]
      q.line = line - 1
      q.filename = p.filename
      q.col += getTokens(row[j], false, q.tok)
      b = newRstNode(rnTableDataCell)
      b.add(parseDoc(q))
      a.add(b)
    result.add(a)

proc readTableRow(p: var RstParser): ColSeq =
  if currentTok(p).symbol == "|": inc p.idx
  while currentTok(p).kind notin {tkIndent, tkEof}:
    var limits: ColumnLimits
    limits.first = p.idx
    while currentTok(p).kind notin {tkIndent, tkEof}:
      if currentTok(p).symbol == "|" and prevTok(p).symbol != "\\": break
      inc p.idx
    limits.last = p.idx
    result.add(limits)
    if currentTok(p).kind in {tkIndent, tkEof}: break
    inc p.idx
  p.idx = tokenAfterNewline(p)

proc getColContents(p: var RstParser, colLim: ColumnLimits): string =
  for i in colLim.first ..< colLim.last:
    result.add(p.tok[i].symbol)
  result.strip

proc isValidDelimiterRow(p: var RstParser, colNum: int): bool =
  let row = readTableRow(p)
  if row.len != colNum: return false
  for limits in row:
    let content = getColContents(p, limits)
    if content.len < 3 or not (content.startsWith("--") or content.startsWith(":-")):
      return false
  return true

proc parseMarkdownTable(p: var RstParser): PRstNode =
  var
    row: ColSeq
    colNum: int
    a, b: PRstNode
    q: RstParser
  result = newRstNodeA(p, rnMarkdownTable)

  proc parseRow(p: var RstParser, cellKind: RstNodeKind, result: PRstNode) =
    row = readTableRow(p)
    if colNum == 0: colNum = row.len # table header
    elif row.len < colNum: row.setLen(colNum)
    a = newRstNode(rnTableRow)
    for j in 0 ..< colNum:
      b = newRstNode(cellKind)
      initParser(q, p.s)
      q.col = p.col
      q.line = currentTok(p).line - 1
      q.filename = p.filename
      q.col += getTokens(getColContents(p, row[j]), false, q.tok)
      b.add(parseDoc(q))
      a.add(b)
    result.add(a)

  parseRow(p, rnTableHeaderCell, result)
  if not isValidDelimiterRow(p, colNum): rstMessage(p, meMarkdownIllformedTable)
  while predNL(p) and currentTok(p).symbol == "|":
    parseRow(p, rnTableDataCell, result)

proc parseTransition(p: var RstParser): PRstNode =
  result = newRstNodeA(p, rnTransition)
  inc p.idx
  if currentTok(p).kind == tkIndent: inc p.idx
  if currentTok(p).kind == tkIndent: inc p.idx

proc parseOverline(p: var RstParser): PRstNode =
  var c = currentTok(p).symbol[0]
  inc p.idx, 2
  result = newRstNode(rnOverline)
  while true:
    parseUntilNewline(p, result)
    if currentTok(p).kind == tkIndent:
      inc p.idx
      if prevTok(p).ival > currInd(p):
        result.add newLeaf(" ")
      else:
        break
    else:
      break
  result.level = getLevel(p.s.overlineToLevel, p.s.oLevel, c)
  if currentTok(p).kind == tkAdornment:
    inc p.idx                # XXX: check?
    if currentTok(p).kind == tkIndent: inc p.idx
  addAnchor(p, rstnodeToRefname(result), reset=true)

proc parseBulletList(p: var RstParser): PRstNode =
  result = nil
  if nextTok(p).kind == tkWhite:
    var bullet = currentTok(p).symbol
    var col = currentTok(p).col
    result = newRstNodeA(p, rnBulletList)
    pushInd(p, p.tok[p.idx + 2].col)
    inc p.idx, 2
    while true:
      var item = newRstNode(rnBulletItem)
      parseSection(p, item)
      result.add(item)
      if currentTok(p).kind == tkIndent and currentTok(p).ival == col and
          nextTok(p).symbol == bullet and
          p.tok[p.idx + 2].kind == tkWhite:
        inc p.idx, 3
      else:
        break
    popInd(p)

proc parseOptionList(p: var RstParser): PRstNode =
  result = newRstNodeA(p, rnOptionList)
  while true:
    if isOptionList(p):
      var a = newRstNode(rnOptionGroup)
      var b = newRstNode(rnDescription)
      var c = newRstNode(rnOptionListItem)
      if match(p, p.idx, "//w"): inc p.idx
      while currentTok(p).kind notin {tkIndent, tkEof}:
        if currentTok(p).kind == tkWhite and currentTok(p).symbol.len > 1:
          inc p.idx
          break
        a.add(newLeaf(p))
        inc p.idx
      var j = tokenAfterNewline(p)
      if j > 0 and p.tok[j - 1].kind == tkIndent and p.tok[j - 1].ival > currInd(p):
        pushInd(p, p.tok[j - 1].ival)
        parseSection(p, b)
        popInd(p)
      else:
        parseLine(p, b)
      if currentTok(p).kind == tkIndent: inc p.idx
      c.add(a)
      c.add(b)
      result.add(c)
    else:
      break

proc parseDefinitionList(p: var RstParser): PRstNode =
  result = nil
  var j = tokenAfterNewline(p) - 1
  if j >= 1 and p.tok[j].kind == tkIndent and
      p.tok[j].ival > currInd(p) and p.tok[j - 1].symbol != "::":
    var col = currentTok(p).col
    result = newRstNodeA(p, rnDefList)
    while true:
      j = p.idx
      var a = newRstNode(rnDefName)
      parseLine(p, a)
      if currentTok(p).kind == tkIndent and
          currentTok(p).ival > currInd(p) and
          nextTok(p).symbol != "::" and
          nextTok(p).kind notin {tkIndent, tkEof}:
        pushInd(p, currentTok(p).ival)
        var b = newRstNode(rnDefBody)
        parseSection(p, b)
        var c = newRstNode(rnDefItem)
        c.add(a)
        c.add(b)
        result.add(c)
        popInd(p)
      else:
        p.idx = j
        break
      if currentTok(p).kind == tkIndent and currentTok(p).ival == col:
        inc p.idx
        j = tokenAfterNewline(p) - 1
        if j >= 1 and p.tok[j].kind == tkIndent and p.tok[j].ival > col and
            p.tok[j-1].symbol != "::" and p.tok[j+1].kind != tkIndent:
          discard
        else:
          break
    if result.len == 0: result = nil

proc parseEnumList(p: var RstParser): PRstNode =
  const
    wildcards: array[0..5, string] = ["(n) ", "n) ", "n. ",
                                      "(x) ", "x) ", "x. "]
      # enumerator patterns, where 'x' means letter and 'n' means number
    wildToken: array[0..5, int] = [4, 3, 3, 4, 3, 3]  # number of tokens
    wildIndex: array[0..5, int] = [1, 0, 0, 1, 0, 0]
      # position of enumeration sequence (number/letter) in enumerator
  result = newRstNodeA(p, rnEnumList)
  let col = currentTok(p).col
  var w = 0
  while w < wildcards.len:
    if match(p, p.idx, wildcards[w]): break
    inc w
  assert w < wildcards.len
  let autoEnums = if roSupportMarkdown in p.s.options: @["#", "1"] else: @["#"]
  var prevAE = ""  # so as not allow mixing auto-enumerators `1` and `#`
  var curEnum = 1
  for i in 0 ..< wildToken[w]-1:  # add first enumerator with (, ), and .
    if p.tok[p.idx + i].symbol == "#":
      prevAE = "#"
      result.labelFmt.add "1"
    else:
      result.labelFmt.add p.tok[p.idx + i].symbol
  var prevEnum = p.tok[p.idx + wildIndex[w]].symbol
  inc p.idx, wildToken[w]
  while true:
    var item = newRstNode(rnEnumItem)
    pushInd(p, currentTok(p).col)
    parseSection(p, item)
    popInd(p)
    result.add(item)
    if currentTok(p).kind == tkIndent and currentTok(p).ival == col and
        match(p, p.idx+1, wildcards[w]):
      let enumerator = p.tok[p.idx + 1 + wildIndex[w]].symbol
      # check that it's in sequence: enumerator == next(prevEnum)
      if "n" in wildcards[w]:  # arabic numeral
        let prevEnumI = try: parseInt(prevEnum) except: 1
        if enumerator in autoEnums:
          if prevAE != "" and enumerator != prevAE:
            break
          prevAE = enumerator
          curEnum = prevEnumI + 1
        else: curEnum = (try: parseInt(enumerator) except: 1)
        if curEnum - prevEnumI != 1:
          break
        prevEnum = enumerator
      else:  # a..z
        let prevEnumI = ord(prevEnum[0])
        if enumerator == "#": curEnum = prevEnumI + 1
        else: curEnum = ord(enumerator[0])
        if curEnum - prevEnumI != 1:
          break
        prevEnum = $chr(curEnum)
      inc p.idx, 1 + wildToken[w]
    else:
      break

proc sonKind(father: PRstNode, i: int): RstNodeKind =
  result = rnLeaf
  if i < father.len: result = father.sons[i].kind

proc parseSection(p: var RstParser, result: PRstNode) =
  ## parse top-level RST elements: sections, transitions and body elements.
  while true:
    var leave = false
    assert(p.idx >= 0)
    while currentTok(p).kind == tkIndent:
      if currInd(p) == currentTok(p).ival:
        inc p.idx
      elif currentTok(p).ival > currInd(p):
        pushInd(p, currentTok(p).ival)
        var a = newRstNodeA(p, rnBlockQuote)
        parseSection(p, a)
        result.add(a)
        popInd(p)
      else:
        while currentTok(p).kind != tkEof and nextTok(p).kind == tkIndent:
          inc p.idx  # skip blank lines
        leave = true
        break
    if leave or currentTok(p).kind == tkEof: break
    var a: PRstNode = nil
    var k = whichSection(p)
    case k
    of rnLiteralBlock:
      inc p.idx              # skip '::'
      a = parseLiteralBlock(p)
    of rnBulletList: a = parseBulletList(p)
    of rnLineBlock: a = parseLineBlock(p)
    of rnDirective: a = parseDotDot(p)
    of rnEnumList: a = parseEnumList(p)
    of rnLeaf: rstMessage(p, meNewSectionExpected, "(syntax error)")
    of rnParagraph: discard
    of rnDefList: a = parseDefinitionList(p)
    of rnFieldList:
      if p.idx > 0: dec p.idx
      a = parseFields(p)
    of rnTransition: a = parseTransition(p)
    of rnHeadline: a = parseHeadline(p)
    of rnOverline: a = parseOverline(p)
    of rnTable: a = parseSimpleTable(p)
    of rnMarkdownTable: a = parseMarkdownTable(p)
    of rnOptionList: a = parseOptionList(p)
    else:
      #InternalError("rst.parseSection()")
      discard
    if a == nil and k != rnDirective:
      a = newRstNodeA(p, rnParagraph)
      parseParagraph(p, a)
    result.addIfNotNil(a)
  if sonKind(result, 0) == rnParagraph and sonKind(result, 1) != rnParagraph:
    result.sons[0] = newRstNode(rnInner, result.sons[0].sons,
                                anchor=result.sons[0].anchor)

proc parseSectionWrapper(p: var RstParser): PRstNode =
  result = newRstNode(rnInner)
  parseSection(p, result)
  while result.kind == rnInner and result.len == 1:
    result = result.sons[0]

proc `$`(t: Token): string =
  result = $t.kind & ' ' & t.symbol

proc parseDoc(p: var RstParser): PRstNode =
  result = parseSectionWrapper(p)
  if currentTok(p).kind != tkEof:
    rstMessage(p, meGeneralParseError)

type
  DirFlag = enum
    hasArg, hasOptions, argIsFile, argIsWord
  DirFlags = set[DirFlag]
  SectionParser = proc (p: var RstParser): PRstNode {.nimcall.}

proc parseDirective(p: var RstParser, k: RstNodeKind, flags: DirFlags): PRstNode =
  ## Parses arguments and options for a directive block.
  ##
  ## A directive block will always have three sons: the arguments for the
  ## directive (rnDirArg), the options (rnFieldList) and the directive
  ## content block. This proc parses the two first nodes, the 3rd is left to
  ## the outer `parseDirective` call.
  ##
  ## Both rnDirArg and rnFieldList children nodes might be nil, so you need to
  ## check them before accessing.
  result = newRstNodeA(p, k)
  var args: PRstNode = nil
  var options: PRstNode = nil
  if hasArg in flags:
    args = newRstNode(rnDirArg)
    if argIsFile in flags:
      while true:
        case currentTok(p).kind
        of tkWord, tkOther, tkPunct, tkAdornment:
          args.add(newLeaf(p))
          inc p.idx
        else: break
    elif argIsWord in flags:
      while currentTok(p).kind == tkWhite: inc p.idx
      if currentTok(p).kind == tkWord:
        args.add(newLeaf(p))
        inc p.idx
      else:
        args = nil
    else:
      parseLine(p, args)
  result.add(args)
  if hasOptions in flags:
    if currentTok(p).kind == tkIndent and currentTok(p).ival >= 3 and
        nextTok(p).symbol == ":":
      options = parseFields(p)
  result.add(options)

proc indFollows(p: RstParser): bool =
  result = currentTok(p).kind == tkIndent and currentTok(p).ival > currInd(p)

proc parseBlockContent(p: var RstParser, father: var PRstNode,
                       contentParser: SectionParser): bool =
  ## parse the final content part of explicit markup blocks (directives,
  ## footnotes, etc). Returns true if succeeded.
  if currentTok(p).kind != tkIndent or indFollows(p):
    var nextIndent = p.tok[tokenAfterNewline(p)-1].ival
    if nextIndent <= currInd(p):  # parse only this line
      nextIndent = currentTok(p).col
    pushInd(p, nextIndent)
    var content = contentParser(p)
    popInd(p)
    father.add content
    result = true

proc parseDirective(p: var RstParser, k: RstNodeKind, flags: DirFlags,
                    contentParser: SectionParser): PRstNode =
  ## A helper proc that does main work for specific directive procs.
  ## Always returns a generic rnDirective tree with these 3 children:
  ##
  ## 1) rnDirArg
  ## 2) rnFieldList
  ## 3) a node returned by `contentParser`.
  ##
  ## .. warning:: Any of the 3 children may be nil.
  result = parseDirective(p, k, flags)
  if not isNil(contentParser) and
      parseBlockContent(p, result, contentParser):
    discard "result is updated by parseBlockContent"
  else:
    result.add(PRstNode(nil))

proc parseDirBody(p: var RstParser, contentParser: SectionParser): PRstNode =
  if indFollows(p):
    pushInd(p, currentTok(p).ival)
    result = contentParser(p)
    popInd(p)

proc dirInclude(p: var RstParser): PRstNode =
  ##
  ## The following options are recognized:
  ##
  ## :start-after: text to find in the external data file
  ##
  ##     Only the content after the first occurrence of the specified
  ##     text will be included. If text is not found inclusion will
  ##     start from beginning of the file
  ##
  ## :end-before: text to find in the external data file
  ##
  ##     Only the content before the first occurrence of the specified
  ##     text (but after any after text) will be included. If text is
  ##     not found inclusion will happen until the end of the file.
  #literal : flag (empty)
  #    The entire included text is inserted into the document as a single
  #    literal block (useful for program listings).
  #encoding : name of text encoding
  #    The text encoding of the external data file. Defaults to the document's
  #    encoding (if specified).
  #
  result = nil
  var n = parseDirective(p, rnDirective, {hasArg, argIsFile, hasOptions}, nil)
  var filename = strip(addNodes(n.sons[0]))
  var path = p.findRelativeFile(filename)
  if path == "":
    rstMessage(p, meCannotOpenFile, filename)
  else:
    # XXX: error handling; recursive file inclusion!
    if getFieldValue(n, "literal") != "":
      result = newRstNode(rnLiteralBlock)
      result.add newLeaf(readFile(path))
    else:
      let inputString = readFile(path)
      let startPosition =
        block:
          let searchFor = n.getFieldValue("start-after").strip()
          if searchFor != "":
            let pos = inputString.find(searchFor)
            if pos != -1: pos + searchFor.len
            else: 0
          else:
            0

      let endPosition =
        block:
          let searchFor = n.getFieldValue("end-before").strip()
          if searchFor != "":
            let pos = inputString.find(searchFor, start = startPosition)
            if pos != -1: pos - 1
            else: 0
          else:
            inputString.len - 1

      var q: RstParser
      initParser(q, p.s)
      q.filename = path
      q.col += getTokens(
        inputString[startPosition..endPosition].strip(),
        false,
        q.tok)
      # workaround a GCC bug; more like the interior pointer bug?
      #if find(q.tok[high(q.tok)].symbol, "\0\x01\x02") > 0:
      #  InternalError("Too many binary zeros in include file")
      result = parseDoc(q)

proc dirCodeBlock(p: var RstParser, nimExtension = false): PRstNode =
  ## Parses a code block.
  ##
  ## Code blocks are rnDirective trees with a `kind` of rnCodeBlock. See the
  ## description of ``parseDirective`` for further structure information.
  ##
  ## Code blocks can come in two forms, the standard `code directive
  ## <http://docutils.sourceforge.net/docs/ref/rst/directives.html#code>`_ and
  ## the nim extension ``.. code-block::``. If the block is an extension, we
  ## want the default language syntax highlighting to be Nim, so we create a
  ## fake internal field to communicate with the generator. The field is named
  ## ``default-language``, which is unlikely to collide with a field specified
  ## by any random rst input file.
  ##
  ## As an extension this proc will process the ``file`` extension field and if
  ## present will replace the code block with the contents of the referenced
  ## file.
  result = parseDirective(p, rnCodeBlock, {hasArg, hasOptions}, parseLiteralBlock)
  var filename = strip(getFieldValue(result, "file"))
  if filename != "":
    var path = p.findRelativeFile(filename)
    if path == "": rstMessage(p, meCannotOpenFile, filename)
    var n = newRstNode(rnLiteralBlock)
    n.add newLeaf(readFile(path))
    result.sons[2] = n

  # Extend the field block if we are using our custom Nim extension.
  if nimExtension:
    # Create a field block if the input block didn't have any.
    if result.sons[1].isNil: result.sons[1] = newRstNode(rnFieldList)
    assert result.sons[1].kind == rnFieldList
    # Hook the extra field and specify the Nim language as value.
    var extraNode = newRstNode(rnField)
    extraNode.add(newRstNode(rnFieldName))
    extraNode.add(newRstNode(rnFieldBody))
    extraNode.sons[0].add newLeaf("default-language")
    extraNode.sons[1].add newLeaf("Nim")
    result.sons[1].add(extraNode)

proc dirContainer(p: var RstParser): PRstNode =
  result = parseDirective(p, rnContainer, {hasArg}, parseSectionWrapper)
  assert(result.len == 3)

proc dirImage(p: var RstParser): PRstNode =
  result = parseDirective(p, rnImage, {hasOptions, hasArg, argIsFile}, nil)

proc dirFigure(p: var RstParser): PRstNode =
  result = parseDirective(p, rnFigure, {hasOptions, hasArg, argIsFile},
                          parseSectionWrapper)

proc dirTitle(p: var RstParser): PRstNode =
  result = parseDirective(p, rnTitle, {hasArg}, nil)

proc dirContents(p: var RstParser): PRstNode =
  result = parseDirective(p, rnContents, {hasArg}, nil)

proc dirIndex(p: var RstParser): PRstNode =
  result = parseDirective(p, rnIndex, {}, parseSectionWrapper)

proc dirAdmonition(p: var RstParser, d: string): PRstNode =
  result = parseDirective(p, rnAdmonition, {}, parseSectionWrapper)
  result.adType = d

proc dirDefaultRole(p: var RstParser): PRstNode =
  result = parseDirective(p, rnDefaultRole, {hasArg}, nil)

proc dirRawAux(p: var RstParser, result: var PRstNode, kind: RstNodeKind,
               contentParser: SectionParser) =
  var filename = getFieldValue(result, "file")
  if filename.len > 0:
    var path = p.findRelativeFile(filename)
    if path.len == 0:
      rstMessage(p, meCannotOpenFile, filename)
    else:
      var f = readFile(path)
      result = newRstNode(kind)
      result.add newLeaf(f)
  else:
    result = newRstNode(kind, result.sons)
    result.add(parseDirBody(p, contentParser))

proc dirRaw(p: var RstParser): PRstNode =
  #
  #The following options are recognized:
  #
  #file : string (newlines removed)
  #    The local filesystem path of a raw data file to be included.
  #
  # html
  # latex
  result = parseDirective(p, rnDirective, {hasOptions, hasArg, argIsWord})
  if result.sons[0] != nil:
    if cmpIgnoreCase(result.sons[0].sons[0].text, "html") == 0:
      dirRawAux(p, result, rnRawHtml, parseLiteralBlock)
    elif cmpIgnoreCase(result.sons[0].sons[0].text, "latex") == 0:
      dirRawAux(p, result, rnRawLatex, parseLiteralBlock)
    else:
      rstMessage(p, meInvalidDirective, result.sons[0].sons[0].text)
  else:
    dirRawAux(p, result, rnRaw, parseSectionWrapper)

proc selectDir(p: var RstParser, d: string): PRstNode =
  result = nil
  case d
  of "admonition", "attention", "caution": result = dirAdmonition(p, d)
  of "code": result = dirCodeBlock(p)
  of "code-block": result = dirCodeBlock(p, nimExtension = true)
  of "container": result = dirContainer(p)
  of "contents": result = dirContents(p)
  of "danger", "error": result = dirAdmonition(p, d)
  of "figure": result = dirFigure(p)
  of "hint": result = dirAdmonition(p, d)
  of "image": result = dirImage(p)
  of "important": result = dirAdmonition(p, d)
  of "include": result = dirInclude(p)
  of "index": result = dirIndex(p)
  of "note": result = dirAdmonition(p, d)
  of "raw":
    if roSupportRawDirective in p.s.options:
      result = dirRaw(p)
    else:
      rstMessage(p, meInvalidDirective, d)
  of "tip": result = dirAdmonition(p, d)
  of "title": result = dirTitle(p)
  of "warning": result = dirAdmonition(p, d)
  of "default-role": result = dirDefaultRole(p)
  else:
    rstMessage(p, meInvalidDirective, d)

proc prefix(ftnType: FootnoteType): string =
  case ftnType
  of fnManualNumber: result = "footnote-"
  of fnAutoNumber: result = "footnoteauto-"
  of fnAutoNumberLabel: result = "footnote-"
  of fnAutoSymbol: result = "footnotesym-"
  of fnCitation: result = "citation-"

proc parseFootnote(p: var RstParser): PRstNode =
  ## Parses footnotes and citations, always returns 2 sons:
  ##
  ## 1) footnote label, always containing rnInner with 1 or more sons
  ## 2) footnote body, which may be nil
  inc p.idx
  let label = parseFootnoteName(p, reference=false)
  if label == nil:
    dec p.idx
    return nil
  result = newRstNode(rnFootnote)
  result.add label
  let (fnType, i) = getFootnoteType(label)
  var name = ""
  var anchor = fnType.prefix
  case fnType
  of fnManualNumber:
    addFootnoteNumManual(p, i)
    anchor.add $i
  of fnAutoNumber, fnAutoNumberLabel:
    name = rstnodeToRefname(label)
    addFootnoteNumAuto(p, name)
    if fnType == fnAutoNumberLabel:
      anchor.add name
    else:  # fnAutoNumber
      result.order = p.s.lineFootnoteNum.len
      anchor.add $result.order
  of fnAutoSymbol:
    addFootnoteSymAuto(p)
    result.order = p.s.lineFootnoteSym.len
    anchor.add $p.s.lineFootnoteSym.len
  of fnCitation:
    anchor.add rstnodeToRefname(label)
  addAnchor(p, anchor, reset=true)
  result.anchor = anchor
  if currentTok(p).kind == tkWhite: inc p.idx
  discard parseBlockContent(p, result, parseSectionWrapper)
  if result.len < 2:
    result.add nil

proc parseDotDot(p: var RstParser): PRstNode =
  # parse "explicit markup blocks"
  result = nil
  var n: PRstNode  # to store result, workaround for bug 16855
  var col = currentTok(p).col
  inc p.idx
  var d = getDirective(p)
  if d != "":
    pushInd(p, col)
    result = selectDir(p, d)
    popInd(p)
  elif match(p, p.idx, " _"):
    # hyperlink target:
    inc p.idx, 2
    var a = getReferenceName(p, ":")
    if currentTok(p).kind == tkWhite: inc p.idx
    var b = untilEol(p)
    if len(b) == 0:  # set internal anchor
      addAnchor(p, rstnodeToRefname(a), reset=false)
    else:  # external hyperlink
      setRef(p, rstnodeToRefname(a), b)
  elif match(p, p.idx, " |"):
    # substitution definitions:
    inc p.idx, 2
    var a = getReferenceName(p, "|")
    var b: PRstNode
    if currentTok(p).kind == tkWhite: inc p.idx
    if cmpIgnoreStyle(currentTok(p).symbol, "replace") == 0:
      inc p.idx
      expect(p, "::")
      b = untilEol(p)
    elif cmpIgnoreStyle(currentTok(p).symbol, "image") == 0:
      inc p.idx
      b = dirImage(p)
    else:
      rstMessage(p, meInvalidDirective, currentTok(p).symbol)
    setSub(p, addNodes(a), b)
  elif match(p, p.idx, " [") and
      (n = parseFootnote(p); n != nil):
    result = n
  else:
    result = parseComment(p)

proc resolveSubs(p: var RstParser, n: PRstNode): PRstNode =
  ## Resolves substitutions and anchor aliases, groups footnotes.
  ## Takes input node `n` and returns the same node with recursive
  ## substitutions in `n.sons` to `result`.
  result = n
  if n == nil: return
  case n.kind
  of rnSubstitutionReferences:
    var x = findSub(p, n)
    if x >= 0:
      result = p.s.subs[x].value
    else:
      var key = addNodes(n)
      var e = getEnv(key)
      if e != "": result = newLeaf(e)
      else: rstMessage(p, mwUnknownSubstitution, key)
  of rnRef:
    let refn = rstnodeToRefname(n)
    var y = findRef(p, refn)
    if y != nil:
      result = newRstNode(rnHyperlink)
      let text = newRstNode(rnInner, n.sons)
      result.sons = @[text, y]
    else:
      let s = findMainAnchor(p, refn)
      if s != "":
        result = newRstNode(rnInternalRef)
        let text = newRstNode(rnInner, n.sons)
        result.sons = @[text,        # visible text of reference
                        newLeaf(s)]  # link itself
  of rnFootnote:
    var (fnType, num) = getFootnoteType(n.sons[0])
    case fnType
    of fnManualNumber, fnCitation:
      discard "no need to alter fixed text"
    of fnAutoNumberLabel, fnAutoNumber:
      if fnType == fnAutoNumberLabel:
        let labelR = rstnodeToRefname(n.sons[0])
        num = getFootnoteNum(p, labelR)
      else:
        num = getFootnoteNum(p, n.order)
      var nn = newRstNode(rnInner)
      nn.add newLeaf($num)
      result.sons[0] = nn
    of fnAutoSymbol:
      let sym = getAutoSymbol(p, n.order)
      n.sons[0].sons[0].text = sym
    n.sons[1] = resolveSubs(p, n.sons[1])
  of rnFootnoteRef:
    var (fnType, num) = getFootnoteType(n.sons[0])
    template addLabel(number: int | string) =
      var nn = newRstNode(rnInner)
      nn.add newLeaf($number)
      result.add(nn)
    var refn = fnType.prefix
    # create new rnFootnoteRef, add final label, and finalize target refn:
    result = newRstNode(rnFootnoteRef)
    case fnType
    of fnManualNumber:
      addLabel num
      refn.add $num
    of fnAutoNumber:
      addLabel getFootnoteNum(p, n.order)
      refn.add $n.order
    of fnAutoNumberLabel:
      addLabel getFootnoteNum(p, rstnodeToRefname(n))
      refn.add rstnodeToRefname(n)
    of fnAutoSymbol:
      addLabel getAutoSymbol(p, n.order)
      refn.add $n.order
    of fnCitation:
      result.add n.sons[0]
      refn.add rstnodeToRefname(n)
    let s = findMainAnchor(p, refn)
    if s != "":
      result.add newLeaf(s)     # add link
    else:
      rstMessage(p, mwUnknownSubstitution, refn)
      result.add newLeaf(refn)  # add link
  of rnLeaf:
    discard
  of rnContents:
    p.hasToc = true
  else:
    var regroup = false
    for i in 0 ..< n.len:
      n.sons[i] = resolveSubs(p, n.sons[i])
      if n.sons[i] != nil and n.sons[i].kind == rnFootnote:
        regroup = true
    if regroup:  # group footnotes together into rnFootnoteGroup
      var newSons: seq[PRstNode]
      var i = 0
      while i < n.len:
        if n.sons[i] != nil and n.sons[i].kind == rnFootnote:
          var grp = newRstNode(rnFootnoteGroup)
          while i < n.len and n.sons[i].kind == rnFootnote:
            grp.sons.add n.sons[i]
            inc i
          newSons.add grp
        else:
          newSons.add n.sons[i]
          inc i
      result.sons = newSons

proc rstParse*(text, filename: string,
               line, column: int, hasToc: var bool,
               options: RstParseOptions,
               findFile: FindFileHandler = nil,
               msgHandler: MsgHandler = nil): PRstNode =
  var p: RstParser
  initParser(p, newSharedState(options, findFile, msgHandler))
  p.filename = filename
  p.line = line
  p.col = column + getTokens(text, roSkipPounds in options, p.tok)
  let unresolved = parseDoc(p)
  orderFootnotes(p)
  result = resolveSubs(p, unresolved)
  hasToc = p.hasToc
