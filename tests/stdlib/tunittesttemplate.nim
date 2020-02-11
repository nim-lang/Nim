discard """
  exitcode: 1
  outputsub: '''
    tunittesttemplate.nim(20, 12): Check failed: a.b == 2
    a.b was 0
  [FAILED] 1
'''
"""


# bug #6736

import unittest

type
  A = object
    b: int

template t: untyped =
  check(a.b == 2)

suite "1":
  test "1":
    var a = A(b: 0)
    t()
