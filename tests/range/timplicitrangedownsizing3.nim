discard """
  matrix: "--warning:systemRangeConversion --warningaserror:systemRangeConversion"
"""

proc foo(x: range[0..100]) = discard

foo(12)