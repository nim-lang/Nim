discard """
  action: run
  targets: '''c js'''
"""

import math
import std/assertions

let x = -0.0
doAssert classify(x) == fcNegZero
doAssert classify(1 / -0.0) == fcNegInf