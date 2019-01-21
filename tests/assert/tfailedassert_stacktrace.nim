discard """
  output: '''true'''
"""

const expected = """
tfailedassert_stacktrace.nim(34, 6) tfailedassert_stacktrace
tfailedassert_stacktrace.nim(33, 11) foo
system.nim(*, *)     failedAssertImpl
system.nim(*, *)     raiseAssert
system.nim(*, *)      sysFatal"""

proc tmatch(x, p: string): bool =
  var i = 0
  var k = 0
  while i < p.len:
    if p[i] == '*':
      let oldk = k
      while k < x.len and x[k] in {'0'..'9'}: inc k
      # no digit skipped?
      if oldk == k: return false
      inc i
    elif k < x.len and p[i] == x[k]:
      inc i
      inc k
    else:
      return false
  while k < x.len and x[k] in {' ', ',', '\L', '\C'}: inc k
  result = i >= p.len and k >= x.len

## line 30
try:
  proc foo() =
    assert(false)
  foo()
except AssertionError:
  let e = getCurrentException()
  let trace = e.getStackTrace
  if tmatch(trace, expected):
    echo true
  else:
    echo "error"
    echo trace
