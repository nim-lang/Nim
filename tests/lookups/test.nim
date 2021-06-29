discard """
output: '''

[Suite] memoization
'''
"""

# This file needs to be called 'test' nim to provoke a clash
# with the unittest.test name. Issue #

import unittest, macros

# bug #4555

macro memo(n: untyped) =
  result = n

proc fastFib(n: int): int {.memo.} = 40
proc fib(n: int): int = 40

suite "memoization":
  test "recursive function memoization":
    check fastFib(40) == fib(40)
