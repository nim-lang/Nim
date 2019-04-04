#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  options, strutils, os, tables, ropes, platform, terminal, macros,
  lineinfos, pathutils

proc toCChar*(c: char; result: var string) =
  case c
  of '\0'..'\x1F', '\x7F'..'\xFF':
    result.add '\\'
    result.add toOctal(c)
  of '\'', '\"', '\\', '?':
    result.add '\\'
    result.add c
  else:
    result.add c

proc makeCString*(s: string): Rope =
  const MaxLineLength = 64
  result = nil
  var res = newStringOfCap(int(s.len.toFloat * 1.1) + 1)
  add(res, "\"")
  for i in countup(0, len(s) - 1):
    if (i + 1) mod MaxLineLength == 0:
      add(res, "\"\L\"")
    toCChar(s[i], res)
  add(res, '\"')
  add(result, rope(res))


proc newFileInfo(fullPath: AbsoluteFile, projPath: RelativeFile): TFileInfo =
  result.fullPath = fullPath
  #shallow(result.fullPath)
  result.projPath = projPath
  #shallow(result.projPath)
  let fileName = fullPath.extractFilename
  result.shortName = fileName.changeFileExt("")
  result.quotedName = fileName.makeCString
  result.quotedFullName = fullPath.string.makeCString
  result.lines = @[]
  when defined(nimpretty):
    if not result.fullPath.isEmpty:
      try:
        result.fullContent = readFile(result.fullPath.string)
      except IOError:
        #rawMessage(errCannotOpenFile, result.fullPath)
        # XXX fixme
        result.fullContent = ""

when defined(nimpretty):
  proc fileSection*(conf: ConfigRef; fid: FileIndex; a, b: int): string =
    substr(conf.m.fileInfos[fid.int].fullContent, a, b)

proc fileInfoKnown*(conf: ConfigRef; filename: AbsoluteFile): bool =
  var
    canon: AbsoluteFile
  try:
    canon = canonicalizePath(conf, filename)
  except OSError:
    canon = filename
  result = conf.m.filenameToIndexTbl.hasKey(canon.string)

proc fileInfoIdx*(conf: ConfigRef; filename: AbsoluteFile; isKnownFile: var bool): FileIndex =
  var
    canon: AbsoluteFile
    pseudoPath = false

  try:
    canon = canonicalizePath(conf, filename)
    shallow(canon.string)
  except OSError:
    canon = filename
    # The compiler uses "filenames" such as `command line` or `stdin`
    # This flag indicates that we are working with such a path here
    pseudoPath = true

  if conf.m.filenameToIndexTbl.hasKey(canon.string):
    result = conf.m.filenameToIndexTbl[canon.string]
  else:
    isKnownFile = false
    result = conf.m.fileInfos.len.FileIndex
    conf.m.fileInfos.add(newFileInfo(canon, if pseudoPath: RelativeFile filename
                                            else: relativeTo(canon, conf.projectPath)))
    conf.m.filenameToIndexTbl[canon.string] = result

proc fileInfoIdx*(conf: ConfigRef; filename: AbsoluteFile): FileIndex =
  var dummy: bool
  result = fileInfoIdx(conf, filename, dummy)

proc newLineInfo*(fileInfoIdx: FileIndex, line, col: int): TLineInfo =
  result.fileIndex = fileInfoIdx
  result.line = uint16(line)
  result.col = int16(col)

proc newLineInfo*(conf: ConfigRef; filename: AbsoluteFile, line, col: int): TLineInfo {.inline.} =
  result = newLineInfo(fileInfoIdx(conf, filename), line, col)


proc concat(strings: openarray[string]): string =
  var totalLen = 0
  for s in strings: totalLen += s.len
  result = newStringOfCap totalLen
  for s in strings: result.add s

proc suggestWriteln*(conf: ConfigRef; s: string) =
  if eStdOut in conf.m.errorOutputs:
    if isNil(conf.writelnHook):
      writeLine(stdout, s)
      flushFile(stdout)
    else:
      conf.writelnHook(s)

proc msgQuit*(x: int8) = quit x
proc msgQuit*(x: string) = quit x

proc suggestQuit*() =
  raise newException(ESuggestDone, "suggest done")

# this format is understood by many text editors: it is the same that
# Borland and Freepascal use
const
  PosFormat    = "$1($2, $3) "
  KindFormat   = " [$1]"
  KindColor    = fgCyan
  ErrorTitle   = "Error: "
  ErrorColor   = fgRed
  WarningTitle = "Warning: "
  WarningColor = fgYellow
  HintTitle    = "Hint: "
  HintColor    = fgGreen
  # NOTE: currently line info line numbers start with 1,
  # but column numbers start with 0, however most editors expect
  # first column to be 1, so we need to +1 here
  ColOffset*   = 1

proc getInfoContextLen*(conf: ConfigRef): int = return conf.m.msgContext.len
proc setInfoContextLen*(conf: ConfigRef; L: int) = setLen(conf.m.msgContext, L)

proc pushInfoContext*(conf: ConfigRef; info: TLineInfo; detail: string = "") =
  conf.m.msgContext.add((info, detail))

proc popInfoContext*(conf: ConfigRef) =
  setLen(conf.m.msgContext, len(conf.m.msgContext) - 1)

proc getInfoContext*(conf: ConfigRef; index: int): TLineInfo =
  let L = conf.m.msgContext.len
  let i = if index < 0: L + index else: index
  if i >=% L: result = unknownLineInfo()
  else: result = conf.m.msgContext[i].info

template toFilename*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0 or conf == nil:
    "???"
  else:
    if optListFullPaths in conf.globalOptions:
      conf.m.fileInfos[fileIdx.int32].fullPath.string
    else:
      conf.m.fileInfos[fileIdx.int32].projPath.string

proc toFullPath*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0 or conf == nil: result = "???"
  else: result = conf.m.fileInfos[fileIdx.int32].fullPath.string

proc setDirtyFile*(conf: ConfigRef; fileIdx: FileIndex; filename: AbsoluteFile) =
  assert fileIdx.int32 >= 0
  conf.m.fileInfos[fileIdx.int32].dirtyFile = filename
  setLen conf.m.fileInfos[fileIdx.int32].lines, 0

proc setHash*(conf: ConfigRef; fileIdx: FileIndex; hash: string) =
  assert fileIdx.int32 >= 0
  shallowCopy(conf.m.fileInfos[fileIdx.int32].hash, hash)

proc getHash*(conf: ConfigRef; fileIdx: FileIndex): string =
  assert fileIdx.int32 >= 0
  shallowCopy(result, conf.m.fileInfos[fileIdx.int32].hash)

proc toFullPathConsiderDirty*(conf: ConfigRef; fileIdx: FileIndex): AbsoluteFile =
  if fileIdx.int32 < 0:
    result = AbsoluteFile"???"
  elif not conf.m.fileInfos[fileIdx.int32].dirtyFile.isEmpty:
    result = conf.m.fileInfos[fileIdx.int32].dirtyFile
  else:
    result = conf.m.fileInfos[fileIdx.int32].fullPath

template toFilename*(conf: ConfigRef; info: TLineInfo): string =
  toFilename(conf, info.fileIndex)

template toFullPath*(conf: ConfigRef; info: TLineInfo): string =
  toFullPath(conf, info.fileIndex)

template toFullPathConsiderDirty*(conf: ConfigRef; info: TLineInfo): string =
  string toFullPathConsiderDirty(conf, info.fileIndex)

proc toMsgFilename*(conf: ConfigRef; info: TLineInfo): string =
  if info.fileIndex.int32 < 0:
    result = "???"
    return
  let absPath = conf.m.fileInfos[info.fileIndex.int32].fullPath.string
  if optListFullPaths in conf.globalOptions:
    result = absPath
  else:
    let relPath = conf.m.fileInfos[info.fileIndex.int32].projPath.string
    result = if relPath.count("..") > 2: absPath else: relPath

proc toLinenumber*(info: TLineInfo): int {.inline.} =
  result = int info.line

proc toColumn*(info: TLineInfo): int {.inline.} =
  result = info.col

proc toFileLine*(conf: ConfigRef; info: TLineInfo): string {.inline.} =
  result = toFilename(conf, info) & ":" & $info.line

proc toFileLineCol*(conf: ConfigRef; info: TLineInfo): string {.inline.} =
  # consider calling `helpers.lineInfoToString` instead
  result = toFilename(conf, info) & "(" & $info.line & ", " &
    $(info.col + ColOffset) & ")"

proc `$`*(conf: ConfigRef; info: TLineInfo): string = toFileLineCol(conf, info)

proc `$`*(info: TLineInfo): string {.error.} = discard

proc `??`* (conf: ConfigRef; info: TLineInfo, filename: string): bool =
  # only for debugging purposes
  result = filename in toFilename(conf, info)

type
  MsgFlag* = enum  ## flags altering msgWriteln behavior
    msgStdout,     ## force writing to stdout, even stderr is default
    msgSkipHook    ## skip message hook even if it is present
  MsgFlags* = set[MsgFlag]

proc msgWriteln*(conf: ConfigRef; s: string, flags: MsgFlags = {}) =
  ## Writes given message string to stderr by default.
  ## If ``--stdout`` option is given, writes to stdout instead. If message hook
  ## is present, then it is used to output message rather than stderr/stdout.
  ## This behavior can be altered by given optional flags.

  ## This is used for 'nim dump' etc. where we don't have nimsuggest
  ## support.
  #if conf.cmd == cmdIdeTools and optCDebug notin gGlobalOptions: return

  if not isNil(conf.writelnHook) and msgSkipHook notin flags:
    conf.writelnHook(s)
  elif optStdout in conf.globalOptions or msgStdout in flags:
    if eStdOut in conf.m.errorOutputs:
      writeLine(stdout, s)
      flushFile(stdout)
  else:
    if eStdErr in conf.m.errorOutputs:
      writeLine(stderr, s)
      # On Windows stderr is fully-buffered when piped, regardless of C std.
      when defined(windows):
        flushFile(stderr)

macro callIgnoringStyle(theProc: typed, first: typed,
                        args: varargs[typed]): untyped =
  let typForegroundColor = bindSym"ForegroundColor".getType
  let typBackgroundColor = bindSym"BackgroundColor".getType
  let typStyle = bindSym"Style".getType
  let typTerminalCmd = bindSym"TerminalCmd".getType
  result = newCall(theProc)
  if first.kind != nnkNilLit: result.add(first)
  for arg in children(args[0][1]):
    if arg.kind == nnkNilLit: continue
    let typ = arg.getType
    if typ.kind != nnkEnumTy or
       typ != typForegroundColor and
       typ != typBackgroundColor and
       typ != typStyle and
       typ != typTerminalCmd:
      result.add(arg)

macro callStyledWriteLineStderr(args: varargs[typed]): untyped =
  result = newCall(bindSym"styledWriteLine")
  result.add(bindSym"stderr")
  for arg in children(args[0][1]):
    result.add(arg)

template callWritelnHook(args: varargs[string, `$`]) =
  conf.writelnHook concat(args)

template styledMsgWriteln*(args: varargs[typed]) =
  if not isNil(conf.writelnHook):
    callIgnoringStyle(callWritelnHook, nil, args)
  elif optStdout in conf.globalOptions:
    if eStdOut in conf.m.errorOutputs:
      callIgnoringStyle(writeLine, stdout, args)
      flushFile(stdout)
  else:
    if eStdErr in conf.m.errorOutputs:
      if optUseColors in conf.globalOptions:
        callStyledWriteLineStderr(args)
      else:
        callIgnoringStyle(writeLine, stderr, args)
      # On Windows stderr is fully-buffered when piped, regardless of C std.
      when defined(windows):
        flushFile(stderr)

proc coordToStr(coord: int): string =
  if coord == -1: result = "???"
  else: result = $coord

proc msgKindToString*(kind: TMsgKind): string =
  # later versions may provide translated error messages
  result = MsgKindToStr[kind]

proc getMessageStr(msg: TMsgKind, arg: string): string =
  result = msgKindToString(msg) % [arg]

type
  TErrorHandling = enum doNothing, doAbort, doRaise

proc log*(s: string) {.procvar.} =
  var f: File
  if open(f, getHomeDir() / "nimsuggest.log", fmAppend):
    f.writeLine(s)
    close(f)

proc quit(conf: ConfigRef; msg: TMsgKind) {.gcsafe.} =
  if defined(debug) or msg == errInternal or hintStackTrace in conf.notes:
    {.gcsafe.}:
      if stackTraceAvailable() and isNil(conf.writelnHook):
        writeStackTrace()
      else:
        styledMsgWriteln(fgRed, "No stack traceback available\n" &
            "To create a stacktrace, rerun compilation with ./koch temp " &
            conf.command & " <file>")
  quit 1

proc handleError(conf: ConfigRef; msg: TMsgKind, eh: TErrorHandling, s: string) =
  if msg >= fatalMin and msg <= fatalMax:
    if conf.cmd == cmdIdeTools: log(s)
    quit(conf, msg)
  if msg >= errMin and msg <= errMax:
    inc(conf.errorCounter)
    conf.exitcode = 1'i8
    if conf.errorCounter >= conf.errorMax:
      quit(conf, msg)
    elif eh == doAbort and conf.cmd != cmdIdeTools:
      quit(conf, msg)
    elif eh == doRaise:
      raiseRecoverableError(s)

proc `==`*(a, b: TLineInfo): bool =
  result = a.line == b.line and a.fileIndex == b.fileIndex

proc exactEquals*(a, b: TLineInfo): bool =
  result = a.fileIndex == b.fileIndex and a.line == b.line and a.col == b.col

proc writeContext(conf: ConfigRef; lastinfo: TLineInfo) =
  const instantiationFrom = "template/generic instantiation from here"
  const instantiationOfFrom = "template/generic instantiation of `$1` from here"
  var info = lastinfo
  for i in 0 ..< len(conf.m.msgContext):
    let context = conf.m.msgContext[i]
    if context.info != lastinfo and context.info != info:
      if conf.structuredErrorHook != nil:
        conf.structuredErrorHook(conf, context.info, instantiationFrom,
                                 Severity.Error)
      else:
        let message = if context.detail == "":
          instantiationFrom
        else:
          instantiationOfFrom.format(context.detail)
        styledMsgWriteln(styleBright,
                         PosFormat % [toMsgFilename(conf, context.info),
                                      coordToStr(context.info.line.int),
                                      coordToStr(context.info.col+ColOffset)],
                         resetStyle,
                         message)
    info = context.info

proc ignoreMsgBecauseOfIdeTools(conf: ConfigRef; msg: TMsgKind): bool =
  msg >= errGenerated and conf.cmd == cmdIdeTools and optIdeDebug notin conf.globalOptions

proc rawMessage*(conf: ConfigRef; msg: TMsgKind, args: openArray[string]) =
  var
    title: string
    color: ForegroundColor
    kind: string
    sev: Severity
  case msg
  of errMin..errMax:
    sev = Severity.Error
    writeContext(conf, unknownLineInfo())
    title = ErrorTitle
    color = ErrorColor
  of warnMin..warnMax:
    sev = Severity.Warning
    if optWarns notin conf.options: return
    if msg notin conf.notes: return
    writeContext(conf, unknownLineInfo())
    title = WarningTitle
    color = WarningColor
    kind = WarningsToStr[ord(msg) - ord(warnMin)]
    inc(conf.warnCounter)
  of hintMin..hintMax:
    sev = Severity.Hint
    if optHints notin conf.options: return
    if msg notin conf.notes: return
    title = HintTitle
    color = HintColor
    if msg != hintUserRaw: kind = HintsToStr[ord(msg) - ord(hintMin)]
    inc(conf.hintCounter)
  let s = msgKindToString(msg) % args

  if conf.structuredErrorHook != nil:
    conf.structuredErrorHook(conf, unknownLineInfo(),
      s & (if kind.len > 0: KindFormat % kind else: ""), sev)

  if not ignoreMsgBecauseOfIdeTools(conf, msg):
    if kind.len > 0:
      styledMsgWriteln(color, title, resetStyle, s,
                       KindColor, `%`(KindFormat, kind))
    else:
      styledMsgWriteln(color, title, resetStyle, s)
  handleError(conf, msg, doAbort, s)

proc rawMessage*(conf: ConfigRef; msg: TMsgKind, arg: string) =
  rawMessage(conf, msg, [arg])

proc resetAttributes*(conf: ConfigRef) =
  if {optUseColors, optStdout} * conf.globalOptions == {optUseColors}:
    terminal.resetAttributes(stderr)

proc addSourceLine(conf: ConfigRef; fileIdx: FileIndex, line: string) =
  conf.m.fileInfos[fileIdx.int32].lines.add line

proc sourceLine*(conf: ConfigRef; i: TLineInfo): string =
  if i.fileIndex.int32 < 0: return ""

  if conf.m.fileInfos[i.fileIndex.int32].lines.len == 0:
    try:
      for line in lines(toFullPathConsiderDirty(conf, i)):
        addSourceLine conf, i.fileIndex, line.string
    except IOError:
      discard
  assert i.fileIndex.int32 < conf.m.fileInfos.len
  # can happen if the error points to EOF:
  if i.line.int > conf.m.fileInfos[i.fileIndex.int32].lines.len: return ""

  result = conf.m.fileInfos[i.fileIndex.int32].lines[i.line.int-1]

proc writeSurroundingSrc(conf: ConfigRef; info: TLineInfo) =
  const indent = "  "
  msgWriteln(conf, indent & $sourceLine(conf, info))
  msgWriteln(conf, indent & spaces(info.col) & '^')

proc formatMsg*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg: string): string =
  let title = case msg
              of warnMin..warnMax: WarningTitle
              of hintMin..hintMax: HintTitle
              else: ErrorTitle
  result = PosFormat % [toMsgFilename(conf, info), coordToStr(info.line.int),
                        coordToStr(info.col+ColOffset)] &
           title &
           getMessageStr(msg, arg)

proc liMessage(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg: string,
               eh: TErrorHandling) =
  var
    title: string
    color: ForegroundColor
    kind:  string
    ignoreMsg = false
    sev: Severity
  case msg
  of errMin..errMax:
    sev = Severity.Error
    writeContext(conf, info)
    title = ErrorTitle
    color = ErrorColor
    # we try to filter error messages so that not two error message
    # in the same file and line are produced:
    #ignoreMsg = lastError == info and eh != doAbort
    conf.m.lastError = info
  of warnMin..warnMax:
    sev = Severity.Warning
    ignoreMsg = optWarns notin conf.options or msg notin conf.notes
    if not ignoreMsg: writeContext(conf, info)
    title = WarningTitle
    color = WarningColor
    kind = WarningsToStr[ord(msg) - ord(warnMin)]
    inc(conf.warnCounter)
  of hintMin..hintMax:
    sev = Severity.Hint
    ignoreMsg = optHints notin conf.options or msg notin conf.notes
    title = HintTitle
    color = HintColor
    if msg != hintUserRaw: kind = HintsToStr[ord(msg) - ord(hintMin)]
    inc(conf.hintCounter)
  let x = PosFormat % [toMsgFilename(conf, info), coordToStr(info.line.int),
                       coordToStr(info.col+ColOffset)]
  let s = getMessageStr(msg, arg)

  if not ignoreMsg:
    if conf.structuredErrorHook != nil:
      conf.structuredErrorHook(conf, info, s & (if kind.len > 0: KindFormat % kind else: ""), sev)
    if not ignoreMsgBecauseOfIdeTools(conf, msg):
      if kind.len > 0:
        styledMsgWriteln(styleBright, x, resetStyle, color, title, resetStyle, s,
                         KindColor, `%`(KindFormat, kind))
      else:
        styledMsgWriteln(styleBright, x, resetStyle, color, title, resetStyle, s)
      if hintSource in conf.notes:
        conf.writeSurroundingSrc(info)
  handleError(conf, msg, eh, s)

proc fatal*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  # this fixes bug #7080 so that it is at least obvious 'fatal'
  # was executed.
  conf.m.errorOutputs = {eStdOut, eStdErr}
  liMessage(conf, info, msg, arg, doAbort)

proc globalError*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doRaise)

proc globalError*(conf: ConfigRef; info: TLineInfo, arg: string) =
  liMessage(conf, info, errGenerated, arg, doRaise)

proc localError*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doNothing)

proc localError*(conf: ConfigRef; info: TLineInfo, arg: string) =
  liMessage(conf, info, errGenerated, arg, doNothing)

proc localError*(conf: ConfigRef; info: TLineInfo, format: string, params: openarray[string]) =
  localError(conf, info, format % params)

proc message*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doNothing)

proc internalError*(conf: ConfigRef; info: TLineInfo, errMsg: string) =
  if conf.cmd == cmdIdeTools and conf.structuredErrorHook.isNil: return
  writeContext(conf, info)
  liMessage(conf, info, errInternal, errMsg, doAbort)

proc internalError*(conf: ConfigRef; errMsg: string) =
  if conf.cmd == cmdIdeTools and conf.structuredErrorHook.isNil: return
  writeContext(conf, unknownLineInfo())
  rawMessage(conf, errInternal, errMsg)

template assertNotNil*(conf: ConfigRef; e): untyped =
  if e == nil: internalError(conf, $instantiationInfo())
  e

template internalAssert*(conf: ConfigRef, e: bool) =
  if not e: internalError(conf, $instantiationInfo())

proc quotedFilename*(conf: ConfigRef; i: TLineInfo): Rope =
  assert i.fileIndex.int32 >= 0
  if optExcessiveStackTrace in conf.globalOptions:
    result = conf.m.fileInfos[i.fileIndex.int32].quotedFullName
  else:
    result = conf.m.fileInfos[i.fileIndex.int32].quotedName

proc listWarnings*(conf: ConfigRef) =
  msgWriteln(conf, "Warnings:")
  for warn in warnMin..warnMax:
    msgWriteln(conf, "  [$1] $2" % [
      if warn in conf.notes: "x" else: " ",
      lineinfos.WarningsToStr[ord(warn) - ord(warnMin)]
    ])

proc listHints*(conf: ConfigRef) =
  msgWriteln(conf, "Hints:")
  for hint in hintMin..hintMax:
    msgWriteln(conf, "  [$1] $2" % [
      if hint in conf.notes: "x" else: " ",
      lineinfos.HintsToStr[ord(hint) - ord(hintMin)]
    ])
