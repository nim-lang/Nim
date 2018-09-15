#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import parseutils, strutils, os, osproc, streams, types, parsecfg

let isTravis* = existsEnv("TRAVIS")
let isAppVeyor* = existsEnv("APPVEYOR")

proc cmdTemplate*(): string =
  "$prefix $target --lib:lib --hints:on -d:testing --nimblePath:tests/deps $options $file"

const
  targetToExt*: array[Target, string] = ["c", "cpp", "m", "js"]
  targetToCmd*: array[Target, string] = ["c", "cpp", "objc", "js"]

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

template parseSpecAux(fillResult: untyped) =
  var ss = newStringStream(extractSpec(filename))
  var p {.inject.}: CfgParser
  open(p, ss, filename, 1)
  while true:
    var e {.inject.} = next(p)
    case e.kind
    of cfgEof: break
    of cfgSectionStart, cfgOption, cfgError:
      echo ignoreMsg(p, e)
    of cfgKeyValuePair:
      fillResult
  close(p)

proc specDefaults*(result: var Spec) =
  result.msg = ""
  result.outp = ""
  result.nimout = ""
  result.ccodeCheck = ""
  result.cmd = cmdTemplate()
  result.line = 0
  result.column = 0
  result.tfile = ""
  result.tline = 0
  result.tcolumn = 0
  result.maxCodeSize = 0

proc parseTargets*(value: string): set[Target] =
  for v in value.normalize.splitWhitespace:
    case v
    of "c": result.incl(targetC)
    of "cpp", "c++": result.incl(targetCpp)
    of "objc": result.incl(targetObjC)
    of "js": result.incl(targetJS)
    else: echo "target ignored: " & v

proc parseSpec*(filename: string, action = actionCompile, targets = {targetC}): Spec =
  specDefaults(result)
  result.file = filename
  result.action = action
  result.targets = targets
  parseSpecAux:
    case normalize(e.key)
    of "action":
      case e.value.normalize
      of "compile": result.action = actionCompile
      of "run": result.action = actionRun
      of "reject": result.action = actionReject
      else: echo ignoreMsg(p, e)
    of "file": result.file = e.value
    of "line": discard parseInt(e.value, result.line)
    of "column": discard parseInt(e.value, result.column)
    of "tfile": result.tfile = e.value
    of "tline": discard parseInt(e.value, result.tline)
    of "tcolumn": discard parseInt(e.value, result.tcolumn)
    of "output":
      result.action = actionRun
      result.outp = e.value
    of "outputsub":
      result.action = actionRun
      result.outp = e.value
      result.substr = true
    of "sortoutput":
      result.sortoutput = parseCfgBool(e.value)
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
    of "disabled":
      case e.value.normalize
      of "y", "yes", "true", "1", "on": result.res = reIgnored
      of "n", "no", "false", "0", "off": discard
      of "win", "windows":
        when defined(windows): result.res = reIgnored
      of "linux":
        when defined(linux): result.res = reIgnored
      of "bsd":
        when defined(bsd): result.res = reIgnored
      of "macosx":
        when defined(macosx): result.res = reIgnored
      of "unix":
        when defined(unix): result.res = reIgnored
      of "posix":
        when defined(posix): result.res = reIgnored
      of "travis":
        if isTravis: result.res = reIgnored
      of "appveyor":
        if isAppVeyor: result.res = reIgnored
      else:
        raise newException(ValueError, "cannot interpret as a bool: " & e.value)
    of "cmd":
      result.cmd = e.value
    of "ccodecheck": result.ccodeCheck = e.value
    of "maxcodesize": discard parseInt(e.value, result.maxCodeSize)
    of "target", "targets":
      for v in e.value.normalize.splitWhitespace:
        case v
        of "c": result.targets.incl(targetC)
        of "cpp", "c++": result.targets.incl(targetCpp)
        of "objc": result.targets.incl(targetObjC)
        of "js": result.targets.incl(targetJS)
        else: echo ignoreMsg(p, e)
    else: echo ignoreMsg(p, e)
