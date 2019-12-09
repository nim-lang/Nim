discard """
  errormsg: '''
type mismatch: got <static[proc (a0: int): string{.noSideEffect, gcsafe, locks: 0.}](bar)>
'''
  line: 13
"""

macro fun(a: static float): untyped =
  discard

when true:
  proc bar(a0: int): string = discard
  fun(bar)
