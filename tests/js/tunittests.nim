discard """
  output: '''
[Suite] Bacon
  [OK] >:)'''
"""

import unittest

suite "Bacon":
  test ">:)":
    check(true == true)
