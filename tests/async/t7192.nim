discard """
output: '''
testCallback()
'''
"""

import asyncdispatch

proc testCallback() =
  echo "testCallback()"

when isMainModule:
  callSoon(testCallback)
  poll()
