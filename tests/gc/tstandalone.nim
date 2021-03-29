discard """
  matrix: "--os:standalone --gc:none"
  errormsg: "value out of range"
"""

type
  rangeType = range[0..1]

var
  r: rangeType = 0
  i = 2

r = rangeType(i)
