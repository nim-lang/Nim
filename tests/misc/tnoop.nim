discard """
  nimout: '''
  found 'a' of kind 'var''''
  file: "tnoop.nim"
  line: 12
  errormsg: "attempting to call routine: 'a'"
"""

var
  a: int

a()
