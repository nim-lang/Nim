discard """
  action: "reject"
  errormsg: "type mismatch: got <int>"
"""
# issue #25826

proc foo(x: var) = x = 123

let a = 0
foo(a)
