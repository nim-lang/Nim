discard """
errormsg: "'type' is a keyword and cannot be used as a parameter name"
"""

proc myproc(type: int) =
  echo type
