discard """
  errormsg: "cannot asign to global variable"
  line: 8
"""

proc foo =
  let a = 0
  var b {.global.} = a
foo()
