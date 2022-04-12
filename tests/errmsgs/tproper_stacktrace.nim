discard """
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
      tproper_stacktrace.nim(86) tproper_stacktrace
      tproper_stacktrace.nim(76) foo
      tproper_stacktrace.nim(73) bar
      tproper_stacktrace.nim(7) raiseTestException
    """

    verifyStackTrace expectedStackTrace:
      foo()

  block:
    proc bar(x: int) =
      raiseTestException()

    template foo(x: int) =
      bar(x)

    const expectedStackTrace = """
      tproper_stacktrace.nim(103) tproper_stacktrace
      tproper_stacktrace.nim(90) bar
      tproper_stacktrace.nim(7) raiseTestException
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
      tproper_stacktrace.nim(120) tproper_stacktrace
      tproper_stacktrace.nim(110) foo
      tproper_stacktrace.nim(107) bar
      tproper_stacktrace.nim(7) raiseTestException
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
      tproper_stacktrace.nim(139) tproper_stacktrace
      tproper_stacktrace.nim(129) foo
      tproper_stacktrace.nim(125) baz
      tproper_stacktrace.nim(7) raiseTestException
    """

    verifyStackTrace expectedStackTrace:
      foo()

  echo "ok"
