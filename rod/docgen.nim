#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This is the documentation generator. It is currently pretty simple: No
# semantic checking is done for the code. Cross-references are generated
# by knowing how the anchors are going to be named.

import 
  ast, astalgo, strutils, nhashes, options, nversion, msgs, os, ropes, idents, 
  wordrecg, math, syntaxes, rnimsyn, scanner, rst, times, highlite

proc CommandDoc*(filename: string)
proc CommandRst2Html*(filename: string)
proc CommandRst2TeX*(filename: string)
# implementation

type 
  TTocEntry{.final.} = object 
    n*: PRstNode
    refname*, header*: PRope

  TSections = array[TSymKind, PRope]
  TMetaEnum = enum 
    metaNone, metaTitle, metaSubtitle, metaAuthor, metaVersion
  TDocumentor{.final.} = object # contains a module's documentation
    filename*: string         # filename of the source file; without extension
    basedir*: string          # base directory (where to put the documentation)
    modDesc*: PRope           # module description
    id*: int                  # for generating IDs
    splitAfter*: int          # split too long entries in the TOC
    tocPart*: seq[TTocEntry]
    hasToc*: bool
    toc*, section*: TSections
    indexFile*, theIndex*: PRstNode
    indexValFilename*: string
    indent*, verbatim*: int   # for code generation
    meta*: array[TMetaEnum, PRope]

  PDoc = ref TDocumentor

var splitter: string = "<wbr />"

proc findIndexNode(n: PRstNode): PRstNode = 
  if n == nil: 
    result = nil
  elif n.kind == rnIndex: 
    result = n.sons[2]
    if result == nil: 
      result = newRstNode(rnDefList)
      n.sons[2] = result
    elif result.kind == rnInner: 
      result = result.sons[0]
  else: 
    result = nil
    for i in countup(0, rsonsLen(n) - 1): 
      result = findIndexNode(n.sons[i])
      if result != nil: return 
  
proc initIndexFile(d: PDoc) = 
  var 
    h: PRstNode
    dummyHasToc: bool
  if gIndexFile.len == 0: return 
  gIndexFile = addFileExt(gIndexFile, "txt")
  d.indexValFilename = changeFileExt(extractFilename(d.filename), HtmlExt)
  if ExistsFile(gIndexFile): 
    d.indexFile = rstParse(readFile(gIndexFile), false, gIndexFile, 0, 1, 
                           dummyHasToc)
    d.theIndex = findIndexNode(d.indexFile)
    if (d.theIndex == nil) or (d.theIndex.kind != rnDefList): 
      rawMessage(errXisNoValidIndexFile, gIndexFile)
    clearIndex(d.theIndex, d.indexValFilename)
  else: 
    d.indexFile = newRstNode(rnInner)
    h = newRstNode(rnOverline)
    h.level = 1
    addSon(h, newRstNode(rnLeaf, "Index"))
    addSon(d.indexFile, h)
    h = newRstNode(rnIndex)
    addSon(h, nil)            # no argument
    addSon(h, nil)            # no options
    d.theIndex = newRstNode(rnDefList)
    addSon(h, d.theIndex)
    addSon(d.indexFile, h)

proc newDocumentor(filename: string): PDoc = 
  new(result)
  result.tocPart = @[]
  result.filename = filename
  result.id = 100
  result.splitAfter = 20
  var s = getConfigVar("split.item.toc")
  if s != "": result.splitAfter = parseInt(s)
  
proc getVarIdx(varnames: openarray[string], id: string): int = 
  for i in countup(0, high(varnames)): 
    if cmpIgnoreStyle(varnames[i], id) == 0: 
      return i
  result = -1

proc ropeFormatNamedVars(frmt: TFormatStr, varnames: openarray[string], 
                         varvalues: openarray[PRope]): PRope = 
  var i = 0
  var L = len(frmt)
  result = nil
  var num = 0
  while i < L: 
    if frmt[i] == '$': 
      inc(i)                  # skip '$'
      case frmt[i]
      of '#': 
        app(result, varvalues[num])
        inc(num)
        inc(i)
      of '$': 
        app(result, "$")
        inc(i)
      of '0'..'9': 
        var j = 0
        while true: 
          j = (j * 10) + Ord(frmt[i]) - ord('0')
          inc(i)
          if (i > L + 0 - 1) or not (frmt[i] in {'0'..'9'}): break 
        if j > high(varvalues) + 1: internalError("ropeFormatNamedVars")
        num = j
        app(result, varvalues[j - 1])
      of 'A'..'Z', 'a'..'z', '\x80'..'\xFF': 
        var id = ""
        while true: 
          add(id, frmt[i])
          inc(i)
          if not (frmt[i] in {'A'..'Z', '_', 'a'..'z', '\x80'..'\xFF'}): break 
        var idx = getVarIdx(varnames, id)
        if idx >= 0: app(result, varvalues[idx])
        else: rawMessage(errUnkownSubstitionVar, id)
      of '{': 
        var id = ""
        inc(i)
        while frmt[i] != '}': 
          if frmt[i] == '\0': rawMessage(errTokenExpected, "}")
          add(id, frmt[i])
          inc(i)
        inc(i)                # skip }
                              # search for the variable:
        var idx = getVarIdx(varnames, id)
        if idx >= 0: app(result, varvalues[idx])
        else: rawMessage(errUnkownSubstitionVar, id)
      else: InternalError("ropeFormatNamedVars")
    var start = i
    while i < L: 
      if (frmt[i] != '$'): inc(i)
      else: break 
    if i - 1 >= start: app(result, copy(frmt, start, i - 1))
  
proc addXmlChar(dest: var string, c: Char) = 
  case c
  of '&': add(dest, "&amp;")
  of '<': add(dest, "&lt;")
  of '>': add(dest, "&gt;")
  of '\"': add(dest, "&quot;")
  else: add(dest, c)
  
proc addRtfChar(dest: var string, c: Char) = 
  case c
  of '{': add(dest, "\\{")
  of '}': add(dest, "\\}")
  of '\\': add(dest, "\\\\")
  else: add(dest, c)
  
proc addTexChar(dest: var string, c: Char) = 
  case c
  of '_': add(dest, "\\_")
  of '{': add(dest, "\\symbol{123}")
  of '}': add(dest, "\\symbol{125}")
  of '[': add(dest, "\\symbol{91}")
  of ']': add(dest, "\\symbol{93}")
  of '\\': add(dest, "\\symbol{92}")
  of '$': add(dest, "\\$")
  of '&': add(dest, "\\&")
  of '#': add(dest, "\\#")
  of '%': add(dest, "\\%")
  of '~': add(dest, "\\symbol{126}")
  of '@': add(dest, "\\symbol{64}")
  of '^': add(dest, "\\symbol{94}")
  of '`': add(dest, "\\symbol{96}")
  else: add(dest, c)
  
proc escChar(dest: var string, c: Char) = 
  if gCmd != cmdRst2Tex: addXmlChar(dest, c)
  else: addTexChar(dest, c)
  
proc nextSplitPoint(s: string, start: int): int = 
  result = start
  while result < len(s) + 0: 
    case s[result]
    of '_': return 
    of 'a'..'z': 
      if result + 1 < len(s) + 0: 
        if s[result + 1] in {'A'..'Z'}: return 
    else: nil
    inc(result)
  dec(result)                 # last valid index
  
proc esc(s: string, splitAfter: int = - 1): string = 
  result = ""
  if splitAfter >= 0: 
    var partLen = 0
    var j = 0
    while j < len(s): 
      var k = nextSplitPoint(s, j)
      if (splitter != " ") or (partLen + k - j + 1 > splitAfter): 
        partLen = 0
        add(result, splitter)
      for i in countup(j, k): escChar(result, s[i])
      inc(partLen, k - j + 1)
      j = k + 1
  else: 
    for i in countup(0, len(s) + 0 - 1): escChar(result, s[i])
  
proc disp(xml, tex: string): string = 
  if gCmd != cmdRst2Tex: result = xml
  else: result = tex
  
proc dispF(xml, tex: string, args: openarray[PRope]): PRope = 
  if gCmd != cmdRst2Tex: result = ropef(xml, args)
  else: result = ropef(tex, args)
  
proc dispA(dest: var PRope, xml, tex: string, args: openarray[PRope]) = 
  if gCmd != cmdRst2Tex: appf(dest, xml, args)
  else: appf(dest, tex, args)
  
proc renderRstToOut(d: PDoc, n: PRstNode): PRope

proc renderAux(d: PDoc, n: PRstNode, outer: string = "$1"): PRope = 
  result = nil
  for i in countup(0, rsonsLen(n) - 1): app(result, renderRstToOut(d, n.sons[i]))
  result = ropef(outer, [result])

proc setIndexForSourceTerm(d: PDoc, name: PRstNode, id: int) = 
  if d.theIndex == nil: return 
  var h = newRstNode(rnHyperlink)
  var a = newRstNode(rnLeaf, d.indexValFilename & disp("#", "") & $id)
  addSon(h, a)
  addSon(h, a)
  a = newRstNode(rnIdx)
  addSon(a, name)
  setIndexPair(d.theIndex, a, h)

proc renderIndexTerm(d: PDoc, n: PRstNode): PRope = 
  inc(d.id)
  result = dispF("<span id=\"$1\">$2</span>", "$2\\label{$1}", 
                 [toRope(d.id), renderAux(d, n)])
  var h = newRstNode(rnHyperlink)
  var a = newRstNode(rnLeaf, d.indexValFilename & disp("#", "") & $d.id)
  addSon(h, a)
  addSon(h, a)
  setIndexPair(d.theIndex, n, h)

proc genComment(d: PDoc, n: PNode): PRope = 
  var dummyHasToc: bool
  if (n.comment != nil) and startsWith(n.comment, "##"): 
    result = renderRstToOut(d, rstParse(n.comment, true, toFilename(n.info), 
                                        toLineNumber(n.info), toColumn(n.info), 
                                        dummyHasToc))
  
proc genRecComment(d: PDoc, n: PNode): PRope = 
  if n == nil: return nil
  result = genComment(d, n)
  if result == nil: 
    if not (n.kind in {nkEmpty..nkNilLit}): 
      for i in countup(0, sonsLen(n) - 1): 
        result = genRecComment(d, n.sons[i])
        if result != nil: return 
  else: 
    n.comment = nil
  
proc isVisible(n: PNode): bool = 
  result = false
  if n.kind == nkPostfix: 
    if (sonsLen(n) == 2) and (n.sons[0].kind == nkIdent): 
      var v = n.sons[0].ident
      result = (v.id == ord(wStar)) or (v.id == ord(wMinus))
  elif n.kind == nkSym: 
    result = sfInInterface in n.sym.flags
  elif n.kind == nkPragmaExpr: 
    result = isVisible(n.sons[0])
  
proc getName(n: PNode, splitAfter: int = - 1): string = 
  case n.kind
  of nkPostfix: result = getName(n.sons[1], splitAfter)
  of nkPragmaExpr: result = getName(n.sons[0], splitAfter)
  of nkSym: result = esc(n.sym.name.s, splitAfter)
  of nkIdent: result = esc(n.ident.s, splitAfter)
  of nkAccQuoted: result = esc("`") & getName(n.sons[0], splitAfter) & esc("`")
  else: 
    internalError(n.info, "getName()")
    result = ""

proc getRstName(n: PNode): PRstNode = 
  case n.kind
  of nkPostfix: result = getRstName(n.sons[1])
  of nkPragmaExpr: result = getRstName(n.sons[0])
  of nkSym: result = newRstNode(rnLeaf, n.sym.name.s)
  of nkIdent: result = newRstNode(rnLeaf, n.ident.s)
  of nkAccQuoted: result = getRstName(n.sons[0])
  else: 
    internalError(n.info, "getRstName()")
    result = nil

proc genItem(d: PDoc, n, nameNode: PNode, k: TSymKind) = 
  if not isVisible(nameNode): return 
  var name = toRope(getName(nameNode))
  var result: PRope = nil
  var literal = ""
  var kind = tkEof
  var comm = genRecComment(d, n)  # call this here for the side-effect!
  var r: TSrcGen
  initTokRender(r, n, {renderNoPragmas, renderNoBody, renderNoComments, 
                       renderDocComments})
  while true: 
    getNextTok(r, kind, literal)
    case kind
    of tkEof: 
      break 
    of tkComment: 
      dispA(result, "<span class=\"Comment\">$1</span>", "\\spanComment{$1}", 
            [toRope(esc(literal))])
    of tokKeywordLow..tokKeywordHigh: 
      dispA(result, "<span class=\"Keyword\">$1</span>", "\\spanKeyword{$1}", 
            [toRope(literal)])
    of tkOpr, tkHat: 
      dispA(result, "<span class=\"Operator\">$1</span>", "\\spanOperator{$1}", 
            [toRope(esc(literal))])
    of tkStrLit..tkTripleStrLit: 
      dispA(result, "<span class=\"StringLit\">$1</span>", 
            "\\spanStringLit{$1}", [toRope(esc(literal))])
    of tkCharLit: 
      dispA(result, "<span class=\"CharLit\">$1</span>", "\\spanCharLit{$1}", 
            [toRope(esc(literal))])
    of tkIntLit..tkInt64Lit: 
      dispA(result, "<span class=\"DecNumber\">$1</span>", 
            "\\spanDecNumber{$1}", [toRope(esc(literal))])
    of tkFloatLit..tkFloat64Lit: 
      dispA(result, "<span class=\"FloatNumber\">$1</span>", 
            "\\spanFloatNumber{$1}", [toRope(esc(literal))])
    of tkSymbol: 
      dispA(result, "<span class=\"Identifier\">$1</span>", 
            "\\spanIdentifier{$1}", [toRope(esc(literal))])
    of tkInd, tkSad, tkDed, tkSpaces: 
      app(result, literal)
    of tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi, 
       tkBracketDotLe, tkBracketDotRi, tkCurlyDotLe, tkCurlyDotRi, tkParDotLe, 
       tkParDotRi, tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot, 
       tkAccent: 
      dispA(result, "<span class=\"Other\">$1</span>", "\\spanOther{$1}", 
            [toRope(esc(literal))])
    else: InternalError(n.info, "docgen.genThing(" & toktypeToStr[kind] & ')')
  inc(d.id)
  app(d.section[k], ropeFormatNamedVars(getConfigVar("doc.item"), 
                                        ["name", "header", "desc", "itemID"], 
                                        [name, result, comm, toRope(d.id)]))
  app(d.toc[k], ropeFormatNamedVars(getConfigVar("doc.item.toc"), 
                                    ["name", "header", "desc", "itemID"], [
      toRope(getName(nameNode, d.splitAfter)), result, comm, toRope(d.id)]))
  setIndexForSourceTerm(d, getRstName(nameNode), d.id)

proc renderHeadline(d: PDoc, n: PRstNode): PRope = 
  result = nil
  for i in countup(0, rsonsLen(n) - 1): app(result, renderRstToOut(d, n.sons[i]))
  var refname = toRope(rstnodeToRefname(n))
  if d.hasToc: 
    var length = len(d.tocPart)
    setlen(d.tocPart, length + 1)
    d.tocPart[length].refname = refname
    d.tocPart[length].n = n
    d.tocPart[length].header = result
    result = dispF("<h$1><a class=\"toc-backref\" id=\"$2\" href=\"#$2_toc\">$3</a></h$1>", 
                   "\\rsth$4{$3}\\label{$2}$n", [toRope(n.level), 
        d.tocPart[length].refname, result, 
        toRope(chr(n.level - 1 + ord('A')) & "")])
  else: 
    result = dispF("<h$1 id=\"$2\">$3</h$1>", "\\rsth$4{$3}\\label{$2}$n", [
        toRope(n.level), refname, result, 
        toRope(chr(n.level - 1 + ord('A')) & "")])
  
proc renderOverline(d: PDoc, n: PRstNode): PRope = 
  var t: PRope = nil
  for i in countup(0, rsonsLen(n) - 1): app(t, renderRstToOut(d, n.sons[i]))
  result = nil
  if d.meta[metaTitle] == nil: 
    d.meta[metaTitle] = t
  elif d.meta[metaSubtitle] == nil: 
    d.meta[metaSubtitle] = t
  else: 
    result = dispF("<h$1 id=\"$2\"><center>$3</center></h$1>", 
                   "\\rstov$4{$3}\\label{$2}$n", [toRope(n.level), 
        toRope(rstnodeToRefname(n)), t, toRope(chr(n.level - 1 + ord('A')) & "")])
  
proc renderRstToRst(d: PDoc, n: PRstNode): PRope
proc renderRstSons(d: PDoc, n: PRstNode): PRope = 
  for i in countup(0, rsonsLen(n) - 1): 
    app(result, renderRstToRst(d, n.sons[i]))
  
proc renderRstToRst(d: PDoc, n: PRstNode): PRope = 
  # this is needed for the index generation; it may also be useful for
  # debugging, but most code is already debugged...
  const 
    lvlToChar: array[0..8, char] = ['!', '=', '-', '~', '`', '<', '*', '|', '+']
  result = nil
  if n == nil: return 
  var ind = toRope(repeatChar(d.indent))
  case n.kind
  of rnInner: 
    result = renderRstSons(d, n)
  of rnHeadline: 
    result = renderRstSons(d, n)
    var L = ropeLen(result)
    result = ropef("$n$1$2$n$1$3", 
                   [ind, result, toRope(repeatChar(L, lvlToChar[n.level]))])
  of rnOverline: 
    result = renderRstSons(d, n)
    var L = ropeLen(result)
    result = ropef("$n$1$3$n$1$2$n$1$3", 
                   [ind, result, toRope(repeatChar(L, lvlToChar[n.level]))])
  of rnTransition: 
    result = ropef("$n$n$1$2$n$n", [ind, toRope(repeatChar(78 - d.indent, '-'))])
  of rnParagraph: 
    result = renderRstSons(d, n)
    result = ropef("$n$n$1$2", [ind, result])
  of rnBulletItem: 
    inc(d.indent, 2)
    result = renderRstSons(d, n)
    if result != nil: result = ropef("$n$1* $2", [ind, result])
    dec(d.indent, 2)
  of rnEnumItem: 
    inc(d.indent, 4)
    result = renderRstSons(d, n)
    if result != nil: result = ropef("$n$1(#) $2", [ind, result])
    dec(d.indent, 4)
  of rnOptionList, rnFieldList, rnDefList, rnDefItem, rnLineBlock, rnFieldName, 
     rnFieldBody, rnStandaloneHyperlink, rnBulletList, rnEnumList: 
    result = renderRstSons(d, n)
  of rnDefName: 
    result = renderRstSons(d, n)
    result = ropef("$n$n$1$2", [ind, result])
  of rnDefBody: 
    inc(d.indent, 2)
    result = renderRstSons(d, n)
    if n.sons[0].kind != rnBulletList: result = ropef("$n$1  $2", [ind, result])
    dec(d.indent, 2)
  of rnField: 
    result = renderRstToRst(d, n.sons[0])
    var L = max(ropeLen(result) + 3, 30)
    inc(d.indent, L)
    result = ropef("$n$1:$2:$3$4", [ind, result, toRope(
        repeatChar(L - ropeLen(result) - 2)), renderRstToRst(d, n.sons[1])])
    dec(d.indent, L)
  of rnLineBlockItem: 
    result = renderRstSons(d, n)
    result = ropef("$n$1| $2", [ind, result])
  of rnBlockQuote: 
    inc(d.indent, 2)
    result = renderRstSons(d, n)
    dec(d.indent, 2)
  of rnRef: 
    result = renderRstSons(d, n)
    result = ropef("`$1`_", [result])
  of rnHyperlink: 
    result = ropef("`$1 <$2>`_", 
                   [renderRstToRst(d, n.sons[0]), renderRstToRst(d, n.sons[1])])
  of rnGeneralRole: 
    result = renderRstToRst(d, n.sons[0])
    result = ropef("`$1`:$2:", [result, renderRstToRst(d, n.sons[1])])
  of rnSub: 
    result = renderRstSons(d, n)
    result = ropef("`$1`:sub:", [result])
  of rnSup: 
    result = renderRstSons(d, n)
    result = ropef("`$1`:sup:", [result])
  of rnIdx: 
    result = renderRstSons(d, n)
    result = ropef("`$1`:idx:", [result])
  of rnEmphasis: 
    result = renderRstSons(d, n)
    result = ropef("*$1*", [result])
  of rnStrongEmphasis: 
    result = renderRstSons(d, n)
    result = ropef("**$1**", [result])
  of rnInterpretedText: 
    result = renderRstSons(d, n)
    result = ropef("`$1`", [result])
  of rnInlineLiteral: 
    inc(d.verbatim)
    result = renderRstSons(d, n)
    result = ropef("``$1``", [result])
    dec(d.verbatim)
  of rnLeaf: 
    if (d.verbatim == 0) and (n.text == "\\"): 
      result = toRope("\\\\") # XXX: escape more special characters!
    else: 
      result = toRope(n.text)
  of rnIndex: 
    inc(d.indent, 3)
    if n.sons[2] != nil: result = renderRstSons(d, n.sons[2])
    dec(d.indent, 3)
    result = ropef("$n$n$1.. index::$n$2", [ind, result])
  of rnContents: 
    result = ropef("$n$n$1.. contents::", [ind])
  else: rawMessage(errCannotRenderX, $n.kind)
  
proc renderTocEntry(d: PDoc, e: TTocEntry): PRope = 
  result = dispF(
    "<li><a class=\"reference\" id=\"$1_toc\" href=\"#$1\">$2</a></li>$n", 
    "\\item\\label{$1_toc} $2\\ref{$1}$n", [e.refname, e.header])

proc renderTocEntries(d: PDoc, j: var int, lvl: int): PRope = 
  result = nil
  while j <= high(d.tocPart): 
    var a = abs(d.tocPart[j].n.level)
    if (a == lvl): 
      app(result, renderTocEntry(d, d.tocPart[j]))
      inc(j)
    elif (a > lvl): 
      app(result, renderTocEntries(d, j, a))
    else: 
      break 
  if lvl > 1: 
    result = dispF("<ul class=\"simple\">$1</ul>", 
                   "\\begin{enumerate}$1\\end{enumerate}", [result])
  
proc fieldAux(s: string): PRope = 
  result = toRope(strip(s))

proc renderImage(d: PDoc, n: PRstNode): PRope = 
  var options: PRope = nil
  var s = getFieldValue(n, "scale")
  if s != "": dispA(options, " scale=\"$1\"", " scale=$1", [fieldAux(s)])
  s = getFieldValue(n, "height")
  if s != "": dispA(options, " height=\"$1\"", " height=$1", [fieldAux(s)])
  s = getFieldValue(n, "width")
  if s != "": dispA(options, " width=\"$1\"", " width=$1", [fieldAux(s)])
  s = getFieldValue(n, "alt")
  if s != "": dispA(options, " alt=\"$1\"", "", [fieldAux(s)])
  s = getFieldValue(n, "align")
  if s != "": dispA(options, " align=\"$1\"", "", [fieldAux(s)])
  if options != nil: options = dispF("$1", "[$1]", [options])
  result = dispF("<img src=\"$1\"$2 />", "\\includegraphics$2{$1}", 
                 [toRope(getArgument(n)), options])
  if rsonsLen(n) >= 3: app(result, renderRstToOut(d, n.sons[2]))
  
proc renderCodeBlock(d: PDoc, n: PRstNode): PRope = 
  result = nil
  if n.sons[2] == nil: return 
  var m = n.sons[2].sons[0]
  if (m.kind != rnLeaf): InternalError("renderCodeBlock")
  var langstr = strip(getArgument(n))
  var lang: TSourceLanguage
  if langstr == "": 
    lang = langNimrod         # default language
  else: 
    lang = getSourceLanguage(langstr)
  if lang == langNone: 
    rawMessage(warnLanguageXNotSupported, langstr)
    result = toRope(m.text)
  else: 
    var g: TGeneralTokenizer
    initGeneralTokenizer(g, m.text)
    while true: 
      getNextToken(g, lang)
      case g.kind
      of gtEof: break 
      of gtNone, gtWhitespace: 
        app(result, copy(m.text, g.start + 0, g.length + g.start - 1 + 0))
      else: 
        dispA(result, "<span class=\"$2\">$1</span>", "\\span$2{$1}", [
            toRope(esc(copy(m.text, g.start + 0, g.length + g.start - 1 + 0))), 
            toRope(tokenClassToStr[g.kind])])
    deinitGeneralTokenizer(g)
  if result != nil: 
    result = dispF("<pre>$1</pre>", "\\begin{rstpre}$n$1$n\\end{rstpre}$n", 
                   [result])
  
proc renderContainer(d: PDoc, n: PRstNode): PRope = 
  result = renderRstToOut(d, n.sons[2])
  var arg = toRope(strip(getArgument(n)))
  if arg == nil: result = dispF("<div>$1</div>", "$1", [result])
  else: result = dispF("<div class=\"$1\">$2</div>", "$2", [arg, result])
  
proc texColumns(n: PRstNode): string = 
  result = ""
  for i in countup(1, rsonsLen(n)): add(result, "|X")
  
proc renderField(d: PDoc, n: PRstNode): PRope = 
  var b = false
  if gCmd == cmdRst2Tex: 
    var fieldname = addNodes(n.sons[0])
    var fieldval = toRope(esc(strip(addNodes(n.sons[1]))))
    if cmpIgnoreStyle(fieldname, "author") == 0: 
      if d.meta[metaAuthor] == nil: 
        d.meta[metaAuthor] = fieldval
        b = true
    elif cmpIgnoreStyle(fieldName, "version") == 0: 
      if d.meta[metaVersion] == nil: 
        d.meta[metaVersion] = fieldval
        b = true
  if b: result = nil
  else: result = renderAux(d, n, disp("<tr>$1</tr>$n", "$1"))
  
proc renderRstToOut(d: PDoc, n: PRstNode): PRope = 
  if n == nil: 
    return nil
  case n.kind
  of rnInner: result = renderAux(d, n)
  of rnHeadline: result = renderHeadline(d, n)
  of rnOverline: result = renderOverline(d, n)
  of rnTransition: result = renderAux(d, n, disp("<hr />\n", "\\hrule\n"))
  of rnParagraph: result = renderAux(d, n, disp("<p>$1</p>\n", "$1$n$n"))
  of rnBulletList: 
    result = renderAux(d, n, disp("<ul class=\"simple\">$1</ul>\n", 
                                  "\\begin{itemize}$1\\end{itemize}\n"))
  of rnBulletItem, rnEnumItem: 
    result = renderAux(d, n, disp("<li>$1</li>\n", "\\item $1\n"))
  of rnEnumList: 
    result = renderAux(d, n, disp("<ol class=\"simple\">$1</ol>\n", 
                                  "\\begin{enumerate}$1\\end{enumerate}\n"))
  of rnDefList: 
    result = renderAux(d, n, disp("<dl class=\"docutils\">$1</dl>\n", 
                       "\\begin{description}$1\\end{description}\n"))
  of rnDefItem: result = renderAux(d, n)
  of rnDefName: result = renderAux(d, n, disp("<dt>$1</dt>\n", "\\item[$1] "))
  of rnDefBody: result = renderAux(d, n, disp("<dd>$1</dd>\n", "$1\n"))
  of rnFieldList: 
    result = nil
    for i in countup(0, rsonsLen(n) - 1): 
      app(result, renderRstToOut(d, n.sons[i]))
    if result != nil: 
      result = dispf(
          "<table class=\"docinfo\" frame=\"void\" rules=\"none\">" &
          "<col class=\"docinfo-name\" />" &
          "<col class=\"docinfo-content\" />" & 
          "<tbody valign=\"top\">$1" &
          "</tbody></table>", 
          "\\begin{description}$1\\end{description}\n", 
          [result])
  of rnField: result = renderField(d, n)
  of rnFieldName: 
    result = renderAux(d, n, disp("<th class=\"docinfo-name\">$1:</th>", 
                                  "\\item[$1:]"))
  of rnFieldBody: 
    result = renderAux(d, n, disp("<td>$1</td>", " $1$n"))
  of rnIndex: 
    result = renderRstToOut(d, n.sons[2])
  of rnOptionList: 
    result = renderAux(d, n, disp("<table frame=\"void\">$1</table>", 
      "\\begin{description}$n$1\\end{description}\n"))
  of rnOptionListItem: 
    result = renderAux(d, n, disp("<tr>$1</tr>$n", "$1"))
  of rnOptionGroup: 
    result = renderAux(d, n, disp("<th align=\"left\">$1</th>", "\\item[$1]"))
  of rnDescription: 
    result = renderAux(d, n, disp("<td align=\"left\">$1</td>$n", " $1$n"))
  of rnOption, rnOptionString, rnOptionArgument: 
    InternalError("renderRstToOut")
  of rnLiteralBlock: 
    result = renderAux(d, n, disp("<pre>$1</pre>$n", 
                                  "\\begin{rstpre}$n$1$n\\end{rstpre}$n"))
  of rnQuotedLiteralBlock: 
    InternalError("renderRstToOut")
  of rnLineBlock: 
    result = renderAux(d, n, disp("<p>$1</p>", "$1$n$n"))
  of rnLineBlockItem: 
    result = renderAux(d, n, disp("$1<br />", "$1\\\\$n"))
  of rnBlockQuote: 
    result = renderAux(d, n, disp("<blockquote><p>$1</p></blockquote>$n", 
                                  "\\begin{quote}$1\\end{quote}$n"))
  of rnTable, rnGridTable: 
    result = renderAux(d, n, disp(
      "<table border=\"1\" class=\"docutils\">$1</table>", 
      "\\begin{table}\\begin{rsttab}{" &
        texColumns(n) & "|}$n\\hline$n$1\\end{rsttab}\\end{table}"))
  of rnTableRow: 
    if rsonsLen(n) >= 1: 
      result = renderRstToOut(d, n.sons[0])
      for i in countup(1, rsonsLen(n) - 1): 
        dispa(result, "$1", " & $1", [renderRstToOut(d, n.sons[i])])
      result = dispf("<tr>$1</tr>$n", "$1\\\\$n\\hline$n", [result])
    else: 
      result = nil
  of rnTableDataCell: result = renderAux(d, n, disp("<td>$1</td>", "$1"))
  of rnTableHeaderCell: 
    result = renderAux(d, n, disp("<th>$1</th>", "\\textbf{$1}"))
  of rnLabel: 
    InternalError("renderRstToOut") # used for footnotes and other
  of rnFootnote: 
    InternalError("renderRstToOut") # a footnote
  of rnCitation: 
    InternalError("renderRstToOut") # similar to footnote
  of rnRef: 
    result = dispF("<a class=\"reference external\" href=\"#$2\">$1</a>", 
                   "$1\\ref{$2}", [renderAux(d, n), toRope(rstnodeToRefname(n))])
  of rnStandaloneHyperlink: 
    result = renderAux(d, n, disp(
      "<a class=\"reference external\" href=\"$1\">$1</a>", 
      "\\href{$1}{$1}"))
  of rnHyperlink: 
    result = dispF("<a class=\"reference external\" href=\"$2\">$1</a>", 
                   "\\href{$2}{$1}", 
                   [renderRstToOut(d, n.sons[0]), renderRstToOut(d, n.sons[1])])
  of rnDirArg, rnRaw: result = renderAux(d, n)
  of rnRawHtml: 
    if gCmd != cmdRst2Tex:
      result = toRope(addNodes(lastSon(n)))
  of rnRawLatex:
    if gCmd == cmdRst2Tex:
      result = toRope(addNodes(lastSon(n)))
      
  of rnImage, rnFigure: result = renderImage(d, n)
  of rnCodeBlock: result = renderCodeBlock(d, n)
  of rnContainer: result = renderContainer(d, n)
  of rnSubstitutionReferences, rnSubstitutionDef: 
    result = renderAux(d, n, disp("|$1|", "|$1|"))
  of rnDirective: 
    result = renderAux(d, n, "") # Inline markup:
  of rnGeneralRole: 
    result = dispF("<span class=\"$2\">$1</span>", "\\span$2{$1}", 
                   [renderRstToOut(d, n.sons[0]), renderRstToOut(d, n.sons[1])])
  of rnSub: result = renderAux(d, n, disp("<sub>$1</sub>", "\\rstsub{$1}"))
  of rnSup: result = renderAux(d, n, disp("<sup>$1</sup>", "\\rstsup{$1}"))
  of rnEmphasis: result = renderAux(d, n, disp("<em>$1</em>", "\\emph{$1}"))
  of rnStrongEmphasis:
    result = renderAux(d, n, disp("<strong>$1</strong>", "\\textbf{$1}"))
  of rnInterpretedText: 
    result = renderAux(d, n, disp("<cite>$1</cite>", "\\emph{$1}"))
  of rnIdx: 
    if d.theIndex == nil: 
      result = renderAux(d, n, disp("<span>$1</span>", "\\emph{$1}"))
    else: 
      result = renderIndexTerm(d, n)
  of rnInlineLiteral: 
    result = renderAux(d, n, disp(
      "<tt class=\"docutils literal\"><span class=\"pre\">$1</span></tt>", 
      "\\texttt{$1}"))
  of rnLeaf: result = toRope(esc(n.text))
  of rnContents: d.hasToc = true
  of rnTitle: d.meta[metaTitle] = renderRstToOut(d, n.sons[0])
  else: InternalError("renderRstToOut")
  
proc checkForFalse(n: PNode): bool = 
  result = n.kind == nkIdent and IdentEq(n.ident, "false")
  
proc getModuleFile(n: PNode): string = 
  case n.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit: result = n.strVal
  of nkIdent: result = n.ident.s
  of nkSym: result = n.sym.name.s
  else: 
    internalError(n.info, "getModuleFile()")
    result = ""
  
proc traceDeps(d: PDoc, n: PNode) = 
  const k = skModule
  if d.section[k] != nil: app(d.section[k], ", ")
  dispA(d.section[k], 
        "<a class=\"reference external\" href=\"$1.html\">$1</a>", 
        "$1", [toRope(getModuleFile(n))])

proc generateDoc(d: PDoc, n: PNode) = 
  case n.kind
  of nkCommentStmt: app(d.modDesc, genComment(d, n))
  of nkProcDef: genItem(d, n, n.sons[namePos], skProc)
  of nkMethodDef: genItem(d, n, n.sons[namePos], skMethod)
  of nkIteratorDef: genItem(d, n, n.sons[namePos], skIterator)
  of nkMacroDef: genItem(d, n, n.sons[namePos], skMacro)
  of nkTemplateDef: genItem(d, n, n.sons[namePos], skTemplate)
  of nkConverterDef: genItem(d, n, n.sons[namePos], skConverter)
  of nkVarSection: 
    for i in countup(0, sonsLen(n) - 1): 
      if n.sons[i].kind != nkCommentStmt: 
        genItem(d, n.sons[i], n.sons[i].sons[0], skVar)
  of nkConstSection: 
    for i in countup(0, sonsLen(n) - 1): 
      if n.sons[i].kind != nkCommentStmt: 
        genItem(d, n.sons[i], n.sons[i].sons[0], skConst)
  of nkTypeSection: 
    for i in countup(0, sonsLen(n) - 1): 
      if n.sons[i].kind != nkCommentStmt: 
        genItem(d, n.sons[i], n.sons[i].sons[0], skType)
  of nkStmtList: 
    for i in countup(0, sonsLen(n) - 1): generateDoc(d, n.sons[i])
  of nkWhenStmt: 
    # generate documentation for the first branch only:
    if not checkForFalse(n.sons[0].sons[0]):
      generateDoc(d, lastSon(n.sons[0]))
  of nkImportStmt:
    for i in 0 .. sonsLen(n)-1: traceDeps(d, n.sons[i]) 
  of nkFromStmt: traceDeps(d, n.sons[0])
  else: nil

proc genSection(d: PDoc, kind: TSymKind) = 
  const sectionNames: array[skModule..skTemplate, string] = [
    "Imports", "Types", "Consts", "Vars", "Procs", "Methods", 
    "Iterators", "Converters", "Macros", "Templates"
  ]
  if d.section[kind] == nil: return 
  var title = toRope(sectionNames[kind])
  d.section[kind] = ropeFormatNamedVars(getConfigVar("doc.section"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      toRope(ord(kind)), title, toRope(ord(kind) + 50), d.section[kind]])
  d.toc[kind] = ropeFormatNamedVars(getConfigVar("doc.section.toc"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      toRope(ord(kind)), title, toRope(ord(kind) + 50), d.toc[kind]])

proc genOutFile(d: PDoc): PRope = 
  var 
    code, toc, title, content: PRope
    bodyname: string
    j: int
  j = 0
  toc = renderTocEntries(d, j, 1)
  code = nil
  content = nil
  title = nil
  for i in countup(low(TSymKind), high(TSymKind)): 
    genSection(d, i)
    app(toc, d.toc[i])
  if toc != nil: 
    toc = ropeFormatNamedVars(getConfigVar("doc.toc"), ["content"], [toc])
  for i in countup(low(TSymKind), high(TSymKind)): app(code, d.section[i])
  if d.meta[metaTitle] != nil: title = d.meta[metaTitle]
  else: title = toRope("Module " &
      extractFilename(changeFileExt(d.filename, "")))
  if d.hasToc: bodyname = "doc.body_toc"
  else: bodyname = "doc.body_no_toc"
  content = ropeFormatNamedVars(getConfigVar(bodyname), ["title", 
      "tableofcontents", "moduledesc", "date", "time", "content"],
      [title, toc, d.modDesc, toRope(getDateStr()), 
      toRope(getClockStr()), code])
  if optCompileOnly notin gGlobalOptions: 
    code = ropeFormatNamedVars(getConfigVar("doc.file"), ["title", 
        "tableofcontents", "moduledesc", "date", "time", 
        "content", "author", "version"], 
        [title, toc, d.modDesc, toRope(getDateStr()), 
                     toRope(getClockStr()), content, d.meta[metaAuthor], 
                     d.meta[metaVersion]])
  else: 
    code = content
  result = code

proc generateIndex(d: PDoc) = 
  if d.theIndex != nil: 
    sortIndex(d.theIndex)
    writeRope(renderRstToRst(d, d.indexFile), gIndexFile)

proc writeOutput(d: PDoc, filename, outExt: string) = 
  var content = genOutFile(d)
  if optStdout in gGlobalOptions:
    writeRope(stdout, content)
  else:
    writeRope(content, getOutFile(filename, outExt))

proc CommandDoc(filename: string) = 
  var ast = parseFile(addFileExt(filename, nimExt))
  if ast == nil: return 
  var d = newDocumentor(filename)
  initIndexFile(d)
  d.hasToc = true
  generateDoc(d, ast)
  writeOutput(d, filename, HtmlExt)
  generateIndex(d)

proc CommandRstAux(filename, outExt: string) = 
  var filen = addFileExt(filename, "txt")
  var d = newDocumentor(filen)
  initIndexFile(d)
  var rst = rstParse(readFile(filen), false, filen, 0, 1, d.hasToc)
  d.modDesc = renderRstToOut(d, rst)
  writeOutput(d, filename, outExt)
  generateIndex(d)

proc CommandRst2Html(filename: string) = 
  CommandRstAux(filename, HtmlExt)

proc CommandRst2TeX(filename: string) = 
  splitter = "\\-"
  CommandRstAux(filename, TexExt)
