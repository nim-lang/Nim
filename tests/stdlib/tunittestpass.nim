discard """
  targets: "c js"
"""


import unittest

block:
  check (type(1.0)) is float
  check type(1.0) is float
  check (typeof(1)) isnot float
  check typeof(1) isnot float

  check 1.0 is float
  check 1 isnot float

  type T = type(0.1)
  check T is float
  check T isnot int
