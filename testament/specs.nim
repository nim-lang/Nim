#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import sequtils, parseutils, strutils, os, streams, parsecfg,
  tables, hashes

type TestamentData* = ref object
  # better to group globals under 1 object; could group the other ones here too
  batchArg*: string
  testamentNumBatch*: int
  testamentBatch*: int

let testamentData0* = TestamentData()

var compilerPrefix* = findExe("nim")

let isTravis* = existsEnv("TRAVIS")
let isAppVeyor* = existsEnv("APPVEYOR")
let isAzure* = existsEnv("TF_BUILD")

var skips*: seq[string]

type
  TTestAction* = enum
    actionRun = "run"
    actionCompile = "compile"
    actionReject = "reject"

  TOutputCheck* = enum
    ocIgnore = "ignore"
    ocEqual  = "equal"
    ocSubstr = "substr"

  TResultEnum* = enum
    reNimcCrash,     # nim compiler seems to have crashed
    reMsgsDiffer,       # error messages differ
    reFilesDiffer,      # expected and given filenames differ
    reLinesDiffer,      # expected and given line numbers differ
    reOutputsDiffer,
    reExitcodesDiffer,  # exit codes of program or of valgrind differ
    reTimeout,
    reInvalidPeg,
    reCodegenFailure,
    reCodeNotFound,
    reExeNotFound,
    reInstallFailed     # package installation failed
    reBuildFailed       # package building failed
    reDisabled,         # test is disabled
    reJoined,           # test is disabled because it was joined into the megatest
    reSuccess           # test was successful
    reInvalidSpec       # test had problems to parse the spec

  TTarget* = enum
    targetC = "C"
    targetCpp = "C++"
    targetObjC = "ObjC"
    targetJS = "JS"

  InlineError* = object
    kind*: string
    msg*: string
    line*, col*: int

  ValgrindSpec* = enum
    disabled, enabled, leaking
  
  TSpec* = object
    action*: TTestAction
    file*, cmd*: string
    input*: string
    outputCheck*: TOutputCheck
    sortoutput*: bool
    output*: string
    line*, column*: int
    tfile*: string
    tline*, tcolumn*: int
    exitCode*: int
    msg*: string
    ccodeCheck*: string
    maxCodeSize*: int
    err*: TResultEnum
    inCurrentBatch*: bool
    targets*: set[TTarget]
    matrix*: seq[string]
    nimout*: string
    parseErrors*: string # when the spec definition is invalid, this is not empty.
    unjoinable*: bool
    unbatchable*: bool
      # whether this test can be batchable via `NIM_TESTAMENT_BATCH`; only very
      # few tests are not batchable; the ones that are not could be turned batchable
      # by making the dependencies explicit
    useValgrind*: ValgrindSpec
    timeout*: float # in seconds, fractions possible,
                    # but don't rely on much precision
    inlineErrors*: seq[InlineError] # line information to error message

proc getCmd*(s: TSpec): string =
  if s.cmd.len == 0:
    result = compilerPrefix & " $target --hints:on -d:testing --nimblePath:tests/deps $options $file"
  else:
    result = s.cmd

const
  targetToExt*: array[TTarget, string] = ["nim.c", "nim.cpp", "nim.m", "js"]
  targetToCmd*: array[TTarget, string] = ["c", "cpp", "objc", "js"]

proc defaultOptions*(a: TTarget): string =
  case a
  of targetJS: "-d:nodejs"
    # once we start testing for `nim js -d:nimbrowser` (eg selenium or similar),
    # we can adapt this logic; or a given js test can override with `-u:nodejs`.
  else: ""

when not declared(parseCfgBool):
  # candidate for the stdlib:
  proc parseCfgBool(s: string): bool =
    case normalize(s)
    of "y", "yes", "true", "1", "on": result = true
    of "n", "no", "false", "0", "off": result = false
    else: raise newException(ValueError, "cannot interpret as a bool: " & s)

const
  inlineErrorMarker = "#[tt."

proc extractErrorMsg(s: string; i: int; line: var int; col: var int; spec: var TSpec): int =
  result = i + len(inlineErrorMarker)
  inc col, len(inlineErrorMarker)
  var kind = ""
  while result < s.len and s[result] in IdentChars:
    kind.add s[result]
    inc result
    inc col

  var caret = (line, -1)

  template skipWhitespace =
    while result < s.len and s[result] in Whitespace:
      if s[result] == '\n':
        col = 1
        inc line
      else:
        inc col
      inc result

  skipWhitespace()
  if result < s.len and s[result] == '^':
    caret = (line-1, col)
    inc result
    inc col
    skipWhitespace()

  var msg = ""
  while result < s.len-1:
    if s[result] == '\n':
      inc result
      inc line
      col = 1
    elif s[result] == ']' and s[result+1] == '#':
      while msg.len > 0 and msg[^1] in Whitespace:
        setLen msg, msg.len - 1

      inc result
      inc col, 2
      if kind == "Error": spec.action = actionReject
      spec.unjoinable = true
      spec.inlineErrors.add InlineError(kind: kind, msg: msg, line: caret[0], col: caret[1])
      break
    else:
      msg.add s[result]
      inc result
      inc col

proc extractSpec(filename: string; spec: var TSpec): string =
  const
    tripleQuote = "\"\"\""
  var s = readFile(filename).string

  var i = 0
  var a = -1
  var b = -1
  var line = 1
  var col = 1
  while i < s.len:
    if s.continuesWith(tripleQuote, i):
      if a < 0: a = i
      elif b < 0: b = i
      inc i, 2
      inc col
    elif s[i] == '\n':
      inc line
      col = 1
    elif s.continuesWith(inlineErrorMarker, i):
      i = extractErrorMsg(s, i, line, col, spec)
    else:
      inc col
    inc i

  # look for """ only in the first section
  if a >= 0 and b > a and a < 40:
    result = s.substr(a+3, b-1).replace("'''", tripleQuote)
  else:
    #echo "warning: file does not contain spec: " & filename
    result = ""

when not defined(nimhygiene):
  {.pragma: inject.}

proc parseTargets*(value: string): set[TTarget] =
  for v in value.normalize.splitWhitespace:
    case v
    of "c": result.incl(targetC)
    of "cpp", "c++": result.incl(targetCpp)
    of "objc": result.incl(targetObjC)
    of "js": result.incl(targetJS)
    else: echo "target ignored: " & v

proc addLine*(self: var string; a: string) =
  self.add a
  self.add "\n"

proc addLine*(self: var string; a,b: string) =
  self.add a
  self.add b
  self.add "\n"

proc initSpec*(filename: string): TSpec =
  result.file = filename

proc isCurrentBatch(testamentData: TestamentData, filename: string): bool =
  if testamentData.testamentNumBatch != 0:
    hash(filename) mod testamentData.testamentNumBatch == testamentData.testamentBatch
  else:
    true

proc parseSpec*(filename: string): TSpec =
  result.file = filename
  let specStr = extractSpec(filename, result)
  var ss = newStringStream(specStr)
  var p: CfgParser
  open(p, ss, filename, 1)
  while true:
    var e = next(p)
    case e.kind
    of cfgKeyValuePair:
      case normalize(e.key)
      of "action":
        case e.value.normalize
        of "compile":
          result.action = actionCompile
        of "run":
          result.action = actionRun
        of "reject":
          result.action = actionReject
        else:
          result.parseErrors.addLine "cannot interpret as action: ", e.value
      of "file":
        if result.msg.len == 0 and result.nimout.len == 0:
          result.parseErrors.addLine "errormsg or msg needs to be specified before file"
        result.file = e.value
      of "line":
        if result.msg.len == 0 and result.nimout.len == 0:
          result.parseErrors.addLine "errormsg, msg or nimout needs to be specified before line"
        discard parseInt(e.value, result.line)
      of "column":
        if result.msg.len == 0 and result.nimout.len == 0:
          result.parseErrors.addLine "errormsg or msg needs to be specified before column"
        discard parseInt(e.value, result.column)
      of "tfile":
        result.tfile = e.value
      of "tline":
        discard parseInt(e.value, result.tline)
      of "tcolumn":
        discard parseInt(e.value, result.tcolumn)
      of "output":
        if result.outputCheck != ocSubstr:
          result.outputCheck = ocEqual
        result.output = strip(e.value)
      of "input":
        result.input = e.value
      of "outputsub":
        result.outputCheck = ocSubstr
        result.output = strip(e.value)
      of "sortoutput":
        try:
          result.sortoutput  = parseCfgBool(e.value)
        except:
          result.parseErrors.addLine getCurrentExceptionMsg()
      of "exitcode":
        discard parseInt(e.value, result.exitCode)
        result.action = actionRun
      of "msg":
        result.msg = e.value
        if result.action != actionRun:
          result.action = actionCompile
      of "errormsg", "errmsg":
        result.msg = e.value
        result.action = actionReject
      of "nimout":
        result.nimout = e.value
      of "batchable":
        result.unbatchable = not parseCfgBool(e.value)
      of "joinable":
        result.unjoinable = not parseCfgBool(e.value)
      of "valgrind":
        when defined(linux) and sizeof(int) == 8:
          result.useValgrind = if e.value.normalize == "leaks": leaking
                               else: ValgrindSpec(parseCfgBool(e.value))
          result.unjoinable = true
          if result.useValgrind != disabled:
            result.outputCheck = ocSubstr
        else:
          # Windows lacks valgrind. Silly OS.
          # Valgrind only supports OSX <= 17.x
          result.useValgrind = false
      of "disabled":
        case e.value.normalize
        of "y", "yes", "true", "1", "on": result.err = reDisabled
        of "n", "no", "false", "0", "off": discard
        of "win", "windows":
          when defined(windows): result.err = reDisabled
        of "linux":
          when defined(linux): result.err = reDisabled
        of "bsd":
          when defined(bsd): result.err = reDisabled
        of "macosx":
          when defined(macosx): result.err = reDisabled
        of "unix":
          when defined(unix): result.err = reDisabled
        of "posix":
          when defined(posix): result.err = reDisabled
        of "travis":
          if isTravis: result.err = reDisabled
        of "appveyor":
          if isAppVeyor: result.err = reDisabled
        of "azure":
          if isAzure: result.err = reDisabled
        of "32bit":
          if sizeof(int) == 4:
            result.err = reDisabled
        of "freebsd":
          when defined(freebsd): result.err = reDisabled
        of "arm64":
          when defined(arm64): result.err = reDisabled
        of "i386":
          when defined(i386): result.err = reDisabled
        of "openbsd":
          when defined(openbsd): result.err = reDisabled
        of "netbsd":
          when defined(netbsd): result.err = reDisabled
        else:
          result.parseErrors.addLine "cannot interpret as a bool: ", e.value
      of "cmd":
        if e.value.startsWith("nim "):
          result.cmd = compilerPrefix & e.value[3..^1]
        else:
          result.cmd = e.value
      of "ccodecheck":
        result.ccodeCheck = e.value
      of "maxcodesize":
        discard parseInt(e.value, result.maxCodeSize)
      of "timeout":
        try:
          result.timeout = parseFloat(e.value)
        except ValueError:
          result.parseErrors.addLine "cannot interpret as a float: ", e.value
      of "target", "targets":
        for v in e.value.normalize.splitWhitespace:
          case v
          of "c":
            result.targets.incl(targetC)
          of "cpp", "c++":
            result.targets.incl(targetCpp)
          of "objc":
            result.targets.incl(targetObjC)
          of "js":
            result.targets.incl(targetJS)
          else:
            result.parseErrors.addLine "cannot interpret as a target: ", e.value
      of "matrix":
        for v in e.value.split(';'):
          result.matrix.add(v.strip)
      else:
        result.parseErrors.addLine "invalid key for test spec: ", e.key

    of cfgSectionStart:
      result.parseErrors.addLine "section ignored: ", e.section
    of cfgOption:
      result.parseErrors.addLine "command ignored: ", e.key & ": " & e.value
    of cfgError:
      result.parseErrors.addLine e.msg
    of cfgEof:
      break
  close(p)

  if skips.anyIt(it in result.file):
    result.err = reDisabled

  result.inCurrentBatch = isCurrentBatch(testamentData0, filename) or result.unbatchable
  if not result.inCurrentBatch:
    result.err = reDisabled
