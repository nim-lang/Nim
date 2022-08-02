discard """
  action: compile
  nimout: '''
const
  foo {.strdefine.} = "abc"
let hey {.tddd.} = 5
'''
"""

import macros

template tddd {.pragma.}

expandMacros:
  const foo {.strdefine.} = "abc"
  let hey {.tddd.} = 5
