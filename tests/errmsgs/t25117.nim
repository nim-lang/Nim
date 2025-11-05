discard """
  errormsg: "'result' requires explicit initialization"
"""

type RI {.requiresInit.} = object
  v: int

proc xxx(v: var RI) = discard

proc f(T: type): T =
  xxx(result) # Should fail

discard f(RI)