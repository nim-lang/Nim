#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Nimrod Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Zahary Karadjov (zah@github)
##
## This module implements the standard unit testing facilities such as
## suites, fixtures and test cases as well as facilities for combinatorial 
## and randomzied test case generation (not yet available) 
## and object mocking (not yet available)
##
## It is loosely based on C++'s boost.test and Haskell's QuickTest

import
  macros, terminal, os

type
  TTestStatus* = enum OK, FAILED
  TOutputLevel* = enum PRINT_ALL, PRINT_FAILURES, PRINT_NONE

var 
  # XXX: These better be thread-local
  AbortOnError*: bool
  OutputLevel*: TOutputLevel
  ColorOutput*: bool
  
  checkpoints: seq[string] = @[]

template TestSetupIMPL*: stmt {.dirty.} = nil
template TestTeardownIMPL*: stmt {.dirty.} = nil

proc shouldRun(testName: string): bool =
  result = true

template suite*(name: expr, body: stmt): stmt {.dirty.} =
  block:
    template setup*(setupBody: stmt): stmt {.dirty.} =
      template TestSetupIMPL: stmt {.dirty.} = setupBody

    template teardown*(teardownBody: stmt): stmt {.dirty.} =
      template TestTeardownIMPL: stmt {.dirty.} = teardownBody

    body

proc testDone(name: string, s: TTestStatus) =
  if s == FAILED:
    program_result += 1

  if OutputLevel != PRINT_NONE and (OutputLevel == PRINT_ALL or s == FAILED):
    var color = (if s == OK: fgGreen else: fgRed)
    
    if ColorOutput:
      styledEcho styleBright, color, "[", $s, "] ", fgWhite, name, "\n"
    else:
      echo "[", $s, "] ", name, "\n"
  
template test*(name: expr, body: stmt): stmt {.dirty.} =
  bind shouldRun, checkpoints, testDone

  if shouldRun(name):
    checkpoints = @[]
    var TestStatusIMPL {.inject.} = OK
    
    try:
      TestSetupIMPL()
      body

    except:
      checkpoint("Unhandled exception: " & getCurrentExceptionMsg())
      fail()

    finally:
      TestTeardownIMPL()
      testDone name, TestStatusIMPL

proc checkpoint*(msg: string) =
  checkpoints.add(msg)
  # TODO: add support for something like SCOPED_TRACE from Google Test

template fail* =
  bind checkpoints
  for msg in items(checkpoints):
    echo msg

  if AbortOnError: quit(1)
  
  TestStatusIMPL = FAILED
  checkpoints = @[]

macro check*(conditions: stmt): stmt =
  proc standardRewrite(e: PNimrodNode): PNimrodNode =
    template rewrite(Exp, lineInfoLit: expr, expLit: string): stmt =
      if not Exp:
        checkpoint(lineInfoLit & ": Check failed: " & expLit)
        fail()
 
    result = getAst(rewrite(e, e.lineinfo, e.toStrLit))
  
  case conditions.kind
  of nnkCall, nnkCommand, nnkMacroStmt:
    case conditions[1].kind
    of nnkInfix:
      proc rewriteBinaryOp(op: PNimrodNode): PNimrodNode =
        template rewrite(op, left, right, lineInfoLit: expr, opLit,
          leftLit, rightLit: string, printLhs, printRhs: bool): stmt =
          block:
            var 
              lhs = left
              rhs = right

            if not `op`(lhs, rhs):
              checkpoint(lineInfoLit & ": Check failed: " & opLit)
              when printLhs: checkpoint("  " & leftLit & " was " & $lhs)
              when printRhs: checkpoint("  " & rightLit & " was " & $rhs)
              fail()

        result = getAst(rewrite(
          op[0], op[1], op[2],
          op.lineinfo,
          op.toStrLit,
          op[1].toStrLit,
          op[2].toStrLit,
          op[1].kind notin nnkLiterals,
          op[2].kind notin nnkLiterals))
        
      result = rewriteBinaryOp(conditions[1])
  
    of nnkCall, nnkCommand:
      # TODO: We can print out the call arguments in case of failure
      result = standardRewrite(conditions[1])

    of nnkStmtList:
      result = newNimNode(nnkStmtList)
      for i in countup(0, conditions[1].len - 1):
        result.add(newCall(!"check", conditions[1][i]))

    else:
      result = standardRewrite(conditions[1])

  else:
    var ast = conditions.treeRepr
    error conditions.lineinfo & ": Malformed check statement:\n" & ast

template require*(conditions: stmt): stmt {.dirty.} =
  block:
    const AbortOnError {.inject.} = true
    check conditions

macro expect*(exp: stmt): stmt =
  template expectBody(errorTypes, lineInfoLit: expr,
                      body: stmt): PNimrodNode {.dirty.} =
    try:
      body
      checkpoint(lineInfoLit & ": Expect Failed, no exception was thrown.")
      fail()
    except errorTypes:
      nil

  var expectCall = exp[0]
  var body = exp[1]
  
  var errorTypes = newNimNode(nnkBracket)
  for i in countup(1, expectCall.len - 1):
    errorTypes.add(expectCall[i])

  result = getAst(expectBody(errorTypes, exp.lineinfo, body))


## Reading settings
var envOutLvl = os.getEnv("NIMTEST_OUTPUT_LVL").string

if envOutLvl.len > 0:
  for opt in countup(low(TOutputLevel), high(TOutputLevel)):
    if $opt == envOutLvl:
      OutputLevel = opt
      break

AbortOnError = existsEnv("NIMTEST_ABORT_ON_ERROR")
ColorOutput  = not existsEnv("NIMTEST_NO_COLOR")
