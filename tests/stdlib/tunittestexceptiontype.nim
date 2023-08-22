discard """
  exitcode: 1
  outputsub: '''exception type is [ValueError]'''
"""

import unittest

suite "exception from test":
  test "show exception type":
    raise newException(ValueError, "exception type is")
