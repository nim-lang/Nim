discard """
  cmd: "nim check $file"
  action: "reject"
  nimout: '''
t17693.nim(10, 24) Error: can't compute offsetof on this ast
'''
"""

# bug #17693; `nim check` crashed in `offsetof`
const ofs = GoodboySave.offsetof(header)
proc getSaveSize: int =
  const len = GoodboySave.sizeof - ofs
  len
