discard """
  errormsg: "invalid pragma for a proc type: importc: \"bind\"; if it is meant for the routine, put its proc return type in parentheses"
  line: 7
"""

# bug #8728: the pragma is attached to the proc return type
proc bindTo(p: proc(), self: int): proc() {.importc: "bind".}
