discard """
  file: "tinout.nim"
  line: 12
  errormsg: "type mismatch: got <int literal(3)>"
"""
# Test in out checking for parameters

proc abc(x: var int) =
    x = 0

proc b() =
    abc(3) #ERROR

b()


