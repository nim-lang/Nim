discard """
  nimout: '''
msg1
msg2
'''
  action: compile
  nimoutFull: true
"""

# should fail because `msg3` is not in nimout and `nimoutFill: true` was given
static:
  echo "msg1"
  echo "msg2"
  echo "msg3"
