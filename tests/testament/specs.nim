#
#
#            Nimrod Tester
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import parseutils, strutils, os, osproc, streams, parsecfg

const
  cmdTemplate* = r"$# cc --hints:on $# $#"

type
  TTestAction* = enum
    actionCompile = "compile"
    actionRun = "run"
    actionReject = "reject"
  TResultEnum* = enum
    reNimrodcCrash,     # nimrod compiler seems to have crashed
    reMsgsDiffer,       # error messages differ
    reFilesDiffer,      # expected and given filenames differ
    reLinesDiffer,      # expected and given line numbers differ
    reOutputsDiffer,
    reExitcodesDiffer,
    reInvalidPeg,
    reCodegenFailure,
    reCodeNotFound,
    reExeNotFound,
    reIgnored,          # test is ignored
    reSuccess           # test was successful
  TTarget* = enum
    targetC = "C"
    targetCpp = "C++"
    targetObjC = "ObjC"
    targetJS = "JS"

  TSpec* = object
    action*: TTestAction
    file*, cmd*: string
    outp*: string
    line*, exitCode*: int
    msg*: string
    ccodeCheck*: string
    err*: TResultEnum
    substr*: bool
    targets*: set[TTarget]

const
  targetToExt*: array[TTarget, string] = ["c", "cpp", "m", "js"]

when not defined(parseCfgBool):
  # candidate for the stdlib:
  proc parseCfgBool(s: string): bool =
    case normalize(s)
    of "y", "yes", "true", "1", "on": result = true
    of "n", "no", "false", "0", "off": result = false
    else: raise newException(EInvalidValue, "cannot interpret as a bool: " & s)

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

template parseSpecAux(fillResult: stmt) {.immediate.} =
  var ss = newStringStream(extractSpec(filename))
  var p {.inject.}: TCfgParser
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

proc parseSpec*(filename: string): TSpec =
  result.file = filename
  result.msg = ""
  result.outp = ""
  result.ccodeCheck = ""
  result.cmd = cmdTemplate
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
    of "output": 
      result.action = actionRun
      result.outp = e.value
    of "outputsub":
      result.action = actionRun
      result.outp = e.value
      result.substr = true
    of "exitcode": 
      discard parseInt(e.value, result.exitCode)
    of "errormsg", "msg":
      result.msg = e.value
      result.action = actionReject
    of "disabled":
      if parseCfgBool(e.value): result.err = reIgnored
    of "cmd": result.cmd = e.value
    of "ccodecheck": result.ccodeCheck = e.value
    of "target", "targets":
      for v in e.value.normalize.split:
        case v
        of "c": result.targets.incl(targetC)
        of "cpp", "c++": result.targets.incl(targetCpp)
        of "objc": result.targets.incl(targetObjC)
        of "js": result.targets.incl(targetJS)
        else: echo ignoreMsg(p, e)
    else: echo ignoreMsg(p, e)
