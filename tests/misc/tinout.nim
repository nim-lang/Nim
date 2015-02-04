discard """
  file: "tinout.nim"
  line: 12
  errormsg: "for a \'var\' type a variable needs to be passed"
"""
# Test in out checking for parameters

proc abc(x: var int) =
    x = 0

proc b() =
    abc(3) #ERROR

b()


