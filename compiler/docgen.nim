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
  wordrecg, syntaxes, renderer, lexer, rstast, rst, rstgen, times, highlite,
  importer, sempass2, json, xmltree, cgi, typesrenderer

type
  TSections = array[TSymKind, PRope]
  TDocumentor = object of rstgen.TRstGenerator
    modDesc: PRope           # module description
    id: int                  # for generating IDs
    toc, section: TSections
    indexValFilename: string
    analytics: string  # Google Analytics javascript, "" if doesn't exist
    seenSymbols: StringTableRef # avoids duplicate symbol generation for HTML.

  PDoc* = ref TDocumentor ## Alias to type less.

proc compilerMsgHandler(filename: string, line, col: int,
                        msgKind: rst.TMsgKind, arg: string) {.procvar.} =
  # translate msg kind:
  var k: msgs.TMsgKind
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
  globalError(newLineInfo(filename, line, col), k, arg)

proc docgenFindFile(s: string): string {.procvar.} =
  result = options.findFile(s)
  if result.len == 0:
    result = getCurrentDir() / s
    if not existsFile(result): result = ""

proc parseRst(text, filename: string,
              line, column: int, hasToc: var bool,
              rstOptions: TRstParseOptions): PRstNode =
  result = rstParse(text, filename, line, column, hasToc, rstOptions,
                    docgenFindFile, compilerMsgHandler)

proc newDocumentor*(filename: string, config: StringTableRef): PDoc =
  new(result)
  initRstGenerator(result[], (if gCmd != cmdRst2tex: outHtml else: outLatex),
                   options.gConfigVars, filename, {roSupportRawDirective},
                   docgenFindFile, compilerMsgHandler)

  if config.hasKey("doc.googleAnalytics"):
    result.analytics = """
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', '$1', 'auto');
  ga('send', 'pageview');

</script>
    """ % [config["doc.googleAnalytics"]]
  else:
    result.analytics = ""

  result.seenSymbols = newStringTable(modeCaseInsensitive)
  result.id = 100

proc dispA(dest: var PRope, xml, tex: string, args: openArray[PRope]) =
  if gCmd != cmdRst2tex: appf(dest, xml, args)
  else: appf(dest, tex, args)

proc getVarIdx(varnames: openArray[string], id: string): int =
  for i in countup(0, high(varnames)):
    if cmpIgnoreStyle(varnames[i], id) == 0:
      return i
  result = -1

proc ropeFormatNamedVars(frmt: TFormatStr, varnames: openArray[string],
                         varvalues: openArray[PRope]): PRope =
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
          j = (j * 10) + ord(frmt[i]) - ord('0')
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
        else: rawMessage(errUnknownSubstitionVar, id)
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
        else: rawMessage(errUnknownSubstitionVar, id)
      else: internalError("ropeFormatNamedVars")
    var start = i
    while i < L:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start: app(result, substr(frmt, start, i - 1))

proc genComment(d: PDoc, n: PNode): string =
  result = ""
  var dummyHasToc: bool
  if n.comment != nil and startsWith(n.comment, "##"):
    renderRstToOut(d[], parseRst(n.comment, toFilename(n.info),
                               toLinenumber(n.info), toColumn(n.info),
                               dummyHasToc, d.options + {roSkipPounds}), result)

proc genRecComment(d: PDoc, n: PNode): PRope =
  if n == nil: return nil
  result = genComment(d, n).toRope
  if result == nil:
    if n.kind notin {nkEmpty..nkNilLit}:
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
    if n.kind notin {nkEmpty..nkNilLit}:
      for i in countup(0, len(n)-1):
        result = getPlainDocstring(n.sons[i])
        if result.len > 0: return


proc findDocComment(n: PNode): PNode =
  if n == nil: return nil
  if not isNil(n.comment) and startsWith(n.comment, "##"): return n
  for i in countup(0, safeLen(n)-1):
    result = findDocComment(n.sons[i])
    if result != nil: return

proc extractDocComment*(s: PSym, d: PDoc = nil): string =
  let n = findDocComment(s.ast)
  result = ""
  if not n.isNil:
    if not d.isNil:
      var dummyHasToc: bool
      renderRstToOut(d[], parseRst(n.comment, toFilename(n.info),
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
    for i in 0.. <n.len: result.add(getName(d, n[i], splitAfter))
    result.add esc(d.target, "`")
  else:
    internalError(n.info, "getName()")
    result = ""

proc getRstName(n: PNode): PRstNode =
  case n.kind
  of nkPostfix: result = getRstName(n.sons[1])
  of nkPragmaExpr: result = getRstName(n.sons[0])
  of nkSym: result = newRstNode(rnLeaf, n.sym.renderDefinitionName)
  of nkIdent: result = newRstNode(rnLeaf, n.ident.s)
  of nkAccQuoted:
    result = getRstName(n.sons[0])
    for i in 1 .. <n.len: result.text.add(getRstName(n[i]).text)
  else:
    internalError(n.info, "getRstName()")
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
  of skProc: result.add(defaultParamSeparator)
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
    nkConverterDef: result = true
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
  assert (rstText.len < 2 or (rstText[0] == '#' and rstText[1] == '#'))
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
    nameRope = name.toRope
    plainDocstring = getPlainDocstring(n) # call here before genRecComment!
  var result: PRope = nil
  var literal, plainName = ""
  var kind = tkEof
  var comm = genRecComment(d, n)  # call this here for the side-effect!
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
  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments})
  while true:
    getNextTok(r, kind, literal)
    case kind
    of tkEof:
      break
    of tkComment:
      dispA(result, "<span class=\"Comment\">$1</span>", "\\spanComment{$1}",
            [toRope(esc(d.target, literal))])
    of tokKeywordLow..tokKeywordHigh:
      dispA(result, "<span class=\"Keyword\">$1</span>", "\\spanKeyword{$1}",
            [toRope(literal)])
    of tkOpr:
      dispA(result, "<span class=\"Operator\">$1</span>", "\\spanOperator{$1}",
            [toRope(esc(d.target, literal))])
    of tkStrLit..tkTripleStrLit:
      dispA(result, "<span class=\"StringLit\">$1</span>",
            "\\spanStringLit{$1}", [toRope(esc(d.target, literal))])
    of tkCharLit:
      dispA(result, "<span class=\"CharLit\">$1</span>", "\\spanCharLit{$1}",
            [toRope(esc(d.target, literal))])
    of tkIntLit..tkUInt64Lit:
      dispA(result, "<span class=\"DecNumber\">$1</span>",
            "\\spanDecNumber{$1}", [toRope(esc(d.target, literal))])
    of tkFloatLit..tkFloat128Lit:
      dispA(result, "<span class=\"FloatNumber\">$1</span>",
            "\\spanFloatNumber{$1}", [toRope(esc(d.target, literal))])
    of tkSymbol:
      dispA(result, "<span class=\"Identifier\">$1</span>",
            "\\spanIdentifier{$1}", [toRope(esc(d.target, literal))])
    of tkSpaces, tkInvalid:
      app(result, literal)
    of tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi,
       tkBracketDotLe, tkBracketDotRi, tkCurlyDotLe, tkCurlyDotRi, tkParDotLe,
       tkParDotRi, tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot,
       tkAccent, tkColonColon,
       tkGStrLit, tkGTripleStrLit, tkInfixOpr, tkPrefixOpr, tkPostfixOpr:
      dispA(result, "<span class=\"Other\">$1</span>", "\\spanOther{$1}",
            [toRope(esc(d.target, literal))])
  inc(d.id)
  let
    plainNameRope = toRope(xmltree.escape(plainName.strip))
    cleanPlainSymbol = renderPlainSymbolName(nameNode)
    complexSymbol = complexName(k, n, cleanPlainSymbol)
    plainSymbolRope = toRope(cleanPlainSymbol)
    plainSymbolEncRope = toRope(encodeUrl(cleanPlainSymbol))
    itemIDRope = toRope(d.id)
    symbolOrId = d.newUniquePlainSymbol(complexSymbol)
    symbolOrIdRope = symbolOrId.toRope
    symbolOrIdEncRope = encodeUrl(symbolOrId).toRope

  var seeSrcRope: PRope = nil
  let docItemSeeSrc = getConfigVar("doc.item.seesrc")
  if docItemSeeSrc.len > 0 and options.docSeeSrcUrl.len > 0:
    # XXX toFilename doesn't really work. We need to ensure that this keeps
    # returning a relative path.
    let urlRope = ropeFormatNamedVars(options.docSeeSrcUrl,
      ["path", "line"], [n.info.toFilename.toRope, toRope($n.info.line)])
    dispA(seeSrcRope, "$1", "", [ropeFormatNamedVars(docItemSeeSrc,
        ["path", "line", "url"], [n.info.toFilename.toRope,
        toRope($n.info.line), urlRope])])

  app(d.section[k], ropeFormatNamedVars(getConfigVar("doc.item"),
    ["name", "header", "desc", "itemID", "header_plain", "itemSym",
      "itemSymOrID", "itemSymEnc", "itemSymOrIDEnc", "seeSrc"],
    [nameRope, result, comm, itemIDRope, plainNameRope, plainSymbolRope,
      symbolOrIdRope, plainSymbolEncRope, symbolOrIdEncRope, seeSrcRope]))
  app(d.toc[k], ropeFormatNamedVars(getConfigVar("doc.item.toc"),
    ["name", "header", "desc", "itemID", "header_plain", "itemSym",
      "itemSymOrID", "itemSymEnc", "itemSymOrIDEnc"],
    [toRope(getName(d, nameNode, d.splitAfter)), result, comm,
      itemIDRope, plainNameRope, plainSymbolRope, symbolOrIdRope,
      plainSymbolEncRope, symbolOrIdEncRope]))

  # Ironically for types the complexSymbol is *cleaner* than the plainName
  # because it doesn't include object fields or documentation comments. So we
  # use the plain one for callable elements, and the complex for the rest.
  var linkTitle = changeFileExt(extractFilename(d.filename), "") & " : "
  if n.isCallable: linkTitle.add(xmltree.escape(plainName.strip))
  else: linkTitle.add(xmltree.escape(complexSymbol.strip))

  setIndexTerm(d[], symbolOrId, name, linkTitle,
    xmltree.escape(plainDocstring.docstringSummary))

proc genJSONItem(d: PDoc, n, nameNode: PNode, k: TSymKind): JsonNode =
  if not isVisible(nameNode): return
  var
    name = getName(d, nameNode)
    comm = genRecComment(d, n).ropeToStr()
    r: TSrcGen

  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments})

  result = %{ "name": %name, "type": %($k) }

  if comm != nil and comm != "":
    result["description"] = %comm
  if r.buf != nil:
    result["code"] = %r.buf

proc checkForFalse(n: PNode): bool =
  result = n.kind == nkIdent and identEq(n.ident, "false")

proc traceDeps(d: PDoc, n: PNode) =
  const k = skModule
  if d.section[k] != nil: app(d.section[k], ", ")
  dispA(d.section[k],
        "<a class=\"reference external\" href=\"$1.html\">$1</a>",
        "$1", [toRope(getModuleName(n))])

proc generateDoc*(d: PDoc, n: PNode) =
  case n.kind
  of nkCommentStmt: app(d.modDesc, genComment(d, n))
  of nkProcDef:
    when useEffectSystem: documentRaises(n)
    genItem(d, n, n.sons[namePos], skProc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(n)
    genItem(d, n, n.sons[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(n)
    genItem(d, n, n.sons[namePos], skIterator)
  of nkMacroDef: genItem(d, n, n.sons[namePos], skMacro)
  of nkTemplateDef: genItem(d, n, n.sons[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(n)
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

proc generateJson(d: PDoc, n: PNode, jArray: JsonNode = nil): JsonNode =
  case n.kind
  of nkCommentStmt:
    if n.comment != nil and startsWith(n.comment, "##"):
      let stripped = n.comment.substr(2).strip
      result = %{ "comment": %stripped }
  of nkProcDef:
    when useEffectSystem: documentRaises(n)
    result = genJSONItem(d, n, n.sons[namePos], skProc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(n)
    result = genJSONItem(d, n, n.sons[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(n)
    result = genJSONItem(d, n, n.sons[namePos], skIterator)
  of nkMacroDef:
    result = genJSONItem(d, n, n.sons[namePos], skMacro)
  of nkTemplateDef:
    result = genJSONItem(d, n, n.sons[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(n)
    result = genJSONItem(d, n, n.sons[namePos], skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1):
      if n.sons[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        result = genJSONItem(d, n.sons[i], n.sons[i].sons[0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)))
  of nkStmtList:
    result = if jArray != nil: jArray else: newJArray()

    for i in countup(0, sonsLen(n) - 1):
      var r = generateJson(d, n.sons[i], result)
      if r != nil:
        result.add(r)

  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n.sons[0].sons[0]) and jArray != nil:
      discard generateJson(d, lastSon(n.sons[0]), jArray)
  else: discard

proc genSection(d: PDoc, kind: TSymKind) =
  const sectionNames: array[skModule..skTemplate, string] = [
    "Imports", "Types", "Vars", "Lets", "Consts", "Vars", "Procs", "Methods",
    "Iterators", "Iterators", "Converters", "Macros", "Templates"
  ]
  if d.section[kind] == nil: return
  var title = sectionNames[kind].toRope
  d.section[kind] = ropeFormatNamedVars(getConfigVar("doc.section"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      ord(kind).toRope, title, toRope(ord(kind) + 50), d.section[kind]])
  d.toc[kind] = ropeFormatNamedVars(getConfigVar("doc.section.toc"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      ord(kind).toRope, title, toRope(ord(kind) + 50), d.toc[kind]])

proc genOutFile(d: PDoc): PRope =
  var
    code, content: PRope
    title = ""
  var j = 0
  var tmp = ""
  renderTocEntries(d[], j, 1, tmp)
  var toc = tmp.toRope
  for i in countup(low(TSymKind), high(TSymKind)):
    genSection(d, i)
    app(toc, d.toc[i])
  if toc != nil:
    toc = ropeFormatNamedVars(getConfigVar("doc.toc"), ["content"], [toc])
  for i in countup(low(TSymKind), high(TSymKind)): app(code, d.section[i])

  # Extract the title. Non API modules generate an entry in the index table.
  if d.meta[metaTitle].len != 0:
    title = d.meta[metaTitle]
    setIndexTerm(d[], "", title)
  else:
    # Modules get an automatic title for the HTML, but no entry in the index.
    title = "Module " & extractFilename(changeFileExt(d.filename, ""))

  let bodyname = if d.hasToc: "doc.body_toc" else: "doc.body_no_toc"
  content = ropeFormatNamedVars(getConfigVar(bodyname), ["title",
      "tableofcontents", "moduledesc", "date", "time", "content"],
      [title.toRope, toc, d.modDesc, toRope(getDateStr()),
      toRope(getClockStr()), code])
  if optCompileOnly notin gGlobalOptions:
    # XXX what is this hack doing here? 'optCompileOnly' means raw output!?
    code = ropeFormatNamedVars(getConfigVar("doc.file"), ["title",
        "tableofcontents", "moduledesc", "date", "time",
        "content", "author", "version", "analytics"],
        [title.toRope, toc, d.modDesc, toRope(getDateStr()),
                     toRope(getClockStr()), content, d.meta[metaAuthor].toRope,
                     d.meta[metaVersion].toRope, d.analytics.toRope])
  else:
    code = content
  result = code

proc generateIndex*(d: PDoc) =
  if optGenIndex in gGlobalOptions:
    writeIndexFile(d[], splitFile(options.outFile).dir /
                        splitFile(d.filename).name & IndexExt)

proc writeOutput*(d: PDoc, filename, outExt: string, useWarning = false) =
  var content = genOutFile(d)
  if optStdout in gGlobalOptions:
    writeRope(stdout, content)
  else:
    writeRope(content, getOutFile(filename, outExt), useWarning)

proc commandDoc*() =
  var ast = parseFile(gProjectMainIdx)
  if ast == nil: return
  var d = newDocumentor(gProjectFull, options.gConfigVars)
  d.hasToc = true
  generateDoc(d, ast)
  writeOutput(d, gProjectFull, HtmlExt)
  generateIndex(d)

proc commandRstAux(filename, outExt: string) =
  var filen = addFileExt(filename, "txt")
  var d = newDocumentor(filen, options.gConfigVars)
  var rst = parseRst(readFile(filen), filen, 0, 1, d.hasToc,
                     {roSupportRawDirective})
  var modDesc = newStringOfCap(30_000)
  #d.modDesc = newMutableRope(30_000)
  renderRstToOut(d[], rst, modDesc)
  #freezeMutableRope(d.modDesc)
  d.modDesc = toRope(modDesc)
  writeOutput(d, filename, outExt)
  generateIndex(d)

proc commandRst2Html*() =
  commandRstAux(gProjectFull, HtmlExt)

proc commandRst2TeX*() =
  splitter = "\\-"
  commandRstAux(gProjectFull, TexExt)

proc commandJSON*() =
  var ast = parseFile(gProjectMainIdx)
  if ast == nil: return
  var d = newDocumentor(gProjectFull, options.gConfigVars)
  d.hasToc = true
  var json = generateJson(d, ast)
  var content = newRope(pretty(json))

  if optStdout in gGlobalOptions:
    writeRope(stdout, content)
  else:
    echo getOutFile(gProjectFull, JsonExt)
    writeRope(content, getOutFile(gProjectFull, JsonExt), useWarning = false)

proc commandBuildIndex*() =
  var content = mergeIndexes(gProjectFull).toRope

  let code = ropeFormatNamedVars(getConfigVar("doc.file"), ["title",
      "tableofcontents", "moduledesc", "date", "time",
      "content", "author", "version", "analytics"],
      ["Index".toRope, nil, nil, toRope(getDateStr()),
                   toRope(getClockStr()), content, nil, nil, nil])
  # no analytics because context is not available
  writeRope(code, getOutFile("theindex", HtmlExt))
