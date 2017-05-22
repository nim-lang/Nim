discard """
  output: '''0 1 2 3 4 (a: 0, b: 4)
0 1 2 3 4 (a: 0, b: 4)
a b c d e (a: a, b: e)
0 1 2 3 4 (a: 0, b: 4)'''
"""

import sequtils

block:
  var x = @[12.0, 15.6, 19.0, 25, 23.9]
  for i in x.indices:
    stdout.write i, " "
  stdout.write indices(x), " "
  echo toSeq(indices(x))

block:
  var x = [12.0, 15.6, 19.0, 25, 23.9]
  for i in x.indices:
    stdout.write i, " "
  stdout.write indices(x), " "
  echo toSeq(indices(x))

block:
  var x: array['a'..'e', float] = [12.0, 15.6, 19.0, 25, 23.9]
  for i in x.indices:
    stdout.write i, " "
  stdout.write indices(x), " "
  echo toSeq(indices(x))

block:
  var x = "fooba"
  for i in x.indices:
    stdout.write i, " "
  stdout.write indices(x), " "
  echo toSeq(indices(x))
