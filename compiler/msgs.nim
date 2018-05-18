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
  configuration

#type
#  MsgConfig* = ref object of RootObj

type
  TFileInfo* = object
    fullPath: string           # This is a canonical full filesystem path
    projPath*: string          # This is relative to the project's root
    shortName*: string         # short name of the module
    quotedName*: Rope          # cached quoted short name for codegen
                               # purposes
    quotedFullName*: Rope      # cached quoted full name for codegen
                               # purposes

    lines*: seq[Rope]          # the source code of the module
                               #   used for better error messages and
                               #   embedding the original source in the
                               #   generated code
    dirtyfile: string          # the file that is actually read into memory
                               # and parsed; usually 'nil' but is used
                               # for 'nimsuggest'
    hash*: string              # the checksum of the file
    when defined(nimpretty):
      fullContent*: string
  FileIndex* = distinct int32
  TLineInfo* = object          # This is designed to be as small as possible,
                               # because it is used
                               # in syntax nodes. We save space here by using
                               # two int16 and an int32.
                               # On 64 bit and on 32 bit systems this is
                               # only 8 bytes.
    line*: uint16
    col*: int16
    fileIndex*: FileIndex
    when defined(nimpretty):
      offsetA*, offsetB*: int
      commentOffsetA*, commentOffsetB*: int

  TErrorOutput* = enum
    eStdOut
    eStdErr

  TErrorOutputs* = set[TErrorOutput]

  ERecoverableError* = object of ValueError
  ESuggestDone* = object of Exception

proc `==`*(a, b: FileIndex): bool {.borrow.}


const
  InvalidFileIDX* = FileIndex(-1)

var
  filenameToIndexTbl = initTable[string, FileIndex]()
  fileInfos*: seq[TFileInfo] = @[]
  systemFileIdx*: FileIndex

proc toCChar*(c: char): string =
  case c
  of '\0'..'\x1F', '\x7F'..'\xFF': result = '\\' & toOctal(c)
  of '\'', '\"', '\\', '?': result = '\\' & c
  else: result = $(c)

proc makeCString*(s: string): Rope =
  const
    MaxLineLength = 64
  result = nil
  var res = newStringOfCap(int(s.len.toFloat * 1.1) + 1)
  add(res, "\"")
  for i in countup(0, len(s) - 1):
    if (i + 1) mod MaxLineLength == 0:
      add(res, '\"')
      add(res, '\L')
      add(res, '\"')
    add(res, toCChar(s[i]))
  add(res, '\"')
  add(result, rope(res))


proc newFileInfo(fullPath, projPath: string): TFileInfo =
  result.fullPath = fullPath
  #shallow(result.fullPath)
  result.projPath = projPath
  #shallow(result.projPath)
  let fileName = projPath.extractFilename
  result.shortName = fileName.changeFileExt("")
  result.quotedName = fileName.makeCString
  result.quotedFullName = fullPath.makeCString
  result.lines = @[]
  when defined(nimpretty):
    if result.fullPath.len > 0:
      try:
        result.fullContent = readFile(result.fullPath)
      except IOError:
        #rawMessage(errCannotOpenFile, result.fullPath)
        # XXX fixme
        result.fullContent = ""

when defined(nimpretty):
  proc fileSection*(fid: FileIndex; a, b: int): string =
    substr(fileInfos[fid.int].fullContent, a, b)

proc fileInfoKnown*(conf: ConfigRef; filename: string): bool =
  var
    canon: string
  try:
    canon = canonicalizePath(conf, filename)
  except:
    canon = filename
  result = filenameToIndexTbl.hasKey(canon)

proc fileInfoIdx*(conf: ConfigRef; filename: string; isKnownFile: var bool): FileIndex =
  var
    canon: string
    pseudoPath = false

  try:
    canon = canonicalizePath(conf, filename)
    shallow(canon)
  except:
    canon = filename
    # The compiler uses "filenames" such as `command line` or `stdin`
    # This flag indicates that we are working with such a path here
    pseudoPath = true

  if filenameToIndexTbl.hasKey(canon):
    result = filenameToIndexTbl[canon]
  else:
    isKnownFile = false
    result = fileInfos.len.FileIndex
    fileInfos.add(newFileInfo(canon, if pseudoPath: filename
                                     else: shortenDir(conf, canon)))
    filenameToIndexTbl[canon] = result

proc fileInfoIdx*(conf: ConfigRef; filename: string): FileIndex =
  var dummy: bool
  result = fileInfoIdx(conf, filename, dummy)

proc newLineInfo*(fileInfoIdx: FileIndex, line, col: int): TLineInfo =
  result.fileIndex = fileInfoIdx
  result.line = uint16(line)
  result.col = int16(col)

proc newLineInfo*(conf: ConfigRef; filename: string, line, col: int): TLineInfo {.inline.} =
  result = newLineInfo(fileInfoIdx(conf, filename), line, col)

proc raiseRecoverableError*(msg: string) {.noinline, noreturn.} =
  raise newException(ERecoverableError, msg)

proc sourceLine*(conf: ConfigRef; i: TLineInfo): Rope

proc unknownLineInfo*(): TLineInfo =
  result.line = uint16(0)
  result.col = int16(-1)
  result.fileIndex = InvalidFileIDX

type
  Severity* {.pure.} = enum ## VS Code only supports these three
    Hint, Warning, Error

var
  msgContext: seq[TLineInfo] = @[]
  lastError = unknownLineInfo()

  errorOutputs* = {eStdOut, eStdErr}
  writelnHook*: proc (output: string) {.closure.}
  structuredErrorHook*: proc (config: ConfigRef; info: TLineInfo; msg: string; severity: Severity) {.closure.}

proc concat(strings: openarray[string]): string =
  var totalLen = 0
  for s in strings: totalLen += s.len
  result = newStringOfCap totalLen
  for s in strings: result.add s

proc suggestWriteln*(s: string) =
  if eStdOut in errorOutputs:
    if isNil(writelnHook):
      writeLine(stdout, s)
      flushFile(stdout)
    else:
      writelnHook(s)

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

proc getInfoContextLen*(): int = return msgContext.len
proc setInfoContextLen*(L: int) = setLen(msgContext, L)

proc pushInfoContext*(info: TLineInfo) =
  msgContext.add(info)

proc popInfoContext*() =
  setLen(msgContext, len(msgContext) - 1)

proc getInfoContext*(index: int): TLineInfo =
  let L = msgContext.len
  let i = if index < 0: L + index else: index
  if i >=% L: result = unknownLineInfo()
  else: result = msgContext[i]

template toFilename*(conf: ConfigRef; fileIdx: FileIndex): string =
  (if fileIdx.int32 < 0: "???" else: fileInfos[fileIdx.int32].projPath)

proc toFullPath*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0: result = "???"
  else: result = fileInfos[fileIdx.int32].fullPath

proc setDirtyFile*(conf: ConfigRef; fileIdx: FileIndex; filename: string) =
  assert fileIdx.int32 >= 0
  fileInfos[fileIdx.int32].dirtyFile = filename

proc setHash*(conf: ConfigRef; fileIdx: FileIndex; hash: string) =
  assert fileIdx.int32 >= 0
  shallowCopy(fileInfos[fileIdx.int32].hash, hash)

proc getHash*(conf: ConfigRef; fileIdx: FileIndex): string =
  assert fileIdx.int32 >= 0
  shallowCopy(result, fileInfos[fileIdx.int32].hash)

proc toFullPathConsiderDirty*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0:
    result = "???"
  elif not fileInfos[fileIdx.int32].dirtyFile.isNil:
    result = fileInfos[fileIdx.int32].dirtyFile
  else:
    result = fileInfos[fileIdx.int32].fullPath

template toFilename*(conf: ConfigRef; info: TLineInfo): string =
  toFilename(conf, info.fileIndex)

template toFullPath*(conf: ConfigRef; info: TLineInfo): string =
  toFullPath(conf, info.fileIndex)

proc toMsgFilename*(conf: ConfigRef; info: TLineInfo): string =
  if info.fileIndex.int32 < 0:
    result = "???"
  elif optListFullPaths in conf.globalOptions:
    result = fileInfos[info.fileIndex.int32].fullPath
  else:
    result = fileInfos[info.fileIndex.int32].projPath

proc toLinenumber*(info: TLineInfo): int {.inline.} =
  result = int info.line

proc toColumn*(info: TLineInfo): int {.inline.} =
  result = info.col

proc toFileLine*(conf: ConfigRef; info: TLineInfo): string {.inline.} =
  result = toFilename(conf, info) & ":" & $info.line

proc toFileLineCol*(conf: ConfigRef; info: TLineInfo): string {.inline.} =
  result = toFilename(conf, info) & "(" & $info.line & ", " & $info.col & ")"

proc `$`*(conf: ConfigRef; info: TLineInfo): string = toFileLineCol(conf, info)

proc `$`*(info: TLineInfo): string {.error.} = discard

proc `??`* (conf: ConfigRef; info: TLineInfo, filename: string): bool =
  # only for debugging purposes
  result = filename in toFilename(conf, info)

const trackPosInvalidFileIdx* = FileIndex(-2) # special marker so that no suggestions
                                   # are produced within comments and string literals
var gTrackPos*: TLineInfo
var gTrackPosAttached*: bool ## whether the tracking position was attached to some
                             ## close token.

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

  if not isNil(writelnHook) and msgSkipHook notin flags:
    writelnHook(s)
  elif optStdout in conf.globalOptions or msgStdout in flags:
    if eStdOut in errorOutputs:
      writeLine(stdout, s)
      flushFile(stdout)
  else:
    if eStdErr in errorOutputs:
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
  writelnHook concat(args)

template styledMsgWriteln*(args: varargs[typed]) =
  if not isNil(writelnHook):
    callIgnoringStyle(callWritelnHook, nil, args)
  elif optStdout in conf.globalOptions:
    if eStdOut in errorOutputs:
      callIgnoringStyle(writeLine, stdout, args)
      flushFile(stdout)
  else:
    if eStdErr in errorOutputs:
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

proc quit(conf: ConfigRef; msg: TMsgKind) =
  if defined(debug) or msg == errInternal or hintStackTrace in conf.notes:
    if stackTraceAvailable() and isNil(writelnHook):
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
  var info = lastinfo
  for i in countup(0, len(msgContext) - 1):
    if msgContext[i] != lastinfo and msgContext[i] != info:
      if structuredErrorHook != nil:
        structuredErrorHook(conf, msgContext[i], instantiationFrom,
                            Severity.Error)
      else:
        styledMsgWriteln(styleBright,
                         PosFormat % [toMsgFilename(conf, msgContext[i]),
                                      coordToStr(msgContext[i].line.int),
                                      coordToStr(msgContext[i].col+1)],
                         resetStyle,
                         instantiationFrom)
    info = msgContext[i]

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

  if structuredErrorHook != nil:
    structuredErrorHook(conf, unknownLineInfo(), s & (if kind != nil: KindFormat % kind else: ""), sev)

  if not ignoreMsgBecauseOfIdeTools(conf, msg):
    if kind != nil:
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
                        coordToStr(info.col+1)] &
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
    lastError = info
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
  # NOTE: currently line info line numbers start with 1,
  # but column numbers start with 0, however most editors expect
  # first column to be 1, so we need to +1 here
  let x = PosFormat % [toMsgFilename(conf, info), coordToStr(info.line.int),
                       coordToStr(info.col+1)]
  let s = getMessageStr(msg, arg)

  if not ignoreMsg:
    if structuredErrorHook != nil:
      structuredErrorHook(conf, info, s & (if kind != nil: KindFormat % kind else: ""), sev)
    if not ignoreMsgBecauseOfIdeTools(conf, msg):
      if kind != nil:
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
  errorOutputs = {eStdOut, eStdErr}
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
  if conf.cmd == cmdIdeTools and structuredErrorHook.isNil: return
  writeContext(conf, info)
  liMessage(conf, info, errInternal, errMsg, doAbort)

proc internalError*(conf: ConfigRef; errMsg: string) =
  if conf.cmd == cmdIdeTools and structuredErrorHook.isNil: return
  writeContext(conf, unknownLineInfo())
  rawMessage(conf, errInternal, errMsg)

template assertNotNil*(conf: ConfigRef; e): untyped =
  if e == nil: internalError(conf, $instantiationInfo())
  e

template internalAssert*(conf: ConfigRef, e: bool) =
  if not e: internalError(conf, $instantiationInfo())

proc addSourceLine*(conf: ConfigRef; fileIdx: FileIndex, line: string) =
  fileInfos[fileIdx.int32].lines.add line.rope

proc sourceLine*(conf: ConfigRef; i: TLineInfo): Rope =
  if i.fileIndex.int32 < 0: return nil

  if not optPreserveOrigSource(conf) and fileInfos[i.fileIndex.int32].lines.len == 0:
    try:
      for line in lines(toFullPath(conf, i)):
        addSourceLine conf, i.fileIndex, line.string
    except IOError:
      discard
  assert i.fileIndex.int32 < fileInfos.len
  # can happen if the error points to EOF:
  if i.line.int > fileInfos[i.fileIndex.int32].lines.len: return nil

  result = fileInfos[i.fileIndex.int32].lines[i.line.int-1]

proc quotedFilename*(conf: ConfigRef; i: TLineInfo): Rope =
  assert i.fileIndex.int32 >= 0
  if optExcessiveStackTrace in conf.globalOptions:
    result = fileInfos[i.fileIndex.int32].quotedFullName
  else:
    result = fileInfos[i.fileIndex.int32].quotedName

proc listWarnings*(conf: ConfigRef) =
  msgWriteln(conf, "Warnings:")
  for warn in warnMin..warnMax:
    msgWriteln(conf, "  [$1] $2" % [
      if warn in conf.notes: "x" else: " ",
      configuration.WarningsToStr[ord(warn) - ord(warnMin)]
    ])

proc listHints*(conf: ConfigRef) =
  msgWriteln(conf, "Hints:")
  for hint in hintMin..hintMax:
    msgWriteln(conf, "  [$1] $2" % [
      if hint in conf.notes: "x" else: " ",
      configuration.HintsToStr[ord(hint) - ord(hintMin)]
    ])
