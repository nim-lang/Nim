#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nimsuggest is a tool that helps to give editors IDE like capabilities.

when not defined(nimcore):
  {.error: "nimcore MUST be defined for Nim's core tooling".}

import strutils, os, parseopt, parseutils, sequtils, net, rdstdin, sexp
# Do NOT import suggest. It will lead to weird bugs with
# suggestionResultHook, because suggest.nim is included by sigmatch.
# So we import that one instead.
import compiler / [options, commands, modules, sem,
  passes, passaux, msgs,
  sigmatch, ast,
  idents, modulegraphs, prefixmatches, lineinfos, cmdlinehelper,
  pathutils]

when defined(windows):
  import winlean
else:
  import posix

const DummyEof = "!EOF!"
const Usage = """
Nimsuggest - Tool to give every editor IDE like capabilities for Nim
Usage:
  nimsuggest [options] projectfile.nim

Options:
  --autobind              automatically binds into a free port
  --port:PORT             port, by default 6000
  --address:HOST          binds to that address, by default ""
  --stdin                 read commands from stdin and write results to
                          stdout instead of using sockets
  --epc                   use emacs epc mode
  --debug                 enable debug output
  --log                   enable verbose logging to nimsuggest.log file
  --v1                    use version 1 of the protocol; for backwards compatibility
  --refresh               perform automatic refreshes to keep the analysis precise
  --maxresults:N          limit the number of suggestions to N
  --tester                implies --stdin and outputs a line
                          '""" & DummyEof & """' for the tester
  --find                  attempts to find the project file of the current project

The server then listens to the connection and takes line-based commands.

If --autobind is used, the binded port number will be printed to stdout.

In addition, all command line options of Nim that do not affect code generation
are supported.
"""
type
  Mode = enum mstdin, mtcp, mepc, mcmdsug, mcmdcon
  CachedMsg = object
    info: TLineInfo
    msg: string
    sev: Severity
  CachedMsgs = seq[CachedMsg]

var
  gPort = 6000.Port
  gAddress = ""
  gMode: Mode
  gEmitEof: bool # whether we write '!EOF!' dummy lines
  gLogging = defined(logging)
  gRefresh: bool
  gAutoBind = false

  requests: Channel[string]
  results: Channel[Suggest]

proc writelnToChannel(line: string) =
  results.send(Suggest(section: ideMsg, doc: line))

proc sugResultHook(s: Suggest) =
  results.send(s)

proc errorHook(conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
  results.send(Suggest(section: ideChk, filePath: toFullPath(conf, info),
    line: toLinenumber(info), column: toColumn(info), doc: msg,
    forth: $sev))

proc myLog(s: string) =
  if gLogging: log(s)

const
  seps = {':', ';', ' ', '\t'}
  Help = "usage: sug|con|def|use|dus|chk|mod|highlight|outline|known|project file.nim[;dirtyfile.nim]:line:col\n" &
         "type 'quit' to quit\n" &
         "type 'debug' to toggle debug mode on/off\n" &
         "type 'terse' to toggle terse mode on/off"

proc parseQuoted(cmd: string; outp: var string; start: int): int =
  var i = start
  i += skipWhitespace(cmd, i)
  if i < cmd.len and cmd[i] == '"':
    i += parseUntil(cmd, outp, '"', i+1)+2
  else:
    i += parseUntil(cmd, outp, seps, i)
  result = i

proc sexp(s: IdeCmd|TSymKind|PrefixMatch): SexpNode = sexp($s)

proc sexp(s: Suggest): SexpNode =
  # If you change the order here, make sure to change it over in
  # nim-mode.el too.
  let qp = if s.qualifiedPath.len == 0: @[] else: s.qualifiedPath
  result = convertSexp([
    s.section,
    TSymKind s.symkind,
    qp.map(newSString),
    s.filePath,
    s.forth,
    s.line,
    s.column,
    s.doc,
    s.quality
  ])
  if s.section == ideSug:
    result.add convertSexp(s.prefix)

proc sexp(s: seq[Suggest]): SexpNode =
  result = newSList()
  for sug in s:
    result.add(sexp(sug))

proc listEpc(): SexpNode =
  # This function is called from Emacs to show available options.
  let
    argspecs = sexp("file line column dirtyfile".split(" ").map(newSSymbol))
    docstring = sexp("line starts at 1, column at 0, dirtyfile is optional")
  result = newSList()
  for command in ["sug", "con", "def", "use", "dus", "chk", "mod"]:
    let
      cmd = sexp(command)
      methodDesc = newSList()
    methodDesc.add(cmd)
    methodDesc.add(argspecs)
    methodDesc.add(docstring)
    result.add(methodDesc)

proc findNode(n: PNode; trackPos: TLineInfo): PSym =
  #echo "checking node ", n.info
  if n.kind == nkSym:
    if isTracked(n.info, trackPos, n.sym.name.s.len): return n.sym
  else:
    for i in 0 ..< safeLen(n):
      let res = findNode(n[i], trackPos)
      if res != nil: return res

proc symFromInfo(graph: ModuleGraph; trackPos: TLineInfo): PSym =
  let m = graph.getModule(trackPos.fileIndex)
  if m != nil and m.ast != nil:
    result = findNode(m.ast, trackPos)

proc executeNoHooks(cmd: IdeCmd, file, dirtyfile: AbsoluteFile, line, col: int;
             graph: ModuleGraph) =
  let conf = graph.config
  myLog("cmd: " & $cmd & ", file: " & file.string &
        ", dirtyFile: " & dirtyfile.string &
        "[" & $line & ":" & $col & "]")
  conf.ideCmd = cmd
  if cmd == ideUse and conf.suggestVersion != 0:
    graph.resetAllModules()
  var isKnownFile = true
  let dirtyIdx = fileInfoIdx(conf, file, isKnownFile)

  if not dirtyfile.isEmpty: msgs.setDirtyFile(conf, dirtyIdx, dirtyfile)
  else: msgs.setDirtyFile(conf, dirtyIdx, AbsoluteFile"")

  conf.m.trackPos = newLineInfo(dirtyIdx, line, col)
  conf.m.trackPosAttached = false
  conf.errorCounter = 0
  if conf.suggestVersion == 1:
    graph.usageSym = nil
  if not isKnownFile:
    graph.compileProject(dirtyIdx)
  if conf.suggestVersion == 0 and conf.ideCmd in {ideUse, ideDus} and
      dirtyfile.isEmpty:
    discard "no need to recompile anything"
  else:
    let modIdx = graph.parentModule(dirtyIdx)
    graph.markDirty dirtyIdx
    graph.markClientsDirty dirtyIdx
    if conf.ideCmd != ideMod:
      if isKnownFile:
        graph.compileProject(modIdx)
  if conf.ideCmd in {ideUse, ideDus}:
    let u = if conf.suggestVersion != 1: graph.symFromInfo(conf.m.trackPos) else: graph.usageSym
    if u != nil:
      listUsages(graph, u)
    else:
      localError(conf, conf.m.trackPos, "found no symbol at this position " & (conf $ conf.m.trackPos))

proc execute(cmd: IdeCmd, file, dirtyfile: AbsoluteFile, line, col: int;
             graph: ModuleGraph) =
  if cmd == ideChk:
    graph.config.structuredErrorHook = errorHook
    graph.config.writelnHook = myLog
  else:
    graph.config.structuredErrorHook = nil
    graph.config.writelnHook = myLog
  executeNoHooks(cmd, file, dirtyfile, line, col, graph)

proc executeEpc(cmd: IdeCmd, args: SexpNode;
                graph: ModuleGraph) =
  let
    file = AbsoluteFile args[0].getStr
    line = args[1].getNum
    column = args[2].getNum
  var dirtyfile = AbsoluteFile""
  if len(args) > 3:
    dirtyfile = AbsoluteFile args[3].getStr("")
  execute(cmd, file, dirtyfile, int(line), int(column), graph)

proc returnEpc(socket: Socket, uid: BiggestInt, s: SexpNode|string,
               returnSymbol = "return") =
  let response = $convertSexp([newSSymbol(returnSymbol), uid, s])
  socket.send(toHex(len(response), 6))
  socket.send(response)

template checkSanity(client, sizeHex, size, messageBuffer: typed) =
  if client.recv(sizeHex, 6) != 6:
    raise newException(ValueError, "didn't get all the hexbytes")
  if parseHex(sizeHex, size) == 0:
    raise newException(ValueError, "invalid size hex: " & $sizeHex)
  if client.recv(messageBuffer, size) != size:
    raise newException(ValueError, "didn't get all the bytes")

proc toStdout() {.gcsafe.} =
  while true:
    let res = results.recv()
    case res.section
    of ideNone: break
    of ideMsg: echo res.doc
    of ideKnown: echo res.quality == 1
    of ideProject: echo res.filePath
    else: echo res

proc toSocket(stdoutSocket: Socket) {.gcsafe.} =
  while true:
    let res = results.recv()
    case res.section
    of ideNone: break
    of ideMsg: stdoutSocket.send(res.doc & "\c\L")
    of ideKnown: stdoutSocket.send($(res.quality == 1) & "\c\L")
    of ideProject: stdoutSocket.send(res.filePath & "\c\L")
    else: stdoutSocket.send($res & "\c\L")

proc toEpc(client: Socket; uid: BiggestInt) {.gcsafe.} =
  var list = newSList()
  while true:
    let res = results.recv()
    case res.section
    of ideNone: break
    of ideMsg:
      list.add sexp(res.doc)
    of ideKnown:
      list.add sexp(res.quality == 1)
    of ideProject:
      list.add sexp(res.filePath)
    else:
      list.add sexp(res)
  returnEpc(client, uid, list)

template setVerbosity(level: typed) =
  gVerbosity = level
  conf.notes = NotesVerbosity[gVerbosity]

proc connectToNextFreePort(server: Socket, host: string): Port =
  server.bindAddr(Port(0), host)
  let (_, port) = server.getLocalAddr
  result = port

type
  ThreadParams = tuple[port: Port; address: string]

proc replStdinSingleCmd(line: string) =
  requests.send line
  toStdout()
  echo ""
  flushFile(stdout)

proc replStdin(x: ThreadParams) {.thread.} =
  if gEmitEof:
    echo DummyEof
    while true:
      let line = readLine(stdin)
      requests.send line
      if line == "quit": break
      toStdout()
      echo DummyEof
      flushFile(stdout)
  else:
    echo Help
    var line = ""
    while readLineFromStdin("> ", line):
      replStdinSingleCmd(line)
    requests.send "quit"

proc replCmdline(x: ThreadParams) {.thread.} =
  replStdinSingleCmd(x.address)
  requests.send "quit"

proc replTcp(x: ThreadParams) {.thread.} =
  var server = newSocket()
  if gAutoBind:
    let port = server.connectToNextFreePort(x.address)
    server.listen()
    echo port
    stdout.flushFile()
  else:
    server.bindAddr(x.port, x.address)
    server.listen()
  var inp = ""
  var stdoutSocket: Socket
  while true:
    accept(server, stdoutSocket)

    stdoutSocket.readLine(inp)
    requests.send inp
    toSocket(stdoutSocket)
    stdoutSocket.send("\c\L")
    stdoutSocket.close()

proc argsToStr(x: SexpNode): string =
  if x.kind != SList: return x.getStr
  doAssert x.kind == SList
  doAssert x.len >= 4
  let file = x[0].getStr
  let line = x[1].getNum
  let col = x[2].getNum
  let dirty = x[3].getStr
  result = x[0].getStr.escape
  if dirty.len > 0:
    result.add ';'
    result.add dirty.escape
  result.add ':'
  result.addInt line
  result.add ':'
  result.addInt col

proc replEpc(x: ThreadParams) {.thread.} =
  var server = newSocket()
  let port = connectToNextFreePort(server, "localhost")
  server.listen()
  echo port
  stdout.flushFile()

  var client: Socket
  # Wait for connection
  accept(server, client)
  while true:
    var
      sizeHex = ""
      size = 0
      messageBuffer = ""
    checkSanity(client, sizeHex, size, messageBuffer)
    let
      message = parseSexp($messageBuffer)
      epcApi = message[0].getSymbol
    case epcApi
    of "call":
      let
        uid = message[1].getNum
        cmd = message[2].getSymbol
        args = message[3]

      when false:
        x.ideCmd[] = parseIdeCmd(message[2].getSymbol)
        case x.ideCmd[]
        of ideSug, ideCon, ideDef, ideUse, ideDus, ideOutline, ideHighlight:
          setVerbosity(0)
        else: discard
      let fullCmd = cmd & " " & args.argsToStr
      myLog "MSG CMD: " & fullCmd
      requests.send(fullCmd)
      toEpc(client, uid)
    of "methods":
      returnEpc(client, message[1].getNum, listEpc())
    of "epc-error":
      # an unhandled exception forces down the whole process anyway, so we
      # use 'quit' here instead of 'raise'
      quit("received epc error: " & $messageBuffer)
    else:
      let errMessage = case epcApi
                       of "return", "return-error":
                         "no return expected"
                       else:
                         "unexpected call: " & epcApi
      quit errMessage

proc execCmd(cmd: string; graph: ModuleGraph; cachedMsgs: CachedMsgs) =
  let conf = graph.config

  template sentinel() =
    # send sentinel for the input reading thread:
    results.send(Suggest(section: ideNone))

  template toggle(sw) =
    if sw in conf.globalOptions:
      excl(conf.globalOptions, sw)
    else:
      incl(conf.globalOptions, sw)
    sentinel()
    return

  template err() =
    echo Help
    sentinel()
    return

  var opc = ""
  var i = parseIdent(cmd, opc, 0)
  case opc.normalize
  of "sug": conf.ideCmd = ideSug
  of "con": conf.ideCmd = ideCon
  of "def": conf.ideCmd = ideDef
  of "use": conf.ideCmd = ideUse
  of "dus": conf.ideCmd = ideDus
  of "mod": conf.ideCmd = ideMod
  of "chk": conf.ideCmd = ideChk
  of "highlight": conf.ideCmd = ideHighlight
  of "outline": conf.ideCmd = ideOutline
  of "quit":
    sentinel()
    quit()
  of "debug": toggle optIdeDebug
  of "terse": toggle optIdeTerse
  of "known": conf.ideCmd = ideKnown
  of "project": conf.ideCmd = ideProject
  else: err()
  var dirtyfile = ""
  var orig = ""
  i += skipWhitespace(cmd, i)
  if i < cmd.len and cmd[i] in {'0'..'9'}:
    orig = string conf.projectFull
  else:
    i = parseQuoted(cmd, orig, i)
    if i < cmd.len and cmd[i] == ';':
      i = parseQuoted(cmd, dirtyfile, i+1)
    i += skipWhile(cmd, seps, i)
  var line = 0
  var col = -1
  i += parseInt(cmd, line, i)
  i += skipWhile(cmd, seps, i)
  i += parseInt(cmd, col, i)

  if conf.ideCmd == ideKnown:
    results.send(Suggest(section: ideKnown, quality: ord(fileInfoKnown(conf, AbsoluteFile orig))))
  elif conf.ideCmd == ideProject:
    results.send(Suggest(section: ideProject, filePath: string conf.projectFull))
  else:
    if conf.ideCmd == ideChk:
      for cm in cachedMsgs: errorHook(conf, cm.info, cm.msg, cm.sev)
    execute(conf.ideCmd, AbsoluteFile orig, AbsoluteFile dirtyfile, line, col, graph)
  sentinel()

proc recompileFullProject(graph: ModuleGraph) =
  #echo "recompiling full project"
  resetSystemArtifacts(graph)
  graph.vm = nil
  graph.resetAllModules()
  GC_fullCollect()
  compileProject(graph)
  #echo GC_getStatistics()

proc mainThread(graph: ModuleGraph) =
  let conf = graph.config
  if gLogging:
    for it in conf.searchPaths:
      log(it.string)

  proc wrHook(line: string) {.closure.} =
    if gMode == mepc:
      if gLogging: log(line)
    else:
      writelnToChannel(line)

  conf.writelnHook = wrHook
  conf.suggestionResultHook = sugResultHook
  graph.doStopCompile = proc (): bool = requests.peek() > 0
  var idle = 0
  var cachedMsgs: CachedMsgs = @[]
  while true:
    let (hasData, req) = requests.tryRecv()
    if hasData:
      conf.writelnHook = wrHook
      conf.suggestionResultHook = sugResultHook
      execCmd(req, graph, cachedMsgs)
      idle = 0
    else:
      os.sleep 250
      idle += 1
    if idle == 20 and gRefresh:
      # we use some nimsuggest activity to enable a lazy recompile:
      conf.ideCmd = ideChk
      conf.writelnHook = proc (s: string) = discard
      cachedMsgs.setLen 0
      conf.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
        cachedMsgs.add(CachedMsg(info: info, msg: msg, sev: sev))
      conf.suggestionResultHook = proc (s: Suggest) = discard
      recompileFullProject(graph)

var
  inputThread: Thread[ThreadParams]

proc mainCommand(graph: ModuleGraph) =
  let conf = graph.config
  clearPasses(graph)
  registerPass graph, verbosePass
  registerPass graph, semPass
  conf.setCmd cmdIdeTools
  wantMainModule(conf)

  if not fileExists(conf.projectFull):
    quit "cannot find file: " & conf.projectFull.string

  add(conf.searchPaths, conf.libpath)

  conf.setErrorMaxHighMaybe # honor --errorMax even if it may not make sense here
  # do not print errors, but log them
  conf.writelnHook = myLog
  conf.structuredErrorHook = nil

  # compile the project before showing any input so that we already
  # can answer questions right away:
  compileProject(graph)

  open(requests)
  open(results)

  case gMode
  of mstdin: createThread(inputThread, replStdin, (gPort, gAddress))
  of mtcp: createThread(inputThread, replTcp, (gPort, gAddress))
  of mepc: createThread(inputThread, replEpc, (gPort, gAddress))
  of mcmdsug: createThread(inputThread, replCmdline,
                            (gPort, "sug \"" & conf.projectFull.string & "\":" & gAddress))
  of mcmdcon: createThread(inputThread, replCmdline,
                            (gPort, "con \"" & conf.projectFull.string & "\":" & gAddress))
  mainThread(graph)
  joinThread(inputThread)
  close(requests)
  close(results)

proc processCmdLine*(pass: TCmdLinePass, cmd: string; conf: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var findProject = false
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      case p.key.normalize
      of "help", "h":
        stdout.writeLine(Usage)
        quit()
      of "autobind":
        gMode = mtcp
        gAutoBind = true
      of "port":
        gPort = parseInt(p.val).Port
        gMode = mtcp
      of "address":
        gAddress = p.val
        gMode = mtcp
      of "stdin": gMode = mstdin
      of "cmdsug":
        gMode = mcmdsug
        gAddress = p.val
        incl(conf.globalOptions, optIdeDebug)
      of "cmdcon":
        gMode = mcmdcon
        gAddress = p.val
        incl(conf.globalOptions, optIdeDebug)
      of "epc":
        gMode = mepc
        conf.verbosity = 0          # Port number gotta be first.
      of "debug": incl(conf.globalOptions, optIdeDebug)
      of "v2": conf.suggestVersion = 0
      of "v1": conf.suggestVersion = 1
      of "tester":
        gMode = mstdin
        gEmitEof = true
        gRefresh = false
      of "log": gLogging = true
      of "refresh":
        if p.val.len > 0:
          gRefresh = parseBool(p.val)
        else:
          gRefresh = true
      of "maxresults":
        conf.suggestMaxResults = parseInt(p.val)
      of "find":
        findProject = true
      else: processSwitch(pass, p, conf)
    of cmdArgument:
      let a = unixToNativePath(p.key)
      if dirExists(a) and not fileExists(a.addFileExt("nim")):
        conf.projectName = findProjectNimFile(conf, a)
        # don't make it worse, report the error the old way:
        if conf.projectName.len == 0: conf.projectName = a
      else:
        if findProject:
          conf.projectName = findProjectNimFile(conf, a.parentDir())
          if conf.projectName.len == 0:
            conf.projectName = a
        else:
          conf.projectName = a
      # if processArgument(pass, p, argsCount): break

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    suggestMode: true,
    processCmdLine: processCmdLine
  )
  self.initDefinesProg(conf, "nimsuggest")

  if paramCount() == 0:
    stdout.writeLine(Usage)
    return

  self.processCmdLineAndProjectPath(conf)

  if gMode != mstdin:
    conf.writelnHook = proc (msg: string) = discard
  # Find Nim's prefix dir.
  let binaryPath = findExe("nim")
  if binaryPath == "":
    raise newException(IOError,
        "Cannot find Nim standard library: Nim compiler not in PATH")
  conf.prefixDir = AbsoluteDir binaryPath.splitPath().head.parentDir()
  if not dirExists(conf.prefixDir / RelativeDir"lib"):
    conf.prefixDir = AbsoluteDir""

  #msgs.writelnHook = proc (line: string) = log(line)
  myLog("START " & conf.projectFull.string)

  var graph = newModuleGraph(cache, conf)
  if self.loadConfigsAndProcessCmdLine(cache, conf, graph):
    mainCommand(graph)

when isMainModule:
  handleCmdLine(newIdentCache(), newConfigRef())
else:
  export Suggest
  export IdeCmd
  export AbsoluteFile
  type NimSuggest* = ref object
    graph: ModuleGraph
    idle: int
    cachedMsgs: CachedMsgs

  proc initNimSuggest*(project: string, nimPath: string = ""): NimSuggest =
    var retval: ModuleGraph
    proc mockCommand(graph: ModuleGraph) =
      retval = graph
      let conf = graph.config
      clearPasses(graph)
      registerPass graph, verbosePass
      registerPass graph, semPass
      conf.setCmd cmdIdeTools
      wantMainModule(conf)

      if not fileExists(conf.projectFull):
        quit "cannot find file: " & conf.projectFull.string

      add(conf.searchPaths, conf.libpath)

      conf.setErrorMaxHighMaybe
      # do not print errors, but log them
      conf.writelnHook = myLog
      conf.structuredErrorHook = nil

      # compile the project before showing any input so that we already
      # can answer questions right away:
      compileProject(graph)


    proc mockCmdLine(pass: TCmdLinePass, cmd: string; conf: ConfigRef) =
      conf.suggestVersion = 0
      let a = unixToNativePath(project)
      if dirExists(a) and not fileExists(a.addFileExt("nim")):
        conf.projectName = findProjectNimFile(conf, a)
        # don't make it worse, report the error the old way:
        if conf.projectName.len == 0: conf.projectName = a
      else:
        conf.projectName = a
          # if processArgument(pass, p, argsCount): break
    let
      cache = newIdentCache()
      conf = newConfigRef()
      self = NimProg(
        suggestMode: true,
        processCmdLine: mockCmdLine
      )
    self.initDefinesProg(conf, "nimsuggest")

    self.processCmdLineAndProjectPath(conf)

    if gMode != mstdin:
      conf.writelnHook = proc (msg: string) = discard
    # Find Nim's prefix dir.
    if nimPath == "":
      let binaryPath = findExe("nim")
      if binaryPath == "":
        raise newException(IOError,
            "Cannot find Nim standard library: Nim compiler not in PATH")
      conf.prefixDir = AbsoluteDir binaryPath.splitPath().head.parentDir()
      if not dirExists(conf.prefixDir / RelativeDir"lib"):
        conf.prefixDir = AbsoluteDir""
    else:
      conf.prefixDir = AbsoluteDir nimPath

    #msgs.writelnHook = proc (line: string) = log(line)
    myLog("START " & conf.projectFull.string)

    var graph = newModuleGraph(cache, conf)
    if self.loadConfigsAndProcessCmdLine(cache, conf, graph):
      mockCommand(graph)
    if gLogging:
      for it in conf.searchPaths:
        log(it.string)

    retval.doStopCompile = proc (): bool = false
    return NimSuggest(graph: retval, idle: 0, cachedMsgs: @[])

  proc runCmd*(nimsuggest: NimSuggest, cmd: IdeCmd, file, dirtyfile: AbsoluteFile, line, col: int): seq[Suggest] =
    var retval: seq[Suggest] = @[]
    let conf = nimsuggest.graph.config
    conf.ideCmd = cmd
    conf.writelnHook = proc (line: string) =
      retval.add(Suggest(section: ideMsg, doc: line))
    conf.suggestionResultHook = proc (s: Suggest) =
      retval.add(s)
    conf.writelnHook = proc (s: string) =
      stderr.write s & "\n"
    if conf.ideCmd == ideKnown:
      retval.add(Suggest(section: ideKnown, quality: ord(fileInfoKnown(conf, file))))
    elif conf.ideCmd == ideProject:
      retval.add(Suggest(section: ideProject, filePath: string conf.projectFull))
    else:
      if conf.ideCmd == ideChk:
        for cm in nimsuggest.cachedMsgs: errorHook(conf, cm.info, cm.msg, cm.sev)
      if conf.ideCmd == ideChk:
        conf.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
          retval.add(Suggest(section: ideChk, filePath: toFullPath(conf, info),
            line: toLinenumber(info), column: toColumn(info), doc: msg,
            forth: $sev))

      else:
        conf.structuredErrorHook = nil
      executeNoHooks(conf.ideCmd, file, dirtyfile, line, col, nimsuggest.graph)
    return retval
