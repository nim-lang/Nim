discard """
  nimout: '''@["1", "2", "3"]'''
"""

import sequtils

{.push compileTime.}

proc foo =
  echo mapIt([1, 2, 3], $it)

{.pop.}

static:
  foo()
