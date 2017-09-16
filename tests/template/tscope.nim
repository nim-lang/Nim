discard """
  errormsg: "redefinition of 'x'"
"""

var x = 1
template quantity() =
  # Causes internal error in compiler/sem.nim
  proc unit*(x = 1.0): float = 12
  # Throws the correct error: redefinition of 'x'
  #proc unit*(y = 1.0): float = 12
quantity()
var x = 2
