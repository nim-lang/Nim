#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import parseutils, strutils, os, osproc, streams, parsecfg

var compilerPrefix* = findExe("nim")

let isTravis* = existsEnv("TRAVIS")
let isAppVeyor* = existsEnv("APPVEYOR")

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
    reExitcodesDiffer,
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
    targets*: set[TTarget]
    nimout*: string
    parseErrors*: string # when the spec definition is invalid, this is not empty.
    unjoinable*: bool

proc getCmd*(s: TSpec): string =
  if s.cmd.len == 0:
    result = compilerPrefix & " $target --hints:on -d:testing --nimblePath:tests/deps $options $file"
  else:
    result = s.cmd

const
  targetToExt*: array[TTarget, string] = ["c", "cpp", "m", "js"]
  targetToCmd*: array[TTarget, string] = ["c", "cpp", "objc", "js"]

when not declared(parseCfgBool):
  # candidate for the stdlib:
  proc parseCfgBool(s: string): bool =
    case normalize(s)
    of "y", "yes", "true", "1", "on": result = true
    of "n", "no", "false", "0", "off": result = false
    else: raise newException(ValueError, "cannot interpret as a bool: " & s)

proc extractSpec(filename: string): string =
  const tripleQuote = "\"\"\""
  var x = readFile(filename).string
  var a = x.find(tripleQuote)
  var b = x.find(tripleQuote, a+3)
  # look for """ only in the first section
  if a >= 0 and b > a and a < 40:
    result = x.substr(a+3, b-1).replace("'''", tripleQuote)
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

proc parseSpec*(filename: string): TSpec =
  result.file = filename
  let specStr = extractSpec(filename)
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
      of "joinable":
        result.unjoinable = not parseCfgBool(e.value)
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
        of "32bit":
          if sizeof(int) == 4:
            result.err = reDisabled
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
