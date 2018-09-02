discard """
  output: "6.0"
"""

proc sum*[T](s: seq[T], R: typedesc): R =
  var sum: R = 0
  for x in s:
    sum += R(x)
  return sum

echo @[1, 2, 3].sum(float)
