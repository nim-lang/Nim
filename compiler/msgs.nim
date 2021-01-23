#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  options, strutils, os, tables, ropes, terminal, macros,
  lineinfos, pathutils
import std/private/miscdollars
import strutils2

type InstantiationInfo* = typeof(instantiationInfo())
template instLoc(): InstantiationInfo = instantiationInfo(-2, fullPaths = true)

template toStdOrrKind(stdOrr): untyped =
  if stdOrr == stdout: stdOrrStdout else: stdOrrStderr

proc flushDot*(conf: ConfigRef) =
  ## safe to call multiple times
  # xxx one edge case not yet handled is when `printf` is called at CT with `compiletimeFFI`.
  let stdOrr = if optStdout in conf.globalOptions: stdout else: stderr
  let stdOrrKind = toStdOrrKind(stdOrr)
  if stdOrrKind in conf.lastMsgWasDot:
    conf.lastMsgWasDot.excl stdOrrKind
    write(stdOrr, "\n")

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
  result = nil
  var res = newStringOfCap(int(s.len.toFloat * 1.1) + 1)
  res.add("\"")
  for i in 0..<s.len:
    # line wrapping of string litterals in cgen'd code was a bad idea, e.g. causes: bug #16265
    # It also makes reading c sources or grepping harder, for zero benefit.
    # const MaxLineLength = 64
    # if (i + 1) mod MaxLineLength == 0:
    #   res.add("\"\L\"")
    toCChar(s[i], res)
  res.add('\"')
  result.add(rope(res))

proc newFileInfo(fullPath: AbsoluteFile, projPath: RelativeFile): TFileInfo =
  result.fullPath = fullPath
  #shallow(result.fullPath)
  result.projPath = projPath
  #shallow(result.projPath)
  result.shortName = fullPath.extractFilename
  result.quotedName = result.shortName.makeCString
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

proc canonicalCase(path: var string) =
  ## the idea is to only use this for checking whether a path is already in
  ## the table but otherwise keep the original case
  when FileSystemCaseSensitive: discard
  else: toLowerAscii(path)

proc fileInfoKnown*(conf: ConfigRef; filename: AbsoluteFile): bool =
  var
    canon: AbsoluteFile
  try:
    canon = canonicalizePath(conf, filename)
  except OSError:
    canon = filename
  canon.string.canonicalCase
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

  var canon2: string
  forceCopy(canon2, canon.string) # because `canon` may be shallow
  canon2.canonicalCase

  if conf.m.filenameToIndexTbl.hasKey(canon2):
    isKnownFile = true
    result = conf.m.filenameToIndexTbl[canon2]
  else:
    isKnownFile = false
    result = conf.m.fileInfos.len.FileIndex
    conf.m.fileInfos.add(newFileInfo(canon, if pseudoPath: RelativeFile filename
                                            else: relativeTo(canon, conf.projectPath)))
    conf.m.filenameToIndexTbl[canon2] = result

proc fileInfoIdx*(conf: ConfigRef; filename: AbsoluteFile): FileIndex =
  var dummy: bool
  result = fileInfoIdx(conf, filename, dummy)

proc newLineInfo*(fileInfoIdx: FileIndex, line, col: int): TLineInfo =
  result.fileIndex = fileInfoIdx
  if line < int high(uint16):
    result.line = uint16(line)
  else:
    result.line = high(uint16)
  if col < int high(int16):
    result.col = int16(col)
  else:
    result.col = -1

proc newLineInfo*(conf: ConfigRef; filename: AbsoluteFile, line, col: int): TLineInfo {.inline.} =
  result = newLineInfo(fileInfoIdx(conf, filename), line, col)

const gCmdLineInfo* = newLineInfo(commandLineIdx, 1, 1)

proc concat(strings: openArray[string]): string =
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
  commandLineDesc* = "command line"

proc getInfoContextLen*(conf: ConfigRef): int = return conf.m.msgContext.len
proc setInfoContextLen*(conf: ConfigRef; L: int) = setLen(conf.m.msgContext, L)

proc pushInfoContext*(conf: ConfigRef; info: TLineInfo; detail: string = "") =
  conf.m.msgContext.add((info, detail))

proc popInfoContext*(conf: ConfigRef) =
  setLen(conf.m.msgContext, conf.m.msgContext.len - 1)

proc getInfoContext*(conf: ConfigRef; index: int): TLineInfo =
  let i = if index < 0: conf.m.msgContext.len + index else: index
  if i >=% conf.m.msgContext.len: result = unknownLineInfo
  else: result = conf.m.msgContext[i].info

template toFilename*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0 or conf == nil:
    (if fileIdx == commandLineIdx: commandLineDesc else: "???")
  else:
    conf.m.fileInfos[fileIdx.int32].shortName

proc toProjPath*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0 or conf == nil:
    (if fileIdx == commandLineIdx: commandLineDesc else: "???")
  else: conf.m.fileInfos[fileIdx.int32].projPath.string

proc toFullPath*(conf: ConfigRef; fileIdx: FileIndex): string =
  if fileIdx.int32 < 0 or conf == nil:
    result = (if fileIdx == commandLineIdx: commandLineDesc else: "???")
  else:
    result = conf.m.fileInfos[fileIdx.int32].fullPath.string

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
    result = AbsoluteFile(if fileIdx == commandLineIdx: commandLineDesc else: "???")
  elif not conf.m.fileInfos[fileIdx.int32].dirtyFile.isEmpty:
    result = conf.m.fileInfos[fileIdx.int32].dirtyFile
  else:
    result = conf.m.fileInfos[fileIdx.int32].fullPath

template toFilename*(conf: ConfigRef; info: TLineInfo): string =
  toFilename(conf, info.fileIndex)

template toProjPath*(conf: ConfigRef; info: TLineInfo): string =
  toProjPath(conf, info.fileIndex)

template toFullPath*(conf: ConfigRef; info: TLineInfo): string =
  toFullPath(conf, info.fileIndex)

template toFullPathConsiderDirty*(conf: ConfigRef; info: TLineInfo): string =
  string toFullPathConsiderDirty(conf, info.fileIndex)

type FilenameOption* = enum
  foAbs # absolute path, e.g.: /pathto/bar/foo.nim
  foRelProject # relative to project path, e.g.: ../foo.nim
  foMagicSauce # magic sauce, shortest of (foAbs, foRelProject)
  foName # lastPathPart, e.g.: foo.nim
  foStacktrace # if optExcessiveStackTrace: foAbs else: foName

proc toFilenameOption*(conf: ConfigRef, fileIdx: FileIndex, opt: FilenameOption): string =
  case opt
  of foAbs: result = toFullPath(conf, fileIdx)
  of foRelProject: result = toProjPath(conf, fileIdx)
  of foMagicSauce:
    let
      absPath = toFullPath(conf, fileIdx)
      relPath = toProjPath(conf, fileIdx)
    result = if (optListFullPaths in conf.globalOptions) or
                (relPath.len > absPath.len) or
                (relPath.count("..") > 2):
               absPath
             else:
               relPath
  of foName: result = toProjPath(conf, fileIdx).lastPathPart
  of foStacktrace:
    if optExcessiveStackTrace in conf.globalOptions:
      result = toFilenameOption(conf, fileIdx, foAbs)
    else:
      result = toFilenameOption(conf, fileIdx, foName)

proc toMsgFilename*(conf: ConfigRef; info: FileIndex): string =
  toFilenameOption(conf, info, foMagicSauce)

template toMsgFilename*(conf: ConfigRef; info: TLineInfo): string =
  toMsgFilename(conf, info.fileIndex)

proc toLinenumber*(info: TLineInfo): int {.inline.} =
  result = int info.line

proc toColumn*(info: TLineInfo): int {.inline.} =
  result = info.col

proc toFileLineCol(info: InstantiationInfo): string {.inline.} =
  result.toLocation(info.filename, info.line, info.column + ColOffset)

proc toFileLineCol*(conf: ConfigRef; info: TLineInfo): string {.inline.} =
  result.toLocation(toMsgFilename(conf, info), info.line.int, info.col.int + ColOffset)

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
      flushDot(conf)
      writeLine(stdout, s)
      flushFile(stdout)
  else:
    if eStdErr in conf.m.errorOutputs:
      flushDot(conf)
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
  when false:
    # not needed because styledWriteLine already ends with resetAttributes
    result = newStmtList(result, newCall(bindSym"resetAttributes", bindSym"stderr"))

template callWritelnHook(args: varargs[string, `$`]) =
  conf.writelnHook concat(args)

proc msgWrite(conf: ConfigRef; s: string) =
  if conf.m.errorOutputs != {}:
    let stdOrr =
      if optStdout in conf.globalOptions:
        stdout
      else:
        stderr
    write(stdOrr, s)
    flushFile(stdOrr)
    conf.lastMsgWasDot.incl stdOrr.toStdOrrKind() # subsequent writes need `flushDot`

template styledMsgWriteln*(args: varargs[typed]) =
  if not isNil(conf.writelnHook):
    callIgnoringStyle(callWritelnHook, nil, args)
  elif optStdout in conf.globalOptions:
    if eStdOut in conf.m.errorOutputs:
      flushDot(conf)
      callIgnoringStyle(writeLine, stdout, args)
      flushFile(stdout)
  elif eStdErr in conf.m.errorOutputs:
    flushDot(conf)
    if optUseColors in conf.globalOptions:
      callStyledWriteLineStderr(args)
    else:
      callIgnoringStyle(writeLine, stderr, args)
    # On Windows stderr is fully-buffered when piped, regardless of C std.
    when defined(windows):
      flushFile(stderr)

proc msgKindToString*(kind: TMsgKind): string = MsgKindToStr[kind]
  # later versions may provide translated error messages

proc getMessageStr(msg: TMsgKind, arg: string): string = msgKindToString(msg) % [arg]

type TErrorHandling* = enum doNothing, doAbort, doRaise

proc log*(s: string) =
  var f: File
  if open(f, getHomeDir() / "nimsuggest.log", fmAppend):
    f.writeLine(s)
    close(f)

proc quit(conf: ConfigRef; msg: TMsgKind) {.gcsafe.} =
  if defined(debug) or msg == errInternal or conf.hasHint(hintStackTrace):
    {.gcsafe.}:
      if stackTraceAvailable() and isNil(conf.writelnHook):
        writeStackTrace()
      else:
        styledMsgWriteln(fgRed, """
No stack traceback available
To create a stacktrace, rerun compilation with './koch temp $1 <file>', see $2 for details""" %
          [conf.command, "intern.html#debugging-the-compiler".createDocLink])
  quit 1

proc handleError(conf: ConfigRef; msg: TMsgKind, eh: TErrorHandling, s: string) =
  if msg >= fatalMin and msg <= fatalMax:
    if conf.cmd == cmdIdeTools: log(s)
    quit(conf, msg)
  if msg >= errMin and msg <= errMax or
      (msg in warnMin..hintMax and msg in conf.warningAsErrors):
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
  for i in 0..<conf.m.msgContext.len:
    let context = conf.m.msgContext[i]
    if context.info != lastinfo and context.info != info:
      if conf.structuredErrorHook != nil:
        conf.structuredErrorHook(conf, context.info, instantiationFrom,
                                 Severity.Hint)
      else:
        let message = if context.detail == "":
          instantiationFrom
        else:
          instantiationOfFrom.format(context.detail)
        styledMsgWriteln(styleBright, conf.toFileLineCol(context.info), " ", resetStyle, message)
    info = context.info

proc ignoreMsgBecauseOfIdeTools(conf: ConfigRef; msg: TMsgKind): bool =
  msg >= errGenerated and conf.cmd == cmdIdeTools and optIdeDebug notin conf.globalOptions

proc addSourceLine(conf: ConfigRef; fileIdx: FileIndex, line: string) =
  conf.m.fileInfos[fileIdx.int32].lines.add line

proc numLines*(conf: ConfigRef, fileIdx: FileIndex): int =
  ## xxx there's an off by 1 error that should be fixed; if a file ends with "foo" or "foo\n"
  ## it will return same number of lines (ie, a trailing empty line is discounted)
  result = conf.m.fileInfos[fileIdx.int32].lines.len
  if result == 0:
    try:
      for line in lines(toFullPathConsiderDirty(conf, fileIdx).string):
        addSourceLine conf, fileIdx, line
    except IOError:
      discard
    result = conf.m.fileInfos[fileIdx.int32].lines.len

proc sourceLine*(conf: ConfigRef; i: TLineInfo): string =
  ## 1-based index (matches editor line numbers); 1st line is for i.line = 1
  ## last valid line is `numLines` inclusive
  if i.fileIndex.int32 < 0: return ""
  let num = numLines(conf, i.fileIndex)
  # can happen if the error points to EOF:
  if i.line.int > num: return ""

  result = conf.m.fileInfos[i.fileIndex.int32].lines[i.line.int-1]

proc writeSurroundingSrc(conf: ConfigRef; info: TLineInfo) =
  const indent = "  "
  msgWriteln(conf, indent & $sourceLine(conf, info))
  if info.col >= 0:
    msgWriteln(conf, indent & spaces(info.col) & '^')

proc formatMsg*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg: string): string =
  let title = case msg
              of warnMin..warnMax: WarningTitle
              of hintMin..hintMax: HintTitle
              else: ErrorTitle
  conf.toFileLineCol(info) & " " & title & getMessageStr(msg, arg)

proc liMessage*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg: string,
               eh: TErrorHandling, info2: InstantiationInfo, isRaw = false) {.noinline.} =
  var
    title: string
    color: ForegroundColor
    ignoreMsg = false
    sev: Severity
  let kind = if msg in warnMin..hintMax and msg != hintUserRaw: $msg else: "" # xxx not sure why hintUserRaw is special
  case msg
  of errMin..errMax:
    sev = Severity.Error
    writeContext(conf, info)
    title = ErrorTitle
    color = ErrorColor
    when false:
      # we try to filter error messages so that not two error message
      # in the same file and line are produced:
      # xxx `lastError` is only used in this disabled code; but could be useful to revive
      ignoreMsg = conf.m.lastError == info and info != unknownLineInfo and eh != doAbort
    if info != unknownLineInfo: conf.m.lastError = info
  of warnMin..warnMax:
    sev = Severity.Warning
    ignoreMsg = not conf.hasWarn(msg)
    if msg in conf.warningAsErrors:
      ignoreMsg = false
      title = ErrorTitle
    else:
      title = WarningTitle
    if not ignoreMsg: writeContext(conf, info)
    color = WarningColor
    inc(conf.warnCounter)
  of hintMin..hintMax:
    sev = Severity.Hint
    ignoreMsg = not conf.hasHint(msg)
    if msg in conf.warningAsErrors:
      ignoreMsg = false
      title = ErrorTitle
    else:
      title = HintTitle
    color = HintColor
    inc(conf.hintCounter)

  let s = if isRaw: arg else: getMessageStr(msg, arg)
  if not ignoreMsg:
    let loc = if info != unknownLineInfo: conf.toFileLineCol(info) & " " else: ""
    # we could also show `conf.cmdInput` here for `projectIsCmd`
    var kindmsg = if kind.len > 0: KindFormat % kind else: ""
    if conf.structuredErrorHook != nil:
      conf.structuredErrorHook(conf, info, s & kindmsg, sev)
    if not ignoreMsgBecauseOfIdeTools(conf, msg):
      if msg == hintProcessing:
        msgWrite(conf, ".")
      else:
        styledMsgWriteln(styleBright, loc, resetStyle, color, title, resetStyle, s, KindColor, kindmsg)
        if conf.hasHint(hintSource) and info != unknownLineInfo:
          conf.writeSurroundingSrc(info)
        if hintMsgOrigin in conf.mainPackageNotes:
          styledMsgWriteln(styleBright, toFileLineCol(info2), resetStyle,
            " compiler msg initiated here", KindColor,
            KindFormat % $hintMsgOrigin,
            resetStyle)
  handleError(conf, msg, eh, s)

template rawMessage*(conf: ConfigRef; msg: TMsgKind, args: openArray[string]) =
  let arg = msgKindToString(msg) % args
  liMessage(conf, unknownLineInfo, msg, arg, eh = doAbort, instLoc(), isRaw = true)

template rawMessage*(conf: ConfigRef; msg: TMsgKind, arg: string) =
  liMessage(conf, unknownLineInfo, msg, arg, eh = doAbort, instLoc())

template fatal*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  # this fixes bug #7080 so that it is at least obvious 'fatal' was executed.
  conf.m.errorOutputs = {eStdOut, eStdErr}
  liMessage(conf, info, msg, arg, doAbort, instLoc())

template globalAssert*(conf: ConfigRef; cond: untyped, info: TLineInfo = unknownLineInfo, arg = "") =
  ## avoids boilerplate
  if not cond:
    var arg2 = "'$1' failed" % [astToStr(cond)]
    if arg.len > 0: arg2.add "; " & astToStr(arg) & ": " & arg
    liMessage(conf, info, errGenerated, arg2, doRaise, instLoc())

template globalError*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  ## `local` means compilation keeps going until errorMax is reached (via `doNothing`),
  ## `global` means it stops.
  liMessage(conf, info, msg, arg, doRaise, instLoc())

template globalError*(conf: ConfigRef; info: TLineInfo, arg: string) =
  liMessage(conf, info, errGenerated, arg, doRaise, instLoc())

template localError*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doNothing, instLoc())

template localError*(conf: ConfigRef; info: TLineInfo, arg: string) =
  liMessage(conf, info, errGenerated, arg, doNothing, instLoc())

template localError*(conf: ConfigRef; info: TLineInfo, format: string, params: openArray[string]) =
  liMessage(conf, info, errGenerated, format % params, doNothing, instLoc())

template message*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doNothing, instLoc())

proc internalErrorImpl(conf: ConfigRef; info: TLineInfo, errMsg: string, info2: InstantiationInfo) =
  if conf.cmd == cmdIdeTools and conf.structuredErrorHook.isNil: return
  writeContext(conf, info)
  liMessage(conf, info, errInternal, errMsg, doAbort, info2)

template internalError*(conf: ConfigRef; info: TLineInfo, errMsg: string) =
  internalErrorImpl(conf, info, errMsg, instLoc())

template internalError*(conf: ConfigRef; errMsg: string) =
  internalErrorImpl(conf, unknownLineInfo, errMsg, instLoc())

template internalAssert*(conf: ConfigRef, e: bool) =
  # xxx merge with `globalAssert`
  if not e:
    const info2 = instLoc()
    let arg = info2.toFileLineCol
    internalErrorImpl(conf, unknownLineInfo, arg, info2)

template lintReport*(conf: ConfigRef; info: TLineInfo, beau, got: string) =
  let m = "'$2' should be: '$1'" % [beau, got]
  let msg = if optStyleError in conf.globalOptions: errGenerated else: hintName
  liMessage(conf, info, msg, m, doNothing, instLoc())

proc quotedFilename*(conf: ConfigRef; i: TLineInfo): Rope =
  if i.fileIndex.int32 < 0:
    result = makeCString "???"
  elif optExcessiveStackTrace in conf.globalOptions:
    result = conf.m.fileInfos[i.fileIndex.int32].quotedFullName
  else:
    result = conf.m.fileInfos[i.fileIndex.int32].quotedName

template listMsg(title, r) =
  msgWriteln(conf, title)
  for a in r: msgWriteln(conf, "  [$1] $2" % [if a in conf.notes: "x" else: " ", $a])

proc listWarnings*(conf: ConfigRef) = listMsg("Warnings:", warnMin..warnMax)
proc listHints*(conf: ConfigRef) = listMsg("Hints:", hintMin..hintMax)
