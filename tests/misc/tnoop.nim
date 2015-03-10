discard """
  file: "tnoop.nim"
  line: 11
  errormsg: "undeclared identifier: 'a'"
"""
# Tests the new check in the semantic pass

var
  a: int

a()  #ERROR_MSG undeclared identifier: 'a'

