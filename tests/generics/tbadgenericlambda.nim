discard """
  file: "tbadgenericlambda.nim"
  errormsg: "nested proc can have generic parameters only when"
  line: 7
"""

let x = proc (x, y): auto = x + y

