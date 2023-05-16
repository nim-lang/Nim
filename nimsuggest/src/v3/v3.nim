import strutils, net, sequtils, parseutils, strformat, algorithm, tables, std/sha1, times

import ../compiler/[renderer, options, msgs, sigmatch, ast, idents, modulegraphs, lineinfos,
    pathutils, syntaxes, passes]

import ../[globals, types, utils]

import graphUtils
import symbolUtils

proc recompilePartially(graph: ModuleGraph, projectFileIdx = InvalidFileIdx) =
  if projectFileIdx == InvalidFileIdx:
    myLog "Recompiling partially from root"
  else:
    myLog fmt "Recompiling partially starting from {graph.getModule(projectFileIdx)}"

  # inst caches are breaking incremental compilation when the cache caches stuff
  # from dirty buffer
  # TODO: investigate more efficient way to achieve the same
  # graph.typeInstCache.clear()
  # graph.procInstCache.clear()

  GC_fullCollect()

  try:
    benchmark "Recompilation":
      graph.compileProject(projectFileIdx)
  except Exception as e:
    myLog fmt "Failed to recompile partially with the following error:\n {e.msg} \n\n {e.getStackTrace()}"
    try:
      graph.recompileFullProject()
    except Exception as e:
      myLog fmt "Failed clean recompilation:\n {e.msg} \n\n {e.getStackTrace()}"

proc markDirtyIfNeeded(graph: ModuleGraph, file: string, originalFileIdx: FileIndex) =
  let sha = $sha1.secureHashFile(file)
  if graph.config.m.fileInfos[originalFileIdx.int32].hash != sha or graph.config.ideCmd == ideSug:
    myLog fmt "{file} changed compared to last compilation"
    graph.markDirty originalFileIdx
    graph.markClientsDirty originalFileIdx
  else:
    myLog fmt "No changes in file {file} compared to last compilation"





const
  # kinds for ideOutline and ideGlobalSymbols
  searchableSymKinds = {skField, skEnumField, skIterator, skMethod, skFunc, skProc, skConverter, skTemplate}

proc symbolEqual(left, right: PSym): bool =
  # More relaxed symbol comparison
  return left.info.exactEquals(right.info) and left.name == right.name

proc findDef(n: PNode, line: uint16, col: int16): PNode =
  if n.kind in {nkProcDef, nkIteratorDef, nkTemplateDef, nkMethodDef, nkMacroDef}:
    if n.info.line == line:
      return n
  else:
    for i in 0 ..< safeLen(n):
      let res = findDef(n[i], line, col)
      if res != nil: return res



proc executeNoHooksV3*(cmd: CommandData, graph: ModuleGraph) =

  #This exposes all it's props as variables in the current scope
  destructure cmd

  let conf = graph.config

  conf.writelnHook = proc (s: string) = discard
  conf.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo;
                                   msg: string; sev: Severity) =
    let suggest = Suggest(section: ideChk, filePath: toFullPath(conf, info),
      line: toLinenumber(info), column: toColumn(info), doc: msg, forth: $sev)
    graph.suggestErrors.mgetOrPut(info.fileIndex, @[]).add suggest

  conf.ideCmd = ideCmd

  myLog fmt "cmd: {ideCmd}, file: {file}[{line}:{col}], dirtyFile: {dirtyFile}, tag: {tag}"

  var fileIndex: FileIndex

  if not (ideCmd in {ideRecompile, ideGlobalSymbols}):
    if not fileInfoKnown(conf, file):
      myLog fmt "{file} is unknown, returning no results"
      return

    fileIndex = fileInfoIdx(conf, file)
    msgs.setDirtyFile(
      conf,
      fileIndex,
      #TODO: We can probably skip this because this will allways be absolutefile ""
      if dirtyFile.isEmpty: AbsoluteFile"" else: dirtyFile)

    if not dirtyFile.isEmpty:
      graph.markDirtyIfNeeded(dirtyFile.string, fileInfoIdx(conf, file))

  # these commands require fully compiled project
  if ideCmd in {ideUse, ideDus, ideGlobalSymbols, ideChk} and graph.needsCompilation():
    graph.recompilePartially()
    # when doing incremental build for the project root we should make sure that
    # everything is unmarked as no longer beeing dirty in case there is no
    # longer reference to a particular module. E. g. A depends on B, B is marked
    # as dirty and A loses B import.
    graph.unmarkAllDirty()

  # these commands require partially compiled project
  elif ideCmd in {ideSug, ideOutline, ideHighlight, ideDef, ideChkFile, ideType, ideDeclaration, ideExpand} and
       (graph.needsCompilation(fileIndex) or ideCmd == ideSug):
    # for ideSug use v2 implementation
    if ideCmd == ideSug:
      conf.m.trackPos = newLineInfo(fileIndex, line, col)
      conf.m.trackPosAttached = false
    else:
      conf.m.trackPos = default(TLineInfo)

    graph.recompilePartially(fileIndex)

  case ideCmd
  of ideDef:
    let s = graph.findSymData(file, line, col)
    if not s.isNil:
      graph.suggestResult(s.sym, s.sym.info)
  of ideType:
    let s = graph.findSymData(file, line, col)
    if not s.isNil:
      let typeSym = s.sym.typ.sym
      if typeSym != nil:
        graph.suggestResult(typeSym, typeSym.info, ideType)
      elif s.sym.typ.len != 0:
        let genericType = s.sym.typ[0].sym
        graph.suggestResult(genericType, genericType.info, ideType)
  of ideUse, ideDus:
    let symbol = graph.findSymData(file, line, col)
    if not symbol.isNil:
      var res: seq[SymInfoPair] = @[]
      for s in graph.suggestSymbolsIter:
        if s.sym.symbolEqual(symbol.sym):
          res.add(s)
      for s in res.deduplicateSymInfoPair():
        graph.suggestResult(s.sym, s.info)
  of ideHighlight:
    let sym = graph.findSymData(file, line, col)
    if not sym.isNil:
      let usages = graph.fileSymbols(fileIndex).filterIt(it.sym == sym.sym)
      myLog fmt "Found {usages.len} usages in {file.string}"
      for s in usages:
        graph.suggestResult(s.sym, s.info)
  of ideRecompile:
    graph.recompileFullProject()
  of ideChanged:
    graph.markDirtyIfNeeded(file.string, fileIndex)
  of ideSug:
    # ideSug performs partial build of the file, thus mark it dirty for the
    # future calls.
    graph.markDirtyIfNeeded(file.string, fileIndex)
  of ideOutline:
    let n = parseFile(fileIndex, graph.cache, graph.config)
    graph.iterateOutlineNodes(n, graph.fileSymbols(fileIndex).deduplicateSymInfoPair)
  of ideChk:
    myLog fmt "Reporting errors for {graph.suggestErrors.len} file(s)"
    for sug in graph.suggestErrorsIter:
      suggestResult(graph.config, sug)
  of ideChkFile:
    let errors = graph.suggestErrors.getOrDefault(fileIndex, @[])
    myLog fmt "Reporting {errors.len} error(s) for {file.string}"
    for error in errors:
      suggestResult(graph.config, error)
  of ideGlobalSymbols:
    var
      counter = 0
      res: seq[SymInfoPair] = @[]

    for s in graph.suggestSymbolsIter:
      if (sfGlobal in s.sym.flags or s.sym.kind in searchableSymKinds) and
          s.sym.info == s.info:
        if contains(s.sym.name.s, file.string):
          inc counter
          res = res.filterIt(not it.info.exactEquals(s.info))
          res.add s
          # stop after first 1000 matches...
          if counter > 1000:
            break

    # ... then sort them by weight ...
    res.sort() do (left, right: SymInfoPair) -> int:
      let
        leftString = left.sym.name.s
        rightString = right.sym.name.s
        leftIndex = leftString.find(file.string)
        rightIndex = rightString.find(file.string)

      if leftIndex == rightIndex:
        result = cmp(toLowerAscii(leftString),
                     toLowerAscii(rightString))
      else:
        result = cmp(leftIndex, rightIndex)

    # ... and send first 100 results
    if res.len > 0:
      for i in 0 .. min(100, res.len - 1):
        let s = res[i]
        graph.suggestResult(s.sym, s.info)

  of ideDeclaration:
    let s = graph.findSymData(file, line, col)
    if not s.isNil:
      # find first mention of the symbol in the file containing the definition.
      # It is either the definition or the declaration.
      var first: SymInfoPair
      for symbol in graph.fileSymbols(s.sym.info.fileIndex).deduplicateSymInfoPair:
        if s.sym.symbolEqual(symbol.sym):
          first = symbol
          break

      if s.info.exactEquals(first.info):
        # we are on declaration, go to definition
        graph.suggestResult(first.sym, first.sym.info, ideDeclaration)
      else:
        # we are on definition or usage, look for declaration
        graph.suggestResult(first.sym, first.info, ideDeclaration)
  of ideExpand:
    var level: int = high(int)
    let index = skipWhitespace(tag, 0);
    let trimmed = substr(tag, index)
    if not (trimmed == "" or trimmed == "all"):
      discard parseInt(trimmed, level, 0)

    conf.expandPosition = newLineInfo(fileIndex, line, col)
    conf.expandLevels = level
    conf.expandProgress = false
    conf.expandNodeResult = ""

    graph.markDirty fileIndex
    graph.markClientsDirty fileIndex
    graph.recompilePartially()
    var suggest = Suggest()
    suggest.section = ideExpand
    suggest.version = 3
    suggest.line = line
    suggest.column = col
    suggest.doc = graph.config.expandNodeResult
    if suggest.doc != "":
      let
        n = parseFile(fileIndex, graph.cache, graph.config)
        endInfo = n.calculateExpandRange(conf.expandPosition)

      suggest.endLine = endInfo.line
      suggest.endCol = endInfo.col

    suggestResult(graph.config, suggest)

    graph.markDirty fileIndex
    graph.markClientsDirty fileIndex
  else:
    myLog fmt "Discarding {cmd}"
