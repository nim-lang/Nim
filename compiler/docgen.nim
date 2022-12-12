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
  ast, strutils, strtabs, algorithm, sequtils, options, msgs, os, idents,
  wordrecg, syntaxes, renderer, lexer,
  packages/docutils/rst, packages/docutils/rstgen,
  json, xmltree, trees, types,
  typesrenderer, astalgo, lineinfos, intsets,
  pathutils, tables, nimpaths, renderverbatim, osproc, packages
import packages/docutils/rstast except FileIndex, TLineInfo

from uri import encodeUrl
from std/private/globs import nativeToUnixPath
from nodejs import findNodeJs

const
  exportSection = skField
  docCmdSkip = "skip"
  DocColOffset = "## ".len  # assuming that a space was added after ##

type
  ItemFragment = object  ## A fragment from each item will be eventually
                         ## constructed by converting `rst` fields to strings.
    case isRst: bool
    of true:
      rst: PRstNode
    of false:            ## contains ready markup e.g. from runnableExamples
      str: string
  ItemPre = seq[ItemFragment]  ## A pre-processed item.
  Item = object        ## Any item in documentation, e.g. symbol
                       ## entry. Configuration variable ``doc.item``
                       ## is used for its HTML rendering.
    descRst: ItemPre     ## Description of the item (may contain
                         ## runnableExamples).
    substitutions: seq[string]    ## Variable names in `doc.item`...
    sortName: string    ## The string used for sorting in output
  ModSection = object  ## Section like Procs, Types, etc.
    secItems: seq[Item]  ## Pre-processed items.
    finalMarkup: string  ## The items, after RST pass 2 and rendering.
  ModSections = array[TSymKind, ModSection]
  TocItem = object  ## HTML TOC item
    content: string
    sortName: string
  TocSectionsFinal = array[TSymKind, string]
  ExampleGroup = ref object
    ## a group of runnableExamples with same rdoccmd
    rdoccmd: string ## from 1st arg in `runnableExamples(rdoccmd): body`
    docCmd: string ## from user config, e.g. --doccmd:-d:foo
    code: string ## contains imports; each import contains `body`
    index: int ## group index
  JsonItem = object  # pre-processed item: `rst` should be finalized
    json: JsonNode
    rst: PRstNode
    rstField: string
  TDocumentor = object of rstgen.RstGenerator
    modDescPre: ItemPre   # module description, not finalized
    modDescFinal: string  # module description, after RST pass 2 and rendering
    module: PSym
    modDeprecationMsg: string
    section: ModSections     # entries of ``.nim`` file (for `proc`s, etc)
    tocSimple: array[TSymKind, seq[TocItem]]
      # TOC entries for non-overloadable symbols (e.g. types, constants)...
    tocTable:  array[TSymKind, Table[string, seq[TocItem]]]
      # ...otherwise (e.g. procs)
    toc2: TocSectionsFinal  # TOC `content`, which is probably wrapped
                            # in `doc.section.toc2`
    toc: TocSectionsFinal  # final TOC (wrapped in `doc.section.toc`)
    indexValFilename: string
    analytics: string  # Google Analytics javascript, "" if doesn't exist
    seenSymbols: StringTableRef # avoids duplicate symbol generation for HTML.
    jEntriesPre: seq[JsonItem] # pre-processed RST + JSON content
    jEntriesFinal: JsonNode    # final JSON after RST pass 2 and rendering
    types: TStrTable
    sharedState: PRstSharedState
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

proc add(dest: var ItemPre, rst: PRstNode) = dest.add ItemFragment(isRst: true, rst: rst)
proc add(dest: var ItemPre, str: string) = dest.add ItemFragment(isRst: false, str: str)

proc cmpDecimalsIgnoreCase(a, b: string): int =
  ## For sorting with correct handling of cases like 'uint8' and 'uint16'.
  ## Also handles leading zeros well (however note that leading zeros are
  ## significant when lengths of numbers mismatch, e.g. 'bar08' > 'bar8' !).
  runnableExamples:
    doAssert cmpDecimalsIgnoreCase("uint8", "uint16") < 0
    doAssert cmpDecimalsIgnoreCase("val00032", "val16suffix") > 0
    doAssert cmpDecimalsIgnoreCase("val16suffix", "val16") > 0
    doAssert cmpDecimalsIgnoreCase("val_08_32", "val_08_8") > 0
    doAssert cmpDecimalsIgnoreCase("val_07_32", "val_08_8") < 0
    doAssert cmpDecimalsIgnoreCase("ab8", "ab08") < 0
    doAssert cmpDecimalsIgnoreCase("ab8de", "ab08c") < 0 # sanity check
  let aLen = a.len
  let bLen = b.len
  var
    iA = 0
    iB = 0
  while iA < aLen and iB < bLen:
    if isDigit(a[iA]) and isDigit(b[iB]):
      var
        limitA = iA  # index after the last (least significant) digit
        limitB = iB
      while limitA < aLen and isDigit(a[limitA]): inc limitA
      while limitB < bLen and isDigit(b[limitB]): inc limitB
      var pos = max(limitA-iA, limitB-iA)
      while pos > 0:
        if limitA-pos < iA:  # digit in `a` is 0 effectively
          result = ord('0') - ord(b[limitB-pos])
        elif limitB-pos < iB:  # digit in `b` is 0 effectively
          result = ord(a[limitA-pos]) - ord('0')
        else:
          result = ord(a[limitA-pos]) - ord(b[limitB-pos])
        if result != 0: return
        dec pos
      result = (limitA - iA) - (limitB - iB)  # consider 'bar08' > 'bar8'
      if result != 0: return
      iA = limitA
      iB = limitB
    else:
      result = ord(toLowerAscii(a[iA])) - ord(toLowerAscii(b[iB]))
      if result != 0: return
      inc iA
      inc iB
  result = (aLen - iA) - (bLen - iB)

proc prettyString(a: object): string =
  # xxx pending std/prettyprint refs https://github.com/nim-lang/RFCs/issues/203#issuecomment-602534906
  for k, v in fieldPairs(a):
    result.add k & ": " & $v & "\n"

proc presentationPath*(conf: ConfigRef, file: AbsoluteFile): RelativeFile =
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
    # a relative path (would it be relative with regard to $PWD or to projectfile)
    conf.globalAssert conf.docRoot.isAbsolute, arg=conf.docRoot
    conf.globalAssert conf.docRoot.dirExists, arg=conf.docRoot
    # needed because `canonicalizePath` called on `file`
    result = file.relativeTo conf.docRoot.expandFilename.AbsoluteDir
  else:
    bail()
  if isAbsolute(result.string):
    result = file.string.splitPath()[1].RelativeFile
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
    of meGridTableNotImplemented: k = errRstGridTableNotImplemented
    of meMarkdownIllformedTable: k = errRstMarkdownIllformedTable
    of meNewSectionExpected: k = errRstNewSectionExpected
    of meGeneralParseError: k = errRstGeneralParseError
    of meInvalidDirective: k = errRstInvalidDirectiveX
    of meInvalidField: k = errRstInvalidField
    of meFootnoteMismatch: k = errRstFootnoteMismatch
    of meSandboxedDirective: k = errRstSandboxedDirective
    of mwRedefinitionOfLabel: k = warnRstRedefinitionOfLabel
    of mwUnknownSubstitution: k = warnRstUnknownSubstitutionX
    of mwBrokenLink: k = warnRstBrokenLink
    of mwUnsupportedLanguage: k = warnRstLanguageXNotSupported
    of mwUnsupportedField: k = warnRstFieldXNotSupported
    of mwRstStyle: k = warnRstStyle
    {.gcsafe.}:
      globalError(conf, newLineInfo(conf, AbsoluteFile filename, line, col), k, arg)

  proc docgenFindFile(s: string): string {.gcsafe.} =
    result = options.findFile(conf, s).string
    if result.len == 0:
      result = getCurrentDir() / s
      if not fileExists(result): result = ""

proc parseRst(text, filename: string,
              line, column: int,
              conf: ConfigRef, sharedState: PRstSharedState): PRstNode =
  declareClosures()
  result = rstParsePass1(text, line, column, sharedState)

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

proc isLatexCmd(conf: ConfigRef): bool = conf.cmd in {cmdRst2tex, cmdDoc2tex}

proc newDocumentor*(filename: AbsoluteFile; cache: IdentCache; conf: ConfigRef,
                    outExt: string = HtmlExt, module: PSym = nil,
                    isPureRst = false): PDoc =
  declareClosures()
  new(result)
  result.module = module
  result.conf = conf
  result.cache = cache
  result.outDir = conf.outDir.string
  result.isPureRst = isPureRst
  var options= {roSupportRawDirective, roSupportMarkdown, roPreferMarkdown, roSandboxDisabled}
  if not isPureRst: options.incl roNimFile
  result.sharedState = newRstSharedState(
      options, filename.string,
      docgenFindFile, compilerMsgHandler)
  initRstGenerator(result[], (if conf.isLatexCmd: outLatex else: outHtml),
                   conf.configVars, filename.string,
                   docgenFindFile, compilerMsgHandler)

  if conf.configVars.hasKey("doc.googleAnalytics") and
      conf.configVars.hasKey("doc.plausibleAnalytics"):
    doAssert false, "Either use googleAnalytics or plausibleAnalytics"

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
  elif conf.configVars.hasKey("doc.plausibleAnalytics"):
    result.analytics = """
    <script defer data-domain="$1" src="https://plausible.io/js/plausible.js"></script>
    """ % [conf.configVars.getOrDefault"doc.plausibleAnalytics"]
  else:
    result.analytics = ""

  result.seenSymbols = newStringTable(modeCaseInsensitive)
  result.id = 100
  result.jEntriesFinal = newJArray()
  initStrTable result.types
  result.onTestSnippet =
    proc (gen: var RstGenerator; filename, cmd: string; status: int; content: string) =
      if conf.docCmd == docCmdSkip: return
      inc(gen.id)
      var d = (ptr TDocumentor)(addr gen)
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

template dispA(conf: ConfigRef; dest: var string, xml, tex: string,
               args: openArray[string]) =
  if not conf.isLatexCmd: dest.addf(xml, args)
  else: dest.addf(tex, args)

proc getVarIdx(varnames: openArray[string], id: string): int =
  for i in 0..high(varnames):
    if cmpIgnoreStyle(varnames[i], id) == 0:
      return i
  result = -1

proc genComment(d: PDoc, n: PNode): PRstNode =
  if n.comment.len > 0:
    result = parseRst(n.comment, toFullPath(d.conf, n.info),
                      toLinenumber(n.info),
                      toColumn(n.info) + DocColOffset,
                      d.conf, d.sharedState)

proc genRecCommentAux(d: PDoc, n: PNode): PRstNode =
  if n == nil: return nil
  result = genComment(d, n)
  if result == nil:
    if n.kind in {nkStmtList, nkStmtListExpr, nkTypeDef, nkConstDef,
                  nkObjectTy, nkRefTy, nkPtrTy, nkAsgn, nkFastAsgn, nkHiddenStdConv}:
      # notin {nkEmpty..nkNilLit, nkEnumTy, nkTupleTy}:
      for i in 0..<n.len:
        result = genRecCommentAux(d, n[i])
        if result != nil: return
  else:
    n.comment = ""

proc genRecComment(d: PDoc, n: PNode): PRstNode =
  if n == nil: return nil
  result = genComment(d, n)
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

proc externalDep(d: PDoc; module: PSym): string =
  if optWholeProject in d.conf.globalOptions or d.conf.docRoot.len > 0:
    let full = AbsoluteFile toFullPath(d.conf, FileIndex module.position)
    let tmp = getOutFile2(d.conf, presentationPath(d.conf, full), HtmlExt, sfMainModule notin module.flags)
    result = relativeTo(tmp, d.thisDir, '/').string
  else:
    result = extractFilename toFullPath(d.conf, FileIndex module.position)

proc nodeToHighlightedHtml(d: PDoc; n: PNode; result: var string;
                           renderFlags: TRenderFlags = {};
                           procLink: string) =
  var r: TSrcGen
  var literal = ""
  initTokRender(r, n, renderFlags)
  var kind = tkEof
  var tokenPos = 0
  var procTokenPos = 0
  template escLit(): untyped = esc(d.target, literal)
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
            [literal])
    of tkOpr:
      dispA(d.conf, result, "<span class=\"Operator\">$1</span>", "\\spanOperator{$1}",
            [escLit])
    of tkStrLit..tkTripleStrLit, tkCustomLit:
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
      if procTokenPos == tokenPos-2 and procLink != "":
        dispA(d.conf, result, "<a href=\"#$2\"><span class=\"Identifier\">$1</span></a>",
              "\\spanIdentifier{$1}", [escLit, procLink])
      elif s != nil and s.kind in {skType, skVar, skLet, skConst} and
           sfExported in s.flags and s.owner != nil and
           belongsToProjectPackage(d.conf, s.owner) and d.target == outHtml:
        let external = externalDep(d, s.owner)
        result.addf "<a href=\"$1#$2\"><span class=\"Identifier\">$3</span></a>",
          [changeFileExt(external, "html"), literal,
           escLit]
      else:
        dispA(d.conf, result, "<span class=\"Identifier\">$1</span>",
              "\\spanIdentifier{$1}", [escLit])
    of tkSpaces, tkInvalid:
      result.add(literal)
    of tkHideableStart:
      template fun(s) = dispA(d.conf, result, s, "\\spanOther{$1}", [escLit])
      if renderRunnableExamples in renderFlags: fun "$1"
      else:
        # 1st span is required for the JS to work properly
        fun """
<span>
<span class="Other pragmadots">...</span>
</span>
<span class="pragmawrap">""".replace("\n", "")  # Must remove newlines because wrapped in a <pre>
    of tkHideableEnd:
      template fun(s) = dispA(d.conf, result, s, "\\spanOther{$1}", [escLit])
      if renderRunnableExamples in renderFlags: fun "$1"
      else: fun "</span>"
    of tkCurlyDotLe: dispA(d.conf, result, "$1", "\\spanOther{$1}", [escLit])
    of tkCurlyDotRi: dispA(d.conf, result, "$1", "\\spanOther{$1}", [escLit])
    of tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, tkCurlyRi,
       tkBracketDotLe, tkBracketDotRi, tkParDotLe,
       tkParDotRi, tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot,
       tkAccent, tkColonColon,
       tkGStrLit, tkGTripleStrLit, tkInfixOpr, tkPrefixOpr, tkPostfixOpr,
       tkBracketLeColon:
      dispA(d.conf, result, "<span class=\"Other\">$1</span>", "\\spanOther{$1}",
            [escLit])

proc exampleOutputDir(d: PDoc): AbsoluteDir = d.conf.getNimcacheDir / RelativeDir"runnableExamples"

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
    if d.conf.backend == backendJs and findNodeJs() == "":
      discard "ignore JS runnableExample"
    elif os.execShellCmd(cmd) != 0:
      d.conf.quitOrRaise "[runnableExamples] failed: generated file: '$1' group: '$2' cmd: $3" % [outp.string, group[].prettyString, cmd]
    else:
      # keep generated source file `outp` to allow inspection.
      rawMessage(d.conf, hintSuccess, ["runnableExamples: " & outp.string])
      # removeFile(outp.changeFileExt(ExeExt)) # it's in nimcache, no need to remove

proc quoted(a: string): string = result.addQuoted(a)

proc toInstantiationInfo(conf: ConfigRef, info: TLineInfo): (string, int, int) =
  # xxx expose in compiler/lineinfos.nim
  (conf.toMsgFilename(info), info.line.int, info.col.int + ColOffset)

proc prepareExample(d: PDoc; n: PNode, topLevel: bool): tuple[rdoccmd: string, code: string] =
  ## returns `rdoccmd` and source code for this runnableExamples
  var rdoccmd = ""
  if n.len < 2 or n.len > 3: globalError(d.conf, n.info, "runnableExamples invalid")
  if n.len == 3:
    let n1 = n[1]
    # xxx this should be evaluated during sempass
    if n1.kind notin nkStrKinds: globalError(d.conf, n1.info, "string litteral expected")
    rdoccmd = n1.strVal

  let useRenderModule = false
  let loc = d.conf.toFileLineCol(n.info)
  let code = extractRunnableExamplesSource(d.conf, n)
  let codeIndent = extractRunnableExamplesSource(d.conf, n, indent = 2)

  if d.conf.errorCounter > 0:
    return (rdoccmd, code)

  let comment = "autogenerated by docgen\nloc: $1\nrdoccmd: $2" % [loc, rdoccmd]
  let outputDir = d.exampleOutputDir
  createDir(outputDir)
  inc d.exampleCounter
  let outp = outputDir / RelativeFile("$#_examples_$#.nim" % [d.filename.extractFilename.changeFileExt"", $d.exampleCounter])

  if useRenderModule:
    var docComment = newTree(nkCommentStmt)
    docComment.comment = comment
    var runnableExamples = newTree(nkStmtList,
        docComment,
        newTree(nkImportStmt, newStrNode(nkStrLit, d.filename)))
    runnableExamples.info = n.info
    for a in n.lastSon: runnableExamples.add a

    # buggy, refs bug #17292
    # still worth fixing as it can affect other code relying on `renderModule`,
    # so we keep this code path here for now, which could still be useful in some
    # other situations.
    renderModule(runnableExamples, outp.string, conf = d.conf)

  else:
    var code2 = code
    if code.len > 0 and "codeReordering" notin code:
      # hacky but simplest solution, until we devise a way to make `{.line.}`
      # work without introducing a scope
      code2 = """
{.line: $#.}:
$#
""" % [$toInstantiationInfo(d.conf, n.info), codeIndent]
    code2 = """
#[
$#
]#
import $#
$#
""" % [comment, d.filename.quoted, code2]
    writeFile(outp.string, code2)

  if rdoccmd notin d.exampleGroups:
    d.exampleGroups[rdoccmd] = ExampleGroup(rdoccmd: rdoccmd, docCmd: d.conf.docCmd, index: d.exampleGroups.len)
  d.exampleGroups[rdoccmd].code.add "import $1\n" % outp.string.quoted

  var codeShown: string
  if topLevel: # refs https://github.com/nim-lang/RFCs/issues/352
    let title = canonicalImport(d.conf, AbsoluteFile d.filename)
    codeShown = "import $#\n$#" % [title, code]
  else:
    codeShown = code
  result = (rdoccmd, codeShown)
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

proc getAllRunnableExamplesImpl(d: PDoc; n: PNode, dest: var ItemPre,
                                state: RunnableState, topLevel: bool):
                               RunnableState =
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
        n.len >= 2 and n.lastSon.kind == nkStmtList:
      if state in {rsStart, rsComment, rsRunnable}:
        let (rdoccmd, code) = prepareExample(d, n, topLevel)
        var msg = "Example:"
        if rdoccmd.len > 0: msg.add " cmd: " & rdoccmd
        var s: string
        dispA(d.conf, s, "\n<p><strong class=\"examples_text\">$1</strong></p>\n",
            "\n\n\\textbf{$1}\n", [msg])
        dest.add s
        inc d.listingCounter
        let id = $d.listingCounter
        dest.add(d.config.getOrDefault"doc.listing_start" % [id, "langNim", ""])
        var dest2 = ""
        renderNimCode(dest2, code, d.target)
        dest.add dest2
        dest.add(d.config.getOrDefault"doc.listing_end" % id)
        return rsRunnable
      else:
        localError(d.conf, n.info, errUser, "runnableExamples must appear before the first non-comment statement")
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

proc getAllRunnableExamples(d: PDoc, n: PNode, dest: var ItemPre) =
  var n = n
  var state = rsStart
  template fn(n2, topLevel) =
    state = getAllRunnableExamplesImpl(d, n2, dest, state, topLevel)
  dest.add genComment(d, n)
  case n.kind
  of routineDefs:
    n = n.getRoutineBody
    case n.kind
    of nkCommentStmt, nkCallKinds: fn(n, topLevel = false)
    else:
      for i in 0..<n.safeLen:
        fn(n[i], topLevel = false)
        if state == rsDone: discard # check all sons
  else: fn(n, topLevel = true)

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
  ## section of ``doc/docgen.rst``.
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
    result.setLen(pos - 1)
    result.add("…")
  if pos < maxDocstringChars:
    return
  # Try to keep trimming at other natural boundaries.
  pos = result.find({'.', ',', ':'})
  let last = result.len - 1
  if pos > 0 and pos < last:
    result.setLen(pos - 1)
    result.add("…")

proc genDeprecationMsg(d: PDoc, n: PNode): string =
  ## Given a nkPragma wDeprecated node output a well-formatted section
  if n == nil: return

  case n.safeLen:
  of 0: # Deprecated w/o any message
    result = getConfigVar(d.conf, "doc.deprecationmsg") % [
       "label" , "Deprecated", "message", ""]
  of 2: # Deprecated w/ a message
    if n[1].kind in {nkStrLit..nkTripleStrLit}:
      result = getConfigVar(d.conf, "doc.deprecationmsg") % [
          "label", "Deprecated:", "message", xmltree.escape(n[1].strVal)]
  else:
    doAssert false

type DocFlags = enum
  kDefault
  kForceExport

proc genSeeSrc(d: PDoc, path: string, line: int): string =
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
      dispA(d.conf, result, "$1", "", [docItemSeeSrc % [
          "path", path.string, "line", $line, "url", gitUrl,
          "commit", commit, "devel", develBranch]])

proc genItem(d: PDoc, n, nameNode: PNode, k: TSymKind, docFlags: DocFlags) =
  if (docFlags != kForceExport) and not isVisible(d, nameNode): return
  let
    name = getName(d, nameNode)
  var plainDocstring = getPlainDocstring(n) # call here before genRecComment!
  var result = ""
  var literal, plainName = ""
  var kind = tkEof
  var comm: ItemPre
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

  var pragmaNode = getDeclPragma(n)
  if pragmaNode != nil: pragmaNode = findPragma(pragmaNode, wDeprecated)

  inc(d.id)
  let
    plainNameEsc = esc(d.target, plainName.strip)
    uniqueName = if k in routineKinds: plainNameEsc else: name
    sortName = if k in routineKinds: plainName.strip else: name
    cleanPlainSymbol = renderPlainSymbolName(nameNode)
    complexSymbol = complexName(k, n, cleanPlainSymbol)
    plainSymbolEnc = encodeUrl(cleanPlainSymbol, usePlus = false)
    symbolOrId = d.newUniquePlainSymbol(complexSymbol)
    symbolOrIdEnc = encodeUrl(symbolOrId, usePlus = false)
    deprecationMsg = genDeprecationMsg(d, pragmaNode)

  nodeToHighlightedHtml(d, n, result, {renderNoBody, renderNoComments,
    renderDocComments, renderSyms}, symbolOrIdEnc)

  let seeSrc = genSeeSrc(d, toFullPath(d.conf, n.info), n.info.line.int)

  d.section[k].secItems.add Item(
    descRst: comm,
    sortName: sortName,
    substitutions: @[
     "name", name, "uniqueName", uniqueName,
     "header", result, "itemID", $d.id,
     "header_plain", plainNameEsc, "itemSym", cleanPlainSymbol,
     "itemSymOrID", symbolOrId, "itemSymEnc", plainSymbolEnc,
     "itemSymOrIDEnc", symbolOrIdEnc, "seeSrc", seeSrc,
     "deprecationMsg", deprecationMsg])

  let external = d.destFile.AbsoluteFile.relativeTo(d.conf.outDir, '/').changeFileExt(HtmlExt).string

  var attype = ""
  if k in routineKinds and nameNode.kind == nkSym:
    let att = attachToType(d, nameNode.sym)
    if att != nil:
      attype = esc(d.target, att.name.s)
  elif k == skType and nameNode.kind == nkSym and nameNode.sym.typ.kind in {tyEnum, tyBool}:
    let etyp = nameNode.sym.typ
    for e in etyp.n:
      if e.sym.kind != skEnumField: continue
      let plain = renderPlainSymbolName(e)
      let symbolOrId = d.newUniquePlainSymbol(plain)
      setIndexTerm(d[], external, symbolOrId, plain, nameNode.sym.name.s & '.' & plain,
        xmltree.escape(getPlainDocstring(e).docstringSummary))

  d.tocSimple[k].add TocItem(
    sortName: sortName,
    content: getConfigVar(d.conf, "doc.item.toc") % [
      "name", name, "header_plain", plainNameEsc,
      "itemSymOrIDEnc", symbolOrIdEnc])

  d.tocTable[k].mgetOrPut(cleanPlainSymbol, newSeq[TocItem]()).add TocItem(
    sortName: sortName,
    content: getConfigVar(d.conf, "doc.item.tocTable") % [
      "name", name, "header_plain", plainNameEsc,
      "itemSymOrID", symbolOrId.replace(",", ",<wbr>"),
      "itemSymOrIDEnc", symbolOrIdEnc])

  # Ironically for types the complexSymbol is *cleaner* than the plainName
  # because it doesn't include object fields or documentation comments. So we
  # use the plain one for callable elements, and the complex for the rest.
  var linkTitle = changeFileExt(extractFilename(d.filename), "") & ": "
  if n.kind in routineDefs: linkTitle.add(xmltree.escape(plainName.strip))
  else: linkTitle.add(xmltree.escape(complexSymbol.strip))

  setIndexTerm(d[], external, symbolOrId, name, linkTitle,
    xmltree.escape(plainDocstring.docstringSummary))
  if k == skType and nameNode.kind == nkSym:
    d.types.strTableAdd nameNode.sym

proc genJsonItem(d: PDoc, n, nameNode: PNode, k: TSymKind): JsonItem =
  if not isVisible(d, nameNode): return
  var
    name = getName(d, nameNode)
    comm = genRecComment(d, n)
    r: TSrcGen
  initTokRender(r, n, {renderNoBody, renderNoComments, renderDocComments})
  result.json = %{ "name": %name, "type": %($k), "line": %n.info.line.int,
                   "col": %n.info.col}
  if comm != nil:
    result.rst = comm
    result.rstField = "description"
  if r.buf.len > 0:
    result.json["code"] = %r.buf
  if k in routineKinds:
    result.json["signature"] = newJObject()
    if n[paramsPos][0].kind != nkEmpty:
      result.json["signature"]["return"] = %($n[paramsPos][0])
    if n[paramsPos].len > 1:
      result.json["signature"]["arguments"] = newJArray()
    for paramIdx in 1 ..< n[paramsPos].len:
      for identIdx in 0 ..< n[paramsPos][paramIdx].len - 2:
        let
          paramName = $n[paramsPos][paramIdx][identIdx]
          paramType = $n[paramsPos][paramIdx][^2]
        if n[paramsPos][paramIdx][^1].kind != nkEmpty:
          let paramDefault = $n[paramsPos][paramIdx][^1]
          result.json["signature"]["arguments"].add %{"name": %paramName, "type": %paramType, "default": %paramDefault}
        else:
          result.json["signature"]["arguments"].add %{"name": %paramName, "type": %paramType}
    if n[pragmasPos].kind != nkEmpty:
      result.json["signature"]["pragmas"] = newJArray()
      for pragma in n[pragmasPos]:
        result.json["signature"]["pragmas"].add %($pragma)
    if n[genericParamsPos].kind != nkEmpty:
      result.json["signature"]["genericParams"] = newJArray()
      for genericParam in n[genericParamsPos]:
        var param = %{"name": %($genericParam)}
        if genericParam.sym.typ.sons.len > 0:
          param["types"] = newJArray()
        for kind in genericParam.sym.typ.sons:
          param["types"].add %($kind)
        result.json["signature"]["genericParams"].add param

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
  elif it.kind == nkSym and belongsToProjectPackage(d.conf, it.sym):
    let external = externalDep(d, it.sym)
    if d.section[k].finalMarkup != "": d.section[k].finalMarkup.add(", ")
    dispA(d.conf, d.section[k].finalMarkup,
          "<a class=\"reference external\" href=\"$2\">$1</a>",
          "$1", [esc(d.target, external.prettyLink),
                 changeFileExt(external, "html")])

proc exportSym(d: PDoc; s: PSym) =
  const k = exportSection
  if s.kind == skModule and belongsToProjectPackage(d.conf, s):
    let external = externalDep(d, s)
    if d.section[k].finalMarkup != "": d.section[k].finalMarkup.add(", ")
    dispA(d.conf, d.section[k].finalMarkup,
          "<a class=\"reference external\" href=\"$2\">$1</a>",
          "$1", [esc(d.target, external.prettyLink),
                 changeFileExt(external, "html")])
  elif s.kind != skModule and s.owner != nil:
    let module = originatingModule(s)
    if belongsToProjectPackage(d.conf, module):
      let
        complexSymbol = complexName(s.kind, s.ast, s.name.s)
        symbolOrId = d.newUniquePlainSymbol(complexSymbol)
        external = externalDep(d, module)
      if d.section[k].finalMarkup != "": d.section[k].finalMarkup.add(", ")
      # XXX proper anchor generation here
      dispA(d.conf, d.section[k].finalMarkup,
            "<a href=\"$2#$3\"><span class=\"Identifier\">$1</span></a>",
            "$1", [esc(d.target, s.name.s),
                   changeFileExt(external, "html"),
                   symbolOrId])

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
    if real == nil: return
    let realLen = real.len
    # warning: hack ahead:
    var effects = newNodeI(nkBracket, n.info, realLen)
    for i in 0..<realLen:
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
  ## Goes through nim nodes recursively and collects doc comments.
  ## Main function for `doc`:option: command,
  ## which is implemented in ``docgen2.nim``.
  template genItemAux(skind) =
    genItem(d, n, n[namePos], skind, docFlags)
  case n.kind
  of nkPragma:
    let pragmaNode = findPragma(n, wDeprecated)
    d.modDeprecationMsg.add(genDeprecationMsg(d, pragmaNode))
  of nkCommentStmt: d.modDescPre.add(genComment(d, n))
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
    var comm: ItemPre
    getAllRunnableExamples(d, n, comm)
    if comm.len != 0: d.modDescPre.add(comm)
  else: discard

proc finishGenerateDoc*(d: var PDoc) =
  ## Perform 2nd RST pass for resolution of links/footnotes/headings...
  # copy file map `filenames` to ``rstgen.nim`` for its warnings
  d.filenames = d.sharedState.filenames

  # Main title/subtitle are allowed only in the first RST fragment of document
  var firstRst = PRstNode(nil)
  for fragment in d.modDescPre:
    if fragment.isRst:
      firstRst = fragment.rst
      break
  preparePass2(d.sharedState, firstRst)

  # Finalize fragments of ``.nim`` or ``.rst`` file
  proc renderItemPre(d: PDoc, fragments: ItemPre, result: var string) =
    for f in fragments:
      case f.isRst:
      of true:
        var resolved = resolveSubs(d.sharedState, f.rst)
        renderRstToOut(d[], resolved, result)
      of false: result &= f.str
  proc cmp(x, y: Item): int = cmpDecimalsIgnoreCase(x.sortName, y.sortName)
  for k in TSymKind:
    for item in d.section[k].secItems.sorted(cmp):
      var itemDesc: string
      renderItemPre(d, item.descRst, itemDesc)
      d.section[k].finalMarkup.add(
        getConfigVar(d.conf, "doc.item") % (
            item.substitutions & @["desc", itemDesc]))
      itemDesc = ""
    d.section[k].secItems.setLen 0
  renderItemPre(d, d.modDescPre, d.modDescFinal)
  d.modDescPre.setLen 0
  d.hasToc = d.hasToc or d.sharedState.hasToc

  # Finalize fragments of ``.json`` file
  for i, entry in d.jEntriesPre:
    if entry.rst != nil:
      let resolved = resolveSubs(d.sharedState, entry.rst)
      var str: string
      renderRstToOut(d[], resolved, str)
      entry.json[entry.rstField] = %str
      d.jEntriesPre[i].rst = nil

    d.jEntriesFinal.add entry.json # generates docs

proc add(d: PDoc; j: JsonItem) =
  if j.json != nil or j.rst != nil: d.jEntriesPre.add j

proc generateJson*(d: PDoc, n: PNode, includeComments: bool = true) =
  case n.kind
  of nkCommentStmt:
    if includeComments:
      d.add JsonItem(rst: genComment(d, n), rstField: "comment",
                     json: %Table[string, string]())
    else:
      d.modDescPre.add(genComment(d, n))
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

proc generateTags*(d: PDoc, n: PNode, r: var string) =
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
  if d.section[kind].finalMarkup == "": return
  var title = sectionNames[kind]
  d.section[kind].finalMarkup = getConfigVar(d.conf, "doc.section") % [
      "sectionid", $ord(kind), "sectionTitle", title,
      "sectionTitleID", $(ord(kind) + 50), "content", d.section[kind].finalMarkup]

  proc cmp(x, y: TocItem): int = cmpDecimalsIgnoreCase(x.sortName, y.sortName)
  if groupedToc:
    let overloadableNames = toSeq(keys(d.tocTable[kind]))
    for plainName in overloadableNames.sorted(cmpDecimalsIgnoreCase):
      var overloadChoices = d.tocTable[kind][plainName]
      overloadChoices.sort(cmp)
      var content: string
      for item in overloadChoices:
        content.add item.content
      d.toc2[kind].add getConfigVar(d.conf, "doc.section.toc2") % [
          "sectionid", $ord(kind), "sectionTitle", title,
          "sectionTitleID", $(ord(kind) + 50),
          "content", content, "plainName", plainName]
  else:
    for item in d.tocSimple[kind].sorted(cmp):
      d.toc2[kind].add item.content

  d.toc[kind] = getConfigVar(d.conf, "doc.section.toc") % [
      "sectionid", $ord(kind), "sectionTitle", title,
      "sectionTitleID", $(ord(kind) + 50), "content", d.toc2[kind]]

proc relLink(outDir: AbsoluteDir, destFile: AbsoluteFile, linkto: RelativeFile): string =
  $relativeTo(outDir / linkto, destFile.splitFile().dir, '/')

proc genOutFile(d: PDoc, groupedToc = false): string =
  var
    code, content: string
    title = ""
  var j = 0
  var toc = ""
  renderTocEntries(d[], j, 1, toc)
  for i in TSymKind:
    var shouldSort = i in routineKinds and groupedToc
    genSection(d, i, shouldSort)
    toc.add(d.toc[i])
  if toc != "" or d.target == outLatex:
    # for Latex $doc.toc will automatically generate TOC if `d.hasToc` is set
    toc = getConfigVar(d.conf, "doc.toc") % ["content", toc]
  for i in TSymKind: code.add(d.section[i].finalMarkup)

  # Extract the title. Non API modules generate an entry in the index table.
  if d.meta[metaTitle].len != 0:
    title = d.meta[metaTitle]
    let external = presentationPath(d.conf, AbsoluteFile d.filename).changeFileExt(HtmlExt).string.nativeToUnixPath
    setIndexTerm(d[], external, "", title)
  else:
    # Modules get an automatic title for the HTML, but no entry in the index.
    title = canonicalImport(d.conf, AbsoluteFile d.filename)
  title = esc(d.target, title)
  var subtitle = ""
  if d.meta[metaSubtitle] != "":
    dispA(d.conf, subtitle, "<h2 class=\"subtitle\">$1</h2>",
        "\\\\\\vspace{0.5em}\\large $1", [esc(d.target, d.meta[metaSubtitle])])

  var groupsection = getConfigVar(d.conf, "doc.body_toc_groupsection")
  let bodyname = if d.hasToc and not d.isPureRst and not d.conf.isLatexCmd:
                   groupsection.setLen 0
                   "doc.body_toc_group"
                 elif d.hasToc: "doc.body_toc"
                 else: "doc.body_no_toc"
  let seeSrc = genSeeSrc(d, d.filename, 1)
  content = getConfigVar(d.conf, bodyname) % [
      "title", title, "subtitle", subtitle,
      "tableofcontents", toc, "moduledesc", d.modDescFinal, "date", getDateStr(),
      "time", getClockStr(), "content", code,
      "deprecationMsg", d.modDeprecationMsg,
      "theindexhref", relLink(d.conf.outDir, d.destFile.AbsoluteFile,
                              theindexFname.RelativeFile),
      "body_toc_groupsection", groupsection, "seeSrc", seeSrc]
  if optCompileOnly notin d.conf.globalOptions:
    # XXX what is this hack doing here? 'optCompileOnly' means raw output!?
    code = getConfigVar(d.conf, "doc.file") % [
        "nimdoccss", relLink(d.conf.outDir, d.destFile.AbsoluteFile,
                             nimdocOutCss.RelativeFile),
        "dochackjs", relLink(d.conf.outDir, d.destFile.AbsoluteFile,
                             docHackJsFname.RelativeFile),
        "title", title, "subtitle", subtitle, "tableofcontents", toc,
        "moduledesc", d.modDescFinal, "date", getDateStr(), "time", getClockStr(),
        "content", content, "author", d.meta[metaAuthor],
        "version", esc(d.target, d.meta[metaVersion]), "analytics", d.analytics,
        "deprecationMsg", d.modDeprecationMsg]
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
    write(stdout, content)
  else:
    template outfile: untyped = d.destFile.AbsoluteFile
    #let outfile = getOutFile2(d.conf, shortenDir(d.conf, filename), outExt)
    let dir = outfile.splitFile.dir
    createDir(dir)
    updateOutfile(d, outfile)
    try:
      writeFile(outfile, content)
    except IOError:
      rawMessage(d.conf, if useWarning: warnCannotOpenFile else: errCannotOpenFile,
        outfile.string)
    if not d.wroteSupportFiles: # nimdoc.css + dochack.js
      let nimr = $d.conf.getPrefixDir()
      copyFile(docCss.interp(nimr = nimr), $d.conf.outDir / nimdocOutCss)
      if optGenIndex in d.conf.globalOptions:
        let docHackJs2 = getDocHacksJs(nimr, nim = getAppFilename())
        copyFile(docHackJs2, $d.conf.outDir / docHackJs2.lastPathPart)
      d.wroteSupportFiles = true

proc writeOutputJson*(d: PDoc, useWarning = false) =
  runAllExamples(d)
  var modDesc: string
  for desc in d.modDescFinal:
    modDesc &= desc
  let content = %*{"orig": d.filename,
    "nimble": getPackageName(d.conf, d.filename),
    "moduleDescription": modDesc,
    "entries": d.jEntriesFinal}
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
  ## implementation of deprecated ``doc0`` command (without semantic checking)
  handleDocOutputOptions conf
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.hasToc = true
  generateDoc(d, ast, ast)
  finishGenerateDoc(d)
  writeOutput(d)
  generateIndex(d)

proc commandRstAux(cache: IdentCache, conf: ConfigRef;
                   filename: AbsoluteFile, outExt: string) =
  var filen = addFileExt(filename, "txt")
  var d = newDocumentor(filen, cache, conf, outExt, isPureRst = true)
  let rst = parseRst(readFile(filen.string), filen.string,
                     line=LineRstInit, column=ColRstInit,
                     conf, d.sharedState)
  d.modDescPre = @[ItemFragment(isRst: true, rst: rst)]
  finishGenerateDoc(d)
  writeOutput(d)
  generateIndex(d)

proc commandRst2Html*(cache: IdentCache, conf: ConfigRef) =
  commandRstAux(cache, conf, conf.projectFull, HtmlExt)

proc commandRst2TeX*(cache: IdentCache, conf: ConfigRef) =
  commandRstAux(cache, conf, conf.projectFull, TexExt)

proc commandJson*(cache: IdentCache, conf: ConfigRef) =
  ## implementation of a deprecated jsondoc0 command
  var ast = parseFile(conf.projectMainIdx, cache, conf)
  if ast == nil: return
  var d = newDocumentor(conf.projectFull, cache, conf)
  d.onTestSnippet = proc (d: var RstGenerator; filename, cmd: string;
                          status: int; content: string) =
    localError(conf, newLineInfo(conf, AbsoluteFile d.filename, -1, -1),
               warnUser, "the ':test:' attribute is not supported by this backend")
  d.hasToc = true
  generateJson(d, ast)
  finishGenerateDoc(d)
  let json = d.jEntriesFinal
  let content = pretty(json)

  if optStdout in d.conf.globalOptions:
    write(stdout, content)
  else:
    #echo getOutFile(gProjectFull, JsonExt)
    let filename = getOutFile(conf, RelativeFile conf.projectName, JsonExt)
    try:
      writeFile(filename, content)
    except IOError:
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
    content = ""
  generateTags(d, ast, content)

  if optStdout in d.conf.globalOptions:
    write(stdout, content)
  else:
    #echo getOutFile(gProjectFull, TagsExt)
    let filename = getOutFile(conf, RelativeFile conf.projectName, TagsExt)
    try:
      writeFile(filename, content)
    except IOError:
      rawMessage(conf, errCannotOpenFile, filename.string)

proc commandBuildIndex*(conf: ConfigRef, dir: string, outFile = RelativeFile"") =
  var content = mergeIndexes(dir)

  var outFile = outFile
  if outFile.isEmpty: outFile = theindexFname.RelativeFile.changeFileExt("")
  let filename = getOutFile(conf, outFile, HtmlExt)

  let code = getConfigVar(conf, "doc.file") % [
      "nimdoccss", relLink(conf.outDir, filename, nimdocOutCss.RelativeFile),
      "dochackjs", relLink(conf.outDir, filename, docHackJsFname.RelativeFile),
      "title", "Index",
      "subtitle", "", "tableofcontents", "", "moduledesc", "",
      "date", getDateStr(), "time", getClockStr(),
      "content", content, "author", "", "version", "", "analytics", ""]
  # no analytics because context is not available

  try:
    writeFile(filename, code)
  except IOError:
    rawMessage(conf, errCannotOpenFile, filename.string)
