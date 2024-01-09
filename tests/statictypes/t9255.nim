discard """
  errormsg: '''
type mismatch: got <proc (a0: int): string{.raises: <inferred> [], noSideEffect, gcsafe.}>
'''
  line: 13
"""

macro fun(a: static float): untyped =
  discard

when true:
  proc bar(a0: int): string = discard
  fun(bar)
