discard """
  file: "tcaseexpr1.nim"

  line: 29
  errormsg: "type mismatch: got <string> but expected 'int'"

  line: 23
  errormsg: "not all cases are covered"
"""

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

