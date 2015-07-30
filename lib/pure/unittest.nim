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
## This module implements boilerplate to make unit testing easy.
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

type
  TestStatus* = enum OK, FAILED ## The status of a test when it is done.
  OutputLevel* = enum  ## The output verbosity of the tests.
    PRINT_ALL,         ## Print as much as possible.
    PRINT_FAILURES,    ## Print only the failed tests.
    PRINT_NONE         ## Print nothing.

{.deprecated: [TTestStatus: TestStatus, TOutputLevel: OutputLevel]}

var ## Global unittest settings!

  abortOnError* {.threadvar.}: bool ## Set to true in order to quit
                                    ## immediately on fail. Default is false,
                                    ## unless the ``NIMTEST_ABORT_ON_ERROR``
                                    ## environment variable is set for
                                    ## the non-js target.
  outputLevel* {.threadvar.}: OutputLevel ## Set the verbosity of test results.
                                          ## Default is ``PRINT_ALL``, unless
                                          ## the ``NIMTEST_OUTPUT_LVL`` environment
                                          ## variable is set for the non-js target.

  colorOutput* {.threadvar.}: bool ## Have test results printed in color.
                                   ## Default is true for the non-js target
                                   ## unless, the environment variable
                                   ## ``NIMTEST_NO_COLOR`` is set.

  checkpoints {.threadvar.}: seq[string]

checkpoints = @[]

template testSetupIMPL*: stmt {.immediate, dirty.} = discard      #Should this be public or even exist?
template testTeardownIMPL*: stmt {.immediate, dirty.} = discard

proc shouldRun(testName: string): bool =
  result = true

template suite*(name: expr, body: stmt): stmt {.immediate, dirty.} =
  ## Declare a test suite identified by `name` with optional ``setup``
  ## and/or ``teardown`` section.
  ##
  ## A test suite is a series of one or more related tests sharing a
  ## common fixture (``setup``, ``teardown``). The fixture is executed
  ## for EACH test.
  ##
  ## .. code-block:: nim
  ##  suite "test suite for addition":
  ##    setup:
  ##      let result = 4
  ##
  ##    test "2 + 2 = 4":
  ##      check(2+2 == result)
  ##
  ##    test "2 + -2 != 4":
  ##      check(2+2 != result)
  ##
  ##    # No teardown needed
  ##
  ## The suite will run the individual test cases in the order in which
  ## they were listed. With default global settings the above code prints:
  ##
  ## .. code-block::
  ##
  ##  [OK] 2 + 2 = 4
  ##  [OK] (2 + -2) != 4
  block:
    template setup(setupBody: stmt): stmt {.immediate, dirty.} =
      template testSetupIMPL: stmt {.immediate, dirty.} = setupBody

    template teardown(teardownBody: stmt): stmt {.immediate, dirty.} =
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
  ## Define a single test case identified by `name`.
  ##
  ## .. code-block:: nim
  ##
  ##  test "roses are red":
  ##    let roses = "red"
  ##    check(roses == "red")
  ##
  ## The above code outputs:
  ##
  ## .. code-block::
  ##
  ##  [OK] roses are red
  bind shouldRun, checkpoints, testDone

  if shouldRun(name):
    checkpoints = @[]
    var testStatusIMPL {.inject.} = OK

    try:
      testSetupIMPL()
      body

    except:
      when not defined(js):
        checkpoint("Unhandled exception: " & getCurrentExceptionMsg())
        echo getCurrentException().getStackTrace()
      fail()

    finally:
      testTeardownIMPL()
      testDone name, testStatusIMPL

proc checkpoint*(msg: string) =
  ## Set a checkpoint identified by `msg`. Upon test failure all
  ## checkpoints encountered so far are printed out. Example:
  ##
  ## .. code-block:: nim
  ##
  ##  checkpoint("Checkpoint A")
  ##  check((42, "the Answer to life and everything") == (1, "a"))
  ##  checkpoint("Checkpoint B")
  ##
  ## outputs "Checkpoint A" once it fails.
  checkpoints.add(msg)
  # TODO: add support for something like SCOPED_TRACE from Google Test

template fail* =
  ## Print out the checkpoints encountered so far and quit if ``abortOnError``
  ## is true. Otherwise, erase the checkpoints and indicate the test has
  ## failed (change exit code and test status). This template is useful
  ## for debugging, but is otherwise mostly used internally. Example:
  ##
  ## .. code-block:: nim
  ##
  ##  checkpoint("Checkpoint A")
  ##  complicatedProcInThread()
  ##  fail()
  ##
  ## outputs "Checkpoint A" before quitting.
  bind checkpoints
  for msg in items(checkpoints):
    echo msg

  when not defined(ECMAScript):
    if abortOnError: quit(1)

  when declared(testStatusIMPL):
    testStatusIMPL = FAILED
  else:
    programResult += 1

  checkpoints = @[]

macro check*(conditions: stmt): stmt {.immediate.} =
  ## Verify if a statement or a list of statements is true.
  ## A helpful error message and set checkpoints are printed out on
  ## failure (if ``outputLevel`` is not ``PRINT_NONE``).
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##  import strutils
  ##
  ##  check("AKB48".toLower() == "akb48")
  ##
  ##  let teams = {'A', 'K', 'B', '4', '8'}
  ##
  ##  check:
  ##    "AKB48".toLower() == "akb48"
  ##    'C' in teams
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
    for i in countup(1, exp.len - 1):
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
        if exp[i].typekind notin {ntyTypeDesc}:
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
  ## Same as `check` except any failed test causes the program to quit
  ## immediately. Any teardown statements are not executed and the failed
  ## test output is not generated.
  let savedAbortOnError = abortOnError
  block:
    abortOnError = true
    check conditions
  abortOnError = savedAbortOnError

macro expect*(exceptions: varargs[expr], body: stmt): stmt {.immediate.} =
  ## Test if `body` raises an exception found in the passed `exceptions`.
  ## The test passes if the raised exception is part of the acceptable
  ## exceptions. Otherwise, it fails.
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##  import math
  ##  proc defectiveRobot() =
  ##    randomize()
  ##    case random(1..4)
  ##    of 1: raise newException(OSError, "CANNOT COMPUTE!")
  ##    of 2: discard parseInt("Hello World!")
  ##    of 3: raise newException(IOError, "I can't do that Dave.")
  ##    else: assert 2 + 2 == 5
  ##
  ##  expect IOError, OSError, ValueError, AssertionError:
  ##    defectiveRobot()
  let exp = callsite()
  template expectBody(errorTypes, lineInfoLit: expr,
                      body: stmt): NimNode {.dirty.} =
    try:
      body
      checkpoint(lineInfoLit & ": Expect Failed, no exception was thrown.")
      fail()
    except errorTypes:
      discard
    except:
      checkpoint(lineInfoLit & ": Expect Failed, unexpected exception was thrown.")
      fail()

  var body = exp[exp.len - 1]

  var errorTypes = newNimNode(nnkBracket)
  for i in countup(1, exp.len - 2):
    errorTypes.add(exp[i])

  result = getAst(expectBody(errorTypes, exp.lineinfo, body))


when declared(stdout):
  # Reading settings
  # On a terminal this branch is executed
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
