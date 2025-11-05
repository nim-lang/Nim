discard """
  errormsg: "{.pop.} without a corresponding {.push.}"
"""

block:
  {.push raises: [].}

proc f() =
  {.pop.}

proc g() = raise newException(ValueError, "")