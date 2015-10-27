discard """
  output: '''[OK] >:)'''
"""

import unittest

suite "Bacon":
  test ">:)":
    check(true == true)
