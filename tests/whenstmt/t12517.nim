# Test based on issue #12517

discard """
  nimout: '''
nimvm
both
'''
  output: '''
both
'''
"""

proc test() =
  when nimvm:
    echo "nimvm"
  echo "both"

static:
  test()
test()

