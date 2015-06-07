discard """
  file: "tnoop.nim"
  line: 11
  errormsg: "attempting to call undeclared routine: 'a'"
"""


var
  a: int

a()
