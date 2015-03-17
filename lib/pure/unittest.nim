#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Zahary Karadjov
##
## This module implements boilerplate to make testing easy.
##
## Example:
##
## .. code:: nim
##
##   suite "description for this stuff":
##     test "essential truths":
##       # give up and stop if this fails
##       require(true)
##
##     test "slightly less obvious stuff":
##       # print a nasty message and move on, skipping
##       # the remainder of this block
##       check(1 != 1)
##       check("asd"[2] == 'd')
##
##     test "out of bounds error is thrown on bad access":
##       let v = @[1, 2, 3]  # you can do initialization here
##       expect(IndexError):
##         discard v[4]

import
  macros

when declared(stdout):
  import os

when not defined(ECMAScript):
  import terminal
  system.addQuitProc(resetAttributes)

type
  TestStatus* = enum OK, FAILED
  OutputLevel* = enum PRINT_ALL, PRINT_FAILURES, PRINT_NONE

{.deprecated: [TTestStatus: TestStatus, TOutputLevel: OutputLevel]}

var
  abortOnError* {.threadvar.}: bool
  outputLevel* {.threadvar.}: OutputLevel
  colorOutput* {.threadvar.}: bool

  checkpoints {.threadvar.}: seq[string]

checkpoints = @[]

template testSetupIMPL*: stmt {.immediate, dirty.} = discard
template testTeardownIMPL*: stmt {.immediate, dirty.} = discard

proc shouldRun(testName: string): bool =
  result = true

template suite*(name: expr, body: stmt): stmt {.immediate, dirty.} =
  block:
    template setup*(setupBody: stmt): stmt {.immediate, dirty.} =
      template testSetupIMPL: stmt {.immediate, dirty.} = setupBody

    template teardown*(teardownBody: stmt): stmt {.immediate, dirty.} =
      template testTeardownIMPL: stmt {.immediate, dirty.} = teardownBody

    body

proc testDone(name: string, s: TestStatus) =
  if s == FAILED:
    programResult += 1

  if outputLevel != PRINT_NONE and (outputLevel == PRINT_ALL or s == FAILED):
    template rawPrint() = echo("[", $s, "] ", name)
    when not defined(ECMAScript):
      if colorOutput and not defined(ECMAScript):
        var color = (if s == OK: fgGreen else: fgRed)
        styledEcho styleBright, color, "[", $s, "] ", fgWhite, name
      else:
        rawPrint()
    else:
      rawPrint()

template test*(name: expr, body: stmt): stmt {.immediate, dirty.} =
  bind shouldRun, checkpoints, testDone

  if shouldRun(name):
    checkpoints = @[]
    var testStatusIMPL {.inject.} = OK

    try:
      testSetupIMPL()
      body

    except:
      checkpoint("Unhandled exception: " & getCurrentExceptionMsg())
      echo getCurrentException().getStackTrace()
      fail()

    finally:
      testTeardownIMPL()
      testDone name, testStatusIMPL

proc checkpoint*(msg: string) =
  checkpoints.add(msg)
  # TODO: add support for something like SCOPED_TRACE from Google Test

template fail* =
  bind checkpoints
  for msg in items(checkpoints):
    # this used to be 'echo' which now breaks due to a bug. XXX will revisit
    # this issue later.
    stdout.writeln msg

  when not defined(ECMAScript):
    if abortOnError: quit(1)

  when declared(testStatusIMPL):
    testStatusIMPL = FAILED
  else:
    programResult += 1

  checkpoints = @[]

macro check*(conditions: stmt): stmt {.immediate.} =
  let checked = callsite()[1]

  var
    argsAsgns = newNimNode(nnkStmtList)
    argsPrintOuts = newNimNode(nnkStmtList)
    counter = 0

  template asgn(a, value: expr): stmt =
    var a = value # XXX: we need "var: var" here in order to
                  # preserve the semantics of var params

  template print(name, value: expr): stmt =
    when compiles(string($value)):
      checkpoint(name & " was " & $value)

  proc inspectArgs(exp: NimNode) =
    for i in 1 .. <exp.len:
      if exp[i].kind notin nnkLiterals:
        inc counter
        var arg = newIdentNode(":p" & $counter)
        var argStr = exp[i].toStrLit
        var paramAst = exp[i]
        if exp[i].kind in nnkCallKinds: inspectArgs(exp[i])
        if exp[i].kind == nnkExprEqExpr:
          # ExprEqExpr
          #   Ident !"v"
          #   IntLit 2
          paramAst = exp[i][1]
        argsAsgns.add getAst(asgn(arg, paramAst))
        argsPrintOuts.add getAst(print(argStr, arg))
        if exp[i].kind != nnkExprEqExpr:
          exp[i] = arg
        else:
          exp[i][1] = arg

  case checked.kind
  of nnkCallKinds:
    template rewrite(call, lineInfoLit: expr, callLit: string,
                     argAssgs, argPrintOuts: stmt): stmt =
      block:
        argAssgs
        if not call:
          checkpoint(lineInfoLit & ": Check failed: " & callLit)
          argPrintOuts
          fail()

    var checkedStr = checked.toStrLit
    inspectArgs(checked)
    result = getAst(rewrite(checked, checked.lineinfo, checkedStr,
                            argsAsgns, argsPrintOuts))

  of nnkStmtList:
    result = newNimNode(nnkStmtList)
    for i in countup(0, checked.len - 1):
      if checked[i].kind != nnkCommentStmt:
        result.add(newCall(!"check", checked[i]))

  else:
    template rewrite(Exp, lineInfoLit: expr, expLit: string): stmt =
      if not Exp:
        checkpoint(lineInfoLit & ": Check failed: " & expLit)
        fail()

    result = getAst(rewrite(checked, checked.lineinfo, checked.toStrLit))

template require*(conditions: stmt): stmt {.immediate, dirty.} =
  block:
    const AbortOnError {.inject.} = true
    check conditions

macro expect*(exceptions: varargs[expr], body: stmt): stmt {.immediate.} =
  let exp = callsite()
  template expectBody(errorTypes, lineInfoLit: expr,
                      body: stmt): NimNode {.dirty.} =
    try:
      body
      checkpoint(lineInfoLit & ": Expect Failed, no exception was thrown.")
      fail()
    except errorTypes:
      discard

  var body = exp[exp.len - 1]

  var errorTypes = newNimNode(nnkBracket)
  for i in countup(1, exp.len - 2):
    errorTypes.add(exp[i])

  result = getAst(expectBody(errorTypes, exp.lineinfo, body))


when declared(stdout):
  ## Reading settings
  var envOutLvl = os.getEnv("NIMTEST_OUTPUT_LVL").string

  abortOnError = existsEnv("NIMTEST_ABORT_ON_ERROR")
  colorOutput  = not existsEnv("NIMTEST_NO_COLOR")

else:
  var envOutLvl = "" # TODO
  colorOutput  = false

if envOutLvl.len > 0:
  for opt in countup(low(OutputLevel), high(OutputLevel)):
    if $opt == envOutLvl:
      outputLevel = opt
      break
