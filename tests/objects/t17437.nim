discard """
  cmd: "nim check $file"
  errormsg: ""
  nimout: '''
t17437.nim(20, 16) Error: undeclared identifier: 'x'
t17437.nim(20, 16) Error: expression 'x' has no type (or is ambiguous)
t17437.nim(20, 19) Error: incorrect object construction syntax
t17437.nim(20, 19) Error: incorrect object construction syntax
t17437.nim(20, 12) Error: expression '' has no type (or is ambiguous)
'''
"""

# bug #17437 invalid object construction should result in error

type
  V = ref object
    x, y: int

proc m =
  var v = V(x: x, y)

m()
