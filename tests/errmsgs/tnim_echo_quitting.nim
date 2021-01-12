discard """
  cmd: "nim check $file"
  action: "reject"
  nimout: '''
tnim_echo_quitting.nim(12, 1) Error: undeclared identifier: 'nonexistant'
NimQuittingError
'''
"""

static: echo "ok1"
static: echo "ok2"
nonexistant
