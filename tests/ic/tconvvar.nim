discard """
  description: '''IC: a converter returning `var` from another module must not mutate its sealed return type'''
"""

import mconvvar

proc bump(x: var int) = inc x

var b = Box(val: 41)
bump(b)
doAssert b.val == 42
