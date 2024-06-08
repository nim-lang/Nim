discard """
  errormsg: "cannot assign local to global variable"
  line: 7
"""

proc example(a:int) =
  let b {.global.} = a

example(1)
