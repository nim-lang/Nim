discard """
  file: "tnoop.nim"
  line: 11
  errormsg: "attempting to call undeclared procedure: 'a'"
"""


var
  a: int

a()
