#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This is the documentation generator. It is currently pretty simple: No
# semantic checking is done for the code. Cross-references are generated
# by knowing how the anchors are going to be named.

import
  ast, strutils, strtabs, options, msgs, os, ropes, idents,
  wordrecg, syntaxes, renderer, lexer, packages/docutils/rstast,
  packages/docutils/rst, packages/docutils/rstgen, times,
  packages/docutils/highlite, sempass2, json, xmltree, cgi,
  typesrenderer, astalgo, modulepaths, lineinfos

type
  TSections = array[TSymKind, Rope]
  TDocumentor = object of rstgen.RstGenerator
    modDesc: Rope           # module description
    toc, section: TSections
    indexValFilename: string
    analytics: string  # Google Analytics javascript, "" if doesn't exist
    seenSymbols: StringTableRef # avoids duplicate symbol generation for HTML.
    jArray: JsonNode
    types: TStrTable
    isPureRst: bool
    conf*: ConfigRef
    cache*: IdentCache

  PDoc* = ref TDocumentor ## Alias to type less.

proc whichType(d: PDoc; n: PNode): PSym =
  if n.kind == nkSym:
    if d.types.strTableContains(n.sym):
      result = n.sym
  else:
    for i in 0..<safeLen(n):
      let x = whichType(d, n[i])
      if x != nil: return x

proc attachToType(d: PDoc; p: PSym): PSym =
  let params = p.ast.sons[paramsPos]
  # first check the first parameter, then the return type,
  # then the other parameter:
  template check(i) =
    result = whichType(d, params[i])
    if result != nil: return result

  if params.len > 1: check(1)
  if params.len > 0: check(0)
  for i in 2..<params.len: check(i)

template declareClosures =
  proc compilerMsgHandler(filename: string, line, col: int,
                          msgKind: rst.MsgKind, arg: string) {.procvar.} =
    # translate msg kind:
    var k: TMsgKind
    case msgKind
    of meCannotOpenFile: k = errCannotOpenFile
    of meExpected: k = errXExpected
    of meGridTableNotImplemented: k = errGridTableNotImplemented
    of meNewSectionExpected: k = errNewSectionExpected
    of meGeneralParseError: k = errGeneralParseError
    of meInvalidDirective: k = errInvalidDirectiveX
    of mwRedefinitionOfLabel: k = warnRedefinitionOfLabel
    of mwUnknownSubstitution: k = warnUnknownSubstitutionX
    of mwUnsupportedLanguage: k = warnLanguageXNotSupported
    of mwUnsupportedField: k = warnFieldXNotSupported
    globalError(conf, newLineInfo(conf, filename, line, col), k, arg)

  proc docgenFindFile(s: string): string {.procvar.} =
    result = options.findFile(conf, s)
    if result.len == 0:
      result = getCurrentDir() / s
      if not existsFile(result): result = ""

proc parseRst(text, filename: string,
              line, column: int, hasToc: var bool,
              rstOptions: RstParseOptions;
              conf: ConfigRef): PRstNode =
  declareClosures()
  result = rstParse(text, filename, line, column, hasToc, rstOptions,
                    docgenFindFile, compilerMsgHandler)

proc newDocumentor*(filename: string; cache: IdentCache; conf: ConfigRef): PDoc =
  declareClosures()
  new(result)
  result.conf = conf
  result.cache = cache
  initRstGenerator(result[], (if conf.cmd != cmdRst2tex: outHtml else: outLatex),
                   conf.configVars, filename, {roSupportRawDirective},
                   docgenFindFile, compilerMsgHandler)

  if conf.configVars.hasKey("doc.googleAnalytics"):
    result.analytics = """
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', '$1', 'auto');
  ga('send', 'pageview');

</script>
    """ % [conf.configVars.getOrDefault"doc.googleAnalytics"]
  else:
    result.analytics = ""

  result.seenSymbols = newStringTable(modeCaseInsensitive)
  result.id = 100
  result.jArray = newJArray()
  initStrTable result.types
  result.onTestSnippet = proc (d: var RstGenerator; filename, cmd: string; status: int; content: string) =
    localError(conf, newLineInfo(conf, d.filename, -1, -1), warnUser, "only 'rst2html' supports the ':test:' attribute")

proc dispA(conf: ConfigRef; dest: var Rope, xml, tex: string, args: openArray[Rope]) =
  if conf.cmd != cmdRst2tex: addf(dest, xml, args)
  else: addf(dest, tex, args)

proc getVarIdx(varnames: openArray[string], id: string): int =
  for i in countup(0, high(varnames)):
    if cmpIgnoreStyle(varnames[i], id) == 0:
      return i
  result = -1

proc ropeFormatNamedVars(conf: ConfigRef; frmt: FormatStr,
                         varnames: openArray[string],
                         varvalues: openArray[Rope]): Rope =
  var i = 0
  var L = len(frmt)
  result = nil
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
          if (i > L + 0 - 1) or not (frmt[i] in {'0'..'9'}): break
        if j > high(varvalues) + 1:
          rawMessage(conf, errGenerated, "Invalid format string; too many $s: " & frmt)
        num = j
        add(result, varvalues[j - 1])
      of 'A'..'Z', 'a'..'z', '\x80'..'\xFF':
        var id = ""
        while true:
          add(id, frmt[i])
          inc(i)
          if not (frmt[i] in {'A'..'Z', '_', 'a'..'z', '\x80'..'\xFF'}): break
        var idx = getVarIdx(varnames, id)
        if idx >= 0: add(result, varvalues[idx])
        else: rawMessage(conf, errGenerated, "unknown substition variable: " & id)
      of '{':
        var id = ""
        inc(i)
        while i < frmt.len and frmt[i] != '}':
          add(id, frmt[i])
          inc(i)
        if i >= frmt.len:
          rawMessage(conf, errGenerated, "expected closing '}'")
        else:
          inc(i)                # skip }
        # search for the variable:
        let idx = getVarIdx(varnames, id)
        if idx >= 0: add(result, varvalues[idx])
        else: rawMessage(conf, errGenerated, "unknown substition variable: " & id)
      else:
        add(result, "$")
    var start = i
    while i < L:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start: add(result, substr(frmt, start, i - 1))

proc genComment(d: PDoc, n: PNode): string =
  result = ""
  var dummyHasToc: bool
  if n.comment != nil:
    renderRstToOut(d[], parseRst(n.comment, toFilename(d.conf, n.info),
                               toLinenumber(n.info), toColumn(n.info),
                               dummyHasToc, d.options, d.conf), result)

proc genRecComment(d: PDoc, n: PNode): Rope =
  if n == nil: return nil
  result = genComment(d, n).rope
  if result == nil:
    if n.kind notin {nkEmpty..nkNilLit, nkEnumTy, nkTupleTy}:
      for i in countup(0, len(n)-1):
        result = genRecComment(d, n.sons[i])
        if result != nil: return
  else:
    n.comment = nil

proc getPlainDocstring(n: PNode): string =
  ## Gets the plain text docstring of a node non destructively.
  ##
  ## You need to call this before genRecComment, whose side effects are removal
  ## of comments from the tree. The proc will recursively scan and return all
  ## the concatenated ``##`` comments of the node.
  result = ""
  if n == nil: return
  if n.comment != nil and startsWith(n.comment, "##"):
    result = n.comment
  if result.len < 1:
    for i in countup(0, safeLen(n)-1):
      result = getPlainDocstring(n.sons[i])
      if result.len > 0: return

proc nodeToHighlightedHtml(d: PDoc; n: PNode; result: var Rope; renderFlags: TRenderFlags = {}) =
  var r: TSrcGen
  var literal = ""
  initTokRender(r, n, renderFlags)
  var kind = tkEof
  while true:
    getNextTok(r, kind, literal)
    case kind
    of tkEof:
      break
    of tkComment:
      dispA(d.conf, result, "<span class=\"Comment\">$1</span>", "\\spanComment{$1}",
            [rope(esc(d.target, literal))])
    of tokKeywordLow..tokKeywordHigh:
      dispA(d.conf, result, "<span class=\"Keyword\">$1</span>", "\\spanKeyword{$1}",
            [rope(literal)])
    of tkOpr:
      dispA(d.conf, result, "<span class=\"Operator\">$1</span>", "\\spanOperator{$1}",
            [rope(esc(d.target, literal))])
    of tkStrLit..tkTripleStrLit:
      dispA(d.conf, result, "<span class=\"StringLit\">$1</span>",
            "\\spanStringLit{$1}", [rope(esc(d.target, literal))])
    of tkCharLit:
      dispA(d.conf, result, "<span class=\"CharLit\">$1</span>", "\\spanCharLit{$1}",
            [rope(esc(d.target, literal))])
    of tkIntLit..tkUInt64Lit:
      dispA(d.conf, result, "<span class=\"DecNumber\">$1</span>",
            "\\spanDecNumber{$1}", [rope(esc(d.target, literal))])
    of tkFloatLit..tkFloat128Lit:
      dispA(d.conf, result, "<span class=\"FloatNumber\">$1</span>",
            "\\spanFloatNumber{$1}", [rope(esc(d.target, literal))])
    of tkSymbol:
      dispA(d.conf, result, "<span class=\"Identifier\">$1</span>",
            "\\spanIdentifier{$1}", [rope(esc(d.target, literal))])
    of tkSpaces, tkInvalid:
      add(result, literal)
    of tkCurlyDotLe:
      dispA(d.conf, result, """<span class="Other pragmabegin">$1</span><div class="pragma">""",
                    "\\spanOther{$1}",
                  [rope(esc(d.target, literal))])
    of tkCurlyDotRi:
      dispA(d.conf, result, "</div><span class=\"Other pragmaend\">$1</span>",
                    "\\spanOther{$1}",
                  [rope(esc(d.target, literal))])
    of tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi,
       tkBracketDotLe, tkBracketDotRi, tkParDotLe,
       tkParDotRi, tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot,
       tkAccent, tkColonColon,
       tkGStrLit, tkGTripleStrLit, tkInfixOpr, tkPrefixOpr, tkPostfixOpr,
       tkBracketLeColon:
      dispA(d.conf, result, "<span class=\"Other\">$1</span>", "\\spanOther{$1}",
            [rope(esc(d.target, literal))])

proc getAllRunnableExamples(d: PDoc; n: PNode; dest: var Rope) =
  case n.kind
  of nkCallKinds:
    if n[0].kind == nkSym and n[0].sym.magic == mRunnableExamples and
        n.len >= 2 and n.lastSon.kind == nkStmtList:
      dispA(d.conf, dest, "\n<strong class=\"examples_text\">$1</strong>\n",
          "\n\\textbf{$1}\n", [rope"Examples:"])
      inc d.listingCounter
      let id = $d.listingCounter
      dest.add(d.config.getOrDefault"doc.listing_start" % [id, "langNim"])
      # this is a rather hacky way to get rid of the initial indentation
      # that the renderer currently produces:
      var i = 0
      var body = n.lastSon
      if body.len == 1 and body.kind == nkStmtList and
          body.lastSon.kind == nkStmtList:
        body = body.lastSon
      for b in body:
        if i > 0: dest.add "\n"
        inc i
        nodeToHighlightedHtml(d, b, dest, {})
      dest.add(d.config.getOrDefault"doc.listing_end" % id)
  else: discard
  for i in 0 ..< n.safeLen:
    getAllRunnableExamples(d, n[i], dest)

when false:
  proc findDocComment(n: PNode): PNode =
    if n == nil: return nil
    if not isNil(n.comment) and startsWith(n.comment, "##"): return n
    for i in countup(0, safeLen(n)-1):
      result = findDocComment(n.sons[i])
      if result != nil: return

  proc extractDocComment*(s: PSym, d: PDoc): string =
    let n = findDocComment(s.ast)
    result = ""
    if not n.isNil:
      if not d.isNil:
        var dummyHasToc: bool
        renderRstToOut(d[], parseRst(n.comment, toFilename(d.conf, n.info),
                                     toLinenumber(n.info), toColumn(n.info),
                                     dummyHasToc, d.options + {roSkipPounds}),
                       result)
      else:
        result = n.comment.substr(2).replace("\n##", "\n").strip

proc isVisible(n: PNode): bool =
  result = false
  if n.kind == nkPostfix:
    if n.len == 2 and n.sons[0].kind == nkIdent:
      var v = n.sons[0].ident
      result = v.id == ord(wStar) or v.id == ord(wMinus)
  elif n.kind == nkSym:
    # we cannot generate code for forwarded symbols here as we have no
    # exception tracking information here. Instead we copy over the comment
    # from the proc header.
    result = {sfExported, sfFromGeneric, sfForward}*n.sym.flags == {sfExported}
  elif n.kind == nkPragmaExpr:
    result = isVisible(n.sons[0])

proc getName(d: PDoc, n: PNode, splitAfter = -1): string =
  case n.kind
  of nkPostfix: result = getName(d, n.sons[1], splitAfter)
  of nkPragmaExpr: result = getName(d, n.sons[0], splitAfter)
  of nkSym: result = esc(d.target, n.sym.renderDefinitionName, splitAfter)
  of nkIdent: result = esc(d.target, n.ident.s, splitAfter)
  of nkAccQuoted:
    result = esc(d.target, "`")
    for i in 0..<n.len: result.add(getName(d, n[i], splitAfter))
    result.add esc(d.target, "`")
  of nkOpenSymChoice, nkClosedSymChoice:
    result = getName(d, n[0], splitAfter)
  else:
    result = ""

proc getNameIdent(cache: IdentCache; n: PNode): PIdent =
  case n.kind
  of nkPostfix: result = getNameIdent(cache, n.sons[1])
  of nkPragmaExpr: result = getNameIdent(cache, n.sons[0])
  of nkSym: result = n.sym.name
  of nkIdent: result = n.ident
  of nkAccQuoted:
    var r = ""
    for i in 0..<n.len: r.add(getNameIdent(cache, n[i]).s)
    result = getIdent(cache, r)
  of nkOpenSymChoice, nkClosedSymChoice:
    result = getNameIdent(cache, n[0])
  else:
    result = nil

proc getRstName(n: PNode): PRstNode =
  case n.kind
  of nkPostfix: result = getRstName(n.sons[1])
  of nkPragmaExpr: result = getRstName(n.sons[0])
  of nkSym: result = newRstNode(rnLeaf, n.sym.renderDefinitionName)
  of nkIdent: result = newRstNode(rnLeaf, n.ident.s)
  of nkAccQuoted:
    result = getRstName(n.sons[0])
    for i in 1 ..< n.len: result.text.add(getRstName(n[i]).text)
  of nkOpenSymChoice, nkClosedSymChoice:
    result = getRstName(n[0])
  else:
    result = nil

proc newUniquePlainSymbol(d: PDoc, original: string): string =
  ## Returns a new unique plain symbol made up from the original.
  ##
  ## When a collision is found in the seenSymbols table, new numerical variants
  ## with underscore + number will be generated.
  if not d.seenSymbols.hasKey(original):
    result = original
    d.seenSymbols[original] = ""
    return

  # Iterate over possible numeric variants of the original name.
  var count = 2

  while true:
    result = original & "_" & $count
    if not d.seenSymbols.hasKey(result):
      d.seenSymbols[result] = ""
      break
    count += 1


proc complexName(k: TSymKind, n: PNode, baseName: string): string =
  ## Builds a complex unique href name for the node.
  ##
  ## Pass as ``baseName`` the plain symbol obtained from the nodeName. The
  ## format of the returned symbol will be ``baseName(.callable type)?,(param
  ## type)?(,param type)*``. The callable type part will be added only if the
  ## node is not a proc, as those are the common ones. The suffix will be a dot
  ## and a single letter representing the type of the callable. The parameter
  ## types will be added with a preceding dash. Return types won't be added.
  ##
  ## If you modify the output of this proc, please update the anchor generation
  ## section of ``doc/docgen.txt``.
  result = baseName
  case k:
  of skProc, skFunc: result.add(defaultParamSeparator)
  of skMacro: result.add(".m" & defaultParamSeparator)
  of skMethod: result.add(".e" & defaultParamSeparator)
  of skIterator: result.add(".i" & defaultParamSeparator)
  of skTemplate: result.add(".t" & defaultParamSeparator)
  of skConverter: result.add(".c" & defaultParamSeparator)
  else: discard

  if len(n) > paramsPos and n[paramsPos].kind == nkFormalParams:
    result.add(renderParamTypes(n[paramsPos]))


proc isCallable(n: PNode): bool =
  ## Returns true if `n` contains a callable node.
  case n.kind
  of nkProcDef, nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef,
    nkConverterDef, nkFuncDef: result = true
  else:
    result = false


proc docstringSummary(rstText: string): string =
  ## Returns just the first line or a brief chunk of text from a rst string.
  ##
  ## Most docstrings will contain a one liner summary, so stripping at the
  ## first newline is usually fine. If after that the content is still too big,
  ## it is stripped at the first comma, colon or dot, usual english sentence
  ## separators.
  ##
  ## No guarantees are made on the size of the output, but it should be small.
  ## Also, we hope to not break the rst, but maybe we do. If there is any
  ## trimming done, an ellipsis unicode char is added.
  const maxDocstringChars = 100
  assert(rstText.len < 2 or (rstText[0] == '#' and rstText[1] == '#'))
  result = rstText.substr(2).strip
  var pos = result.find('\L')
  if pos > 0:
    result.delete(pos, result.len - 1)
    result.add("…")
  if pos < maxDocstringChars:
    return
  # Try to keep trimming at other natural boundaries.
  pos = result.find({'.', ',', ':'})
  let last = result.len - 1
  if pos > 0 and pos < last:
    result.delete(pos, last)
    result.add("…")


proc genItem(d: PDoc, n, nameNode: PNode, k: TSymKind) =
  if not isVisible(nameNode): return
  let
    name = getName(d, nameNode)
    nameRope = name.rope
  var plainDocstring = getPlainDocstring(n) # call here before genRecComment!
  var result: Rope = nil
  var literal, plainName = ""
  var kind = tkEof
  var comm = genRecComment(d, n)  # call this here for the side-effect!
  getAllRunnableExamples(d, n, comm)
  var r: TSrcGen
  # Obtain the plain rendered string for hyperlink titles.
  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments,
    renderNoPragmas, renderNoProcDefs})
  while true:
    getNextTok(r, kind, literal)
    if kind == tkEof:
      break
    plainName.add(literal)

  # Render the HTML hyperlink.
  nodeToHighlightedHtml(d, n, result, {renderNoBody, renderNoComments, renderDocComments})

  inc(d.id)
  let
    plainNameRope = rope(xmltree.escape(plainName.strip))
    cleanPlainSymbol = renderPlainSymbolName(nameNode)
    complexSymbol = complexName(k, n, cleanPlainSymbol)
    plainSymbolRope = rope(cleanPlainSymbol)
    plainSymbolEncRope = rope(encodeUrl(cleanPlainSymbol))
    itemIDRope = rope(d.id)
    symbolOrId = d.newUniquePlainSymbol(complexSymbol)
    symbolOrIdRope = symbolOrId.rope
    symbolOrIdEncRope = encodeUrl(symbolOrId).rope

  var seeSrcRope: Rope = nil
  let docItemSeeSrc = getConfigVar(d.conf, "doc.item.seesrc")
  if docItemSeeSrc.len > 0:
    let cwd = canonicalizePath(d.conf, getCurrentDir())
    var path = toFullPath(d.conf, n.info)
    if path.startsWith(cwd):
      path = path[cwd.len+1 .. ^1].replace('\\', '/')
    let gitUrl = getConfigVar(d.conf, "git.url")
    if gitUrl.len > 0:
      var commit = getConfigVar(d.conf, "git.commit")
      if commit.len == 0: commit = "master"
      dispA(d.conf, seeSrcRope, "$1", "", [ropeFormatNamedVars(d.conf, docItemSeeSrc,
          ["path", "line", "url", "commit"], [rope path,
          rope($n.info.line), rope gitUrl,
          rope commit])])

  add(d.section[k], ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.item"),
    ["name", "header", "desc", "itemID", "header_plain", "itemSym",
      "itemSymOrID", "itemSymEnc", "itemSymOrIDEnc", "seeSrc"],
    [nameRope, result, comm, itemIDRope, plainNameRope, plainSymbolRope,
      symbolOrIdRope, plainSymbolEncRope, symbolOrIdEncRope, seeSrcRope]))

  var attype: Rope
  if k in routineKinds and nameNode.kind == nkSym:
    let att = attachToType(d, nameNode.sym)
    if att != nil:
      attype = rope esc(d.target, att.name.s)
  add(d.toc[k], ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.item.toc"),
    ["name", "header", "desc", "itemID", "header_plain", "itemSym",
      "itemSymOrID", "itemSymEnc", "itemSymOrIDEnc", "attype"],
    [rope(getName(d, nameNode, d.splitAfter)), result, comm,
      itemIDRope, plainNameRope, plainSymbolRope, symbolOrIdRope,
      plainSymbolEncRope, symbolOrIdEncRope, attype]))

  # Ironically for types the complexSymbol is *cleaner* than the plainName
  # because it doesn't include object fields or documentation comments. So we
  # use the plain one for callable elements, and the complex for the rest.
  var linkTitle = changeFileExt(extractFilename(d.filename), "") & " : "
  if n.isCallable: linkTitle.add(xmltree.escape(plainName.strip))
  else: linkTitle.add(xmltree.escape(complexSymbol.strip))

  setIndexTerm(d[], symbolOrId, name, linkTitle,
    xmltree.escape(plainDocstring.docstringSummary))
  if k == skType and nameNode.kind == nkSym:
    d.types.strTableAdd nameNode.sym

proc genJsonItem(d: PDoc, n, nameNode: PNode, k: TSymKind): JsonNode =
  if not isVisible(nameNode): return
  var
    name = getName(d, nameNode)
    comm = $genRecComment(d, n)
    r: TSrcGen

  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments})

  result = %{ "name": %name, "type": %($k), "line": %n.info.line.int,
                 "col": %n.info.col}
  if comm != nil and comm != "":
    result["description"] = %comm
  if r.buf != nil:
    result["code"] = %r.buf

proc checkForFalse(n: PNode): bool =
  result = n.kind == nkIdent and cmpIgnoreStyle(n.ident.s, "false") == 0

proc traceDeps(d: PDoc, it: PNode) =
  const k = skModule

  if it.kind == nkInfix and it.len == 3 and it[2].kind == nkBracket:
    let sep = it[0]
    let dir = it[1]
    let a = newNodeI(nkInfix, it.info)
    a.add sep
    a.add dir
    a.add sep # dummy entry, replaced in the loop
    for x in it[2]:
      a.sons[2] = x
      traceDeps(d, a)
  else:
    if d.section[k] != nil: add(d.section[k], ", ")
    dispA(d.conf, d.section[k],
          "<a class=\"reference external\" href=\"$1.html\">$1</a>",
          "$1", [rope(getModuleName(d.conf, it))])

proc generateDoc*(d: PDoc, n: PNode) =
  case n.kind
  of nkCommentStmt: add(d.modDesc, genComment(d, n))
  of nkProcDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItem(d, n, n.sons[namePos], skProc)
  of nkFuncDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItem(d, n, n.sons[namePos], skFunc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItem(d, n, n.sons[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItem(d, n, n.sons[namePos], skIterator)
  of nkMacroDef: genItem(d, n, n.sons[namePos], skMacro)
  of nkTemplateDef: genItem(d, n, n.sons[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItem(d, n, n.sons[namePos], skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1):
      if n.sons[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        genItem(d, n.sons[i], n.sons[i].sons[0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)))
  of nkStmtList:
    for i in countup(0, sonsLen(n) - 1): generateDoc(d, n.sons[i])
  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n.sons[0].sons[0]):
      generateDoc(d, lastSon(n.sons[0]))
  of nkImportStmt:
    for i in 0 .. sonsLen(n)-1: traceDeps(d, n.sons[i])
  of nkFromStmt, nkImportExceptStmt: traceDeps(d, n.sons[0])
  else: discard

proc add(d: PDoc; j: JsonNode) =
  if j != nil: d.jArray.add j

proc generateJson*(d: PDoc, n: PNode) =
  case n.kind
  of nkCommentStmt:
    if n.comment != nil and startsWith(n.comment, "##"):
      let stripped = n.comment.substr(2).strip
      d.add %{ "comment": %stripped, "line": %n.info.line.int,
               "col": %n.info.col }
  of nkProcDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n.sons[namePos], skProc)
  of nkFuncDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n.sons[namePos], skFunc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n.sons[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n.sons[namePos], skIterator)
  of nkMacroDef:
    d.add genJsonItem(d, n, n.sons[namePos], skMacro)
  of nkTemplateDef:
    d.add genJsonItem(d, n, n.sons[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n.sons[namePos], skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1):
      if n.sons[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        d.add genJsonItem(d, n.sons[i], n.sons[i].sons[0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)))
  of nkStmtList:
    for i in countup(0, sonsLen(n) - 1):
      generateJson(d, n.sons[i])
  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n.sons[0].sons[0]):
      generateJson(d, lastSon(n.sons[0]))
  else: discard

proc genTagsItem(d: PDoc, n, nameNode: PNode, k: TSymKind): string =
  result = getName(d, nameNode) & "\n"

proc generateTags*(d: PDoc, n: PNode, r: var Rope) =
  case n.kind
  of nkCommentStmt:
    if n.comment != nil and startsWith(n.comment, "##"):
      let stripped = n.comment.substr(2).strip
      r.add stripped
  of nkProcDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n.sons[namePos], skProc)
  of nkFuncDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n.sons[namePos], skFunc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n.sons[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n.sons[namePos], skIterator)
  of nkMacroDef:
    r.add genTagsItem(d, n, n.sons[namePos], skMacro)
  of nkTemplateDef:
    r.add genTagsItem(d, n, n.sons[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n.sons[namePos], skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1):
      if n.sons[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        r.add genTagsItem(d, n.sons[i], n.sons[i].sons[0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)))
  of nkStmtList:
    for i in countup(0, sonsLen(n) - 1):
      generateTags(d, n.sons[i], r)
  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n.sons[0].sons[0]):
      generateTags(d, lastSon(n.sons[0]), r)
  else: discard

proc genSection(d: PDoc, kind: TSymKind) =
  const sectionNames: array[skModule..skTemplate, string] = [
    "Imports", "Types", "Vars", "Lets", "Consts", "Vars", "Procs", "Funcs",
    "Methods", "Iterators", "Converters", "Macros", "Templates"
  ]
  if d.section[kind] == nil: return
  var title = sectionNames[kind].rope
  d.section[kind] = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.section"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      ord(kind).rope, title, rope(ord(kind) + 50), d.section[kind]])
  d.toc[kind] = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.section.toc"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      ord(kind).rope, title, rope(ord(kind) + 50), d.toc[kind]])

proc genOutFile(d: PDoc): Rope =
  var
    code, content: Rope
    title = ""
  var j = 0
  var tmp = ""
  renderTocEntries(d[], j, 1, tmp)
  var toc = tmp.rope
  for i in countup(low(TSymKind), high(TSymKind)):
    genSection(d, i)
    add(toc, d.toc[i])
  if toc != nil:
    toc = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.toc"), ["content"], [toc])
  for i in countup(low(TSymKind), high(TSymKind)): add(code, d.section[i])

  # Extract the title. Non API modules generate an entry in the index table.
  if d.meta[metaTitle].len != 0:
    title = d.meta[metaTitle]
    setIndexTerm(d[], "", title)
  else:
    # Modules get an automatic title for the HTML, but no entry in the index.
    title = "Module " & extractFilename(changeFileExt(d.filename, ""))

  let bodyname = if d.hasToc and not d.isPureRst: "doc.body_toc_group"
                 elif d.hasToc: "doc.body_toc"
                 else: "doc.body_no_toc"
  content = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, bodyname), ["title",
      "tableofcontents", "moduledesc", "date", "time", "content"],
      [title.rope, toc, d.modDesc, rope(getDateStr()),
      rope(getClockStr()), code])
  if optCompileOnly notin d.conf.globalOptions:
    # XXX what is this hack doing here? 'optCompileOnly' means raw output!?
    code = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.file"), ["title",
        "tableofcontents", "moduledesc", "date", "time",
        "content", "author", "version", "analytics"],
        [title.rope, toc, d.modDesc, rope(getDateStr()),
                     rope(getClockStr()), content, d.meta[metaAuthor].rope,
                     d.meta[metaVersion].rope, d.analytics.rope])
  else:
    code = content
  result = code

proc generateIndex*(d: PDoc) =
  if optGenIndex in d.conf.globalOptions:
    writeIndexFile(d[], splitFile(d.conf.outFile).dir /
                        splitFile(d.filename).name & IndexExt)

proc getOutFile2(conf: ConfigRef; filename, ext, dir: string): string =
  if optWholeProject in conf.globalOptions:
    let d = if conf.outFile != "": conf.outFile else: dir
    createDir(d)
    result = d / changeFileExt(filename, ext)
  else:
    result = getOutFile(conf, filename, ext)

proc writeOutput*(d: PDoc, filename, outExt: string, useWarning = false) =
  var content = genOutFile(d)
  var success = true
  var filename: string
  if optStdout in d.conf.globalOptions:
    writeRope(stdout, content)
    filename = "<stdout>"
  else:
    filename = getOutFile2(d.conf, filename, outExt, "htmldocs")
    success = writeRope(content, filename)
  if not success:
    rawMessage(d.conf, if useWarning: warnCannotOpenFile else: errCannotOpenFile, filename)

proc writeOutputJson*(d: PDoc, filename, outExt: string,
                      useWarning = false) =
  let content = %*{"orig": d.filename,
    "nimble": getPackageName(d.conf, d.filename),
    "entries": d.jArray}
  if optStdout in d.conf.globalOptions:
    write(stdout, $content)
  else:
    var f: File
    if open(f, getOutFile2(d.conf, splitFile(filename).name,
            outExt, "jsondocs"), fmWrite):
      write(f, $content)
      close(f)
    else:
      discard "fixme: error report"

proc commandDoc*(cache: IdentCache, conf: ConfigRef) =
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.hasToc = true
  generateDoc(d, ast)
  writeOutput(d, conf.projectFull, HtmlExt)
  generateIndex(d)

proc commandRstAux(cache: IdentCache, conf: ConfigRef; filename, outExt: string) =
  var filen = addFileExt(filename, "txt")
  var d = newDocumentor(filen, cache, conf)
  d.onTestSnippet = proc (d: var RstGenerator; filename, cmd: string;
                          status: int; content: string) =
    var outp: string
    if filename.len == 0:
      inc(d.id)
      let nameOnly = splitFile(d.filename).name
      let subdir = getNimcacheDir(conf) / nameOnly
      createDir(subdir)
      outp = subdir / (nameOnly & "_snippet_" & $d.id & ".nim")
    elif isAbsolute(filename):
      outp = filename
    else:
      # Nim's convention: every path is relative to the file it was written in:
      outp = splitFile(d.filename).dir / filename
    writeFile(outp, content)
    let cmd = cmd % quoteShell(outp)
    rawMessage(conf, hintExecuting, cmd)
    if execShellCmd(cmd) != status:
      rawMessage(conf, errGenerated, "executing of external program failed: " & cmd)

  d.isPureRst = true
  var rst = parseRst(readFile(filen), filen, 0, 1, d.hasToc,
                     {roSupportRawDirective}, conf)
  var modDesc = newStringOfCap(30_000)
  #d.modDesc = newMutableRope(30_000)
  renderRstToOut(d[], rst, modDesc)
  #freezeMutableRope(d.modDesc)
  d.modDesc = rope(modDesc)
  writeOutput(d, filename, outExt)
  generateIndex(d)

proc commandRst2Html*(cache: IdentCache, conf: ConfigRef) =
  commandRstAux(cache, conf, conf.projectFull, HtmlExt)

proc commandRst2TeX*(cache: IdentCache, conf: ConfigRef) =
  commandRstAux(cache, conf, conf.projectFull, TexExt)

proc commandJson*(cache: IdentCache, conf: ConfigRef) =
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.hasToc = true
  generateJson(d, ast)
  let json = d.jArray
  let content = rope(pretty(json))

  if optStdout in d.conf.globalOptions:
    writeRope(stdout, content)
  else:
    #echo getOutFile(gProjectFull, JsonExt)
    let filename = getOutFile(conf, conf.projectFull, JsonExt)
    if not writeRope(content, filename):
      rawMessage(conf, errCannotOpenFile, filename)

proc commandTags*(cache: IdentCache, conf: ConfigRef) =
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.hasToc = true
  var
    content: Rope
  generateTags(d, ast, content)

  if optStdout in d.conf.globalOptions:
    writeRope(stdout, content)
  else:
    #echo getOutFile(gProjectFull, TagsExt)
    let filename = getOutFile(conf, conf.projectFull, TagsExt)
    if not writeRope(content, filename):
      rawMessage(conf, errCannotOpenFile, filename)

proc commandBuildIndex*(cache: IdentCache, conf: ConfigRef) =
  var content = mergeIndexes(conf.projectFull).rope

  let code = ropeFormatNamedVars(conf, getConfigVar(conf, "doc.file"), ["title",
      "tableofcontents", "moduledesc", "date", "time",
      "content", "author", "version", "analytics"],
      ["Index".rope, nil, nil, rope(getDateStr()),
                   rope(getClockStr()), content, nil, nil, nil])
  # no analytics because context is not available
  let filename = getOutFile(conf, "theindex", HtmlExt)
  if not writeRope(code, filename):
    rawMessage(conf, errCannotOpenFile, filename)
