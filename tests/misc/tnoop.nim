discard """
  file: "tnoop.nim"
  line: 11
  errormsg: "undeclared identifier: 'a'"
"""


var
  a: int

a()
