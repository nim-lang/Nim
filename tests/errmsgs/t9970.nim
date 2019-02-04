discard """
  errormsg: "{.compileTime.} variable 'i' cannot be used at runtime"
  line: 7
"""

var i {.compileTime.} : int = 0
echo i
