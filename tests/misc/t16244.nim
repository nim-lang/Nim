discard """
  errormsg: "type mismatch: got <int, float64>"
  line: 9
"""

proc g(): auto = 1
proc h(): auto = 1.0

var a = g() + h()
