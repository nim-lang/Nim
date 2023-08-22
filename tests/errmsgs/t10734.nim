discard """
  cmd: "nim check $file"
  errormsg: ""
  nimout: '''
t10734.nim(19, 1) Error: invalid indentation
t10734.nim(19, 6) Error: invalid indentation
t10734.nim(20, 7) Error: expression expected, but found '[EOF]'
t10734.nim(18, 5) Error: 'proc' is not a concrete type; for a callback without parameters use 'proc()'
t10734.nim(19, 6) Error: undeclared identifier: 'p'
t10734.nim(19, 6) Error: expression 'p' has no type (or is ambiguous)
t10734.nim(19, 6) Error: 'p' cannot be assigned to
t10734.nim(17, 3) Hint: 'T' is declared but not used [XDeclaredButNotUsed]
'''
"""

type
  T = object
    a:
proc p =
  case