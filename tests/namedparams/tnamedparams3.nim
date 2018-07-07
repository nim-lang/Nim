discard """
  errormsg: "type mismatch: got <int literal(5), b: bool>"
  line: 10
"""

# bug #2993
proc test(i: int, a, b: bool) = discard
#test(5, b = false)             #Missing param a

5.test(b = false)             #Missing param a
