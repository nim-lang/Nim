discard """
  output: '''
ok
'''
"""



import strutils

try:
  proc foo() =
    assert(false)
  foo()
except AssertionError:
  let e = getCurrentException()
  let expectedStart = """tfailedassert_stacktrace.nim(14) tfailedassert_stacktrace
tfailedassert_stacktrace.nim(13) foo
system.nim("""
  let output = e.getStackTrace
  if output.startsWith expectedStart:
    echo "ok"
  else:
    echo "error"
    echo output
