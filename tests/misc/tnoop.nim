discard """
  file: "tnoop.nim"
  line: 11
  errormsg: "expression \'a()\' cannot be called"
"""
# Tests the new check in the semantic pass

var
  a: int

a()  #ERROR_MSG expression 'a()' cannot be called

