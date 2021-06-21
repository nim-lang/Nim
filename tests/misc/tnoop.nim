discard """
  nimout: '''
  found 'a' [var declared in tnoop.nim(10, 3)]
  '''
  file: "tnoop.nim"
  errormsg: "attempting to call routine: 'a'"
"""

var
  a: int

a()
