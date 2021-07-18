discard """
  errormsg: "type mismatch: got <string> but expected 'int'"
  line: 10
"""

# bug #15836
proc takesProc[T](x: T, f: proc(x: T): int) =
  echo f(x) + 2

takesProc(1, proc (a: auto): auto = "uh uh") # prints garbage
