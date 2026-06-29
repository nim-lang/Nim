discard """
  matrix: "--warning:systemRangeConversion --warningaserror:systemRangeConversion"
"""

proc foo(x: range[0..100]) = discard

foo(12)

type
  Float = range[0.0..100.0]

proc bar(x: Float) = discard

bar(12.0)