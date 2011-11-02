#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Nimrod Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the standard unit testing facilities such as
## suites, fixtures and test cases as well as facilities for combinatorial 
## and randomzied test case generation (not yet available) 
## and object mocking (not yet available)
##
## It is loosely based on C++'s boost.test and Haskell's QuickTest
##
## Maintainer: Zahary Karadjov (zah@github)
##

import
  macros, terminal

type
  TestStatus* = enum OK, FAILED
  # ETestFailed* = object of ESynch

var 
  # XXX: These better be thread-local
  AbortOnError* = false
  checkpoints: seq[string] = @[]

template TestSetupIMPL*: stmt = nil
template TestTeardownIMPL*: stmt = nil

proc shouldRun(testName: string): bool =
  result = true

template suite*(name: expr, body: stmt): stmt =
  block:
    template setup(setupBody: stmt): stmt =
      template TestSetupIMPL: stmt = setupBody

    template teardown(teardownBody: stmt): stmt =
      template TestTeardownIMPL: stmt = teardownBody

    body

proc printStatus*(s: TestStatus, name: string) =
  var color = (if s == OK: fgGreen else: fgRed)
  styledEcho styleBright, color, "[", $s, "] ", fgWhite, name, "\n"
  
template test*(name: expr, body: stmt): stmt =
  bind shouldRun, checkPoints
  if shouldRun(name):
    checkpoints = @[]
    var TestStatusIMPL = OK
    
    try:
      TestSetupIMPL()
      body

    finally:
      TestTeardownIMPL()
      printStatus(TestStatusIMPL, name)

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
  proc standardRewrite(e: expr): stmt =
    template rewrite(Exp, lineInfoLit: expr, expLit: string): stmt =
      if not Exp:
        checkpoint(lineInfoLit & ": Check failed: " & expLit)
        fail()
 
    result = getAst(rewrite(e, e.lineinfo, e.toStrLit))
  
  case conditions.kind
  of nnkCall, nnkCommand, nnkMacroStmt:
    case conditions[1].kind
    of nnkInfix:
      proc rewriteBinaryOp(op: expr): stmt =
        template rewrite(op, left, right, lineInfoLit: expr, opLit, leftLit, rightLit: string): stmt =
          block:
            var 
              lhs = left
              rhs = right

            if not `op`(lhs, rhs):
              checkpoint(lineInfoLit & ": Check failed: " & opLit)
              checkpoint("  " & leftLit & " was " & $lhs)
              checkpoint("  " & rightLit & " was " & $rhs)
              fail()

        result = getAst(rewrite(
          op[0], op[1], op[2],
          op.lineinfo,
          op.toStrLit,
          op[1].toStrLit,
          op[2].toStrLit))
        
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
    error conditions.lineinfo & ": Malformed check statement"

template require*(conditions: stmt): stmt =
  block:
    const AbortOnError = true    
    check conditions

macro expect*(exp: stmt): stmt =
  template expectBody(errorTypes, lineInfoLit: expr, body: stmt): stmt =
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

