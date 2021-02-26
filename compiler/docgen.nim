#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This is the documentation generator. Cross-references are generated
# by knowing how the anchors are going to be named.

import
  ast, strutils, strtabs, options, msgs, os, ropes, idents,
  wordrecg, syntaxes, renderer, lexer, packages/docutils/rstast,
  packages/docutils/rst, packages/docutils/rstgen,
  json, xmltree, trees, types,
  typesrenderer, astalgo, lineinfos, intsets,
  pathutils, trees, tables, nimpaths, renderverbatim, osproc

from uri import encodeUrl
from std/private/globs import nativeToUnixPath


const
  exportSection = skField
  docCmdSkip = "skip"

type
  TSections = array[TSymKind, Rope]
  ExampleGroup = ref object
    ## a group of runnableExamples with same rdoccmd
    rdoccmd: string ## from 1st arg in `runnableExamples(rdoccmd): body`
    docCmd: string ## from user config, e.g. --doccmd:-d:foo
    code: string ## contains imports; each import contains `body`
    index: int ## group index
  TDocumentor = object of rstgen.RstGenerator
    modDesc: Rope       # module description
    module: PSym
    modDeprecationMsg: Rope
    toc, toc2, section: TSections
    tocTable: array[TSymKind, Table[string, Rope]]
    indexValFilename: string
    analytics: string  # Google Analytics javascript, "" if doesn't exist
    seenSymbols: StringTableRef # avoids duplicate symbol generation for HTML.
    jArray: JsonNode
    types: TStrTable
    isPureRst: bool
    conf*: ConfigRef
    cache*: IdentCache
    exampleCounter: int
    emitted: IntSet # we need to track which symbols have been emitted
                    # already. See bug #3655
    thisDir*: AbsoluteDir
    exampleGroups: OrderedTable[string, ExampleGroup]
    wroteSupportFiles*: bool

  PDoc* = ref TDocumentor ## Alias to type less.

proc prettyString(a: object): string =
  # xxx pending std/prettyprint refs https://github.com/nim-lang/RFCs/issues/203#issuecomment-602534906
  for k, v in fieldPairs(a):
    result.add k & ": " & $v & "\n"

proc presentationPath*(conf: ConfigRef, file: AbsoluteFile, isTitle = false): RelativeFile =
  ## returns a relative file that will be appended to outDir
  let file2 = $file
  template bail() =
    result = relativeTo(file, conf.projectPath)
  proc nimbleDir(): AbsoluteDir =
    getNimbleFile(conf, file2).parentDir.AbsoluteDir
  case conf.docRoot:
  of docRootDefault:
    result = getRelativePathFromConfigPath(conf, file)
    let dir = nimbleDir()
    if not dir.isEmpty:
      let result2 = relativeTo(file, dir)
      if not result2.isEmpty and (result.isEmpty or result2.string.len < result.string.len):
        result = result2
    if result.isEmpty: bail()
  of "@pkg":
    let dir = nimbleDir()
    if dir.isEmpty: bail()
    else: result = relativeTo(file, dir)
  of "@path":
    result = getRelativePathFromConfigPath(conf, file)
    if result.isEmpty: bail()
  elif conf.docRoot.len > 0:
    # we're (currently) requiring `isAbsolute` to avoid confusion when passing
    # a relative path (would it be relative wrt $PWD or to projectfile)
    conf.globalAssert conf.docRoot.isAbsolute, arg=conf.docRoot
    conf.globalAssert conf.docRoot.dirExists, arg=conf.docRoot
    # needed because `canonicalizePath` called on `file`
    result = file.relativeTo conf.docRoot.expandFilename.AbsoluteDir
  else:
    bail()
  if isAbsolute(result.string):
    result = file.string.splitPath()[1].RelativeFile
  if isTitle:
    result = result.string.nativeToUnixPath.RelativeFile
  else:
    result = result.string.replace("..", dotdotMangle).RelativeFile
  doAssert not result.isEmpty
  doAssert not isAbsolute(result.string)

proc whichType(d: PDoc; n: PNode): PSym =
  if n.kind == nkSym:
    if d.types.strTableContains(n.sym):
      result = n.sym
  else:
    for i in 0..<n.safeLen:
      let x = whichType(d, n[i])
      if x != nil: return x

proc attachToType(d: PDoc; p: PSym): PSym =
  let params = p.ast[paramsPos]
  template check(i) =
    result = whichType(d, params[i])
    if result != nil: return result

  # first check the first parameter, then the return type,
  # then the other parameter:
  if params.len > 1: check(1)
  if params.len > 0: check(0)
  for i in 2..<params.len: check(i)

template declareClosures =
  proc compilerMsgHandler(filename: string, line, col: int,
                          msgKind: rst.MsgKind, arg: string) {.gcsafe.} =
    # translate msg kind:
    var k: TMsgKind
    case msgKind
    of meCannotOpenFile: k = errCannotOpenFile
    of meExpected: k = errXExpected
    of meGridTableNotImplemented: k = errGridTableNotImplemented
    of meMarkdownIllformedTable: k = errMarkdownIllformedTable
    of meNewSectionExpected: k = errNewSectionExpected
    of meGeneralParseError: k = errGeneralParseError
    of meInvalidDirective: k = errInvalidDirectiveX
    of meFootnoteMismatch: k = errFootnoteMismatch
    of mwRedefinitionOfLabel: k = warnRedefinitionOfLabel
    of mwUnknownSubstitution: k = warnUnknownSubstitutionX
    of mwUnsupportedLanguage: k = warnLanguageXNotSupported
    of mwUnsupportedField: k = warnFieldXNotSupported
    of mwRstStyle: k = warnRstStyle
    {.gcsafe.}:
      globalError(conf, newLineInfo(conf, AbsoluteFile filename, line, col), k, arg)

  proc docgenFindFile(s: string): string {.gcsafe.} =
    result = options.findFile(conf, s).string
    if result.len == 0:
      result = getCurrentDir() / s
      if not fileExists(result): result = ""

proc parseRst(text, filename: string,
              line, column: int, hasToc: var bool,
              rstOptions: RstParseOptions;
              conf: ConfigRef): PRstNode =
  declareClosures()
  result = rstParse(text, filename, line, column, hasToc, rstOptions,
                    docgenFindFile, compilerMsgHandler)

proc getOutFile2(conf: ConfigRef; filename: RelativeFile,
                 ext: string, guessTarget: bool): AbsoluteFile =
  if optWholeProject in conf.globalOptions or guessTarget:
    let d = conf.outDir
    createDir(d)
    result = d / changeFileExt(filename, ext)
  elif not conf.outFile.isEmpty:
    result = absOutFile(conf)
  else:
    result = getOutFile(conf, filename, ext)

proc newDocumentor*(filename: AbsoluteFile; cache: IdentCache; conf: ConfigRef, outExt: string = HtmlExt, module: PSym = nil): PDoc =
  declareClosures()
  new(result)
  result.module = module
  result.conf = conf
  result.cache = cache
  result.outDir = conf.outDir.string
  initRstGenerator(result[], (if conf.cmd != cmdRst2tex: outHtml else: outLatex),
                   conf.configVars, filename.string, {roSupportRawDirective, roSupportMarkdown},
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
  result.onTestSnippet =
    proc (gen: var RstGenerator; filename, cmd: string; status: int; content: string) =
      if conf.docCmd == docCmdSkip: return
      inc(gen.id)
      var d = TDocumentor(gen)
      var outp: AbsoluteFile
      if filename.len == 0:
        let nameOnly = splitFile(d.filename).name
        # "snippets" needed, refs bug #17183
        outp = getNimcacheDir(conf) / "snippets".RelativeDir / RelativeDir(nameOnly) /
               RelativeFile(nameOnly & "_snippet_" & $d.id & ".nim")
      elif isAbsolute(filename):
        outp = AbsoluteFile(filename)
      else:
        # Nim's convention: every path is relative to the file it was written in:
        let nameOnly = splitFile(d.filename).name
        outp = AbsoluteDir(nameOnly) / RelativeFile(filename)
      # Make sure the destination directory exists
      createDir(outp.splitFile.dir)
      # Include the current file if we're parsing a nim file
      let importStmt = if d.isPureRst: "" else: "import \"$1\"\n" % [d.filename.replace("\\", "/")]
      writeFile(outp, importStmt & content)

      proc interpSnippetCmd(cmd: string): string =
        # backward compatibility hacks; interpolation commands should explicitly use `$`
        if cmd.startsWith "nim ": result = "$nim " & cmd[4..^1]
        else: result = cmd
        # factor with D20210224T221756
        result = result.replace("$1", "$options") % [
          "nim", os.getAppFilename().quoteShell,
          "libpath", quoteShell(d.conf.libpath),
          "docCmd", d.conf.docCmd,
          "backend", $d.conf.backend,
          "options", outp.quoteShell,
            # xxx `quoteShell` seems buggy if user passes options = "-d:foo somefile.nim"
        ]
      let cmd = cmd.interpSnippetCmd
      rawMessage(conf, hintExecuting, cmd)
      let (output, gotten) = execCmdEx(cmd)
      if gotten != status:
        rawMessage(conf, errGenerated, "snippet failed: cmd: '$1' status: $2 expected: $3 output: $4" % [cmd, $gotten, $status, output])
  result.emitted = initIntSet()
  result.destFile = getOutFile2(conf, presentationPath(conf, filename), outExt, false).string
  result.thisDir = result.destFile.AbsoluteFile.splitFile.dir

template dispA(conf: ConfigRef; dest: var Rope, xml, tex: string, args: openArray[Rope]) =
  if conf.cmd != cmdRst2tex: dest.addf(xml, args)
  else: dest.addf(tex, args)

proc getVarIdx(varnames: openArray[string], id: string): int =
  for i in 0..high(varnames):
    if cmpIgnoreStyle(varnames[i], id) == 0:
      return i
  result = -1

proc ropeFormatNamedVars(conf: ConfigRef; frmt: FormatStr,
                         varnames: openArray[string],
                         varvalues: openArray[Rope]): Rope =
  var i = 0
  result = nil
  var num = 0
  while i < frmt.len:
    if frmt[i] == '$':
      inc(i)                  # skip '$'
      case frmt[i]
      of '#':
        result.add(varvalues[num])
        inc(num)
        inc(i)
      of '$':
        result.add("$")
        inc(i)
      of '0'..'9':
        var j = 0
        while true:
          j = (j * 10) + ord(frmt[i]) - ord('0')
          inc(i)
          if (i > frmt.len + 0 - 1) or not (frmt[i] in {'0'..'9'}): break
        if j > high(varvalues) + 1:
          rawMessage(conf, errGenerated, "Invalid format string; too many $s: " & frmt)
        num = j
        result.add(varvalues[j - 1])
      of 'A'..'Z', 'a'..'z', '\x80'..'\xFF':
        var id = ""
        while true:
          id.add(frmt[i])
          inc(i)
          if not (frmt[i] in {'A'..'Z', '_', 'a'..'z', '\x80'..'\xFF'}): break
        var idx = getVarIdx(varnames, id)
        if idx >= 0: result.add(varvalues[idx])
        else: rawMessage(conf, errGenerated, "unknown substition variable: " & id)
      of '{':
        var id = ""
        inc(i)
        while i < frmt.len and frmt[i] != '}':
          id.add(frmt[i])
          inc(i)
        if i >= frmt.len:
          rawMessage(conf, errGenerated, "expected closing '}'")
        else:
          inc(i)                # skip }
        # search for the variable:
        let idx = getVarIdx(varnames, id)
        if idx >= 0: result.add(varvalues[idx])
        else: rawMessage(conf, errGenerated, "unknown substition variable: " & id)
      else:
        result.add("$")
    var start = i
    while i < frmt.len:
      if frmt[i] != '$': inc(i)
      else: break
    if i - 1 >= start: result.add(substr(frmt, start, i - 1))

proc genComment(d: PDoc, n: PNode): string =
  result = ""
  if n.comment.len > 0:
    let comment = n.comment
    when false:
      # RFC: to preseve newlines in comments, this would work:
      comment = comment.replace("\n", "\n\n")
    renderRstToOut(d[], parseRst(comment, toFullPath(d.conf, n.info), toLinenumber(n.info),
                   toColumn(n.info), (var dummy: bool; dummy), d.options, d.conf), result)

proc genRecCommentAux(d: PDoc, n: PNode): Rope =
  if n == nil: return nil
  result = genComment(d, n).rope
  if result == nil:
    if n.kind in {nkStmtList, nkStmtListExpr, nkTypeDef, nkConstDef,
                  nkObjectTy, nkRefTy, nkPtrTy, nkAsgn, nkFastAsgn, nkHiddenStdConv}:
      # notin {nkEmpty..nkNilLit, nkEnumTy, nkTupleTy}:
      for i in 0..<n.len:
        result = genRecCommentAux(d, n[i])
        if result != nil: return
  else:
    n.comment = ""

proc genRecComment(d: PDoc, n: PNode): Rope =
  if n == nil: return nil
  result = genComment(d, n).rope
  if result == nil:
    if n.kind in {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef,
                  nkMacroDef, nkTemplateDef, nkConverterDef}:
      result = genRecCommentAux(d, n[bodyPos])
    else:
      result = genRecCommentAux(d, n)

proc getPlainDocstring(n: PNode): string =
  ## Gets the plain text docstring of a node non destructively.
  ##
  ## You need to call this before genRecComment, whose side effects are removal
  ## of comments from the tree. The proc will recursively scan and return all
  ## the concatenated ``##`` comments of the node.
  if n == nil: result = ""
  elif startsWith(n.comment, "##"):
    result = n.comment
  else:
    for i in 0..<n.safeLen:
      result = getPlainDocstring(n[i])
      if result.len > 0: return

proc belongsToPackage(conf: ConfigRef; module: PSym): bool =
  result = module.kind == skModule and module.getnimblePkgId == conf.mainPackageId

proc externalDep(d: PDoc; module: PSym): string =
  if optWholeProject in d.conf.globalOptions or d.conf.docRoot.len > 0:
    let full = AbsoluteFile toFullPath(d.conf, FileIndex module.position)
    let tmp = getOutFile2(d.conf, presentationPath(d.conf, full), HtmlExt, sfMainModule notin module.flags)
    result = relativeTo(tmp, d.thisDir, '/').string
  else:
    result = extractFilename toFullPath(d.conf, FileIndex module.position)

proc nodeToHighlightedHtml(d: PDoc; n: PNode; result: var Rope; renderFlags: TRenderFlags = {};
                           procLink: Rope) =
  var r: TSrcGen
  var literal = ""
  initTokRender(r, n, renderFlags)
  var kind = tkEof
  var tokenPos = 0
  var procTokenPos = 0
  template escLit(): untyped = rope(esc(d.target, literal))
  while true:
    getNextTok(r, kind, literal)
    inc tokenPos
    case kind
    of tkEof:
      break
    of tkComment:
      dispA(d.conf, result, "<span class=\"Comment\">$1</span>", "\\spanComment{$1}",
            [escLit])
    of tokKeywordLow..tokKeywordHigh:
      if kind in {tkProc, tkMethod, tkIterator, tkMacro, tkTemplate, tkFunc, tkConverter}:
        procTokenPos = tokenPos
      dispA(d.conf, result, "<span class=\"Keyword\">$1</span>", "\\spanKeyword{$1}",
            [rope(literal)])
    of tkOpr:
      dispA(d.conf, result, "<span class=\"Operator\">$1</span>", "\\spanOperator{$1}",
            [escLit])
    of tkStrLit..tkTripleStrLit:
      dispA(d.conf, result, "<span class=\"StringLit\">$1</span>",
            "\\spanStringLit{$1}", [escLit])
    of tkCharLit:
      dispA(d.conf, result, "<span class=\"CharLit\">$1</span>", "\\spanCharLit{$1}",
            [escLit])
    of tkIntLit..tkUInt64Lit:
      dispA(d.conf, result, "<span class=\"DecNumber\">$1</span>",
            "\\spanDecNumber{$1}", [escLit])
    of tkFloatLit..tkFloat128Lit:
      dispA(d.conf, result, "<span class=\"FloatNumber\">$1</span>",
            "\\spanFloatNumber{$1}", [escLit])
    of tkSymbol:
      let s = getTokSym(r)
      # -2 because of the whitespace in between:
      if procTokenPos == tokenPos-2 and procLink != nil:
        dispA(d.conf, result, "<a href=\"#$2\"><span class=\"Identifier\">$1</span></a>",
              "\\spanIdentifier{$1}", [escLit, procLink])
      elif s != nil and s.kind in {skType, skVar, skLet, skConst} and
           sfExported in s.flags and s.owner != nil and
           belongsToPackage(d.conf, s.owner) and d.target == outHtml:
        let external = externalDep(d, s.owner)
        result.addf "<a href=\"$1#$2\"><span class=\"Identifier\">$3</span></a>",
          [rope changeFileExt(external, "html"), rope literal,
           escLit]
      else:
        dispA(d.conf, result, "<span class=\"Identifier\">$1</span>",
              "\\spanIdentifier{$1}", [escLit])
    of tkSpaces, tkInvalid:
      result.add(literal)
    of tkCurlyDotLe:
      template fun(s) = dispA(d.conf, result, s, "\\spanOther{$1}", [escLit])
      if renderRunnableExamples in renderFlags: fun "$1"
      else: fun: "<span>" & # This span is required for the JS to work properly
        """<span class="Other">{</span><span class="Other pragmadots">...</span><span class="Other">}</span>
</span>
<span class="pragmawrap">
<span class="Other">$1</span>
<span class="pragma">""".replace("\n", "")  # Must remove newlines because wrapped in a <pre>
    of tkCurlyDotRi:
      template fun(s) = dispA(d.conf, result, s, "\\spanOther{$1}", [escLit])
      if renderRunnableExamples in renderFlags: fun "$1"
      else: fun """
</span>
<span class="Other">$1</span>
</span>""".replace("\n", "")
    of tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi,
       tkBracketDotLe, tkBracketDotRi, tkParDotLe,
       tkParDotRi, tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot,
       tkAccent, tkColonColon,
       tkGStrLit, tkGTripleStrLit, tkInfixOpr, tkPrefixOpr, tkPostfixOpr,
       tkBracketLeColon:
      dispA(d.conf, result, "<span class=\"Other\">$1</span>", "\\spanOther{$1}",
            [escLit])

proc exampleOutputDir(d: PDoc): AbsoluteDir = d.conf.getNimcacheDir / RelativeDir"runnableExamples"

proc writeExample(d: PDoc; ex: PNode, rdoccmd: string) =
  if d.conf.errorCounter > 0: return
  let outputDir = d.exampleOutputDir
  createDir(outputDir)
  inc d.exampleCounter
  let outp = outputDir / RelativeFile(extractFilename(d.filename.changeFileExt"" &
      "_examples" & $d.exampleCounter & ".nim"))
  #let nimcache = outp.changeFileExt"" & "_nimcache"
  renderModule(ex, d.filename, outp.string, conf = d.conf)
  if rdoccmd notin d.exampleGroups: d.exampleGroups[rdoccmd] = ExampleGroup(rdoccmd: rdoccmd, docCmd: d.conf.docCmd, index: d.exampleGroups.len)
  d.exampleGroups[rdoccmd].code.add "import r\"$1\"\n" % outp.string

proc runAllExamples(d: PDoc) =
  # This used to be: `let backend = if isDefined(d.conf, "js"): "js"` (etc), however
  # using `-d:js` (etc) cannot work properly, e.g. would fail with `importjs`
  # since semantics are affected by `config.backend`, not by isDefined(d.conf, "js")
  let outputDir = d.exampleOutputDir
  for _, group in d.exampleGroups:
    if group.docCmd == docCmdSkip: continue
    let outp = outputDir / RelativeFile("$1_group$2_examples.nim" % [d.filename.splitFile.name, $group.index])
    group.code = "# autogenerated by docgen\n# source: $1\n# rdoccmd: $2\n$3" % [d.filename, group.rdoccmd, group.code]
    writeFile(outp, group.code)
    # most useful semantics is that `docCmd` comes after `rdoccmd`, so that we can (temporarily) override
    # via command line
    # D20210224T221756:here
    let cmd = "$nim $backend -r --lib:$libpath --warning:UnusedImport:off --path:$path --nimcache:$nimcache $rdoccmd $docCmd $file" % [
      "nim", quoteShell(os.getAppFilename()),
      "backend", $d.conf.backend,
      "path", quoteShell(d.conf.projectPath),
      "libpath", quoteShell(d.conf.libpath),
      "nimcache", quoteShell(outputDir),
      "file", quoteShell(outp),
      "rdoccmd", group.rdoccmd,
      "docCmd", group.docCmd,
    ]
    if os.execShellCmd(cmd) != 0:
      quit "[runnableExamples] failed: generated file: '$1' group: '$2' cmd: $3" % [outp.string, group[].prettyString, cmd]
    else:
      # keep generated source file `outp` to allow inspection.
      rawMessage(d.conf, hintSuccess, ["runnableExamples: " & outp.string])
      # removeFile(outp.changeFileExt(ExeExt)) # it's in nimcache, no need to remove

proc prepareExample(d: PDoc; n: PNode): tuple[rdoccmd: string, code: string] =
  ## returns `rdoccmd` and source code for this runnableExamples
  var rdoccmd = ""
  if n.len < 2 or n.len > 3: globalError(d.conf, n.info, "runnableExamples invalid")
  if n.len == 3:
    let n1 = n[1]
    # xxx this should be evaluated during sempass
    if n1.kind notin nkStrKinds: globalError(d.conf, n1.info, "string litteral expected")
    rdoccmd = n1.strVal

  var docComment = newTree(nkCommentStmt)
  let loc = d.conf.toFileLineCol(n.info)

  docComment.comment = "autogenerated by docgen\nloc: $1\nrdoccmd: $2" % [loc, rdoccmd]
  var runnableExamples = newTree(nkStmtList,
      docComment,
      newTree(nkImportStmt, newStrNode(nkStrLit, d.filename)))
  runnableExamples.info = n.info
  let ret = extractRunnableExamplesSource(d.conf, n)
  for a in n.lastSon: runnableExamples.add a
  # we could also use `ret` instead here, to keep sources verbatim
  writeExample(d, runnableExamples, rdoccmd)
  result = (rdoccmd, ret)
  when false:
    proc extractImports(n: PNode; result: PNode) =
      if n.kind in {nkImportStmt, nkImportExceptStmt, nkFromStmt}:
        result.add copyTree(n)
        n.kind = nkEmpty
        return
      for i in 0..<n.safeLen: extractImports(n[i], result)
    let imports = newTree(nkStmtList)
    var savedLastSon = copyTree n.lastSon
    extractImports(savedLastSon, imports)
    for imp in imports: runnableExamples.add imp
    runnableExamples.add newTree(nkBlockStmt, newNode(nkEmpty), copyTree savedLastSon)

type RunnableState = enum
  rsStart
  rsComment
  rsRunnable
  rsDone

proc getAllRunnableExamplesImpl(d: PDoc; n: PNode, dest: var Rope, state: RunnableState): RunnableState =
  ##[
  Simple state machine to tell whether we render runnableExamples and doc comments.
  This is to ensure that we can interleave runnableExamples and doc comments freely;
  the logic is easy to change but currently a doc comment following another doc comment
  will not render, to avoid rendering in following case:

  proc fn* =
    runnableExamples: discard
    ## d1
    runnableExamples: discard
    ## d2

    ## internal explanation  # <- this one should be out; it's part of rest of function body and would likey not make sense in doc comment
    discard # some code
  ]##

  case n.kind
  of nkCommentStmt:
    if state in {rsStart, rsRunnable}:
      dest.add genRecComment(d, n)
      return rsComment
  of nkCallKinds:
    if isRunnableExamples(n[0]) and
        n.len >= 2 and n.lastSon.kind == nkStmtList and state in {rsStart, rsComment, rsRunnable}:
      let (rdoccmd, code) = prepareExample(d, n)
      var msg = "Example:"
      if rdoccmd.len > 0: msg.add " cmd: " & rdoccmd
      dispA(d.conf, dest, "\n<p><strong class=\"examples_text\">$1</strong></p>\n",
          "\n\\textbf{$1}\n", [msg.rope])
      inc d.listingCounter
      let id = $d.listingCounter
      dest.add(d.config.getOrDefault"doc.listing_start" % [id, "langNim", ""])
      var dest2 = ""
      renderNimCode(dest2, code, isLatex = d.conf.cmd == cmdRst2tex)
      dest.add dest2
      dest.add(d.config.getOrDefault"doc.listing_end" % id)
      return rsRunnable
  else: discard
  return rsDone
    # change this to `rsStart` if you want to keep generating doc comments
    # and runnableExamples that occur after some code in routine

proc getRoutineBody(n: PNode): PNode =
  ##[
  nim transforms these quite differently:

  proc someType*(): int =
    ## foo
    result = 3
=>
  result =
    ## foo
    3;

  proc someType*(): int =
    ## foo
    3
=>
  ## foo
  result = 3;

  so we normalize the results to get to the statement list containing the
  (0 or more) doc comments and runnableExamples.
  ]##
  result = n[bodyPos]

  # This won't be transformed: result.id = 10. Namely result[0].kind != nkSym.
  if result.kind == nkAsgn and result[0].kind == nkSym and
                               n.len > bodyPos+1 and n[bodyPos+1].kind == nkSym:
    doAssert result.len == 2
    result = result[1]

proc getAllRunnableExamples(d: PDoc, n: PNode, dest: var Rope) =
  var n = n
  var state = rsStart
  template fn(n2) =
    state = getAllRunnableExamplesImpl(d, n2, dest, state)
  dest.add genComment(d, n).rope
  case n.kind
  of routineDefs:
    n = n.getRoutineBody
    case n.kind
    of nkCommentStmt, nkCallKinds: fn(n)
    else:
      for i in 0..<n.safeLen:
        fn(n[i])
        if state == rsDone: return
  else: fn(n)

proc isVisible(d: PDoc; n: PNode): bool =
  result = false
  if n.kind == nkPostfix:
    if n.len == 2 and n[0].kind == nkIdent:
      var v = n[0].ident
      result = v.id == ord(wStar) or v.id == ord(wMinus)
  elif n.kind == nkSym:
    # we cannot generate code for forwarded symbols here as we have no
    # exception tracking information here. Instead we copy over the comment
    # from the proc header.
    if optDocInternal in d.conf.globalOptions:
      result = {sfFromGeneric, sfForward}*n.sym.flags == {}
    else:
      result = {sfExported, sfFromGeneric, sfForward}*n.sym.flags == {sfExported}
    if result and containsOrIncl(d.emitted, n.sym.id):
      result = false
  elif n.kind == nkPragmaExpr:
    result = isVisible(d, n[0])

proc getName(d: PDoc, n: PNode, splitAfter = -1): string =
  case n.kind
  of nkPostfix: result = getName(d, n[1], splitAfter)
  of nkPragmaExpr: result = getName(d, n[0], splitAfter)
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
  of nkPostfix: result = getNameIdent(cache, n[1])
  of nkPragmaExpr: result = getNameIdent(cache, n[0])
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
  of nkPostfix: result = getRstName(n[1])
  of nkPragmaExpr: result = getRstName(n[0])
  of nkSym: result = newRstLeaf(n.sym.renderDefinitionName)
  of nkIdent: result = newRstLeaf(n.ident.s)
  of nkAccQuoted:
    result = getRstName(n[0])
    for i in 1..<n.len: result.text.add(getRstName(n[i]).text)
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
  case k
  of skProc, skFunc: discard
  of skMacro: result.add(".m")
  of skMethod: result.add(".e")
  of skIterator: result.add(".i")
  of skTemplate: result.add(".t")
  of skConverter: result.add(".c")
  else: discard
  if n.safeLen > paramsPos and n[paramsPos].kind == nkFormalParams:
    let params = renderParamTypes(n[paramsPos])
    if params.len > 0:
      result.add(defaultParamSeparator)
      result.add(params)

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
  ## it is stripped at the first comma, colon or dot, usual English sentence
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

proc genDeprecationMsg(d: PDoc, n: PNode): Rope =
  ## Given a nkPragma wDeprecated node output a well-formatted section
  if n == nil: return

  case n.safeLen:
  of 0: # Deprecated w/o any message
    result = ropeFormatNamedVars(d.conf,
      getConfigVar(d.conf, "doc.deprecationmsg"), ["label", "message"],
      [~"Deprecated", nil])
  of 2: # Deprecated w/ a message
    if n[1].kind in {nkStrLit..nkTripleStrLit}:
      result = ropeFormatNamedVars(d.conf,
        getConfigVar(d.conf, "doc.deprecationmsg"), ["label", "message"],
        [~"Deprecated:", rope(xmltree.escape(n[1].strVal))])
  else:
    doAssert false

type DocFlags = enum
  kDefault
  kForceExport

proc genSeeSrcRope(d: PDoc, path: string, line: int): Rope =
  let docItemSeeSrc = getConfigVar(d.conf, "doc.item.seesrc")
  if docItemSeeSrc.len > 0:
    let path = relativeTo(AbsoluteFile path, AbsoluteDir getCurrentDir(), '/')
    when false:
      let cwd = canonicalizePath(d.conf, getCurrentDir())
      var path = path
      if path.startsWith(cwd):
        path = path[cwd.len+1..^1].replace('\\', '/')
    let gitUrl = getConfigVar(d.conf, "git.url")
    if gitUrl.len > 0:
      let defaultBranch =
        if NimPatch mod 2 == 1: "devel"
        else: "version-$1-$2" % [$NimMajor, $NimMinor]
      let commit = getConfigVar(d.conf, "git.commit", defaultBranch)
      let develBranch = getConfigVar(d.conf, "git.devel", "devel")
      dispA(d.conf, result, "$1", "", [ropeFormatNamedVars(d.conf, docItemSeeSrc,
          ["path", "line", "url", "commit", "devel"], [rope path.string,
          rope($line), rope gitUrl, rope commit, rope develBranch])])

proc genItem(d: PDoc, n, nameNode: PNode, k: TSymKind, docFlags: DocFlags) =
  if (docFlags != kForceExport) and not isVisible(d, nameNode): return
  let
    name = getName(d, nameNode)
    nameRope = name.rope
  var plainDocstring = getPlainDocstring(n) # call here before genRecComment!
  var result: Rope = nil
  var literal, plainName = ""
  var kind = tkEof
  var comm: Rope = nil
  if n.kind in routineDefs:
    getAllRunnableExamples(d, n, comm)
  else:
    comm.add genRecComment(d, n)

  var r: TSrcGen
  # Obtain the plain rendered string for hyperlink titles.
  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments,
    renderNoPragmas, renderNoProcDefs})
  while true:
    getNextTok(r, kind, literal)
    if kind == tkEof:
      break
    plainName.add(literal)

  var pragmaNode: PNode = nil
  if n.isCallable and n[pragmasPos].kind != nkEmpty:
    pragmaNode = findPragma(n[pragmasPos], wDeprecated)

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
    deprecationMsgRope = genDeprecationMsg(d, pragmaNode)

  nodeToHighlightedHtml(d, n, result, {renderNoBody, renderNoComments,
    renderDocComments, renderSyms}, symbolOrIdEncRope)

  let seeSrcRope = genSeeSrcRope(d, toFullPath(d.conf, n.info), n.info.line.int)
  d.section[k].add(ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.item"),
    ["name", "header", "desc", "itemID", "header_plain", "itemSym",
      "itemSymOrID", "itemSymEnc", "itemSymOrIDEnc", "seeSrc", "deprecationMsg"],
    [nameRope, result, comm, itemIDRope, plainNameRope, plainSymbolRope,
      symbolOrIdRope, plainSymbolEncRope, symbolOrIdEncRope, seeSrcRope,
      deprecationMsgRope]))

  let external = d.destFile.AbsoluteFile.relativeTo(d.conf.outDir, '/').changeFileExt(HtmlExt).string

  var attype: Rope
  if k in routineKinds and nameNode.kind == nkSym:
    let att = attachToType(d, nameNode.sym)
    if att != nil:
      attype = rope esc(d.target, att.name.s)
  elif k == skType and nameNode.kind == nkSym and nameNode.sym.typ.kind in {tyEnum, tyBool}:
    let etyp = nameNode.sym.typ
    for e in etyp.n:
      if e.sym.kind != skEnumField: continue
      let plain = renderPlainSymbolName(e)
      let symbolOrId = d.newUniquePlainSymbol(plain)
      setIndexTerm(d[], external, symbolOrId, plain, nameNode.sym.name.s & '.' & plain,
        xmltree.escape(getPlainDocstring(e).docstringSummary))

  d.toc[k].add(ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.item.toc"),
    ["name", "header_plain", "itemSymOrIDEnc"],
    [nameRope, plainNameRope, symbolOrIdEncRope]))

  d.tocTable[k].mgetOrPut(cleanPlainSymbol, nil).add(ropeFormatNamedVars(
    d.conf, getConfigVar(d.conf, "doc.item.tocTable"),
    ["name", "header_plain", "itemSymOrID", "itemSymOrIDEnc"],
    [nameRope, plainNameRope, rope(symbolOrId.replace(",", ",<wbr>")), symbolOrIdEncRope]))

  # Ironically for types the complexSymbol is *cleaner* than the plainName
  # because it doesn't include object fields or documentation comments. So we
  # use the plain one for callable elements, and the complex for the rest.
  var linkTitle = changeFileExt(extractFilename(d.filename), "") & ": "
  if n.isCallable: linkTitle.add(xmltree.escape(plainName.strip))
  else: linkTitle.add(xmltree.escape(complexSymbol.strip))

  setIndexTerm(d[], external, symbolOrId, name, linkTitle,
    xmltree.escape(plainDocstring.docstringSummary))
  if k == skType and nameNode.kind == nkSym:
    d.types.strTableAdd nameNode.sym

proc genJsonItem(d: PDoc, n, nameNode: PNode, k: TSymKind): JsonNode =
  if not isVisible(d, nameNode): return
  var
    name = getName(d, nameNode)
    comm = $genRecComment(d, n)
    r: TSrcGen
  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments})
  result = %{ "name": %name, "type": %($k), "line": %n.info.line.int,
                 "col": %n.info.col}
  if comm.len > 0:
    result["description"] = %comm
  if r.buf.len > 0:
    result["code"] = %r.buf
  if k in routineKinds:
    result["signature"] = newJObject()
    if n[paramsPos][0].kind != nkEmpty:
      result["signature"]["return"] = %($n[paramsPos][0])
    if n[paramsPos].len > 1:
      result["signature"]["arguments"] = newJArray()
    for paramIdx in 1 ..< n[paramsPos].len:
      for identIdx in 0 ..< n[paramsPos][paramIdx].len - 2:
        let
          paramName = $n[paramsPos][paramIdx][identIdx]
          paramType = $n[paramsPos][paramIdx][^2]
        if n[paramsPos][paramIdx][^1].kind != nkEmpty:
          let paramDefault = $n[paramsPos][paramIdx][^1]
          result["signature"]["arguments"].add %{"name": %paramName, "type": %paramType, "default": %paramDefault}
        else:
          result["signature"]["arguments"].add %{"name": %paramName, "type": %paramType}
    if n[pragmasPos].kind != nkEmpty:
      result["signature"]["pragmas"] = newJArray()
      for pragma in n[pragmasPos]:
        result["signature"]["pragmas"].add %($pragma)
    if n[genericParamsPos].kind != nkEmpty:
      result["signature"]["genericParams"] = newJArray()
      for genericParam in n[genericParamsPos]:
        var param = %{"name": %($genericParam)}
        if genericParam.sym.typ.sons.len > 0:
          param["types"] = newJArray()
        for kind in genericParam.sym.typ.sons:
          param["types"].add %($kind)
        result["signature"]["genericParams"].add param

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
      a[2] = x
      traceDeps(d, a)
  elif it.kind == nkSym and belongsToPackage(d.conf, it.sym):
    let external = externalDep(d, it.sym)
    if d.section[k] != nil: d.section[k].add(", ")
    dispA(d.conf, d.section[k],
          "<a class=\"reference external\" href=\"$2\">$1</a>",
          "$1", [rope esc(d.target, external.prettyLink),
          rope changeFileExt(external, "html")])

proc exportSym(d: PDoc; s: PSym) =
  const k = exportSection
  if s.kind == skModule and belongsToPackage(d.conf, s):
    let external = externalDep(d, s)
    if d.section[k] != nil: d.section[k].add(", ")
    dispA(d.conf, d.section[k],
          "<a class=\"reference external\" href=\"$2\">$1</a>",
          "$1", [rope esc(d.target, external.prettyLink),
          rope changeFileExt(external, "html")])
  elif s.kind != skModule and s.owner != nil:
    let module = originatingModule(s)
    if belongsToPackage(d.conf, module):
      let
        complexSymbol = complexName(s.kind, s.ast, s.name.s)
        symbolOrIdRope = rope(d.newUniquePlainSymbol(complexSymbol))
        external = externalDep(d, module)
      if d.section[k] != nil: d.section[k].add(", ")
      # XXX proper anchor generation here
      dispA(d.conf, d.section[k],
            "<a href=\"$2#$3\"><span class=\"Identifier\">$1</span></a>",
            "$1", [rope esc(d.target, s.name.s),
            rope changeFileExt(external, "html"),
            symbolOrIdRope])

proc documentNewEffect(cache: IdentCache; n: PNode): PNode =
  let s = n[namePos].sym
  if tfReturnsNew in s.typ.flags:
    result = newIdentNode(getIdent(cache, "new"), n.info)

proc documentEffect(cache: IdentCache; n, x: PNode, effectType: TSpecialWord, idx: int): PNode =
  let spec = effectSpec(x, effectType)
  if isNil(spec):
    let s = n[namePos].sym

    let actual = s.typ.n[0]
    if actual.len != effectListLen: return
    let real = actual[idx]

    # warning: hack ahead:
    var effects = newNodeI(nkBracket, n.info, real.len)
    for i in 0..<real.len:
      var t = typeToString(real[i].typ)
      if t.startsWith("ref "): t = substr(t, 4)
      effects[i] = newIdentNode(getIdent(cache, t), n.info)
      # set the type so that the following analysis doesn't screw up:
      effects[i].typ = real[i].typ

    result = newTreeI(nkExprColonExpr, n.info,
      newIdentNode(getIdent(cache, $effectType), n.info), effects)

proc documentWriteEffect(cache: IdentCache; n: PNode; flag: TSymFlag; pragmaName: string): PNode =
  let s = n[namePos].sym
  let params = s.typ.n

  var effects = newNodeI(nkBracket, n.info)
  for i in 1..<params.len:
    if params[i].kind == nkSym and flag in params[i].sym.flags:
      effects.add params[i]

  if effects.len > 0:
    result = newTreeI(nkExprColonExpr, n.info,
      newIdentNode(getIdent(cache, pragmaName), n.info), effects)

proc documentRaises*(cache: IdentCache; n: PNode) =
  if n[namePos].kind != nkSym: return
  let pragmas = n[pragmasPos]
  let p1 = documentEffect(cache, n, pragmas, wRaises, exceptionEffects)
  let p2 = documentEffect(cache, n, pragmas, wTags, tagEffects)
  let p3 = documentWriteEffect(cache, n, sfWrittenTo, "writes")
  let p4 = documentNewEffect(cache, n)
  let p5 = documentWriteEffect(cache, n, sfEscapes, "escapes")

  if p1 != nil or p2 != nil or p3 != nil or p4 != nil or p5 != nil:
    if pragmas.kind == nkEmpty:
      n[pragmasPos] = newNodeI(nkPragma, n.info)
    if p1 != nil: n[pragmasPos].add p1
    if p2 != nil: n[pragmasPos].add p2
    if p3 != nil: n[pragmasPos].add p3
    if p4 != nil: n[pragmasPos].add p4
    if p5 != nil: n[pragmasPos].add p5

proc generateDoc*(d: PDoc, n, orig: PNode, docFlags: DocFlags = kDefault) =
  template genItemAux(skind) =
    genItem(d, n, n[namePos], skind, docFlags)
  case n.kind
  of nkPragma:
    let pragmaNode = findPragma(n, wDeprecated)
    d.modDeprecationMsg.add(genDeprecationMsg(d, pragmaNode))
  of nkCommentStmt: d.modDesc.add(genComment(d, n))
  of nkProcDef, nkFuncDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItemAux(skProc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItemAux(skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItemAux(skIterator)
  of nkMacroDef: genItemAux(skMacro)
  of nkTemplateDef: genItemAux(skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(d.cache, n)
    genItemAux(skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in 0..<n.len:
      if n[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        genItem(d, n[i], n[i][0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)), docFlags)
  of nkStmtList:
    for i in 0..<n.len: generateDoc(d, n[i], orig)
  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n[0][0]):
      generateDoc(d, lastSon(n[0]), orig)
  of nkImportStmt:
    for it in n: traceDeps(d, it)
  of nkExportStmt:
    for it in n:
      if it.kind == nkSym:
        if d.module != nil and d.module == it.sym.owner:
          generateDoc(d, it.sym.ast, orig, kForceExport)
        elif it.sym.ast != nil:
          exportSym(d, it.sym)
  of nkExportExceptStmt: discard "transformed into nkExportStmt by semExportExcept"
  of nkFromStmt, nkImportExceptStmt: traceDeps(d, n[0])
  of nkCallKinds:
    var comm: Rope = nil
    getAllRunnableExamples(d, n, comm)
    if comm != nil: d.modDesc.add(comm)
  else: discard

proc add(d: PDoc; j: JsonNode) =
  if j != nil: d.jArray.add j

proc generateJson*(d: PDoc, n: PNode, includeComments: bool = true) =
  case n.kind
  of nkCommentStmt:
    if includeComments:
      d.add %*{"comment": genComment(d, n)}
    else:
      d.modDesc.add(genComment(d, n))
  of nkProcDef, nkFuncDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n[namePos], skProc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n[namePos], skIterator)
  of nkMacroDef:
    d.add genJsonItem(d, n, n[namePos], skMacro)
  of nkTemplateDef:
    d.add genJsonItem(d, n, n[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(d.cache, n)
    d.add genJsonItem(d, n, n[namePos], skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in 0..<n.len:
      if n[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        d.add genJsonItem(d, n[i], n[i][0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)))
  of nkStmtList:
    for i in 0..<n.len:
      generateJson(d, n[i], includeComments)
  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n[0][0]):
      generateJson(d, lastSon(n[0]), includeComments)
  else: discard

proc genTagsItem(d: PDoc, n, nameNode: PNode, k: TSymKind): string =
  result = getName(d, nameNode) & "\n"

proc generateTags*(d: PDoc, n: PNode, r: var Rope) =
  case n.kind
  of nkCommentStmt:
    if startsWith(n.comment, "##"):
      let stripped = n.comment.substr(2).strip
      r.add stripped
  of nkProcDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n[namePos], skProc)
  of nkFuncDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n[namePos], skFunc)
  of nkMethodDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n[namePos], skMethod)
  of nkIteratorDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n[namePos], skIterator)
  of nkMacroDef:
    r.add genTagsItem(d, n, n[namePos], skMacro)
  of nkTemplateDef:
    r.add genTagsItem(d, n, n[namePos], skTemplate)
  of nkConverterDef:
    when useEffectSystem: documentRaises(d.cache, n)
    r.add genTagsItem(d, n, n[namePos], skConverter)
  of nkTypeSection, nkVarSection, nkLetSection, nkConstSection:
    for i in 0..<n.len:
      if n[i].kind != nkCommentStmt:
        # order is always 'type var let const':
        r.add genTagsItem(d, n[i], n[i][0],
                succ(skType, ord(n.kind)-ord(nkTypeSection)))
  of nkStmtList:
    for i in 0..<n.len:
      generateTags(d, n[i], r)
  of nkWhenStmt:
    # generate documentation for the first branch only:
    if not checkForFalse(n[0][0]):
      generateTags(d, lastSon(n[0]), r)
  else: discard

proc genSection(d: PDoc, kind: TSymKind, groupedToc = false) =
  const sectionNames: array[skModule..skField, string] = [
    "Imports", "Types", "Vars", "Lets", "Consts", "Vars", "Procs", "Funcs",
    "Methods", "Iterators", "Converters", "Macros", "Templates", "Exports"
  ]
  if d.section[kind] == nil: return
  var title = sectionNames[kind].rope
  d.section[kind] = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.section"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      ord(kind).rope, title, rope(ord(kind) + 50), d.section[kind]])

  var tocSource = d.toc
  if groupedToc:
    for p in d.tocTable[kind].keys:
      d.toc2[kind].add ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.section.toc2"), [
          "sectionid", "sectionTitle", "sectionTitleID", "content", "plainName"], [
          ord(kind).rope, title, rope(ord(kind) + 50), d.tocTable[kind][p], p.rope])
    tocSource = d.toc2

  d.toc[kind] = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.section.toc"), [
      "sectionid", "sectionTitle", "sectionTitleID", "content"], [
      ord(kind).rope, title, rope(ord(kind) + 50), tocSource[kind]])

proc relLink(outDir: AbsoluteDir, destFile: AbsoluteFile, linkto: RelativeFile): Rope =
  rope($relativeTo(outDir / linkto, destFile.splitFile().dir, '/'))

proc genOutFile(d: PDoc, groupedToc = false): Rope =
  var
    code, content: Rope
    title = ""
  var j = 0
  var tmp = ""
  renderTocEntries(d[], j, 1, tmp)
  var toc = tmp.rope
  for i in TSymKind:
    var shouldSort = i in {skProc, skFunc} and groupedToc
    genSection(d, i, shouldSort)
    toc.add(d.toc[i])
  if toc != nil:
    toc = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.toc"), ["content"], [toc])
  for i in TSymKind: code.add(d.section[i])

  # Extract the title. Non API modules generate an entry in the index table.
  if d.meta[metaTitle].len != 0:
    title = d.meta[metaTitle]
    let external = presentationPath(d.conf, AbsoluteFile d.filename).changeFileExt(HtmlExt).string.nativeToUnixPath
    setIndexTerm(d[], external, "", title)
  else:
    # Modules get an automatic title for the HTML, but no entry in the index.
    # better than `extractFilename(changeFileExt(d.filename, ""))` as it disambiguates dups
    title = $presentationPath(d.conf, AbsoluteFile d.filename, isTitle = true).changeFileExt("")

  var groupsection = getConfigVar(d.conf, "doc.body_toc_groupsection")
  let bodyname = if d.hasToc and not d.isPureRst:
                   groupsection.setLen 0
                   "doc.body_toc_group"
                 elif d.hasToc: "doc.body_toc"
                 else: "doc.body_no_toc"
  let seeSrcRope = genSeeSrcRope(d, d.filename, 1)
  content = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, bodyname), ["title",
      "tableofcontents", "moduledesc", "date", "time", "content", "deprecationMsg", "theindexhref", "body_toc_groupsection", "seeSrc"],
      [title.rope, toc, d.modDesc, rope(getDateStr()),
      rope(getClockStr()), code, d.modDeprecationMsg, relLink(d.conf.outDir, d.destFile.AbsoluteFile, theindexFname.RelativeFile), groupsection.rope, seeSrcRope])
  if optCompileOnly notin d.conf.globalOptions:
    # XXX what is this hack doing here? 'optCompileOnly' means raw output!?
    code = ropeFormatNamedVars(d.conf, getConfigVar(d.conf, "doc.file"), [
        "nimdoccss", "dochackjs",  "title", "tableofcontents", "moduledesc", "date", "time",
        "content", "author", "version", "analytics", "deprecationMsg"],
        [relLink(d.conf.outDir, d.destFile.AbsoluteFile, nimdocOutCss.RelativeFile),
        relLink(d.conf.outDir, d.destFile.AbsoluteFile, docHackJsFname.RelativeFile),
        title.rope, toc, d.modDesc, rope(getDateStr()), rope(getClockStr()),
        content, d.meta[metaAuthor].rope, d.meta[metaVersion].rope, d.analytics.rope, d.modDeprecationMsg])
  else:
    code = content
  result = code

proc generateIndex*(d: PDoc) =
  if optGenIndex in d.conf.globalOptions:
    let dir = d.conf.outDir
    createDir(dir)
    let dest = dir / changeFileExt(presentationPath(d.conf, AbsoluteFile d.filename), IndexExt)
    writeIndexFile(d[], dest.string)

proc updateOutfile(d: PDoc, outfile: AbsoluteFile) =
  if d.module == nil or sfMainModule in d.module.flags: # nil for e.g. for commandRst2Html
    if d.conf.outFile.isEmpty:
      d.conf.outFile = outfile.relativeTo(d.conf.outDir)
      if isAbsolute(d.conf.outFile.string):
        d.conf.outFile = splitPath(d.conf.outFile.string)[1].RelativeFile

proc writeOutput*(d: PDoc, useWarning = false, groupedToc = false) =
  runAllExamples(d)
  var content = genOutFile(d, groupedToc)
  if optStdout in d.conf.globalOptions:
    writeRope(stdout, content)
  else:
    template outfile: untyped = d.destFile.AbsoluteFile
    #let outfile = getOutFile2(d.conf, shortenDir(d.conf, filename), outExt)
    let dir = outfile.splitFile.dir
    createDir(dir)
    updateOutfile(d, outfile)
    if not writeRope(content, outfile):
      rawMessage(d.conf, if useWarning: warnCannotOpenFile else: errCannotOpenFile,
        outfile.string)
    elif not d.wroteSupportFiles: # nimdoc.css + dochack.js
      let nimr = $d.conf.getPrefixDir()
      copyFile(docCss.interp(nimr = nimr), $d.conf.outDir / nimdocOutCss)
      if optGenIndex in d.conf.globalOptions:
        let docHackJs2 = getDocHacksJs(nimr, nim = getAppFilename())
        copyFile(docHackJs2, $d.conf.outDir / docHackJs2.lastPathPart)
      d.wroteSupportFiles = true

proc writeOutputJson*(d: PDoc, useWarning = false) =
  runAllExamples(d)
  var modDesc: string
  for desc in d.modDesc:
    modDesc &= desc
  let content = %*{"orig": d.filename,
    "nimble": getPackageName(d.conf, d.filename),
    "moduleDescription": modDesc,
    "entries": d.jArray}
  if optStdout in d.conf.globalOptions:
    write(stdout, $content)
  else:
    var f: File
    if open(f, d.destFile, fmWrite):
      write(f, $content)
      close(f)
      updateOutfile(d, d.destFile.AbsoluteFile)
    else:
      localError(d.conf, newLineInfo(d.conf, AbsoluteFile d.filename, -1, -1),
                 warnUser, "unable to open file \"" & d.destFile &
                 "\" for writing")

proc handleDocOutputOptions*(conf: ConfigRef) =
  if optWholeProject in conf.globalOptions:
    # Backward compatibility with previous versions
    # xxx this is buggy when user provides `nim doc --project -o:sub/bar.html main`,
    # it'd write to `sub/bar.html/main.html`
    conf.outDir = AbsoluteDir(conf.outDir / conf.outFile)

proc commandDoc*(cache: IdentCache, conf: ConfigRef) =
  handleDocOutputOptions conf
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.hasToc = true
  generateDoc(d, ast, ast)
  writeOutput(d)
  generateIndex(d)

proc commandRstAux(cache: IdentCache, conf: ConfigRef;
                   filename: AbsoluteFile, outExt: string) =
  var filen = addFileExt(filename, "txt")
  var d = newDocumentor(filen, cache, conf, outExt)

  d.isPureRst = true
  var rst = parseRst(readFile(filen.string), filen.string, 0, 1, d.hasToc,
                     {roSupportRawDirective, roSupportMarkdown}, conf)
  var modDesc = newStringOfCap(30_000)
  renderRstToOut(d[], rst, modDesc)
  d.modDesc = rope(modDesc)
  writeOutput(d)
  generateIndex(d)

proc commandRst2Html*(cache: IdentCache, conf: ConfigRef) =
  commandRstAux(cache, conf, conf.projectFull, HtmlExt)

proc commandRst2TeX*(cache: IdentCache, conf: ConfigRef) =
  commandRstAux(cache, conf, conf.projectFull, TexExt)

proc commandJson*(cache: IdentCache, conf: ConfigRef) =
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.onTestSnippet = proc (d: var RstGenerator; filename, cmd: string;
                          status: int; content: string) =
    localError(conf, newLineInfo(conf, AbsoluteFile d.filename, -1, -1),
               warnUser, "the ':test:' attribute is not supported by this backend")
  d.hasToc = true
  generateJson(d, ast)
  let json = d.jArray
  let content = rope(pretty(json))

  if optStdout in d.conf.globalOptions:
    writeRope(stdout, content)
  else:
    #echo getOutFile(gProjectFull, JsonExt)
    let filename = getOutFile(conf, RelativeFile conf.projectName, JsonExt)
    if not writeRope(content, filename):
      rawMessage(conf, errCannotOpenFile, filename.string)

proc commandTags*(cache: IdentCache, conf: ConfigRef) =
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.onTestSnippet = proc (d: var RstGenerator; filename, cmd: string;
                          status: int; content: string) =
    localError(conf, newLineInfo(conf, AbsoluteFile d.filename, -1, -1),
               warnUser, "the ':test:' attribute is not supported by this backend")
  d.hasToc = true
  var
    content: Rope
  generateTags(d, ast, content)

  if optStdout in d.conf.globalOptions:
    writeRope(stdout, content)
  else:
    #echo getOutFile(gProjectFull, TagsExt)
    let filename = getOutFile(conf, RelativeFile conf.projectName, TagsExt)
    if not writeRope(content, filename):
      rawMessage(conf, errCannotOpenFile, filename.string)

proc commandBuildIndex*(conf: ConfigRef, dir: string, outFile = RelativeFile"") =
  var content = mergeIndexes(dir).rope

  var outFile = outFile
  if outFile.isEmpty: outFile = theindexFname.RelativeFile.changeFileExt("")
  let filename = getOutFile(conf, outFile, HtmlExt)

  let code = ropeFormatNamedVars(conf, getConfigVar(conf, "doc.file"), [
      "nimdoccss", "dochackjs",
      "title", "tableofcontents", "moduledesc", "date", "time",
      "content", "author", "version", "analytics"],
      [relLink(conf.outDir, filename, nimdocOutCss.RelativeFile),
      relLink(conf.outDir, filename, docHackJsFname.RelativeFile),
      rope"Index", nil, nil, rope(getDateStr()),
      rope(getClockStr()), content, nil, nil, nil])
  # no analytics because context is not available

  if not writeRope(code, filename):
    rawMessage(conf, errCannotOpenFile, filename.string)
