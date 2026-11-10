discard """
  errormsg: "undeclared identifier: 'g'"
  line: "10"
"""

# bug #26044
proc p =
  when nimvm:
    var g: int
  discard g
p()
