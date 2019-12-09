discard """
output: '''
testCallback()
'''
"""

import asyncdispatch

proc testCallback() =
  echo "testCallback()"

when true:
  callSoon(testCallback)
  poll()
