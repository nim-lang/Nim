#
#
#           The Nim Compiler
#        (c) Copyright 2026 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## nimsuggest2's one-shot (`nimsuggest2 --one-shot`): answers one command of
## nimsuggest's protocol v4 and exits.

import compiler/renderer
import compiler/wordrecg
import std/[strformat, algorithm, tables, times, sets, strutils, os, osproc,
  parseopt, parseutils, sequtils]

when not defined(nimcore):
  {.error: "nimcore MUST be defined for Nim's core tooling".}

import compiler / [options, commands, modules, msgs, pipelines, sigmatch, ast, idents,
  modulegraphs, prefixmatches, lineinfos, cmdlinehelper, pathutils, condsyms,
  syntaxes, suggestsymdb, lexer, ast2nif, idetools, icconfig]

const HighestSuggestProtocolVersion = 4
const Usage = """
Nimsuggest2 - nimsuggest answering every command from the NIFs `nim ns` builds
Usage:
  nimsuggest2 [options] projectfile.nim

Options:
  --autobind              automatically binds into a free port
  --port:PORT             port
  --address:HOST          binds to that address, by default 127.0.0.1
  --clientProcessId:PID   shutdown nimsuggest2 in case this process dies
  --one-shot              answer the command read from stdin and exit
  --debug                 enable debug output
  --log                   enable verbose logging to nimsuggest.log file
  --info:X                information
    --info:nimVer           return the Nim compiler version that nimsuggest2 uses internally
    --info:protocolVer      return the newest protocol version that is supported
    --info:capabilities     return the capabilities supported by nimsuggest2
  --maxresults:N          limit the number of suggestions to N

In addition, all command line options of Nim that do not affect code generation
are supported.
"""

var
  gLogging = defined(logging)
  gRoot = InvalidFileIdx # the module a one-shot command compiles
  gNsModules: HashSet[string] # the project's modules, as `nim ns` reported them

proc myLog(s: string) =
  if gLogging: log(s)

const
  seps = {':', ';', ' ', '\t'}
  Help = "usage: sug|con|def|use|dus|chk|highlight|outline2|known|project file.nim[;dirtyfile.nim]:line:col\n" &
         "type 'quit' to quit"
  Capabilities = ["con", "unknownFile", "outline2"]

proc parseQuoted(cmd: string; outp: var string; start: int): int =
  var i = start
  i += skipWhitespace(cmd, i)
  if i < cmd.len and cmd[i] == '"':
    i += parseUntil(cmd, outp, '"', i+1)+2
  else:
    i += parseUntil(cmd, outp, seps, i)
  result = i

template benchmark(benchmarkName: untyped, code: untyped) =
  block:
    myLog "Started [" & benchmarkName & "]..."
    let t0 = epochTime()
    code
    let elapsed = epochTime() - t0
    let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
    myLog "CPU Time [" & benchmarkName & "] " & elapsedStr & "s"

proc compileRoot(graph: ModuleGraph) =
  ## A root with a fresh NIF is loaded from it first, so that compiling it from
  ## source reuses the instances it brings.
  if not graph.icNifIsStale(gRoot):
    benchmark "Load":
      graph.compilePipelineProject(gRoot)
    graph.markDirty gRoot
  graph.icNoteFromSource(gRoot)
  benchmark "Compilation":
    graph.compilePipelineProject(gRoot)

func deduplicateSymInfoPair[SymInfoPair](xs: seq[SymInfoPair]): seq[SymInfoPair] =
  result = newSeqOfCap[SymInfoPair](xs.len)
  for itm in xs.reversed:
    var found = false
    for res in result:
      if res.info.exactEquals(itm.info):
        found = true
        break
    if not found:
      result.add(itm)
  result.reverse()

func deduplicateSymInfoPair(xs: SuggestFileSymbolDatabase, isGenericInstance: bool): SuggestFileSymbolDatabase =
  result = SuggestFileSymbolDatabase(
    lineInfo: newSeqOfCap[TinyLineInfo](xs.lineInfo.len),
    sym: newSeqOfCap[PSym](xs.sym.len),
    isDecl: newPackedBoolArray(),
    caughtExceptions: newSeqOfCap[seq[PType]](xs.caughtExceptions.len),
    caughtExceptionsSet: newPackedBoolArray(),
    isGenericInstance: newPackedBoolArray(),
    fileIndex: xs.fileIndex,
    trackCaughtExceptions: xs.trackCaughtExceptions,
    isSorted: false
  )
  var i = xs.lineInfo.high
  while i >= 0:
    let itm = xs.lineInfo[i]
    var found = false
    for res in result.lineInfo:
      if res.exactEquals(itm):
        found = true
        break
    if not found:
      let q = xs.getSymInfoPair(i)
      if q.isGenericInstance == isGenericInstance:
        result.add(q)
    dec i
  result.reverse()

proc findSymData(graph: ModuleGraph, trackPos: TLineInfo): ref SymInfoPair =
  result = nil
  let db = graph.fileSymbols(trackPos.fileIndex).deduplicateSymInfoPair(false)
  doAssert(db.fileIndex == trackPos.fileIndex)
  for i in db.lineInfo.low..db.lineInfo.high:
    if isTracked(db.lineInfo[i], TinyLineInfo(line: trackPos.line, col: trackPos.col), db.sym[i].name.s.len):
      var res = db.getSymInfoPair(i)
      new(result)
      result[] = res
      break

func isInRange(current, startPos, endPos: TinyLineInfo, tokenLen: int): bool =
  result =
    (current.line > startPos.line or (current.line == startPos.line and current.col>=startPos.col)) and
    (current.line < endPos.line or (current.line == endPos.line and current.col <= endPos.col))

proc findSymDataInRange(graph: ModuleGraph, startPos, endPos: TLineInfo): seq[SymInfoPair] =
  result = newSeq[SymInfoPair]()
  let db = graph.fileSymbols(startPos.fileIndex).deduplicateSymInfoPair(false)
  for i in db.lineInfo.low..db.lineInfo.high:
    if isInRange(db.lineInfo[i], TinyLineInfo(line: startPos.line, col: startPos.col), TinyLineInfo(line: endPos.line, col: endPos.col), db.sym[i].name.s.len):
      result.add(db.getSymInfoPair(i))

proc symbolEqual(left, right: PSym): bool =
  return left.info.exactEquals(right.info) and left.name == right.name

proc findSymDataAll(graph: ModuleGraph, trackPos: TLineInfo): seq[SymInfoPair] =
  ## The symbol `findSymData` picks at `trackPos`, followed by every *other*
  ## routine overload of the same name recorded at that exact position.
  result = @[]
  let primary = graph.findSymData(trackPos)
  if primary.isNil: return
  result.add primary[]
  if primary.sym.kind notin routineKinds: return
  let db = graph.fileSymbols(trackPos.fileIndex)
  for i in db.lineInfo.low..db.lineInfo.high:
    let s = db.getSymInfoPair(i)
    if s.sym.kind in routineKinds and not s.isGenericInstance and
        s.info.exactEquals(primary.info) and s.sym.name.id == primary.sym.name.id and
        not result.anyIt(it.sym.symbolEqual(s.sym)):
      result.add s

proc identInRoutineBody(n: PNode, trackPos: TLineInfo, inRoutine = false): bool =
  if n.isNil: return false
  case n.kind
  of nkIdent:
    inRoutine and isTracked(n.info, trackPos, n.ident.s.len)
  of routineDefs:
    n.info.line <= trackPos.line and trackPos.line <= n.endInfo.line and
      identInRoutineBody(n[bodyPos], trackPos, inRoutine = true)
  else:
    for i in 0 ..< safeLen(n):
      if identInRoutineBody(n[i], trackPos, inRoutine): return true
    false

proc findSymDataWithFallback(graph: ModuleGraph; fileIndex: FileIndex;
                             line, col: int): seq[SymInfoPair] =
  ## Inside a generic body that is never instantiated the symbol database has
  ## nothing: then the root is compiled again with the cursor tracked (see
  ## `semIdeForTemplateOrGeneric`), keeping only the results at the cursor.
  let conf = graph.config
  let trackPos = newLineInfo(fileIndex, line, col)
  result = graph.findSymDataAll(trackPos)
  if result.len > 0 or
      not identInRoutineBody(parseFile(fileIndex, graph.cache, conf), trackPos):
    return
  myLog fmt "Symbol lookup at {conf $ trackPos} failed; recompiling with the cursor tracked"
  let savedSymbols = graph.suggestSymbols
  let ideCmd = conf.ideCmd
  conf.ideCmd = ideNone
  conf.m.trackPos = trackPos
  conf.m.trackPosAttached = false
  graph.markDirty gRoot
  graph.compileRoot()
  result = graph.findSymDataAll(trackPos)
  conf.ideCmd = ideCmd
  conf.m.trackPos = TLineInfo(fileIndex: trackPosInvalidFileIdx)
  graph.suggestSymbols = savedSymbols
  for s in result:
    graph.suggestSymbols.add(s, false)
proc suggestResult(graph: ModuleGraph, sym: PSym, info: TLineInfo,
                   defaultSection = ideNone, endLine: uint16 = 0, endCol = 0) =
  let section = if defaultSection != ideNone:
                  defaultSection
                elif sym.info.exactEquals(info):
                  ideDef
                else:
                  ideUse
  let suggest = symToSuggest(graph, sym, isLocal=false, section,
                             info, 100, PrefixMatch.None, false, 0,
                             endLine = endLine, endCol = endCol)
  suggestResult(graph.config, suggest)

proc suggestInlayHintResultType(graph: ModuleGraph, sym: PSym, info: TLineInfo,
                   defaultSection = ideNone, endLine: uint16 = 0, endCol = 0) =
  let section = if defaultSection != ideNone:
                  defaultSection
                elif sym.info.exactEquals(info):
                  ideDef
                else:
                  ideUse
  var suggestDef = symToSuggest(graph, sym, isLocal=false, section,
                                info, 100, PrefixMatch.None, false, 0, true,
                                endLine = endLine, endCol = endCol)
  suggestDef.inlayHintInfo = suggestToSuggestInlayTypeHint(suggestDef)
  suggestDef.section = ideInlayHints
  if sym.kind == skForVar:
    suggestDef.inlayHintInfo.allowInsert = false
  suggestResult(graph.config, suggestDef)

const
  searchableSymKinds = {skField, skEnumField, skIterator, skMethod, skFunc, skProc, skConverter, skTemplate}


proc calculateExpandRange(n: PNode, info: TLineInfo): TLineInfo =
  if ((n.kind in {nkFuncDef, nkProcDef, nkIteratorDef, nkTemplateDef, nkMethodDef, nkConverterDef} and
          n.info.exactEquals(info)) or
         (n.kind in {nkCall, nkCommand} and n[0].info.exactEquals(info))):
    result = n.endInfo
  else:
    for child in n:
      result = child.calculateExpandRange(info)
      if result != unknownLineInfo:
        return result
    result = unknownLineInfo

proc outline2Kind(n: PNode): TSymKind =
  case n.kind
  of nkProcDef: skProc
  of nkFuncDef: skFunc
  of nkMethodDef: skMethod
  of nkIteratorDef: skIterator
  of nkConverterDef: skConverter
  of nkTemplateDef: skTemplate
  of nkMacroDef: skMacro
  of nkTypeDef: skType
  of nkConstDef: skConst
  else: skUnknown

proc outline2NameNode(n: PNode): PNode =
  case n.kind
  of nkPostfix: outline2NameNode(n[1])
  of nkPragmaExpr: outline2NameNode(n[0])
  of nkIdent, nkSym, nkAccQuoted: n
  else: nil

proc outline2Name(n: PNode): string =
  case n.kind
  of nkIdent: n.ident.s
  of nkSym: n.sym.name.s
  of nkAccQuoted:
    var name = ""
    for x in n:
      if x.kind in nkLiterals - nkFloatLiterals: name.add x.renderTree
      else: name.add outline2Name(x)
    name
  else: ""

proc outline2Result(graph: ModuleGraph; kind: TSymKind; nameNode: PNode;
                    endInfo: TLineInfo; module: string; owners: seq[string]) =
  let name = graph.cache.getIdent(outline2Name(nameNode))
  if name.s.len == 0: return
  let info = nameNode.info
  var suggest = Suggest(section: ideOutline, symkind: byte kind, quality: 100,
    name: addr name.s, filePath: toFullPath(graph.config, info),
    line: toLinenumber(info), column: toColumn(info), tokenLen: name.s.len,
    version: graph.config.suggestVersion, endLine: endInfo.line, endCol: endInfo.col)
  if optIdeTerse notin graph.config.globalOptions:
    case owners.len
    of 0: suggest.qualifiedPath = @[module]
    of 1: suggest.qualifiedPath = @[module, owners[0]]
    else: suggest.qualifiedPath = owners[^2 .. ^1]
    if name.s[0] in OpChars + {'[', '{', '('} or name.id in ord(wAddr)..ord(wYield):
      suggest.qualifiedPath.add('`' & name.s & '`')
    else:
      suggest.qualifiedPath.add(name.s)
  suggestResult(graph.config, suggest)

proc outline2(graph: ModuleGraph; n: PNode; module: string; owners: var seq[string];
              inRoutine: bool) =
  case n.kind
  of nkFormalParams:
    discard
  of routineDefs, nkTypeDef, nkConstDef:
    let kind = outline2Kind(n)
    let nameNode = outline2NameNode(n[0])
    if nameNode != nil and (not inRoutine or
        kind in {skProc, skMethod, skIterator, skTemplate, skType}):
      graph.outline2Result(kind, nameNode, n.endInfo, module, owners)
    owners.add(if nameNode != nil: outline2Name(nameNode) else: "")
    for child in n:
      graph.outline2(child, module, owners, inRoutine or n.kind in routineDefs)
    owners.setLen(owners.len - 1)
  of nkEnumTy:
    for i in 1 ..< n.len:
      let field = if n[i].kind == nkEnumFieldDef: n[i][0] else: n[i]
      let nameNode = outline2NameNode(field)
      if nameNode != nil:
        graph.outline2Result(skEnumField, nameNode, nameNode.endInfo, module, owners)
  else:
    for child in n:
      graph.outline2(child, module, owners, inRoutine or n.kind in {nkLambda, nkDo})

proc answer(graph: ModuleGraph; cmd: IdeCmd; file: string; fileIndex: FileIndex;
            line, col: int; tag: string) =
  let conf = graph.config
  case cmd
  of ideDef:
    for s in graph.findSymDataWithFallback(fileIndex, line, col):
      graph.suggestResult(s.sym, s.sym.info)
  of ideType:
    let symbols = graph.findSymDataWithFallback(fileIndex, line, col)
    if symbols.len > 0 and symbols[0].sym.typ != nil:
      let s = symbols[0]
      let typeSym = s.sym.typ.sym
      if typeSym != nil:
        graph.suggestResult(typeSym, typeSym.info, ideType)
      elif s.sym.typ.len != 0 and s.sym.typ[0] != nil:
        let genericType = s.sym.typ[0].sym
        if genericType != nil:
          graph.suggestResult(genericType, genericType.info, ideType)
  of ideUse, ideDus:
    let symbols = graph.findSymDataWithFallback(fileIndex, line, col)
    if symbols.len > 0:
      var res: seq[SymInfoPair] = @[]
      for s in graph.suggestSymbolsIter:
        if symbols.anyIt(s.sym.symbolEqual(it.sym)):
          res.add(s)
      for s in res.deduplicateSymInfoPair():
        graph.suggestResult(s.sym, s.info)
  of ideHighlight:
    let sym = graph.findSymData(newLineInfo(fileIndex, line, col))
    if not sym.isNil:
      let fs = graph.fileSymbols(fileIndex)
      for i in fs.lineInfo.low..fs.lineInfo.high:
        if fs.sym[i] == sym.sym:
          let s = fs.getSymInfoPair(i)
          graph.suggestResult(s.sym, s.info)
  of ideOutline2:
    let n = parseFile(fileIndex, graph.cache, conf)
    if n != nil:
      var owners: seq[string] = @[]
      graph.outline2(n, splitFile(toFullPath(conf, gRoot)).name, owners, false)
  of ideChk:
    for sug in graph.suggestErrorsIter:
      suggestResult(conf, sug)
  of ideChkFile:
    for error in graph.suggestErrors.getOrDefault(fileIndex, @[]):
      suggestResult(conf, error)
  of ideGlobalSymbols:
    var
      counter = 0
      res: seq[SymInfoPair] = @[]
    for s in graph.suggestSymbolsIter:
      if (sfGlobal in s.sym.flags or s.sym.kind in searchableSymKinds) and
          s.sym.info == s.info:
        if contains(s.sym.name.s, file):
          inc counter
          res = res.filterIt(not it.info.exactEquals(s.info))
          res.add s
          if counter > 1000:
            break
    res.sort() do (left, right: SymInfoPair) -> int:
      let
        leftString = left.sym.name.s
        rightString = right.sym.name.s
        leftIndex = leftString.find(file)
        rightIndex = rightString.find(file)
      if leftIndex == rightIndex:
        result = cmp(toLowerAscii(leftString),
                     toLowerAscii(rightString))
      else:
        result = cmp(leftIndex, rightIndex)
    if res.len > 0:
      for i in 0 .. min(100, res.len - 1):
        let s = res[i]
        graph.suggestResult(s.sym, s.info)
  of ideDeclaration:
    for s in graph.findSymDataWithFallback(fileIndex, line, col):
      var first: SymInfoPair = default(SymInfoPair)
      let db = graph.fileSymbols(s.sym.info.fileIndex).deduplicateSymInfoPair(false)
      for i in db.lineInfo.low..db.lineInfo.high:
        if s.sym.symbolEqual(db.sym[i]):
          first = db.getSymInfoPair(i)
          break
      if s.info.exactEquals(first.info):
        graph.suggestResult(first.sym, first.sym.info, ideDeclaration)
      else:
        graph.suggestResult(first.sym, first.info, ideDeclaration)
  of ideExpand:
    var suggest = Suggest(section: ideExpand, version: 3, line: line, column: col,
      doc: conf.expandNodeResult)
    if suggest.doc != "":
      let endInfo = parseFile(fileIndex, graph.cache, conf).calculateExpandRange(conf.expandPosition)
      suggest.endLine = endInfo.line
      suggest.endCol = endInfo.col
    suggestResult(conf, suggest)
  of ideInlayHints:
    var endLine = 0
    var endCol = -1
    var i = 0
    i += skipWhile(tag, seps, i)
    i += parseInt(tag, endLine, i)
    i += skipWhile(tag, seps, i)
    i += parseInt(tag, endCol, i)
    i += skipWhile(tag, seps, i)
    var typeHints = true
    while i <= tag.high:
      var token: string = ""
      i += parseUntil(tag, token, seps, i)
      i += skipWhile(tag, seps, i)
      case token:
      of "+typeHints":
        typeHints = true
      of "-typeHints":
        typeHints = false
      else:
        myLog fmt "Discarding inlay hint parameter {token}"
    if typeHints:
      let startPos = newLineInfo(fileIndex, line, col)
      let endPos = newLineInfo(fileIndex, endLine, endCol)
      for q in graph.findSymDataInRange(startPos, endPos):
        if q.sym.kind in {skLet, skVar, skForVar, skConst} and q.isDecl and not q.sym.hasUserSpecifiedType:
          graph.suggestInlayHintResultType(q.sym, q.info, ideInlayHints)
  else:
    discard

proc useNsReport(graph: ModuleGraph; output: string) =
  let conf = graph.config
  for line in output.splitLines:
    if line.startsWith("icsemdir:"):
      conf.icSemDir = AbsoluteDir(line.substr("icsemdir:".len))
    elif line.startsWith("icmodule:"):
      graph.icVerify(line.substr("icmodule:".len))
      gNsModules.incl line.substr("icmodule:".len)
    elif line.startsWith("icdeferred:"):
      gNsModules.incl line.substr("icdeferred:".len)

proc nsReport(conf: ConfigRef): string =
  ## Where `nim ns` leaves its report (see `useNsReport`).
  getNimcacheDir(conf).string / "nimsuggest.txt"

proc changedSince(report: string): bool =
  ## Whether a module or include file `nim ns` read was saved after that run
  ## started, which is the report's modification time.
  result = false
  let seen = getLastModificationTime(report)
  for line in readFile(report).splitLines:
    let i = line.find(':')
    if i > 0 and line.substr(0, i) in ["icmodule:", "icdeferred:", "icinclude:"]:
      let f = line.substr(i + 1)
      if fileExists(f) and getLastModificationTime(f) > seen: return true

proc nsRoots(report: string): seq[string] =
  ## The modules besides the project `nim ns` built as roots (`--nsRoot`).
  ## For unknown files support.
  result = @[]
  if fileExists(report):
    for line in readFile(report).splitLines:
      if line.startsWith("icroot:"): result.add line.substr("icroot:".len)

proc runNimNs(graph: ModuleGraph; roots: seq[string]) =
  ## Brings the NIFs of the project and of `roots` and `nsReport` up to date
  ## with `nim ns`. Modules that fail to compile there are compiled from source
  ## by the queries; not being able to run `nim ns` is an error.
  let conf = graph.config
  let nim = getAppDir() / addFileExt("nim", ExeExt)
  let cache = getNimcacheDir(conf).string
  var args = @[nim, "ns", "--nimcache:" & cache]
  for root in roots: args.add "--nsRoot:" & root
  let cmd = quoteShellCommand(args & conf.projectFull.string)
  template fail(msg: string) =
    stderr.writeLine "nimsuggest2: nim ns: " & msg
    quit 1
  var output = ""
  var exitCode = -1
  benchmark "nim ns":
    try:
      (output, exitCode) = execCmdEx(cmd, workingDir = conf.projectPath.string)
    except OSError as e:
      fail "cannot run " & cmd & ": " & e.msg
  myLog "nim ns: " & cmd & " exit code: " & $exitCode
  if exitCode != 0: myLog output
  let format = cache / "ic.version"
  if not fileExists(format) or readFile(format) != icFormatVersion:
    fail nim & " writes NIFs in another format than nimsuggest2 reads (" &
      icFormatVersion & "): is it from the same build?\n" & output
  if not fileExists(nsReport(conf)):
    fail cmd & " wrote no report: is " & nim &
      " from the same build as nimsuggest2?\n" & output

type Query = object
  opc: string
  cmd: IdeCmd
  file, dirty: string
  line, col: int
  tag: string

proc parseQuery(cmd: string; conf: ConfigRef): Query =
  ## Parses a command like nimsuggest's `execCmd` does; `cmd` is `ideNone`
  ## for an unknown command.
  result = Query(col: -1)
  var i = parseIdent(cmd, result.opc, 0)
  result.opc = result.opc.normalize
  result.cmd =
    case result.opc
    of "sug": ideSug
    of "con": ideCon
    of "def": ideDef
    of "use": ideUse
    of "dus": ideDus
    of "chk": ideChk
    of "highlight": ideHighlight
    of "known": ideKnown
    of "project": ideProject
    of "changed": ideChanged
    of "globalsymbols": ideGlobalSymbols
    of "declaration": ideDeclaration
    of "expand": ideExpand
    of "chkfile": ideChkFile
    of "recompile": ideRecompile
    of "type": ideType
    of "inlayhints": ideInlayHints
    of "outline2": ideOutline2
    else: ideNone
  i += skipWhitespace(cmd, i)
  if i < cmd.len and cmd[i] in {'0'..'9'}:
    result.file = string conf.projectFull
  else:
    i = parseQuoted(cmd, result.file, i)
    if i < cmd.len and cmd[i] == ';':
      i = parseQuoted(cmd, result.dirty, i+1)
    i += skipWhile(cmd, seps, i)
  i += parseInt(cmd, result.line, i)
  i += skipWhile(cmd, seps, i)
  i += parseInt(cmd, result.col, i)
  result.tag = substr(cmd, i)

const SourceIdentChars = IdentChars + {'\x80'..'\xFF'}

proc sourceLine(src: var Table[FileIndex, seq[string]]; conf: ConfigRef;
                fileIdx: FileIndex; line: int): string =
  if fileIdx notin src:
    src[fileIdx] =
      try: readFile(toFullPath(conf, fileIdx)).splitLines
      except IOError: @[]
  let lines = src[fileIdx]
  result = if line in 1..lines.len: lines[line - 1] else: ""

proc identAround(text: string; col: int): tuple[ident: string, start: int] =
  ## The identifier of `text` that `col` is in.
  if col < 0 or col >= text.len or text[col] notin SourceIdentChars: return ("", col)
  var a = col
  while a > 0 and text[a - 1] in SourceIdentChars: dec a
  var b = col
  while b < text.len and text[b] in SourceIdentChars: inc b
  result = (text.substr(a, b - 1), a)

proc symAtPos(graph: ModuleGraph; n: PNode; target: TLineInfo; ident: string): PSym =
  ## The symbol named `ident` that `n` has at `target`.
  result = nil
  if n == nil: return
  if n.kind == nkSym:
    if n.info.fileIndex == target.fileIndex and n.info.line == target.line and
        n.info.col <= target.col and target.col <= n.info.col + ident.len and
        cmpIgnoreStyle(n.sym.name.s, ident) == 0:
      result = n.sym
    return
  if nfLazyBody in n.flags and forceLazyBodyHook != nil: forceLazyBodyHook(n)
  for i in 0..<n.safeLen:
    result = graph.symAtPos(n[i], target, ident)
    if result != nil: return

proc answerFromNif(graph: ModuleGraph; q: Query): bool =
  ## Answers `highlight`, `def`, `use` and `dus` about a saved file whose NIF
  ## is fresh from the NIFs, without compiling or loading the import closure:
  ## the loader opens the NIFs the symbols need. False when they cannot.
  let conf = graph.config
  let cmd = q.cmd
  if cmd notin {ideHighlight, ideDef, ideUse, ideDus} or q.dirty.len > 0 or
      graph.icNifIsStale(gRoot):
    return false
  var src = initTable[FileIndex, seq[string]]()
  let fileIdx = fileInfoIdx(conf, AbsoluteFile q.file)
  let ident = identAround(src.sourceLine(conf, fileIdx, q.line), q.col).ident
  if ident.len == 0: return false
  let target = newLineInfo(fileIdx, q.line, q.col)
  let bif = toNifFilename(conf, gRoot)
  let at = ideSymAt(conf, bif, target, ident)
  if at.name.len == 0 or (cmd != ideDef and isFieldNifName(at.name)): return false
  var sym = resolveHookSym(ast.program, at.name)
  if sym == nil:
    for r in at.routines:
      let owner = resolveHookSym(ast.program, r)
      if owner != nil and owner.kind in routineKinds:
        sym = graph.symAtPos(owner.ast, target, ident)
        if sym != nil: break
  if sym == nil or cmpIgnoreStyle(sym.name.s, ident) != 0: return false
  myLog fmt "answering {q.opc} from NIF: {at.name}"

  var infos = @[sym.info]
  if cmd != ideDef:
    infos.add ideOccurrences(conf, bif, at.name)
  if cmd in {ideUse, ideDus}:
    for m in gNsModules:
      let other = toNifFilename(conf, fileInfoIdx(conf, AbsoluteFile m))
      if other != bif: infos.add ideOccurrences(conf, other, at.name)
  var found: seq[TLineInfo] = @[]
  for info in infos:
    if cmd == ideHighlight and info.fileIndex != fileIdx: continue
    let (id, start) = identAround(src.sourceLine(conf, info.fileIndex, info.line.int), info.col)
    if start == info.col and cmpIgnoreStyle(id, sym.name.s) == 0 and
        not found.anyIt(it.exactEquals(info)):
      found.add info
  if found.len == 0: return false
  found.sort(proc (a, b: TLineInfo): int =
    cmp((a.fileIndex.int32, a.line, a.col), (b.fileIndex.int32, b.line, b.col)))
  conf.ideCmd = cmd
  for info in found:
    graph.suggestResult(sym, info)
  result = true

proc isKnown(graph: ModuleGraph; fileIdx: FileIndex): bool =
  ## Whether `nim ns` built `fileIdx`, or a module including it.
  toFullPath(graph.config, fileIdx) in gNsModules or
    graph.inclToMod.hasKey(fileIdx) or graph.registerIncluderFromNif(fileIdx)

proc queryRoot(graph: ModuleGraph; q: Query): FileIndex =
  ## The module a command compiles: the project's main file for the commands
  ## about the whole project (`chk`, `globalSymbols`, `recompile`) or when it
  ## names no file; otherwise the file it names or the module including it.
  let conf = graph.config
  if q.cmd in {ideChk, ideGlobalSymbols, ideRecompile} or q.file.len == 0:
    return fileInfoIdx(conf, conf.projectFull)
  let fileIdx = fileInfoIdx(conf, AbsoluteFile q.file)
  if not graph.isIcVerified(toFullPath(conf, fileIdx)) and
      graph.needsIncludeScan(fileIdx):
    discard graph.registerIncluderFromNif(fileIdx)
  result = if graph.inclToMod.hasKey(fileIdx): graph.parentModule(fileIdx) else: fileIdx

proc processCmdLine(pass: TCmdLinePass, cmd: string; conf: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      case p.key.normalize
      of "help", "h":
        stdout.writeLine(Usage)
        quit()
      of "one-shot", "autobind", "port", "address", "clientprocessid",
          "v1", "v2", "v3", "v4":
        discard
      of "debug": incl(conf.globalOptions, optIdeDebug)
      of "info":
        case p.val.normalize
        of "protocolver":
          stdout.writeLine(HighestSuggestProtocolVersion)
          quit 0
        of "nimver":
          stdout.writeLine(system.NimVersion)
          quit 0
        of "capabilities":
          stdout.writeLine(Capabilities.join(" "))
          quit 0
        else:
          processSwitch(pass, p, conf)
      of "log": gLogging = true
      of "maxresults":
        conf.suggestMaxResults = parseInt(p.val)
      else: processSwitch(pass, p, conf)
    of cmdArgument:
      let a = unixToNativePath(p.key)
      if dirExists(a) and not fileExists(a.addFileExt("nim")):
        conf.projectName = findProjectNimFile(conf, a)
        if conf.projectName.len == 0: conf.projectName = a
      else:
        conf.projectName = a

proc oneShot*() =
  ## `nimsuggest2 --one-shot`: answers the command read from stdin and exits.
  ## Every module is loaded from the NIFs `nim ns` left in the nimcache, then
  ## the module the command names is compiled from source like an import: no
  ## module is the main module. `changed` runs `nim ns`, and so does any
  ## command once a file it read was saved after its last run (a branch switch,
  ## an edit outside the editor) or the config changed. A command about a file
  ## `nim ns` did not build makes the file one of its roots and runs it.
  let
    cache = newIdentCache()
    conf = newConfigRef()
    self = NimProg(suggestMode: true, processCmdLine: processCmdLine)
  conf.suggestVersion = 4
  self.initDefinesProg(conf, "nimsuggest")
  self.processCmdLineAndProjectPath(conf)
  conf.ideActive = true
  let preReport = nsReport(conf)
  var configChanged = false
  if fileExists(preReport):
    for line in readFile(preReport).splitLines:
      if line.startsWith("icconfig:") and line.len > "icconfig:".len:
        let config = line.substr("icconfig:".len)
        configChanged = sourcesChanged(config)
        if not configChanged: conf.icPreparsedConfig = config
  conf.writelnHook = proc (msg: string) = discard
  conf.prefixDir = conf.getPrefixDir()
  let graph = newModuleGraph(cache, conf)
  if not self.loadConfigsAndProcessCmdLine(cache, conf, graph): quit 1
  if conf.selectedGC == gcUnselected and
      conf.backend != backendJs and optWasNimscript notin conf.globalOptions:
    initOrcDefines(conf)
  conf.ideImportsFromNif = true
  conf.ideNsNifs = true
  conf.setCmd(cmdM)
  conf.ideActive = true
  defineSymbol(conf.symbols, $conf.backend)
  setPipeLinePass(graph, SemPass)
  wantMainModule(conf)
  if not fileExists(conf.projectFull):
    quit "cannot find file: " & conf.projectFull.string
  add(conf.searchPaths, conf.libpath)

  let line = stdin.readLine()
  myLog "one-shot: " & line
  let q = parseQuery(line, conf)
  let report = nsReport(conf)
  var roots = nsRoots(report)
  if q.cmd == ideChanged or configChanged or not fileExists(report) or
      changedSince(report):
    runNimNs(graph, roots)
  useNsReport(graph, readFile(report))
  case q.opc
  of "changed", "recompile", "quit":
    quit 0
  of "project":
    echo conf.projectFull.string
    quit 0
  of "known":
    echo graph.isKnown(fileInfoIdx(conf, AbsoluteFile q.file))
    quit 0
  else: discard
  if q.cmd == ideNone:
    echo Help
    quit 0
  if q.cmd notin {ideChk, ideGlobalSymbols, ideRecompile, ideOutline2} and
      q.file.endsWith(".nim") and fileExists(q.file):
    let fileIdx = fileInfoIdx(conf, AbsoluteFile q.file)
    if not graph.isKnown(fileIdx):
      roots.add toFullPath(conf, fileIdx)
      runNimNs(graph, roots)
      useNsReport(graph, readFile(report))

  conf.setErrorMaxHighMaybe
  conf.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
    let suggest = Suggest(section: ideChk, filePath: toFullPath(conf, info),
      line: toLinenumber(info), column: toColumn(info), doc: msg, forth: $sev)
    graph.suggestErrors.mgetOrPut(info.fileIndex, @[]).add suggest
  conf.suggestionResultHook = proc (s: Suggest) = echo s
  gRoot = graph.queryRoot(q)
  if graph.answerFromNif(q): quit 0

  let fileIndex =
    if q.cmd == ideGlobalSymbols: InvalidFileIdx
    else: fileInfoIdx(conf, AbsoluteFile q.file)
  conf.ideCmd = q.cmd
  conf.m.trackPos = TLineInfo(fileIndex: trackPosInvalidFileIdx)
  case q.cmd
  of ideSug, ideCon:
    conf.m.trackPos = newLineInfo(fileIndex, q.line, q.col)
    conf.m.trackPosAttached = false
  of ideExpand:
    var level = high(int)
    let trimmed = substr(q.tag, skipWhitespace(q.tag, 0))
    if trimmed notin ["", "all"]:
      discard parseInt(trimmed, level, 0)
    conf.expandPosition = newLineInfo(fileIndex, q.line, q.col)
    conf.expandLevels = level
    conf.expandProgress = false
    conf.expandNodeResult = ""
  else: discard
  if fileIndex != InvalidFileIdx:
    msgs.setDirtyFile(conf, fileIndex, AbsoluteFile q.dirty)
  if q.cmd != ideOutline2:
    graph.compileRoot()
  graph.answer(q.cmd, q.file, fileIndex, q.line, q.col, q.tag)
  quit 0
