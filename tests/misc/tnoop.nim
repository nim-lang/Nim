discard """
  nimout: '''
  found 'a' [var declared in tnoop.nim(11, 3)]
  '''
  file: "tnoop.nim"
  line: 13
  errormsg: "attempting to call routine: 'a'"
"""

var
  a: int

a()
