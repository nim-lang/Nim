discard """
  errormsg: "type mismatch"
  line: 8
"""

# bug #7815: used to crash the compiler
type MyProc* = proc (arg: object)
var test: MyProc = nil
