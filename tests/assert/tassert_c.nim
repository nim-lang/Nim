discard """
  cmd: "nim $target $options --excessiveStackTrace:off $file"
  output: '''true'''
"""

const expected = """
tassert_c.nim(35)        tassert_c
tassert_c.nim(34)        foo
assertions.nim(*)       failedAssertImpl
assertions.nim(*)       raiseAssert
fatal.nim(*)            sysFatal"""

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
  while k < x.len and x[k] in {' ', '\L', '\C'}: inc k
  result = i >= p.len and k >= x.len


try:
  proc foo() =
    assert(false)
  foo()
except AssertionDefect:
  let e = getCurrentException()
  let trace = e.getStackTrace
  if tmatch(trace, expected): echo true
  else: echo "wrong trace:\n" & trace
