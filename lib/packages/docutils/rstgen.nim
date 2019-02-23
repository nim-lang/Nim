#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a generator of HTML/Latex from
## `reStructuredText`:idx: (see http://docutils.sourceforge.net/rst.html for
## information on this markup syntax) and is used by the compiler's `docgen
## tools <docgen.html>`_.
##
## You can generate HTML output through the convenience proc ``rstToHtml``,
## which provided an input string with rst markup returns a string with the
## generated HTML. The final output is meant to be embedded inside a full
## document you provide yourself, so it won't contain the usual ``<header>`` or
## ``<body>`` parts.
##
## You can also create a ``RstGenerator`` structure and populate it with the
## other lower level methods to finally build complete documents. This requires
## many options and tweaking, but you are not limited to snippets and can
## generate `LaTeX documents <https://en.wikipedia.org/wiki/LaTeX>`_ too.
##
## **Note:** Import ``packages/docutils/rstgen`` to use this module

import strutils, os, hashes, strtabs, rstast, rst, highlite, tables, sequtils,
  algorithm, parseutils

const
  HtmlExt = "html"
  IndexExt* = ".idx"

type
  OutputTarget* = enum ## which document type to generate
    outHtml,            # output is HTML
    outLatex            # output is Latex

  TocEntry = object
    n*: PRstNode
    refname*, header*: string

  MetaEnum* = enum
    metaNone, metaTitle, metaSubtitle, metaAuthor, metaVersion

  RstGenerator* = object of RootObj
    target*: OutputTarget
    config*: StringTableRef
    splitAfter*: int          # split too long entries in the TOC
    listingCounter*: int
    tocPart*: seq[TocEntry]
    hasToc*: bool
    theIndex: string # Contents of the index file to be dumped at the end.
    options*: RstParseOptions
    findFile*: FindFileHandler
    msgHandler*: MsgHandler
    filename*: string
    meta*: array[MetaEnum, string]
    currentSection: string ## \
    ## Stores the empty string or the last headline/overline found in the rst
    ## document, so it can be used as a prettier name for term index generation.
    seenIndexTerms: Table[string, int] ## \
    ## Keeps count of same text index terms to generate different identifiers
    ## for hyperlinks. See renderIndexTerm proc for details.
    id*: int               ## A counter useful for generating IDs.
    onTestSnippet*: proc (d: var RstGenerator; filename, cmd: string; status: int;
                          content: string)

  PDoc = var RstGenerator ## Alias to type less.

  CodeBlockParams = object ## Stores code block params.
    numberLines: bool ## True if the renderer has to show line numbers.
    startLine: int ## The starting line of the code block, by default 1.
    langStr: string ## Input string used to specify the language.
    lang: SourceLanguage ## Type of highlighting, by default none.
    filename: string
    testCmd: string
    status: int

proc init(p: var CodeBlockParams) =
  ## Default initialisation of CodeBlockParams to sane values.
  p.startLine = 1
  p.lang = langNone
  p.langStr = ""

proc initRstGenerator*(g: var RstGenerator, target: OutputTarget,
                       config: StringTableRef, filename: string,
                       options: RstParseOptions,
                       findFile: FindFileHandler = nil,
                       msgHandler: MsgHandler = nil) =
  ## Initializes a ``RstGenerator``.
  ##
  ## You need to call this before using a ``RstGenerator`` with any other
  ## procs in this module. Pass a non ``nil`` ``StringTableRef`` value as
  ## `config` with parameters used by the HTML output generator.  If you don't
  ## know what to use, pass the results of the `defaultConfig()
  ## <#defaultConfig>_` proc.
  ##
  ## The `filename` parameter will be used for error reporting and creating
  ## index hyperlinks to the file, but you can pass an empty string here if you
  ## are parsing a stream in memory. If `filename` ends with the ``.nim``
  ## extension, the title for the document will be set by default to ``Module
  ## filename``.  This default title can be overriden by the embedded rst, but
  ## it helps to prettify the generated index if no title is found.
  ##
  ## The ``RstParseOptions``, ``FindFileHandler`` and ``MsgHandler`` types
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
  ## .. code-block:: nim
  ##
  ##   import packages/docutils/rstgen
  ##
  ##   var gen: RstGenerator
  ##   gen.initRstGenerator(outHtml, defaultConfig(), "filename", {})
  g.config = config
  g.target = target
  g.tocPart = @[]
  g.filename = filename
  g.splitAfter = 20
  g.theIndex = ""
  g.options = options
  g.findFile = findFile
  g.currentSection = ""
  g.id = 0
  let fileParts = filename.splitFile
  if fileParts.ext == ".nim":
    g.currentSection = "Module " & fileParts.name
  g.seenIndexTerms = initTable[string, int]()
  g.msgHandler = msgHandler

  let s = config.getOrDefault"split.item.toc"
  if s != "": g.splitAfter = parseInt(s)
  for i in low(g.meta)..high(g.meta): g.meta[i] = ""

proc writeIndexFile*(g: var RstGenerator, outfile: string) =
  ## Writes the current index buffer to the specified output file.
  ##
  ## You previously need to add entries to the index with the `setIndexTerm()
  ## <#setIndexTerm>`_ proc. If the index is empty the file won't be created.
  if g.theIndex.len > 0: writeFile(outfile, g.theIndex)

proc addXmlChar(dest: var string, c: char) =
  case c
  of '&': add(dest, "&amp;")
  of '<': add(dest, "&lt;")
  of '>': add(dest, "&gt;")
  of '\"': add(dest, "&quot;")
  else: add(dest, c)

proc addRtfChar(dest: var string, c: char) =
  case c
  of '{': add(dest, "\\{")
  of '}': add(dest, "\\}")
  of '\\': add(dest, "\\\\")
  else: add(dest, c)

proc addTexChar(dest: var string, c: char) =
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

proc escChar*(target: OutputTarget, dest: var string, c: char) {.inline.} =
  case target
  of outHtml:  addXmlChar(dest, c)
  of outLatex: addTexChar(dest, c)

proc addSplitter(target: OutputTarget; dest: var string) {.inline.} =
  case target
  of outHtml: add(dest, "<wbr />")
  of outLatex: add(dest, "\\-")

proc nextSplitPoint*(s: string, start: int): int =
  result = start
  while result < len(s) + 0:
    case s[result]
    of '_': return
    of 'a'..'z':
      if result + 1 < len(s) + 0:
        if s[result + 1] in {'A'..'Z'}: return
    else: discard
    inc(result)
  dec(result)                 # last valid index

proc esc*(target: OutputTarget, s: string, splitAfter = -1): string =
  ## Escapes the HTML.
  result = ""
  if splitAfter >= 0:
    var partLen = 0
    var j = 0
    while j < len(s):
      var k = nextSplitPoint(s, j)
      #if (splitter != " ") or (partLen + k - j + 1 > splitAfter):
      partLen = 0
      addSplitter(target, result)
      for i in countup(j, k): escChar(target, result, s[i])
      inc(partLen, k - j + 1)
      j = k + 1
  else:
    for i in countup(0, len(s) - 1): escChar(target, result, s[i])


proc disp(target: OutputTarget, xml, tex: string): string =
  if target != outLatex: result = xml
  else: result = tex

proc dispF(target: OutputTarget, xml, tex: string,
           args: varargs[string]): string =
  if target != outLatex: result = xml % args
  else: result = tex % args

proc dispA(target: OutputTarget, dest: var string,
           xml, tex: string, args: varargs[string]) =
  if target != outLatex: addf(dest, xml, args)
  else: addf(dest, tex, args)

proc `or`(x, y: string): string {.inline.} =
  result = if x.len == 0: y else: x

proc renderRstToOut*(d: var RstGenerator, n: PRstNode, result: var string)
  ## Writes into ``result`` the rst ast ``n`` using the ``d`` configuration.
  ##
  ## Before using this proc you need to initialise a ``RstGenerator`` with
  ## ``initRstGenerator`` and parse a rst file with ``rstParse`` from the
  ## `packages/docutils/rst module <rst.html>`_. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   # ...configure gen and rst vars...
  ##   var generatedHtml = ""
  ##   renderRstToOut(gen, rst, generatedHtml)
  ##   echo generatedHtml

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

proc quoteIndexColumn(text: string): string =
  ## Returns a safe version of `text` for serialization to the ``.idx`` file.
  ##
  ## The returned version can be put without worries in a line based tab
  ## separated column text file. The following character sequence replacements
  ## will be performed for that goal:
  ##
  ## * ``"\\"`` => ``"\\\\"``
  ## * ``"\n"`` => ``"\\n"``
  ## * ``"\t"`` => ``"\\t"``
  result = newStringOfCap(text.len + 3)
  for c in text:
    case c
    of '\\': result.add "\\"
    of '\L': result.add "\\n"
    of '\C': discard
    of '\t': result.add "\\t"
    else: result.add c

proc unquoteIndexColumn(text: string): string =
  ## Returns the unquoted version generated by ``quoteIndexColumn``.
  result = text.multiReplace(("\\t", "\t"), ("\\n", "\n"), ("\\\\", "\\"))

proc setIndexTerm*(d: var RstGenerator, htmlFile, id, term: string,
                   linkTitle, linkDesc = "") =
  ## Adds a `term` to the index using the specified hyperlink identifier.
  ##
  ## A new entry will be added to the index using the format
  ## ``term<tab>file#id``. The file part will come from the `htmlFile`
  ## parameter.
  ##
  ## The `id` will be appended with a hash character only if its length is not
  ## zero, otherwise no specific anchor will be generated. In general you
  ## should only pass an empty `id` value for the title of standalone rst
  ## documents (they are special for the `mergeIndexes() <#mergeIndexes>`_
  ## proc, see `Index (idx) file format <docgen.html#index-idx-file-format>`_
  ## for more information). Unlike other index terms, title entries are
  ## inserted at the beginning of the accumulated buffer to maintain a logical
  ## order of entries.
  ##
  ## If `linkTitle` or `linkDesc` are not the empty string, two additional
  ## columns with their contents will be added.
  ##
  ## The index won't be written to disk unless you call `writeIndexFile()
  ## <#writeIndexFile>`_. The purpose of the index is documented in the `docgen
  ## tools guide <docgen.html#index-switch>`_.
  var
    entry = term
    isTitle = false
  entry.add('\t')
  entry.add(htmlFile)
  if id.len > 0:
    entry.add('#')
    entry.add(id)
  else:
    isTitle = true
  if linkTitle.len > 0 or linkDesc.len > 0:
    entry.add('\t' & linkTitle.quoteIndexColumn)
    entry.add('\t' & linkDesc.quoteIndexColumn)
  entry.add("\n")

  if isTitle: d.theIndex.insert(entry)
  else: d.theIndex.add(entry)

proc hash(n: PRstNode): int =
  if n.kind == rnLeaf:
    result = hash(n.text)
  elif n.len > 0:
    result = hash(n.sons[0])
    for i in 1 ..< len(n):
      result = result !& hash(n.sons[i])
    result = !$result

proc renderIndexTerm*(d: PDoc, n: PRstNode, result: var string) =
  ## Renders the string decorated within \`foobar\`\:idx\: markers.
  ##
  ## Additionally adds the encosed text to the index as a term. Since we are
  ## interested in different instances of the same term to have different
  ## entries, a table is used to keep track of the amount of times a term has
  ## previously appeared to give a different identifier value for each.
  let refname = n.rstnodeToRefname
  if d.seenIndexTerms.hasKey(refname):
    d.seenIndexTerms[refname] = d.seenIndexTerms.getOrDefault(refname) + 1
  else:
    d.seenIndexTerms[refname] = 1
  let id = refname & '_' & $d.seenIndexTerms.getOrDefault(refname)

  var term = ""
  renderAux(d, n, term)
  setIndexTerm(d, changeFileExt(extractFilename(d.filename), HtmlExt), id, term, d.currentSection)
  dispA(d.target, result, "<span id=\"$1\">$2</span>", "$2\\label{$1}",
        [id, term])

type
  IndexEntry = object
    keyword: string
    link: string
    linkTitle: string ## contains a prettier text for the href
    linkDesc: string ## the title attribute of the final href

  IndexedDocs = Table[IndexEntry, seq[IndexEntry]] ## \
    ## Contains the index sequences for doc types.
    ##
    ## The key is a *fake* IndexEntry which will contain the title of the
    ## document in the `keyword` field and `link` will contain the html
    ## filename for the document. `linkTitle` and `linkDesc` will be empty.
    ##
    ## The value indexed by this IndexEntry is a sequence with the real index
    ## entries found in the ``.idx`` file.

proc cmp(a, b: IndexEntry): int =
  ## Sorts two ``IndexEntry`` first by `keyword` field, then by `link`.
  result = cmpIgnoreStyle(a.keyword, b.keyword)
  if result == 0:
    result = cmpIgnoreStyle(a.link, b.link)

proc hash(x: IndexEntry): Hash =
  ## Returns the hash for the combined fields of the type.
  ##
  ## The hash is computed as the chained hash of the individual string hashes.
  result = x.keyword.hash !& x.link.hash
  result = result !& x.linkTitle.hash
  result = result !& x.linkDesc.hash
  result = !$result

proc `<-`(a: var IndexEntry, b: IndexEntry) =
  shallowCopy a.keyword, b.keyword
  shallowCopy a.link, b.link
  shallowCopy a.linkTitle, b.linkTitle
  shallowCopy a.linkDesc, b.linkDesc

proc sortIndex(a: var openArray[IndexEntry]) =
  # we use shellsort here; fast and simple
  let n = len(a)
  var h = 1
  while true:
    h = 3 * h + 1
    if h > n: break
  while true:
    h = h div 3
    for i in countup(h, n - 1):
      var v: IndexEntry
      v <- a[i]
      var j = i
      while cmp(a[j-h], v) >= 0:
        a[j] <- a[j-h]
        j = j-h
        if j < h: break
      a[j] <- v
    if h == 1: break

proc escapeLink(s: string): string =
  ## This proc is mostly copied from uri/encodeUrl except that
  ## these chars are also left unencoded: '#', '/'.
  result = newStringOfCap(s.len + s.len shr 2)
  for c in items(s):
    case c
    of 'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~': # same as that in uri/encodeUrl
      add(result, c)
    of '#', '/': # example.com/foo/#bar (don't escape the '/' and '#' in such links)
      add(result, c)
    else:
      add(result, "%")
      add(result, toHex(ord(c), 2))

proc generateSymbolIndex(symbols: seq[IndexEntry]): string =
  result = "<dl>"
  var i = 0
  while i < symbols.len:
    let keyword = symbols[i].keyword
    let cleanedKeyword = keyword.escapeLink
    result.addf("<dt><a name=\"$2\" href=\"#$2\"><span>$1:</span></a></dt><dd><ul class=\"simple\">\n",
                [keyword, cleanedKeyword])
    var j = i
    while j < symbols.len and keyword == symbols[j].keyword:
      let
        url = symbols[j].link.escapeLink
        text = if symbols[j].linkTitle.len > 0: symbols[j].linkTitle else: url
        desc = if symbols[j].linkDesc.len > 0: symbols[j].linkDesc else: ""
      if desc.len > 0:
        result.addf("""<li><a class="reference external"
          title="$3" data-doc-search-tag="$2" href="$1">$2</a></li>
          """, [url, text, desc])
      else:
        result.addf("""<li><a class="reference external"
          data-doc-search-tag="$2" href="$1">$2</a></li>
          """, [url, text])
      inc j
    result.add("</ul></dd>\n")
    i = j
  result.add("</dl>")

proc isDocumentationTitle(hyperlink: string): bool =
  ## Returns true if the hyperlink is actually a documentation title.
  ##
  ## Documentation titles lack the hash. See `mergeIndexes() <#mergeIndexes>`_
  ## for a more detailed explanation.
  result = hyperlink.find('#') < 0

proc stripTocLevel(s: string): tuple[level: int, text: string] =
  ## Returns the *level* of the toc along with the text without it.
  for c in 0 ..< s.len:
    result.level = c
    if s[c] != ' ': break
  result.text = s[result.level ..< s.len]

proc indentToLevel(level: var int, newLevel: int): string =
  ## Returns the sequence of <ul>|</ul> characters to switch to `newLevel`.
  ##
  ## The amount of lists added/removed will be based on the `level` variable,
  ## which will be reset to `newLevel` at the end of the proc.
  result = ""
  if level == newLevel:
    return
  if newLevel > level:
    result = repeat("<li><ul>", newLevel - level)
  else:
    result = repeat("</ul></li>", level - newLevel)
  level = newLevel

proc generateDocumentationToc(entries: seq[IndexEntry]): string =
  ## Returns the sequence of index entries in an HTML hierarchical list.
  result = ""
  # Build a list of levels and extracted titles to make processing easier.
  var
    titleRef: string
    titleTag: string
    levels: seq[tuple[level: int, text: string]]
    L = 0
    level = 1
  levels.newSeq(entries.len)
  for entry in entries:
    let (rawLevel, rawText) = stripTocLevel(entry.linkTitle or entry.keyword)
    if rawLevel < 1:
      # This is a normal symbol, push it *inside* one level from the last one.
      levels[L].level = level + 1
      # Also, ignore the linkTitle and use directly the keyword.
      levels[L].text = entry.keyword
    else:
      # The level did change, update the level indicator.
      level = rawLevel
      levels[L].level = rawLevel
      levels[L].text = rawText
    inc L

  # Now generate hierarchical lists based on the precalculated levels.
  result = "<ul>\n"
  level = 1
  L = 0
  while L < entries.len:
    let link = entries[L].link
    if link.isDocumentationTitle:
      titleRef = link
      titleTag = levels[L].text
    else:
      result.add(level.indentToLevel(levels[L].level))
      result.addf("""<li><a class="reference" data-doc-search-tag="$1: $2" href="$3">
        $3</a></li>
        """, [titleTag, levels[L].text, link, levels[L].text])
    inc L
  result.add(level.indentToLevel(1) & "</ul>\n")

proc generateDocumentationIndex(docs: IndexedDocs): string =
  ## Returns all the documentation TOCs in an HTML hierarchical list.
  result = ""

  # Sort the titles to generate their toc in alphabetical order.
  var titles = toSeq(keys[IndexEntry, seq[IndexEntry]](docs))
  sort(titles, cmp)

  for title in titles:
    let tocList = generateDocumentationToc(docs.getOrDefault(title))
    result.add("<ul><li><a href=\"" &
      title.link & "\">" & title.keyword & "</a>\n" & tocList & "</li></ul>\n")

proc generateDocumentationJumps(docs: IndexedDocs): string =
  ## Returns a plain list of hyperlinks to documentation TOCs in HTML.
  result = "Documents: "

  # Sort the titles to generate their toc in alphabetical order.
  var titles = toSeq(keys[IndexEntry, seq[IndexEntry]](docs))
  sort(titles, cmp)

  var chunks: seq[string] = @[]
  for title in titles:
    chunks.add("<a href=\"" & title.link & "\">" & title.keyword & "</a>")

  result.add(chunks.join(", ") & ".<br/>")

proc generateModuleJumps(modules: seq[string]): string =
  ## Returns a plain list of hyperlinks to the list of modules.
  result = "Modules: "

  var chunks: seq[string] = @[]
  for name in modules:
    chunks.add("<a href=\"" & name & ".html\">" & name & "</a>")

  result.add(chunks.join(", ") & ".<br/>")

proc readIndexDir(dir: string):
    tuple[modules: seq[string], symbols: seq[IndexEntry], docs: IndexedDocs] =
  ## Walks `dir` reading ``.idx`` files converting them in IndexEntry items.
  ##
  ## Returns the list of found module names, the list of free symbol entries
  ## and the different documentation indexes. The list of modules is sorted.
  ## See the documentation of ``mergeIndexes`` for details.
  result.modules = @[]
  result.docs = initTable[IndexEntry, seq[IndexEntry]](32)
  newSeq(result.symbols, 15_000)
  setLen(result.symbols, 0)
  var L = 0
  # Scan index files and build the list of symbols.
  for path in walkDirRec(dir):
    if path.endsWith(IndexExt):
      var
        fileEntries: seq[IndexEntry]
        title: IndexEntry
        F = 0
      newSeq(fileEntries, 500)
      setLen(fileEntries, 0)
      for line in lines(path):
        let s = line.find('\t')
        if s < 0: continue
        setLen(fileEntries, F+1)
        fileEntries[F].keyword = line.substr(0, s-1)
        fileEntries[F].link = line.substr(s+1)
        # See if we detect a title, a link without a `#foobar` trailing part.
        if title.keyword.len == 0 and fileEntries[F].link.isDocumentationTitle:
          title.keyword = fileEntries[F].keyword
          title.link = fileEntries[F].link

        if fileEntries[F].link.find('\t') > 0:
          let extraCols = fileEntries[F].link.split('\t')
          fileEntries[F].link = extraCols[0]
          assert extraCols.len == 3
          fileEntries[F].linkTitle = extraCols[1].unquoteIndexColumn
          fileEntries[F].linkDesc = extraCols[2].unquoteIndexColumn
        else:
          fileEntries[F].linkTitle = ""
          fileEntries[F].linkDesc = ""
        inc F
      # Depending on type add this to the list of symbols or table of APIs.
      if title.keyword.len == 0:
        for i in 0 ..< F:
          # Don't add to symbols TOC entries (they start with a whitespace).
          let toc = fileEntries[i].linkTitle
          if toc.len > 0 and toc[0] == ' ':
            continue
          # Ok, non TOC entry, add it.
          setLen(result.symbols, L + 1)
          result.symbols[L] = fileEntries[i]
          inc L
        if fileEntries.len > 0:
          var x = fileEntries[0].link
          let i = find(x, '#')
          if i > 0:
            x = x.substr(0, i-1)
          if i != 0:
            # don't add entries starting with '#'
            result.modules.add(x.changeFileExt(""))
      else:
        # Generate the symbolic anchor for index quickjumps.
        title.linkTitle = "doc_toc_" & $result.docs.len
        result.docs[title] = fileEntries

  sort(result.modules, system.cmp)

proc mergeIndexes*(dir: string): string =
  ## Merges all index files in `dir` and returns the generated index as HTML.
  ##
  ## This proc will first scan `dir` for index files with the ``.idx``
  ## extension previously created by commands like ``nim doc|rst2html``
  ## which use the ``--index:on`` switch. These index files are the result of
  ## calls to `setIndexTerm() <#setIndexTerm>`_ and `writeIndexFile()
  ## <#writeIndexFile>`_, so they are simple tab separated files.
  ##
  ## As convention this proc will split index files into two categories:
  ## documentation and API. API indices will be all joined together into a
  ## single big sorted index, making the bulk of the final index. This is good
  ## for API documentation because many symbols are repated in different
  ## modules. On the other hand, documentation indices are essentially table of
  ## contents plus a few special markers. These documents will be rendered in a
  ## separate section which tries to maintain the order and hierarchy of the
  ## symbols in the index file.
  ##
  ## To differentiate between a documentation and API file a convention is
  ## used: indices which contain one entry without the HTML hash character (#)
  ## will be considered `documentation`, since this hash-less entry is the
  ## explicit title of the document.  Indices without this explicit entry will
  ## be considered `generated API` extracted out of a source ``.nim`` file.
  ##
  ## Returns the merged and sorted indices into a single HTML block which can
  ## be further embedded into nimdoc templates.
  var (modules, symbols, docs) = readIndexDir(dir)

  result = ""
  # Generate a quick jump list of documents.
  if docs.len > 0:
    result.add(generateDocumentationJumps(docs))
    result.add("<p />")

  # Generate hyperlinks to all the linked modules.
  if modules.len > 0:
    result.add(generateModuleJumps(modules))
    result.add("<p />")

  when false:
    # Generate the HTML block with API documents.
    if docs.len > 0:
      result.add("<h2>Documentation files</h2>\n")
      result.add(generateDocumentationIndex(docs))

  # Generate the HTML block with symbols.
  if symbols.len > 0:
    sortIndex(symbols)
    result.add("<h2>API symbols</h2>\n")
    result.add(generateSymbolIndex(symbols))


# ----------------------------------------------------------------------------

proc stripTocHtml(s: string): string =
  ## Ugly quick hack to remove HTML tags from TOC titles.
  ##
  ## A TocEntry.header field already contains rendered HTML tags. Instead of
  ## implementing a proper version of renderRstToOut() which recursively
  ## renders an rst tree to plain text, we simply remove text found between
  ## angled brackets. Given the limited possibilities of rst inside TOC titles
  ## this should be enough.
  result = s
  var first = result.find('<')
  while first >= 0:
    let last = result.find('>', first)
    if last < 0:
      # Abort, since we didn't found a closing angled bracket.
      return
    result.delete(first, last)
    first = result.find('<', first)

proc renderHeadline(d: PDoc, n: PRstNode, result: var string) =
  var tmp = ""
  for i in countup(0, len(n) - 1): renderRstToOut(d, n.sons[i], tmp)
  d.currentSection = tmp
  # Find the last higher level section for unique reference name
  var sectionPrefix = ""
  for i in countdown(d.tocPart.high, 0):
    let n2 = d.tocPart[i].n
    if n2.level < n.level:
      sectionPrefix = rstnodeToRefname(n2) & "-"
      break
  var refname = sectionPrefix & rstnodeToRefname(n)
  if d.hasToc:
    var length = len(d.tocPart)
    setLen(d.tocPart, length + 1)
    d.tocPart[length].refname = refname
    d.tocPart[length].n = n
    d.tocPart[length].header = tmp

    dispA(d.target, result, "\n<h$1><a class=\"toc-backref\" " &
      "id=\"$2\" href=\"#$2\">$3</a></h$1>", "\\rsth$4{$3}\\label{$2}\n",
      [$n.level, d.tocPart[length].refname, tmp, $chr(n.level - 1 + ord('A'))])
  else:
    dispA(d.target, result, "\n<h$1 id=\"$2\">$3</h$1>",
                            "\\rsth$4{$3}\\label{$2}\n", [
        $n.level, refname, tmp,
        $chr(n.level - 1 + ord('A'))])

  # Generate index entry using spaces to indicate TOC level for the output HTML.
  assert n.level >= 0
  setIndexTerm(d, changeFileExt(extractFilename(d.filename), HtmlExt), refname, tmp.stripTocHtml,
    spaces(max(0, n.level)) & tmp)

proc renderOverline(d: PDoc, n: PRstNode, result: var string) =
  if d.meta[metaTitle].len == 0:
    for i in countup(0, len(n)-1):
      renderRstToOut(d, n.sons[i], d.meta[metaTitle])
    d.currentSection = d.meta[metaTitle]
  elif d.meta[metaSubtitle].len == 0:
    for i in countup(0, len(n)-1):
      renderRstToOut(d, n.sons[i], d.meta[metaSubtitle])
    d.currentSection = d.meta[metaSubtitle]
  else:
    var tmp = ""
    for i in countup(0, len(n) - 1): renderRstToOut(d, n.sons[i], tmp)
    d.currentSection = tmp
    dispA(d.target, result, "<h$1 id=\"$2\"><center>$3</center></h$1>",
                   "\\rstov$4{$3}\\label{$2}\n", [$n.level,
        rstnodeToRefname(n), tmp, $chr(n.level - 1 + ord('A'))])


proc renderTocEntry(d: PDoc, e: TocEntry, result: var string) =
  dispA(d.target, result,
    "<li><a class=\"reference\" id=\"$1_toc\" href=\"#$1\">$2</a></li>\n",
    "\\item\\label{$1_toc} $2\\ref{$1}\n", [e.refname, e.header])

proc renderTocEntries*(d: var RstGenerator, j: var int, lvl: int,
                       result: var string) =
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
  let
    arg = getArgument(n)
  var
    options = ""

  var s = esc(d.target, getFieldValue(n, "scale").strip())
  if s.len > 0:
    dispA(d.target, options, " scale=\"$1\"", " scale=$1", [s])

  s = esc(d.target, getFieldValue(n, "height").strip())
  if s.len > 0:
    dispA(d.target, options, " height=\"$1\"", " height=$1", [s])

  s = esc(d.target, getFieldValue(n, "width").strip())
  if s.len > 0:
    dispA(d.target, options, " width=\"$1\"", " width=$1", [s])

  s = esc(d.target, getFieldValue(n, "alt").strip())
  if s.len > 0:
    dispA(d.target, options, " alt=\"$1\"", "", [s])

  s = esc(d.target, getFieldValue(n, "align").strip())
  if s.len > 0:
    dispA(d.target, options, " align=\"$1\"", "", [s])

  if options.len > 0: options = dispF(d.target, "$1", "[$1]", [options])

  var htmlOut = ""
  if arg.endsWith(".mp4") or arg.endsWith(".ogg") or
     arg.endsWith(".webm"):
    htmlOut = """
      <video src="$1"$2 autoPlay='true' loop='true' muted='true'>
      Sorry, your browser doesn't support embedded videos
      </video>
    """
  else:
    htmlOut = "<img src=\"$1\"$2/>"
  dispA(d.target, result, htmlOut, "\\includegraphics$2{$1}",
        [esc(d.target, arg), options])
  if len(n) >= 3: renderRstToOut(d, n.sons[2], result)

proc renderSmiley(d: PDoc, n: PRstNode, result: var string) =
  dispA(d.target, result,
    """<img src="$1" width="15"
        height="17" hspace="2" vspace="2" class="smiley" />""",
    "\\includegraphics{$1}",
    [d.config.getOrDefault"doc.smiley_format" % n.text])

proc parseCodeBlockField(d: PDoc, n: PRstNode, params: var CodeBlockParams) =
  ## Parses useful fields which can appear before a code block.
  ##
  ## This supports the special ``default-language`` internal string generated
  ## by the ``rst`` module to communicate a specific default language.
  case n.getArgument.toLowerAscii
  of "number-lines":
    params.numberLines = true
    # See if the field has a parameter specifying a different line than 1.
    var number: int
    if parseInt(n.getFieldValue, number) > 0:
      params.startLine = number
  of "file", "filename":
    # The ``file`` option is a Nim extension to the official spec, it acts
    # like it would for other directives like ``raw`` or ``cvs-table``. This
    # field is dealt with in ``rst.nim`` which replaces the existing block with
    # the referenced file, so we only need to ignore it here to avoid incorrect
    # warning messages.
    params.filename = n.getFieldValue.strip
  of "test":
    params.testCmd = n.getFieldValue.strip
    if params.testCmd.len == 0:
      params.testCmd = "nim c -r $1"
    else:
      params.testCmd = unescape(params.testCmd)
  of "status", "exitcode":
    var status: int
    if parseInt(n.getFieldValue, status) > 0:
      params.status = status
  of "default-language":
    params.langStr = n.getFieldValue.strip
    params.lang = params.langStr.getSourceLanguage
  else:
    d.msgHandler(d.filename, 1, 0, mwUnsupportedField, n.getArgument)

proc parseCodeBlockParams(d: PDoc, n: PRstNode): CodeBlockParams =
  ## Iterates over all code block fields and returns processed params.
  ##
  ## Also processes the argument of the directive as the default language. This
  ## is done last so as to override any internal communication field variables.
  result.init
  if n.isNil:
    return
  assert n.kind == rnCodeBlock
  assert(not n.sons[2].isNil)

  # Parse the field list for rendering parameters if there are any.
  if not n.sons[1].isNil:
    for son in n.sons[1].sons: d.parseCodeBlockField(son, result)

  # Parse the argument and override the language.
  result.langStr = strip(getArgument(n))
  if result.langStr != "":
    result.lang = getSourceLanguage(result.langStr)

proc buildLinesHtmlTable(d: PDoc; params: CodeBlockParams, code: string):
    tuple[beginTable, endTable: string] =
  ## Returns the necessary tags to start/end a code block in HTML.
  ##
  ## If the numberLines has not been used, the tags will default to a simple
  ## <pre> pair. Otherwise it will build a table and insert an initial column
  ## with all the line numbers, which requires you to pass the `code` to detect
  ## how many lines have to be generated (and starting at which point!).
  inc d.listingCounter
  let id = $d.listingCounter
  if not params.numberLines:
    result = (d.config.getOrDefault"doc.listing_start" %
                [id, sourceLanguageToStr[params.lang]],
              d.config.getOrDefault"doc.listing_end" % id)
    return

  var codeLines = code.strip.countLines
  assert codeLines > 0
  result.beginTable = """<table class="line-nums-table"><tbody><tr><td class="blob-line-nums"><pre class="line-nums">"""
  var line = params.startLine
  while codeLines > 0:
    result.beginTable.add($line & "\n")
    line.inc
    codeLines.dec
  result.beginTable.add("</pre></td><td>" & (
      d.config.getOrDefault"doc.listing_start" %
        [id, sourceLanguageToStr[params.lang]]))
  result.endTable = (d.config.getOrDefault"doc.listing_end" % id) &
      "</td></tr></tbody></table>" & (
      d.config.getOrDefault"doc.listing_button" % id)

proc renderCodeBlock(d: PDoc, n: PRstNode, result: var string) =
  ## Renders a code block, appending it to `result`.
  ##
  ## If the code block uses the ``number-lines`` option, a table will be
  ## generated with two columns, the first being a list of numbers and the
  ## second the code block itself. The code block can use syntax highlighting,
  ## which depends on the directive argument specified by the rst input, and
  ## may also come from the parser through the internal ``default-language``
  ## option to differentiate between a plain code block and Nim's code block
  ## extension.
  assert n.kind == rnCodeBlock
  if n.sons[2] == nil: return
  var params = d.parseCodeBlockParams(n)
  var m = n.sons[2].sons[0]
  assert m.kind == rnLeaf

  if params.testCmd.len > 0 and d.onTestSnippet != nil:
    d.onTestSnippet(d, params.filename, params.testCmd, params.status, m.text)

  let (blockStart, blockEnd) = buildLinesHtmlTable(d, params, m.text)

  dispA(d.target, result, blockStart, "\\begin{rstpre}\n", [])
  if params.lang == langNone:
    if len(params.langStr) > 0:
      d.msgHandler(d.filename, 1, 0, mwUnsupportedLanguage, params.langStr)
    for letter in m.text: escChar(d.target, result, letter)
  else:
    var g: GeneralTokenizer
    initGeneralTokenizer(g, m.text)
    while true:
      getNextToken(g, params.lang)
      case g.kind
      of gtEof: break
      of gtNone, gtWhitespace:
        add(result, substr(m.text, g.start, g.length + g.start - 1))
      else:
        dispA(d.target, result, "<span class=\"$2\">$1</span>", "\\span$2{$1}", [
          esc(d.target, substr(m.text, g.start, g.length+g.start-1)),
          tokenClassToStr[g.kind]])
    deinitGeneralTokenizer(g)
  dispA(d.target, result, blockEnd, "\n\\end{rstpre}\n")

proc renderContainer(d: PDoc, n: PRstNode, result: var string) =
  var tmp = ""
  renderRstToOut(d, n.sons[2], tmp)
  var arg = esc(d.target, strip(getArgument(n)))
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
    elif cmpIgnoreStyle(fieldname, "version") == 0:
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
    renderAux(d, n, "<th class=\"docinfo-name\">$1:</th>",
                    "\\item[$1:]", result)
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
    dispA(d.target, result,
      "<a class=\"reference external\" href=\"#$2\">$1</a>",
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
    dispA(d.target, result,
      "<a class=\"reference external\" href=\"$2\">$1</a>",
      "\\href{$2}{$1}", [tmp0, tmp1])
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
  of rnIdx:
    renderIndexTerm(d, n, result)
  of rnInlineLiteral, rnInterpretedText:
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

proc getVarIdx(varnames: openArray[string], id: string): int =
  for i in countup(0, high(varnames)):
    if cmpIgnoreStyle(varnames[i], id) == 0:
      return i
  result = -1

proc formatNamedVars*(frmt: string, varnames: openArray[string],
                      varvalues: openArray[string]): string =
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
          j = (j * 10) + ord(frmt[i]) - ord('0')
          inc(i)
          if i > L-1 or frmt[i] notin {'0'..'9'}: break
        if j > high(varvalues) + 1:
          raise newException(ValueError, "invalid index: " & $j)
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
          raise newException(ValueError, "unknown substitution var: " & id)
      of '{':
        var id = ""
        inc(i)
        while frmt[i] != '}':
          if frmt[i] == '\0':
            raise newException(ValueError, "'}' expected")
          add(id, frmt[i])
          inc(i)
        inc(i)                # skip }
                              # search for the variable:
        var idx = getVarIdx(varnames, id)
        if idx >= 0: add(result, varvalues[idx])
        else:
          raise newException(ValueError, "unknown substitution var: " & id)
      else:
        raise newException(ValueError, "unknown substitution: $" & $frmt[i])
    var start = i
    while i < L:
      if frmt[i] != '$': inc(i)
      else: break
    if i-1 >= start: add(result, substr(frmt, start, i - 1))


proc defaultConfig*(): StringTableRef =
  ## Returns a default configuration for embedded HTML generation.
  ##
  ## The returned ``StringTableRef`` contains the parameters used by the HTML
  ## engine to build the final output. For information on what these parameters
  ## are and their purpose, please look up the file ``config/nimdoc.cfg``
  ## bundled with the compiler.
  ##
  ## The only difference between the contents of that file and the values
  ## provided by this proc is the ``doc.file`` variable. The ``doc.file``
  ## variable of the configuration file contains HTML to build standalone
  ## pages, while this proc returns just the content for procs like
  ## ``rstToHtml`` to generate the bare minimum HTML.
  result = newStringTable(modeStyleInsensitive)

  template setConfigVar(key, val) =
    result[key] = val

  # If you need to modify these values, it might be worth updating the template
  # file in config/nimdoc.cfg.
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
<dt id="$itemID"><a name="$itemSymOrIDEnc"></a><pre>$header</pre></dt>
<dd>
$desc
</dd>
""")
  setConfigVar("doc.item.toc", """
  <li><a class="reference" href="#$itemSymOrIDEnc"
    title="$header_plain">$name</a></li>
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
  setConfigVar("doc.listing_start", "<pre class = \"listing\">")
  setConfigVar("doc.listing_end", "</pre>")
  setConfigVar("doc.listing_button", "</pre>")
  setConfigVar("doc.body_no_toc", "$moduledesc $content")
  setConfigVar("doc.file", "$content")
  setConfigVar("doc.smiley_format", "/images/smilies/$1.gif")

# ---------- forum ---------------------------------------------------------

proc rstToHtml*(s: string, options: RstParseOptions,
                config: StringTableRef): string =
  ## Converts an input rst string into embeddable HTML.
  ##
  ## This convenience proc parses any input string using rst markup (it doesn't
  ## have to be a full document!) and returns an embeddable piece of HTML. The
  ## proc is meant to be used in *online* environments without access to a
  ## meaningful filesystem, and therefore rst ``include`` like directives won't
  ## work. For an explanation of the ``config`` parameter see the
  ## ``initRstGenerator`` proc. Example:
  ##
  ## .. code-block:: nim
  ##   import packages/docutils/rstgen, strtabs
  ##
  ##   echo rstToHtml("*Hello* **world**!", {},
  ##     newStringTable(modeStyleInsensitive))
  ##   # --> <em>Hello</em> <strong>world</strong>!
  ##
  ## If you need to allow the rst ``include`` directive or tweak the generated
  ## output you have to create your own ``RstGenerator`` with
  ## ``initRstGenerator`` and related procs.

  proc myFindFile(filename: string): string =
    # we don't find any files in online mode:
    result = ""

  const filen = "input"
  var d: RstGenerator
  initRstGenerator(d, outHtml, config, filen, options, myFindFile,
                   rst.defaultMsgHandler)
  var dummyHasToc = false
  var rst = rstParse(s, filen, 0, 1, dummyHasToc, options)
  result = ""
  renderRstToOut(d, rst, result)


when isMainModule:
  assert rstToHtml("*Hello* **world**!", {},
    newStringTable(modeStyleInsensitive)) ==
    "<em>Hello</em> <strong>world</strong>!"
