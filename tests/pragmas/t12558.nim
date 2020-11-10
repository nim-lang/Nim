discard """
  nimout: '''@["1", "2", "3"]'''
"""

import sequtils

{.push compile_time.}

proc foo =
  echo map_it([1, 2, 3], $it)

{.pop.}

static:
  foo()
