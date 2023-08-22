discard """
  matrix: "--stackTrace:on --hint:all:off --warnings:off"
  output: '''ok'''
"""
import strscans, strutils

proc raiseTestException*() =
  raise newException(Exception, "test")

proc matchStackTrace(actualEntries: openArray[StackTraceEntry], expected: string) =
  var expectedEntries = newSeq[StackTraceEntry]()
  var i = 0

  template checkEqual(actual, expected: typed, subject: string) =
    if actual != expected:
      echo "Unexpected ", subject, " on line ", i
      echo "Actual: ", actual
      echo "Expected: ", expected
      doAssert(false)

  for l in splitLines(expected.strip):
    var procname, filename: string
    var line: int
    if not scanf(l, "$s$w.nim($i) $w", filename, line, procname):
      doAssert(false, "Wrong expected stack trace")
    checkEqual(actualEntries[i].filename.`$`.split('/')[^1], filename & ".nim", "file name")
    if line != 0:
      checkEqual(actualEntries[i].line, line, "line number")
    checkEqual($actualEntries[i].procname, procname, "proc name")
    inc i

  doAssert(i == actualEntries.len, "Unexpected number of lines in stack trace")

template verifyStackTrace*(expectedStackTrace: string, body: untyped) =
  var verified = false
  try:
    body
  except Exception as e:
    verified = true
    # echo "Stack trace:"
    # echo e.getStackTrace
    matchStackTrace(e.getStackTraceEntries(), expectedStackTrace)

  doAssert(verified, "No exception was raised")

























when true:
# <-- Align with line 70 in the text editor
  block:
    proc bar() =
      raiseTestException()

    proc foo() =
      bar()

    const expectedStackTrace = """
      tproper_stacktrace.nim(87) tproper_stacktrace
      tproper_stacktrace.nim(77) foo
      tproper_stacktrace.nim(74) bar
      tproper_stacktrace.nim(8) raiseTestException
    """

    verifyStackTrace expectedStackTrace:
      foo()

  block:
    proc bar(x: int) =
      raiseTestException()

    template foo(x: int) =
      bar(x)

    const expectedStackTrace = """
      tproper_stacktrace.nim(104) tproper_stacktrace
      tproper_stacktrace.nim(91) bar
      tproper_stacktrace.nim(8) raiseTestException
    """

    verifyStackTrace expectedStackTrace:
      var x: int
      foo(x)

  block: #6803
    proc bar(x = 500) =
      raiseTestException()

    proc foo() =
      bar()

    const expectedStackTrace = """
      tproper_stacktrace.nim(121) tproper_stacktrace
      tproper_stacktrace.nim(111) foo
      tproper_stacktrace.nim(108) bar
      tproper_stacktrace.nim(8) raiseTestException
    """

    verifyStackTrace expectedStackTrace:
      foo()

  block:
    proc bar() {.stackTrace: off.} =
      proc baz() = # Stack trace should be enabled
        raiseTestException()
      baz()

    proc foo() =
      bar()

    const expectedStackTrace = """
      tproper_stacktrace.nim(140) tproper_stacktrace
      tproper_stacktrace.nim(130) foo
      tproper_stacktrace.nim(126) baz
      tproper_stacktrace.nim(8) raiseTestException
    """

    verifyStackTrace expectedStackTrace:
      foo()

  echo "ok"
