discard """
  errormsg: "'result' requires explicit initialization"
  line: 10
"""

type Meow {.requiresInit.} = object 
  init: bool

proc initMeow(): Meow =
  discard
