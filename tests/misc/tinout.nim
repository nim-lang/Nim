discard """
  errormsg: "type mismatch: got <int literal(3)>"
  file: "tinout.nim"
  line: 12
"""
# Test in out checking for parameters

proc abc(x: var int) =
    x = 0

proc b() =
    abc(3) #ERROR

b()
