discard """
  cmd: "nim check $file"
  errormsg: "statement returns no value that can be discarded"
  nimout: '''
tillegaldiscardtypes.nim(11, 3) Error: statement returns no value that can be discarded
tillegaldiscardtypes.nim(12, 3) Error: statement returns no value that can be discarded
'''
"""

proc b(v: int) = # bug #21360
  discard @[]
  discard []

b(0)