discard """
  cmd: "nim check --hints:off $file"
  action: "reject"
  nimout: '''
t25508.nim(10, 23) Error: 'void' is not allowed as a field type
t25508.nim(11, 18) Error: 'void' is not allowed as a field type
'''
"""

discard default(tuple[b: void])
discard default((void,))