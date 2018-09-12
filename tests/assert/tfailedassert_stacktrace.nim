discard """
  output: '''
tfailedassert_stacktrace.nim(16) tfailedassert_stacktrace
tfailedassert_stacktrace.nim(15) foo
system.nim(3777)         failedAssertImpl
system.nim(3770)         raiseAssert
system.nim(2817)         sysFatal
'''
"""



try:
  proc foo() =
    assert(false)
  foo()
except AssertionError:
  let e = getCurrentException()
  echo e.getStackTrace
