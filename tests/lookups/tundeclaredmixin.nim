discard """
  nimout: '''
  mixin nothing, add
'''
"""

# issue #22012

import macros

expandMacros:
  proc foo[T](): int =
    # `nothing` is undeclared, `add` is declared
    mixin nothing, add
    123

  doAssert foo[int]() == 123
