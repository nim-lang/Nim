discard """


  file: "tnoop.nim"
  line: 13
  errormsg: "attempting to call undeclared routine: 'a'"
"""


var
  a: int

a()
