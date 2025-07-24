
discard """
  cmd: "nim check $file"
  action: "reject"
  nimout: '''
tunamedbreak.nim(12, 5) Error: Using an unnamed break in a block is deprecated; Use a named block with a named break instead [UnnamedBreak]
tunamedbreak.nim(15, 3) Error: Using an unnamed break in a block is deprecated; Use a named block with a named break instead [UnnamedBreak]
  '''
"""
for i in 1..2: # errors
  block:
    break

block: # errors
  break
