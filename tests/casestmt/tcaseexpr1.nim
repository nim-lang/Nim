discard """
  cmd: "nim check $options $file"
  action: "reject"
  nimout: '''
tcaseexpr1.nim(33, 10) Error: not all cases are covered; missing: {C}
tcaseexpr1.nim(39, 12) Error: type mismatch: got <string> but expected 'int literal(10)'
'''
"""











# line 20
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
