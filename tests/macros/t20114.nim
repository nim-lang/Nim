discard """
  action: compile
  nimout: '''
const
  foo {.strdefine.} = "abc"
'''
"""

import macros

expandMacros:
  const foo {.strdefine.} = "abc"
