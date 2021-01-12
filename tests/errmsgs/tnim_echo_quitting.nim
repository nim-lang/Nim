discard """
  cmd: "nim check -d:nimEchoQuitting $file"
  action: "reject"
  nimout: '''
tnim_echo_quitting.nim(12, 1) Error: undeclared identifier: 'nonexistant'
nim quitting
'''
"""

static: echo "ok1"
static: echo "ok2"
nonexistant
