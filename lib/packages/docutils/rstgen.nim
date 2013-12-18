#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a generator of HTML/Latex from
## `reStructuredText`:idx: (see http://docutils.sourceforge.net/rst.html for
## information on this markup syntax). You can generate HTML output through the
## convenience proc ``rstToHtml``, which provided an input string with rst
## markup returns a string with the generated HTML. The final output is meant
## to be embedded inside a full document you provide yourself, so it won't
## contain the usual ``<header>`` or ``<body>`` parts.
##
## You can also create a ``TRstGenerator`` structure and populate it with the
## other lower level methods to finally build complete documents. This requires
## many options and tweaking, but you are not limited to snippets and can
## generate `LaTeX documents <https://en.wikipedia.org/wiki/LaTeX>`_ too.

import strutils, os, hashes, strtabs, rstast, rst, highlite

const
  HtmlExt = "html"
  IndexExt* = ".idx"

type
  TOutputTarget* = enum ## which document type to generate
    outHtml,            # output is HTML
    outLatex            # output is Latex
  
  TTocEntry{.final.} = object 
    n*: PRstNode
    refname*, header*: string

  TMetaEnum* = enum 
    metaNone, metaTitle, metaSubtitle, metaAuthor, metaVersion
    
  TRstGenerator* = object of TObject
    target*: TOutputTarget
    config*: PStringTable
    splitAfter*: int          # split too long entries in the TOC
    tocPart*: seq[TTocEntry]
    hasToc*: bool
    theIndex: string
    options*: TRstParseOptions
    findFile*: TFindFileHandler
    msgHandler*: TMsgHandler
    filename*: string
    meta*: array[TMetaEnum, string]
  
  PDoc = var TRstGenerator ## Alias to type less.

proc initRstGenerator*(g: var TRstGenerator, target: TOutputTarget,
                       config: PStringTable, filename: string,
                       options: TRstParseOptions,
                       findFile: TFindFileHandler,
                       msgHandler: TMsgHandler) =
  ## Initializes a ``TRstGenerator``.
  ##
  ## You need to call this before using a ``TRstGenerator`` with any other
  ## procs in this module. Pass a non ``nil`` ``PStringTable`` value as
  ## ``config`` with parameters used by the HTML output generator.  If you
  ## don't know what to use, pass the results of the ``defaultConfig()`` proc.
  ## The ``filename`` is symbolic and used only for error reporting, you can
  ## pass any non ``nil`` string here.
  ##
  ## The ``TRstParseOptions``, ``TFindFileHandler`` and ``TMsgHandler`` types
  ## are defined in the the `packages/docutils/rst module <rst.html>`_.
  ## ``options`` selects the behaviour of the rst parser.
  ##
  ## ``findFile`` is a proc used by the rst ``include`` directive among others.
  ## The purpose of this proc is to mangle or filter paths. It receives paths
  ## specified in the rst document and has to return a valid path to existing
  ## files or the empty string otherwise.  If you pass ``nil``, a default proc
  ## will be used which given a path returns the input path only if the file
  ## exists. One use for this proc is to transform relative paths found in the
  ## document to absolute path, useful if the rst file and the resources it
  ## references are not in the same directory as the current working directory.
  ##
  ## The ``msgHandler`` is a proc used for user error reporting. It will be
  ## called with the filename, line, col, and type of any error found during
  ## parsing. If you pass ``nil``, a default message handler will be used which
  ## writes the messages to the standard output.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##
  ##   import packages/docutils/rstgen
  ##
  ##   var gen: TRstGenerator
  ##
  ##   gen.initRstGenerator(outHtml, defaultConfig(),
  ##     "filename", {}, nil, nil)

  g.config = config
  g.target = target
  g.tocPart = @[]
  g.filename = filename
  g.splitAfter = 20
  g.theIndex = ""
  g.options = options
  g.findFile = findFile
  g.msgHandler = msgHandler
  
  let s = config["split.item.toc"]
  if s != "": g.splitAfter = parseInt(s)
  for i in low(g.meta)..high(g.meta): g.meta[i] = ""

proc writeIndexFile*(g: var TRstGenerator, outfile: string) =
  if g.theIndex.len > 0: writeFile(outfile, g.theIndex)
  
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

var splitter*: string = "<wbr />"

proc escChar*(target: TOutputTarget, dest: var string, c: Char) {.inline.} = 
  case target
  of outHtml:  addXmlChar(dest, c)
  of outLatex: addTexChar(dest, c)
  
proc nextSplitPoint*(s: string, start: int): int = 
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
  
proc esc*(target: TOutputTarget, s: string, splitAfter = -1): string = 
  result = ""
  if splitAfter >= 0: 
    var partLen = 0
    var j = 0
    while j < len(s): 
      var k = nextSplitPoint(s, j)
      if (splitter != " ") or (partLen + k - j + 1 > splitAfter): 
        partLen = 0
        add(result, splitter)
      for i in countup(j, k): escChar(target, result, s[i])
      inc(partLen, k - j + 1)
      j = k + 1
  else: 
    for i in countup(0, len(s) - 1): escChar(target, result, s[i])


proc disp(target: TOutputTarget, xml, tex: string): string =
  if target != outLatex: result = xml 
  else: result = tex
  
proc dispF(target: TOutputTarget, xml, tex: string, 
           args: varargs[string]): string = 
  if target != outLatex: result = xml % args 
  else: result = tex % args
  
proc dispA(target: TOutputTarget, dest: var string, 
           xml, tex: string, args: varargs[string]) =
  if target != outLatex: addf(dest, xml, args)
  else: addf(dest, tex, args)
  
proc renderRstToOut*(d: var TRstGenerator, n: PRstNode, result: var string)
  ## Writes into ``result`` the rst ast ``n`` using the ``d`` configuration.
  ##
  ## Before using this proc you need to initialise a ``TRstGenerator`` with
  ## ``initRstGenerator`` and parse a rst file with ``rstParse`` from the
  ## `packages/docutils/rst module <rst.html>`_. Example:
  ##
  ## .. code-block:: nimrod
  ##
  ##   # ...configure gen and rst vars...
  ##   var generatedHTML = ""
  ##   renderRstToOut(gen, rst, generatedHTML)
  ##   echo generatedHTML

proc renderAux(d: PDoc, n: PRstNode, result: var string) = 
  for i in countup(0, len(n)-1): renderRstToOut(d, n.sons[i], result)

proc renderAux(d: PDoc, n: PRstNode, frmtA, frmtB: string, result: var string) = 
  var tmp = ""
  for i in countup(0, len(n)-1): renderRstToOut(d, n.sons[i], tmp)
  if d.target != outLatex:
    result.addf(frmtA, [tmp])
  else:
    result.addf(frmtB, [tmp])

# ---------------- index handling --------------------------------------------

proc setIndexTerm*(d: var TRstGenerator, id, term: string) =
  d.theIndex.add(term)
  d.theIndex.add('\t')
  let htmlFile = changeFileExt(extractFilename(d.filename), HtmlExt)
  d.theIndex.add(htmlFile)
  d.theIndex.add('#')
  d.theIndex.add(id)
  d.theIndex.add("\n")

proc hash(n: PRstNode): int =
  if n.kind == rnLeaf:
    result = hash(n.text)
  elif n.len > 0:
    result = hash(n.sons[0])
    for i in 1 .. <len(n):
      result = result !& hash(n.sons[i])
    result = !$result

proc renderIndexTerm(d: PDoc, n: PRstNode, result: var string) =
  let id = rstnodeToRefname(n) & '_' & $abs(hash(n))
  var term = ""
  renderAux(d, n, term)
  setIndexTerm(d, id, term)
  dispA(d.target, result, "<span id=\"$1\">$2</span>", "$2\\label{$1}", 
        [id, term])

type
  TIndexEntry {.pure, final.} = object
    keyword: string
    link: string

proc cmp(a, b: TIndexEntry): int =
  result = cmpIgnoreStyle(a.keyword, b.keyword)

proc `<-`(a: var TIndexEntry, b: TIndexEntry) =
  shallowCopy a.keyword, b.keyword
  shallowCopy a.link, b.link

proc sortIndex(a: var openArray[TIndexEntry]) =
  # we use shellsort here; fast and simple
  let N = len(a)
  var h = 1
  while true:
    h = 3 * h + 1
    if h > N: break
  while true:
    h = h div 3
    for i in countup(h, N - 1):
      var v: TIndexEntry
      v <- a[i]
      var j = i
      while cmp(a[j-h], v) >= 0:
        a[j] <- a[j-h]
        j = j-h
        if j < h: break
      a[j] <- v
    if h == 1: break

proc mergeIndexes*(dir: string): string =
  ## merges all index files in `dir` and returns the generated index as HTML.
  ## The result is no full HTML for flexibility.
  var a: seq[TIndexEntry]
  newSeq(a, 15_000)
  setLen(a, 0)
  var L = 0
  for kind, path in walkDir(dir):
    if kind == pcFile and path.endsWith(IndexExt):
      for line in lines(path):
        let s = line.find('\t')
        if s < 0: continue
        setLen(a, L+1)
        a[L].keyword = line.substr(0, s-1)
        a[L].link = line.substr(s+1)
        inc L
  sortIndex(a)
  result = ""
  var i = 0
  while i < L:
    result.addf("<dt><span>$1</span></dt><ul class=\"simple\"><dd>\n", 
                [a[i].keyword])
    var j = i
    while j < L and a[i].keyword == a[j].keyword:
      result.addf(
        "<li><a class=\"reference external\" href=\"$1\">$1</a></li>\n", 
        [a[j].link])
      inc j
    result.add("</ul></dd>\n")
    i = j
  
# ----------------------------------------------------------------------------      
  
proc renderHeadline(d: PDoc, n: PRstNode, result: var string) = 
  var tmp = ""
  for i in countup(0, len(n) - 1): renderRstToOut(d, n.sons[i], tmp)
  var refname = rstnodeToRefname(n)
  if d.hasToc:
    var length = len(d.tocPart)
    setlen(d.tocPart, length + 1)
    d.tocPart[length].refname = refname
    d.tocPart[length].n = n
    d.tocPart[length].header = tmp
    
    dispA(d.target, result,
        "\n<h$1><a class=\"toc-backref\" id=\"$2\" href=\"#$2_toc\">$3</a></h$1>", 
        "\\rsth$4{$3}\\label{$2}\n", [$n.level, 
        d.tocPart[length].refname, tmp, 
        $chr(n.level - 1 + ord('A'))])
  else:
    dispA(d.target, result, "\n<h$1 id=\"$2\">$3</h$1>", 
                            "\\rsth$4{$3}\\label{$2}\n", [
        $n.level, refname, tmp, 
        $chr(n.level - 1 + ord('A'))])
  
proc renderOverline(d: PDoc, n: PRstNode, result: var string) = 
  if d.meta[metaTitle].len == 0:
    for i in countup(0, len(n)-1):
      renderRstToOut(d, n.sons[i], d.meta[metaTitle])
  elif d.meta[metaSubtitle].len == 0:
    for i in countup(0, len(n)-1):
      renderRstToOut(d, n.sons[i], d.meta[metaSubtitle])
  else:
    var tmp = ""
    for i in countup(0, len(n) - 1): renderRstToOut(d, n.sons[i], tmp)
    dispA(d.target, result, "<h$1 id=\"$2\"><center>$3</center></h$1>", 
                   "\\rstov$4{$3}\\label{$2}\n", [$n.level,
        rstnodeToRefname(n), tmp, $chr(n.level - 1 + ord('A'))])
  

proc renderTocEntry(d: PDoc, e: TTocEntry, result: var string) = 
  dispA(d.target, result,
    "<li><a class=\"reference\" id=\"$1_toc\" href=\"#$1\">$2</a></li>\n", 
    "\\item\\label{$1_toc} $2\\ref{$1}\n", [e.refname, e.header])

proc renderTocEntries*(d: var TRstGenerator, j: var int, lvl: int, result: var string) =
  var tmp = ""
  while j <= high(d.tocPart): 
    var a = abs(d.tocPart[j].n.level)
    if a == lvl:
      renderTocEntry(d, d.tocPart[j], tmp)
      inc(j)
    elif a > lvl:
      renderTocEntries(d, j, a, tmp)
    else:
      break
  if lvl > 1:
    dispA(d.target, result, "<ul class=\"simple\">$1</ul>", 
                            "\\begin{enumerate}$1\\end{enumerate}", [tmp])
  else:
    result.add(tmp)
  
proc renderImage(d: PDoc, n: PRstNode, result: var string) = 
  var options = ""
  var s = getFieldValue(n, "scale")
  if s != "": dispA(d.target, options, " scale=\"$1\"", " scale=$1", [strip(s)])
  
  s = getFieldValue(n, "height")
  if s != "": dispA(d.target, options, " height=\"$1\"", " height=$1", [strip(s)])
  
  s = getFieldValue(n, "width")
  if s != "": dispA(d.target, options, " width=\"$1\"", " width=$1", [strip(s)])
  
  s = getFieldValue(n, "alt")
  if s != "": dispA(d.target, options, " alt=\"$1\"", "", [strip(s)])
  
  s = getFieldValue(n, "align")
  if s != "": dispA(d.target, options, " align=\"$1\"", "", [strip(s)])
  
  if options.len > 0: options = dispF(d.target, "$1", "[$1]", [options])
  
  dispA(d.target, result, "<img src=\"$1\"$2 />", "\\includegraphics$2{$1}", 
                 [getArgument(n), options])
  if len(n) >= 3: renderRstToOut(d, n.sons[2], result)
  
proc renderSmiley(d: PDoc, n: PRstNode, result: var string) =
  dispA(d.target, result,
    """<img src="/images/smilies/$1.gif" width="15" 
        height="17" hspace="2" vspace="2" />""",
    "\\includegraphics{$1}", [n.text])
  
proc renderCodeBlock(d: PDoc, n: PRstNode, result: var string) =
  if n.sons[2] == nil: return
  var m = n.sons[2].sons[0]
  assert m.kind == rnLeaf
  var langstr = strip(getArgument(n))
  var lang: TSourceLanguage
  if langstr == "":
    lang = langNimrod         # default language
  else:
    lang = getSourceLanguage(langstr)
  
  dispA(d.target, result, "<pre>", "\\begin{rstpre}\n", [])
  if lang == langNone:
    d.msgHandler(d.filename, 1, 0, mwUnsupportedLanguage, langstr)
    result.add(m.text)
  else:
    var g: TGeneralTokenizer
    initGeneralTokenizer(g, m.text)
    while true: 
      getNextToken(g, lang)
      case g.kind
      of gtEof: break 
      of gtNone, gtWhitespace: 
        add(result, substr(m.text, g.start, g.length + g.start - 1))
      else:
        dispA(d.target, result, "<span class=\"$2\">$1</span>", "\\span$2{$1}", [
          esc(d.target, substr(m.text, g.start, g.length+g.start-1)),
          tokenClassToStr[g.kind]])
    deinitGeneralTokenizer(g)
  dispA(d.target, result, "</pre>", "\n\\end{rstpre}\n")
  
proc renderContainer(d: PDoc, n: PRstNode, result: var string) = 
  var tmp = ""
  renderRstToOut(d, n.sons[2], tmp)
  var arg = strip(getArgument(n))
  if arg == "": 
    dispA(d.target, result, "<div>$1</div>", "$1", [tmp])
  else:
    dispA(d.target, result, "<div class=\"$1\">$2</div>", "$2", [arg, tmp])
  
proc texColumns(n: PRstNode): string = 
  result = ""
  for i in countup(1, len(n)): add(result, "|X")
  
proc renderField(d: PDoc, n: PRstNode, result: var string) = 
  var b = false
  if d.target == outLatex: 
    var fieldname = addNodes(n.sons[0])
    var fieldval = esc(d.target, strip(addNodes(n.sons[1])))
    if cmpIgnoreStyle(fieldname, "author") == 0 or 
       cmpIgnoreStyle(fieldname, "authors") == 0:
      if d.meta[metaAuthor].len == 0:
        d.meta[metaAuthor] = fieldval
        b = true
    elif cmpIgnoreStyle(fieldName, "version") == 0: 
      if d.meta[metaVersion].len == 0:
        d.meta[metaVersion] = fieldval
        b = true
  if not b:
    renderAux(d, n, "<tr>$1</tr>\n", "$1", result)
  
proc renderRstToOut(d: PDoc, n: PRstNode, result: var string) =
  if n == nil: return
  case n.kind
  of rnInner: renderAux(d, n, result)
  of rnHeadline: renderHeadline(d, n, result)
  of rnOverline: renderOverline(d, n, result)
  of rnTransition: renderAux(d, n, "<hr />\n", "\\hrule\n", result)
  of rnParagraph: renderAux(d, n, "<p>$1</p>\n", "$1\n\n", result)
  of rnBulletList:
    renderAux(d, n, "<ul class=\"simple\">$1</ul>\n",
                    "\\begin{itemize}$1\\end{itemize}\n", result)
  of rnBulletItem, rnEnumItem:
    renderAux(d, n, "<li>$1</li>\n", "\\item $1\n", result)
  of rnEnumList:
    renderAux(d, n, "<ol class=\"simple\">$1</ol>\n",
                    "\\begin{enumerate}$1\\end{enumerate}\n", result)
  of rnDefList:
    renderAux(d, n, "<dl class=\"docutils\">$1</dl>\n",
                       "\\begin{description}$1\\end{description}\n", result)
  of rnDefItem: renderAux(d, n, result)
  of rnDefName: renderAux(d, n, "<dt>$1</dt>\n", "\\item[$1] ", result)
  of rnDefBody: renderAux(d, n, "<dd>$1</dd>\n", "$1\n", result)
  of rnFieldList:
    var tmp = ""
    for i in countup(0, len(n) - 1): 
      renderRstToOut(d, n.sons[i], tmp)
    if tmp.len != 0: 
      dispA(d.target, result,
          "<table class=\"docinfo\" frame=\"void\" rules=\"none\">" &
          "<col class=\"docinfo-name\" />" &
          "<col class=\"docinfo-content\" />" & 
          "<tbody valign=\"top\">$1" &
          "</tbody></table>", 
          "\\begin{description}$1\\end{description}\n", 
          [tmp])
  of rnField: renderField(d, n, result)
  of rnFieldName: 
    renderAux(d, n, "<th class=\"docinfo-name\">$1:</th>", "\\item[$1:]", result)
  of rnFieldBody: 
    renderAux(d, n, "<td>$1</td>", " $1\n", result)
  of rnIndex: 
    renderRstToOut(d, n.sons[2], result)
  of rnOptionList: 
    renderAux(d, n, "<table frame=\"void\">$1</table>", 
      "\\begin{description}\n$1\\end{description}\n", result)
  of rnOptionListItem: 
    renderAux(d, n, "<tr>$1</tr>\n", "$1", result)
  of rnOptionGroup: 
    renderAux(d, n, "<th align=\"left\">$1</th>", "\\item[$1]", result)
  of rnDescription: 
    renderAux(d, n, "<td align=\"left\">$1</td>\n", " $1\n", result)
  of rnOption, rnOptionString, rnOptionArgument: 
    doAssert false, "renderRstToOut"
  of rnLiteralBlock:
    renderAux(d, n, "<pre>$1</pre>\n", 
                    "\\begin{rstpre}\n$1\n\\end{rstpre}\n", result)
  of rnQuotedLiteralBlock: 
    doAssert false, "renderRstToOut"
  of rnLineBlock: 
    renderAux(d, n, "<p>$1</p>", "$1\n\n", result)
  of rnLineBlockItem: 
    renderAux(d, n, "$1<br />", "$1\\\\\n", result)
  of rnBlockQuote: 
    renderAux(d, n, "<blockquote><p>$1</p></blockquote>\n", 
                    "\\begin{quote}$1\\end{quote}\n", result)
  of rnTable, rnGridTable: 
    renderAux(d, n, 
      "<table border=\"1\" class=\"docutils\">$1</table>", 
      "\\begin{table}\\begin{rsttab}{" &
        texColumns(n) & "|}\n\\hline\n$1\\end{rsttab}\\end{table}", result)
  of rnTableRow: 
    if len(n) >= 1:
      if d.target == outLatex:
        #var tmp = ""
        renderRstToOut(d, n.sons[0], result)
        for i in countup(1, len(n) - 1):
          result.add(" & ")
          renderRstToOut(d, n.sons[i], result)
        result.add("\\\\\n\\hline\n")
      else:
        result.add("<tr>")
        renderAux(d, n, result)
        result.add("</tr>\n")
  of rnTableDataCell: 
    renderAux(d, n, "<td>$1</td>", "$1", result)
  of rnTableHeaderCell: 
    renderAux(d, n, "<th>$1</th>", "\\textbf{$1}", result)
  of rnLabel: 
    doAssert false, "renderRstToOut" # used for footnotes and other
  of rnFootnote: 
    doAssert false, "renderRstToOut" # a footnote
  of rnCitation: 
    doAssert false, "renderRstToOut" # similar to footnote
  of rnRef: 
    var tmp = ""
    renderAux(d, n, tmp)
    dispA(d.target, result, "<a class=\"reference external\" href=\"#$2\">$1</a>", 
                            "$1\\ref{$2}", [tmp, rstnodeToRefname(n)])
  of rnStandaloneHyperlink: 
    renderAux(d, n, 
      "<a class=\"reference external\" href=\"$1\">$1</a>", 
      "\\href{$1}{$1}", result)
  of rnHyperlink:
    var tmp0 = ""
    var tmp1 = ""
    renderRstToOut(d, n.sons[0], tmp0)
    renderRstToOut(d, n.sons[1], tmp1)
    dispA(d.target, result, "<a class=\"reference external\" href=\"$2\">$1</a>", 
                   "\\href{$2}{$1}", 
                   [tmp0, tmp1])
  of rnDirArg, rnRaw: renderAux(d, n, result)
  of rnRawHtml:
    if d.target != outLatex:
      result.add addNodes(lastSon(n))
  of rnRawLatex:
    if d.target == outLatex:
      result.add addNodes(lastSon(n))
      
  of rnImage, rnFigure: renderImage(d, n, result)
  of rnCodeBlock: renderCodeBlock(d, n, result)
  of rnContainer: renderContainer(d, n, result)
  of rnSubstitutionReferences, rnSubstitutionDef: 
    renderAux(d, n, "|$1|", "|$1|", result)
  of rnDirective:
    renderAux(d, n, "", "", result)
  of rnGeneralRole:
    var tmp0 = ""
    var tmp1 = ""
    renderRstToOut(d, n.sons[0], tmp0)
    renderRstToOut(d, n.sons[1], tmp1)
    dispA(d.target, result, "<span class=\"$2\">$1</span>", "\\span$2{$1}",
          [tmp0, tmp1])
  of rnSub: renderAux(d, n, "<sub>$1</sub>", "\\rstsub{$1}", result)
  of rnSup: renderAux(d, n, "<sup>$1</sup>", "\\rstsup{$1}", result)
  of rnEmphasis: renderAux(d, n, "<em>$1</em>", "\\emph{$1}", result)
  of rnStrongEmphasis:
    renderAux(d, n, "<strong>$1</strong>", "\\textbf{$1}", result)
  of rnTripleEmphasis:
    renderAux(d, n, "<strong><em>$1</em></strong>", 
                    "\\textbf{emph{$1}}", result)
  of rnInterpretedText:
    renderAux(d, n, "<cite>$1</cite>", "\\emph{$1}", result)
  of rnIdx:
    renderIndexTerm(d, n, result)
  of rnInlineLiteral: 
    renderAux(d, n, 
      "<tt class=\"docutils literal\"><span class=\"pre\">$1</span></tt>", 
      "\\texttt{$1}", result)
  of rnSmiley: renderSmiley(d, n, result)
  of rnLeaf: result.add(esc(d.target, n.text))
  of rnContents: d.hasToc = true
  of rnTitle:
    d.meta[metaTitle] = ""
    renderRstToOut(d, n.sons[0], d.meta[metaTitle])

# -----------------------------------------------------------------------------

proc getVarIdx(varnames: openarray[string], id: string): int = 
  for i in countup(0, high(varnames)): 
    if cmpIgnoreStyle(varnames[i], id) == 0: 
      return i
  result = -1

proc formatNamedVars*(frmt: string, varnames: openarray[string], 
                      varvalues: openarray[string]): string = 
  var i = 0
  var L = len(frmt)
  result = ""
  var num = 0
  while i < L: 
    if frmt[i] == '$': 
      inc(i)                  # skip '$'
      case frmt[i]
      of '#': 
        add(result, varvalues[num])
        inc(num)
        inc(i)
      of '$': 
        add(result, "$")
        inc(i)
      of '0'..'9': 
        var j = 0
        while true: 
          j = (j * 10) + Ord(frmt[i]) - ord('0')
          inc(i)
          if i > L-1 or frmt[i] notin {'0'..'9'}: break 
        if j > high(varvalues) + 1:
          raise newException(EInvalidValue, "invalid index: " & $j)
        num = j
        add(result, varvalues[j - 1])
      of 'A'..'Z', 'a'..'z', '\x80'..'\xFF': 
        var id = ""
        while true: 
          add(id, frmt[i])
          inc(i)
          if frmt[i] notin {'A'..'Z', '_', 'a'..'z', '\x80'..'\xFF'}: break 
        var idx = getVarIdx(varnames, id)
        if idx >= 0: 
          add(result, varvalues[idx])
        else:
          raise newException(EInvalidValue, "unknown substitution var: " & id)
      of '{': 
        var id = ""
        inc(i)
        while frmt[i] != '}': 
          if frmt[i] == '\0': 
            raise newException(EInvalidValue, "'}' expected")
          add(id, frmt[i])
          inc(i)
        inc(i)                # skip }
                              # search for the variable:
        var idx = getVarIdx(varnames, id)
        if idx >= 0: add(result, varvalues[idx])
        else: 
          raise newException(EInvalidValue, "unknown substitution var: " & id)
      else:
        raise newException(EInvalidValue, "unknown substitution: $" & $frmt[i])
    var start = i
    while i < L: 
      if frmt[i] != '$': inc(i)
      else: break
    if i-1 >= start: add(result, substr(frmt, start, i - 1))


proc defaultConfig*(): PStringTable =
  ## creates a default configuration for HTML generation.
  result = newStringTable(modeStyleInsensitive)
  
  template setConfigVar(key, val: expr) =
    result[key] = val
  
  setConfigVar("split.item.toc", "20")
  setConfigVar("doc.section", """
<div class="section" id="$sectionID">
<h1><a class="toc-backref" href="#$sectionTitleID">$sectionTitle</a></h1>
<dl class="item">
$content
</dl></div>
""")
  setConfigVar("doc.section.toc", """
<li>
  <a class="reference" href="#$sectionID" id="$sectionTitleID">$sectionTitle</a>
  <ul class="simple">
    $content
  </ul>
</li>
""")
  setConfigVar("doc.item", """
<dt id="$itemID"><pre>$header</pre></dt>
<dd>
$desc
</dd>
""")
  setConfigVar("doc.item.toc", """
  <li><a class="reference" href="#$itemID">$name</a></li>
""")
  setConfigVar("doc.toc", """
<div class="navigation" id="navigation">
<ul class="simple">
$content
</ul>
</div>""")
  setConfigVar("doc.body_toc", """
$tableofcontents
<div class="content" id="content">
$moduledesc
$content
</div>
""")
  setConfigVar("doc.body_no_toc", "$moduledesc $content")
  setConfigVar("doc.file", "$content")

# ---------- forum ---------------------------------------------------------

proc rstToHtml*(s: string, options: TRstParseOptions, 
                config: PStringTable): string =
  ## Converts an input rst string into embeddable HTML.
  ##
  ## This convenience proc parses any input string using rst markup (it doesn't
  ## have to be a full document!) and returns an embeddable piece of HTML. The
  ## proc is meant to be used in *online* environments without access to a
  ## meaningful filesystem, and therefore rst ``include`` like directives won't
  ## work. For an explanation of the ``config`` parameter see the
  ## ``initRstGenerator`` proc. Example:
  ##
  ## .. code-block:: nimrod
  ##   import packages/docutils/rstgen, strtabs
  ##
  ##   echo rstToHtml("*Hello* **world**!", {},
  ##     newStringTable(modeStyleInsensitive))
  ##   # --> <em>Hello</em> <strong>world</strong>!
  ##
  ## If you need to allow the rst ``include`` directive or tweak the generated
  ## output you have to create your own ``TRstGenerator`` with
  ## ``initRstGenerator`` and related procs.

  proc myFindFile(filename: string): string = 
    # we don't find any files in online mode:
    result = ""

  const filen = "input"
  var d: TRstGenerator
  initRstGenerator(d, outHtml, config, filen, options, myFindFile, 
                   rst.defaultMsgHandler)
  var dummyHasToc = false
  var rst = rstParse(s, filen, 0, 1, dummyHasToc, options)
  result = ""
  renderRstToOut(d, rst, result)


when isMainModule:
  echo rstToHtml("*Hello* **world**!", {},
    newStringTable(modeStyleInsensitive))
