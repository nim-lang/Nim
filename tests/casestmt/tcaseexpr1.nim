discard """
  errormsg: "type mismatch: got <string> but expected 'int'"
  line: 33
  file: "tcaseexpr1.nim"

  errormsg: "not all cases are covered; missing: {C}"
  line: 27
  file: "tcaseexpr1.nim"
"""

# NOTE: This spec is wrong. Spec doesn't support multiple error
# messages. The first one is simply overridden by the second one.
# This just has never been noticed.

type
  E = enum A, B, C

proc foo(x: int): auto =
  return case x
    of 1..9: "digit"
    else: "number"

var r = foo(10)

var x = C

var t1 = case x:
  of A: "a"
  of B: "b"

var t2 = case x:
  of A: 10
  of B, C: "23"
