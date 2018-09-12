discard """
  output: '''
tfailedassert_stacktrace.nim(16) tfailedassert_stacktrace
tfailedassert_stacktrace.nim(15) foo
system.nim(3778)         failedAssertImpl
system.nim(3771)         raiseAssert
system.nim(2818)         sysFatal
'''
"""



try:
  proc foo() =
    assert(false)
  foo()
except AssertionError:
  let e = getCurrentException()
  echo e.getStackTrace
