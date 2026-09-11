discard """
  errormsg: "The 'RI' type doesn't have a valid default value"
"""


type RI {.requiresInit.} = object
  v: int

var v = default(RI) # should be flagged as invalid