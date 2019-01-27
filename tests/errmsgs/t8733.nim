discard """
errormsg: "compiletime symbol 'val2' needs to be global"
line: 7
"""

proc foo() =
  var val2 {.compileTime.} = 1
